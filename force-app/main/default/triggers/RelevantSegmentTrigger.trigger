trigger RelevantSegmentTrigger on Relevant_Segment__c (After insert, After Update) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            RelevantSegmentTriggerHandler.validateAddedPrimarySegmentOnAccount(trigger.new, null);
            RelevantSegmentTriggerHandler.validateAddedPrimarySegmentOnOpportunity(trigger.new, null);
        }else if(trigger.isUpdate){
            RelevantSegmentTriggerHandler.validateAddedPrimarySegmentOnAccount(trigger.new, trigger.oldMap);
            RelevantSegmentTriggerHandler.validateAddedPrimarySegmentOnOpportunity(trigger.new, trigger.oldMap);
        }
    }
}