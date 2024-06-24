/************************************************************************************************
 * @description : Handler class for trigger Co_Exhibitor__c
 * @author      : SalesFix Dev - JL
 * @date        : 2018-03-02
 * History      : 24/08/2018 - Change the field that is being populated when the
 *                             Co-Exhibitor record is created
 *                   Original: newOpportunity.Event__c = coExhibitor.Opportunity__r.Event__c;
 *                             newOpportunity.Stand__c = coExhibitor.Opportunity__r.Stand__c;
 *                   Changes: 8/24/2018
 *                             newOpportunity.Event__c = coExhibitor.Event__c;
 *                             newOpportunity.Stand__c = coExhibitor.Stand__c;
 *************************************************************************************************/
public class CoExhibitorTriggerHandler {

    /**************************************************************************************************
    * @description : method to process data and insert new Opportunity and OpportunityLineItem
    * @author      : SalesFix Dev - JL
    * @date        : 2018-03-02
    * @param       : newCoExhibitorList - trigger.new data
    * @param       : oldCoExhibitorsMap - trigger.oldMap
    ***************************************************************************************************/
    public void createCoExhibitorOpportunity(List<Co_Exhibitor__c> newCoExhibitorList, Map<Id, Co_Exhibitor__c> oldCoExhibitorsMap){
        Set<Id> coExhibitorIds = new Set<Id>();
        for(Co_Exhibitor__c newCoExhibitor: newCoExhibitorList){
            if(newCoExhibitor.Opportunity_Created__c != oldCoExhibitorsMap.get(newCoExhibitor.Id).Opportunity_Created__c && newCoExhibitor.Opportunity_Created__c){
                 coExhibitorIds.add(newCoExhibitor.Id);
            }
        }
        if(!coExhibitorIds.isEmpty()){
            List<Opportunity> opportunityToInsert = new List<Opportunity>();
            Set<Id> priceBookIds = new Set<Id>();
            for(Co_Exhibitor__c coExhibitorToProcess: [SELECT Id, Exhibiting_As__c, Opportunity__c, Opportunity__r.AccountId, Opportunity__r.Account.Name, Opportunity__r.Event__r.Name, Opportunity__r.Stand__r.Name, Opportunity__r.OwnerId,
                                                              Account__c, Account__r.Name, Opportunity__r.Event__c, Opportunity__r.Stand__c, Opportunity__r.StageName, Opportunity__r.CloseDate, Opportunity__r.Event__r.Price_Book__c,
                                                              Opportunity__r.Cooling_Off_Period_Active__c, Opportunity__r.Pavilion__c, Opportunity__r.Pavilion__r.Name, Opportunity__r.Trading_As__c,
                                                              Event__c, Stand__c, Event__r.Price_Book__c, Event__r.Name, Stand__r.Name FROM Co_Exhibitor__c WHERE Id IN: coExhibitorIds]){
                Opportunity newOpportunity = populateDataToOpportunity(coExhibitorToProcess);
                opportunityToInsert.add(newOpportunity);
                priceBookIds.add(coExhibitorToProcess.Event__r.Price_Book__c);
            }
            if(!opportunityToInsert.isEmpty()){
                try{
                    insert opportunityToInsert;
                    List<OpportunityLineItem> opportunityLineItemDML = new List<OpportunityLineItem>();
                    Map<Id, PricebookEntry> mapPriceBookIdToEntry = queryPriceBookEntries(priceBookIds);
                    for(Opportunity opportunityCreated: opportunityToInsert){
                        if(opportunityCreated.Pricebook2Id != null){
                            if(mapPriceBookIdToEntry.get(opportunityCreated.Pricebook2Id) != null){
                                OpportunityLineItem lineItemToCreate = populateDataToOpportunityLineItem(opportunityCreated, mapPriceBookIdToEntry);
                                opportunityLineItemDML.add(lineItemToCreate);
                            }
                        }
                    }

                    if(!opportunityLineItemDML.isEmpty()){
                        insert opportunityLineItemDML;
                    }
                }
                catch(Exception e){
                    sendEmailError(e.getMessage());
                }
            }
        }
    }

