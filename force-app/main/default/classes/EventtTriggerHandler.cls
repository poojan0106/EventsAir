public  class EventtTriggerHandler {
    
    public static void afterUpdate(List<Event__c> newEventList, Map<Id, Event__c> oldEventMap){
        // Check if TriggerController__c object and fields are accessible
        if (!Schema.SObjectType.TriggerController__c.isAccessible() && !Schema.SObjectType.TriggerController__c.fields.EventTrigger__c.isAccessible()) {
            return; // Exit if not accessible
        }
        // Get custom setting value
        TriggerController__c customSettings = TriggerController__c.getValues('TriggerSettings');
        if(customSettings!=null && customSettings.EventTrigger__c){
            System.debug('afterUpdate');
            for(Event__c eventRecord:newEventList){
                Event__c oldEvent= oldEventMap.get(eventRecord.Id);
                Boolean detailsSyncedChanged = eventRecord.Details_Synced_with_ExpoCAD__c != oldEvent.Details_Synced_with_ExpoCAD__c;
                Boolean isRequested = eventRecord.Details_Synced_with_ExpoCAD__c == 'Requested';
                if (isRequested && detailsSyncedChanged) {
                    ExpocadIntegrationLogic.pavilionExpocadCallout(eventRecord.Id);
                }
            }
        }
    }

}