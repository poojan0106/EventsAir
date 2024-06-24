/************************************************************************************************************
* @description  : Test Class for OpportunityContactRoleHelper
* @author       : Salesfix - CI
* @date         : 2018-07-30
*************************************************************************************************************/
@isTest
private class OpportunityContactRoleHelperTest{
    /************************************************************************************************************
    * @description  : Setup test data
    * @author       : Salesfix - CI
    * @date         : 2018-07-30
    *************************************************************************************************************/
    @testSetup static void setupTestData(){
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

        List<Pavilion__c> newPavilionList = TestDataFactory.createPavilions(currentEvent.Id, 1);
        insert newPavilionList;
        System.assert(newPavilionList != null);
    }
    
    /************************************************************************************************************
    * @description  : Check if Primary Contact added will be updated - positive
    * @author       : Salesfix - CI
    * @date         : 2018-07-30
    *************************************************************************************************************/
    @isTest static void testUpdatePrimaryContactAdded(){
        List<Opportunity> createdOpp = [SELECT Id, Account.Name, AccountId, Rebooked__c, Event__c, Event__r.Next_Event__r.Name  FROM Opportunity LIMIT 1];
        Id setupContactId = [SELECT Id FROM Contact WHERE LastName = 'Reyes 1'].Id;
        List<OpportunityContactRole> contactRolesList = TestDataFactory.createContactRoles(setupContactId, createdOpp[0].Id, 'Business User', 1);
        contactRolesList[0].isPrimary = true;
        insert contactRolesList;
        
        test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(createdOpp[0]);
        OpportunityContactRoleHelper oppViewTriggerController = new OpportunityContactRoleHelper (sc);
        oppViewTriggerController.updateParentAccountValues();
        test.stopTest();
        
        List<Opportunity> updatedOpp = [SELECT Id, Name, Primary_Contact_Added__c FROM Opportunity LIMIT 1];
        System.assert(updatedOpp.get(0).Primary_Contact_Added__c);
    }
    
    /************************************************************************************************************
    * @description  : Check if Primary Contact added will be updated - negative
    * @author       : Salesfix - CI
    * @date         : 2018-07-30
    *************************************************************************************************************/
    @isTest static void testUpdatePrimaryContactDeleted(){
        List<Opportunity> createdOpp = [SELECT Id, Account.Name, AccountId, Rebooked__c, Event__c, Event__r.Next_Event__r.Name FROM Opportunity LIMIT 1];
        createdOpp[0].Primary_Contact_Added__c = true;
        update createdOpp[0];
        
        Id setupContactId = [SELECT Id FROM Contact WHERE LastName = 'Reyes 1'].Id;
        List<OpportunityContactRole> contactRolesList = TestDataFactory.createContactRoles(setupContactId, createdOpp[0].Id, 'Business User', 1);
        insert contactRolesList;
        
        test.startTest();
        delete contactRolesList;
        
        ApexPages.StandardController sc1 = new ApexPages.StandardController(createdOpp[0]);
        OpportunityContactRoleHelper oppViewTriggerController1 = new OpportunityContactRoleHelper (sc1);
        oppViewTriggerController1.updateParentAccountValues();
        test.stopTest();
        
        List<Opportunity> updatedOpp = [SELECT Id, Name, Primary_Contact_Added__c FROM Opportunity LIMIT 1];
        System.assert(!updatedOpp.get(0).Primary_Contact_Added__c);
    }


    /************************************************************************************************************
    * @description  : Negative testing
    * @author       : Salesfix - CI
    * @date         : 2018-07-30
    *************************************************************************************************************/
    @isTest static void testThrowError(){
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id cureentEventId = [SELECT Id FROM Event__c WHERE Name = 'Current Event' LIMIT 1].Id;
        List<Opportunity> opportunityList = TestDataFactory.createOpportunities(accountId, cureentEventId, date.today(), Label.Opportunity_Stage_Closed_Won, 1);

        Email_Error__c emailError = new Email_Error__c();
        emailError.Email_Address__c = 'test@test.testtt';
        insert emailError;

        test.startTest();
        ApexPages.StandardController sc1 = new ApexPages.StandardController(opportunityList.get(0));
        OpportunityContactRoleHelper oppViewTriggerController1 = new OpportunityContactRoleHelper (sc1);
        oppViewTriggerController1.updateParentAccountValues();
        test.stopTest();

    }
}