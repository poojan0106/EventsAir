/************************************************************************************************************
* @description  : Stand Trigger
* @author       : Salesfix - CI
* @date         : 2018-04-18
* @changes      : 2018-08-24 - CI - Parent pavillion area rollup
*************************************************************************************************************/
trigger StandTrigger on Stand__c (after insert, after update, after delete) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            StandTriggerHandler standHandler = new StandTriggerHandler();
            standHandler.doAfterInsert(trigger.new);
        }

        if(trigger.isUpdate){
            StandTriggerHandler standHandler = new StandTriggerHandler();
            standHandler.doAfterUpdate(trigger.new,trigger.newMap, trigger.oldMap);
        }

        if(trigger.isDelete){
            StandTriggerHandler standHandler = new StandTriggerHandler();
            standHandler.doAfterDelete(trigger.old);
        }
    }
}