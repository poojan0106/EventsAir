@isTest
public  class ExpocadIntegrationLogicTest {
    @testSetup
    static void setupTestData() {
        // Create test data for Account
        Account accountRec = new Account(
            Name='Test Account',
            BillingStreet = '123 Main St',
            BillingCity = 'Anytown',
            BillingState = 'CA',
            BillingPostalCode = '12345',
            BillingCountry = 'United States'
        );
        insert accountRec;

        Opportunity oppRec= new Opportunity(Name='Test Oppp', StageName='Proposal Sent', CloseDate=system.today());
        insert oppRec;

        // Create test data for Event__c
        Event__c eventRec = new Event__c(
            Name = 'Test Event',
            ExpoCAD_ID__c = 'eaws20',
            Event_Portfolio__c = 'Wealth'
        );
        insert eventRec;

        // Create test data for Stand__c
        Stand__c standRec = new Stand__c(
            Name = 'G36',
            ExpoCAD_ID__c = 'G36.' + eventRec.ExpoCAD_ID__c,
            Account_ID__c = accountRec.Id,
            Event__c=eventRec.Id
        );
        insert standRec;

        Trading_As__c exhibitingAsRec = new Trading_As__c(
            Name = 'test exhibiting as',
            Account__c = accountRec.Id
        );
        insert exhibitingAsRec;

        Co_Exhibitor__c coExhibitorRec = new Co_Exhibitor__c(
            Opportunity__c = oppRec.Id,
            Account__c = accountRec.Id,
            Exhibiting_As__c = exhibitingAsRec.Id,
            Event__c=eventRec.Id,
            Stand__c=standRec.Id,
            Exhibitor_Sync_with_ExpoCAD__c='Verifying',
            Details_Synced_with_ExpoCAD__c='Success'
        );
        insert coExhibitorRec;

    }

    // Mock HTTP response generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"Name":"AORA Organics Zone"},{"Name":"Test Pavilion 1"},{"Name":"Test Pavilion 2"},{"Name":"Test Pavilion 3"}]');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockHttpResponseGeneratorFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('mesage');
            res.setStatusCode(404);
            return res;
        }
    }

    private class MockHttpResponseGeneratorTest implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"mockResponse": "This is a mock response"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testPavilionExpocadCallout() {
        Event__c eventRec = [SELECT Id, Name, ExpoCAD_ID__c FROM Event__c LIMIT 1];
        List<Stand__c> stands = [SELECT Name FROM Stand__c WHERE Event__c = :eventRec.Id];
        Co_Exhibitor__c coExhRec = [SELECT Id, Opportunity__c, Event__c, Account__c, Exhibiting_As__c FROM Co_Exhibitor__c WHERE Event__c=:eventRec.Id];


        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ExpocadIntegration expocad = new ExpocadIntegration();

        // Call the method under test
        Test.startTest();
        // HttpResponse mockResponse = expocad.makeGetCallout('https://divcomausb.expocad.com/EdgeApi/eaws20/all');
        ExpocadIntegrationLogic.pavilionExpocadCallout(eventRec.Id);
        ExpocadIntegrationLogic.childExhibitorTransformation(coExhRec.Id);
        ExpocadIntegrationLogic.checkVerifingStatus(coExhRec.Id);
        ExpocadIntegrationLogic.checkCreatingStatus(coExhRec.Id);
        ExpocadIntegrationLogic.checkCoExhibitorStatus(coExhRec.Id);
        Test.stopTest();
    }

    @isTest
    static void testPavilionExpocadCallout_Failure() {
        Event__c eventRec = [SELECT Id, Name, ExpoCAD_ID__c FROM Event__c LIMIT 1];
        List<Stand__c> stands = [SELECT Name FROM Stand__c WHERE Event__c = :eventRec.Id];

        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorFailure());
        ExpocadIntegration expocad = new ExpocadIntegration();

        // Call the method under test
        Test.startTest();
        // HttpResponse mockResponse = expocad.makeGetCallout('https://divcomausb.expocad.com/EdgeApi/eaws20/all');
        ExpocadIntegrationLogic.pavilionExpocadCallout(eventRec.Id);
        Test.stopTest();
    }


   
    @isTest
    static void testMethodForCatch() {
        Event__c eventRec = [SELECT Id, Name, ExpoCAD_ID__c FROM Event__c LIMIT 1];
        List<Stand__c> stands = [SELECT Name FROM Stand__c WHERE Event__c = :eventRec.Id];

        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTest());
        ExpocadIntegration expocad = new ExpocadIntegration();

        // Call the method under test
        Test.startTest();
        // HttpResponse mockResponse = expocad.makeGetCallout('https://divcomausb.expocad.com/EdgeApi/eaws20/all');
        ExpocadIntegrationLogic.pavilionExpocadCallout(eventRec.Id);
        Test.stopTest();
    }
  
    @isTest
    static void testMethodForCoExhibitor() {
        Event__c eventRec = [SELECT Id, Name, ExpoCAD_ID__c FROM Event__c LIMIT 1];
        Stand__c standRec = [SELECT Id, Name FROM Stand__c WHERE Event__c = :eventRec.Id LIMIT 1];
        Account accountRec = [SELECT Id, Name FROM Account LIMIT 1];
        Opportunity oppRec = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Trading_As__c exhibitingAsRec = [SELECT Id, Name FROM Trading_As__c LIMIT 1];


        Co_Exhibitor__c coExhibitorRec = new Co_Exhibitor__c(
            Opportunity__c = oppRec.Id,
            Account__c = accountRec.Id,
            Exhibiting_As__c = exhibitingAsRec.Id,
            Event__c=eventRec.Id,
            Stand__c=standRec.Id,
            Exhibitor_Sync_with_ExpoCAD__c='Creating',
            Details_Synced_with_ExpoCAD__c='Success'
        );
        insert coExhibitorRec;
    

        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ExpocadIntegration expocad = new ExpocadIntegration();

        // Call the method under test
        Test.startTest();
        // HttpResponse mockResponse = expocad.makeGetCallout('https://divcomausb.expocad.com/EdgeApi/eaws20/all');
        ExpocadIntegrationLogic.checkCoExhibitorStatus(coExhibitorRec.Id);
        Test.stopTest();
    }



}