@isTest
public class UpdateRegAndConForDivcomEventsTest {
    
      static testMethod void testExecuteBatch() {
        // Create a custom Event record for testing
        
		 Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMock'));
               RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Event__c' AND Name = 'Trade Show' LIMIT 1];

        Event__c testEvent = new Event__c(Name = 'Test Event', EventsAirID__c = '12345',RecordTypeId = rt.Id,Event_Portfolio__c = 'Food',Event_Category__c = 'Naturally Good',Is_Pricebook_Created__c=false );
        system.debug('testEvent'+testEvent);
        insert testEvent;
        
        Manage_Eventsair_Reg_Apex_batch__c meab = new Manage_Eventsair_Reg_Apex_batch__c();
        meab.Name = 'test vandana';
        meab.Offset__c = 0;
        meab.Is_Execute_Next__c = true;
        //meab.Total_Contacts__c = 10;
        insert meab;
        
         Account acc = new Account();
        acc.Name = 'Test account - 2';
        acc.Domain_Name__c = 'gmail.com';
        insert acc;
        Account acc1 = new Account();
        acc1.Name = 'Cleanup Services';
        insert acc1;
        
        contact con = new Contact();
        con.Email = 'vandana@gmail.com';
        con.FirstName = 'Fname';
        con.LastName = 'Lname';
        con.AccountId = acc.Id;
        insert con;
        
        lead ld = new lead();
        ld.FirstName = 'Fname';
        ld.LastName = 'Lname';
        ld.Email = 'vandana@gmail.com';
        ld.Event_Category__c = 'Naturally Good';
        ld.Company = 'Unknown';
        insert ld;
        // Pricebook2 pb1 = new Pricebook2();
        Pricebook2 standardPricebook = new Pricebook2(Id =Test.getStandardPricebookId(),IsActive = true);
		update standardPricebook;
        
      
        
          

        Test.startTest();
        //UpdateImportRegistartionController controllerInstance = new UpdateImportRegistartionController(controller);
        Database.executeBatch(new UpdateRegistartionsAndConForDivcomEvents(testEvent.EventsAirID__c, testEvent.Id), 100);
        //PageReference resultPage = controllerInstance.executeBatch();
        Test.stopTest();
  }
  static testMethod void testAuthentication(){
    Test.setMock(HttpCalloutMock.class, new MockHttpResponse());  
    Token_Request_Information__c customSetting = new Token_Request_Information__c(
            Name = 'AccessToken Information',
            EndPoint__c = 'https://example.com/token',
            Grant_Type__c = 'client_credentials',
            Scope__c = 'some_scope',
            Client_Id__c = 'client_id',
            Client_Secret__c = 'client_secret'
        );
        insert customSetting;

    Test.startTest();
    String accessToken = EventsAirOAuthTokenRequest.getAccessToken('trade');
    Test.stopTest();

  }
    
    public static StaticResourceCalloutMock setStaticMock (String mockName) {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"mock_access_token"}');
            res.setStatusCode(200);
            return res;
        }
    }

}