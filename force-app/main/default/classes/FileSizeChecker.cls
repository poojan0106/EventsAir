public class FileSizeChecker {

    public class CustomException extends Exception {}

   
    //update file URL feild of event form object
    @AuraEnabled
    public static void updateFileURL(String recordId, String fileUrl) {
        if (String.isBlank(recordId) || String.isBlank(fileUrl)) {
            throw new AuraHandledException('Record Id and File URL are required.');
        }
        Forms__c form = new Forms__c(Id = recordId, file_url__c = fileUrl);
        if(form!=null){
            update form;
        }
        else{
            System.debug('Form is null');
        }
        
    }

    //update logo URL feild of event form object
    @AuraEnabled
    public static void updateLogoURL(String recordId, String fileUrl) {
        if (String.isBlank(recordId) || String.isBlank(fileUrl)) {
            throw new AuraHandledException('Record Id and File URL are required.');
        }
        Forms__c form = new Forms__c(Id = recordId, logo_url__c = fileUrl);
        if(form!=null){
            update form;
        }
        else{
            System.debug('Form is null');
        }
    }

    //update Product Logo URL feild of event form object
    @AuraEnabled
    public static void updateFormRecordForFileUploader(String recordId, String fileUrl) {
            if (String.isBlank(recordId) || String.isBlank(fileUrl)) {
            throw new AuraHandledException('Record Id and File URL are required.');
        }
            Forms__c form = new Forms__c(Id = recordId, Product_Logo__c = fileUrl);
            if(form!=null){
            update form;
        }
            else{
            System.debug('Form is null');
        }
    }

    //update State design file1, State design file2, State design file3 feild of event form object
    @AuraEnabled
    public static void updateFormRecordForStateDesignFlow(String recordId, String fileUrl, String flowContext) {
            if (String.isBlank(recordId) || String.isBlank(fileUrl) || String.isBlank(flowContext)) {
            throw new AuraHandledException('Record Id, File URL, and Flow Context are required.');
        }
            Forms__c form = new Forms__c();
            form.Id=recordId;
            if(flowContext=='StateDesign1'){
                form.Stand_design_file1__c=fileUrl;
            }
            else if(flowContext=='StateDesign2'){
                form.Stand_design_file2__c=fileUrl;
            }
            else{
                form.Stand_design_file3__c=fileUrl;
            }
            if(form!=null){
            update form;
        }
        else{
            System.debug('Form is null');
        }
    }
    
    //File Upload To S3
    @AuraEnabled
    public static String uploadToS3(String base64Data, String fileName, String fileType, String folderName, String recordId) {
        // ---- 0) Decode incoming data ----
        Blob body = decodePossiblyDataUri(base64Data);
        if (body == null || body.size() == 0) {
            throw new AuraHandledException('No file content to upload.');
        }
        String folder='';
        List<Forms__c> formRecord = [SELECT Name,Event_Name__c FROM Forms__c WHERE Id = :recordId LIMIT 1];
        // folder name is event name and subfolder is form name 
        if (formRecord == null || formRecord.size() == 0) {
            throw new AuraHandledException('Form record not found.');
        }
        else{
            folder = formRecord.get(0).Event_Name__c + '/' + formRecord.get(0).Name;
        }
        // ---- 1) Load config from your custom setting ----
        Amezon_s3__c configuration = Amezon_s3__c.getOrgDefaults();
        if (configuration == null
            || String.isBlank(configuration.Access_Key_Id__c)
            || String.isBlank(configuration.Secret_Access_Key__c)
            || String.isBlank(configuration.Bucket_Name__c)
            || String.isBlank(configuration.Region__c)) {
            throw new AuraHandledException('Incomplete S3 configuration (keys/bucket/region).');
        }
        String accessKey = configuration.Access_Key_Id__c.trim();
        String secretKey = configuration.Secret_Access_Key__c.trim();
        String bucket    = configuration.Bucket_Name__c.trim();
        String region    = configuration.Region__c.trim();

        // ---- 2) Build a safe key (in a folder if you want) ----
        String clean  = sanitizeFileName(fileName);
        String key='';
        
        if(clean==''){
            System.debug('File name not available');
        }
        else{
            key = (String.isNotBlank(folder) ? folder + '/' : '') + clean;
        }

        // ---- 3) Derive host + URL ----
        
             String host  = bucket + '.s3.' + region + '.amazonaws.com';
             String url    = 'https://' + host + '/' + rfc3986EncodePath(key);

        // ---- 4) Prepare headers ----
        String contentType = String.isBlank(fileType) ? 'application/octet-stream' : fileType;
        Datetime now = Datetime.now();
        String amzDate = now.formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
        String dateScope = now.formatGMT('yyyyMMdd');

        // We will sign with UNSIGNED-PAYLOAD (valid for S3 over HTTPS)
        String payloadHash = 'UNSIGNED-PAYLOAD';

        // Canonical headers (lowercase, sorted). Only include headers you also send.
        Map<String, String> headers = new Map<String, String>{
            'content-type'          => contentType,
            'host'                  => host,
            'x-amz-content-sha256'  => payloadHash,
            'x-amz-date'            => amzDate
        };

        // ---- 5) Build canonical request ----
        String canonicalUri    = '/' + rfc3986EncodePath(key);
        String canonicalQuery  = ''; // none
        String canonicalHeaders = buildCanonicalHeaders(headers);
        String signedHeaders    = 'content-type;host;x-amz-content-sha256;x-amz-date';
        String canonicalRequest =
            'PUT\n' +
            canonicalUri + '\n' +
            canonicalQuery + '\n' +
            canonicalHeaders + '\n' +
            signedHeaders + '\n' +
            payloadHash;

        // ---- 6) String to sign ----
        String algorithm = 'AWS4-HMAC-SHA256';
        String credentialScope = dateScope + '/' + region + '/s3/aws4_request';
        String stringToSign =
            algorithm + '\n' +
            amzDate + '\n' +
            credentialScope + '\n' +
            toHex( Crypto.generateDigest('SHA-256', Blob.valueOf(canonicalRequest)) );

        // ---- 7) Derive signing key & signature ----
        Blob kDate    = hmacSha256(Blob.valueOf('AWS4' + secretKey), Blob.valueOf(dateScope));
        Blob kRegion  = hmacSha256(kDate, Blob.valueOf(region));
        Blob kService = hmacSha256(kRegion, Blob.valueOf('s3'));
        Blob kSigning = hmacSha256(kService, Blob.valueOf('aws4_request'));
        String signature = toHex( hmacSha256(kSigning, Blob.valueOf(stringToSign)) );

        String authorization =
            algorithm + ' ' +
            'Credential=' + accessKey + '/' + credentialScope + ', ' +
            'SignedHeaders=' + signedHeaders + ', ' +
            'Signature=' + signature;

        // ---- 8) Make the callout ----
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setEndpoint(url);                            // using full URL (requires Remote Site Setting)
        req.setCompressed(false);                        // avoid gzip
        req.setHeader('Expect', '');                     // avoid 100-continue
        req.setHeader('Connection', 'close');            // avoid keep-alive edge cases
        req.setHeader('Authorization', authorization);
        req.setHeader('x-amz-date', amzDate);
        req.setHeader('x-amz-content-sha256', payloadHash);
        req.setHeader('Content-Type', contentType);
        req.setHeader('Content-Length', String.valueOf(body.size())); // force fixed-length (prevents 505)
        
        req.setBodyAsBlob(body);
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new AuraHandledException(
                'S3 PUT failed: HTTP ' + res.getStatusCode() + ' ' + res.getStatus()
                + ' | x-amz-request-id=' + nvl(res.getHeader('x-amz-request-id'))
                + ' | x-amz-id-2=' + nvl(res.getHeader('x-amz-id-2'))
                + ' | body=' + nvl(res.getBody())
            );
        }

        return 'https://' + host + '/' + rfc3986EncodePath(key);
    }

    // ---------- Helpers ----------

    private static String buildCanonicalHeaders(Map<String,String> headers) {
        // headers are already lowercase keys; sort by key
        List<String> keys = new List<String>(headers.keySet());
        keys.sort();
        String out = '';
        for (String k : keys) {
            out += k.toLowerCase() + ':' + headers.get(k).trim() + '\n';
        }
        return out;
    }

    //Generates hash code
    private static Blob hmacSha256(Blob key, Blob msg) {
        return Crypto.generateMac('HmacSHA256', msg, key);
    }

    //Converting to hexadecimal
    private static String toHex(Blob b) {
        return EncodingUtil.convertToHex(b).toLowerCase();
    }

    private static String nvl(String s) { return (s == null) ? '' : s; }

    //Encode file content
    private static Blob decodePossiblyDataUri(String base64Data) {
        if (String.isBlank(base64Data)) return null;
        Integer idx = base64Data.indexOf('base64,');
        String b64 = (idx >= 0) ? base64Data.substring(idx + 'base64,'.length()) : base64Data;
        try {
            return EncodingUtil.base64Decode(b64);
        } catch (Exception e) {
            try { return EncodingUtil.base64Decode(EncodingUtil.urlDecode(b64, 'UTF-8')); }
            catch (Exception ex) { throw new AuraHandledException('Invalid base64 data.'); }
        }
    }
    
    //Replacing \ with / and returning file name
    private static String sanitizeFileName(String nameIn) {
        String n = String.isBlank(nameIn) ? 'file' : nameIn;
        n = n.replace('\\','/'); if (n.contains('/')) { List<String> p = n.split('/'); if (!p.isEmpty()) n = p.get(p.size()-1); }
        return (n == '') ? 'file' : n;
    }

    // Encode each path segment per RFC 3986; preserve '/'
    private static String rfc3986EncodePath(String path) {
        List<String> parts = path.split('/');
        for (Integer i=0; i<parts.size(); i++) {
            parts[i] = EncodingUtil.urlEncode(parts[i], 'UTF-8')
                .replace('+','%20')
                .replace('*','%2A')
                .replace('%7E','~');
        }
        return String.join(parts, '/');
    }


}