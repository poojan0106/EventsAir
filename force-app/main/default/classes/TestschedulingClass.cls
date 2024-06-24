public class TestschedulingClass {
    public  void methodtoCallBatch(){
         Datetime todaytime;
         todaytime = system.now();
        Time currentTime;
        currentTime = todaytime.time(); 
        List<Event__c> LstOfEvents = [SELECT Id,Batch_Execution_Time__c, name FROM Event__c where Close_Date__c > today and EventsAirID__c != null limit 2];
       		Integer numberOfEvents = LstOfEvents.size();
        List<Event__c> LstOfEventstoUpdt = new  List<Event__c>();
        for(Event__c evnt :LstOfEvents){
            Event__c evt = new Event__c();
            evt.id = evnt.Id;
             evt.Batch_Execution_Time__c = currentTime;
             system.debug('sdfg currentTime'+currentTime);
            currentTime = currentTime.addHours(1);
            LstOfEventstoUpdt.add(evt);
        }
        
        if(LstOfEventstoUpdt.size() > 0){
            system.debug('sdfg');
            update LstOfEventstoUpdt;
            
        }
          List<Event__c> LstOfEventsupdated = [SELECT Id,Batch_Execution_Time__c, name FROM Event__c where Id in :LstOfEventstoUpdt];
        system.debug('sdfg'+LstOfEventsupdated);
        for(Event__c evnt :LstOfEventsupdated){
             Datetime todaytime1;
         todaytime1 = system.now();
        Time currentTime1;
        currentTime1 = todaytime1.time(); 
             system.debug('sdfg currentTime1'+currentTime1);
            system.debug('Batch_Execution_Time__c'+evnt.Batch_Execution_Time__c);
            if(evnt.Batch_Execution_Time__c == currentTime1){
                system.debug('sdfg');
                 Database.executeBatch(new ImportRegistartionBatchForLiveEvent(evnt.Id), 100);
            }
        }
    }

}