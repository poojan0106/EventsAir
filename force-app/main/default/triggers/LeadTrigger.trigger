/************************************************************************************************************
* @description : Trigger for Lead object
* @author      : Salesfix Dev - JL
* @date        : 12/12/2018
*************************************************************************************************************/
trigger LeadTrigger on Lead (after update) {
    if(trigger.isAfter){
        if(trigger.isUpdate){
            LeadTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        }
    }
}