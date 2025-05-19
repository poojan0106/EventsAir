@isTest
public class ImportFunRegSeprateSecAndInteLiveTest {
    @isTest
    static void testExecuteSepBatch(){
        Test.setMock(HttpCalloutMock.class, setStaticMock('importfuncregistrationMock'));
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Event__c' AND Name ='Trade Show' LIMIT 1];
        
        Event__c testEvent = new Event__c(
            Name = 'Test Event',
            Registration_Types__c='Speaker;Security Exhibitor;Security Media;Security Stand Coordinator', 
            Function_Registration_Types__c ='1 Day Conference Pass - Thursday;1 Day Conference Pass - Thursday - Rate;',
            EventsAirID__c = '12345',
            Event_Portfolio__c = 'Food',
            Event_Category__c = 'Naturally Good',
            Close_Date__c = system.today().addMonths(1),
            Next_Date__c = null 
        );
        system.debug('testEvent'+testEvent);
        insert testEvent;
        
        ManageEvtAir_FunReg_SecAndInt_Live_Batch__c meab = new ManageEvtAir_FunReg_SecAndInt_Live_Batch__c();
        meab.Name = 'test vandana';
        meab.Offset__c = 0;
        meab.Is_Execute_Next__c = false;
        meab.Generic_Email_Domains__c = 'gmail.com,yahoo.com,bigpond.com';
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
        
        Registration__c registrationRec= new Registration__c();
        registrationRec.Event__c=testEvent.Id;
        registrationRec.Lead__c = ld.id;
        registrationRec.Registration_Type__c = 'Business Summit - Early Bird';
        insert registrationRec;
        
        Pricebook2 standardPricebook = new Pricebook2(Id =Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;
        
        String eventId = testEvent.Id;
        ImportFunRegSeprateSecAndInteLiveBatch batch = new ImportFunRegSeprateSecAndInteLiveBatch();
        Database.executeBatch(batch);
    }
    
    @isTest
    static void testExecuteSepBatch1(){
        Test.setMock(HttpCalloutMock.class, setStaticMock('importfuncregistrationMock'));
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Event__c' AND Name ='Trade Show' LIMIT 1];
        
        Event__c testEvent = new Event__c(
            Name = 'Test Event',
            Registration_Types__c='Speaker;Security Exhibitor;Security Media;Security Stand Coordinator', 
            Function_Registration_Types__c ='1 Day Conference Pass - Thursday;1 Day Conference Pass - Thursday - Rate;',
            EventsAirID__c = '12345',
            Event_Portfolio__c = 'Food',
            Event_Category__c = 'Naturally Good',
            Close_Date__c = system.today().addMonths(1),
            Next_Date__c = null 
        );
        system.debug('testEvent'+testEvent);
        insert testEvent;
        
        ManageEvtAir_FunReg_SecAndInt_Live_Batch__c meab = new ManageEvtAir_FunReg_SecAndInt_Live_Batch__c();
        meab.Name = 'test vandana';
        meab.Offset__c = 0;
        meab.Is_Execute_Next__c = false;
        meab.Generic_Email_Domains__c = 'gmail.com,yahoo.com,bigpond.com';
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
        
        contact con1 = new Contact();
        con1.Email = 'Joachim@acewt.com';
        con1.FirstName = 'Joachim';
        con1.LastName = 'Aakesson';
        con1.AccountId = acc.Id;
        insert con1;
        
        lead ld = new lead();
        ld.FirstName = 'Fname';
        ld.LastName = 'Lname';
        ld.Email = 'vandana@gmail.com';
        ld.Event_Category__c = 'Naturally Good';
        ld.Company = 'Unknown';
        insert ld;
        
        Registration__c registrationRec= new Registration__c();
        registrationRec.Event__c=testEvent.Id;
        registrationRec.Lead__c = ld.id;
        registrationRec.Registration_Type__c = 'Business Summit - Early Bird';
        insert registrationRec;
        
        Pricebook2 standardPricebook = new Pricebook2(Id =Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;
        
        String eventId = testEvent.Id;
        ImportFunRegSeprateSecAndInteLiveBatch batch = new ImportFunRegSeprateSecAndInteLiveBatch();
        Database.executeBatch(batch);
    }
    
    @isTest
    static void testExecuteSepBatch2(){
        Test.setMock(HttpCalloutMock.class, setStaticMock('importfuncregistrationMock'));
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Event__c' AND Name ='Trade Show' LIMIT 1];
        
        Event__c testEvent = new Event__c(
            Name = 'Test Event',
            Registration_Types__c='Speaker;Security Exhibitor;Security Media;Security Stand Coordinator', 
            Function_Registration_Types__c ='1 Day Conference Pass - Thursday;1 Day Conference Pass - Thursday - Rate;',
            EventsAirID__c = '12345',
            Event_Portfolio__c = 'Food',
            Event_Category__c = 'Naturally Good',
            Close_Date__c = system.today().addMonths(1),
            Next_Date__c = null 
        );
        system.debug('testEvent'+testEvent);
        insert testEvent;
        
        ManageEvtAir_FunReg_SecAndInt_Live_Batch__c meab = new ManageEvtAir_FunReg_SecAndInt_Live_Batch__c();
        meab.Name = 'test vandana';
        meab.Offset__c = 0;
        meab.Is_Execute_Next__c = false;
        meab.Generic_Email_Domains__c = 'gmail.com,yahoo.com,bigpond.com';
        //meab.Total_Contacts__c = 10;
        insert meab;
        
        Account acc = new Account();
        acc.Name = 'Test account - 2';
        acc.Domain_Name__c = 'gmail.com';
        insert acc;
        
        
        
        lead ld1 = new lead();
        ld1.FirstName = 'Fname';
        ld1.LastName = 'Lname';
        ld1.Email = 'vandana@gmail.com';
        ld1.Event_Category__c = 'Naturally Good';
        ld1.Company = 'Unknown';
        insert ld1;
        
        lead ld = new lead();
        ld.Email = 'Joachim@acewt.com';
        ld.FirstName = 'Joachim';
        ld.LastName = 'Aakesson';
        ld.Event_Category__c = 'Naturally Good';
        ld.Company = 'Unknown';
        insert ld;
        
        contact con = new Contact();
        con.Email = 'vandana@gmail.com';
        con.FirstName = 'Fname';
        con.LastName = 'Lname';
        con.AccountId = acc.Id;
        insert con;
        
        
        Registration__c registrationRec= new Registration__c();
        registrationRec.Event__c=testEvent.Id;
        registrationRec.Lead__c = ld.id;
        registrationRec.Registration_Type__c = 'Business Summit - Early Bird';
        insert registrationRec;
        
        Pricebook2 standardPricebook = new Pricebook2(Id =Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;
        
        String eventId = testEvent.Id;
        ImportFunRegSeprateSecAndInteLiveBatch batch = new ImportFunRegSeprateSecAndInteLiveBatch();
        Database.executeBatch(batch);
        
        ImportFunRegSeprateSecAndInteLiveSch sch = new ImportFunRegSeprateSecAndInteLiveSch();
        sch.execute(null);
    }
    
    
    @isTest
    static void testExecuteSepBatch3(){
        Test.setMock(HttpCalloutMock.class, setStaticMock('importfuncregistrationMock'));
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Event__c' AND Name ='Trade Show' LIMIT 1];
        
        Event__c testEvent = new Event__c(
            Name = 'Test Event',
            Registration_Types__c='Speaker;Security Exhibitor;Security Media;Security Stand Coordinator', 
            Function_Registration_Types__c ='1 Day Conference Pass - Thursday;1 Day Conference Pass - Thursday - Rate;',
            EventsAirID__c = '12345',
            Event_Portfolio__c = 'Food',
            Event_Category__c = 'Naturally Good',
            Close_Date__c = system.today().addMonths(1),
            Next_Date__c = null 
        );
        system.debug('testEvent'+testEvent);
        insert testEvent;
        
        ManageEvtAir_FunReg_SecAndInt_Live_Batch__c meab = new ManageEvtAir_FunReg_SecAndInt_Live_Batch__c();
        meab.Name = 'test vandana';
        meab.Offset__c = 0;
        meab.Is_Execute_Next__c = false;
        meab.Generic_Email_Domains__c = 'gmail.com,yahoo.com,bigpond.com';
        //meab.Total_Contacts__c = 10;
        insert meab;
        
        Account acc = new Account();
        acc.Name = 'Test account - 2';
        acc.Domain_Name__c = 'gmail.com';
        insert acc;        
        
        lead ld1 = new lead();
        ld1.FirstName = 'Fname';
        ld1.LastName = 'Lname';
        ld1.Email = 'vandana@gmail.com';
        ld1.Event_Category__c = 'Naturally Good';
        ld1.Company = 'Unknown';
        insert ld1;
        
        lead ld = new lead();
        ld.Email = 'anna.aase@dof.com';
        ld.FirstName = 'Anna';
        ld.LastName = 'Aase';
        ld.Event_Category__c = 'Naturally Good';
        ld.Company = 'Unknown';
        insert ld;
        
        Registration__c registrationRec= new Registration__c();
        registrationRec.Event__c=testEvent.Id;
        registrationRec.Lead__c = ld1.id;
        registrationRec.Registration_Type__c = 'Business Summit - Early Bird';
        insert registrationRec;
        
        Pricebook2 standardPricebook = new Pricebook2(Id =Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;
        
        String eventId = testEvent.Id;
        ImportFunRegSeprateSecAndInteLiveBatch batch = new ImportFunRegSeprateSecAndInteLiveBatch();
        Database.executeBatch(batch);
    }
    
    
    
    public static StaticResourceCalloutMock setStaticMock (String mockName) {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }
}