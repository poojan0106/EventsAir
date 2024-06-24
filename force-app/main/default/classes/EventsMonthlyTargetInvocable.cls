public class EventsMonthlyTargetInvocable {
    @InvocableMethod(label='Logic for saving Event Monthly Targets' description='Saves Event Monthly Target' category='Events')
    public static void saveEventMonthlyTarget(List<Id> eventIds) {
        if(!eventIds.isEmpty()){
            Map<Event__c, Date> openDateByEventId = new Map<Event__c, Date>();
            for(Event__c ev : [Select Id, Open_Date__c From Event__c Where Id IN :eventIds]){
                openDateByEventId.put(ev, ev.Open_Date__c.Date());
            }
            
            List<Event_Monthly_Targets__c> saveEventMonthlyTarget = new List<Event_Monthly_Targets__c>();
            if(!openDateByEventId.keySet().isEmpty()){
                for(Event__c ev : openDateByEventId.keySet()){
                    Date todayDate = Date.today().toStartOfMonth();
                    Date openDate = openDateByEventId.get(ev).toStartOfMonth();
                    Integer dateDiff = todayDate.monthsBetween(openDate);
                    for(Integer i=0; i <= dateDiff; i++){
                        Integer monthInt = todayDate.month();
                        Integer yearInt = todayDate.year();
                        Integer day = todayDate.day();
                        DateTime dateTimeInstance = DateTime.newInstance(yearInt, monthInt, day);
                        
                        Event_Monthly_Targets__c eventMonthlyTargets = new Event_Monthly_Targets__c();
                        eventMonthlyTargets.Month__c = dateTimeInstance.format('MMMM');
                        eventMonthlyTargets.Year__c = yearInt.toString();
                        eventMonthlyTargets.Events__c = ev.Id;
                        saveEventMonthlyTarget.add(eventMonthlyTargets);
                        todayDate = todayDate.addMonths(1);
                    }
                }
                
                try {
                    insert saveEventMonthlyTarget;
                } catch(DmlException e) {
                    System.debug('Error: ' + e.getMessage());
                }
            }
        }
        
    }
}