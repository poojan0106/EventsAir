public class RelevantSegmentTriggerHandler {

    public static void validateAddedPrimarySegmentOnAccount(List<Relevant_Segment__c> relevantSegments, Map<Id,Relevant_Segment__c> oldSegmentMap) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> excludedSegmentIds = new Set<Id>();

        for (Relevant_Segment__c primarySegment : relevantSegments) {
            if (primarySegment.Primary_Segment__c && Trigger.isInsert && primarySegment.Account__c != null) {
                accountIds.add(primarySegment.Account__c);
                excludedSegmentIds.add(primarySegment.Id); //CHECK SEGMENTS EXCLUDING ITSELF

            } else if (primarySegment.Primary_Segment__c && Trigger.isUpdate && primarySegment.Account__c != null) {
                accountIds.add(primarySegment.Account__c);
                excludedSegmentIds.add(primarySegment.Id); //CHECK SEGMENTS EXCLUDING ITSELF
            }
        }
        
        if (!accountIds.isEmpty()) {
            Map<Id,List<Relevant_Segment__c>> primarySegmentsByAccountId = new Map<Id,List<Relevant_Segment__c>>();
            for (Relevant_Segment__c relevantPrimarySegment : [
                SELECT Id, 
                       Primary_Segment__c, 
                       Secondary_Segment__c, 
                       Account__c, 
                       Event_Category__c, 
                       Opportunity__c 
                FROM Relevant_Segment__c 
                WHERE Account__c IN :accountIds AND 
                      Primary_Segment__c = true AND 
                      Id NOT IN :excludedSegmentIds
            ]) {
                if (!primarySegmentsByAccountId.containsKey(relevantPrimarySegment.Account__c)) {
                    primarySegmentsByAccountId.put(relevantPrimarySegment.Account__c, new List<Relevant_Segment__c> { relevantPrimarySegment });

                } else {
                    primarySegmentsByAccountId.get(relevantPrimarySegment.Account__c).add(relevantPrimarySegment);
                }
            }
            
            for (Relevant_Segment__c primarySegment : relevantSegments) {
                if (primarySegment.Primary_Segment__c && 
                    ((Trigger.isInsert && primarySegment.Account__c != null) || 
                    (Trigger.isUpdate && primarySegment.Account__c != null))) {

                    if (primarySegmentsByAccountId.containsKey(primarySegment.Account__c)) {
                        for (Relevant_Segment__c existingPrimarySegment : primarySegmentsByAccountId.get(primarySegment.Account__c)) {
                            System.debug('Trggered primary segment (filtered) : ' + primarySegment.Event_Category__c);
                            System.debug('Trggered primary segment existing (filtered) : ' + existingPrimarySegment.Event_Category__c);

                            if (existingPrimarySegment.Event_Category__c == primarySegment.Event_Category__c) {
                                primarySegment.addError('An account can not have more than one primary segment added per event per account');

                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    public static void validateAddedPrimarySegmentOnOpportunity(List<Relevant_Segment__c> relevantSegments, Map<Id,Relevant_Segment__c> oldSegmentMap) {
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> excludedSegmentIds = new Set<Id>();

        for (Relevant_Segment__c primarySegment : relevantSegments) {
            if (primarySegment.Primary_Segment__c && Trigger.isInsert && primarySegment.Opportunity__c != null) {
                opportunityIds.add(primarySegment.Opportunity__c);
                excludedSegmentIds.add(primarySegment.Id);

            } else if (Trigger.isUpdate && primarySegment.Opportunity__c != null) {
                opportunityIds.add(primarySegment.Opportunity__c);
                excludedSegmentIds.add(primarySegment.Id);
            }
        }
        
        if (!opportunityIds.isEmpty()) {
            Map<Id,List<Relevant_Segment__c>> primarySegmentsByOppId = new Map<Id,List<Relevant_Segment__c>>();
            for (Relevant_Segment__c relevantPrimarySegment : [
                SELECT Id, 
                       Primary_Segment__c, 
                       Secondary_Segment__c, 
                       Account__c, 
                       Event_Category__c, 
                       Opportunity__c 
                FROM Relevant_Segment__c 
                WHERE Opportunity__c IN :opportunityIds AND 
                      Primary_Segment__c = true AND 
                      Id NOT IN :excludedSegmentIds
            ]) {
                if (!primarySegmentsByOppId.containsKey(relevantPrimarySegment.Opportunity__c)) {
                    primarySegmentsByOppId.put(relevantPrimarySegment.Opportunity__c, new List<Relevant_Segment__c> { relevantPrimarySegment });

                } else {
                    primarySegmentsByOppId.get(relevantPrimarySegment.Opportunity__c).add(relevantPrimarySegment);
                }
            }
            
            for (Relevant_Segment__c primarySegment : relevantSegments) {
                if (primarySegment.Primary_Segment__c && 
                    ((Trigger.isInsert && primarySegment.Opportunity__c != null) || 
                    (Trigger.isUpdate && primarySegment.Opportunity__c != null))) {

                    if (primarySegmentsByOppId.containsKey(primarySegment.Opportunity__c)) {//THERE EXISTS A PRIMARY SEGMENT ATTACHED TO THE OPP
                        primarySegment.addError('An opportunity can not have more than one primary segment');
                    }
                }
            }
        }
    }
}