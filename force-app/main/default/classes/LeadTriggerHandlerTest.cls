/************************************************************************************************************
* @description : Test class for LeadTriggerHandler
* @author	  : Salesfix Dev - JL
* @date		: 12/13/2018
*************************************************************************************************************/
@isTest
private class LeadTriggerHandlerTest {

	@testSetup
	private static void setup() {
		Id digitalEventRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
		Id tradeShowRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Trade Show').getRecordTypeId();

		//Instantiate the Pricebook2 record with StandardPricebookId
		Pricebook2 technologyEventPriceBook = new Pricebook2(
			Id = Test.getStandardPricebookId(),
			IsActive = true
		);

		//Execute an update DML on the Pricebook2 record, to make IsStandard to true
		update technologyEventPriceBook;

		Account newAccount = TestDataFactory.createDifferentAccount('Contractor', '32323212111');
		insert newAccount;

		Account venueAccount = TestDataFactory.createDifferentAccount('Venue', '65656565212');
		venueAccount.Name = 'test VenueAcc';
		insert venueAccount;

		Event__c eventTechnologyIntegrate = TestDataFactory.createCustomEvents(null, 'Technology Integrate Event', technologyEventPriceBook.Id);
		eventTechnologyIntegrate.Active__c = false;
		eventTechnologyIntegrate.Event_Manager__c = UserInfo.getUserId();
		eventTechnologyIntegrate.Contractor__c = newAccount.Id;
		eventTechnologyIntegrate.Venue__c = venueAccount.Id;
		insert eventTechnologyIntegrate;

		Lead newLead = TestDataFactory.createNewLead();
		newLead.State = 'New South Wales';
		newLead.Street = 'testStreet';
		newLead.PostalCode = '9000';
		newLead.City = 'Sydney';
		newLead.Country = 'Australia';
		newLead.Event__c =  eventTechnologyIntegrate.id;
		newLead.Website = 'testSite.com';
		newLead.Event_Category__c = 'AOG Energy';
		insert newLead;

		System.assert(newLead != null);

		Industry_Option__c newIndustryOption = TestDataFactory.createIndustryOption();
		insert newIndustryOption;

		System.assert(newIndustryOption != null);

		Relevant_industry__c newRelevantIndustry = TestDataFactory.createRelevantIndustry(newLead.Id, newIndustryOption.Id);
		insert newRelevantIndustry;

		System.assert(newRelevantIndustry != null);

		Segment_Option__c newSegmentOption = TestDataFactory.createSegmentOption();
		newSegmentOption.Event_Category__c = newLead.Event_Category__c;
		insert newSegmentOption;

		System.assert(newSegmentOption != null);

		Relevant_Segment__c newReleventSegment = TestDataFactory.createRelevantSegment(newLead.Id, newSegmentOption.Id);
		newReleventSegment.Primary_Segment__c = true;
		insert newReleventSegment;

		System.assert(newReleventSegment != null);
	}

	/************************************************************************************************************
	* @description : Test method to successfully update the account field for relevant records
	* @author	  : Salesfix Dev - JL
	* @date		: 12/13/2018
	*************************************************************************************************************/
	@isTest
	private static void testSucessfulAccountUpdate() {
		Id leadId = [
			SELECT Id 
			FROM Lead 
			LIMIT 1
		].Id;

		Test.startTest();

		Database.leadConvert lc = new Database.leadConvert();

		lc.setLeadId(leadId);

		LeadStatus convertStatus = [
			SELECT Id, 
				   MasterLabel 
			FROM LeadStatus 
			WHERE IsConverted = true 
			LIMIT 1
		];

		lc.setConvertedStatus(convertStatus.MasterLabel);
		lc.setDoNotCreateOpportunity(false);

		Database.LeadConvertResult lcr = Database.convertLead(lc);

		System.assert(lcr.isSuccess());

		Id oppId = lc.getOpportunityId();

		Test.stopTest();

		Relevant_industry__c updatedRelevantIndustry = [
			SELECT Id, 
				   Account__c 
			FROM Relevant_industry__c LIMIT 1
		];

		System.assert(updatedRelevantIndustry.Account__c != null);

		Relevant_Segment__c updatedRelevantSegment = [
			SELECT Id, 
				   Account__c, 
				   Primary_Segment__c, 
				   Opportunity__c 
			FROM Relevant_Segment__c LIMIT 1
		];

		System.assert(updatedRelevantSegment.Account__c != null);
	}

	/************************************************************************************************************
	* @description : Test method to successfully update the account field for relevant records
	* @author	  : Salesfix Dev - JL
	* @date		: 12/13/2018
	*************************************************************************************************************/
	@isTest
	private static void testSucessfulFailedConversion() {
		Id leadId = [
			SELECT Id 
			FROM Lead 
			LIMIT 1
		].Id;

		List<Relevant_Segment__c> relevantSegment = new List<Relevant_Segment__c>([
			SELECT Id, 
				   Primary_Segment__c 
			FROM Relevant_Segment__c 
			WHERE Lead__c = :leadId
		]);

		relevantSegment.get(0).Primary_Segment__c = false;

		update relevantSegment;

		Test.startTest();

		try {
			Database.leadConvert lc = new Database.leadConvert();
			lc.setLeadId(leadId);

			LeadStatus convertStatus = [
				SELECT Id, 
					   MasterLabel 
				FROM LeadStatus 
				WHERE IsConverted=true LIMIT 1
			];

			lc.setConvertedStatus(convertStatus.MasterLabel);

			Database.LeadConvertResult lcr = Database.convertLead(lc);

			System.assert(lcr.isSuccess());

		} catch (Exception ex) {
			Boolean expectedExceptionThrown = ex.getMessage().contains('A Lead must have a primary segment added for the event related to that lead before being able to convert')? true : false;

			System.assertEquals(true, expectedExceptionThrown);
		}

		Test.stopTest();
	}

}