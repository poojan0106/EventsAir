public class EventFormFileUpload {

    public static void handleAfterInsert(List<ContentDocumentLink> listOfFiles){
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : listOfFiles) {
            docIds.add(cdl.ContentDocumentId);
        }
        if (docIds.isEmpty()) {
            return;
        }
        List<ContentDocumentLink> listOfCDL = [SELECT Id, LinkedEntityId, ContentDocumentId
                                               FROM ContentDocumentLink
                                               WHERE ContentDocumentId IN :docIds];
        Map<String, String> mapOfContentFile=new Map<String, String>();
        if(listOfCDL.size()>0){

        }
    }
}