@isTest
public class ExpocadBatchClassTest {
    @testSetup
    static void setupTestData() {
        // Create test data for Account
        Account accountRec = new Account(Name='Test Account');
        insert accountRec;

        // Create test data for Event__c
        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;

        Trading_As__c exhRec=new Trading_As__c(Name='test', Account__c=accountRec.Id);

        // Create test data for Stand__c
        Stand__c standRec = new Stand__c(
            Name = 'G36',
            ExpoCAD_ID__c = 'G36.' + eventRec.ExpoCAD_ID__c,
            Account_ID__c = accountRec.Id,
            Account_Name__c=accountRec.Name,
            Trading_As__c=exhRec.Id,
            Is_On_Hold__c=true
        );
        insert standRec;
    }


    private class MockHttpResponseGenerator2 implements HttpCalloutMock {
        Stand__c stand=[Select Id, Account_ID__c from Stand__c LIMIT 1];

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ExhibitorId":"","BoothNumber":"G18","Dimensions":"3m x 3m","DisplayNameOverride":"","XSize":"3m","YSize":"3m","Area":"9 m²","NumericArea":9,"CalculatedArea":null,"ObstructionsArea":null,"Status":"Initial","BoothClasses":["Pavilion Booth"],"ChildExhibitors":[],"HoldComment":"", "HoldExhibitorId":"' + stand.Account_ID__c + '", "HoldExhibitorName":"Test", "IsDeleted":false, "IsOnHold":true, "IsRented":false}');
            res.setStatusCode(200);
            return res;
        }

    }

   // Mock class to simulate a callout error
   private class ExpocadCalloutMockError implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"success": false, "message": "Simulated error"}');
        res.setStatusCode(500);
        return res;
    }
}
    private class MockHttpResponseGenerator4 implements HttpCalloutMock {
        Stand__c stand=[Select Id, Account_ID__c from Stand__c LIMIT 1];

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ExhibitorId":"' + stand.Account_ID__c + '","BoothNumber":"G18","Dimensions":"3m x 3m","DisplayNameOverride":"","XSize":"3m","YSize":"3m","Area":"9 m²","NumericArea":9,"CalculatedArea":null,"ObstructionsArea":null,"Status":"Initial","BoothClasses":["Pavilion Booth"],"ChildExhibitors":[],"HoldComment":"", "HoldExhibitorId":"", "HoldExhibitorName":"", "IsDeleted":false, "IsOnHold":false, "IsRented":true}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
       
        Stand__c stand=[Select Id, Account_ID__c from Stand__c LIMIT 1];

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ExhibitorId":"' + stand.Account_ID__c + '","BoothNumber":"G18","Dimensions":"3m x 3m","DisplayNameOverride":"","XSize":"3m","YSize":"3m","Area":"9 m²","NumericArea":9,"CalculatedArea":null,"ObstructionsArea":null,"Status":"Initial","BoothClasses":["Pavilion Booth"],"ChildExhibitors":[],"HoldComment":"", "HoldExhibitorId":"", "HoldExhibitorName":"", "IsDeleted":false, "IsOnHold":false, "IsRented":false}');
            res.setStatusCode(200);
            return res;
        }
    }


    // // Helper method to create test data for Stand__c records
    private static List<Stand__c> createTestStands(String accountRectId, String eventRecExpocadId, Boolean isOnHold, Boolean isRented) {

        List<Stand__c> stands = new List<Stand__c>();
        Stand__c standRec1= new Stand__c();
        standRec1.Name='G36';
        if(eventRecExpocadId!=null){
            standRec1.ExpoCAD_ID__c='G36.' + eventRecExpocadId;
        }
        if(accountRectId!=null){
            standRec1.Account_ID__c=accountRectId;
        }
        standRec1.Is_Rented__c=isRented;
        standRec1.Is_On_Hold__c=isOnHold;
        stands.add(standRec1);

        Stand__c standRec2= new Stand__c();
        standRec2.Name='A17';
        if(eventRecExpocadId!=null){
            standRec2.ExpoCAD_ID__c='A17.' + eventRecExpocadId;
        }
        if(accountRectId!=null){
            standRec2.Account_ID__c=accountRectId;
        }
        standRec2.Is_Rented__c=isRented;
        standRec2.Is_On_Hold__c=isOnHold;
        stands.add(standRec2);

        insert stands;
        return stands;
    }

    @isTest
    static void testBatchProcessing() {

        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;

        Stand__c standList=[Select Id, Account_ID__c from Stand__c LIMIT 1];

        List<Stand__c> stands = createTestStands(standList.Account_ID__c, eventRec.ExpoCAD_ID__c,true, false);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create instance of ExpocadBatchClass with test Stand__c record Ids
        List<Id> standIds = new List<Id>();
        for (Stand__c stand : stands) {
            standIds.add(stand.Id);
        }
        ExpocadBatchClass batchClass = new ExpocadBatchClass(standIds);

        // Test start method
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }

    @isTest
    static void testBatchProcessing2() {

        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;
        // Create test data for Account
        Account accountRec = new Account(Name='Test Account');
        insert accountRec;

      
        List<Stand__c> stands = createTestStands(accountRec.Id, eventRec.ExpoCAD_ID__c,false, true);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create instance of ExpocadBatchClass with test Stand__c record Ids
        List<Id> standIds = new List<Id>();
        for (Stand__c stand : stands) {
            standIds.add(stand.Id);
        }
        ExpocadBatchClass batchClass = new ExpocadBatchClass(standIds);

        // Test start method
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }

    @isTest
    static void testBatchProcessing3() {
        // Create test data
        Stand__c standList=[Select Id, Account_ID__c from Stand__c LIMIT 1];

        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;

        List<Stand__c> stands = createTestStands(standList.Account_ID__c, eventRec.ExpoCAD_ID__c,false, false);  

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());

        // Create instance of ExpocadBatchClass with test Stand__c record Ids
        List<Id> standIds = new List<Id>();
        for (Stand__c stand : stands) {
            standIds.add(stand.Id);
        }
        ExpocadBatchClass batchClass = new ExpocadBatchClass(standIds);

        // Test start method
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }


    @isTest
    static void testBatchProcessing4() {
        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;

        // Create test data
        List<Stand__c> stands = createTestStands(null,eventRec.ExpoCAD_ID__c, false, false);  

       

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create instance of ExpocadBatchClass with test Stand__c record Ids
        List<Id> standIds = new List<Id>();
        for (Stand__c stand : stands) {
            standIds.add(stand.Id);
        }
        ExpocadBatchClass batchClass = new ExpocadBatchClass(standIds);

        // Test start method
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }

    @isTest
    static void testBatchProcessing5() {
        // Create test data for Account
        Account accountRec = new Account(Name='Test Account');
        insert accountRec;

        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;

        // Create test data
        List<Stand__c> stands = createTestStands(accountRec.Id, eventRec.ExpoCAD_ID__c,false, true);  

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator4());

        // Create instance of ExpocadBatchClass with test Stand__c record Ids
        List<Id> standIds = new List<Id>();
        for (Stand__c stand : stands) {
            standIds.add(stand.Id);
        }
        ExpocadBatchClass batchClass = new ExpocadBatchClass(standIds);

        // Test start method
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }

    @isTest
    static void testBatchProcessing6() {
        // Create test data for Account
        Account accountRec = new Account(Name='Test Account');
        insert accountRec;

        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;

        // Create test data
        List<Stand__c> stands = createTestStands(accountRec.Id, eventRec.ExpoCAD_ID__c,false, false);  

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator4());

        // Create instance of ExpocadBatchClass with test Stand__c record Ids
        List<Id> standIds = new List<Id>();
        for (Stand__c stand : stands) {
            standIds.add(stand.Id);
        }
        ExpocadBatchClass batchClass = new ExpocadBatchClass(standIds);

        // Test start method
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }


    @isTest
    static void testBatchProcessing7() {
        Stand__c standList=[Select Id, Account_ID__c from Stand__c LIMIT 1];
        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;

        // Create test data
        List<Stand__c> stands = createTestStands(standList.Account_ID__c, eventRec.ExpoCAD_ID__c,false, true);  

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create instance of ExpocadBatchClass with test Stand__c record Ids
        List<Id> standIds = new List<Id>();
        for (Stand__c stand : stands) {
            standIds.add(stand.Id);
        }
        ExpocadBatchClass batchClass = new ExpocadBatchClass(standIds);

        // Test start method
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }

    
    @isTest
    static void testBatchProcessing8() {
        // Create test data for Account
        Account accountRec = new Account(Name='Test Account');
        insert accountRec;

        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;

        // Create test data
        List<Stand__c> stands = createTestStands(accountRec.Id, eventRec.ExpoCAD_ID__c,true, false);  

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create instance of ExpocadBatchClass with test Stand__c record Ids
        List<Id> standIds = new List<Id>();
        for (Stand__c stand : stands) {
            standIds.add(stand.Id);
        }
        ExpocadBatchClass batchClass = new ExpocadBatchClass(standIds);

        // Test start method
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }

    @isTest
    static void testBatchProcessing9() {
        Stand__c standList=[Select Id, Account_ID__c from Stand__c LIMIT 1];

        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;

        // Create test data
        List<Stand__c> stands = createTestStands(standList.Account_ID__c, eventRec.ExpoCAD_ID__c, false, true);  
        Test.setMock(HttpCalloutMock.class, new ExpocadCalloutMockError());

        // Create instance of ExpocadBatchClass with test Stand__c record Ids
        List<Id> standIds = new List<Id>();
        for (Stand__c stand : stands) {
            standIds.add(stand.Id);
        }
        ExpocadBatchClass batchClass = new ExpocadBatchClass(standIds);

        // Test start method
        Test.startTest();
        Database.executeBatch(batchClass);
        Test.stopTest();
    }

    @isTest
    static void testBatchProcessing10() {
        // Test start method
        Test.startTest();
        ExpocadBatchClass.addExhibitor(null , null);
        ExpocadBatchClass.checkExhibitor(null , null);
        ExpocadBatchClass.holdUnHoldStand(null , null);
        ExpocadBatchClass.unHoldStand(null , null);
        ExpocadBatchClass.RentUnRentStand(null , null);
        ExpocadBatchClass.unRentStand(null , null);
        ExpocadBatchClass.rentStand(null , null);
        ExpocadBatchClass.removeExpocadClass(null , null);
        ExpocadBatchClass.addBoothClass(null);
        ExpocadBatchClass.holdStandInExpocad(null,null);
        ExpocadBatchClass.SFStandExpocadBoothSync(null);

        Test.stopTest();
    }


    @isTest
    static void testBatchProcessing12() {
        Stand__c stand=[Select Id, Name , Is_On_Hold__c, Event_Expocad_Id__c, Account_ID__c ,Trading_As__c , Account_Name__c from Stand__c LIMIT 1];

        String jsonData='{"ExhibitorId":"'+stand.Account_ID__c+'","BoothNumber":"G18","Dimensions":"3m x 3m","DisplayNameOverride":"","XSize":"3m","YSize":"3m","Area":"9 m²","NumericArea":9,"CalculatedArea":null,"ObstructionsArea":null,"Status":"Initial","BoothClasses":["Pavilion Booth"],"ChildExhibitors":[],"HoldComment":"", "HoldExhibitorId":"", "HoldExhibitorName":"", "IsDeleted":false, "IsOnHold":false, "IsRented":false}';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Test start method
        Test.startTest();
        ExpocadBatchClass.addExhibitor(jsonData , stand);
        Test.stopTest();
    }


    @isTest
    static void testBatchProcessing11() {

        Stand__c stand=[Select Id, Name , Is_On_Hold__c, Event_Expocad_Id__c, Account_ID__c from Stand__c LIMIT 1];

        String jsonData='{"ExhibitorId":"'+stand.Account_ID__c+'","BoothNumber":"G18","Dimensions":"3m x 3m","DisplayNameOverride":"","XSize":"3m","YSize":"3m","Area":"9 m²","NumericArea":9,"CalculatedArea":null,"ObstructionsArea":null,"Status":"Initial","BoothClasses":["Pavilion Booth"],"ChildExhibitors":[],"HoldComment":"", "HoldExhibitorId":"", "HoldExhibitorName":"", "IsDeleted":false, "IsOnHold":false, "IsRented":false}';

        Test.setMock(HttpCalloutMock.class, new ExpocadCalloutMockError());
        // Test start method
        Test.startTest();
        ExpocadBatchClass.addBoothClass(stand);
        ExpocadBatchClass.removeExpocadClass(stand,jsonData);
        ExpocadBatchClass.addExhibitor(jsonData,stand);
        ExpocadBatchClass.checkExhibitor(stand,jsonData);
        ExpocadBatchClass.unHoldStand(jsonData,stand);
        ExpocadBatchClass.holdUnHoldStand(stand,jsonData);
        ExpocadBatchClass.RentUnRentStand(stand,jsonData);
        ExpocadBatchClass.unRentStand(stand,jsonData);
        ExpocadBatchClass.rentStand(stand,jsonData);
        ExpocadBatchClass.holdStandInExpocad(stand,jsonData);
        Test.stopTest();
    }


}