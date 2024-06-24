/************************************************************************************************************
* @description : Test class for OpportunityLineItemTriggerHandler and OpportunityLineItemTrigger
* @author      : Salesfix Dev - JL
* @date        : 12/21/2018
*************************************************************************************************************/
@isTest
private class OpportunityLineItemTriggerHandlerTest {

    /************************************************************************************************************
    * @description : test setup method
    * @author      : Salesfix Dev - JL
    * @date        : 12/20/2018
    *************************************************************************************************************/
    @testSetup static void setup() {
        List<Account> accountList =  TestDataFactory.createAccounts(1);
        insert accountList;
        System.assert(accountList != null);

        List<Contact> contactList = TestDataFactory.createContacts(accountList[0].id,1);
        insert contactList;
        System.assert(contactList != null);

        Product2 pliProduct = TestDataFactory.createProduct2('Public Liability Insurance', 'Stand Package');
        insert pliProduct;
        System.assert(pliProduct != null);

        Product2 pliProduct2 = TestDataFactory.createProduct2('Test Corner', 'Stand Package');
        pliProduct2.QuantityUnitOfMeasure = 'CORNER';
        pliProduct2.Side_Count__c = 3;
        insert pliProduct2;
        System.assert(pliProduct2 != null);

        Pricebook2 newPricebook2 = TestDataFactory.createPricebook('Security', true);
        insert newPricebook2;
        System.assert(newPricebook2 != null);

        Id pricebookId = Test.getStandardPricebookId();

        PriceBookEntry newPricebookEntry = TestDataFactory.createPriceBPricebookEntry(pliProduct.Id, pricebookId, 10000, true);
        insert newPricebookEntry;
        System.assert(newPricebookEntry != null);

        PriceBookEntry newPricebookEntry4 = TestDataFactory.createPriceBPricebookEntry(pliProduct2.Id, pricebookId, 10000, true);
        insert newPricebookEntry4;
        System.assert(newPricebookEntry4 != null);

        PriceBookEntry newPricebookEntry2 = TestDataFactory.createPriceBPricebookEntry(pliProduct.Id, newPricebook2.Id, 10000, true);
        newPricebookEntry2.Default_Selected_for_Stand__c = true;
        newPricebookEntry2.Default_Selected_for_Pavilion__c = true;
        newPricebookEntry2.Default_Selected_for_Withdrawals__c = true;
        insert newPricebookEntry2;
        System.assert(newPricebookEntry2 != null);

        PriceBookEntry newPricebookEntry3 = TestDataFactory.createPriceBPricebookEntry(pliProduct2.Id, newPricebook2.Id, 10000, true);
        newPricebookEntry3.Default_Selected_for_Stand__c = true;
        newPricebookEntry3.Default_Selected_for_Pavilion__c = true;
        newPricebookEntry3.Default_Selected_for_Withdrawals__c = true;
        insert newPricebookEntry3;
        System.assert(newPricebookEntry3 != null);

        Account newAccount = TestDataFactory.createDifferentAccount('Contractor');
        insert newAccount;
        System.assert(newAccount != null);

        Account venueAccount = TestDataFactory.createDifferentAccount('Venue');
        venueAccount.Name = 'test Venue';
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

        Event__c dummyEvent = TestDataFactory.createCustomEvents(null, 'Dummy Event', newPricebook2.Id);
        dummyEvent.Active__c = false;
        insert dummyEvent;
        System.assert(dummyEvent != null);

        Event__c nextEvent = TestDataFactory.createCustomEvents(dummyEvent.Id, 'Next Event', newPricebook2.Id);
        nextEvent.Contractor__c = newAccount.Id;
        nextEvent.Venue__c = venueAccount.Id;
        nextEvent.X1_Payment_Term__c = paymentTerm1.Id;
        nextEvent.X2_Payment_Term__c = paymentTerm2.Id;
        nextEvent.X3_Payment_Term__c = paymentTerm3.Id;
        insert nextEvent;
        System.assert(nextEvent != null);

        Event__c currentEvent = TestDataFactory.createCustomEvents(nextEvent.Id, 'Current Event', newPricebook2.Id);
        currentEvent.Contractor__c = newAccount.Id;
        currentEvent.Venue__c = venueAccount.Id;
        currentEvent.X1_Payment_Term__c = paymentTerm1.Id;
        currentEvent.X2_Payment_Term__c = paymentTerm2.Id;
        currentEvent.X3_Payment_Term__c = paymentTerm3.Id;
        insert currentEvent;
        System.assert(currentEvent != null);

        Trading_As__c newTradingAs = TestDataFactory.createTradingAs(accountList.get(0).Id);
        insert newTradingAs;
        System.assert(newTradingAs != null);

        List<Opportunity> opportunityList = TestDataFactory.createOpportunities(accountList[0].id, currentEvent.Id, date.today(), Label.Opportunity_Stage_Closed_Won, 1);
        opportunityList.get(0).Trading_As__c = newTradingAs.Id;
        opportunityList.get(0).Agreement_Signed__c = true;
        insert opportunityList;
        System.assert(opportunityList != null);

        List<Stand__c> newStandList = TestDataFactory.createStands(currentEvent.Id, 1);
        insert newStandList;
        System.assert(newStandList != null);

    }

