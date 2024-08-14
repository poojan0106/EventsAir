global class ImportRegSeprateSecAndInteBatchScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Your batch job logic goes here
        Database.executeBatch(new ImportRegSeprateSecAndInteBatch());
    }
}