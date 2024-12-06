@isTest
public class ImportFunRegBatchForLiveEventTest {
    
     static testMethod void testExecuteBatch() {
        // Create a custom Event record for testing
        
        DateTime currentDateTime = System.now();
        Time currentTime = Time.newInstance(currentDateTime.hour(), currentDateTime.minute(), currentDateTime.second(), 0);
        
        Test.setMock(HttpCalloutMock.class, setStaticMock('importfuncregistrationMock'));
         Event__c testEvent = new Event__c(Name = 'Test Event', EventsAirID__c = '12345',Event_Portfolio__c = 'Food',Event_Category__c = 'Naturally Good',Close_Date__c = system.today().addMonths(1),Next_Date__c = null);
        system.debug('testEvent'+testEvent);
        insert testEvent;
        
        System.debug('@@@ testEvent = '+testEvent.Id);
        
        Manage_Eventsair_Fun_Reg_Apex_batch__c meab = new Manage_Eventsair_Fun_Reg_Apex_batch__c();
        meab.Name = 'test vandana';
        meab.Offset__c = 0;
        meab.Is_Execute_Next__c = true;
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
        
        Pricebook2 standardPricebook = new Pricebook2(Id =Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;

        Test.startTest();
        
         // System.schedule(jobName, cronExpression, new FunctionRegLiveEventBatchScheduler());
        ImportFunRegBatchForLiveEvent batchInstance = new ImportFunRegBatchForLiveEvent();
        Database.executeBatch(batchInstance);
        ImportFunRegBatchForLiveEvent.generatestringMethod('Test1','Test2','Test3');
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