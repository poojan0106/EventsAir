@isTest
public class FileSizeCheckerTest {
	
    private static Forms__c createTestForm() {
        Forms__c form = new Forms__c(
            file_url__c = '',
            logo_url__c = '',
            Product_Logo__c = '',
            Stand_design_file1__c = '',
            Stand_design_file2__c = '',
            Stand_design_file3__c = ''
        );
        insert form;
        return form;
    }

    @IsTest
    static void testupdateFileURL() {
        Forms__c form = createTestForm();
        Test.startTest();
        FileSizeChecker.updateFileURL(form.Id, 'https://test.com/file1.pdf');
        Test.stopTest();

        Forms__c updatedForm = [SELECT Id, file_url__c FROM Forms__c WHERE Id = :form.Id];
        System.assertEquals('https://test.com/file1.pdf', updatedForm.file_url__c, 'File URL should be updated correctly.');
    }

    @IsTest
    static void testupdateLogoURL() {
        Forms__c form = createTestForm();
        Test.startTest();
        FileSizeChecker.updateLogoURL(form.Id, 'https://test.com/logo.png');
        Test.stopTest();

        Forms__c updatedForm = [SELECT Id, logo_url__c FROM Forms__c WHERE Id = :form.Id];
        System.assertEquals('https://test.com/logo.png', updatedForm.logo_url__c, 'Logo URL should be updated correctly.');
    }

    @IsTest
    static void testUpdateFormRecordForFileUploader() {
        Forms__c form = createTestForm();
        Test.startTest();
        FileSizeChecker.updateFormRecordForFileUploader(form.Id, 'https://test.com/productlogo.png');
        Test.stopTest();

        Forms__c updatedForm = [SELECT Id, Product_Logo__c FROM Forms__c WHERE Id = :form.Id];
        System.assertEquals('https://test.com/productlogo.png', updatedForm.Product_Logo__c, 'Product Logo should be updated correctly.');
    }

    @IsTest
    static void testUpdateFormRecordForStateDesignFlow_StateDesign1() {
        Forms__c form = createTestForm();
        Test.startTest();
        FileSizeChecker.updateFormRecordForStateDesignFlow(form.Id, 'https://test.com/state1.png', 'StateDesign1');
        Test.stopTest();

        Forms__c updatedForm = [SELECT Id, Stand_design_file1__c FROM Forms__c WHERE Id = :form.Id];
        System.assertEquals('https://test.com/state1.png', updatedForm.Stand_design_file1__c, 'StateDesign1 field should be updated correctly.');
    }

    @IsTest
    static void testUpdateFormRecordForStateDesignFlow_StateDesign2() {
        Forms__c form = createTestForm();
        Test.startTest();
        FileSizeChecker.updateFormRecordForStateDesignFlow(form.Id, 'https://test.com/state2.png', 'StateDesign2');
        Test.stopTest();

        Forms__c updatedForm = [SELECT Id, Stand_design_file2__c FROM Forms__c WHERE Id = :form.Id];
        System.assertEquals('https://test.com/state2.png', updatedForm.Stand_design_file2__c, 'StateDesign2 field should be updated correctly.');
    }

    @IsTest
    static void testUpdateFormRecordForStateDesignFlow_StateDesign3() {
        Forms__c form = createTestForm();
        Test.startTest();
        FileSizeChecker.updateFormRecordForStateDesignFlow(form.Id, 'https://test.com/state3.png', 'StateDesign3');
        Test.stopTest();

        Forms__c updatedForm = [SELECT Id, Stand_design_file3__c FROM Forms__c WHERE Id = :form.Id];
        System.assertEquals('https://test.com/state3.png', updatedForm.Stand_design_file3__c, 'StateDesign3 field should be updated correctly.');
    }

//Fake HTTP mock class to simulate S3 upload success response.

    private class S3SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('PUT', req.getMethod(), 'Method must be PUT');
            System.assert(req.getBodyAsBlob() != null, 'Request body must not be null');
            
            HttpResponse res = new HttpResponse();
            res.setHeader('x-amz-request-id', 'mock-request-id');
            res.setHeader('x-amz-id-2', 'mock-id-2');
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('Success');
            return res;
        }
    }

