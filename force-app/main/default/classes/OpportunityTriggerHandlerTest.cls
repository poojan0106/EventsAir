/************************************************************************************************************
* @description  : Test Class for OpportunityTriggerHandler
* @author	   : Salesfix - CI
* @date		 : 2018-03-01
*************************************************************************************************************/

@isTest
private class OpportunityTriggerHandlerTest {

	/************************************************************************************************************
	* @description  : Setup test data
	* @author	   : Salesfix - CI
	* @date		 : 2018-03-01
	*************************************************************************************************************/
	@testSetup
	private static void setupTestData() {
		List<Account> accountList = TestDataFactory.createAccounts(1);
		insert accountList;
		System.assert(accountList != null);

		List<Contact> contactList = TestDataFactory.createContacts(accountList[0].id, 1);
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
       	newAccount.Name = 'test Contractor';
        newAccount.ABN__c = '98006864342';
        newAccount.Phone = '(213) 444-5555';
		insert newAccount;
		System.assert(newAccount != null);

		Account venueAccount = TestDataFactory.createDifferentAccount('Venue');
		venueAccount.Name = 'test Venue';
        venueAccount.ABN__c = '98006864141';
        venueAccount.Phone = '(216) 333-2222';
        venueAccount.Website = 'test1.com';
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
		dummyEvent.Event_Manager__c = UserInfo.getUserId();
		insert dummyEvent;
		System.assert(dummyEvent != null);

		Event__c nextEvent = TestDataFactory.createCustomEvents(dummyEvent.Id, 'Next Event', newPricebook2.Id);
		nextEvent.Contractor__c = newAccount.Id;
		nextEvent.Venue__c = venueAccount.Id;
		nextEvent.X1_Payment_Term__c = paymentTerm1.Id;
		nextEvent.X2_Payment_Term__c = paymentTerm2.Id;
		nextEvent.X3_Payment_Term__c = paymentTerm3.Id;
		nextEvent.Event_Manager__c = UserInfo.getUserId();
		insert nextEvent;
		System.assert(nextEvent != null);

		Event__c currentEvent = TestDataFactory.createCustomEvents(nextEvent.Id, 'Current Event', newPricebook2.Id);
		currentEvent.Contractor__c = newAccount.Id;
		currentEvent.Venue__c = venueAccount.Id;
		currentEvent.X1_Payment_Term__c = paymentTerm1.Id;
		currentEvent.X2_Payment_Term__c = paymentTerm2.Id;
		currentEvent.X3_Payment_Term__c = paymentTerm3.Id;
		currentEvent.Event_Manager__c = UserInfo.getUserId();
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
	* @description  : Check if Rebooking Opportunity will be created
	* @author	   : Salesfix - CI
	* @date		 : 2018-03-01
	*************************************************************************************************************/
	@isTest
	private static void testCreateRebookOpportunity() {
		List<Opportunity> createdOpp = [SELECT Id, Account.Name, AccountId, Rebooked__c, Event__c, Event__r.Next_Event__r.Name, Trading_As__c, Event__r.Event_Code__c FROM Opportunity LIMIT 1];

		Test.startTest();

		createdOpp[0].Rebooked__c = true;
		update createdOpp;

		Test.stopTest();

		String nameFilter = 'Rebook - ' + createdOpp[0].Event__r.Event_Code__c + ' - ' + createdOpp[0].Account.Name;
		List<Opportunity> rebookedOpps = [SELECT Id, Name FROM Opportunity WHERE Name = :nameFilter LIMIT 1];
	}

	/************************************************************************************************************
	* @description  : Check if Contact roles in the original Opportunity are carried over
	* @author	   : Salesfix - CI
	* @date		 : 2018-03-01
	*************************************************************************************************************/
	@isTest
	private static void testCopiedContactRole() {
		List<Opportunity> createdOpp = [SELECT Id, Account.Name, AccountId, Rebooked__c, Event__c, Event__r.Next_Event__r.Name, Trading_As__c, Event__r.Event_Code__c FROM Opportunity LIMIT 1];
		Id setupContactId = [SELECT Id FROM Contact WHERE LastName = 'Reyes 1'].Id;

		List<OpportunityContactRole> contactRolesList = TestDataFactory.createContactRoles(setupContactId, createdOpp[0].Id, 'Business User', 1);
		insert contactRolesList;

		Test.startTest();

		createdOpp[0].Rebooked__c = true;
		update createdOpp;

		Test.stopTest();

		String nameFilter = 'Rebook - ' + createdOpp[0].Event__r.Event_Code__c + ' - ' + createdOpp[0].Account.Name;
	}

	/************************************************************************************************************
	* @description  : Check if first contact role will be set as primary
	* @author	   : Salesfix - CI
	* @date		 : 2018-03-01
	*************************************************************************************************************/
	@isTest
	private static void testIfFirstCopiedContactRoleIsPrimary() {
		List<Opportunity> createdOpp = [SELECT Id, Account.Name, AccountId, Rebooked__c, Event__c, Event__r.Next_Event__r.Name, Event__r.Event_Code__c  FROM Opportunity LIMIT 1];
		Id setupContactId = [SELECT Id FROM Contact WHERE LastName = 'Reyes 1'].Id;

		List<OpportunityContactRole> contactRolesList = TestDataFactory.createContactRoles(setupContactId, createdOpp[0].Id, 'Business User', 1);
		insert contactRolesList;

		Test.startTest();

		createdOpp[0].Rebooked__c = true;
		update createdOpp;

		Test.stopTest();

		String nameFilter = 'Rebook - ' + createdOpp[0].Event__r.Event_Code__c + ' - ' + createdOpp[0].Account.Name;
	}

	/************************************************************************************************************
	* @description  : Method to update Stand for Opportunity
	* @author	   : Salesfix - JL
	* @date		 : 2018-03-01
	*************************************************************************************************************/
	@isTest
	private static void testUpdateStandOpportunity() {
		Id priceBookId = [SELECT Id FROM PriceBook2 WHERE Name = 'Security' LIMIT 1].Id;
		Id standId = [SELECT Id FROM Stand__c LIMIT 1].Id;
		List<Opportunity> createdOpp = [SELECT Id, Stand__c  FROM Opportunity LIMIT 1];
		createdOpp.get(0).Pricebook2Id = priceBookId;
		update createdOpp;

		Test.startTest();

		createdOpp.get(0).StageName = 'Proposal Agreement';
		createdOpp.get(0).Stand__c = standId;
		update createdOpp;

		Test.stopTest();

		List<OpportunityLineItem> oppLineItem = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :createdOpp.get(0).Id LIMIT 1];
		System.assert(!oppLineItem.isEmpty());
	}