    /**************************************************************************************************
    * @description : method to send email when there is unexpected error
    * @author      : SalesFix Dev - JL
    * @date        : 2018-03-02
    * @param       : errorMessage - error message from try catch
    ***************************************************************************************************/
    public void sendEmailError(String errorMessage){
        List<String> emailAddressToSend = new List<String>();
        Email_Error__c emailError = Email_Error__c.getOrgDefaults();
        if(emailError.Email_Address__c != null){
            emailAddressToSend.add(emailError.Email_Address__c);
        }
        if(!emailAddressToSend.isEmpty()){
            String currentClassName = String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject(currentClassName + ' Error on Insert');
            email.setToAddresses(emailAddressToSend );
            email.setPlainTextBody(currentClassName + ' failed to execute: ' + errorMessage);
            Messaging.sendEmail(new Messaging.Email[] { email });
        }
    }
    /**************************************************************************************************
    * @description : method to assign Data to Opportunity object.
    * @author      : SalesFix Dev - JL
    * @date        : 2018-03-02
    * @param       : coExhibitor - Co_Exhibitor__c record to be assigned to Opportunity
    * @return      : newOpportunity - opportunity to be created.
    * -------------------------------------------------------------------------------------------------
    * @History     : Original: newOpportunity.Event__c = coExhibitor.Opportunity__r.Event__c;
    *                          newOpportunity.Stand__c = coExhibitor.Opportunity__r.Stand__c;
    *                Changes: 8/24/2018
    *                          newOpportunity.Event__c = coExhibitor.Event__c;
    *                          newOpportunity.Stand__c = coExhibitor.Stand__c;
    ***************************************************************************************************/
    public Opportunity populateDataToOpportunity(Co_Exhibitor__c coExhibitor){
        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = combineName(coExhibitor);
        newOpportunity.OwnerId = coExhibitor.Opportunity__r.OwnerId;
        newOpportunity.AccountId = coExhibitor.Account__c;
        newOpportunity.Event__c = coExhibitor.Event__c;
        newOpportunity.Stand__c = coExhibitor.Stand__c;
        //newOpportunity.Pavilion__c = coExhibitor.Opportunity__r.Pavilion__c;
        newOpportunity.StageName = coExhibitor.Opportunity__r.StageName;
        newOpportunity.CloseDate = coExhibitor.Opportunity__r.CloseDate;
        newOpportunity.StageName = Label.Opportunity_Stage_Negotiation;
        newOpportunity.NextStep = Label.Co_ExhibitorOpp_NextStep;
        newOpportunity.Description = Label.Co_ExhibitorOpp_Description;
        newOpportunity.Cooling_Off_Period_Active__c = coExhibitor.Opportunity__r.Cooling_Off_Period_Active__c;
        newOpportunity.Co_Exhibitor_Opportunity__c = coExhibitor.Opportunity__c;
        newOpportunity.Pricebook2Id = coExhibitor.Event__r.Price_Book__c;
        newOpportunity.Coex_Opportunity__c = coExhibitor.Id;
        newOpportunity.Trading_As__c = coExhibitor.Exhibiting_As__c;
        return newOpportunity;
    }

    /****************************************************************************************************
    * @description : method to build the Opportunity Name
    * @author      : SalesFix Dev - JL
    * @date        : 2018-03-02
    * @param       : coExhibitor - Co_Exhibitor__c to build the Opportuntiy Name
    * @return      : finalName - The created name
    *****************************************************************************************************/
    public String combineName(Co_Exhibitor__c coExhibitor){
        String accountName = (coExhibitor.Account__c != null) ? coExhibitor.Account__r.Name : '';
        String eventName = (coExhibitor.Event__c != null) ? coExhibitor.Event__r.Name : '';
        String standName = (coExhibitor.Stand__c != null) ? coExhibitor.Stand__r.Name : '';
        String pavillionName = (coExhibitor.Opportunity__r.Pavilion__c != null) ? coExhibitor.Opportunity__r.Pavilion__r.Name : '';
        String finalName = 'COEX - ' + accountName;
        finalName = (eventName != '') ? finalName + ' - ' + eventName : finalName;
        finalName = (standName != '') ? finalName + ' - ' + standName : finalName;
        finalName = (pavillionName != '') ? finalName + ' - ' + pavillionName : finalName;
        return finalName;
    }

    /**************************************************************************************************
    * @description : method to assign Data to OpporutnityLineItem object
    * @author      : SalesFix Dev - JL
    * @date        : 2018-03-02
    * @param       : opportunityToProcess - recently created Opportunity
    * @param       : mapPriceBookIdToEntry - map of PricebookEntry
    * @return      : lineItemToCreate - OpportunityLIneItem to be created
    ***************************************************************************************************/
    public OpportunityLineItem populateDataToOpportunityLineItem(Opportunity opportunityToProcess, Map<Id, PricebookEntry> mapPriceBookIdToEntry){
        OpportunityLineItem lineItemToCreate = new OpportunityLineItem();
        lineItemToCreate.OpportunityId = opportunityToProcess.Id;
        lineItemToCreate.Quantity = 1;
        lineItemToCreate.Unitprice = mapPriceBookIdToEntry.get(opportunityToProcess.Pricebook2Id).UnitPrice;
        lineItemToCreate.Pricebookentryid = mapPriceBookIdToEntry.get(opportunityToProcess.Pricebook2Id).Id;
        return lineItemToCreate;
    }

    /**************************************************************************************************
    * @description : method to query existing PriceBookEntry records and assign to Map
    * @author      : SalesFix Dev - JL
    * @date        : 2018-03-02
    * @param       : priceBookIds - Set of PriceBook Ids
    * @return      : mapPriceBookIdToEntry - map of PriceBookEntry
    ***************************************************************************************************/
    public Map<Id, PricebookEntry> queryPriceBookEntries(Set<Id> priceBookIds){
        Map<Id, PricebookEntry> mapPriceBookIdToEntry = new Map<Id, PricebookEntry>();
        for(PricebookEntry entry: [SELECT Id, UnitPrice, Product2Id, Product2.Name, Pricebook2Id FROM PricebookEntry WHERE Product2.Name =: Label.Product2_PLI AND Pricebook2Id IN: priceBookIds]){
            mapPriceBookIdToEntry.put(entry.Pricebook2Id, entry);
        }
        return mapPriceBookIdToEntry;
    }
}