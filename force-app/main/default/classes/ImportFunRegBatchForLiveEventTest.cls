@isTest
public class ImportFunRegBatchForLiveEventTest {
    
     static testMethod void testExecuteBatch() {
        // Create a custom Event record for testing
        
        DateTime currentDateTime = System.now();
        Time currentTime = Time.newInstance(currentDateTime.hour(), currentDateTime.minute(), currentDateTime.second(), 0);
        
        Test.setMock(HttpCalloutMock.class, setStaticMock('importfuncregistrationMock'));
         Event__c testEvent = new Event__c(Name = 'Test Event', EventsAirID__c = '12345',Event_Portfolio__c = 'Food',Event_Category__c = 'Foodpro',Close_Date__c = system.today().addMonths(1),Next_Date__c = null);
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
        ld.Event_Category__c = 'Foodpro';
        ld.Company = 'Unknown';
        insert ld;
        
        Id standardPricebookId = Test.getStandardPricebookId();

          // Schedule the batch job
        String jobName = 'Test Function Registration Batch Job';
        String cronExpression = '0 0 */2 * * ?'; // Every 2 hours
        
        Test.startTest();
        
        //  System.schedule(jobName, cronExpression, new FunctionRegLiveEventBatchScheduler());
        ImportFunRegBatchForLiveEvent batchInstance = new ImportFunRegBatchForLiveEvent();
        Database.executeBatch(batchInstance);
        ImportFunRegBatchForLiveEvent.generatestringMethod('Test1','Test2','Test3');
        Test.stopTest();
    }

    @isTest
    static void testStateCountryBackfillRequiresCoreFieldsBlank() {
        Map<String, Object> eventContactMap = buildEventContactAddress();

        Contact blankContact = new Contact();
        ImportFunRegBatchForLiveEvent.applyStateCountryFields(blankContact, eventContactMap);
        System.assertEquals(null, blankContact.MailingCity, 'Contact city should not be filled by state/country backfill.');
        System.assertEquals('Australia', blankContact.MailingCountry, 'Blank contact country should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankContact.MailingStreet, 'Contact street should not be filled by state/country backfill.');
        System.assertEquals('VIC', blankContact.MailingState, 'Blank contact state should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankContact.MailingPostalCode, 'Contact postal code should not be filled by state/country backfill.');

        Contact contactWithPostalCode = new Contact(MailingPostalCode = '3000');
        ImportFunRegBatchForLiveEvent.applyStateCountryFields(contactWithPostalCode, eventContactMap);
        System.assertEquals(null, contactWithPostalCode.MailingCountry, 'Contact country should not be filled when postal code exists.');
        System.assertEquals(null, contactWithPostalCode.MailingState, 'Contact state should not be filled when postal code exists.');

        Lead blankLead = new Lead();
        ImportFunRegBatchForLiveEvent.applyStateCountryFields(blankLead, eventContactMap);
        System.assertEquals(null, blankLead.City, 'Lead city should not be filled by state/country backfill.');
        System.assertEquals('Australia', blankLead.Country, 'Blank lead country should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankLead.Street, 'Lead street should not be filled by state/country backfill.');
        System.assertEquals('VIC', blankLead.State, 'Blank lead state should be filled when street, city, and postal code are blank.');
        System.assertEquals(null, blankLead.PostalCode, 'Lead postal code should not be filled by state/country backfill.');

        Lead leadWithCity = new Lead(City = 'Melbourne');
        ImportFunRegBatchForLiveEvent.applyStateCountryFields(leadWithCity, eventContactMap);
        System.assertEquals(null, leadWithCity.Country, 'Lead country should not be filled when city exists.');
        System.assertEquals(null, leadWithCity.State, 'Lead state should not be filled when city exists.');
    }

    @isTest
    static void testRegistrationLinkHelpersCoverExistingRows() {
        Event__c testEvent = new Event__c(
            Name = 'Live Function Helper Coverage Event',
            EventsAirID__c = 'LIVE-FUNC-COV-EVENT',
            Event_Portfolio__c = 'Food',
            Event_Category__c = 'Foodpro',
            Close_Date__c = Date.today().addMonths(1),
            Next_Date__c = null
        );
        insert testEvent;

        Registration__c registrationRecord = new Registration__c(
            RecordTypeId = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Registration').getRecordTypeId(),
            Event__c = testEvent.Id,
            EventsAir_Regisration_ID__c = 'LIVE-FUNC-COV-REG-1',
            Payment_Status__c = 'PURCHASE',
            Date_Registered__c = System.now()
        );
        insert registrationRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = 'Live Function Helper Coverage Opportunity',
            StageName = 'ClosedWon',
            CloseDate = Date.today(),
            Event__c = testEvent.Id
        );
        insert opportunityRecord;

        OpportunityLineItem oli = new OpportunityLineItem(
            Function_Registration_Id__c = 'LIVE-FUNC-COV-REG-1',
            OpportunityId = opportunityRecord.Id
        );

        Test.startTest();
        ImportFunRegBatchForLiveEvent.UpdateRegistrationsOLI(new List<OpportunityLineItem>{ oli });
        new ImportFunRegBatchForLiveEvent().LinkFunctionToRegistration(new List<Registration__c>{
            new Registration__c(Id = registrationRecord.Id, EventsAir_Function_Id__c = 'LIVE-FUNC-COV-NO-MATCH')
        });
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Registration__c WHERE Id = :registrationRecord.Id],
            'Registration helper test should keep the seeded registration available.'
        );
    }

    @isTest
    static void testInsertLeadsHelperCreatesAndUpdates() {
        Lead existingLead = new Lead(
            FirstName = 'ExistingLive',
            LastName = 'Coverage',
            Email = 'existing.live.coverage@example.com',
            Company = 'Existing Company',
            Title = 'Before Update'
        );
        insert existingLead;

        Lead leadToInsert = new Lead(
            FirstName = 'NewLive',
            LastName = 'Coverage',
            Email = 'new.live.coverage@example.com',
            Company = 'New Company'
        );
        Lead duplicateLeadToInsert = new Lead(
            FirstName = 'NewLive',
            LastName = 'Coverage',
            Email = 'new.live.coverage@example.com',
            Company = 'New Company'
        );
        Lead leadToUpdate = new Lead(
            Id = existingLead.Id,
            FirstName = 'ExistingLive',
            LastName = 'Coverage',
            Email = 'existing.live.coverage@example.com',
            Company = 'Existing Company',
            Title = 'After Update'
        );

        Test.startTest();
        ImportFunRegBatchForLiveEvent.insertLeadsIfNotExist(
            new List<Lead>{ leadToInsert, duplicateLeadToInsert },
            new Map<String, Boolean>{ 'existinglivecoverageexisting.live.coverage@example.com' => true },
            new List<Lead>{ leadToUpdate }
        );
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Lead WHERE Email = 'new.live.coverage@example.com'],
            'Helper should insert one new lead and ignore the duplicate payload row.'
        );
        System.assertEquals(
            'After Update',
            [SELECT Title FROM Lead WHERE Id = :existingLead.Id].Title,
            'Helper should update existing matching leads.'
        );
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

    public static StaticResourceCalloutMock setStaticMock (String mockName) {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }

}