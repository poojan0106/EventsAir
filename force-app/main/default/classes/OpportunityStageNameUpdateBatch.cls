public class OpportunityStageNameUpdateBatch implements Database.Batchable<sObject>  {
    public List<List<Id>> recordIdCollections;  
    
    public OpportunityStageNameUpdateBatch(List<List<Id>> recordIdCollections) {
        this.recordIdCollections = recordIdCollections;
    } 
       
    public Database.QueryLocator start(Database.BatchableContext context) {
        Set<Id> allRecordIds = new Set<Id>();
        for (List<Id> recordIds : recordIdCollections) {
            allRecordIds.addAll(recordIds);
        }

        return Database.getQueryLocator([SELECT Id, StageName FROM Opportunity WHERE Id IN :allRecordIds ]);
    }
    public void execute(Database.BatchableContext context, List<sObject> scope) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for (sObject record : scope) {
            Opportunity opp = (Opportunity)record;
            opp.StageName = 'Closed Won';
            opportunitiesToUpdate.add(opp);
        }

        try {
            Database.update(opportunitiesToUpdate, false);
        } catch (Exception e) {
            System.debug('Error occurred while updating opportunities: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    public void finish(Database.BatchableContext context) {
        System.debug('Batch processing finished.');
    }
}