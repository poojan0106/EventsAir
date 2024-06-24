/************************************************************************************************************
* @description : Trigger Handler for LeadTrigger class
* @author      : Salesfix Dev - JL
* @date        : 12/12/2018
*************************************************************************************************************/
public class LeadTriggerHandler {

    /************************************************************************************************************
    * @description : on after update event method
    * @author      : Salesfix Dev - JL
    * @date        : 12/12/2018
    * @param       : newLeadListTriggerNew - trigger.new
    * @param       : oldMapLead - trigger.oldMap
    *************************************************************************************************************/
    public static void onAfterUpdate(List<Lead> newLeadListTriggerNew, Map<Id, Lead> oldMapLead) {
        validationBeforeConvertingLead(newLeadListTriggerNew, oldMapLead);
        onConvertLinkSegmentAndIndustries(newLeadListTriggerNew, oldMapLead);
    }

    /************************************************************************************************************
    * @description : method to validate a lead for primary segment before converting the lead
    * @author      : Salesfix Dev - RH
    * @date        : January 7, 2020
    * @param       : newLeadListTriggerNew - trigger.new
    * @param       : oldMapLead - trigger.oldMap
    *************************************************************************************************************/
    public static void validationBeforeConvertingLead(List<Lead> newLeadList, Map<Id, Lead> oldMapLead) {
        List<Lead> leadsForConversion = new List<Lead>();

        for (Lead newLead: newLeadList) {
            if (newLead.IsConverted != oldMapLead.get(newLead.Id).IsConverted && newLead.IsConverted) {
                leadsForConversion.add(newLead);
            }
        }

        //PROCESS FOR CHECKING IF THERE IS PRIMARY SEGMENT RELATED TO THE EVENT CATEGORY
        if (!leadsForConversion.isEmpty()) {
            //CODE BLOCK TO QUERY ALL RELATED PRIMARY SEGMENTS AND MAP TO THE LEAD
            List<Relevant_Segment__c> primarySegments = new List<Relevant_Segment__c>([
                SELECT Id, 
                       Primary_Segment__c, 
                       Secondary_Segment__c, 
                       Event_Category__c, 
                       Account__c, 
                       Lead__c, 
                       Lead__r.Event_Category__c, 
                       Segment_Option__c, 
                       Opportunity__c 
                FROM Relevant_Segment__c 
                WHERE Lead__c IN :leadsForConversion AND 
                      Primary_Segment__c = true
            ]);

            if (!primarySegments.isEmpty()) {
                Map<Id, Relevant_Segment__c> primarySegmentByLeadId = new Map<Id, Relevant_Segment__c>();
                List<Relevant_Segment__c> primarySegmentsFoCreation = new List<Relevant_Segment__c>();	

                for (Relevant_Segment__c primarySegment : primarySegments) {
                    //FOR MAPPING CODE BLOCK
                    if (primarySegment.Event_Category__c == primarySegment.Lead__r.Event_Category__c) {
                        primarySegmentByLeadId.put(primarySegment.Lead__c, primarySegment);
                    }
                }

                for (Lead newLead : newLeadList) {
                    if (newLead.IsConverted != oldMapLead.get(newLead.Id).IsConverted && newLead.IsConverted) {
                        if (primarySegmentByLeadId.containsKey(newLead.Id)) {
                            Relevant_Segment__c cloneSegment = new Relevant_Segment__c();

                            cloneSegment = primarySegmentByLeadId.get(newLead.Id).clone(false);
                            //Relevant_Segment__c primarySegment = primarySegmentByLeadId.get(newLead.Id);
                            cloneSegment.Account__c = null;
                            cloneSegment.Lead__c = null;
                            cloneSegment.Opportunity__c = newLead.convertedOpportunityId;
                            primarySegmentsFoCreation.add(cloneSegment);

                        } else if(AccountTriggerHandler.hasInsertRun) {  //NO PRIMARY SEGMENT RELATED TO THE LEAD'S EVENT CATEGORY
                            newLead.addError('A Lead must have a primary segment added for the event related to that lead before being able to convert');
                        }
                    }
                }
                
                insert primarySegmentsFoCreation;
                
            } else {
                for (Lead newLead : newLeadList) {
                    if(AccountTriggerHandler.hasInsertRun){
                        newLead.addError('A Lead must have a primary segment added for the event related to that lead before being able to convert');
                    }
                    
                }
            }
        }
    }

