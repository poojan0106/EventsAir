trigger EventTrigger on Event__c (after update) {
   
    
    //======================= After Update Start ===============================
    if(Trigger.isAfter){
            if(Trigger.isUpdate && !ExpocadIntegrationLogic.updateFromExpocad){
                System.debug('Callout to expocad::');
                EventtTriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
            }
        // ======================After Update End ==================================
    }
    
}