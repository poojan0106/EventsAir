/**
 * LogoMigrationBatch
 * 
 * Migrates existing Company Logo images (stored as Salesforce internal URLs in
 * Company_Logo__c) to AWS S3, then writes the public S3 URL to logo_url__c.
 *
 * Each record requires TWO HTTP callouts:
 *   1. GET  – fetch the image binary from the Salesforce /sfc/p/... URL
 *   2. PUT  – upload the binary to S3 (handled inside FileSizeChecker.uploadToS3)
 *
 * Because of the dual-callout requirement, scope size MUST be 1.
 *
 * Usage (execute in Developer Console > Execute Anonymous):
 *   Database.executeBatch(new LogoMigrationBatch(), 1);
 *
 * To run for specific records only:
 *   Database.executeBatch(new LogoMigrationBatch(new Set<Id>{'a0X...','a0X...'}), 1);
 */
public class LogoMigrationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    // Optional: restrict to a specific set of record IDs
    private Set<Id> recordIds;

    // Counters for final status email / debug
    private Integer totalProcessed = 0;
    private Integer totalSuccess   = 0;
    private Integer totalFailed    = 0;
    private List<String> errors    = new List<String>();

    // ── Constructors ──────────────────────────────────────────────────────────

    public LogoMigrationBatch() {}

    public LogoMigrationBatch(Set<Id> recordIds) {
        this.recordIds = recordIds;
    }

    // ── Start ─────────────────────────────────────────────────────────────────

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (recordIds != null && !recordIds.isEmpty()) {
            return Database.getQueryLocator(
                'SELECT Id, Name, Event_Name__c, Company_Logo__c, logo_url__c ' +
                'FROM Forms__c ' +
                'WHERE Id IN :recordIds ' +
                'AND Company_Logo__c != null ' +
                'AND logo_url__c = null'
            );
        }
        return Database.getQueryLocator(
            'SELECT Id, Name, Event_Name__c, Company_Logo__c, logo_url__c ' +
            'FROM Forms__c ' +
            'WHERE Company_Logo__c != null ' +
            'AND logo_url__c = null'
        );
    }

    // ── Execute ───────────────────────────────────────────────────────────────

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Forms__c form = (Forms__c) scope[0];
        totalProcessed++;

        try {
            // ── Step 1: Fetch the image from the Salesforce internal URL ──────
            String imageUrl = form.Company_Logo__c;

            // Ensure we have a full absolute URL
            if (!imageUrl.startsWith('http')) {
                // Relative URL — prepend org domain
                imageUrl = URL.getOrgDomainUrl().toExternalForm() + imageUrl;
            }

            // Derive the filename from the URL (last path segment before any query string)
            String fileName = deriveFileName(imageUrl);

            // Make authenticated GET callout using the current session ID
            HttpRequest getReq = new HttpRequest();
            getReq.setMethod('GET');
            getReq.setEndpoint(imageUrl);
            getReq.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            getReq.setTimeout(120000);

            Http http = new Http();
            HttpResponse getRes = http.send(getReq);

            if (getRes.getStatusCode() < 200 || getRes.getStatusCode() >= 300) {
                throw new LogoMigrationException(
                    'Failed to fetch image from Salesforce. HTTP ' +
                    getRes.getStatusCode() + ' ' + getRes.getStatus() +
                    ' | URL: ' + imageUrl
                );
            }

            Blob imageBlob = getRes.getBodyAsBlob();
            if (imageBlob == null || imageBlob.size() == 0) {
                throw new LogoMigrationException('Empty image body returned from: ' + imageUrl);
            }

            // Derive content type from response headers, fall back to image/jpeg
            String contentType = getRes.getHeader('Content-Type');
            if (String.isBlank(contentType)) {
                contentType = guessContentType(fileName);
            }
            // Strip any charset suffix (e.g. "image/png; charset=UTF-8")
            if (contentType.contains(';')) {
                contentType = contentType.split(';')[0].trim();
            }

            // Convert blob to plain base64 (no data URI prefix — uploadToS3 handles both)
            String base64Data = EncodingUtil.base64Encode(imageBlob);

            // ── Step 2: Upload to S3 via existing FileSizeChecker method ─────
            // uploadToS3 signature: (base64Data, fileName, fileType, folderName, recordId)
            // Note: folderName is derived inside uploadToS3 from the record itself,
            // so we pass an empty string — it is ignored when recordId is provided.
            String s3Url = FileSizeChecker.uploadToS3(
                base64Data,
                fileName,
                contentType,
                '',          // folderName — built inside uploadToS3 from Event_Name__c + Name
                form.Id
            );

            // ── Step 3: Write S3 URL to logo_url__c ──────────────────────────
            update new Forms__c(Id = form.Id, logo_url__c = s3Url);

            totalSuccess++;
            System.debug('✅ Migrated ' + form.Name + ' → ' + s3Url);

        } catch (Exception e) {
            totalFailed++;
            String err = 'FAILED [' + form.Id + '] ' + form.Name + ': ' + e.getMessage();
            errors.add(err);
            System.debug('❌ ' + err);
            // Do NOT rethrow — allow batch to continue with remaining records
        }
    }

    // ── Finish ────────────────────────────────────────────────────────────────

    public void finish(Database.BatchableContext bc) {
        String summary =
            '=== LogoMigrationBatch Complete ===\n' +
            'Total processed : ' + totalProcessed + '\n' +
            'Succeeded       : ' + totalSuccess   + '\n' +
            'Failed          : ' + totalFailed    + '\n';

        if (!errors.isEmpty()) {
            summary += '\nErrors:\n' + String.join(errors, '\n');
        }

        System.debug(summary);

        // Optional: send result email to yourself
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
        mail.setSubject('Logo Migration Batch — ' + totalSuccess + '/' + totalProcessed + ' succeeded');
        mail.setPlainTextBody(summary);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    // ── Private Helpers ───────────────────────────────────────────────────────

    /**
     * Derive a filename from a URL.
     * For /sfc/p/... URLs the last path segment is an opaque hash,
     * so we default to 'logo.jpg' when nothing meaningful is found.
     */
    private static String deriveFileName(String url) {
        try {
            // Strip query string
            String path = url.contains('?') ? url.split('\\?')[0] : url;
            List<String> parts = path.split('/');
            String last = parts[parts.size() - 1];
            // If it looks like a recognisable file name, use it
            if (last.contains('.') && last.length() < 100) {
                return last;
            }
        } catch (Exception e) {
            // Fall through to default
        }
        return 'logo.jpg';
    }

    /**
     * Guess MIME type from file extension.
     */
    private static String guessContentType(String fileName) {
        if (String.isBlank(fileName)) return 'image/jpeg';
        String lower = fileName.toLowerCase();
        if (lower.endsWith('.png'))  return 'image/png';
        if (lower.endsWith('.gif'))  return 'image/gif';
        if (lower.endsWith('.webp')) return 'image/webp';
        if (lower.endsWith('.svg'))  return 'image/svg+xml';
        return 'image/jpeg'; // safe default for logos
    }

    // ── Custom Exception ──────────────────────────────────────────────────────

    public class LogoMigrationException extends Exception {}
}