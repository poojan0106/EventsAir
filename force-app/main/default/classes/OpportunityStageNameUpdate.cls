public class OpportunityStageNameUpdate {
    @InvocableMethod(label='Update Opportunity StageName' description = 'Update StageName for Yesterdays Event Cool Off ')
    public static List<List<Id>> updateField(List<List<Id>> recordIdCollections) {
        OpportunityStageNameUpdateBatch batch = new OpportunityStageNameUpdateBatch(recordIdCollections);
        Database.executeBatch( batch ,50); 
        return recordIdCollections;
	}
}