/************************************************************************************************************
* @description  : User Trigger
* @author       : Salesfix - CI
* @date         : 2018-10-11
*************************************************************************************************************/
trigger UserTrigger on User (before update) {
    UserTriggerHandler userTrgHandler = new UserTriggerHandler();
    if(trigger.isBefore){
        if(trigger.isUpdate){
            userTrgHandler.onBeforeUpdate(trigger.new, trigger.newMap, trigger.oldMap);
        }
    }
}