public class ImportFunRegSepSecAndInteBatchscheduler implements schedulable{
    
    public void execute(SchedulableContext sc) {
        
        ImportFunRegSeprateSecAndInteBatch newBatch = new ImportFunRegSeprateSecAndInteBatch();
        Database.executeBatch(newBatch, 500);
    }

}