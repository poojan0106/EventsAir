public class CustomEventController {
    public final Event__c customEvent {get; private set;}

    public CustomEventController(ApexPages.StandardController stdController) {
        this.customEvent = (Event__c)stdController.getRecord();
    }

    public PageReference getEvents() {
        // Query records in smaller batches
        List<Id> lstContact = new List<Id>();
        List<Function__c> lstFunction = [SELECT Id FROM Function__c WHERE Events__c = :customEvent.Id];
        List<Registration__c> lstRegistration = [SELECT Id, Event__c, Contact__c FROM Registration__c WHERE Event__c = :customEvent.Id];
        System.debug(lstRegistration.size());
        List<Opportunity> lstOpp = [SELECT Id, Name FROM Opportunity WHERE Event__c = :customEvent.Id AND RecordType.Name != 'Divcom_Exhibitor'];

        if (!lstRegistration.isEmpty()) {
            for (Registration__c reg : lstRegistration) {
                lstContact.add(reg.Contact__c);
            }
        }
		
        List<Case> contactIdsAssociatedWithCasesToDelete = new List<Case>();
        for (Case c : [SELECT Id,ContactId FROM Case WHERE ContactId IN :lstContact]) {
            contactIdsAssociatedWithCasesToDelete.add(c);
        } 
        if (!contactIdsAssociatedWithCasesToDelete.isEmpty()) {
            delete contactIdsAssociatedWithCasesToDelete;
        }
        List<Contact> lstContactTodelete = new List<Contact>();
        for (Contact con : [SELECT Id FROM Contact WHERE Id IN :lstContact]) {
            lstContactTodelete.add(con);
        } 
        if (!lstContactTodelete.isEmpty()){
            delete lstContactTodelete;
        }
        if (!lstFunction.isEmpty()) {
            delete lstFunction;
        }

        // Enqueue the deletion process in batches
        if (!lstRegistration.isEmpty()) {
            Integer batchSize = 2000;
            Integer numberOfBatches = (lstRegistration.size() + batchSize - 1) / batchSize;
            for (Integer i = 0; i < numberOfBatches; i++) {
                List<Registration__c> batchToDelete = new List<Registration__c>();
                Integer startIdx = i * batchSize;
                Integer endIdx = Math.min((i + 1) * batchSize, lstRegistration.size());
                for (Integer j = startIdx; j < endIdx; j++) {
                    batchToDelete.add(lstRegistration[j]);
                }
                DeleteRegistrationQueueableclass deleteReg = new DeleteRegistrationQueueableclass(batchToDelete);
                System.enqueueJob(deleteReg);
            }
        }

        if (!lstOpp.isEmpty()) {
            delete lstOpp;
        }

        PageReference pageRef = new PageReference('/' + customEvent.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
}