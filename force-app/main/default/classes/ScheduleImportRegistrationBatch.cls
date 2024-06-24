public class ScheduleImportRegistrationBatch implements Schedulable {
    public void execute(SchedulableContext ctx) {
        // Schedule the batch to run the first time
        String jobId = System.schedule('Batch Job 1', '0 0 * * * ?', new ImportRegistartionBatchForLiveEvent('a0sAD000000T79NYAS'));

        // Schedule the batch to run the second time after one hour
        String jobId2 = System.schedule('Batch Job 2', '0 0 * * * ?', new ImportRegistartionBatchForLiveEvent('a0s6F00000hQUpWQAW'));
    }
}