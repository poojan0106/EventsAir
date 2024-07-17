@isTest
public class OpportunityStageNameUpdateTest {
    @isTest
    static void testBatchExecution() {  
        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i = 0; i < 10; i++) { 
            oppList.add(new Opportunity(Name = 'Test Opportunity ' + i, StageName = 'Prospecting', CloseDate = Date.today()));
        }
        insert oppList;
        
        List<List<Id>> recordIdCollections = new List<List<Id>>();
        List<Id> opportunityIds = new List<Id>();
        for(Opportunity opp : oppList) { 
            opportunityIds.add(opp.Id);
            if(opportunityIds.size() == 10) {
                recordIdCollections.add(new List<Id>(opportunityIds));
                opportunityIds.clear();
            }
        }
        if(!opportunityIds.isEmpty()) {
            recordIdCollections.add(opportunityIds);
        }
        
        Test.startTest();
		List<List<Id>> result = OpportunityStageNameUpdate.updateField(recordIdCollections);   
        Test.stopTest();
        
        System.assertEquals(recordIdCollections, result);

        List<Opportunity> updatedOpportunities = [SELECT Id, StageName FROM Opportunity WHERE Id IN :opportunityIds];
        for(Opportunity opp : updatedOpportunities) {
            System.assertEquals('Closed Won', opp.StageName);
        }
    }

    @isTest
    static void testUpdateFieldWithEmptyInnerLists() {
        List<List<Id>> recordIdCollections = new List<List<Id>>();
        recordIdCollections.add(new List<Id>());

        Test.startTest();
        List<List<Id>> result = OpportunityStageNameUpdate.updateField(recordIdCollections);
        Test.stopTest();

        // Verify that the method returns the same empty inner lists
        System.assertEquals(true, result.get(0).isEmpty(), 'The method should return the same empty inner lists');
    }
    
    @isTest
    static void testUpdateFieldWithEmptyInput() {
        Test.startTest();
        List<List<Id>> result = OpportunityStageNameUpdate.updateField(new List<List<Id>>());
        Test.stopTest();

        // Verify that the method returns the same empty input
        System.assertEquals(true, result.isEmpty(), 'The method should return an empty list for empty input');
    }
}