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
        
        
        Pricebook2 pb1 = new Pricebook2();
        pb1.Name = 'vandanaTest';
        pb1.Events__c = testEvent.id;
        insert pb1;
        
        List<Pricebook2> lstofpricebook = new List<Pricebook2>();
        
        Pricebook2 pb = new Pricebook2();
        pb.Name = 'vandanaTest';
        // pb.Events__c = testEvent.id;
        //pb.isStandard = true;
        lstofpricebook.add(pb);
        insert lstofpricebook;
        
        Pricebook2 standardPricebook = new Pricebook2(Id =Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;
        
        Product2 objProduct2=new Product2();
        objProduct2.Name='SSP - Comprehensive - E';
        objProduct2.ProductCode = 'Pro-D';
        insert objProduct2;
        
        List<Pricebook2> objPricebook = [Select id,Name from PriceBook2 where isStandard =: true];
        Id standardPB = Test.getStandardPricebookId();  
        
        PricebookEntry objpricebookentry =new PricebookEntry();
        objpricebookentry.Product2ID = objProduct2.id;
        objpricebookentry.UnitPrice=23.50;
        objpricebookentry.UseStandardPrice=false;
        objpricebookentry.Pricebook2ID=standardPB;
        objpricebookentry.isActive=true;
        insert objpricebookentry;
         
          // Schedule the batch job
        String jobName = 'Test Function Registration Batch Job';
        String cronExpression = '0 0 */2 * * ?'; // Every 2 hours
        
         
        
        Test.startTest();
        
          System.schedule(jobName, cronExpression, new FunctionRegLiveEventBatchScheduler());
        ImportFunRegBatchForLiveEvent batchInstance = new ImportFunRegBatchForLiveEvent();
        Database.executeBatch(batchInstance);
        ImportFuncRegistartionFromEventsAirBatch.isValidEmail('Vandana@resonantcloud.info');
        ImportFuncRegistartionFromEventsAirBatch.generatestringMethod('Test1','Test2','Test3');
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