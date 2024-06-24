/************************************************************************************************
 * @description : Test Class for CoExhibitorTriggerHandler
 * @author      : SalesFix Dev - JL
 * @date        : 2018-02-28
 *************************************************************************************************/
@isTest
private class CoExhibitorTriggerHandlerTest {

    /**************************************************************************************************
    * @description : method to setup data.
    * @author      : SalesFix Dev - JL
    * @date        : 2018-02-18
    ***************************************************************************************************/
    @testSetup static void setupData(){
        List<Account> newAccounts = TestDataFactory.createAccounts(1);
        insert newAccounts;
        System.assert(newAccounts != null);

        Product2 pliProduct = TestDataFactory.createProduct2('Public Liability Insurance', 'Stand Package');
        insert pliProduct;
        System.assert(pliProduct != null);

        Pricebook2 newPricebook2 = TestDataFactory.createPricebook('Security', true);
        insert newPricebook2;
        System.assert(newPricebook2 != null);

        Id pricebookId = Test.getStandardPricebookId();

        PriceBookEntry newPricebookEntry = TestDataFactory.createPriceBPricebookEntry(pliProduct.Id, pricebookId, 10000, true);
        insert newPricebookEntry;
        System.assert(newPricebookEntry != null);

        PriceBookEntry newPricebookEntry2 = TestDataFactory.createPriceBPricebookEntry(pliProduct.Id, newPricebook2.Id, 10000, true);
        insert newPricebookEntry2;
        System.assert(newPricebookEntry2 != null);

        Account newAccount = TestDataFactory.createDifferentAccount('Contractor');
        insert newAccount;
        System.assert(newAccount != null);

        Account venueAccount = TestDataFactory.createDifferentAccount('Venue');
        venueAccount.Name = 'Venue test Account';
        insert venueAccount;
        System.assert(venueAccount != null);

        Id payment1Id = Schema.SObjectType.Payment_Term__c.getRecordTypeInfosByName().get('1 Payment').getRecordTypeId();
        Payment_Term__c paymentTerm1 = TestDataFactory.createPaymentTerm('Payment Term 1', payment1Id);
        insert paymentTerm1;
        System.assert(paymentTerm1 != null);

        Id payment2Id = Schema.SObjectType.Payment_Term__c.getRecordTypeInfosByName().get('2 Payments').getRecordTypeId();
        Payment_Term__c paymentTerm2 = TestDataFactory.createPaymentTerm('Payment Term 2', payment2Id);
        insert paymentTerm2;
        System.assert(paymentTerm2 != null);

        Id payment3Id = Schema.SObjectType.Payment_Term__c.getRecordTypeInfosByName().get('3 Payments').getRecordTypeId();
        Payment_Term__c paymentTerm3 = TestDataFactory.createPaymentTerm('Payment Term 3', payment3Id);
        insert paymentTerm3;
        System.assert(paymentTerm3 != null);

        Event__c testEvent = new Event__c();
        testEvent.Name = 'testt';
        testEvent.Price_Book__c = newPricebook2.Id;
        testEvent.Active__c = false;
        testEvent.ExpoCAD_ID__c = 'SECEX18';
        testEvent.Cooling_Off_Date__c = Date.today();
        insert testEvent;
        System.assert(testEvent != null);

        Event__c nextEvent = TestDataFactory.createCustomEvents(testEvent.Id, 'Next Event', newPricebook2.Id);
        nextEvent.Contractor__c = newAccount.Id;
        nextEvent.Venue__c = venueAccount.Id;
        nextEvent.X1_Payment_Term__c = paymentTerm1.Id;
        nextEvent.X2_Payment_Term__c = paymentTerm2.Id;
        nextEvent.X3_Payment_Term__c = paymentTerm3.Id;
        insert nextEvent;
        System.assert(nextEvent != null);

        /*
        Event__c nextEvent = TestDataFactory.createCustomEvents(null, 'Next Event', pricebookId);
        nextEvent.Price_Book__c = newPricebook2.Id;
        insert nextEvent;
        System.assert(nextEvent != null);
        */

        Trading_As__c newTradingAs = TestDataFactory.createTradingAs(newAccounts.get(0).Id);
        insert newTradingAs;

        List<Opportunity> opportunityList = TestDataFactory.createOpportunities(newAccounts[0].id, nextEvent.Id, date.today(), 'Negotiation', 1);
        opportunityList.get(0).Trading_As__c = newTradingAs.Id;
        opportunityList.get(0).Agreement_Signed__c = true;
        opportunityList.get(0).Pricebook2Id =  newPricebook2.Id;
        opportunityLIst.get(0).Primary_Contact_Added__c = true;
        insert opportunityList;
        System.assert(opportunityList != null);

        List<Stand__c> newStands = TestDataFactory.createStands(nextEvent.Id, 1);
        insert newStands;

        List<Co_Exhibitor__c> coExhibitorsList = TestDataFactory.createCoExhibitors(newAccounts.get(0).id, opportunityList.get(0).Id, 1, newTradingAs.Id);
        coExhibitorsList[0].Event__c  = nextEvent.Id;
        coExhibitorsList[0].Stand__c = newStands[0].Id;
        insert coExhibitorsList;
        System.assert(coExhibitorsList != null);
    }

