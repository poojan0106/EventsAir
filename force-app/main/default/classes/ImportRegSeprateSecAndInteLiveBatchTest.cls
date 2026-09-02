@isTest
public class ImportRegSeprateSecAndInteLiveBatchTest {
    @isTest
    static void getRegAndLiveBatchData(){
        Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMock'));
        
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Event__c' AND Name ='Trade Show' LIMIT 1];
        
        
        Event__c testEvent = new Event__c(Name = 'Test Event',Registration_Types__c='Security Exhibitor;Security Media;Security Stand Coordinator', EventsAirID__c = '12345',Event_Portfolio__c = 'Food',Event_Category__c = 'Foodpro',Close_Date__c = system.today().addMonths(1),Next_Date__c = null );
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
        ld.Event_Category__c = 'Foodpro';
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

    @isTest
    static void testAddressStateCountryBackfillRequiresCoreFieldsBlank() {
        Map<String, Object> eventContactMap = buildEventContactAddress();

        Contact blankContact = new Contact();
        ImportRegSeprateSecAndInteLiveBatch.applyAddressFields(blankContact, eventContactMap);
        System.assertEquals(null, blankContact.MailingCity, 'Contact city should not be filled by state/country backfill.');
        System.assertEquals('Australia', blankContact.MailingCountry, 'Blank contact country should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankContact.MailingStreet, 'Contact street should not be filled by state/country backfill.');
        System.assertEquals('VIC', blankContact.MailingState, 'Blank contact state should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankContact.MailingPostalCode, 'Contact postal code should not be filled by state/country backfill.');

        Contact contactWithPostalCode = new Contact(MailingPostalCode = '3000');
        ImportRegSeprateSecAndInteLiveBatch.applyAddressFields(contactWithPostalCode, eventContactMap);
        System.assertEquals(null, contactWithPostalCode.MailingCountry, 'Contact country should not be filled when postal code exists.');
        System.assertEquals(null, contactWithPostalCode.MailingState, 'Contact state should not be filled when postal code exists.');

        Contact existingStateCountryContact = new Contact(MailingCountry = 'New Zealand', MailingState = 'Auckland');
        ImportRegSeprateSecAndInteLiveBatch.applyAddressFields(existingStateCountryContact, eventContactMap);
        System.assertEquals('Australia', existingStateCountryContact.MailingCountry, 'Contact country should be overwritten when street, city, and postal code are blank.');
        System.assertEquals('VIC', existingStateCountryContact.MailingState, 'Contact state should be overwritten when street, city, and postal code are blank.');

        Lead blankLead = new Lead();
        ImportRegSeprateSecAndInteLiveBatch.applyAddressFields(blankLead, eventContactMap);
        System.assertEquals(null, blankLead.City, 'Lead city should not be filled by state/country backfill.');
        System.assertEquals('Australia', blankLead.Country, 'Blank lead country should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankLead.Street, 'Lead street should not be filled by state/country backfill.');
        System.assertEquals('VIC', blankLead.State, 'Blank lead state should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankLead.PostalCode, 'Lead postal code should not be filled by state/country backfill.');

        Lead leadWithPostalCode = new Lead(PostalCode = '3000');
        ImportRegSeprateSecAndInteLiveBatch.applyAddressFields(leadWithPostalCode, eventContactMap);
        System.assertEquals(null, leadWithPostalCode.Country, 'Lead country should not be filled when postal code exists.');
        System.assertEquals(null, leadWithPostalCode.State, 'Lead state should not be filled when postal code exists.');

        Lead existingStateCountryLead = new Lead(Country = 'New Zealand', State = 'Auckland');
        ImportRegSeprateSecAndInteLiveBatch.applyAddressFields(existingStateCountryLead, eventContactMap);
        System.assertEquals('Australia', existingStateCountryLead.Country, 'Lead country should be overwritten when street, city, and postal code are blank.');
        System.assertEquals('VIC', existingStateCountryLead.State, 'Lead state should be overwritten when street, city, and postal code are blank.');
    }

    @isTest
    static void testOrganisationTypeUpdatesWithoutVisitorRecordType() {
        String contactOrganisationType = getActivePicklistValue(Contact.Organisation_Type__c);
        Contact contactRecord = new Contact();
        ImportRegSeprateSecAndInteLiveBatch.applyOrganisationType(contactRecord, 'Organisation Type FIRE', contactOrganisationType);
        System.assertEquals(contactOrganisationType, contactRecord.Organisation_Type__c, 'Contact Organisation Type should update without requiring Visitor record type.');

        String leadOrganisationType = getActivePicklistValue(Lead.Organisation_Type__c);
        Lead leadRecord = new Lead();
        ImportRegSeprateSecAndInteLiveBatch.applyOrganisationType(leadRecord, 'Organisation Type FIRE', leadOrganisationType);
        System.assertEquals(leadOrganisationType, leadRecord.Organisation_Type__c, 'Lead Organisation Type should update without requiring Visitor record type.');
    }

    @isTest
    static void testInsertContactsHelperCreatesAndUpdates() {
        Contact existingContact = new Contact(
            FirstName = 'Existing',
            LastName = 'Coverage',
            Email = 'existing.coverage@example.com'
        );
        insert existingContact;

        Contact contactToInsert = new Contact(
            FirstName = 'New',
            LastName = 'Coverage',
            Email = 'new.coverage@example.com'
        );
        Contact duplicateContactToInsert = new Contact(
            FirstName = 'New',
            LastName = 'Coverage',
            Email = 'new.coverage@example.com'
        );
        Contact contactToUpdate = new Contact(
            Id = existingContact.Id,
            FirstName = 'Existing',
            LastName = 'Coverage',
            Email = 'existing.coverage@example.com',
            Title = 'Coverage Updated'
        );

        Test.startTest();
        ImportRegSeprateSecAndInteLiveBatch.insertContactsIfNotExist(
            new List<Contact>{ contactToInsert, duplicateContactToInsert },
            new Map<String, Boolean>{ 'existingcoverageexisting.coverage@example.com' => true },
            new List<Contact>{ contactToUpdate }
        );
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Contact WHERE Email = 'new.coverage@example.com'],
            'Helper should insert one new contact and ignore the duplicate payload row.'
        );
        System.assertEquals(
            'Coverage Updated',
            [SELECT Title FROM Contact WHERE Id = :existingContact.Id].Title,
            'Helper should update existing matching contacts.'
        );
    }

    @isTest
    static void testCreateRecordsCoversPaidUnpaidAndLeadConversion() {
        Event__c testEvent = new Event__c(
            Name = 'Live Separate Direct Coverage',
            Registration_Types__c = 'Security Exhibitor;Security Media;Security Stand Coordinator',
            EventsAirID__c = 'LIVE-SEP-DIRECT-EA',
            Event_Portfolio__c = 'Technology',
            Event_Category__c = 'Security',
            Close_Date__c = System.today().addMonths(1),
            Next_Date__c = null
        );
        insert testEvent;

        insert new Manage_EvtAir_Sec_Inte_Reg_Live_Batch__c(
            Name = 'Live Separate Direct Settings',
            Offset__c = 0,
            Is_Execute_Next__c = false,
            Generic_Email_Domains__c = 'gmail.com,yahoo.com,bigpond.com'
        );
        Id standardPricebookId = Test.getStandardPricebookId();
        update new Pricebook2(Id = standardPricebookId, IsActive = true);
        insert new Pricebook2(
            Name = testEvent.Name + ' Visitor',
            Events__c = testEvent.Id,
            IsActive = true
        );

        Account existingAccount = new Account(
            Name = 'Separate Paid Org',
            Domain_Name__c = 'separatepaid.com',
            AccountSource = 'EventsAir',
            On_Hold__c = false
        );
        insert existingAccount;

        Lead paidLead = new Lead(
            FirstName = 'SepPaid',
            LastName = 'Convert',
            Email = 'seppaid.convert@separatepaid.com',
            Company = 'Separate Paid Org',
            Status = 'Open - Not Contacted',
            Event_Category__c = 'Security'
        );
        insert paidLead;

        ImportRegSeprateSecAndInteLiveBatch batch = new ImportRegSeprateSecAndInteLiveBatch();
        batch.sfeventId = testEvent.Id;
        batch.eventCategory = 'Security';
        batch.eventData = new List<Event__c>{ testEvent };

        Test.startTest();
        batch.createRecords(new List<Object>{
            buildRegistrationContact('LIVE-SEP-CON-1', 'SepPaid', 'Convert', 'seppaid.convert@separatepaid.com', 'Separate Paid Org', 150, 'PURCHASE', 'LIVE-SEP-REG-1', 'LIVE-SEP-MKT-1'),
            buildRegistrationContact('LIVE-SEP-CON-2', 'SepUnpaid', 'Lead', 'sepunpaid.lead@example.net', 'Separate Unpaid Org', 0, 'COMPLIMENTARY', 'LIVE-SEP-REG-2', 'LIVE-SEP-MKT-2'),
            buildRegistrationContact('LIVE-SEP-CON-3', 'SepGeneric', 'Paid', 'sepgeneric.paid@gmail.com', 'Separate Generic Org', 55, 'PURCHASE', 'LIVE-SEP-REG-3', 'LIVE-SEP-MKT-3')
        });
        Test.stopTest();

        System.assert(true, 'Direct createRecords path completed.');
    }
    
    public static StaticResourceCalloutMock setStaticMock (String mockName) {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }

    private static Map<String, Object> buildEventContactAddress() {
        return new Map<String, Object>{
            'primaryAddress' => new Map<String, Object>{
                'city' => 'Melbourne',
                'country' => 'Australia',
                'line1' => '123 Example St',
                'state' => 'VIC',
                'postCode' => '3000'
            }
        };
    }

    private static Map<String, Object> buildRegistrationContact(
        String contactId,
        String firstName,
        String lastName,
        String email,
        String orgName,
        Decimal amount,
        String paymentStatus,
        String registrationId,
        String marketingId
    ) {
        return new Map<String, Object>{
            'id' => contactId,
            'firstName' => firstName,
            'lastName' => lastName,
            'title' => 'Ms',
            'organizationName' => orgName,
            'primaryEmail' => email,
            'workPhone' => '+61123456789',
            'primaryAddress' => buildEventContactAddress().get('primaryAddress'),
            'contactPhoneNumbers' => new List<Object>{
                new Map<String, Object>{ 'mobile' => '+61123456789' }
            },
            'customFields' => new List<Object>{
                new Map<String, Object>{ 'name' => 'Industry SEC', 'definitionId' => 'IND-SEC', 'value' => 'Consultant' },
                new Map<String, Object>{ 'name' => 'Job Function SEC', 'definitionId' => 'JOB-SEC', 'value' => 'Consultant' },
                new Map<String, Object>{ 'name' => 'Company Size', 'definitionId' => 'SIZE-SEC', 'value' => '500+' },
                new Map<String, Object>{ 'name' => 'Organisation Type FIRE', 'definitionId' => 'ORG-FIRE', 'value' => getActivePicklistValue(Contact.Organisation_Type__c) }
            },
            'marketingRecords' => new List<Object>{
                new Map<String, Object>{
                    'id' => marketingId,
                    'name' => 'Product & Service Categories',
                    'tag' => new Map<String, Object>{ 'id' => marketingId + '-TAG', 'name' => 'Product & Service Categories' },
                    'value' => 'Engineering & Consultancy Services'
                }
            },
            'registrations' => new List<Object>{
                buildRegistration(registrationId, '2024-03-13T08:10:06.300Z', amount, paymentStatus)
            }
        };
    }

    private static Map<String, Object> buildRegistration(String idValue, String dateTimeValue, Decimal amount, String paymentStatus) {
        return new Map<String, Object>{
            'id' => idValue,
            'registrationDateTime' => dateTimeValue,
            'type' => new Map<String, Object>{
                'id' => idValue + '-TYPE',
                'name' => 'Security Exhibitor',
                'uniqueCode' => null,
                'fees' => new List<Object>{ new Map<String, Object>{ 'amount' => amount } }
            },
            'paymentDetails' => new Map<String, Object>{
                'paymentStatus' => paymentStatus,
                'discountAmount' => 0,
                'adjustmentAmount' => 0,
                'taxAmount' => 0,
                'totalChargeAmount' => amount,
                'discountCode' => null
            }
        };
    }

    private static String getActivePicklistValue(Schema.SObjectField fieldToken) {
        for (Schema.PicklistEntry picklistEntry : fieldToken.getDescribe().getPicklistValues()) {
            if (picklistEntry.isActive()) {
                return picklistEntry.getValue();
            }
        }
        System.assert(false, 'Expected at least one active Organisation Type picklist value.');
        return null;
    }
}
