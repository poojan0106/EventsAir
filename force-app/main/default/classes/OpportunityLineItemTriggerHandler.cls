/************************************************************************************************************
* @description : Handler class for OpportunityLineItem trigger
* @author      : Salesfix Dev - JL
* @date        : 12/20/2018
*************************************************************************************************************/
public class OpportunityLineItemTriggerHandler {
    /************************************************************************************************************
    * @description : after insert method
    * @author      : Salesfix Dev - JL
    * @date        : 12/20/2018
    * @param       : newOpportunityLineItems - trigger.new
    *************************************************************************************************************/
    public static void onAfterInsert(List<OpportunityLineItem> newOpportunityLineItems){
        afterInsertUpdateOpportunity(newOpportunityLineItems);
    }

    /************************************************************************************************************
    * @description : after delete method
    * @author      : Salesfix Dev - JL
    * @date        : 12/20/2018
    * @param       : newOpportunityLineItems - trigger.new
    *************************************************************************************************************/
    public static void onAfterDelete(List<OpportunityLineItem> newOpportunityLineItems){
        System.debug('@@@ onAfterDelete OLI Trigger');
        afterDeleteUpdateOpportunity(newOpportunityLineItems);
    }

    /************************************************************************************************************
    * @description : after insert method to check the OLI criteria and call the method for updating opportunity
    * @author      : Salesfix Dev - JL
    * @date        : 12/20/2018
    * @param       : newOpportunityLineItems - trigger.new
    *************************************************************************************************************/
    public static void afterInsertUpdateOpportunity(List<OpportunityLineItem> newOpportunityLineItems){
        Set<Id> opportunityIds = new Set<Id>();
        for(OpportunityLineItem newLineItem: [SELECT Id, Product2.Family, OpportunityId FROM OpportunityLineItem WHERE Id IN: newOpportunityLineItems]){
            if(newLineItem.Product2.Family == 'Stand Package'){
                opportunityIds.add(newLineItem.OpportunityId);
            }
        }

        if(!opportunityIds.isEmpty()){
            recalculateStandPackageListOpportunity(opportunityIds);
        }
    }

    /************************************************************************************************************
    * @description : after delete method to get deleted OLI and call method to update Opportunity
    * @author      : Salesfix Dev - JL
    * @date        : 12/20/2018
    * @param       : newOpportunityLineItems - trigger.new
    *************************************************************************************************************/
    public static void afterDeleteUpdateOpportunity(List<OpportunityLineItem> newOpportunityLineItems){
        Set<Id> opportunityIds = new Set<Id>();
        for(OpportunityLineItem deletedLineItem: newOpportunityLineItems){
            opportunityIds.add(deletedLineItem.OpportunityId);
        }
        if(!opportunityIds.isEmpty()){
            System.debug('@@@ afterDeleteUpdateOpportunity opportunityIds: ' + opportunityIds);
            recalculateStandPackageListOpportunity(opportunityIds);
        }
    }

    /************************************************************************************************************
    * @description : after delete method to get deleted OLI and call method to update Opportunity
    * @author      : Salesfix Dev - JL
    * @date        : 12/20/2018
    * @param       : opportunityIds - set opportunity ids
    *************************************************************************************************************/
    public static void recalculateStandPackageListOpportunity(Set<Id> opportunityIds){
        System.debug('@@@ recalculateStandPackageListOpportunity');
        Map<Id, List<String>> mapOppIdToProductsName = instantiateMap(opportunityIds);
        for(OpportunityLineItem existingLineItem: [SELECT Id, Product2.Name, OpportunityId FROM OpportunityLineItem
                                                          WHERE OpportunityId IN: opportunityIds AND Product2.Family = 'Stand Package']){
            if(!mapOppIdToProductsName.containsKey(existingLineItem.OpportunityId)){
                mapOppIdToProductsName.put(existingLineItem.OpportunityId, new List<String>{existingLineItem.Product2.Name});
            }
            else{
                mapOppIdToProductsName.get(existingLineItem.OpportunityId).add(existingLineItem.Product2.Name);
            }
        }

        if(!mapOppIdToProductsName.isEmpty()){
            List<Opportunity> opportunityToUpdateList = new List<Opportunity>();
            for(Id opportunityId: mapOppIdToProductsName.keySet()){
                Opportunity opportunityToUpdate = new Opportunity(Id=opportunityId);
                opportunityToUpdate.Stand_Package_Products_List__c = String.join(mapOppIdToProductsName.get(opportunityId), ', ');
                opportunityToUpdateList.add(opportunityToUpdate);
            }

            if(!opportunityToUpdateList.isEmpty()){
                System.debug('@@@ opportunityToUpdateList: ' + opportunityToUpdateList);
                update opportunityToUpdateList;
            }
        }
    }

    /************************************************************************************************************
    * @description : method to instantiate map to add all the oppids  into keyset
    * @author      : Salesfix Dev - JL
    * @date        : 12/20/2018
    * @param       : opportunityIds - set opportunity ids
    *************************************************************************************************************/
    public static Map<Id, List<String>> instantiateMap(Set<Id> opportunityIds){
        Map<Id, List<String>> mapToReturn = new Map<Id, List<String>>();
        for(Id oppId: opportunityIds){
            mapToReturn.put(oppId, new List<String>());
        }
        return mapToReturn;
    }
}