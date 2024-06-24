public class UpdateMarketingBatch implements Database.Batchable<sObject> {
    private String recordId;

    public UpdateMarketingBatch(String recordId) {
        this.recordId = recordId;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id, Marketing_Update__c, Event__c FROM Registration__c WHERE Event__c = :recordId]);
    }

    public void execute(Database.BatchableContext context, List<Registration__c> scope) {
        String currentTimeString = DateTime.now().format('HH:mm:ss');
        
        for (Registration__c registration : scope) {
            registration.Marketing_Update__c = currentTimeString;
        }

        update scope;
    }

    public void finish(Database.BatchableContext context) {
        // Perform any post-processing tasks if needed
    }
}