	/************************************************************************************************************
	* @description  : Method to update Stand for Opportunity
	* @author	   : Salesfix - JL
	* @date		 : 2018-03-01
	*************************************************************************************************************/
	@isTest
	private static void testUpdatePavilionOpportunity() {
		Id priceBookId = [SELECT Id FROM PriceBook2 WHERE Name = 'Security' LIMIT 1].Id;
		Id pavilionId = [SELECT Id FROM Pavilion__c LIMIT 1].Id;
		List<Opportunity> createdOpp = [SELECT Id, Stand__c  FROM Opportunity LIMIT 1];
		createdOpp.get(0).Pricebook2Id = priceBookId;
		update createdOpp;

		Test.startTest();

		createdOpp.get(0).StageName = 'Proposal Agreement';
		createdOpp.get(0).Pavilion__c = pavilionId;
		update createdOpp;

		Test.stopTest();

		List<OpportunityLineItem> oppLineItem = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :createdOpp.get(0).Id LIMIT 1];
		System.assert(!oppLineItem.isEmpty());
	}

	/************************************************************************************************************
	* @description  : Method to update Stand for Opportunity
	* @author	   : Salesfix - JL
	* @date		 : 2018-03-01
	*************************************************************************************************************/
	@isTest
	private static void testInsertPavilionOpportunity() {
		Id eventId = [SELECT Id FROM Event__c WHERE Name = 'Current Event' LIMIT 1].Id;
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
		Id priceBookId = [SELECT Id FROM PriceBook2 WHERE Name = 'Security' LIMIT 1].Id;
		Id pavilionId = [SELECT Id FROM Pavilion__c LIMIT 1].Id;

		Trading_As__c newTradingAs = TestDataFactory.createTradingAs(accountId);
		insert newTradingAs;

		Test.startTest();

		List<Opportunity> opportunityList = TestDataFactory.createOpportunities(accountId, eventId, date.today(), Label.Opportunity_Stage_Closed_Won, 1);
		opportunityList.get(0).StageName = 'Proposal Agreement';
		opportunityList.get(0).Trading_As__c = newTradingAs.Id;
		opportunityList.get(0).Pricebook2Id = priceBookId;
		opportunityList.get(0).Pavilion__c = pavilionId;
		opportunityList.get(0).Agreement_Signed__c = true;
		insert opportunityList;

		Test.stopTest();

		List<OpportunityLineItem> oppLineItem = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opportunityList.get(0).Id LIMIT 1];
		System.assert(!oppLineItem.isEmpty());
	}

	/************************************************************************************************************
	* @description  : Method to update Stand for Opportunity
	* @author	   : Salesfix - JL
	* @date		 : 2018-03-01
	*************************************************************************************************************/

	@isTest
	private static void testUpdateStandOpportunityPavilion() {
		Id priceBookId = [SELECT Id FROM PriceBook2 WHERE Name = 'Security' LIMIT 1].Id;
		Id standId = [SELECT Id FROM Stand__c LIMIT 1].Id;
		Id pavilionId = [SELECT Id FROM Pavilion__c LIMIT 1].Id;

		List<Opportunity> createdOpp = [SELECT Id, Stand__c, Pavilion__c FROM Opportunity LIMIT 1];
		createdOpp.get(0).Pricebook2Id = priceBookId;
		createdOpp.get(0).Pavilion__c = pavilionId;
		update createdOpp;

		Test.startTest();

		createdOpp.get(0).StageName = 'Proposal Agreement';
		createdOpp.get(0).Stand__c = standId;
		createdOpp.get(0).Pavilion__c = null;
		update createdOpp;

		Test.stopTest();

		List<OpportunityLineItem> oppLineItem = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :createdOpp.get(0).Id LIMIT 1];
		System.assert(!oppLineItem.isEmpty());
	}

	/************************************************************************************************************
	* @description  : Method to update parent Downgrade opportunity to Clost Won and for New contact role
	* @author	   : Salesfix - JL
	* @date		 : 2018-04-11
	*************************************************************************************************************/
	@isTest
	private static void testUpdateDowngradeOpportunityAndInsertContactRole() {
		Id eventId = [SELECT Id FROM Event__c WHERE Name = 'Current Event' LIMIT 1].Id;
		Id accountId = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1].Id;
		Id contactId = [SELECT Id FROM Contact LIMIT 1].Id;

		Opportunity parentOpportunity = [SELECT Id, StageName FROM Opportunity LIMIT 1];
		OpportunityContactRole ocrForParentOpp = new OpportunityContactRole();
		ocrForParentOpp.ContactId = contactId;
		ocrForParentOpp.IsPrimary = true;
		ocrForParentOpp.OpportunityId = parentOpportunity.Id;
		ocrForParentOpp.Role = 'Business User';
		insert ocrForParentOpp;

		Trading_As__c newTradingAs = TestDataFactory.createTradingAs(accountId);
		insert newTradingAs;

		List<Opportunity> downgradeOpporutnity = TestDataFactory.createOpportunities(accountId, eventId, date.today(), 'Proposal Agreement', 1);
		downgradeOpporutnity.get(0).Parent_Downgrade_Opportunity__c = parentOpportunity.Id;
		downgradeOpporutnity.get(0).Type = Label.Opportunity_Type_Downgrade;
		downgradeOpporutnity.get(0).Trading_As__c = newTradingAs.Id;
		insert downgradeOpporutnity;

		Test.startTest();

		Opportunity downgradedOpportunity = [SELECT Id FROM Opportunity WHERE Id = :downgradeOpporutnity.get(0).Id];
		downgradedOpportunity.StageName = Label.Opportunity_Stage_Closed_Won;
		downgradedOpportunity.Agreement_Signed__c = true;
		update downgradedOpportunity;

		Test.stopTest();

		List<OpportunityContactRole> newContactRole = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :downgradedOpportunity.Id LIMIT 1];
		System.assert(newContactRole.size() == 1);

		List<Opportunity> updatedParentOpporutnity = [SELECT Id, StageName, Reason_Lost__c FROM Opportunity WHERE Id = :parentOpportunity.Id];
	}

	/************************************************************************************************************
	* @description  : Method to update parent Downgrade opportunity to Close Lost
	* @author	   : Salesfix - JL
	* @date		 : 2018-04-11
	*************************************************************************************************************/
	@isTest
	private static void testUpdateDowngradeOpportunityClosedLost() {
		Id eventId = [SELECT Id FROM Event__c WHERE Name = 'Current Event' LIMIT 1].Id;
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
		Id contactId = [SELECT Id FROM Contact LIMIT 1].Id;
		Opportunity parentOpportunity = [SELECT Id, StageName FROM Opportunity LIMIT 1];
		OpportunityContactRole ocrForParentOpp = new OpportunityContactRole();
		ocrForParentOpp.ContactId = contactId;
		ocrForParentOpp.IsPrimary = true;
		ocrForParentOpp.OpportunityId = parentOpportunity.Id;
		ocrForParentOpp.Role = 'Business User';
		insert ocrForParentOpp;

		Trading_As__c newTradingAs = TestDataFactory.createTradingAs(accountId);
		insert newTradingAs;

		List<Opportunity> downgradeOpporutnity = TestDataFactory.createOpportunities(accountId, eventId, date.today(), 'Prospecting', 1);
		downgradeOpporutnity.get(0).Parent_Downgrade_Opportunity__c = parentOpportunity.Id;
		downgradeOpporutnity.get(0).Type = Label.Opportunity_Type_Downgrade;
		downgradeOpporutnity.get(0).RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Closed').getRecordTypeId();//ADDED BY RAY
		downgradeOpporutnity.get(0).Reason_Lost__c = Label.Reason_Lost_Downgraded;
		downgradeOpporutnity.get(0).Trading_As__c = newTradingAs.Id;
		insert downgradeOpporutnity;

		Test.startTest();

		Opportunity downgradedOpportunity = [SELECT Id FROM Opportunity WHERE Id = :downgradeOpporutnity.get(0).Id];

		downgradedOpportunity.StageName = Label.Opportunity_Stage_Closed_Lost;

		try {
			update downgradedOpportunity;

		} catch (Exception ex) {
			System.debug('@@@ex: ' + ex.getMessage());
		}

		Test.stopTest();

		List<OpportunityContactRole> newContactRole = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :downgradedOpportunity.Id LIMIT 1];
		System.assert(newContactRole.size() == 1);

		List<Opportunity> updatedParentOpporutnity = [SELECT Id, StageName, Reason_Lost__c FROM Opportunity WHERE Id = :parentOpportunity.Id];
		System.assert(updatedParentOpporutnity.get(0).StageName == Label.Opportunity_Stage_Closed_Won);
	}

	/************************************************************************************************************
	* @description  : Method to update parent Upgrade opportunity to Close Won
	* @author	   : Salesfix - JL
	* @date		 : 2018-04-11
	*************************************************************************************************************/
	@isTest
	private static void testUpdateUpgradeOpportunityClosedWon() {
		Id eventId = [SELECT Id FROM Event__c WHERE Name = 'Current Event' LIMIT 1].Id;
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
		Id contactId = [SELECT Id FROM Contact LIMIT 1].Id;
		Opportunity parentOpportunity = [SELECT Id, StageName FROM Opportunity LIMIT 1];
		OpportunityContactRole ocrForParentOpp = new OpportunityContactRole();
		ocrForParentOpp.ContactId = contactId;
		ocrForParentOpp.IsPrimary = true;
		ocrForParentOpp.OpportunityId = parentOpportunity.Id;
		ocrForParentOpp.Role = 'Business User';
		insert ocrForParentOpp;

		Trading_As__c newTradingAs = TestDataFactory.createTradingAs(accountId);
		insert newTradingAs;

		List<Opportunity> downgradeOpporutnity = TestDataFactory.createOpportunities(accountId, eventId, date.today(), 'Proposal Agreement', 1);
		downgradeOpporutnity.get(0).Parent_Upgrade_Opportunity__c = parentOpportunity.Id;
		downgradeOpporutnity.get(0).Type = Label.Opportunity_Type_Upgrade;
		downgradeOpporutnity.get(0).Trading_As__c = newTradingAs.Id;
		insert downgradeOpporutnity;

		Test.startTest();
		Opportunity downgradedOpportunity = [SELECT Id FROM Opportunity WHERE Id = :downgradeOpporutnity.get(0).Id];
		downgradedOpportunity.StageName = Label.Opportunity_Stage_Closed_Won;
		downgradedOpportunity.Agreement_Signed__c = true;
		update downgradedOpportunity;
		Test.stopTest();

		List<OpportunityContactRole> newContactRole = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :downgradedOpportunity.Id LIMIT 1];
		System.assert(newContactRole.size() == 1);
		List<Opportunity> updatedParentOpporutnity = [SELECT Id, StageName, Reason_Lost__c FROM Opportunity WHERE Id = :parentOpportunity.Id];
		System.assert(!updatedParentOpporutnity.isEmpty());
	}

	/************************************************************************************************************
	* @description  : Method to update parent Upgrade opportunity to Close Lost
	* @author	   : Salesfix - JL
	* @date		 : 2018-04-11
	*************************************************************************************************************/
	@isTest
	private static void testUpdateUpgradeOpportunityClosedLost() {
		Id eventId = [SELECT Id FROM Event__c WHERE Name = 'Current Event' LIMIT 1].Id;
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
		Id contactId = [SELECT Id FROM Contact LIMIT 1].Id;
		Opportunity parentOpportunity = [SELECT Id, StageName FROM Opportunity LIMIT 1];
		OpportunityContactRole ocrForParentOpp = new OpportunityContactRole();
		ocrForParentOpp.ContactId = contactId;
		ocrForParentOpp.IsPrimary = true;
		ocrForParentOpp.OpportunityId = parentOpportunity.Id;
		ocrForParentOpp.Role = 'Business User';
		insert ocrForParentOpp;

		Trading_As__c newTradingAs = TestDataFactory.createTradingAs(accountId);
		insert newTradingAs;

		List<Opportunity> downgradeOpporutnity = TestDataFactory.createOpportunities(accountId, eventId, date.today(), 'Prospecting', 1);
		downgradeOpporutnity.get(0).Parent_Upgrade_Opportunity__c = parentOpportunity.Id;
		downgradeOpporutnity.get(0).Type = Label.Opportunity_Type_Upgrade;
		downgradeOpporutnity.get(0).RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Closed').getRecordTypeId();//ADDED BY RAY
		downgradeOpporutnity.get(0).Reason_Lost__c = Label.Reason_Lost_Upgraded;
		downgradeOpporutnity.get(0).Trading_As__c = newTradingAs.Id;
		insert downgradeOpporutnity;

		Test.startTest();
		Opportunity downgradedOpportunity = [SELECT Id FROM Opportunity WHERE Id = :downgradeOpporutnity.get(0).Id];
		downgradedOpportunity.StageName = Label.Opportunity_Stage_Closed_Lost;
		try {
			update downgradedOpportunity;
		} catch (Exception ex) {
			System.debug('@@@ex: ' + ex.getMessage());
		}
		Test.stopTest();

		List<OpportunityContactRole> newContactRole = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :downgradedOpportunity.Id LIMIT 1];
		System.assert(newContactRole.size() == 1);
		List<Opportunity> updatedParentOpporutnity = [SELECT Id, StageName, Reason_Lost__c FROM Opportunity WHERE Id = :parentOpportunity.Id];
		System.assert(updatedParentOpporutnity.get(0).StageName == Label.Opportunity_Stage_Closed_Won);
	}

	/************************************************************************************************************
	* @description  : Method for Corner
	* @author	   : Salesfix - JL
	* @date		 : 2018-04-11
	*************************************************************************************************************/
	@isTest
	private static void testCornerPricing() {
		Id eventId = [SELECT Id FROM Event__c WHERE Name = 'Current Event' LIMIT 1].Id;
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
		Stand__c stand = [SELECT Id, Open_Corners__c FROM Stand__c LIMIT 1];

		Trading_As__c newTradingAs = TestDataFactory.createTradingAs(accountId);
		insert newTradingAs;

		List<Opportunity> opportunityList = TestDataFactory.createOpportunities(accountId, eventId, date.today(), Label.Opportunity_Stage_Closed_Won, 1);
		opportunityList.get(0).Trading_As__c = newTradingAs.Id;
		opportunityList.get(0).Agreement_Signed__c = true;
		insert opportunityList;

		Test.startTest();
		opportunityList.get(0).Stand__c = stand.Id;
		update opportunityList;
		Test.stopTest();
	}

	/************************************************************************************************************
	* @description  : Method for Corner negative testing
	* @author	   : Salesfix - JL
	* @date		 : 2018-04-11
	*************************************************************************************************************/
	@isTest
	private static void testCornerPricingNegative() {
		Id eventId = [SELECT Id FROM Event__c WHERE Name = 'Current Event' LIMIT 1].Id;
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
		Stand__c stand = [SELECT Id, Open_Corners__c FROM Stand__c LIMIT 1];
		stand.Open_Corners__c = 3;
		update stand;

		Trading_As__c newTradingAs = TestDataFactory.createTradingAs(accountId);
		insert newTradingAs;

		List<Opportunity> opportunityList = TestDataFactory.createOpportunities(accountId, eventId, date.today(), Label.Opportunity_Stage_Closed_Won, 1);
		opportunityList.get(0).Trading_As__c = newTradingAs.Id;
		opportunityList.get(0).Agreement_Signed__c = true;
		insert opportunityList;

		Test.startTest();
		opportunityList.get(0).Stand__c = stand.Id;
		update opportunityList;
		Test.stopTest();
	}

	/************************************************************************************************************
	* @description  : Method for Corner negative testing2
	* @author	   : Salesfix - JL
	* @date		 : 2018-04-11
	*************************************************************************************************************/
	@isTest
	private static void testCornerPricingNegative2() {
		Id eventId = [SELECT Id FROM Event__c WHERE Name = 'Current Event' LIMIT 1].Id;
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
		Stand__c stand = [SELECT Id, Open_Corners__c FROM Stand__c LIMIT 1];
		stand.Open_Corners__c = 3;
		update stand;

		Trading_As__c newTradingAs = TestDataFactory.createTradingAs(accountId);
		insert newTradingAs;

		List<Opportunity> opportunityList = TestDataFactory.createOpportunities(accountId, eventId, date.today(), Label.Opportunity_Stage_Closed_Won, 1);
		opportunityList.get(0).Trading_As__c = newTradingAs.Id;
		opportunityList.get(0).Agreement_Signed__c = true;
		insert opportunityList;

		opportunityList.get(0).Stand__c = stand.Id;
		update opportunityList;

		Test.startTest();
		opportunityList.get(0).Stand__c = null;
		update opportunityList;
		Test.stopTest();

		List<OpportunityLineItem> oppLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opportunityList.get(0).Id];
		System.assert(oppLineItems.isEmpty());
	}

	/************************************************************************************************************
	* @description  : Method for Withdrawal
	* @author	   : Salesfix - JL
	* @date		 : 2018-04-11
	*************************************************************************************************************/
	@isTest
	private static void testWithdrawal() {
		Id eventId = [SELECT Id FROM Event__c WHERE Name = 'Current Event' LIMIT 1].Id;
		Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
		Id customPricebook = [SELECT Id FROM Pricebook2 WHERE Name ='Security' LIMIT 1].Id;
		Id pricebookId = Test.getStandardPricebookId();
		Opportunity parentOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

		Trading_As__c newTradingAs = TestDataFactory.createTradingAs(accountId);
		insert newTradingAs;

		List<Opportunity> opportunityList = TestDataFactory.createOpportunities(accountId, eventId, date.today(), Label.Opportunity_Stage_Closed_Won, 1);
		opportunityList.get(0).Trading_As__c = newTradingAs.Id;
		opportunityList.get(0).Agreement_Signed__c = true;
		opportunityList.get(0).Parent_Withdrawal_Opportunity__c = parentOpportunity.Id;
		insert opportunityList;

		opportunityList.get(0).Pricebook2Id = pricebookId;
		update opportunityList;

		Test.startTest();
		opportunityList.get(0).Pricebook2Id = customPricebook;
		opportunityList.get(0).Is_Withdrawal__c = true;
		update opportunityList;
		Test.stopTest();
	}

	/************************************************************************************************************
	* @description  : Method for Exception
	* @author	   : Salesfix - JL
	* @date		 : 2018-04-11
	*************************************************************************************************************/
	@isTest
	private static void testExceptionMethod() {
		Email_Error__c emailError = TestDataFactory.createEmailCustomSetting();
		insert emailError;
		System.assert(emailError != null);

		Test.startTest();
		OpportunityTriggerHandler oppHandler = new OpportunityTriggerHandler();
		oppHandler.sendEmailError('test email error');
		Test.stopTest();
	}

	/************************************************************************************************************
	* @description  : Method to call sendEmailForNotFound
	* @author	   : Salesfix - Ray
	* @date		 : July 3, 2019
	*************************************************************************************************************/
	@isTest
	private static void sendEmailForNotFound_Test() {
		List<Opportunity> createdOpp = [SELECT Id, Name, Account.Name, Pricebook2Id, AccountId, Rebooked__c, Event__c, Stand__c, 
										Stand__r.Name, Event__r.Next_Event__r.Name, Event__r.Event_Code__c  FROM Opportunity LIMIT 1];

		Test.startTest();
		List<OpportunityTriggerHandler.CornerWrapper> wrapperList = new List<OpportunityTriggerHandler.CornerWrapper>();
		OpportunityTriggerHandler.CornerWrapper wrapperRecord = OpportunityTriggerHandler.mapValuesTOWrapper(createdOpp[0]);
		wrapperList.add(wrapperRecord);
		OpportunityTriggerHandler.sendEmailForNotFound(wrapperList);
		Test.stopTest();
	}

	/************************************************************************************************************
	* @description  : Method to test getOpptyIdWithParentOppty Method
	* @author	   : Salesfix - Ray
	* @date		 : July 4, 2019
	*************************************************************************************************************/	  
	@isTest
	private static void getOpptyIdWithParentOppty_Test() {
		Account accRec = [SELECT Id FROM Account LIMIT 1];	  
		Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];

		OpportunityLineItem opptyLineItemRecord = new OpportunityLineItem();
		opptyLineItemRecord.OpportunityId = oppRec.Id;
		opptyLineItemRecord.Product2Id = [SELECT Id FROM Product2 WHERE Name = 'Public Liability Insurance'].Id;//pliProduct.Id;
		opptyLineItemRecord.Quantity = 1;
		opptyLineItemRecord.TotalPrice = 100;
		insert opptyLineItemRecord;

		List<OpportunityLineItem> opptyLineItemListParent = new List<OpportunityLineItem>([SELECT Id FROM OpportunityLineItem WHERE opportunityId = :oppRec.Id]);
		System.assertEquals(1, opptyLineItemListParent.size());// TO TEST THAT THE PARENT OPPTY HAS LINE ITEM

		Test.startTest();
		List<Opportunity> opportunityList = TestDataFactory.createOpportunities(accRec.id, null, date.today(), Label.Opportunity_Stage_Closed_Won, 1);
		opportunityList.get(0).Name = 'Test Opp Ray' + 1;
		opportunityList.get(0).Agreement_Signed__c = true;
		opportunityList.get(0).Parent_Downgrade_Opportunity__c = oppRec.Id;
		insert opportunityList; 
		Test.stopTest();

		List<OpportunityLineItem> opptyLineItemListNew = new List<OpportunityLineItem>([SELECT Id FROM OpportunityLineItem WHERE opportunityId = :opportunityList.get(0).Id]);
		System.assertEquals(1, opptyLineItemListNew.size());// TO TEST THAT THE NEW OPPTY HAS LINE ITEM
	}

	/************************************************************************************************************
	* @description  : Method to test validateOnChangeToNegotiation Method
	* @author	   : Salesfix - Ray
	* @date		 : July 4, 2019
	*************************************************************************************************************/	  
	@isTest
	private static void validateOnChangeToNegotiation_Test() {
		Id digitalEventRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
		Id tradeShowRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Trade Show').getRecordTypeId();
		Id mumbrellaEventRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Mumbrella').getRecordTypeId();
		Id contractorId = [SELECT Id FROM Account WHERE Name = 'test Contractor' LIMIT 1].Id;
        Date today = system.today();
        
        //Instantiate the Pricebook2 record with StandardPricebookId
		Pricebook2 technologyEventPriceBook = new Pricebook2(
			Id = Test.getStandardPricebookId(), 
			IsActive = true
		);

		//Execute an update DML on the Pricebook2 record, to make IsStandard to true
		update technologyEventPriceBook;

        Event__c eventTechnologyIntegrate1 = new Event__c();
		eventTechnologyIntegrate1.RecordTypeId = tradeShowRTId;
		eventTechnologyIntegrate1.Event_Portfolio__c = 'Technology';
		eventTechnologyIntegrate1.Active__c = false;
		eventTechnologyIntegrate1.Event_Category__c = 'Integrate';
		eventTechnologyIntegrate1.Name= 'Next Event Technology Integrate Event';
		eventTechnologyIntegrate1.Price_Book__c = technologyEventPriceBook.Id;
		eventTechnologyIntegrate1.Event_Code__c = '1245';
       	eventTechnologyIntegrate1.Close_Date__c = today.addYears(1);
        eventTechnologyIntegrate1.Cooling_Off_Date__c = today.addYears(1);
		eventTechnologyIntegrate1.Contractor__c = contractorId;
		insert eventTechnologyIntegrate1; 

		Event__c eventTechnologyIntegrate = new Event__c();
		eventTechnologyIntegrate.RecordTypeId = digitalEventRTId;
		eventTechnologyIntegrate.Event_Portfolio__c = 'Technology';
		eventTechnologyIntegrate.Active__c = true;
		eventTechnologyIntegrate.Event_Category__c = 'Integrate';
		eventTechnologyIntegrate.Name= 'Technology Integrate Event';
		eventTechnologyIntegrate.Price_Book__c = technologyEventPriceBook.Id;
		eventTechnologyIntegrate.Event_Code__c = '1245';
        eventTechnologyIntegrate.Next_Event__c = eventTechnologyIntegrate1.Id;
		insert eventTechnologyIntegrate;

		Account acc = new Account();
		acc.Website = 'testWebsite';
		acc.Name = 'testName';
		acc.Industry = 'Technology';
		acc.Phone = '12345';
		acc.BillingCity = 'Sydney';
		acc.BillingPostalCode = '9000';
		acc.BillingStreet = 'testStreet';
		acc.BillingCountry = 'Australia';
		acc.BillingState = 'New South Wales';
		insert acc;

		Opportunity opp = new Opportunity();
		opp.AccountId = acc.Id;
		opp.Event__c = eventTechnologyIntegrate.Id;
		opp.Name = 'testOppName';
		opp.StageName = 'Prospecting';
		opp.CloseDate = date.today() + 10;
		insert opp;

		Segment_Option__c segmentOption = new Segment_Option__c();
		segmentOption.Name = 'testOptionName';
		segmentOption.Event_Category__c = 'Integrate';
		insert segmentOption;

		Relevant_Segment__c primarySegmentAcc = new Relevant_Segment__c();
		primarySegmentAcc.Segment_Option__c = segmentOption.Id;
		primarySegmentAcc.Primary_Segment__c = true;
		primarySegmentAcc.Account__c = acc.Id;
		insert primarySegmentAcc;

		Relevant_Segment__c primarySegment = new Relevant_Segment__c();
		primarySegment.Segment_Option__c = segmentOption.Id;
		primarySegment.Primary_Segment__c = false;
		primarySegment.Opportunity__c = opp.Id;
		insert primarySegment;

		List<Relevant_Segment__c> primarySegments = new List<Relevant_Segment__c>([
			SELECT Id, 
				   Primary_Segment__c, 
				   Event_Category__c, 
				   Account__c, 
				   Lead__c, 
				   Lead__r.Event_Category__c, 
				   Opportunity__c, 
				   Opportunity__r.Event_Category__c 
			FROM Relevant_Segment__c 
			WHERE Opportunity__c = :opp.Id
		]);

		Test.startTest();
		opp.StageName = 'Negotiation';
		Database.SaveResult result = Database.update(opp, false);
		Test.stopTest(); 

		// assert
		System.assert(result.isSuccess() == false);
		System.assert(result.getErrors().size() == 1);
	}

	/************************************************************************************************************
	* @description  : Method to test validateOnChangeToNegotiation Method
	* @author	   : Salesfix - Ray
	* @date		 : July 4, 2019
	*************************************************************************************************************/	  
	@isTest
	private static void validateOnChangeToNegotiationAccount_Test() {
		Id digitalEventRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
		Id mumbrellaEventRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Mumbrella').getRecordTypeId();
        Id tradeShowRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Trade Show').getRecordTypeId();
        Id contractorId = [SELECT Id FROM Account WHERE Name = 'test Contractor' LIMIT 1].Id;
        Date today = system.today();
        //Instantiate the Pricebook2 record with StandardPricebookId
		Pricebook2 technologyEventPriceBook = new Pricebook2(
			Id = Test.getStandardPricebookId(), 
			IsActive = true
		);

		//Execute an update DML on the Pricebook2 record, to make IsStandard to true
		update technologyEventPriceBook;
	
       	Event__c eventTechnologyIntegrate1 = new Event__c();
		eventTechnologyIntegrate1.RecordTypeId = tradeShowRTId;
		eventTechnologyIntegrate1.Event_Portfolio__c = 'Technology';
		eventTechnologyIntegrate1.Active__c = false;
		eventTechnologyIntegrate1.Event_Category__c = 'Integrate';
		eventTechnologyIntegrate1.Name= 'Next Event Technology Integrate Event';
		eventTechnologyIntegrate1.Price_Book__c = technologyEventPriceBook.Id;
		eventTechnologyIntegrate1.Event_Code__c = '1245';
       	eventTechnologyIntegrate1.Close_Date__c = today.addYears(1);
        eventTechnologyIntegrate1.Cooling_Off_Date__c = today.addYears(1);
		eventTechnologyIntegrate1.Contractor__c = contractorId;
		insert eventTechnologyIntegrate1;
		
		Event__c eventTechnologyIntegrate = new Event__c();
		eventTechnologyIntegrate.RecordTypeId = digitalEventRTId;
		eventTechnologyIntegrate.Event_Portfolio__c = 'Technology';
		eventTechnologyIntegrate.Active__c = true;
		eventTechnologyIntegrate.Event_Category__c = 'Integrate';
		eventTechnologyIntegrate.Name= 'Technology Integrate Event';
		eventTechnologyIntegrate.Price_Book__c = technologyEventPriceBook.Id;
		eventTechnologyIntegrate.Event_Code__c = '1245';
       	eventTechnologyIntegrate.Next_Event__c = eventTechnologyIntegrate1.Id;
		insert eventTechnologyIntegrate;

		Account acc = new Account();
		acc.Website = 'testWebsite';
		acc.Name = 'testName';
		acc.Industry = 'Technology';
		acc.Phone = '12345';
		acc.BillingCity = 'Sydney';
		acc.BillingPostalCode = '9000';
		acc.BillingStreet = 'testStreet';
		acc.BillingCountry = 'Australia';
		acc.BillingState = 'New South Wales';
		insert acc;

		Opportunity opp = new Opportunity();
		opp.AccountId = acc.Id;
		opp.Event__c = eventTechnologyIntegrate.Id;
		opp.Name = 'testOppName';
		opp.StageName = 'Prospecting';
		opp.CloseDate = date.today() + 10;
		insert opp;

		Segment_Option__c segmentOption = new Segment_Option__c();
		segmentOption.Name = 'testOptionName';
		segmentOption.Event_Category__c = 'Integrate';
		insert segmentOption;

		Relevant_Segment__c primarySegment = new Relevant_Segment__c();
		primarySegment.Segment_Option__c = segmentOption.Id;
		primarySegment.Primary_Segment__c = false;
		primarySegment.Opportunity__c = opp.Id;
		insert primarySegment;

		primarySegment.Primary_Segment__c = true;
		update primarySegment;

		List<Relevant_Segment__c> primarySegments = new List<Relevant_Segment__c>([
			SELECT Id, 
				   Primary_Segment__c, 
				   Event_Category__c, 
				   Account__c, 
				   Lead__c, 
				   Lead__r.Event_Category__c, 
				   Opportunity__c, 
				   Opportunity__r.Event_Category__c 
			FROM Relevant_Segment__c 
			WHERE Opportunity__c = :opp.Id
		]);

		Test.startTest();

		opp.StageName = 'Negotiation';
		Database.SaveResult result = Database.update(opp, false);

		Test.stopTest(); 

		// assert
		System.assert(result.isSuccess() == false);
		System.assert(result.getErrors().size() == 1);
	}

	/************************************************************************************************************
	* @description  : Method to test validateOnChangeToNegotiation Method
	* @author	   : Salesfix - Ray
	* @date		 : July 4, 2019
	*************************************************************************************************************/	  
	@isTest
	private static void addPrimarySegmentToNewOpp_Test() {
		Id digitalEventRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
		Id mumbrellaEventRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Mumbrella').getRecordTypeId();
		Id tradeShowRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Trade Show').getRecordTypeId();
		Id contractorId = [SELECT Id FROM Account WHERE Name = 'test Contractor' LIMIT 1].Id;
        Date today = system.today();
        //Instantiate the Pricebook2 record with StandardPricebookId
		Pricebook2 technologyEventPriceBook = new Pricebook2(
			Id = Test.getStandardPricebookId(), 
			IsActive = true
		);

		//Execute an update DML on the Pricebook2 record, to make IsStandard to true
		update technologyEventPriceBook;

        Event__c eventTechnologyIntegrate1 = new Event__c();
		eventTechnologyIntegrate1.RecordTypeId = tradeShowRTId;
		eventTechnologyIntegrate1.Event_Portfolio__c = 'Technology';
		eventTechnologyIntegrate1.Active__c = false;
		eventTechnologyIntegrate1.Event_Category__c = 'Integrate';
		eventTechnologyIntegrate1.Name= 'Next Event Technology Integrate Event';
		eventTechnologyIntegrate1.Price_Book__c = technologyEventPriceBook.Id;
		eventTechnologyIntegrate1.Event_Code__c = '1245';
       	eventTechnologyIntegrate1.Close_Date__c = today.addYears(1);
        eventTechnologyIntegrate1.Cooling_Off_Date__c = today.addYears(1);
        eventTechnologyIntegrate1.Contractor__c = contractorId;
		insert eventTechnologyIntegrate1;
        
		Event__c eventTechnologyIntegrate = new Event__c();
		eventTechnologyIntegrate.RecordTypeId = digitalEventRTId;
		eventTechnologyIntegrate.Event_Portfolio__c = 'Technology';
		eventTechnologyIntegrate.Active__c = true;
		eventTechnologyIntegrate.Event_Category__c = 'Integrate';
		eventTechnologyIntegrate.Name= 'Technology Integrate Event';
		eventTechnologyIntegrate.Price_Book__c = technologyEventPriceBook.Id;
		eventTechnologyIntegrate.Event_Code__c = '1245';
       	eventTechnologyIntegrate.Next_Event__c = eventTechnologyIntegrate1.Id;
		insert eventTechnologyIntegrate;

		Account acc = new Account();
		acc.Website = 'testWebsite';
		acc.Name = 'testName';
		acc.Industry = 'Technology';
		acc.Phone = '12345';
		acc.BillingCity = 'Sydney';
		acc.BillingPostalCode = '9000';
		acc.BillingStreet = 'testStreet';
		acc.BillingCountry = 'Australia';
		acc.BillingState = 'New South Wales';
		insert acc;

		Segment_Option__c segmentOption = new Segment_Option__c();
		segmentOption.Name = 'testOptionName';
		segmentOption.Event_Category__c = 'Integrate';
		insert segmentOption;

		Relevant_Segment__c primarySegmentAccount = new Relevant_Segment__c();
		primarySegmentAccount.Segment_Option__c = segmentOption.Id;
		primarySegmentAccount.Primary_Segment__c = true;
		primarySegmentAccount.Account__c = acc.Id;
		insert primarySegmentAccount;

		Test.startTest();

		Opportunity opp = new Opportunity();
		opp.AccountId = acc.Id;
		opp.Event__c = eventTechnologyIntegrate.Id;
		opp.Name = 'testOppName';
		opp.StageName = 'Prospecting';
		opp.CloseDate = date.today() + 10;
		Database.SaveResult result = Database.insert(opp, false);

		Test.stopTest();

		List<Relevant_Segment__c> relatedSegmentOnOpp = new List<Relevant_Segment__c>([
			SELECT Id 
			FROM Relevant_Segment__c 
			WHERE Opportunity__c = :opp.Id 
			LIMIT 1
		]);

		System.assert(result.isSuccess() == true);
		System.assertEquals(1, relatedSegmentOnOpp.size());
	}
}