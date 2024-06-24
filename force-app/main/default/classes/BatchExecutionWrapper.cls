// Define a wrapper class to execute the batch class
public class BatchExecutionWrapper implements Schedulable {
    private String eventId;
    
    public BatchExecutionWrapper(String eventId) {
        this.eventId = eventId;
    }
    
    // Implement the execute method defined in the Schedulable interface
    public void execute(SchedulableContext context) {
        // Call the batch class here with the specific event ID
        Database.executeBatch(new ImportRegistartionBatchForLiveEvent(eventId), 100);
    }
}