// Fake HTTP mock class to simulate S3 upload failure.
     
    private class S3ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(403);
            res.setStatus('Forbidden');
            res.setBody('Access Denied');
            return res;
        }
    }

    private static void createTestData() {
        // Create dummy S3 configuration
        Amezon_s3__c cfg = new Amezon_s3__c(
            Name='TestConfig',
            Access_Key_Id__c = 'TESTACCESSKEY',
            Secret_Access_Key__c = 'TESTSECRETKEY',
            Bucket_Name__c = 'test-bucket',
            Region__c = 'ap-south-1'
        );
        insert cfg;
    }

    //Test Case 1: Successful upload to S3.
    @IsTest
    static void testUploadToS3_Success() {
        createTestData();
        Forms__c form = createTestForm();
        Test.setMock(HttpCalloutMock.class, new S3SuccessMock());

        // Create fake Base64 image
        Blob fakeBlob = Blob.valueOf('This is test data');
        String base64Data = 'data:image/png;base64,' + EncodingUtil.base64Encode(fakeBlob);

        Test.startTest();
        String resultUrl = FileSizeChecker.uploadToS3(
            base64Data,
            'testImage.png',
            'image/png',
            'TestFolder',
            form.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, resultUrl, 'Result URL should not be null');
        System.assert(resultUrl.contains('amazonaws.com'), 'Result must contain AWS URL');
    }

    //Test Case 2: No file content (should throw AuraHandledException).
    @IsTest
    static void testUploadToS3_NoFileContent() {
        Forms__c form = createTestForm();
        createTestData();

        Test.startTest();
        try {
            FileSizeChecker.uploadToS3('', 'nofile.png', 'image/png', 'Folder', form.Id);
            System.assert(false, 'Expected exception for empty file content');
        } catch (AuraHandledException e) {
            System.debug('HandledException');
        }
        Test.stopTest();
    }

    //Test Case 3: Missing S3 configuration (should throw AuraHandledException).
    @IsTest
    static void testUploadToS3_MissingConfig() {
        // No Amezon_s3__c record inserted intentionally
        Forms__c form = createTestForm();

        Blob fakeBlob = Blob.valueOf('Test');
        String base64Data = 'data:image/png;base64,' + EncodingUtil.base64Encode(fakeBlob);

        Test.startTest();
        try {
            FileSizeChecker.uploadToS3(base64Data, 'file.png', 'image/png', 'Folder', form.Id);
            System.assert(false, 'Expected configuration exception');
        } catch (AuraHandledException e) {
            System.debug('HandledException');
        }
        Test.stopTest();
    }

    //Test Case 4: Failed S3 response (HTTP error).
     @IsTest
    static void testUploadToS3_FailureResponse() {
        createTestData();
        Forms__c form = createTestForm();
        Test.setMock(HttpCalloutMock.class, new S3ErrorMock());

        Blob fakeBlob = Blob.valueOf('Bad test data');
        String base64Data = 'data:image/png;base64,' + EncodingUtil.base64Encode(fakeBlob);

        Test.startTest();
        try {
            FileSizeChecker.uploadToS3(base64Data, 'testfail.png', 'image/png', 'Folder', form.Id);
            System.assert(false, 'Expected failure response');
        } catch (AuraHandledException e) {
            System.debug('HandledException');
        }
        Test.stopTest();
    }

    //Test Case 5: Invalid Base64 data handling.
    @IsTest
    static void testUploadToS3_InvalidBase64() {
        createTestData();
        Forms__c form = createTestForm();

        String invalidBase64 = 'data:image/png,this_is_not_valid';

        Test.startTest();
        try {
            FileSizeChecker.uploadToS3(invalidBase64, 'bad.png', 'image/png', 'Folder', form.Id);
            System.assert(false, 'Expected AuraHandledException for invalid base64');
        } catch (AuraHandledException e) {
            System.debug('HandledException');
        }
        Test.stopTest();
    }

	/*@isTest
    static void getFileSizeChecker(){
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        String fileContent = 'Hello World';
        Blob fileBlob = Blob.valueOf(fileContent);
        String base64Body = EncodingUtil.base64Encode(fileBlob);
        
        String base64Data = 'data:text/plain;base64,' + base64Body;
        String fileName = 'TestFile.txt';

        Test.startTest();
        Id contentDocumentId = FileSizeChecker.uploadBase64Image(base64Data, fileName, testAccount.Id);
        Test.stopTest();

        System.assertNotEquals(null, contentDocumentId, 'ContentDocumentId should not be null');

        List<ContentVersion> cvs = [
            SELECT Id, Title FROM ContentVersion WHERE Title = :fileName
        ];
        System.assertEquals(1, cvs.size(), 'One ContentVersion should be created');

        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId FROM ContentDocumentLink 
            WHERE LinkedEntityId = :testAccount.Id
        ];
        System.assertEquals(1, links.size(), 'One ContentDocumentLink should be created');
    }*/

}