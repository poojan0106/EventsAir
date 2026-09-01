/**
 * LogoMigrationBatchLauncher
 *
 * Invocable Apex wrapper that accepts a list of Forms__c record IDs
 * and kicks off LogoMigrationBatch for those specific records.
 *
 * Called from a Screen Flow via an Action element.
 */
public class LogoMigrationBatchLauncher {

    public class FlowInput {
        @InvocableVariable(label='Form Record IDs' description='List of Forms__c record IDs to migrate' required=true)
        public List<Id> formIds;
    }

    @InvocableMethod(label='Launch Logo Migration Batch' description='Kicks off LogoMigrationBatch for the supplied Forms__c record IDs')
    public static void launch(List<FlowInput> inputs) {
        // Collect all IDs across all input collections (Flow bulk-safe pattern)
        Set<Id> allIds = new Set<Id>();
        for (FlowInput input : inputs) {
            if (input.formIds != null) {
                allIds.addAll(input.formIds);
            }
        }

        if (allIds.isEmpty()) {
            throw new LogoMigrationLaunchException('No Form record IDs were provided to the batch launcher.');
        }

        Database.executeBatch(new LogoMigrationBatch(allIds), 1);
    }

    public class LogoMigrationLaunchException extends Exception {}
}