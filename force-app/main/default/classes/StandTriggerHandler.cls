/************************************************************************************************************
* @description  : Handler for the Stand Trigger
* @author       : Salesfix - CI
* @date         : 2018-04-18
* @changes      : 2018-08-24 - CI - Parent pavillion area rollup
*************************************************************************************************************/
public class StandTriggerHandler{

    /***************************************************************************************************************
    * @description  : Calls the methods for after insert trigger event
    * @author       : SalesFix - CI
    * @date         : 2018-08-24
    ****************************************************************************************************************/
    public void doAfterInsert(List<Stand__c> newStandList){
        updatePavillionFromInsertedDeletedStands(newStandList,false);
    }

    /***************************************************************************************************************
   * @description  : Calls the methods for after delete trigger event
   * @author       : SalesFix - CI
   * @date         : 2018-08-24
   ****************************************************************************************************************/
    public void doAfterDelete(List<Stand__c> oldStandList){
        updatePavillionFromInsertedDeletedStands(oldStandList,true);
    }

    /***************************************************************************************************************
   * @description  : Calls the methods for after update trigger event
   * @author       : SalesFix - CI
   * @date         : 2018-08-24
   ****************************************************************************************************************/
    public void doAfterUpdate(List<Stand__c> newStandList, Map<Id, Stand__c> newStandMap, Map<Id, Stand__c> oldStandMap){
        System.debug('doAfterUpdate');
        updatePavillionFromUpdatedStands(newStandList, newStandMap, oldStandMap);
        updateOppLineItems(newStandList, newStandMap, oldStandMap);
        updateOppLineItemsOpenCornerChanged(newStandList, oldStandMap);
        if(!ExpocadIntegrationLogic.updateFromExpocad){
            standResync(newStandList, oldStandMap);
        }

    }

    /***************************************************************************************************************
    * @description  : Update Pavilions from Updated Stand Record(s)
    * @author       : SalesFix - CI
    * @date         : 2018-08-24
    ****************************************************************************************************************/
    public void updatePavillionFromUpdatedStands(List<Stand__c> newStandList, Map<Id, Stand__c> newStandMap, Map<Id, Stand__c> oldStandMap){
        Set<Id> pavillionsToUpdate =  getPavillionsToUpdate(newStandList, newStandMap, oldStandMap);
        if(!pavillionsToUpdate.isEmpty()){
            Map<Id, Pavilion__c> updatePavillionsMap = updatePavillionsArea(pavillionsToUpdate);
            update updatePavillionsMap.values();
        }
    }

    /***************************************************************************************************************
    * @description  : Update Pavilions from Inserted/Deleted Stand Record(s)
    * @author       : SalesFix - CI
    * @date         : 2018-08-24
    ****************************************************************************************************************/
    public void updatePavillionFromInsertedDeletedStands(List<Stand__c> newStandList, Boolean isDelete){
        Set<Id> validPavillions = new Set<Id>();
        Map<Id,Decimal> areaByPavilionId = new Map<Id,Decimal>();
        
        List<Pavilion__c> pavilionsToUpdateAfterStandDeletion = new List<Pavilion__c>();
        
        for(Stand__c standItem :  newStandList){
            if(standItem.Area__c != null && standItem.Pavilion__c != null && !isDelete) {
                validPavillions.add(standItem.Pavilion__c);
            }
            
            if(isDelete && standItem.Area__c != null && standItem.Pavilion__c != null ){
                
                if(!areaByPavilionId.containsKey(standItem.Pavilion__c)){
                    
                    areaByPavilionId.put(standItem.Pavilion__c,standItem.Area__c);
                                        
                }else if(areaByPavilionId.containsKey(standItem.Pavilion__c)){
                 
                    Decimal areaToUpdate = areaByPavilionId.get(standItem.Pavilion__c) + standItem.Area__c;
                    areaByPavilionId.put(standItem.Pavilion__c,areaToUpdate);
                }
                
                
            }
            
        }
        
        if(!areaByPavilionId.isEmpty()){
            
            for(Pavilion__c pav:[Select Id,area__c from Pavilion__c where Id In:areaByPavilionId.keySet()] ){
                        
            pav.area__c = pav.area__c - areaByPavilionId.get(pav.Id);
            pavilionsToUpdateAfterStandDeletion.add(pav);
            
        }
    }     
        
        If(!isDelete && !validPavillions.isEmpty()){
        Map<Id, Pavilion__c> updatePavillionsMap = updatePavillionsArea(validPavillions);
            
            If(!updatePavillionsMap.isEmpty()){
              update updatePavillionsMap.values();
            }      
        } else if(isDelete && !pavilionsToUpdateAfterStandDeletion.isEmpty()){
            
            update pavilionsToUpdateAfterStandDeletion;
            
        }     
    }

