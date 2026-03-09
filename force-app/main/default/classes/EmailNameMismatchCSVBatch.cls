public class EmailNameMismatchCSVBatch
    implements Database.Batchable<AggregateResult> {

    private String objectName;
    private String fileTitle;

    public EmailNameMismatchCSVBatch(String objectName, String fileTitle) {
        this.objectName = objectName;
        this.fileTitle  = fileTitle;
    }

    // ================= START =================
    public Iterable<AggregateResult> start(Database.BatchableContext bc) {

        String soql =
            'SELECT Email,' +
            ' COUNT(Id) totalCnt,' +
            ' COUNT_DISTINCT(FirstName) fnCnt,' +
            ' COUNT_DISTINCT(LastName) lnCnt ' +
            'FROM ' + objectName + ' ' +
            'WHERE Email != null ' +
            'GROUP BY Email ' +
            'HAVING COUNT(Id) > 1 ' +
            'AND (COUNT_DISTINCT(FirstName) > 1 ' +
            'OR COUNT_DISTINCT(LastName) > 1) limit 1';

        // 👇 IMPORTANT FIX
        List<AggregateResult> results =
            (List<AggregateResult>) Database.query(soql);

        return results; // List implements Iterable
    }

    // ================= EXECUTE =================
    public void execute(
        Database.BatchableContext bc,
        List<AggregateResult> scope
    ) {

        if (scope.isEmpty()) return;

        String csv = '';

      

       
    }

    public void finish(Database.BatchableContext bc) {
        // no-op
    }
}