@isTest
public class ImportFunRegistartionbatchTest {
    
    static testMethod void testExecuteBatch() {
        // Create a custom Event record for testing
        
        DateTime currentDateTime = System.now();
        Time currentTime = Time.newInstance(currentDateTime.hour(), currentDateTime.minute(), currentDateTime.second(), 0);
        
        Test.setMock(HttpCalloutMock.class, setStaticMock('importfuncregistrationMock'));
        Event__c testEvent = new Event__c(Name = 'Test Event', EventsAirID__c = '12345',Event_Portfolio__c = 'Food', Batch_Execution_Time__c = currentTime,Event_Category__c = 'Foodpro');
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
        ld.Event_Category__c = 'Foodpro';
        ld.Company = 'Unknown';
        insert ld;

        Id standardPricebookId = Test.getStandardPricebookId();

          ApexPages.StandardController controller = new ApexPages.StandardController(testEvent);

        ImportFunctionRegistartionController controllerInstance = new ImportFunctionRegistartionController(controller);
        
        
        Test.startTest();
        
         PageReference resultPage = controllerInstance.executeBatch();
        ImportFuncRegistartionFromEventsAirBatch.generatestringMethod('Test1','Test2','Test3');
        Test.stopTest();
    }

    @isTest
    static void testStateCountryBackfillRequiresCoreFieldsBlank() {
        Map<String, Object> eventContactMap = buildEventContactAddress();

        Contact blankContact = new Contact();
        ImportFuncRegistartionFromEventsAirBatch.applyStateCountryFields(blankContact, eventContactMap);
        System.assertEquals(null, blankContact.MailingCity, 'Contact city should not be filled by state/country backfill.');
        System.assertEquals('Australia', blankContact.MailingCountry, 'Blank contact country should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankContact.MailingStreet, 'Contact street should not be filled by state/country backfill.');
        System.assertEquals('VIC', blankContact.MailingState, 'Blank contact state should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankContact.MailingPostalCode, 'Contact postal code should not be filled by state/country backfill.');

        Contact contactWithCity = new Contact(MailingCity = 'Melbourne');
        ImportFuncRegistartionFromEventsAirBatch.applyStateCountryFields(contactWithCity, eventContactMap);
        System.assertEquals(null, contactWithCity.MailingCountry, 'Contact country should not be filled when city exists.');
        System.assertEquals(null, contactWithCity.MailingState, 'Contact state should not be filled when city exists.');

        Lead blankLead = new Lead();
        ImportFuncRegistartionFromEventsAirBatch.applyStateCountryFields(blankLead, eventContactMap);
        System.assertEquals(null, blankLead.City, 'Lead city should not be filled by state/country backfill.');
        System.assertEquals('Australia', blankLead.Country, 'Blank lead country should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankLead.Street, 'Lead street should not be filled by state/country backfill.');
        System.assertEquals('VIC', blankLead.State, 'Blank lead state should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankLead.PostalCode, 'Lead postal code should not be filled by state/country backfill.');

        Lead leadWithStreet = new Lead(Street = '1 Test Street');
        ImportFuncRegistartionFromEventsAirBatch.applyStateCountryFields(leadWithStreet, eventContactMap);
        System.assertEquals(null, leadWithStreet.Country, 'Lead country should not be filled when street exists.');
        System.assertEquals(null, leadWithStreet.State, 'Lead state should not be filled when street exists.');
    }

    @isTest
    static void testRegistrationLinkHelpersCoverExistingRows() {
        Event__c testEvent = new Event__c(
            Name = 'Function Helper Coverage Event',
            EventsAirID__c = 'FUNC-COV-EVENT',
            Event_Portfolio__c = 'Food',
            Event_Category__c = 'Foodpro'
        );
        insert testEvent;

        Registration__c registrationRecord = new Registration__c(
            RecordTypeId = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Registration').getRecordTypeId(),
            Event__c = testEvent.Id,
            EventsAir_Regisration_ID__c = 'FUNC-COV-REG-1',
            Payment_Status__c = 'PURCHASE',
            Date_Registered__c = System.now()
        );
        insert registrationRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = 'Function Helper Coverage Opportunity',
            StageName = 'ClosedWon',
            CloseDate = Date.today(),
            Event__c = testEvent.Id
        );
        insert opportunityRecord;

        OpportunityLineItem oli = new OpportunityLineItem(
            Function_Registration_Id__c = 'FUNC-COV-REG-1',
            OpportunityId = opportunityRecord.Id
        );

        Test.startTest();
        ImportFuncRegistartionFromEventsAirBatch.UpdateRegistrationsOLI(new List<OpportunityLineItem>{ oli });
        new ImportFuncRegistartionFromEventsAirBatch(testEvent.EventsAirID__c, testEvent.Id)
            .LinkFunctionToRegistration(new List<Registration__c>{
                new Registration__c(Id = registrationRecord.Id, EventsAir_Function_Id__c = 'FUNC-COV-NO-MATCH')
            });
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Registration__c WHERE Id = :registrationRecord.Id],
            'Registration helper test should keep the seeded registration available.'
        );
    }

    @isTest
    static void testCreateRecordsEndToEnd() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Event__c' AND Name = 'Trade Show' LIMIT 1];
        Event__c testEvent = new Event__c(
            Name = 'Direct Function Coverage',
            EventsAirID__c = 'DIRECT-FUNC-EA',
            RecordTypeId = rt.Id,
            Event_Portfolio__c = 'Technology',
            Event_Category__c = 'Integrate',
            Close_Date__c = System.today().addMonths(1),
            Next_Date__c = null
        );
        insert testEvent;

        insert new Manage_Eventsair_Fun_Reg_Apex_batch__c(
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

        ImportFuncRegistartionFromEventsAirBatch batch = new ImportFuncRegistartionFromEventsAirBatch(testEvent.EventsAirID__c, testEvent.Id);
        batch.eventCategory = 'Integrate';

        Test.startTest();
        batch.createRecords(new List<Object>{
            buildFunctionContact('END-CON-1', 'FuncPaid', 'Convert', 'funcpaid.convert@paidfunction.com', 'Paid Function Org', buildFunctionRegistration('REG-END-1', '1 Day Conference Pass - Thursday', 'FEE-END-1', 110, true)),
            buildFunctionContact('END-CON-2', 'FuncUnpaid', 'Lead', 'funcunpaid.lead@example.net', 'Unpaid Function Org', buildFunctionRegistration('REG-END-2', '1 Day Conference Pass - Thursday', 'FEE-END-2', 0, false)),
            buildFunctionContact('END-CON-3', 'GenericFunc', 'Paid', 'generic.func@gmail.com', 'Generic Function Org', buildFunctionRegistration('REG-END-3', '1 Day Conference Pass - Thursday', 'FEE-END-3', 75, true))
        });
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Registration__c WHERE EventsAir_Regisration_ID__c IN ('REG-END-1','REG-END-2','REG-END-3')] > 0, 'Function registrations should be inserted or updated.');
    }

    private static Map<String, Object> buildEventContactAddress() {
        return new Map<String, Object>{
            'primaryAddress' => new Map<String, Object>{
                'city' => 'Melbourne',
                'country' => 'Australia',
                'line1' => '1 Test Street',
                'line2' => 'Suite 2',
                'line3' => 'Level 3',
                'postCode' => '3000',
                'state' => 'VIC'
            }
        };
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
            'primaryAddress' => buildEventContactAddress().get('primaryAddress'),
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