    /**************************************************************************************************
    * @description : Test Class to update coExhibitor and Create new Opportunity
    * @author      : SalesFix Dev - JL
    * @date        : 2018-02-18
    ***************************************************************************************************/
    @istest static void testMethodToUpdateOpportunityCreated(){
        Co_Exhibitor__c coex = [SELECT Id, Opportunity_Created__c, Opportunity__c FROM Co_Exhibitor__c LIMIT 1 ];

        test.startTest();
        coex.Opportunity_Created__c = true;
        update coex;
        test.stopTest();
        
        PriceBook2 price = [SELECT Id, Name FROM PriceBook2 WHERE Name = 'Security' Limit 1];
        Map<Id, PriceBookEntry> priceEntryMap = new Map<Id, PriceBookEntry>([SELECT Id, Pricebook2Id FROM PriceBookEntry WHERE Pricebook2Id =: price.Id]);
        

        List<Opportunity> createdOpportunity = [SELECT Id, PriceBook2Id FROM Opportunity WHERE Name LIKE '%Test%'];
        CoExhibitorTriggerHandler cotrig = new CoExhibitorTriggerHandler();
        
        Set<Id> priceEnSetId = new Set<Id>();
        for(PriceBookEntry priceEn: priceEntryMap.values()){
            priceEnSetId.add(priceEn.Id);
        }
        cotrig.queryPriceBookEntries(priceEnSetId);
        System.assert(!createdOpportunity.isEmpty());

        //List<OpportunityLineItem> createOpporuLineItem = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId =: createdOpportunity.get(0).Id];
        //System.assert(!oppLine.isEmpty());
    }

    /**************************************************************************************************
    * @description : Test Class to update coExhibitor and Create new Opportunity without Pricebook in Event
    * @author      : SalesFix Dev - JL
    * @date        : 2018-02-18
    ***************************************************************************************************/
    @istest static void testMethodToUpdateOpportunityWithoutPriceBook(){
        Event__c eventCreated = [SELECT Id, Price_Book__c FROM Event__c LIMIT 1];
        eventCreated.Price_Book__c = null;
        update eventCreated;

        Co_Exhibitor__c coexCreated = [SELECT Id, Opportunity_Created__c, Opportunity__c FROM Co_Exhibitor__c LIMIT 1 ];

        test.startTest();
        coexCreated.Opportunity_Created__c = true;
        update coexCreated;
        test.stopTest();

        List<Opportunity> createdOpportunity = [SELECT Id FROM Opportunity WHERE Name LIKE '%Test%'];
        System.assert(!createdOpportunity.isEmpty());

    }

    /************************************************************************************************************
    * @description  : Method for exception
    * @author       : Salesfix - JL
    * @date         : 2018-04-11
    *************************************************************************************************************/
    @isTest static void testExceptionMethod(){
        Email_Error__c emailError = TestDataFactory.createEmailCustomSetting();
        insert emailError;
        System.assert(emailError != null);

        test.startTest();
        CoExhibitorTriggerHandler coexhibitorHandler = new CoExhibitorTriggerHandler();
        coexhibitorHandler.sendEmailError('test email error');
        
        test.stopTest();
    }
}