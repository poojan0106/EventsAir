public class BatchForContactUpdateController {
    
    public final Contact objCon;
    
    public BatchForContactUpdateController(ApexPages.StandardController controller) {
        this.objCon = (Contact)controller.getRecord();
        
        
    }
    
    public PageReference executeBatch() {
        
        List<Contact> lstcon = [Select Id from Contact where Id =: objCon.Id];
        
        System.debug('@@@ lstcon = '+lstcon);
        if(lstcon.size() >0 ) {
            //BatchForContactUpdate batch = new BatchForContactUpdate(lstcon[0].Id);
            //Database.executeBatch(batch, 1); 
        }        
        
        
        PageReference pageRef = new PageReference('/' + objCon.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
}