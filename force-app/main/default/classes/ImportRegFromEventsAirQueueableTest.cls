@isTest
public class ImportRegFromEventsAirQueueableTest {
    
    @isTest
    static  void testExecuteQueable() {
        Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMock'));
        
		date today = system.today();     
        Event__c testEvent = new Event__c(Name = 'Test Event', EventsAirID__c = '12345',Event_Portfolio__c = 'Food', Is_Ready_To_Proceed__c = true,Close_Date__c =today.addDays(1));
        insert testEvent;
        System.debug('@@@ testEvent = '+testEvent.Id);
        
        Manage_Eventsair_Apex_batch_All_Events__c meab = new Manage_Eventsair_Apex_batch_All_Events__c();
        meab.Name = 'test vandana';
        meab.Offset__c = 0;
        meab.Is_Execute_Next__c = true;
        insert meab;
        
         Account acct = new Account();
        acct.Name = 'Test account - 2';
        acct.Domain_Name__c = 'gmail.com';
        insert acct;
        
        contact con = new Contact();
        con.Email = 'vandana@gmail.com';
        con.FirstName = 'Fname';
        con.LastName = 'Lname';
        con.AccountId = acct.Id;
        insert con;
        
        List<Pricebook2> objPricebook = [SELECT Id,Name FROM Pricebook2 WHERE isStandard = true];
        //insert objPricebook;
        system.debug('objPricebook'+objPricebook);
        
        Pricebook2 pb1 = new Pricebook2();
        pb1.Name = 'vandanaTest';
        pb1.Events__c = testEvent.id;
        insert pb1;
        
        List<Pricebook2> lstofpricebook = new List<Pricebook2>();
        
        Pricebook2 pb = new Pricebook2();
        pb.Name = 'vandanaTest';
        pb.Events__c = testEvent.id;
        // pb.isStandard = true;
        lstofpricebook.add(pb);
        insert lstofpricebook;
        
        Pricebook2 standardPricebook = new Pricebook2(Id =Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;
        
        
        
        PriceBook2  objPricebook2= new PriceBook2();
        objPricebook2.Name='Standard Price Book1';
        objPricebook2.IsActive=true;
        insert objPricebook2;
        List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: testEvent.id];
        system.debug('lstPriceook'+lstPriceook);
        
        
        Product2 newProduct = new Product2();
        newProduct.Name = 'test product';
        newProduct.EventsAir_ID__c = '12345';
        // newProduct.ProductCode = (String) eventregtypemap.get('uniqueCode');
        newProduct.Description = 'This is a product from eventsair';
        newProduct.IsActive = true;
        newProduct.Family = 'Sample Family';
        // newProduct.IsActive = true;  
        insert newProduct;
        
        PricebookEntry pbEntry2 = new PricebookEntry();
        pbEntry2.Pricebook2Id = Test.getStandardPricebookId();
        pbEntry2.Product2Id = newProduct.id;                        
        pbEntry2.UnitPrice = 100;
        pbEntry2.IsActive = true;
        pbEntry2.UseStandardPrice = false;
        insert pbEntry2;
        
        Account acc = new Account(Name='Test Account');
        insert acc;
        ApexPages.StandardController standardController = new ApexPages.StandardController(acc);
        
        
        
        
        
        Id standardPB = Test.getStandardPricebookId();
        Test.startTest();
        ImportRegistrationForAllEventsController controllerInstance = new ImportRegistrationForAllEventsController(standardController);
        controllerInstance.executeQueueable();
        ImportRegistartionFromEventsAirQueueable job = new ImportRegistartionFromEventsAirQueueable();
        System.enqueueJob(job);
        Test.stopTest();
    }
    
    
    @isTest
    static void testQueueableClass() {
        Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMock'));
        Event__c testEvent = new Event__c(
            Is_Ready_To_Proceed__c = false,
            EventsAirID__c = 'test123',
            Event_Portfolio__c = 'Food',
            Close_Date__c = System.today() + 1
        );
        insert testEvent;
        
        // Enqueue the queueable class
        Test.startTest();
        System.enqueueJob(new ImportRegistartionFromEventsAirQueueable());
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