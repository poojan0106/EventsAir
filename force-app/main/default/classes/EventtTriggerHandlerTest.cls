@isTest
public class EventtTriggerHandlerTest {

    @isTest
    static void testAfterUpdate() {
        Account venueAccount = new Account();
        venueAccount.Name = 'Ray ' + 'Venue';
        venueAccount.Type = 'Venue';
        venueAccount.Phone = '1234555555';
        venueAccount.ABN__c = '23468888888';
        venueAccount.BillingStreet = 'er44';
        venueAccount.BillingCity = 'ferfe';
        venueAccount.BillingState = 'Victoria';
        venueAccount.BillingPostalCode = '4000';
        venueAccount.BillingCountry = 'Australia';
        insert venueAccount;

        Account newAccount = new Account();
        newAccount.Name = 'Ray ' + 'Contractor';
        newAccount.Type = 'Contractor';
        newAccount.Phone = '(212) 555-6666';
        newAccount.ABN__c = '98006864347';
        newAccount.BillingStreet = 'St1111';
        newAccount.BillingCity = 'Ci1111';
        newAccount.BillingState = 'Victoria';
        newAccount.BillingPostalCode = '4000';
        newAccount.BillingCountry = 'Australia';
        insert newAccount;
        System.assert(newAccount != null);

        List<Contact> contactList = new List<Contact>();
        Contact newCon = new Contact();
        newCon.LastName = 'Reyes ';
        newCon.FirstName = 'Test ';
        newCon.AccountId = newAccount.Id;
        newCon.Email = 'testEmail@test.com';
        contactList.add(newCon);
        insert contactList;
        System.assert(contactList != null);

        Product2 pliProduct = new Product2();
        pliProduct.Name = 'Public Liability Insurance';
        pliProduct.Family = 'Stand Package';
        pliProduct.QuantityUnitOfMeasure = 'SQM';
        pliProduct.Target_Category__c = 'Test';
        insert pliProduct;
        System.assert(pliProduct != null);

        Pricebook2 newPricebook2 = new Pricebook2();
        newPricebook2.Name = 'Security';
        newPricebook2.isActive = true;
        insert newPricebook2;
        System.assert(newPricebook2 != null);

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry newPricebookEntry = new PricebookEntry();
        newPricebookEntry.Pricebook2Id = pricebookId;
        newPricebookEntry.Product2Id = pliProduct.Id;
        newPricebookEntry.UnitPrice = 10000;
        newPricebookEntry.isActive = true;
        insert newPricebookEntry;
        System.assert(newPricebookEntry != null);

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id; // Change 'Standard User' to the actual profile name

        User dummyUser = new User(
            FirstName = 'Test',
            LastName = 'john12',
            Email = 'testjohn12@example.com',
            Username = 'testjohn12.doe@example.com',
            Alias = 'jdoetest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profileId 
        );

        // Insert the User record
        insert dummyUser;

        Id payment1Id = Schema.SObjectType.Payment_Term__c.getRecordTypeInfosByName().get('1 Payment').getRecordTypeId();
        Payment_Term__c paymentTerm1 = new Payment_Term__c();
        paymentTerm1.Name = 'Payment Term 1';
        paymentTerm1.RecordTypeId = payment1Id;
        insert paymentTerm1;

        Id payment2Id = Schema.SObjectType.Payment_Term__c.getRecordTypeInfosByName().get('2 Payments').getRecordTypeId();
        Payment_Term__c paymentTerm2 = new Payment_Term__c();
        paymentTerm2.Name = 'Payment Term 2';
        paymentTerm2.RecordTypeId = payment2Id;
        insert paymentTerm2;
        
        Id payment3Id = Schema.SObjectType.Payment_Term__c.getRecordTypeInfosByName().get('3 Payments').getRecordTypeId();
        Payment_Term__c paymentTerm3 = new Payment_Term__c();
        paymentTerm3.Name = 'Payment Term 3';
        paymentTerm3.RecordTypeId = payment3Id;
        insert paymentTerm3;

        Event__c newEvent = new Event__c(Details_Synced_with_ExpoCAD__c = 'Success',Name = 'Test Event', ExpoCAD_ID__c = 'eaws20', Event_Portfolio__c = 'Wealth');
        insert newEvent;
       

        // Create test data
        Event__c oldEvent = new Event__c(X3_Payment_Term__c=paymentTerm3.Id,X2_Payment_Term__c=paymentTerm2.Id,X1_Payment_Term__c=paymentTerm1.Id,Venue__c=venueAccount.Id,Shell_Scheme_Exhibitor_End__c = System.now(),Price_Book__c=newPricebook2.Id, Open_Date__c=System.today(),Official_Stand_Builder_Start__c=System.today(),Official_Stand_Builder_End__c=System.today(),Next_Event__c =newEvent.Id,Move_Out_Date__c=System.today(),Move_In_Date__c=System.today(),Marketing_Coordinator_Email_Address__c='test@gmail.com',Event_Manager__c=dummyUser.Id, Event_Coordinator_Email_Address__c='test@gmail.com',Event_Code__c='zx',Cooling_Off_Date__c=System.today(),Contractor__c = newAccount.Id,Close_Date__c=system.today(),Active__c=true, Name = 'Test Event', ExpoCAD_ID__c = 'eaws20',Event_Portfolio__c = 'Wealth', Details_Synced_with_ExpoCAD__c = 'OldValue', multi__c = false,Shell_Scheme_Exhibitor_Start__c = System.now(),Space_Only_Exhibitor_End__c = System.now(),Space_Only_Exhibitor_Start__c = System.now(),Tenancy_End_Date__c = System.now(),Tenancy_Start_Date__c = System.now(),Website__c = 'www.google.com',X1P_Balance_Due_Date__c = Date.today(),X2_Payment_Period_Ends__c = Date.today(),X2P_Balance_Due_Date__c = Date.today(),X2P_Deposit_Due_Date__c = Date.today(),X3_Payment_Period_Ends__c = Date.today(),X3P_Balance_Due_Date__c = Date.today(),X3P_Deposit_Due_Date__c = Date.today(),X3P_Installment_Due_Date__c = Date.today());
        insert oldEvent;
        oldEvent.Details_Synced_with_ExpoCAD__c = 'Requested';
        update oldEvent;

         // Inserting custom settings
         TriggerController__c customSetting = new TriggerController__c(
            Name = 'TriggerSettings',
            EventTrigger__c = true // Set this to true to test the functionality
        );
        insert customSetting;

        ExpocadIntegrationLogic.updateFromExpocad=true;
        Test.startTest();
        EventtTriggerHandler.afterUpdate(new List<Event__c>{oldEvent}, new Map<Id, Event__c>{oldEvent.Id => oldEvent});
        Test.stopTest();

        // // Retrieve the updated event
        // newEvent = [SELECT Id, Details_Synced_with_ExpoCAD__c, multi__c FROM Event__c WHERE Id = :newEvent.Id];

        // // Add assertions to verify the expected behavior
        // System.assertEquals('Requested', newEvent.Details_Synced_with_ExpoCAD__c);
        // System.assertEquals(true, newEvent.multi__c);
        // // Add more assertions as needed
    }
}