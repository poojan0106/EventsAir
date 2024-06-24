trigger PavilionTrigger on Pavilion__c (after update) {
    if(trigger.isAfter){
        if(trigger.isUpdate){
            PavilionTriggerHandler pavHandler = new PavilionTriggerHandler();
            pavHandler.doAfterUpdate(trigger.new, trigger.newMap, trigger.oldMap);
        }
    }
}