@isTest
public class ImportRegistartionBatchForLiveEventTest {

    @isTest
    static void testExecuteBatch_CoversHappyPath() {
        Event__c testEvent = createEvent('Coverage Event', Date.today().addMonths(1));
        seedCoreData(testEvent.Id);

        Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMockCoverage', 200));

        Test.startTest();
        Database.executeBatch(new ImportRegistartionBatchForLiveEvent(), 200);
        Test.stopTest();

        Event__c refreshedEvent = [
            SELECT Id, Open_Date__c, Close_Date__c, Is_Pricebook_Created__c, Next_Date__c
            FROM Event__c
            WHERE Id = :testEvent.Id
            LIMIT 1
        ];
        System.assertEquals(true, refreshedEvent.Is_Pricebook_Created__c, 'Batch should mark the event as pricebook-created');
        System.assertNotEquals(null, refreshedEvent.Open_Date__c, 'Open date should be updated from the payload');
        System.assertNotEquals(null, refreshedEvent.Close_Date__c, 'Close date should be updated from the payload');

        System.assert(
            [SELECT COUNT() FROM Contact WHERE Email IN ('monica@santos.com', 'anna.fire@gmail.com')] > 0,
            'Batch should create or update contacts'
        );
        System.assert(
            [SELECT COUNT() FROM Lead WHERE Email = 'testrcs123@gmail.com'] > 0,
            'Batch should create or update leads'
        );
        System.assert(
            [SELECT COUNT() FROM Product_Service_Option__c] > 0,
            'Batch should create or update product and service rows'
        );
    }

    @isTest
    static void testStartHandlesHttpError() {
        Event__c testEvent = createEvent('HTTP Error Event', Date.today().addMonths(1));
        seedCustomSetting('gmail.com', 0, true);

        Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMockCoverage', 500));

        Test.startTest();
        Database.executeBatch(new ImportRegistartionBatchForLiveEvent(), 200);
        Test.stopTest();

        Manage_Eventsair_Reg_batch_Live_Event__c settings = [
            SELECT Offset__c, Is_Execute_Next__c
            FROM Manage_Eventsair_Reg_batch_Live_Event__c
            LIMIT 1
        ];
        System.assertEquals(0, settings.Offset__c, 'Offset should reset after a callout error');
        System.assertEquals(false, settings.Is_Execute_Next__c, 'Batch should pause after a callout error');
    }

    @isTest
    static void testStartHandlesNoEvent() {
        seedCustomSetting('gmail.com', 0, true);

        Event__c ignoredEvent = new Event__c(
            Name = 'Ignored Event',
            EventsAirID__c = 'IGNORED-001',
            Event_Portfolio__c = 'Food',
            Close_Date__c = Date.today().addDays(-1),
            Next_Date__c = Date.today().addDays(-2)
        );
        insert ignoredEvent;

        ImportRegistartionBatchForLiveEvent batchInstance = new ImportRegistartionBatchForLiveEvent();
        batchInstance.start(null);

        Manage_Eventsair_Reg_batch_Live_Event__c settings = [
            SELECT Offset__c, Is_Execute_Next__c
            FROM Manage_Eventsair_Reg_batch_Live_Event__c
            LIMIT 1
        ];
        System.assertEquals(0, settings.Offset__c, 'Offset should reset when no event is found');
        System.assertEquals(false, settings.Is_Execute_Next__c, 'Batch should stop when no event is found');
    }

    @isTest
    static void testExecuteHandlesMalformedWrapper() {
        Event__c testEvent = createEvent('Catch Event', Date.today().addMonths(1));
        seedCustomSetting('gmail.com', 0, true);

        ImportRegistartionBatchForLiveEvent batchInstance = new ImportRegistartionBatchForLiveEvent();
        batchInstance.sfeventId = testEvent.Id;
        batchInstance.eventCategory = 'Security';

        Test.startTest();
        batchInstance.execute(null, new List<ResponseWrapper>{ new ResponseWrapper() });
        Test.stopTest();

        System.assert(
            [SELECT COUNT() FROM FeedItem WHERE ParentId = :testEvent.Id] > 0,
            'Malformed wrapper should be logged to the event feed'
        );
    }

