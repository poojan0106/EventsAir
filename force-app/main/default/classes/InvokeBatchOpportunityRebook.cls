public class InvokeBatchOpportunityRebook {
    @InvocableMethod(label='Bulk Rebook Opportunities' description='Runs a batch to update Rebooked__c field in chunks of 50')
    public static void runBatch(List<List<Id>> opportunityIdLists) {
        if (opportunityIdLists == null || opportunityIdLists.isEmpty()) {
            return;
        }

        // Flatten the list of lists into a single set of IDs
        Set<Id> oppIdsSet = new Set<Id>();
        for (List<Id> idList : opportunityIdLists) {
            if (idList != null) {
                oppIdsSet.addAll(idList);
            }
        }

        if (!oppIdsSet.isEmpty()) {
            Database.executeBatch(new BatchOpportunityRebook(oppIdsSet), 20);
        }
    }
}