    /***************************************************************************************************************
    * @description  : Collects the pavilion which area will be updated
    * @author       : SalesFix - CI
    * @date         : 2018-08-24
    ****************************************************************************************************************/
    public Map<Id, Pavilion__c> updatePavillionsArea(Set<Id> pavillionsToUpdate){
        Map<Id, Pavilion__c> updatePavillionsMap = new Map<Id, Pavilion__c>();
        List<Pavilion__c> pavillionsUpdateList = [SELECT Id, Area__c, (SELECT Id, Area__c FROM Stands__r) FROM Pavilion__c WHERE Id IN: pavillionsToUpdate];
        if(!pavillionsUpdateList.isEmpty()){
            for(Pavilion__c pavillionItem : pavillionsUpdateList){
                if(pavillionItem.Stands__r.size() > 0){
                    for(Stand__c childStandItem : pavillionItem.Stands__r){
                        if(!updatePavillionsMap.containsKey(pavillionItem.Id)){
                            pavillionItem.Area__c = childStandItem.Area__c;
                            updatePavillionsMap.put(pavillionItem.Id, pavillionItem);
                        }else{
                            pavillionItem.Area__c = updatePavillionsMap.get(pavillionItem.Id).Area__c + childStandItem.Area__c;
                            updatePavillionsMap.put(pavillionItem.Id, pavillionItem);
                        }
                    }    
                }else{
                    pavillionItem.Area__c = null;
                    updatePavillionsMap.put(pavillionItem.Id, pavillionItem);
                }
            }
        }
        System.debug('@@@updatePavillionsMap: ' + updatePavillionsMap);
        return updatePavillionsMap;
    }

    /***************************************************************************************************************
    * @description  : Collect all the valid pavilion records
    * @author       : SalesFix - CI
    * @date         : 2018-08-24
    ****************************************************************************************************************/
    public Set<Id> getPavillionsToUpdate(List<Stand__c> newStandList, Map<Id, Stand__c> newStandMap, Map<Id, Stand__c> oldStandMap) {
        Set<Id> pavillionsToUpdate = new Set<Id>();
        for (Stand__c stand : newStandList) {
            if((newStandMap.get(stand.Id).Area__c != oldStandMap.get(stand.Id).Area__c && stand.Pavilion__c != null) || 
            (stand.Area__c != null && newStandMap.get(stand.Id).Pavilion__c != oldStandMap.get(stand.Id).Pavilion__c)){
                if(stand.Pavilion__c != null){
                    pavillionsToUpdate.add(stand.Pavilion__c);
                    System.debug('@@@new: ' + newStandMap.get(stand.Id).Pavilion__c);
                    System.debug('@@@old: ' + oldStandMap.get(stand.Id).Pavilion__c);
                    if(newStandMap.get(stand.Id).Pavilion__c != oldStandMap.get(stand.Id).Pavilion__c){
                        pavillionsToUpdate.add(oldStandMap.get(stand.Id).Pavilion__c);
                    }
                }else{
                    pavillionsToUpdate.add(oldStandMap.get(stand.Id).Pavilion__c);
                }
            }
        }
        System.debug('@@@pavillionsToUpdate: ' + pavillionsToUpdate);
        return pavillionsToUpdate;
    }

