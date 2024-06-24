public class ImportRegistrationForAllEventsController {
    
    
     public ImportRegistrationForAllEventsController(ApexPages.StandardController controller) {
       executeQueueable(); 
     }
    
    public void executeQueueable(){
    
    ImportRegistartionFromEventsAirQueueable job = new ImportRegistartionFromEventsAirQueueable();
    System.enqueueJob(job);
        
    }
    
}