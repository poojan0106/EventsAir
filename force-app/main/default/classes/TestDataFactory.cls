/************************************************************************************************************
* @description  : Test Data Factory
* @author       : Salesfix - CI
* @date         : 2018-03-05
*************************************************************************************************************/
@isTest
public with sharing class TestDataFactory {

    /************************************************************************************************************
    * @description  : collects account records
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : accountSize - number of account records that should be created
    * @return       : list of accounts
    *************************************************************************************************************/
    public static List<Account> createAccounts(Integer accountSize) {
        List<Account> accountList = new List<Account>();
        for (Integer i = 1; i <= accountSize; i ++) {
            Account newAccount = new Account();
            newAccount.Name = 'Test Account ' + i;
            newAccount.Type = 'Other';
            newAccount.Phone = '(212) 555-5555';
            newAccount.ABN__c = '98006864347';
            newAccount.BillingStreet = 'Billing Street';
            newAccount.BillingCity = 'Billing City';
            newAccount.BillingState = 'Victoria';
            newAccount.BillingPostalCode = '3000';
            newAccount.BillingCountry = 'Australia';
            accountList.add(newAccount);
        }
        return accountList;
    }

    /************************************************************************************************************
    * @description  : collects contact records
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : accountId - id of the parent account record
    * @param        : contactSize - number of contact records that will be created
    * @return       : list of contacts
    *************************************************************************************************************/
    public static List<Contact> createContacts(Id accountId, Integer contactSize) {
        List<Contact> contactList = new List<Contact>();
        for (Integer i = 1; i <= contactSize; i ++) {
            Contact newCon = new Contact();
            newCon.LastName = 'Reyes ' + i;
            newCon.FirstName = 'Test ' + i;
            newCon.AccountId = accountId;
            newCon.Email = 'testEmail@test.com';
            contactList.add(newCon);
        }
        return contactList;
    }

    /************************************************************************************************************
    * @description  : collects custom event records
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : nextEvent - id of the next event
    * @param        : eventName - name of the event record
    * @return       : event sobject
    *************************************************************************************************************/
    public static Event__c createCustomEvents(Id nextEvent, String eventName, Id priceBookId) {
        Event__c eventRecord = new Event__c();
        eventRecord.Name = eventName;
        eventRecord.Next_Event__c = nextEvent;
        eventRecord.Price_Book__c = priceBookId;
        eventRecord.Active__c = true;
        eventRecord.ExpoCAD_ID__c = 'SECEX18';
        eventRecord.Cooling_Off_Date__c = Date.today();
        eventRecord.Close_Date__c = System.now() + 5;
        eventRecord.Email__c ='test@test.test';
        eventRecord.Event_Code__c = 'testcode';
        eventRecord.Move_In_Date__c = System.now();
        eventRecord.Move_Out_Date__c = System.now();
        eventRecord.Official_Stand_Builder_Start__c = System.now();
        eventRecord.Official_Stand_Builder_End__c = System.now();
        eventRecord.Open_Date__c = System.now();
        eventRecord.Shell_Scheme_Exhibitor_End__c = System.now();
        eventRecord.Event_Coordinator_Email_Address__c = 'test.event.coordinator@yopmail.com';
        eventRecord.Marketing_Coordinator_Email_Address__c = 'test.marketing.coordinator@yopmail.com';
        eventRecord.Shell_Scheme_Exhibitor_Start__c = System.now();
        eventRecord.Space_Only_Exhibitor_End__c = System.now();
        eventRecord.Space_Only_Exhibitor_Start__c = System.now();
        eventRecord.Tenancy_End_Date__c = System.now();
        eventRecord.Tenancy_Start_Date__c = System.now();
        eventRecord.Tenancy_Start_Date__c = System.now();
        eventRecord.Website__c = 'www.google.com';
        eventRecord.X1P_Balance_Due_Date__c = Date.today();
        eventRecord.X2_Payment_Period_Ends__c = Date.today();
        eventRecord.X2P_Balance_Due_Date__c = Date.today();
        eventRecord.X2P_Deposit_Due_Date__c = Date.today();
        eventRecord.X3_Payment_Period_Ends__c = Date.today();
        eventRecord.X3P_Balance_Due_Date__c = Date.today();
        eventRecord.X3P_Deposit_Due_Date__c = Date.today();
        eventRecord.X3P_Installment_Due_Date__c = Date.today();
        eventRecord.Event_Portfolio__c = 'Built Environment';
        return eventRecord;
    }

    /************************************************************************************************************
    * @description  : collects opportunity records
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : accountId - id of the parent account record
    * @param        : eventName - id of the parent event record
    * @param        : closeDate - close date
    * @param        : stageName - stage
    * @param        : oppSize - number of opportunities
    * @return       : list of opportunity
    *************************************************************************************************************/
    public static List<Opportunity> createOpportunities(Id accountId, Id customEventId, Date closeDate, String stageName, Integer oppSize) {
        List<Opportunity> opportunityList = new List<Opportunity>();

        for (Integer i = 1; i <= oppSize; i ++) {
            Opportunity newOpp = new Opportunity();
            newOpp.Name = 'Test Opp ' + i;
            newOpp.AccountId = accountId;
            newOpp.CloseDate = closeDate;
            newOpp.Event__c = customEventId;
            newOpp.StageName = stageName;
            opportunityList.add(newOpp);
        }

        return opportunityList;
    }

    /************************************************************************************************************
    * @description  : collects contact role records
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : contactId - id of the contact record
    * @param        : opportunityId - id of the opportunity record
    * @param        : roleName - role of the contact
    * @param        : roleSize - number of roles that will be created
    * @return       : list of opportunity contact roles
    *************************************************************************************************************/
    public static List<OpportunityContactRole> createContactRoles(Id contactId, Id opportunityId, String roleName, Integer roleSize) {
        List<OpportunityContactRole> oppContactRolesList = new List<OpportunityContactRole>();

        for (Integer i = 1; i <= roleSize; i ++) {
            OpportunityContactRole newContactRole = new OpportunityContactRole();
            newContactRole.Role = roleName;
            newContactRole.ContactId = contactId;
            newContactRole.OpportunityId = opportunityId;
            oppContactRolesList.add(newContactRole);
        }

        return oppContactRolesList;
    }

    /************************************************************************************************************
    * @description  : collects contact role records
    * @author       : Salesfix - JL
    * @date         : 2018-03-08
    * @param        : accountId - id of the account record
    * @param        : opportunityId - id of the opportunity record
    * @param        : coexhibitorSize - number of coexhibitor to be created
    * @return       : list of Co_Exhibitor__c
    *************************************************************************************************************/
    public static List<Co_Exhibitor__c> createCoExhibitors(Id accountId, Id opportunityId, Integer coexhibitorSize, Id exhibitId) {
        List<Co_Exhibitor__c> coExhibitorsToReturn = new List<Co_Exhibitor__c>();

        for (Integer i = 1; i <= coexhibitorSize; i ++) {
            Co_Exhibitor__c coExhibitor = new Co_Exhibitor__c();
            coExhibitor.Account__c = accountId;
            coExhibitor.Opportunity__c = opportunityId;
            coExhibitor.Exhibiting_As__c = exhibitId;
            coExhibitorsToReturn.add(coExhibitor);
        }

        return coExhibitorsToReturn;
    }

    public static Product2 createProduct2(String productName, String familyName) {
        Product2 newProduct = new Product2();

        newProduct.Name = productName;
        newProduct.Family = familyName;
        newProduct.QuantityUnitOfMeasure = 'SQM';
        newProduct.Target_Category__c = 'Test';

        return newProduct;
    }

    public static Pricebook2 createPricebook(String priceBookName, Boolean isActivePB) {
        Pricebook2 newPriceBook = new Pricebook2();

        newPriceBook.Name = priceBookName;
        newPriceBook.isActive = isActivePB;

        return newPriceBook;
    }

    public static PricebookEntry createPriceBPricebookEntry(Id productId, Id priceBookId, Decimal price, Boolean isActivePBE) {
        PricebookEntry newPricebookEntry = new PricebookEntry();

        newPricebookEntry.Pricebook2Id = priceBookId;
        newPricebookEntry.Product2Id = productId;
        newPricebookEntry.UnitPrice = price;
        newPricebookEntry.isActive = isActivePBE;

        return newPricebookEntry;
    }

    public static List<Stand__c> createStands(Id eventId, Integer standSize) {
        List<Stand__c> standToReturn = new List<Stand__c>();

        for (Integer i = 0; i < standSize; i ++) {
            Stand__c stand = new Stand__c();
            stand.Name = 'test stand ' + i;
            stand.Event__c = eventId;
            stand.Area__c = 1;
            stand.Open_Corners__c = 2;
            stand.ExpoCAD_ID__c = 'SECEX18';
            standToReturn.add(stand);
        }

        return standToReturn;
    }

    public static List<Pavilion__c> createPavilions(Id eventId, Integer pavilionSize) {
        List<Pavilion__c> pavlitionToReturn = new List<Pavilion__c>();

        for (Integer i = 0; i < pavilionSize; i ++) {
            Pavilion__c pavilion = new Pavilion__c();
            pavilion.Name = 'test stand ' + i;
            pavilion.Event__c = eventId;
            pavilion.Pavilion_Code__c = String.valueOf(i);
            pavlitionToReturn.add(pavilion);
        }

        return pavlitionToReturn;
    }

    public static Account createDifferentAccount(String type, String abn) {
        Account newAccount = new Account();

        newAccount.Name = 'Ray ' + type;
        newAccount.Type = type;
        newAccount.Phone = '(212) 555-6666';
        newAccount.ABN__c = abn;
        newAccount.BillingStreet = 'St1111 '+type;
        newAccount.BillingCity = 'Ci1111 '+type;
        newAccount.BillingState = 'Victoria '+type;
        newAccount.BillingPostalCode = '4000';
        newAccount.BillingCountry = 'Australia '+type;
        newAccount.Website = 'test'+type+'.com';
        newAccount.Primary_Event_Category__c = 'AOG Energy';
        newAccount.Industry = 'Technology';

        return newAccount;
    }

    public static Payment_Term__c createPaymentTerm(String name, Id recordTypeId) {
        Payment_Term__c paymentTerm = new Payment_Term__c();
        paymentTerm.Name = name;
        paymentTerm.RecordTypeId = recordTypeId;
        return paymentTerm;
    }

    public static Email_Error__c createEmailCustomSetting() {
        Email_Error__c emailError = new Email_Error__c();
        emailError.Email_Address__c = 'test@test.testt';
        return emailError;
    }

    public static Trading_As__c createTradingAs(Id accountId) {
        Trading_As__c newTrading = new Trading_As__c();
        newTrading.Name = 'Test trading';
        newTrading.Account__c = accountId;
        return newTrading;
    }
    
    //COMMENTED BY - SALESFIX DEV - RAY HORMILLADA
    /*public static OpportunityLineItem createOpplines(Integer i, Id oppId, Id proId) {
        
        OpportunityLineItem opLine = new OpportunityLineItem();
            opLine.Quantity = i+1;
            opLine.OpportunityId = oppId;
            opLine.Product2Id = proId;
            opLine.UnitPrice = 100;
            
        return opLine;
    }*/
    
    public static Trading_As__c createExhibitingAs(Id accId) {
        Trading_As__c trd = new Trading_As__c();
        trd.Name = 'Sample Trading As';
        trd.Account__c = accId;
            
        return trd;
    }

    public static Lead createNewLead() {
        Lead newLead = new Lead();
        newLead.Status = 'New';
        newLead.FirstName = 'First';
        newLead.LastName = 'Last';
        newLead.Title = 'test';
        newLead.Email = 'test@test.testt';
        newLead.Company = 'Test Company';
        newLead.Industry = 'Agriculture';
        newLead.LeadSource = 'Advertisement';
        newLead.Marketing_Qualified__c = true;
        newLead.Event_Category__c = 'Design Build';
        return newLead;
    }

    public static Industry_Option__c createIndustryOption() {
        Industry_Option__c industryOption = new Industry_Option__c();
        industryOption.Name = 'Test Industry';
        return industryOption;
    }

    public static Relevant_industry__c createRelevantIndustry(Id leadId, Id industryId) {
        Relevant_industry__c relevantIndustry  = new Relevant_industry__c();
        relevantIndustry.Industry_Option__c = industryId;
        relevantIndustry.Lead__c = leadId;
        return relevantIndustry;
    }

    public static Segment_Option__c createSegmentOption() {
        Segment_Option__c newSegmentOption = new Segment_Option__c();
        newSegmentOption.Name = 'Test Segment';
        return newSegmentOption;
    }

    public static Relevant_Segment__c createRelevantSegment(Id leadId, Id segmentId) {
        Relevant_Segment__c relevantSegment = new Relevant_Segment__c();
        relevantSegment.Segment_Option__c = segmentId;
        relevantSegment.Lead__c = leadId;
        return relevantSegment;
    }
}