    @isTest
    static void testStateCountryBackfillForLiveRegistrationBatch() {
        Map<String, Object> eventContactMap = buildEventContactAddress('Australia', 'VIC');

        Contact contactRecord = new Contact();
        ImportRegistartionBatchForLiveEvent.applyStateCountryFields(contactRecord, eventContactMap);
        System.assertEquals(null, contactRecord.MailingCity, 'Contact city should not be filled by state/country backfill.');
        System.assertEquals('Australia', contactRecord.MailingCountry, 'Blank contact country should be filled from EventsAir.');
        System.assertEquals(null, contactRecord.MailingStreet, 'Contact street should not be filled by state/country backfill.');
        System.assertEquals('VIC', contactRecord.MailingState, 'Blank contact state should be filled from EventsAir.');
        System.assertEquals(null, contactRecord.MailingPostalCode, 'Contact postal code should not be filled by state/country backfill.');

        Lead leadRecord = new Lead();
        ImportRegistartionBatchForLiveEvent.applyStateCountryFields(leadRecord, eventContactMap);
        System.assertEquals(null, leadRecord.City, 'Lead city should not be filled by state/country backfill.');
        System.assertEquals('Australia', leadRecord.Country, 'Blank lead country should be filled from EventsAir.');
        System.assertEquals(null, leadRecord.Street, 'Lead street should not be filled by state/country backfill.');
        System.assertEquals('VIC', leadRecord.State, 'Blank lead state should be filled from EventsAir.');
        System.assertEquals(null, leadRecord.PostalCode, 'Lead postal code should not be filled by state/country backfill.');

        Contact contactWithPostalCode = new Contact(MailingPostalCode = '3000');
        ImportRegistartionBatchForLiveEvent.applyStateCountryFields(contactWithPostalCode, eventContactMap);
        System.assertEquals(null, contactWithPostalCode.MailingCountry, 'Contact country should not be filled when postal code exists.');
        System.assertEquals(null, contactWithPostalCode.MailingState, 'Contact state should not be filled when postal code exists.');

        Lead leadWithPostalCode = new Lead(PostalCode = '3000');
        ImportRegistartionBatchForLiveEvent.applyStateCountryFields(leadWithPostalCode, eventContactMap);
        System.assertEquals(null, leadWithPostalCode.Country, 'Lead country should not be filled when postal code exists.');
        System.assertEquals(null, leadWithPostalCode.State, 'Lead state should not be filled when postal code exists.');

        Contact existingContact = new Contact(MailingCountry = 'New Zealand', MailingState = 'Auckland');
        ImportRegistartionBatchForLiveEvent.applyStateCountryFields(existingContact, eventContactMap);
        System.assertEquals('Australia', existingContact.MailingCountry, 'Existing contact country should be overwritten when street, city, and postal code are blank.');
        System.assertEquals('VIC', existingContact.MailingState, 'Existing contact state should be overwritten when street, city, and postal code are blank.');

        Lead existingLead = new Lead(Country = 'New Zealand', State = 'Auckland');
        ImportRegistartionBatchForLiveEvent.applyStateCountryFields(existingLead, eventContactMap);
        System.assertEquals('Australia', existingLead.Country, 'Existing lead country should be overwritten when street, city, and postal code are blank.');
        System.assertEquals('VIC', existingLead.State, 'Existing lead state should be overwritten when street, city, and postal code are blank.');
    }

