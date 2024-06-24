/************************************************************************************************************
* @description  : Handler for the Pavilion Trigger
* @author       : Salesfix - CI
* @date         : 2018-09-21
*************************************************************************************************************/
public class PavilionTriggerHandler{
    public void doAfterUpdate(List<Pavilion__c> newPavilions, Map<Id, Pavilion__c> newPavilionsMap, Map<Id, Pavilion__c> oldPavilionsMap){
        updateOppLineItems(newPavilions, newPavilionsMap, oldPavilionsMap);
    }
    
    /***************************************************************************************************************
    * @description  :
    * @author       :
    * @date         :
    ****************************************************************************************************************/
    public void updateOppLineItems(List<Pavilion__c> newPavilions, Map<Id, Pavilion__c> newPavilionsMap, Map<Id, Pavilion__c> oldPavilionsMap){
        Set<Id> validPavilionIds =  getValidPavilions(newPavilions, newPavilionsMap, oldPavilionsMap);
        if(!validPavilionIds.isEmpty()){
            List<OpportunityLineItem> oppLineItemsList = getOpportunityLineItems(validPavilionIds);
            if(!oppLineItemsList.isEmpty()){
                List<OpportunityLineItem> updateLineItems = collectToUpdateLineItems(oppLineItemsList);
                if(!updateLineItems.isEmpty()) {
                    update updateLineItems;
                }
            }
        }
    }
    
    /***************************************************************************************************************
    * @description  :
    * @author       :
    * @date         :
    ****************************************************************************************************************/
    public Set<Id> getValidPavilions(List<Pavilion__c> newPavilions, Map<Id, Pavilion__c> newPavilionsMap, Map<Id, Pavilion__c> oldPavilionsMap) {
        Set<Id> validPavilions = new Set<Id>();
        for (Pavilion__c pav : newPavilions) {
            if(newPavilionsMap.get(pav.Id).Area__c != oldPavilionsMap.get(pav.Id).Area__c){
                validPavilions.add(pav.Id);
            }
        }
        return validPavilions;
    }
    
    /***************************************************************************************************************
    * @description  :
    * @author       :
    * @date         :
    ****************************************************************************************************************/
    public List<OpportunityLineItem> getOpportunityLineItems(Set<Id> pavs){
        List<OpportunityLineItem> oppLineItemsList = [SELECT Id, Quantity, UnitPrice, ListPrice, Product2Id, Product2.QuantityUnitOfMeasure, Opportunity.Stand__c,
                                                        Opportunity.Stand__r.Area__c, Opportunity.Stand__r.Open_Corners__c, Opportunity.Pavilion__c, Opportunity.Pavilion__r.Area__c
                                                        FROM OpportunityLineItem
                                                        WHERE Opportunity.Pavilion__c IN: pavs
                                                        AND Opportunity.isClosed != TRUE
                                                        AND Opportunity.StageName !=: Label.Opportunity_Stage_Pending_Change];

        System.debug('@@@ oppLineItemsList: ' + oppLineItemsList);
        return oppLineItemsList;
    }
    
    /***************************************************************************************************************
    * @description  :
    * @author       :
    * @date         :
    ****************************************************************************************************************/
    public List<OpportunityLineItem> collectToUpdateLineItems(List<OpportunityLineItem> oppLineItems){
        System.debug('@@@oppLineItems' + oppLineItems);
        List<OpportunityLineItem> updateLineItemsList = new List<OpportunityLineItem>();
        for(OpportunityLineItem oppItem : oppLineItems){
            OpportunityLineItem lineItems = new OpportunityLineItem();
            if(oppItem.Product2.QuantityUnitOfMeasure == Label.Uom_Sqm) {
                if (oppItem.Quantity != oppItem.Opportunity.Pavilion__r.Area__c) {
                    lineItems.Quantity = oppItem.Opportunity.Pavilion__r.Area__c;
                    lineItems.UnitPrice = oppItem.ListPrice;
                    lineItems.Id = oppItem.Id;
                    updateLineItemsList.add(lineItems);
                    System.debug('@@@updateLineItems' + updateLineItemsList);
                }
            }
        }
        return updateLineItemsList;
    }
}