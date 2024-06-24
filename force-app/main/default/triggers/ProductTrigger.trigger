/************************************************************************************************************
* @description : trigger for Product2 object
* @author      : Salesfix Dev - JL
* @date        : 12/21/2018
*************************************************************************************************************/
trigger ProductTrigger on Product2 (after update) {
    if(trigger.isAfter){
        if(trigger.isUpdate){
            ProductTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        }
    }
}