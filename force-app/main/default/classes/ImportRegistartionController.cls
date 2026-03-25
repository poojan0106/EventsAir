public class ImportRegistartionController {
    
    public final Event__c customEvent;
    
    public ImportRegistartionController(ApexPages.StandardController controller) {
        this.customEvent = (Event__c)controller.getRecord();
        
       
    }
    
    public PageReference executeBatch() {
        
        FeedItem post = new FeedItem();
        post.ParentId = customEvent.Id; //eg. Opportunity id, custom object id..
        post.Body = 'Apex batch Start for fetching EventsAir Data';
        insert post;
        
        // Call the batch class to start the batch process
        //fetch eventsair id
        List<Event__c> lstevent = [Select Id, EventsAirID__c from Event__c where Id =: customEvent.Id];
        
        System.debug('@@@ lstevent = '+lstevent);
        if(lstevent.size() >0 ) {
            Database.executeBatch(new ImportRegistartionFromEventsAirBatch(lstevent[0].EventsAirID__c, lstevent[0].Id), 100);
        }        
        
        
        PageReference pageRef = new PageReference('/' + customEvent.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
}