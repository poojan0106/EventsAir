global class ImportFunRegSeprateSecAndInteLiveSch implements schedulable{
	global void execute(SchedulableContext sc) {
        Database.executeBatch(new ImportFunRegSeprateSecAndInteLiveBatch());
    }
}