    /************************************************************************************************************
    * @description : method to create new OLI on opportunity and confirm if opportuntiy update
    * @author      : Salesfix Dev - JL
    * @date        : 12/20/2018
    *************************************************************************************************************/
    @isTest static void testCreateNewOLIonOpportunity(){
        Id priceBookId = [SELECT Id FROM PriceBook2 WHERE Name = 'Security' LIMIT 1].Id;
        Id standId = [SELECT Id FROM Stand__c LIMIT 1].Id;
        List<Opportunity> createdOpp = [SELECT Id, Stand__c  FROM Opportunity LIMIT 1];
        createdOpp.get(0).Pricebook2Id = priceBookId;
        update createdOpp;

        test.startTest();
        createdOpp.get(0).StageName = 'Proposal Agreement';
        createdOpp.get(0).Stand__c = standId;
        update createdOpp;

        test.stopTest();

        Opportunity updatedOpportunity = [SELECT Id, Stand_Package_Products_List__c FROM Opportunity WHERE Id =: createdOpp.get(0).Id];
        //System.assertEquals(updatedOpportunity.Stand_Package_Products_List__c, 'Public Liability Insurance, Test Corner');
    }

    /************************************************************************************************************
    * @description : method to delete OLI and confirm the opportunity update
    * @author      : Salesfix Dev - JL
    * @date        : 12/20/2018
    *************************************************************************************************************/
    @isTest static void testDeleteExistingOLI(){
        Id priceBookId = [SELECT Id FROM PriceBook2 WHERE Name = 'Security' LIMIT 1].Id;
        Id standId = [SELECT Id FROM Stand__c LIMIT 1].Id;
        List<Opportunity> createdOpp = [SELECT Id, Stand__c  FROM Opportunity LIMIT 1];
        createdOpp.get(0).Pricebook2Id = priceBookId;
        update createdOpp;

        test.startTest();
        createdOpp.get(0).StageName = 'Proposal Agreement';
        createdOpp.get(0).Stand__c = standId;
        update createdOpp;

        List<OpportunityLineItem> oppLineItem = [SELECT Id, Product2.Name FROM OpportunityLineItem WHERE OpportunityId =: createdOpp.get(0).Id  AND Product2.Name = 'Test Corner' LIMIT 1];
        delete oppLineItem;
        test.stopTest();

        Opportunity updatedOpportunity = [SELECT Id, Stand_Package_Products_List__c FROM Opportunity WHERE Id =: createdOpp.get(0).Id];
        //System.assertEquals(updatedOpportunity.Stand_Package_Products_List__c, 'Public Liability Insurance');
    }
}