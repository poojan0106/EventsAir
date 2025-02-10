global class BatchOpportunityRebook implements Database.Batchable<sObject>, Database.Stateful {
    private Set<Id> opportunityIds;
    private Boolean hasErrors = false; // Flag to track errors
    private String errorMessage = ''; // Stores the first error message

    public BatchOpportunityRebook(Set<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
    }

    // Query Opportunities in batches of 50
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Rebooked__c FROM Opportunity WHERE Id IN :opportunityIds
        ]);
    }

    // Process 50 records per batch
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        try {
            for (Opportunity opp : scope) {
                opp.Rebooked__c = true;
            }
            update scope;
        } catch (Exception ex) {
            hasErrors = true;
            if (String.isEmpty(errorMessage)) {
                errorMessage = ex.getMessage(); // Store the first error message
            }
            System.debug('Batch execution error: ' + ex.getMessage());
        }
    }

    // Send an email notification if there were errors
    global void finish(Database.BatchableContext BC) {
        if (hasErrors) {
            sendErrorEmail();
        }
        System.debug('Batch Process Completed');
    }

    // Method to send an error email with the error message
    private void sendErrorEmail() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {'developer@j4rvis.com'});
        mail.setSubject('Batch Opportunity Rebook - Error Notification');
        
        String body = 'An error occurred while updating Opportunities in the batch process. \n\n' +
                      'Error Message: ' + errorMessage + '\n\n' +
                      'Please check the logs for more details.';
        
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}