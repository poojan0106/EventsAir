public class DeleteRegistrationQueueableclass implements Queueable  {
    private List<Registration__c> registrationsToDelete;
    private static final Integer batchSize = 200; 
    private static final Integer maxRetries = 3;
    private Integer retryCount;
    
    public DeleteRegistrationQueueableclass(List<Registration__c> registrationsToDelete) {
        this.registrationsToDelete = registrationsToDelete;
        this.retryCount = 0;
    }
    
    public void execute(QueueableContext context) {
        try {
            Database.delete(registrationsToDelete);
        } catch (Exception e) {
            // Handle the exception and retry the operation
             
                // Handle the error or log it for investigation
                System.debug('Error: ' + e.getMessage());
            
        }
    }
    
}