@isTest
public class ImportFunRegSeprateSecAndInteBatchTest {
    static testMethod void testExecuteBatch() {
        // Create a custom Event record for testing
        
        Test.setMock(HttpCalloutMock.class, setStaticMock('importfuncregistrationMock'));
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Event__c' AND Name = 'Trade Show' LIMIT 1];
        
        
        Event__c testEvent = new Event__c(Name = 'Test Event',Function_Registration_Types__c='1 x Session Pass', EventsAirID__c = '12345',Event_Portfolio__c = 'Food',Event_Category__c = 'Naturally Good',RecordTypeId = rt.Id,Close_Date__c = system.today().addMonths(1),Next_Date__c = null );
        system.debug('testEvent'+testEvent);
        insert testEvent;
        
        Manage_EvtAir_Fun_Reg_Sec_And_Inte_Batch__c meab = new Manage_EvtAir_Fun_Reg_Sec_And_Inte_Batch__c();
        meab.Name = 'test vandana';
        meab.Offset__c = 0;
        meab.Is_Execute_Next__c = true;
        meab.Generic_Email_Domains__c = 'gmail.com,yahoo.com,bigpond.com';
        //meab.Total_Contacts__c = 10;
        insert meab;
        
        Account acc = new Account();
        acc.Name = 'Test account - 2';
        acc.Domain_Name__c = 'gmail.com';
        insert acc;
        
        Pricebook2 standardPricebook = new Pricebook2(Id =Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;
        
        contact con = new Contact();
        con.Email = 'anna.aase@dof.com';
        con.FirstName = 'Anna';
        con.LastName = 'Aase';
        con.AccountId = acc.Id;
        insert con;
        
        lead ld = new lead();
        ld.FirstName = 'Asfand Fida';
        ld.LastName = 'Abbasi';
        ld.Email = 'asfandfida@gmail.com';
        ld.Event_Category__c = 'Naturally Good';
        ld.Company = 'Unknown';
        insert ld;
        
        Registration__c registrationRec= new Registration__c();
        registrationRec.Event__c=testEvent.Id;
        registrationRec.Lead__c = ld.id;
        registrationRec.Registration_Type__c = 'Business Summit - Early Bird';
        insert registrationRec;
        
        String jobName = 'Test Registration Batch Job';
        String cronExpression = '0 0 */2 * * ?'; // Every 2 hours
        Decimal totalcharge = 100;
        
        ApexPages.StandardController standardController = new ApexPages.StandardController(testEvent);
        Test.startTest();
        
         ImportFunRegSeprateSecAndIntController controllerInstance = new ImportFunRegSeprateSecAndIntController(standardController);
        controllerInstance.executeBatch();
        ImportFunRegSeprateSecAndInteBatch batchInstance = new ImportFunRegSeprateSecAndInteBatch(testEvent.Id);
        Database.executeBatch(batchInstance);
         //System.schedule(jobName, cronExpression, new ImportFunRegSepSecAndInteBatchscheduler());
         //ImportFunRegSepSecAndInteBatchscheduler sch = new ImportFunRegSepSecAndInteBatchscheduler();
         // sch.execute(); 
        // System.schedule(jobName, cronExpression, new ImportFunRegSepSecAndInteBatchscheduler());
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