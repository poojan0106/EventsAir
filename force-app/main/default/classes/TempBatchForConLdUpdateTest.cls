@isTest
public class TempBatchForConLdUpdateTest {
    static testMethod void testExecuteBatch() {
        // Create a custom Event record for testing
        
		 Test.setMock(HttpCalloutMock.class, setStaticMock('importfuncregistrationMock'));
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Event__c' AND Name = 'Trade Show' LIMIT 1];

       
        Event__c testEvent = new Event__c(Name = 'Test Event', EventsAirID__c = '12345',Event_Portfolio__c = 'Food',Event_Category__c = 'Naturally Good',RecordTypeId = rt.Id,Close_Date__c = system.today().addMonths(1),Next_Date__c = null );
        system.debug('testEvent'+testEvent);
        insert testEvent;
        
     
        
        Manage_Eventsair_Con_Lead_Updt_batch__c meab = new Manage_Eventsair_Con_Lead_Updt_batch__c();
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
        con.Email = 'ala.chemeng@gmail.com';
        con.FirstName = 'Arsalan';
        con.LastName = 'A. Ghavanini';
        con.AccountId = acc.Id;
       
        insert con;
        
        lead ld = new lead();
        ld.FirstName = 'Jarle';
        ld.LastName = 'Aakermann';
        ld.Email = 'jaa@dan-bunkering.com';
        ld.Event_Category__c = 'Naturally Good';
        ld.Company = 'Unknown';
         
        insert ld;
        
           Registration__c registrationRec= new Registration__c();
         registrationRec.Event__c=testEvent.Id;
        registrationRec.Lead__c = ld.id;
         insert registrationRec;
        
        Test.startTest();
       // System.schedule(jobName, cronExpression, new ImportFunRegSepSecAndInteBatchscheduler());
        TempBatchForConLdUpdate batchInstance = new TempBatchForConLdUpdate(testEvent.id);
        Database.executeBatch(batchInstance);
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