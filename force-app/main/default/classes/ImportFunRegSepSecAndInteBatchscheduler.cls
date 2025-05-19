public class ImportFunRegSepSecAndInteBatchscheduler implements schedulable{

    public void execute(SchedulableContext sc) {
        
        ImportFunRegSeprateSecAndInteLiveBatch newBatch = new ImportFunRegSeprateSecAndInteLiveBatch();
        Database.executeBatch(newBatch, 500);
    }

}