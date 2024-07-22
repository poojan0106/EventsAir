@isTest
public with sharing class ImportRegSeprateSecAndInteBatchTest {
    
    static testMethod void testExecuteBatch() {
        // Create a custom Event record for testing
        
		 Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMock'));
       
        Event__c testEvent = new Event__c(Name = 'Test Event',Registration_Types__c='Speaker Registration', EventsAirID__c = '12345',Event_Portfolio__c = 'Food',Event_Category__c = 'Naturally Good' );
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
        
         ApexPages.StandardController controller = new ApexPages.StandardController(testEvent);

		ImportRegSeprateSecAndIntController controllerInstance =  new ImportRegSeprateSecAndIntController(controller);
        Database.executeBatch(new ImportRegSeprateSecAndInteBatch(testEvent.EventsAirID__c, testEvent.Id),500);
        
       Test.startTest();
        
        PageReference resultPage = controllerInstance.executeBatch();
        Test.stopTest();
       
  }
    
    public static StaticResourceCalloutMock setStaticMock (String mockName) {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }
}