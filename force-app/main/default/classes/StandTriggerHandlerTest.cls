/************************************************************************************************************
* @description  : Test Class for StandTriggerHandler
* @author       : Salesfix - CI
* @date         : 2018-04-19
* @changes      : 2018-08-24 - CI - Parent pavillion area rollup
*************************************************************************************************************/
@isTest
private class StandTriggerHandlerTest{
    /************************************************************************************************************
    * @description  : Setup test data
    * @author       : Salesfix - CI
    * @date         : 2018-04-19
    *************************************************************************************************************/
    @testSetup static void setupTestData() {
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
        Event__c currentEvent = new Event__c(X3_Payment_Term__c=paymentTerm3.Id,X2_Payment_Term__c=paymentTerm2.Id,X1_Payment_Term__c=paymentTerm1.Id,Venue__c=venueAccount.Id,Shell_Scheme_Exhibitor_End__c = System.now(),Price_Book__c=newPricebook2.Id, Open_Date__c=System.today(),Official_Stand_Builder_Start__c=System.today(),Official_Stand_Builder_End__c=System.today(),Next_Event__c =newEvent.Id,Move_Out_Date__c=System.today(),Move_In_Date__c=System.today(),Marketing_Coordinator_Email_Address__c='test@gmail.com',Event_Manager__c=dummyUser.Id, Event_Coordinator_Email_Address__c='test@gmail.com',Event_Code__c='zx',Cooling_Off_Date__c=System.today(),Contractor__c = newAccount.Id,Close_Date__c=system.today(),Active__c=true, Name = 'Test Event', ExpoCAD_ID__c = 'eaws20',Event_Portfolio__c = 'Wealth', Details_Synced_with_ExpoCAD__c = 'OldValue', multi__c = false,Shell_Scheme_Exhibitor_Start__c = System.now(),Space_Only_Exhibitor_End__c = System.now(),Space_Only_Exhibitor_Start__c = System.now(),Tenancy_End_Date__c = System.now(),Tenancy_Start_Date__c = System.now(),Website__c = 'www.google.com',X1P_Balance_Due_Date__c = Date.today(),X2_Payment_Period_Ends__c = Date.today(),X2P_Balance_Due_Date__c = Date.today(),X2P_Deposit_Due_Date__c = Date.today(),X3_Payment_Period_Ends__c = Date.today(),X3P_Balance_Due_Date__c = Date.today(),X3P_Deposit_Due_Date__c = Date.today(),X3P_Installment_Due_Date__c = Date.today());
        insert currentEvent;
        System.assert(currentEvent != null);

        Trading_As__c newTradingAs=new Trading_As__c(Name='test', Account__c=newAccount.Id);
        insert newTradingAs;
        System.assert(newTradingAs != null);
        
        Opportunity newOpp = new Opportunity();
        newOpp.Name = 'Test Opp';
        newOpp.AccountId = newAccount.id;
        newOpp.CloseDate = date.today();
        newOpp.Event__c = currentEvent.Id;
        newOpp.StageName = Label.Opportunity_Stage_Closed_Won;
        newOpp.Agreement_Signed__c = true;
        newOpp.Trading_As__c = newTradingAs.Id;
        insert newOpp;

        List<Opportunity> opportunityList = new List<Opportunity>();
        Opportunity newOpp2 = new Opportunity();
        newOpp2.Name = 'Test Opp ';
        newOpp2.AccountId = newAccount.id;
        newOpp2.CloseDate = date.today();
        newOpp2.Event__c = currentEvent.Id;
        newOpp2.StageName = Label.Opportunity_Stage_Closed_Won;
        newOpp2.Trading_As__c = newTradingAs.Id;
        newOpp2.Agreement_Signed__c = true;
        newOpp2.Co_Exhibitor_Opportunity__c = newOpp.Id;
        opportunityList.add(newOpp2);
        insert opportunityList;
        System.assert(opportunityList != null);

        Stand__c standRec = new Stand__c(
            Name = 'G36',
            ExpoCAD_ID__c = 'G36.' + currentEvent.ExpoCAD_ID__c,
            Account_ID__c = newAccount.Id,
            Account_Name__c=newAccount.Name,
            Trading_As__c=newTradingAs.Id,
            Is_On_Hold__c=true,
            Status_Synced_with_ExpoCAD__c='Success'
        );
        insert standRec;

        standRec.Area__c = 5;
        update standRec;
        System.assert(standRec != null);

        List<Pavilion__c> pavlitionToReturn = new List<Pavilion__c>();
        Pavilion__c pavilion = new Pavilion__c();
        pavilion.Name = 'test stand ';
        pavilion.Event__c = currentEvent.Id;
        pavilion.Pavilion_Code__c = String.valueOf(1);
        pavlitionToReturn.add(pavilion);
        insert pavlitionToReturn;
        System.assert(pavlitionToReturn != null);
    }

    /************************************************************************************************************
    * @description  : Method to update Stand Area
    * @author       : Salesfix - CI
    * @date         : 2018-04-19
    *************************************************************************************************************/
    @isTest static void testUpdateStandOpportunity(){
        Id priceBookId = [SELECT Id FROM PriceBook2 WHERE Name = 'Security' LIMIT 1].Id;
        Id standId = [SELECT Id FROM Stand__c LIMIT 1].Id;
        List<Opportunity> createdOpp = [SELECT Id, Stand__c  FROM Opportunity LIMIT 1];
        createdOpp.get(0).Pricebook2Id = priceBookId;
        update createdOpp;
        
        // createdOpp.get(0).Stand__c = standId;
        // update createdOpp;

        test.startTest();
        List<Pavilion__c> existPavilion = [SELECT Id, Name FROM Pavilion__c LIMIT 1];
        Stand__c newStand = new Stand__c();
        newStand.Name = '135';
        newStand.Pavilion__c = existPavilion.get(0).Id;
        newStand.Area__c = 12;
        insert newStand;

        List<Stand__c> existStand = [SELECT Id, Name FROM Stand__c LIMIT 1];
        existStand.get(0).Area__c = 10;
        existStand.get(0).Pavilion__c = existPavilion.get(0).Id;
        update existStand;

        delete existStand;
        System.debug('@@@existStand' + existStand);
        test.stopTest();
    }

    /************************************************************************************************************
    * @description  : Method to update Stand Area
    * @author       : Salesfix - CI
    * @date         : 2018-04-19
    *************************************************************************************************************/
    @isTest static void testUpdateOpenCornersOpportunity(){
        Stand__c currentStand = [SELECT Id, Open_Corners__c FROM Stand__c LIMIT 1];
        currentStand.Open_Corners__c = 3;
        update currentStand;
    }
    @isTest static void syncStandFromExpocad(){
        Stand__c currentStand = [SELECT Id, Name,ExpoCAD_ID__c, Account_ID__c,Account_Name__c,Trading_As__c FROM Stand__c];
        currentStand.Status_Synced_with_ExpoCAD__c='Requested';
        update currentStand;

        StandTriggerHandler.standResync(new List<Stand__c>{currentStand}, new Map<Id, Stand__c>{currentStand.Id => currentStand});
    }
}