    /************************************************************************************************************
    * @description : method to check the lead record if converted then call queryRelatedRecords method to process
    * @author      : Salesfix Dev - JL
    * @date        : 12/12/2018
    * @param       : newLeadListTriggerNew - trigger.new
    * @param       : oldMapLead - trigger.oldMap
    *************************************************************************************************************/
    public static void onConvertLinkSegmentAndIndustries(List<Lead> newLeadList, Map<Id, Lead> oldMapLead) {
        Map<Id, Id> mapLeadIdToAccountId = new Map<Id, Id>();

        for (Lead newLead: newLeadList) {
            if (newLead.IsConverted != oldMapLead.get(newLead.Id).IsConverted && newLead.IsConverted) {
                mapLeadIdToAccountId.put(newLead.Id, newLead.ConvertedAccountId);
            }
        }

        if (!mapLeadIdToAccountId.isEmpty()) {
            queryRelatedRecords(mapLeadIdToAccountId);
        }
    }

    /************************************************************************************************************
    * @description : method to call the methods for querying existing record and update
    * @author      : Salesfix Dev - JL
    * @date        : 12/12/2018
    * @param       : mapLeadIdToAccountId - map for lead id to account id
    *************************************************************************************************************/
    public static void queryRelatedRecords(Map<Id, Id> mapLeadIdToAccountId) {
        Map<Id, Set<Id>> mapAccountIdToIndustryIds = queryExistingIndustry(mapLeadIdToAccountId.values());
        queryIndustryAndUpdate(mapLeadIdToAccountId, mapAccountIdToIndustryIds);

        Map<Id, Set<Id>> mapAccountIdToSegmentIds = queryExistingSegment(mapLeadIdToAccountId.values());
        querySegmentAndUpdate(mapLeadIdToAccountId, mapAccountIdToSegmentIds);
    }

    /************************************************************************************************************
    * @description : method to query existing industry records and return the industry set ids
    * @author      : Salesfix Dev - JL
    * @date        : 12/12/2018
    * @oaram       : accountIds - list of account Ids
    *************************************************************************************************************/
    public static Map<Id, Set<Id>> queryExistingIndustry(List<Id> accountIds) {
        Map<Id, Set<Id>> mapAccountIdToIndustryIds = new Map<Id, Set<Id>>();
        List<Relevant_industry__c> existingIndustries = [
            SELECT Id, 
                   Industry_Option__c, 
                   Account__c 
            FROM Relevant_industry__c 
            WHERE Account__c IN :accountIds
        ];

        if (!existingIndustries.isEmpty()) {
            for (Relevant_industry__c industry: existingIndustries) {
                if (!mapAccountIdToIndustryIds.containsKey(industry.Account__c)) {
                    mapAccountIdToIndustryIds.put(industry.Account__c, new Set<Id> { industry.Industry_Option__c });

                } else {
                    mapAccountIdToIndustryIds.get(industry.Account__c).add(industry.Industry_Option__c);
                }
            }
        }

        return mapAccountIdToIndustryIds;
    }

