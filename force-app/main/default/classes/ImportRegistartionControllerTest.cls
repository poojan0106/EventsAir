@isTest
public class ImportRegistartionControllerTest {

     
    static testMethod void testExecuteBatch() {
        // Create a custom Event record for testing
        
		 Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMock'));
               RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Event__c' AND Name = 'Trade Show' LIMIT 1];

        Event__c testEvent = new Event__c(Name = 'Test Event', EventsAirID__c = '12345',RecordTypeId = rt.Id,Event_Portfolio__c = 'Food',Event_Category__c = 'Foodpro',Is_Pricebook_Created__c=false );
        system.debug('testEvent'+testEvent);
        insert testEvent;
        
        Manage_Eventsair_Reg_Apex_batch__c meab = new Manage_Eventsair_Reg_Apex_batch__c();
        meab.Name = 'test vandana';
        meab.Offset__c = 0;
        meab.Is_Execute_Next__c = true;
        //meab.Total_Contacts__c = 10;
        insert meab;
        
         Account acc = new Account();
        acc.Name = 'Test account - 2';
        acc.Domain_Name__c = 'gmail.com';
        insert acc;
        Account acc1 = new Account();
        acc1.Name = 'Cleanup Services';
        insert acc1;
        
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
        // Pricebook2 pb1 = new Pricebook2();
// pb1.Name = 'vandanaTest';
// pb1.Events__c = testEvent.id;
// insert pb1;

// List<Pricebook2> lstofpricebook = new List<Pricebook2>();

// Pricebook2 pb = new Pricebook2();
// pb.Name = 'vandanaTest';
// // pb.Events__c = testEvent.id;
// //pb.isStandard = true;
// lstofpricebook.add(pb);
// insert lstofpricebook;
        Id standardPricebookId = Test.getStandardPricebookId();
        
      
        
          // Product2 objProduct2=new Product2();
//         objProduct2.Name='SSP - Comprehensive - E';
//         objProduct2.ProductCode = 'Pro-D';
//         insert objProduct2;
        
//         List<Pricebook2> objPricebook = [Select id,Name from PriceBook2 where isStandard =: true];
//         Id standardPB = Test.getStandardPricebookId();  
        
//         PricebookEntry objpricebookentry =new PricebookEntry();
//         objpricebookentry.Product2ID = objProduct2.id;
//         objpricebookentry.UnitPrice=23.50;
//         objpricebookentry.UseStandardPrice=false;
//         objpricebookentry.Pricebook2ID=standardPB;
//         objpricebookentry.isActive=true;
//         insert objpricebookentry;
        ApexPages.StandardController controller = new ApexPages.StandardController(testEvent);

        Test.startTest();
        ImportRegistartionController controllerInstance = new ImportRegistartionController(controller);
        Database.executeBatch(new ImportRegistartionFromEventsAirBatch(testEvent.EventsAirID__c, testEvent.Id), 100);
        PageReference resultPage = controllerInstance.executeBatch();
        Test.stopTest();
  }
    static testMethod void testAuthentication(){
    Test.setMock(HttpCalloutMock.class, new MockHttpResponse());  
    Token_Request_Information__c customSetting = new Token_Request_Information__c(
            Name = 'AccessToken Information',
            EndPoint__c = 'https://example.com/token',
            Grant_Type__c = 'client_credentials',
            Scope__c = 'some_scope',
            Client_Id__c = 'client_id',
            Client_Secret__c = 'client_secret'
        );
        insert customSetting;

    Test.startTest();
    String accessToken = EventsAirOAuthTokenRequest.getAccessToken('trade');
    Test.stopTest();

  }

