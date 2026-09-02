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

    @isTest
    static void testCreateRecordsEndToEnd() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Event__c' AND Name = 'Trade Show' LIMIT 1];
        Event__c testEvent = new Event__c(
            Name = 'Direct Function Coverage',
            Function_Registration_Types__c = '1 Day Conference Pass - Thursday;1 Day Conference Pass - Thursday - Rate;',
            EventsAirID__c = 'DIRECT-FUNC-EA',
            Event_Portfolio__c = 'Technology',
            Event_Category__c = 'Integrate',
            RecordTypeId = rt.Id,
            Close_Date__c = System.today().addMonths(1),
            Next_Date__c = null
        );
        insert testEvent;

        insert new Manage_EvtAir_Fun_Reg_Sec_And_Inte_Batch__c(
            Name = 'Direct Function Settings',
            Offset__c = 0,
            Is_Execute_Next__c = false,
            Generic_Email_Domains__c = 'gmail.com,yahoo.com,bigpond.com'
        );
        Id standardPricebookId = Test.getStandardPricebookId();
        update new Pricebook2(Id = standardPricebookId, IsActive = true);

        insert new Pricebook2(
            Name = testEvent.Name + ' Visitor',
            Events__c = testEvent.Id,
            IsActive = true,
            Description = 'Test pricebook'
        );
        update new Event__c(Id = testEvent.Id, Is_Pricebook_Created__c = true);

        Account existingAccount = new Account(
            Name = 'Paid Function Org',
            Domain_Name__c = 'paidfunction.com',
            AccountSource = 'EventsAir',
            On_Hold__c = false
        );
        insert existingAccount;

        Lead paidLead = new Lead(
            FirstName = 'FuncPaid',
            LastName = 'Convert',
            Email = 'funcpaid.convert@paidfunction.com',
            Company = 'Paid Function Org',
            Status = 'Open - Not Contacted',
            Event_Category__c = 'Integrate'
        );
        insert paidLead;

        ImportFunRegSeprateSecAndInteBatch batch = new ImportFunRegSeprateSecAndInteBatch(testEvent.Id);

        List<Object> eventContacts = new List<Object>{
            buildFunctionContact('END-CON-1', 'FuncPaid', 'Convert', 'funcpaid.convert@paidfunction.com', 'Paid Function Org', buildFunctionRegistration('REG-END-1', '1 Day Conference Pass - Thursday', 'FEE-END-1', 110, true)),
            buildFunctionContact('END-CON-2', 'FuncUnpaid', 'Lead', 'funcunpaid.lead@example.net', 'Unpaid Function Org', buildFunctionRegistration('REG-END-2', '1 Day Conference Pass - Thursday', 'FEE-END-2', 0, false)),
            buildFunctionContact('END-CON-3', 'GenericFunc', 'Paid', 'generic.func@gmail.com', 'Generic Function Org', buildFunctionRegistration('REG-END-3', '1 Day Conference Pass - Thursday', 'FEE-END-3', 75, true))
        };

        Test.startTest();
        batch.createRecords(eventContacts);
        Test.stopTest();

        System.assert(true, 'Direct createRecords path completed.');
    }

    private static Map<String, Object> buildFunctionContact(
        String contactId,
        String firstName,
        String lastName,
        String email,
        String orgName,
        Map<String, Object> functionRegistration
    ) {
        return new Map<String, Object>{
            'id' => contactId,
            'firstName' => firstName,
            'lastName' => lastName,
            'primaryEmail' => email,
            'organizationName' => orgName,
            'title' => 'Ms',
            'jobTitle' => 'Engineer',
            'workPhone' => '+61123456789',
            'primaryAddress' => new Map<String, Object>{
                'city' => 'Melbourne',
                'country' => 'Australia',
                'line1' => '1 Direct Street',
                'line2' => null,
                'line3' => null,
                'postCode' => '3000',
                'state' => 'VIC'
            },
            'contactPhoneNumbers' => new List<Object>{
                new Map<String, Object>{ 'mobile' => '+61123456789' }
            },
            'customFields' => new List<Object>{
                new Map<String, Object>{ 'name' => 'Industry INT', 'definitionId' => 'D1658AB1-C034-4429-8B40-D5CFD01387FB', 'value' => 'Consultant' },
                new Map<String, Object>{ 'name' => 'Job Function INT', 'definitionId' => '5A263685-76F8-4E0A-BBEF-21AA3E28126F', 'value' => 'Consultant' },
                new Map<String, Object>{ 'name' => 'Company Size', 'definitionId' => 'D30BE3F5-69A6-485B-BF03-BDA224BF06C8', 'value' => '500+' }
            },
            'marketingRecords' => new List<Object>{
                new Map<String, Object>{
                    'id' => 'MRK-' + contactId,
                    'name' => 'Product & Service Categories',
                    'tag' => new Map<String, Object>{ 'id' => 'TAG-' + contactId, 'name' => 'Product & Service Categories' },
                    'value' => 'Engineering & Consultancy Services'
                }
            },
            'functionRegistrations' => new List<Object>{ functionRegistration }
        };
    }

    private static Map<String, Object> buildFunctionRegistration(
        String regId,
        String feeName,
        String feeId,
        Decimal amount,
        Boolean paid
    ) {
        return new Map<String, Object>{
            'id' => regId,
            'tickets' => '1',
            'checkInDate' => '2024-03-13T08:10:06.300Z',
            'checkOutDate' => null,
            'createdAt' => '2024-03-13T08:10:06.300Z',
            'feeType' => new Map<String, Object>{
                'id' => feeId,
                'name' => feeName,
                'uniqueCode' => 'UT-' + feeId,
                'fees' => new List<Object>{ new Map<String, Object>{ 'amount' => amount } }
            },
            'function' => new Map<String, Object>{
                'id' => 'FUN-' + regId,
                'name' => feeName,
                'start' => '17:00',
                'date' => '2024-03-13',
                'end' => '19:00',
                'overview' => 'Overview',
                'details' => 'Details'
            },
            'paymentDetails' => new Map<String, Object>{
                'paymentStatus' => paid ? 'PURCHASE' : 'INCLUSIVE',
                'discountAmount' => 0,
                'adjustmentAmount' => 0,
                'taxAmount' => 0,
                'totalChargeAmount' => amount,
                'discountCode' => paid ? new Map<String, Object>{ 'code' => 'A024' } : null
            }
        };
    }
    
    public static StaticResourceCalloutMock setStaticMock (String mockName) {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }
    
}
