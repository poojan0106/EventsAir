@isTest
public with sharing class ImportRegSeprateSecAndInteBatchTest {
    static void setupData() {
        insert new Manage_Eventsair_Sec_And_Int_Reg_batch__c(
            Name = 'Batch Test Settings',
            Offset__c = 0,
            Is_Execute_Next__c = true,
            Generic_Email_Domains__c = 'gmail.com,example.com'
        );

        insert new Account(
            Name = 'gmail.com',
            Domain_Name__c = 'gmail.com',
            AccountSource = 'EventsAir'
        );
    }

    @isTest(SeeAllData=true)
    static void testSecurityCategoryBatch() {
        setupData();
        runSuccessfulBatch('Security - Sydney - 2024', true);
    }

    @isTest(SeeAllData=true)
    static void testIntegrateCategoryBatch() {
        setupData();
        runSuccessfulBatch('Integrate - Sydney - 2024', true);
    }

    @isTest(SeeAllData=true)
    static void testFireCategoryBatch() {
        setupData();
        runSuccessfulBatch('Fire Security Expo - Sydney - 2026', false);
    }

    @isTest(SeeAllData=true)
    static void testStartHandlesHttpError() {
        setupData();
        Event__c testEvent = getExistingEvent('Security - Sydney - 2024');

        Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMockCoverage', 500));

        Test.startTest();
        Database.executeBatch(new ImportRegSeprateSecAndInteBatch(testEvent.Id), 200);
        Test.stopTest();

        Manage_Eventsair_Sec_And_Int_Reg_batch__c settings = [
            SELECT Offset__c, Is_Execute_Next__c
            FROM Manage_Eventsair_Sec_And_Int_Reg_batch__c
            LIMIT 1
        ];

        System.assertEquals(0, settings.Offset__c, 'Offset resets on callout error');
        System.assertEquals(false, settings.Is_Execute_Next__c, 'Batch pauses on callout error');
    }

    private static void runSuccessfulBatch(String eventName, Boolean expectPricebookCreated) {
        Event__c testEvent = getExistingEvent(eventName);
        seedExistingRecords(testEvent.Id);

        Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMockCoverage', 200));

        Test.startTest();
        Database.executeBatch(new ImportRegSeprateSecAndInteBatch(testEvent.Id), 200);
        Test.stopTest();

        Event__c refreshedEvent = [
            SELECT Id, Open_Date__c, Close_Date__c, Is_Pricebook_Created__c
            FROM Event__c
            WHERE Id = :testEvent.Id
            LIMIT 1
        ];
        if (expectPricebookCreated) {
            System.assertEquals(true, refreshedEvent.Is_Pricebook_Created__c, 'Pricebook flag should be set');
        }
        System.assertNotEquals(null, refreshedEvent.Open_Date__c, 'Open date should be populated');
        System.assertNotEquals(null, refreshedEvent.Close_Date__c, 'Close date should be populated');

        System.assert(
            [SELECT COUNT() FROM Contact WHERE Email IN ('monica@santos.com', 'anna.fire@gmail.com')] > 0,
            'Batch should create or update contacts'
        );
        System.assert(
            [SELECT COUNT() FROM Lead WHERE Email = 'testrcs123@gmail.com'] > 0,
            'Batch should create or update leads'
        );
        System.assert(
            [SELECT COUNT() FROM Registration__c WHERE Event__c = :testEvent.Id] > 0,
            'Registration seed should exist'
        );
        System.assert(
            [SELECT COUNT() FROM Opportunity WHERE Event__c = :testEvent.Id] > 0,
            'Batch should create opportunities'
        );
        System.assert(
            [SELECT COUNT() FROM OpportunityLineItem] > 0,
            'Batch should create opportunity line items'
        );
        System.assert(
            [SELECT COUNT() FROM Product_Service_Option__c] > 0,
            'Batch should create product and service rows'
        );

    }

    @isTest(SeeAllData=true)
    static void testInsertRegistrationHelperUpdatesExistingRow() {
        setupData();
        Event__c testEvent = getExistingEvent('Security - Sydney - 2024');
        seedExistingRecords(testEvent.Id);

        ImportRegSeprateSecAndInteBatch batchInstance = new ImportRegSeprateSecAndInteBatch(testEvent.Id);
        List<Registration__c> registrationsToInsert = new List<Registration__c>{
            new Registration__c(
                EventsAir_Regisration_ID__c = 'REG-FIRE-1',
                Event__c = testEvent.Id
            )
        };
        Map<String, String> checkInMap = new Map<String, String>{
            'REG-FIRE-1' => '2021-08-25T08:00:00.000Z'
        };

        Test.startTest();
        batchInstance.insertRegistrationIfNotExist(registrationsToInsert, checkInMap);
        Test.stopTest();

        Registration__c updatedRegistration = [
            SELECT Id, CheckInDate__c
            FROM Registration__c
            WHERE EventsAir_Regisration_ID__c = 'REG-FIRE-1'
            AND Event__c = :testEvent.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, updatedRegistration.CheckInDate__c, 'Helper should backfill check-in date');
    }

    @isTest
    static void testAddressStateCountryBackfillRequiresCoreFieldsBlank() {
        Map<String, Object> eventContactMap = buildEventContactAddress();

        Contact blankContact = new Contact();
        ImportRegSeprateSecAndInteBatch.applyAddressFields(blankContact, eventContactMap);
        System.assertEquals(null, blankContact.MailingCity, 'Contact city should not be filled by state/country backfill.');
        System.assertEquals('Australia', blankContact.MailingCountry, 'Blank contact country should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankContact.MailingStreet, 'Contact street should not be filled by state/country backfill.');
        System.assertEquals('VIC', blankContact.MailingState, 'Blank contact state should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankContact.MailingPostalCode, 'Contact postal code should not be filled by state/country backfill.');

        Contact contactWithPostalCode = new Contact(MailingPostalCode = '3000');
        ImportRegSeprateSecAndInteBatch.applyAddressFields(contactWithPostalCode, eventContactMap);
        System.assertEquals(null, contactWithPostalCode.MailingCountry, 'Contact country should not be filled when postal code exists.');
        System.assertEquals(null, contactWithPostalCode.MailingState, 'Contact state should not be filled when postal code exists.');

        Contact existingStateCountryContact = new Contact(MailingCountry = 'New Zealand', MailingState = 'Auckland');
        ImportRegSeprateSecAndInteBatch.applyAddressFields(existingStateCountryContact, eventContactMap);
        System.assertEquals('Australia', existingStateCountryContact.MailingCountry, 'Contact country should be overwritten when street, city, and postal code are blank.');
        System.assertEquals('VIC', existingStateCountryContact.MailingState, 'Contact state should be overwritten when street, city, and postal code are blank.');

        Lead blankLead = new Lead();
        ImportRegSeprateSecAndInteBatch.applyAddressFields(blankLead, eventContactMap);
        System.assertEquals(null, blankLead.City, 'Lead city should not be filled by state/country backfill.');
        System.assertEquals('Australia', blankLead.Country, 'Blank lead country should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankLead.Street, 'Lead street should not be filled by state/country backfill.');
        System.assertEquals('VIC', blankLead.State, 'Blank lead state should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankLead.PostalCode, 'Lead postal code should not be filled by state/country backfill.');

        Lead leadWithPostalCode = new Lead(PostalCode = '3000');
        ImportRegSeprateSecAndInteBatch.applyAddressFields(leadWithPostalCode, eventContactMap);
        System.assertEquals(null, leadWithPostalCode.Country, 'Lead country should not be filled when postal code exists.');
        System.assertEquals(null, leadWithPostalCode.State, 'Lead state should not be filled when postal code exists.');

        Lead existingStateCountryLead = new Lead(Country = 'New Zealand', State = 'Auckland');
        ImportRegSeprateSecAndInteBatch.applyAddressFields(existingStateCountryLead, eventContactMap);
        System.assertEquals('Australia', existingStateCountryLead.Country, 'Lead country should be overwritten when street, city, and postal code are blank.');
        System.assertEquals('VIC', existingStateCountryLead.State, 'Lead state should be overwritten when street, city, and postal code are blank.');
    }

    @isTest
    static void testOrganisationTypeUpdatesWithoutVisitorRecordType() {
        String contactOrganisationType = getActivePicklistValue(Contact.Organisation_Type__c);
        Contact contactRecord = new Contact();
        ImportRegSeprateSecAndInteBatch.applyOrganisationType(contactRecord, 'Organisation Type FIRE', contactOrganisationType);
        System.assertEquals(contactOrganisationType, contactRecord.Organisation_Type__c, 'Contact Organisation Type should update without requiring Visitor record type.');

        String leadOrganisationType = getActivePicklistValue(Lead.Organisation_Type__c);
        Lead leadRecord = new Lead();
        ImportRegSeprateSecAndInteBatch.applyOrganisationType(leadRecord, 'Organisation Type FIRE', leadOrganisationType);
        System.assertEquals(leadOrganisationType, leadRecord.Organisation_Type__c, 'Lead Organisation Type should update without requiring Visitor record type.');
    }

    private static void seedExistingRecords(Id eventId) {
        insert new Contact(
            FirstName = 'Monica',
            LastName = 'Abad Esteva',
            Email = 'monica@santos.com'
        );

        insert new Lead(
            FirstName = 'Mahesh',
            LastName = 'Agarwal',
            Email = 'testrcs123@gmail.com',
            Company = 'Mp Associates Pty Ltd new test Mp Associates Pty Ltd 12345 Mp Associates Pty Ltd Mp Associates Pty Ltd',
            Status = 'Open - Not Contacted'
        );

        insert new Product_Service_Option__c(
            Name = 'Visitor Type',
            EventsAirMarketing_Record_ID__c = 'MKT-SEC-1',
            Marketing_Value__c = 'Security Visitor'
        );

        Registration__c seededRegistration = new Registration__c(
            RecordTypeId = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Registration').getRecordTypeId(),
            Event__c = eventId,
            EventsAir_Regisration_ID__c = 'REG-FIRE-1',
            EventsAir_Contact_Id__c = 'CON-FIRE-1',
            Payment_Status__c = 'PURCHASE',
            Date_Registered__c = System.now()
        );
        insert seededRegistration;
    }

    private static Event__c getExistingEvent(String eventName) {
        return [
            SELECT Id, Name, Registration_Types__c, Event_Category__c, Event_Portfolio__c, Close_Date__c, RecordTypeId
            FROM Event__c
            WHERE Name = :eventName
            LIMIT 1
        ];
    }

    private static StaticResourceCalloutMock setStaticMock(String mockName, Integer statusCode) {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(statusCode);
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