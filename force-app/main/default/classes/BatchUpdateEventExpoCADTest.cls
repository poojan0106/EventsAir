/******************************************************************************************************************************
* @description  : Test class for BatchUpdateEventExpoCADTest
* @author       : Salesfix Dev - JL
* @date         : 2018-04-18
*******************************************************************************************************************************/
@isTest
private class BatchUpdateEventExpoCADTest {
    /******************************************************************************************************************************
    * @description  : test setup method
    * @author       : Salesfix Dev - JL
    * @date         : 2018-04-18
    *******************************************************************************************************************************/
    @testSetup static void setup() {
        Email_Error__c emailError = TestDataFactory.createEmailCustomSetting();
        insert emailError;
        System.assert(emailError != null);

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
    }

    /******************************************************************************************************************************
    * @description  : test class to run the batch class
    * @author       : Salesfix Dev - JL
    * @date         : 2018-04-18
    *******************************************************************************************************************************/
    @isTest static void testMethodToCallBatchClass() {
        Event__c existingEvent = [SELECT Id, Active__c, ExpoCAD_ID__c, Details_Synced_with_ExpoCAD__c FROM Event__c WHERE Name = 'Next Event' LIMIT 1];
        existingEvent.Active__c = true;
        existingEvent.ExpoCAD_ID__c = 'Test123';
        existingEvent.Details_Synced_with_ExpoCAD__c = 'Failure';
        update existingEvent;

        test.startTest();
        Database.executeBatch(new BatchUpdateEventExpoCAD());
        BatchUpdateEventExpoCAD batch = new BatchUpdateEventExpoCAD();
        batch.sendEmailError('test email');
        test.stopTest();

        Event__c updatedEvent = [SELECT Id, Details_Synced_with_ExpoCAD__c FROM Event__c WHERE Id =: existingEvent.Id LIMIT 1];
        System.assert(updatedEvent.Details_Synced_with_ExpoCAD__c == 'Requested');
    }

    /******************************************************************************************************************************
    * @description  : test class to run the schedule class
    * @author       : Salesfix Dev - JL
    * @date         : 2018-04-18
    *******************************************************************************************************************************/
    @isTest static void testMethodToScheduleBatch() {
        Event__c existingEvent = [SELECT Id, Active__c, ExpoCAD_ID__c, Details_Synced_with_ExpoCAD__c FROM Event__c WHERE Name = 'Next Event' LIMIT 1];
        existingEvent.Active__c = true;
        existingEvent.ExpoCAD_ID__c = 'Test123';
        existingEvent.Details_Synced_with_ExpoCAD__c = 'Failure';
        update existingEvent;

        BatchUpdateEventExpoCADSchedule sched = new BatchUpdateEventExpoCADSchedule();
        Decimal hour= System.now().hour();
        Decimal minute= System.now().minute();
        String cronExp = '0 '+minute+' '+hour+' * * ?';

        test.startTest();
        System.schedule('Test Schedule', cronExp, sched);
        Database.executeBatch(new BatchUpdateEventExpoCAD());
        test.stopTest();

        Event__c updatedEvent = [SELECT Id, Details_Synced_with_ExpoCAD__c FROM Event__c WHERE Id =: existingEvent.Id LIMIT 1];
        System.assert(updatedEvent.Details_Synced_with_ExpoCAD__c == 'Requested');
    }
}