    /***************************************************************************************************************
    * @description  :
    * @author       :
    * @date         :
    ****************************************************************************************************************/
    public void updateOppLineItems(List<Stand__c> newStandList, Map<Id, Stand__c> newStandMap, Map<Id, Stand__c> oldStandMap){
        Set<Id> validStandIds =  getValidStands(newStandList, newStandMap, oldStandMap);
        if(!validStandIds.isEmpty()){
            List<OpportunityLineItem> oppLineItemsList = getOpportunityLineItems(validStandIds);
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
    public Set<Id> getValidStands(List<Stand__c> newStandList, Map<Id, Stand__c> newStandMap, Map<Id, Stand__c> oldStandMap) {
        Set<Id> validStands = new Set<Id>();
        for (Stand__c stand : newStandList) {
            if(newStandMap.get(stand.Id).Area__c != oldStandMap.get(stand.Id).Area__c){
                validStands.add(stand.Id);
            }
        }
        return validStands;
    }

    /***************************************************************************************************************
    * @description  :
    * @author       :
    * @date         :
    ****************************************************************************************************************/
    public List<OpportunityLineItem> getOpportunityLineItems(Set<Id> stands){
        List<OpportunityLineItem> oppLineItemsList = [SELECT Id, Quantity, UnitPrice, ListPrice, Product2Id, Product2.QuantityUnitOfMeasure, Opportunity.Stand__c,
                                                        Opportunity.Stand__r.Area__c, Opportunity.Stand__r.Open_Corners__c
                                                        FROM OpportunityLineItem
                                                        WHERE Opportunity.Stand__c IN: stands
                                                        AND Opportunity.isClosed != TRUE
														AND Opportunity.StageName !=: Label.Opportunity_Stage_Proposal_Sent
                                                        AND Opportunity.StageName !=: Label.Opportunity_Stage_Cooling_Off
                                                        AND Opportunity.StageName !=: Label.Opportunity_Stage_Pending_Change];
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
                if (oppItem.Quantity != oppItem.Opportunity.Stand__r.Area__c) {
                    lineItems.Quantity = oppItem.Opportunity.Stand__r.Area__c;
                    lineItems.UnitPrice = oppItem.ListPrice;
                    lineItems.Id = oppItem.Id;
                    updateLineItemsList.add(lineItems);
                    System.debug('@@@updateLineItems' + updateLineItemsList);
                }
            }
        }
        return updateLineItemsList;
    }

    /***************************************************************************************************************
    * @description  :
    * @author       :
    * @date         :
    ****************************************************************************************************************/
    public void updateOppLineItemsOpenCornerChanged(List<Stand__c> newStandList, Map<Id, Stand__c> oldStandMap){
        Set<Id> standIdToProcess = new Set<Id>();
        Set<Decimal> sideCountToGet = new Set<Decimal>();
        Set<Id> opportunityIdToProcess = new Set<Id>();
        for(Stand__c newStand: newStandList){
            if(newStand.Open_Corners__c != oldStandMap.get(newStand.Id).Open_Corners__c && newStand.Open_Corners__c != null){
                standIdToProcess.add(newStand.Id);
                sideCountToGet.add(getSideCountToBeQuerying(newStand.Open_Corners__c));
            }
        }

        if(!standIdToProcess.isEmpty()){
            List<OpportunityLineItem> lineItemsToRemove = getOpportunityLineItemsToRemove(standIdToProcess, sideCountToGet);
            if(!lineItemsToRemove.isEmpty()){
               delete lineItemsToRemove;
            }
        }
        opportunityIdToProcess = getOpportunityId(standIdToProcess);
        if(!opportunityIdToProcess.isEmpty()){
            OpportunityTriggerHandler.processCornerAndCreateLineItem(opportunityIdToProcess);
        }
    }

