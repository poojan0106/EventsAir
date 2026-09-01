@IsTest
private class LogoMigrationBatchTest {

    // ── Mock HTTP callouts ────────────────────────────────────────────────────

    /**
     * Handles both callouts in sequence:
     *   1. GET  from Salesforce /sfc/p/... → returns a fake image blob
     *   2. PUT  to AWS S3                  → returns HTTP 200
     */
    private class LogoMigrationMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'GET') {
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'image/jpeg');
                res.setBodyAsBlob(Blob.valueOf('FAKEIMAGEBYTES'));
            } else if (req.getMethod() == 'PUT') {
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody('');
            } else {
                res.setStatusCode(400);
                res.setBody('Unexpected method: ' + req.getMethod());
            }
            return res;
        }
    }

    /**
     * Mock that returns a 404 on the GET — simulates a broken image URL.
     */
    private class FailingFetchMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setStatus('Not Found');
            res.setBody('Not Found');
            return res;
        }
    }

    // ── Test data setup ───────────────────────────────────────────────────────

    // Name and Event_Name__c are auto-generated — only set writeable fields
    private static Forms__c createTestForm(String logoUrl) {
        Forms__c form = new Forms__c(
            Company_Logo__c = logoUrl
        );
        insert form;
        return form;
    }

    // ── Tests ─────────────────────────────────────────────────────────────────

    @IsTest
    static void testBatchSuccessfulMigration() {
        Forms__c form = createTestForm(
            'https://divcomau.my.salesforce.com/sfc/p/000000001/a/testlogo.jpg'
        );

        Test.setMock(HttpCalloutMock.class, new LogoMigrationMock());

        Test.startTest();
        Database.executeBatch(new LogoMigrationBatch(), 1);
        Test.stopTest();

        Forms__c updated = [SELECT logo_url__c FROM Forms__c WHERE Id = :form.Id];
        System.assertNotEquals(null, updated.logo_url__c, 'logo_url__c should be populated after migration');
        System.assert(updated.logo_url__c.startsWith('https://'), 'logo_url__c should be a valid HTTPS URL');
    }

    @IsTest
    static void testBatchWithSpecificIds() {
        Forms__c form1 = createTestForm('https://divcomau.my.salesforce.com/sfc/p/aaa/a/logo1.jpg');
        Forms__c form2 = createTestForm('https://divcomau.my.salesforce.com/sfc/p/bbb/a/logo2.jpg');

        // Only pass form1 — form2 should remain unprocessed
        Test.setMock(HttpCalloutMock.class, new LogoMigrationMock());

        Test.startTest();
        Database.executeBatch(new LogoMigrationBatch(new Set<Id>{ form1.Id }), 1);
        Test.stopTest();

        Forms__c updated1 = [SELECT logo_url__c FROM Forms__c WHERE Id = :form1.Id];
        Forms__c updated2 = [SELECT logo_url__c FROM Forms__c WHERE Id = :form2.Id];

        System.assertNotEquals(null, updated1.logo_url__c, 'Form1 should have been migrated');
        System.assertEquals(null, updated2.logo_url__c, 'Form2 was not in scope and should be unchanged');
    }

    @IsTest
    static void testBatchSkipsAlreadyMigrated() {
        Forms__c form = createTestForm(
            'https://divcomau.my.salesforce.com/sfc/p/xxx/a/logo.jpg'
        );
        // Pre-populate logo_url__c to simulate already migrated
        form.logo_url__c = 'https://divcomsalesforcefiles.s3.ap-southeast-2.amazonaws.com/existing/logo.jpg';
        update form;

        Test.setMock(HttpCalloutMock.class, new LogoMigrationMock());

        Test.startTest();
        Database.executeBatch(new LogoMigrationBatch(), 1);
        Test.stopTest();

        Forms__c updated = [SELECT logo_url__c FROM Forms__c WHERE Id = :form.Id];
        System.assertEquals(
            'https://divcomsalesforcefiles.s3.ap-southeast-2.amazonaws.com/existing/logo.jpg',
            updated.logo_url__c,
            'Already migrated record should not be overwritten'
        );
    }

    @IsTest
    static void testBatchHandlesFailedFetchGracefully() {
        Forms__c form = createTestForm(
            'https://divcomau.my.salesforce.com/sfc/p/yyy/a/broken.jpg'
        );

        Test.setMock(HttpCalloutMock.class, new FailingFetchMock());

        Test.startTest();
        Database.executeBatch(new LogoMigrationBatch(), 1);
        Test.stopTest();

        Forms__c updated = [SELECT logo_url__c FROM Forms__c WHERE Id = :form.Id];
        System.assertEquals(null, updated.logo_url__c, 'Failed fetch should leave logo_url__c null');
    }

    @IsTest
    static void testBatchSkipsNullLogoUrl() {
        // Form with no Company_Logo__c — should not be picked up by the batch query
        Forms__c form = new Forms__c();
        insert form;

        Test.setMock(HttpCalloutMock.class, new LogoMigrationMock());

        Test.startTest();
        Database.executeBatch(new LogoMigrationBatch(), 1);
        Test.stopTest();

        Forms__c updated = [SELECT logo_url__c FROM Forms__c WHERE Id = :form.Id];
        System.assertEquals(null, updated.logo_url__c, 'Form with no Company_Logo__c should not be processed');
    }

    @IsTest
    static void testLauncherInvocable() {
        Forms__c form = createTestForm(
            'https://divcomau.my.salesforce.com/sfc/p/zzz/a/logo.jpg'
        );

        Test.setMock(HttpCalloutMock.class, new LogoMigrationMock());

        LogoMigrationBatchLauncher.FlowInput input = new LogoMigrationBatchLauncher.FlowInput();
        input.formIds = new List<Id>{ form.Id };

        Test.startTest();
        LogoMigrationBatchLauncher.launch(new List<LogoMigrationBatchLauncher.FlowInput>{ input });
        Test.stopTest();

        System.assert(true, 'Launcher should enqueue batch without exception');
    }

    @IsTest
    static void testLauncherThrowsOnEmptyIds() {
        LogoMigrationBatchLauncher.FlowInput input = new LogoMigrationBatchLauncher.FlowInput();
        input.formIds = new List<Id>();

        Test.startTest();
        try {
            LogoMigrationBatchLauncher.launch(new List<LogoMigrationBatchLauncher.FlowInput>{ input });
            System.assert(false, 'Should have thrown an exception for empty ID list');
        } catch (LogoMigrationBatchLauncher.LogoMigrationLaunchException e) {
            System.assert(e.getMessage().contains('No Form record IDs'), 'Exception message should mention missing IDs');
        }
        Test.stopTest();
    }
}