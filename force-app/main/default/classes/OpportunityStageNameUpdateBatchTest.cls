@isTest
public class OpportunityStageNameUpdateBatchTest {
    @isTest
    static void testBatchExecution() {
        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i = 0; i < 100; i++) {
            oppList.add(new Opportunity(Name = 'Test Opportunity ' + i, StageName = 'Prospecting', CloseDate = Date.today()));
        }
        insert oppList;
        
        List<List<Id>> recordIdCollections = new List<List<Id>>();
        List<Id> opportunityIds = new List<Id>();
        for(Opportunity opp : oppList) { 
            opportunityIds.add(opp.Id);
            if(opportunityIds.size() == 20) {
                recordIdCollections.add(new List<Id>(opportunityIds));
                opportunityIds.clear();
            }
        }
        if(!opportunityIds.isEmpty()) {
            recordIdCollections.add(opportunityIds);
        }
        
        Test.startTest();
        OpportunityStageNameUpdateBatch batch = new OpportunityStageNameUpdateBatch(recordIdCollections);
        Database.executeBatch(batch);
        Test.stopTest();
        
        List<Opportunity> updatedOpportunities = [SELECT Id, StageName FROM Opportunity WHERE Id IN :opportunityIds];
        for(Opportunity opp : updatedOpportunities) {
            System.assertEquals('Closed Won', opp.StageName);
        }
    }
}