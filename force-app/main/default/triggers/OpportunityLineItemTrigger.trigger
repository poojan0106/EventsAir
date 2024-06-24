/************************************************************************************************************
* @description : Trigger for OpportunityLineItem object
* @author      : Salesfix Dev - JL
* @date        : 12/20/2018
*************************************************************************************************************/

trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after delete) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            OpportunityLineItemTriggerHandler.onAfterInsert(trigger.new);
        }

        if(trigger.isDelete){
            OpportunityLineItemTriggerHandler.onAfterDelete(trigger.old);
        }
    }
}