@isTest
public class RelevantSegmentTriggerHandler_Test {
	@testSetup
    static void testData(){
        Id digitalEventRTId = Schema.SObjectType.Event__c.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
        
        //Instantiate the Pricebook2 record with StandardPricebookId
        Pricebook2 technologyEventPriceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        //Execute an update DML on the Pricebook2 record, to make IsStandard to true
        Update technologyEventPriceBook;

        Event__c eventTechnologyIntegrate = new Event__c();
        eventTechnologyIntegrate.RecordTypeId = digitalEventRTId;
        eventTechnologyIntegrate.Event_Portfolio__c = 'Technology';
        eventTechnologyIntegrate.Active__c = true;
        eventTechnologyIntegrate.Event_Category__c = 'Integrate';
        eventTechnologyIntegrate.Name= 'Technology Integrate Event';
        eventTechnologyIntegrate.Price_Book__c = technologyEventPriceBook.Id;
        eventTechnologyIntegrate.Event_Code__c = '1245';
        insert eventTechnologyIntegrate;
        
        Account acc = new Account();
        acc.Website = 'testWebsite';
        acc.Name = 'testName';
        acc.Industry = 'Technology';
        acc.Primary_Event_Category__c = 'Integrate';
        acc.Phone = '12345';
        acc.BillingCity = 'testCity';
        acc.BillingPostalCode = '9000';
        acc.BillingStreet = 'testStreet';
        acc.BillingCountry = 'testCountry';
        acc.BillingState = 'testState';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Event__c = eventTechnologyIntegrate.Id;
        opp.Name = 'testOppName';
        opp.StageName = 'Prospecting';
        opp.CloseDate = date.today() + 10;
        insert opp;
    }
    
    @isTest
    static void testInsertPrimarySegmentSameEventCategoryAcc(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Segment_Option__c segmentOption = new Segment_Option__c();
        segmentOption.Name = 'testOptionName';
        segmentOption.Event_Category__c = 'Integrate';
        insert segmentOption;
        
        Relevant_Segment__c primarySegment = new Relevant_Segment__c();
        primarySegment.Segment_Option__c = segmentOption.Id;
        primarySegment.Primary_Segment__c = true;
        primarySegment.Account__c = acc.Id;
        insert primarySegment;
        
        test.startTest();
        Relevant_Segment__c primarySegmentDupli = new Relevant_Segment__c();
        primarySegmentDupli.Segment_Option__c = segmentOption.Id;
        primarySegmentDupli.Primary_Segment__c = true;
        primarySegmentDupli.Account__c = acc.Id;
        Database.SaveResult result = Database.insert(primarySegmentDupli,false);
        test.stopTest();
        
        // assert
        System.assert(result.isSuccess() == false);
        System.assert(result.getErrors().size() == 1);
    }
    
    @isTest
    static void testUpdatePrimarySegmentSameEventCategoryAcc(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Segment_Option__c segmentOption = new Segment_Option__c();
        segmentOption.Name = 'testOptionName';
        segmentOption.Event_Category__c = 'Integrate';
        insert segmentOption;
        
        Relevant_Segment__c primarySegment = new Relevant_Segment__c();
        primarySegment.Segment_Option__c = segmentOption.Id;
        primarySegment.Primary_Segment__c = true;
        primarySegment.Account__c = acc.Id;
        insert primarySegment;
        
        
        Relevant_Segment__c primarySegmentDupli = new Relevant_Segment__c();
        primarySegmentDupli.Segment_Option__c = segmentOption.Id;
        primarySegmentDupli.Primary_Segment__c = false;
        primarySegmentDupli.Account__c = acc.Id;
        insert primarySegmentDupli;      
        
        
        test.startTest();
        primarySegmentDupli.Primary_Segment__c = true;
        Database.SaveResult result = Database.update(primarySegmentDupli,false);
        test.stopTest(); 
        
        // assert
        System.assert(result.isSuccess() == false);
        System.assert(result.getErrors().size() == 1);
    }
    
    @isTest
    static void testInsertPrimarySegmentSameEventCategoryOpp(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Segment_Option__c segmentOption = new Segment_Option__c();
        segmentOption.Name = 'testOptionName';
        segmentOption.Event_Category__c = 'Integrate';
        insert segmentOption;
        
        
        Relevant_Segment__c primarySegment = new Relevant_Segment__c();
        primarySegment.Segment_Option__c = segmentOption.Id;
        primarySegment.Primary_Segment__c = true;
        primarySegment.Opportunity__c = opp.Id;
        insert primarySegment;
        
        
        test.startTest();
        Relevant_Segment__c primarySegmentDupli = new Relevant_Segment__c();
        primarySegmentDupli.Segment_Option__c = segmentOption.Id;
        primarySegmentDupli.Primary_Segment__c = true;
        primarySegmentDupli.Opportunity__c = opp.Id;
        Database.SaveResult result = Database.insert(primarySegmentDupli,false);
        test.stopTest();

        // assert
        System.assert(result.isSuccess() == false);
        System.assert(result.getErrors().size() == 1);
    }
    
    @isTest
    static void testUpdatePrimarySegmentSameEventCategoryOpp(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Segment_Option__c segmentOption = new Segment_Option__c();
        segmentOption.Name = 'testOptionName';
        segmentOption.Event_Category__c = 'Integrate';
        insert segmentOption;
        
        Relevant_Segment__c primarySegment = new Relevant_Segment__c();
        primarySegment.Segment_Option__c = segmentOption.Id;
        primarySegment.Primary_Segment__c = true;
        primarySegment.Opportunity__c = opp.Id;
        insert primarySegment;
           
        Relevant_Segment__c primarySegmentDupli = new Relevant_Segment__c();
        primarySegmentDupli.Segment_Option__c = segmentOption.Id;
        primarySegmentDupli.Primary_Segment__c = false;
        primarySegmentDupli.Opportunity__c = opp.Id;
        insert primarySegmentDupli;
        
        test.startTest();
        primarySegmentDupli.Primary_Segment__c = true;
        Database.SaveResult result = Database.update(primarySegmentDupli,false);
        test.stopTest(); 
        
        // assert
        System.assert(result.isSuccess() == false);
        System.assert(result.getErrors().size() == 1);
    }
}