    /************************************************************************************************************
    * @description : method to query Industry for Lead and Update the Account field
    * @author      : Salesfix Dev - JL
    * @date        : 12/12/2018
    * @param       : mapLeadIdToAccountId - map of lead id to account id
    * @param       : mapAccountIdToIndustryIds - map of account id to set of existing industries
    *************************************************************************************************************/
    public static void queryIndustryAndUpdate(Map<Id, Id> mapLeadIdToAccountId, Map<Id, Set<Id>> mapAccountIdToIndustryIds) {
        List<Relevant_industry__c> relevantIndustriesToUpdate = new List<Relevant_industry__c>();
        List<Relevant_industry__c> relevantIndustries = [
            SELECT Id, 
                   Lead__c, 
                   Industry_Option__c 
            FROM Relevant_industry__c 
            WHERE Lead__c IN :mapLeadIdToAccountId.keySet()
        ];

        if (!relevantIndustries.isEmpty()) {
            for (Relevant_industry__c industry: relevantIndustries) {
                Set<Id> existingIndusryIds = mapAccountIdToIndustryIds.get(mapLeadIdToAccountId.get(industry.Lead__c));

                if (existingIndusryIds == null || !existingIndusryIds.contains(industry.Industry_Option__c)) {
                    industry.Account__c = mapLeadIdToAccountId.get(industry.Lead__c);
                    relevantIndustriesToUpdate.add(industry);
                }
            }
        }

        if (!relevantIndustriesToUpdate.isEmpty()) {
            update relevantIndustriesToUpdate;
        }
    }

    /************************************************************************************************************
    * @description : method to query existing segment and return the segment ids
    * @author      : Salesfix Dev - JL
    * @date        : 12/12/2018
    * @param       : accountIds - List of account ids to query
    *************************************************************************************************************/
    public static Map<Id, Set<Id>> queryExistingSegment(List<Id> accountIds) {
        Map<Id, Set<Id>> mapAccountIdToSegmentIds = new Map<Id, Set<Id>>();
        List<Relevant_Segment__c> existingSegments = [
            SELECT Id, 
                   Segment_Option__c, 
                   Account__c 
            FROM Relevant_Segment__c 
            WHERE Account__c IN :accountIds
        ];

        if (!existingSegments.isEmpty()) {
            for (Relevant_Segment__c segment: existingSegments) {
                if (!mapAccountIdToSegmentIds.containsKey(segment.Account__c)) {
                    mapAccountIdToSegmentIds.put(segment.Account__c, new Set<Id> { segment.Segment_Option__c });

                } else {
                    mapAccountIdToSegmentIds.get(segment.Account__c).add(segment.Segment_Option__c);
                }
            }
        }

        return mapAccountIdToSegmentIds;
    }

    /************************************************************************************************************
    * @description : method to query segment on lead record then update the account field
    * @author      : Salesfix Dev - JL
    * @date        : 12/12/2018
    * @param       : mapLeadIdToAccountId - map lead id to account id
    * @param       : mapAccountIdToSegmentIds - map of account id to set of segment ids
    *************************************************************************************************************/
    public static void querySegmentAndUpdate(Map<Id, Id> mapLeadIdToAccountId, Map<Id, Set<Id>> mapAccountIdToSegmentIds) {
        List<Relevant_Segment__c> relevantSegmentToUpdate = new List<Relevant_Segment__c>();
        List<Relevant_Segment__c> relevantSegments = [
            SELECT Id, 
                   Lead__c, 
                   Segment_Option__c 
            FROM Relevant_Segment__c 
            WHERE Lead__c IN :mapLeadIdToAccountId.keySet()
        ];

        if (!relevantSegments.isEmpty()) {
            for (Relevant_Segment__c segment: relevantSegments) {
                Set<Id> existingSegmentIds = mapAccountIdToSegmentIds.get(mapLeadIdToAccountId.get(segment.Lead__c));

                if (existingSegmentIds == null || !existingSegmentIds.contains(segment.Segment_Option__c)) {
                    segment.Account__c = mapLeadIdToAccountId.get(segment.Lead__c);

                    relevantSegmentToUpdate.add(segment);
                }
            }
        }

        if (!relevantSegmentToUpdate.isEmpty()) {
            update relevantSegmentToUpdate;
        }
    }

}