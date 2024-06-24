@isTest
public class PavilionTriggerHandlerTest {
/************************************************************************************************************
    * @description  : Setup test data
    * @author       : Salesfix - CI
    * @date         : 2018-09-21
    *************************************************************************************************************/
    @testSetup static void setupTestData() {
        List<Account> accountList = TestDataFactory.createAccounts(1);
        insert accountList;
        System.assert(accountList != null);

        List<Contact> contactList = TestDataFactory.createContacts(accountList[0].id, 1);
        insert contactList;
        System.assert(contactList != null);

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
        newPricebookEntry2.Default_Selected_for_Stand__c = true;
        newPricebookEntry2.Default_Selected_for_Pavilion__c = true;
        insert newPricebookEntry2;
        System.assert(newPricebookEntry2 != null);

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

        Event__c nextEvent = TestDataFactory.createCustomEvents(null, 'Next Event', newPricebook2.Id);
        nextEvent.Contractor__c = newAccount.Id;
        nextEvent.Venue__c = venueAccount.Id;
        nextEvent.X1_Payment_Term__c = paymentTerm1.Id;
        nextEvent.X2_Payment_Term__c = paymentTerm2.Id;
        nextEvent.X3_Payment_Term__c = paymentTerm3.Id;
        nextEvent.Active__c = false;
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

        List<Opportunity> opportunityList = TestDataFactory.createOpportunities(accountList[0].id, currentEvent.Id, date.today(), Label.Opportunity_Stage_Prospecting, 1);
        opportunityList.get(0).Trading_As__c = newTradingAs.Id;
        opportunityList.get(0).Agreement_Signed__c = true;
        insert opportunityList;
        System.assert(opportunityList != null);

        List<Stand__c> newStandList = TestDataFactory.createStands(currentEvent.Id, 1);
        insert newStandList;
        newStandList[0].Area__c = 5;
        update newStandList;
        System.assert(newStandList != null);

        List<Pavilion__c> newPavilionList = TestDataFactory.createPavilions(currentEvent.Id, 1);
        insert newPavilionList;
        System.assert(newPavilionList != null);
    }
    
    /************************************************************************************************************
    * @description  : Method to update Pavillion Area
    * @author       : Salesfix - CI
    * @date         : 2018-09-21
    *************************************************************************************************************/
    @isTest static void testUpdatePavillionOpportunity(){
        Id priceBookId = [SELECT Id FROM PriceBook2 WHERE Name = 'Security' LIMIT 1].Id;
        Id pavId = [SELECT Id FROM Pavilion__c LIMIT 1].Id;
        List<Opportunity> createdOpp = [SELECT Id, Stand__c, StageName  FROM Opportunity LIMIT 1];
        createdOpp.get(0).Pricebook2Id = priceBookId;
        update createdOpp;

        System.debug('@@@ testclass: ' + createdOpp.get(0).StageName);

        createdOpp.get(0).Pavilion__c = pavId;
        createdOpp.get(0).StageName = Label.Opportunity_Stage_Prospecting;
        update createdOpp;

        System.debug('@@@ testclass2: ' + createdOpp.get(0).StageName);

        test.startTest();
        List<Pavilion__c> existPav = [SELECT Id, Name FROM Pavilion__c WHERE Id =: pavId LIMIT 1];
        existPav.get(0).Area__c = 10;
        test.stopTest();
        update existPav;

        List<OpportunityLineItem> oppLineItem = [SELECT Id, Quantity FROM OpportunityLineItem WHERE OpportunityId =: createdOpp.get(0).Id LIMIT 1];
        System.assert(!oppLineItem.isEmpty());
        System.assertEquals(10,oppLineItem.get(0).Quantity, 'Did not match');

    }
}