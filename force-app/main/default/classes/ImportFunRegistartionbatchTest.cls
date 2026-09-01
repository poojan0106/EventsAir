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