    @isTest
    static void testOrganisationTypeMappingForLiveRegistrationBatch() {
        String contactOrganisationType = getActivePicklistValue(Contact.Organisation_Type__c);
        Contact contactRecord = new Contact();
        ImportRegistartionBatchForLiveEvent.applyOrganisationType(contactRecord, 'Organisation Type', contactOrganisationType);
        System.assertEquals(contactOrganisationType, contactRecord.Organisation_Type__c, 'Contact organisation type should map from EventsAir.');

        String leadOrganisationType = getActivePicklistValue(Lead.Organisation_Type__c);
        Lead leadRecord = new Lead();
        ImportRegistartionBatchForLiveEvent.applyOrganisationType(leadRecord, 'Organisation Type', leadOrganisationType);
        System.assertEquals(leadOrganisationType, leadRecord.Organisation_Type__c, 'Lead organisation type should map from EventsAir.');

        Contact unsupportedFieldContact = new Contact();
        ImportRegistartionBatchForLiveEvent.applyOrganisationType(unsupportedFieldContact, 'Organisation Type FIRE', contactOrganisationType);
        System.assertEquals(null, unsupportedFieldContact.Organisation_Type__c, 'SEC/INT/FIRE EventsAir field should not map in this batch.');

        Lead blankValueLead = new Lead();
        ImportRegistartionBatchForLiveEvent.applyOrganisationType(blankValueLead, 'Organisation Type', ' ');
        System.assertEquals(null, blankValueLead.Organisation_Type__c, 'Blank EventsAir value should not map organisation type.');
    }

    private static Event__c createEvent(String name, Date closeDate) {
        Event__c eventRecord = new Event__c(
            Name = name,
            EventsAirID__c = name.replace(' ', '-') + '-EA',
            Event_Portfolio__c = 'Food',
            Close_Date__c = closeDate,
            Next_Date__c = null
        );
        insert eventRecord;
        return eventRecord;
    }

    private static void seedCustomSetting(String genericDomains, Integer offset, Boolean executeNext) {
        delete [SELECT Id FROM Manage_Eventsair_Reg_batch_Live_Event__c];
        insert new Manage_Eventsair_Reg_batch_Live_Event__c(
            Name = 'Batch Test Settings',
            Offset__c = offset,
            Is_Execute_Next__c = executeNext,
            Generic_Email_Domains__c = genericDomains
        );
    }

    private static void seedCoreData(Id eventId) {
        seedCustomSetting('gmail.com', 0, true);

        insert new Account(
            Name = 'Cleanup Services',
            Domain_Name__c = 'santos.com',
            AccountSource = 'EventsAir',
            On_Hold__c = false
        );

        insert new Contact(
            FirstName = 'Monica',
            LastName = 'Abad Esteva',
            Email = 'monica@santos.com',
            AccountId = [SELECT Id FROM Account WHERE Name = 'Cleanup Services' LIMIT 1].Id
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

        insert new Registration__c(
            RecordTypeId = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Registration').getRecordTypeId(),
            Event__c = eventId,
            EventsAir_Regisration_ID__c = 'REG-SEC-1',
            EventsAir_Contact_Id__c = 'CON-SEC-1',
            Payment_Status__c = 'PURCHASE',
            Date_Registered__c = System.now()
        );

        insert new Opportunity(
            Name = 'Seeded Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Divcom_Visitor').getRecordTypeId(),
            Event__c = eventId,
            EventsAir_Contact_Id__c = 'CON-SEC-1',
            LeadSource = 'EventsAir'
        );

        insert new Pricebook2(
            Name = 'Seeded Visitor Pricebook',
            Events__c = eventId,
            IsActive = true
        );

        Id standardPricebookId = Test.getStandardPricebookId();
    }

