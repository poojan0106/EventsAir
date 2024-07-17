public class OpportunityStageNameUpdate {
    @InvocableMethod(label='Update Opportunity StageName' description='Update StageName for Yesterdays Event Cool Off')
    public static List<List<Id>> updateField(List<List<Id>> recordIdCollections) {
        if (recordIdCollections == null || recordIdCollections.isEmpty()) {
            System.debug('recordIdCollections is null or empty.');
            return recordIdCollections;
        }

        Boolean hasRecords = false;
        for (List<Id> recordIds : recordIdCollections) {
            if (recordIds != null && !recordIds.isEmpty()) {
                hasRecords = true;
                break;
            } 
        }

        if (!hasRecords) {
            System.debug('All provided record ID lists are empty.');
            return recordIdCollections;
        }

        OpportunityStageNameUpdateBatch batch = new OpportunityStageNameUpdateBatch(recordIdCollections);
        Database.executeBatch(batch, 10);

        return recordIdCollections;
    }
}