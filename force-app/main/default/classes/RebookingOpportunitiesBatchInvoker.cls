public class RebookingOpportunitiesBatchInvoker {

    @InvocableMethod(label='Invoke Rebooking Batch' description='This method invokes the RebookingOpportunitiesBatch with a list of Opportunity IDs')
    public static void executeBatch(List<String> eventId) {
        System.debug('###>>> ' + eventId);
        List<Opportunity> opps = [ SELECT Id, Rebooked__c, StageName
        FROM Opportunity
        WHERE Event__c =:eventId[0] 
        AND Rebooked__c = false
        AND StageName = :Label.Opportunity_Stage_Closed_Won];
        System.debug('opps ' + opps.size());
        // Create and execute the batch job using the provided list of Opportunity IDs.
        RebookingOpportunitiesBatch batch = new RebookingOpportunitiesBatch(eventId[0]);
        
        // Execute the batch with a batch size of 200 (can be adjusted if needed).
        Database.executeBatch(batch, 200);
    }
}