    /***************************************************************************************************************
    * @description  : method to get side count
    * @author       : SalesFix Dev - JL
    * @date         :
    ****************************************************************************************************************/
    public Decimal getSideCountToBeQuerying(Decimal openCorner){
        if(openCorner == 0){
            return 1;
        }
        else if(openCorner == 1){
            return 2;
        }
        else if(openCorner == 2){
            return 3;
        }
        else if(openCorner == 3 || openCorner == 4){
            return 4;
        }
        return null;
    }

    /***************************************************************************************************************
    * @description  : method to get opportunity line item
    * @author       : SalesFix Dev - JL
    * @date         :
    ****************************************************************************************************************/
    public List<OpportunityLineItem> getOpportunityLineItemsToRemove(Set<Id> standIds, Set<Decimal> sideCounts){
        List<OpportunityLineItem> oppLineItemsList = [SELECT Id, Quantity, UnitPrice, Product2Id, Product2.QuantityUnitOfMeasure, Opportunity.Stand__c,
                                                             Opportunity.Stand__r.Open_Corners__c, Opportunity.Pricebook2Id, Product2.Side_Count__c, OpportunityId
                                                             FROM OpportunityLineItem
                                                             WHERE Product2.QuantityUnitOfMeasure =: Label.Corner
                                                             AND Opportunity.Stand__c IN: standIds
                                                             /*OR Product2.Side_Count__c IN: sideCounts)*/
                                                             AND Opportunity.isClosed != TRUE
															 AND Opportunity.StageName !=: Label.Opportunity_Stage_Proposal_Sent
                                                        	 AND Opportunity.StageName !=: Label.Opportunity_Stage_Cooling_Off
                                                             AND Opportunity.StageName !=: Label.Opportunity_Stage_Pending_Change
                                                             AND Opportunity.Agreement_Active__c != TRUE];
        return oppLineItemsList;
    }

    /***************************************************************************************************************
    * @description  : method to get opportunity id
    * @author       : SalesFix Dev - JL
    * @date         :
    ****************************************************************************************************************/
    public Set<Id> getOpportunityId(Set<Id> standIds){
        Set<Id> opportunityId = new Set<Id>();
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE Stand__c IN: standIds AND isClosed != TRUE AND StageName !=: Label.Opportunity_Stage_Pending_Change AND Agreement_Active__c != TRUE];
        for(Opportunity opportunity: opportunities){
            opportunityId.add(opportunity.Id);
        }
        return opportunityId;
    }

     /***************************************************************************************************************
    * @description  : 
    * @author       : Sakina
    * @date         :23/11/2023
    ****************************************************************************************************************/
    public static void standResync(List<Stand__c> newStandList, Map<Id, Stand__c> oldStandMap) {
        System.debug('standResync');
         // Check if TriggerController__c object and fields are accessible
        if (!Schema.SObjectType.TriggerController__c.isAccessible() && !Schema.SObjectType.TriggerController__c.fields.StandTrigger__c.isAccessible()) {
            return; // Exit if not accessible
        }

        // Get custom setting value
        TriggerController__c customSettings = TriggerController__c.getValues('TriggerSettings');
        
        List<Id> standIdsToSync = new List<Id>();
        for (Stand__c newStand : newStandList) {
            Stand__c oldStand = oldStandMap.get(newStand.Id);
            if (newStand.Status_Synced_with_ExpoCAD__c != oldStand.Status_Synced_with_ExpoCAD__c && newStand.Status_Synced_with_ExpoCAD__c == 'Requested') {
                System.debug('NEW STAND: ' + newStand.Name);
                standIdsToSync.add(newStand.Id);
            }
        }
        
        // Execute batch if there are stands to sync and custom setting is enabled
        if (!standIdsToSync.isEmpty() && customSettings != null && customSettings.StandTrigger__c) {
            ExpocadBatchClass batch = new ExpocadBatchClass(standIdsToSync);
            Database.executeBatch(batch, 10);        
        }
    }
}