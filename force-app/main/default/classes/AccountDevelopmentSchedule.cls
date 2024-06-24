public class AccountDevelopmentSchedule implements Schedulable {
    public void execute(SchedulableContext ctx) {
        AccountStatusHandler.updateDevelopmentStatus();
    }
}