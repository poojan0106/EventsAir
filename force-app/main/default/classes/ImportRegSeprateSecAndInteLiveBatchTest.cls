@isTest
public class ImportRegSeprateSecAndInteLiveBatchTest {
    @isTest
    static void getRegAndLiveBatchData(){
        Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMock'));
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Event__c' AND Name ='Trade Show' LIMIT 1];
        
        
        Event__c testEvent = new Event__c(Name = 'Test Event',Registration_Types__c='Security Exhibitor;Security Media;Security Stand Coordinator', EventsAirID__c = '12345',Event_Portfolio__c = 'Food',Event_Category__c = 'Naturally Good',Close_Date__c = system.today().addMonths(1),Next_Date__c = null );
        system.debug('testEvent'+testEvent);
        insert testEvent;
        
        Manage_EvtAir_Sec_Inte_Reg_Live_Batch__c meab = new Manage_EvtAir_Sec_Inte_Reg_Live_Batch__c();
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
        
        Opportunity opp = new Opportunity(Name = 'Test opp', StageName = 'ClosedWon', CloseDate = System.today(), Event__c =testEvent.Id);
        insert opp;
        
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
        
        Test.startTest();
        ImportRegSeprateSecAndInteLiveBatch batch  = new ImportRegSeprateSecAndInteLiveBatch();
        Database.executeBatch(batch);
        
        
        ImportRegSeprateSecAndInteLiveBatchSch sch = new ImportRegSeprateSecAndInteLiveBatchSch();
        sch.execute(null);
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