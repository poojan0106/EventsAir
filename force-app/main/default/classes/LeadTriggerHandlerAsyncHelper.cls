public class LeadTriggerHandlerAsyncHelper {
    
    @future
    public static void updateIndustryAndSegmentAsync(Map<Id, Id> mapLeadIdToAccountId) {
        if (mapLeadIdToAccountId == null || mapLeadIdToAccountId.isEmpty()) return;
        
        // --- Update Industries ---
        List<Relevant_Industry__c> relevantIndustriesToUpdate = [
            SELECT Id, Lead__c, Account__c, Industry_Option__c
            FROM Relevant_Industry__c
            WHERE Lead__c IN :mapLeadIdToAccountId.keySet()
        ];
        
        for (Relevant_Industry__c industry : relevantIndustriesToUpdate) {
            industry.Account__c = mapLeadIdToAccountId.get(industry.Lead__c);
        }
        if (!relevantIndustriesToUpdate.isEmpty()) {
            update relevantIndustriesToUpdate;
        }
        
        // --- Update Segments ---
        List<Relevant_Segment__c> relevantSegmentsToUpdate = [
            SELECT Id, Lead__c, Account__c, Segment_Option__c
            FROM Relevant_Segment__c
            WHERE Lead__c IN :mapLeadIdToAccountId.keySet()
        ];
        
        for (Relevant_Segment__c segment : relevantSegmentsToUpdate) {
            segment.Account__c = mapLeadIdToAccountId.get(segment.Lead__c);
        }
        if (!relevantSegmentsToUpdate.isEmpty()) {
            update relevantSegmentsToUpdate;
        }
    }
}