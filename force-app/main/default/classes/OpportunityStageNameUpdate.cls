public class OpportunityStageNameUpdate {
    @InvocableMethod(label='Update Opportunity StageName' description='Update StageName for Yesterdays Event Cool Off')
    public static List<List<Id>> updateField(List<List<Id>> recordIdCollections) {
        if (recordIdCollections == null || recordIdCollections.isEmpty()) {
            System.debug('recordIdCollections is null or empty.');
            return recordIdCollections;
        }

        Boolean hasRecords = false;
        for (List<Id> recordIds : recordIdCollections) {
            if (recordIds != null && !recordIds.isEmpty()) {
                hasRecords = true;
                break;
            } 
        }
        
        if (!hasRecords) {
            System.debug('All provided record ID lists are empty.');
            return recordIdCollections;
        }else{
            Set<Id> allRecordIds = new Set<Id>();
            
            for (List<Id> recordIds : recordIdCollections) {
                allRecordIds.addAll(recordIds);
            }
            
            if(!allRecordIds.isEmpty()){
                List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
                for(Opportunity opp : [SELECT Id, StageName FROM Opportunity WHERE Id IN :allRecordIds]){
                    opp.StageName = 'Closed Won';
                    opportunitiesToUpdate.add(opp);
                }
                try{
                    Database.update(opportunitiesToUpdate, true);
                }catch(Exception e){
                    system.debug(e);
                }
            }
            
        }
        
        return recordIdCollections;
    }
}