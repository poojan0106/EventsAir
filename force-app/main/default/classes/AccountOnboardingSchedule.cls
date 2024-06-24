public class AccountOnboardingSchedule implements Schedulable {
    public void execute(SchedulableContext ctx) {
        AccountStatusHandler.updateOnboardingStatus();
    }
}