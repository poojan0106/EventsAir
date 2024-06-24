public class ImportRegistartionFromEventsAirQueueable implements Queueable {
    
    public void execute(QueueableContext context) {
        
        // Query for Event records where Flag equals false
        List<Event__c> eventsToProcess = [SELECT Id, EventsAirID__c, Is_Ready_To_Proceed__c FROM Event__c 
                                          WHERE Is_Ready_To_Proceed__c = true AND EventsAirID__c != null AND Close_Date__c >= TODAY  LIMIT 1];
        
        System.debug('@@@@ eventsToProcess = '+eventsToProcess);
        if(!eventsToProcess.isEmpty()) {            
            Database.executeBatch(new ImportRegistartionForAllEventsBatch(eventsToProcess[0].EventsAirID__c, eventsToProcess[0].Id), 1000);
            eventsToProcess[0].Is_Ready_To_Proceed__c = false;
            update eventsToProcess;            
        }
        else{            
            System.debug('!@@@ All Synced..');
            List<Event__c> lstevnt = [SELECT Id, Is_Ready_To_Proceed__c FROM Event__c 
                                      WHERE Is_Ready_To_Proceed__c = false  AND EventsAirID__c != null AND Close_Date__c >= TODAY];
            System.debug('@@@@ lstevnt = '+lstevnt);
            List<Event__c> lstupdateEvent = new List<Event__c>();
            
            for(Event__c objEvent: lstevnt) {
                objEvent.Is_Ready_To_Proceed__c = true;
                lstupdateEvent.add(objEvent);
            }
            
            System.debug('@@ lstupdateEvent = '+lstupdateEvent);
            if(!lstupdateEvent.isEmpty()) {
                update lstupdateEvent;
            }
        }
       
    }
}