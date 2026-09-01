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