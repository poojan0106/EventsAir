@isTest
public class ExpocadIntegrationTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type','application/json');
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody('{"mockResponse": "This is a mock response"}');
                return res;
        }
    }


    @isTest
    static void testCallout() {
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

        // Create test data for Stand__c
        Stand__c standRec = new Stand__c(
            Name = 'G36',
            ExpoCAD_ID__c = 'G36.' + eventRec.ExpoCAD_ID__c,
            Account_ID__c = accountRec.Id
        );
        insert standRec;
        // Request Body
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(standRec.Name, 'UTF-8') + '&exhibitorId=' + EncodingUtil.urlEncode(standRec.Account_ID__c, 'UTF-8');

                 
        // Set up mock response for GET callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create an instance of ExpocadIntegration
        ExpocadIntegration expocad = new ExpocadIntegration();

        // Make a test GET callout using the mock response
        Test.startTest();
        ExpocadIntegration.getPavilionsByEvent(eventRec.ExpoCAD_ID__c);
        ExpocadIntegration.getBoothByEvent(eventRec.ExpoCAD_ID__c);
        ExpocadIntegration.getBoothByEventAndName(eventRec.ExpoCAD_ID__c , standRec.Name);
        ExpocadIntegration.setBoothToRent(eventRec.ExpoCAD_ID__c, standRec.Name, standRec.Account_ID__c);
        ExpocadIntegration.getExhibitorById(eventRec.ExpoCAD_ID__c , standRec.Account_ID__c);
        ExpocadIntegration.setBoothHold(eventRec.ExpoCAD_ID__c, standRec.Name, standRec.Account_ID__c);
        ExpocadIntegration.setBoothToUnhold(eventRec.ExpoCAD_ID__c, standRec.Name);
        ExpocadIntegration.setBoothToUnrent(eventRec.ExpoCAD_ID__c, standRec.Name, standRec.Account_ID__c);
        ExpocadIntegration.resetBoothDisplayName(eventRec.ExpoCAD_ID__c, standRec.Name);
        ExpocadIntegration.setBoothChildExhibitors(eventRec.ExpoCAD_ID__c, standRec.Name, standRec.Account_ID__c);
        ExpocadIntegration.removeBoothClass(eventRec.ExpoCAD_ID__c, standRec.Name ,'Pavilion Booth');
        ExpocadIntegration.setBoothClass(eventRec.ExpoCAD_ID__c, standRec.Name ,'Pavilion Booth');
        ExpocadIntegration.addNewExhibitor(eventRec.ExpoCAD_ID__c, requestBody);
        Test.stopTest();
    }

}