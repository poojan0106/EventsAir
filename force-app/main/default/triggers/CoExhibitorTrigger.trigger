/************************************************************************************************
 * @author : SalesFix Dev - JL
 * @date : 2018-02-28
 * @description : Trigger for Co_Exhibitor__c object
 *************************************************************************************************/
trigger CoExhibitorTrigger on Co_Exhibitor__c (after update) {
    if(trigger.isAfter){
        if(trigger.isUpdate){
            CoExhibitorTriggerHandler coExhibitor = new CoExhibitorTriggerHandler();
            coExhibitor.createCoExhibitorOpportunity(trigger.new, trigger.oldMap);
        }
    }
}