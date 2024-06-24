global class ExpocadSessionTokenScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.debug('Start Refreshing...');
        ExpocadSessionTokenGenerator.refreshSessionToken();
    }
    
}