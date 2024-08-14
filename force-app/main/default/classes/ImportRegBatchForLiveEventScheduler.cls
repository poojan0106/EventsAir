public class ImportRegBatchForLiveEventScheduler implements schedulable{
    
    public void execute(SchedulableContext sc) {
        
        ImportRegistartionBatchForLiveEvent newBatch = new ImportRegistartionBatchForLiveEvent();
        Database.executeBatch(newBatch, 500);
    }

}