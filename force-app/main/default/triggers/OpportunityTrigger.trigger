/************************************************************************************************************
* @description  : Opportunity Trigger
* @author       : Salesfix - CI
* @date         : 2018-03-01
*************************************************************************************************************/

trigger OpportunityTrigger on Opportunity (before update, before insert, after update, after insert) {
    if(trigger.isBefore){
        if(trigger.isUpdate){
            OpportunityTriggerHandler oppHandler = new OpportunityTriggerHandler();
            oppHandler.doBeforeUpdate(trigger.new, trigger.newMap, trigger.oldMap);
        }
    }
    if(trigger.isAfter){
        if(trigger.isUpdate){
            OpportunityTriggerHandler oppHandler = new OpportunityTriggerHandler();
            oppHandler.doAfterUpdate(trigger.new, trigger.newMap, trigger.oldMap);
        }
        if(trigger.isInsert){
            OpportunityTriggerHandler oppHandler = new OpportunityTriggerHandler();
            oppHandler.doAfterInsert(trigger.new);
        }
    }
}