    @isTest
    static void testStateCountryBackfillForRegistrationBatch() {
        Map<String, Object> eventContactMap = buildEventContactAddress('Australia', 'VIC');

        Contact contactRecord = new Contact();
        ImportRegistartionFromEventsAirBatch.applyStateCountryFields(contactRecord, eventContactMap);
        System.assertEquals(null, contactRecord.MailingCity, 'Contact city should not be filled by state/country backfill.');
        System.assertEquals('Australia', contactRecord.MailingCountry, 'Blank contact country should be filled from EventsAir.');
        System.assertEquals(null, contactRecord.MailingStreet, 'Contact street should not be filled by state/country backfill.');
        System.assertEquals('VIC', contactRecord.MailingState, 'Blank contact state should be filled from EventsAir.');
        System.assertEquals(null, contactRecord.MailingPostalCode, 'Contact postal code should not be filled by state/country backfill.');

        Lead leadRecord = new Lead();
        ImportRegistartionFromEventsAirBatch.applyStateCountryFields(leadRecord, eventContactMap);
        System.assertEquals(null, leadRecord.City, 'Lead city should not be filled by state/country backfill.');
        System.assertEquals('Australia', leadRecord.Country, 'Blank lead country should be filled from EventsAir.');
        System.assertEquals(null, leadRecord.Street, 'Lead street should not be filled by state/country backfill.');
        System.assertEquals('VIC', leadRecord.State, 'Blank lead state should be filled from EventsAir.');
        System.assertEquals(null, leadRecord.PostalCode, 'Lead postal code should not be filled by state/country backfill.');

        Contact contactWithPostalCode = new Contact(MailingPostalCode = '3000');
        ImportRegistartionFromEventsAirBatch.applyStateCountryFields(contactWithPostalCode, eventContactMap);
        System.assertEquals(null, contactWithPostalCode.MailingCountry, 'Contact country should not be filled when postal code exists.');
        System.assertEquals(null, contactWithPostalCode.MailingState, 'Contact state should not be filled when postal code exists.');

        Lead leadWithPostalCode = new Lead(PostalCode = '3000');
        ImportRegistartionFromEventsAirBatch.applyStateCountryFields(leadWithPostalCode, eventContactMap);
        System.assertEquals(null, leadWithPostalCode.Country, 'Lead country should not be filled when postal code exists.');
        System.assertEquals(null, leadWithPostalCode.State, 'Lead state should not be filled when postal code exists.');

        Contact existingContact = new Contact(MailingCountry = 'New Zealand', MailingState = 'Auckland');
        ImportRegistartionFromEventsAirBatch.applyStateCountryFields(existingContact, eventContactMap);
        System.assertEquals('Australia', existingContact.MailingCountry, 'Existing contact country should be overwritten when street, city, and postal code are blank.');
        System.assertEquals('VIC', existingContact.MailingState, 'Existing contact state should be overwritten when street, city, and postal code are blank.');

        Lead existingLead = new Lead(Country = 'New Zealand', State = 'Auckland');
        ImportRegistartionFromEventsAirBatch.applyStateCountryFields(existingLead, eventContactMap);
        System.assertEquals('Australia', existingLead.Country, 'Existing lead country should be overwritten when street, city, and postal code are blank.');
        System.assertEquals('VIC', existingLead.State, 'Existing lead state should be overwritten when street, city, and postal code are blank.');
    }

    @isTest
    static void testOrganisationTypeMappingForRegistrationBatch() {
        String contactOrganisationType = getActivePicklistValue(Contact.Organisation_Type__c);
        Contact contactRecord = new Contact();
        ImportRegistartionFromEventsAirBatch.applyOrganisationType(contactRecord, 'Organisation Type', contactOrganisationType);
        System.assertEquals(contactOrganisationType, contactRecord.Organisation_Type__c, 'Contact organisation type should map from EventsAir.');

        String leadOrganisationType = getActivePicklistValue(Lead.Organisation_Type__c);
        Lead leadRecord = new Lead();
        ImportRegistartionFromEventsAirBatch.applyOrganisationType(leadRecord, 'Organisation Type', leadOrganisationType);
        System.assertEquals(leadOrganisationType, leadRecord.Organisation_Type__c, 'Lead organisation type should map from EventsAir.');

        Contact unsupportedFieldContact = new Contact();
        ImportRegistartionFromEventsAirBatch.applyOrganisationType(unsupportedFieldContact, 'Organisation Type FIRE', contactOrganisationType);
        System.assertEquals(null, unsupportedFieldContact.Organisation_Type__c, 'SEC/INT/FIRE EventsAir field should not map in this batch.');

        Lead blankValueLead = new Lead();
        ImportRegistartionFromEventsAirBatch.applyOrganisationType(blankValueLead, 'Organisation Type', ' ');
        System.assertEquals(null, blankValueLead.Organisation_Type__c, 'Blank EventsAir value should not map organisation type.');
    }
    
    public static StaticResourceCalloutMock setStaticMock (String mockName) {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
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

    private static String getActivePicklistValue(Schema.SObjectField fieldToken) {
        for (Schema.PicklistEntry picklistEntry : fieldToken.getDescribe().getPicklistValues()) {
            if (picklistEntry.isActive()) {
                return picklistEntry.getValue();
            }
        }

        System.assert(false, 'Expected at least one active Organisation Type picklist value.');
        return null;
    }

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"mock_access_token"}');
            res.setStatusCode(200);
            return res;
        }
    }
}