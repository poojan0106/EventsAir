/************************************************************************************************************
* @description : Trigger handler for ProductTrigger
* @author      : Salesfix Dev - JL
* @date        : 12/21/2018
*************************************************************************************************************/
public class ProductTriggerHandler {

    /************************************************************************************************************
    * @description : after update method
    * @author      : Salesfix Dev - JL
    * @date        : 12/21/2018
    * @param       : newProductList - trigger.new
    * @param       : oldProductMap - trigger.oldMap
    *************************************************************************************************************/
    public static void onAfterUpdate(List<Product2> newProductList, Map<Id, Product2> oldProductMap){
        isChangeNameUpdateOpportunityStandPackage(newProductList, oldProductMap);
    }

    /************************************************************************************************************
    * @description : after update method to check if name ischanged and family is stand package
    * @author      : Salesfix Dev - JL
    * @date        : 12/21/2018
    * @param       : newProductList - trigger.new
    * @param       : oldProductMap - trigger.oldMap
    *************************************************************************************************************/
    public static void isChangeNameUpdateOpportunityStandPackage(List<Product2> newProductList, Map<Id, Product2> oldProductMap){
        Set<Id> productIds = new Set<Id>();
        for(Product2 newProduct2: newProductList){
            if(newProduct2.Family == 'Stand Package' && newProduct2.Name != oldProductMap.get(newProduct2.Id).Name){
                productIds.add(newProduct2.Id);
            }
        }

        if(!productIds.isEmpty()){
            Set<Id> opportunityIdsToRecalculate = queryExistingOpportunityWithProduct(productIds);
            if(!opportunityIdsToRecalculate.isEmpty()){
                recalculateStandPackageListOpportunity(opportunityIdsToRecalculate);
            }
        }
    }

    /************************************************************************************************************
    * @description : method to query existing OLI and return opportunity ids set
    * @author      : Salesfix Dev - JL
    * @date        : 12/21/2018
    * @param       : productIds - set of product ids to process
    *************************************************************************************************************/
    public static Set<Id> queryExistingOpportunityWithProduct(Set<Id> productIds){
        Set<Id> opportunityIdToReturn = new Set<Id>();
        List<OpportunityLineItem> existingOLIs = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE Product2Id IN: productIds];
        if(!existingOLIs.isEmpty()){
            for(OpportunityLineItem existingOLI: existingOLIs){
                opportunityIdToReturn.add(existingOLI.OpportunityId);
            }
        }
        return opportunityIdToReturn;
    }

    /************************************************************************************************************
    * @description : method to query existing OLI and return opportunity ids set
    * @author      : Salesfix Dev - JL
    * @date        : 12/21/2018
    * @param       : opportunityIds - set of opportunity ids set
    *************************************************************************************************************/
    public static void recalculateStandPackageListOpportunity(Set<Id> opportunityIds){
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