    private static Map<String, Object> buildPaidContactWithWorkPhone() {
        return new Map<String, Object>{
            'id' => 'CON-EDGE-1',
            'firstName' => 'ExtremelyLongFirstNameThatShouldBeTrimmedToFortyCharacters',
            'lastName' => null,
            'title' => null,
            'organizationName' => null,
            'checkInDate' => '2021-08-25T08:00:00.000Z',
            'checkOutDate' => null,
            'primaryEmail' => 'longpaid@gmail.com',
            'workPhone' => '+61111111111',
            'primaryAddress' => new Map<String, Object>{
                'city' => 'Sydney',
                'country' => 'Australia',
                'line1' => 'Level 10',
                'line2' => '1 Market Street',
                'line3' => 'Tower A',
                'postCode' => '2000',
                'state' => 'NSW'
            },
            'contactPhoneNumbers' => new Map<String, Object>{
                'mobile' => '+61111111111'
            },
            'customFields' => new List<Object>{
                buildCustomField('Industry', 'Waste Management'),
                buildCustomField('Company Size', '10 - 49'),
                buildCustomField('Job Function', 'Operations')
            },
            'marketingRecords' => new List<Object>{
                buildMarketingRecord('MKT-EDGE-1', 'Visitor Type', 'Edge Visitor'),
                buildMarketingRecord('MKT-EDGE-2', 'Products & Service Categories', 'Software & Technologies')
            },
            'registrations' => new List<Object>{
                buildRegistration('REG-EDGE-1', '2021-08-25T08:00:00.000Z', 25, 'PURCHASE')
            }
        };
    }

    private static Map<String, Object> buildEventContactAddress(String country, String state) {
        return new Map<String, Object>{
            'primaryAddress' => new Map<String, Object>{
                'city' => 'Melbourne',
                'country' => country,
                'line1' => '1 Test Street',
                'line2' => 'Suite 2',
                'line3' => 'Level 3',
                'postCode' => '3000',
                'state' => state
            }
        };
    }

    private static Map<String, Object> buildUnpaidContactWithPhoneList() {
        return new Map<String, Object>{
            'id' => 'CON-EDGE-2',
            'firstName' => 'ListPhone',
            'lastName' => null,
            'title' => null,
            'organizationName' => null,
            'checkInDate' => null,
            'checkOutDate' => null,
            'primaryEmail' => 'unpaid.list@example.net',
            'workPhone' => null,
            'primaryAddress' => new Map<String, Object>{
                'city' => null,
                'country' => 'Australia',
                'line1' => null,
                'line2' => null,
                'line3' => null,
                'postCode' => '3000',
                'state' => 'VIC'
            },
            'contactPhoneNumbers' => new List<Object>{
                new Map<String, Object>{ 'mobile' => '+61123456789' }
            },
            'customFields' => new List<Object>{
                buildCustomField('Industry', 'Environmental Services'),
                buildCustomField('Company Size', '1 - 9'),
                buildCustomField('Job Function', 'Student & Trainee')
            },
            'marketingRecords' => new List<Object>{
                buildMarketingRecord('MKT-EDGE-3', 'Visitor Type', 'Edge Visitor'),
                buildMarketingRecord('MKT-EDGE-4', 'Products & Service Categories', 'Bins/Waste Collection/Waste Products')
            },
            'registrations' => new List<Object>{
                buildRegistration('REG-EDGE-2', '2021-08-25T09:00:00.000Z', 0, 'COMPLIMENTARY')
            }
        };
    }

    private static Map<String, Object> buildCustomField(String name, String value) {
        return new Map<String, Object>{
            'name' => name,
            'definitionId' => name + '-DEF',
            'value' => value
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

    private static Map<String, Object> buildMarketingRecord(String idValue, String name, String value) {
        return new Map<String, Object>{
            'id' => idValue,
            'name' => name,
            'tag' => new Map<String, Object>{
                'id' => idValue + '-TAG',
                'name' => name
            },
            'value' => value
        };
    }

    private static Map<String, Object> buildRegistration(String idValue, String dateTimeValue, Decimal amount, String paymentStatus) {
        return new Map<String, Object>{
            'id' => idValue,
            'registrationDateTime' => dateTimeValue,
            'type' => new Map<String, Object>{
                'id' => idValue + '-TYPE',
                'name' => 'Visitor Registration',
                'uniqueCode' => null,
                'fees' => new List<Object>{
                    new Map<String, Object>{ 'amount' => amount }
                }
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

    public static StaticResourceCalloutMock setStaticMock(String mockName, Integer statusCode) {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(statusCode);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }
}