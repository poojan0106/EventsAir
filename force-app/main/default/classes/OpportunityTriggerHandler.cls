/************************************************************************************************************
* @description  : Handler for the Opportunity Trigger
* @author       : Salesfix - CI
* @date         : 2018-03-01
* @changes      : 2018-10-29 - CI - Downgrade/Upgrade Parent Opp Stage should only be updated once.
*************************************************************************************************************/
public with sharing class OpportunityTriggerHandler {

    private static Boolean isCornerUpdateDone = false;

    public void doBeforeUpdate(List<Opportunity> newOpportunityList, Map<Id, Opportunity> newOpportunityMap, Map<Id, Opportunity> oldOpportunityMap) {
        system.debug('@newOpportunityList'+newOpportunityList[0].name);
        validateOnChangeToNegotiation(newOpportunityList, oldOpportunityMap);
        populateAccountPrimaryContact(newOpportunityList, newOpportunityMap, oldOpportunityMap);
    }

    public void doAfterUpdate(List<Opportunity> newOpportunityList, Map<Id, Opportunity> newOpportunityMap, Map<Id, Opportunity> oldOpportunityMap) {
        createRebookingOpportunities(newOpportunityList, newOpportunityMap, oldOpportunityMap);
        createLineItemForStandAndPavilion(newOpportunityList, oldOpportunityMap, false);
        updateParentOpportunityFromUpgrade(newOpportunityList, oldOpportunityMap);
        createWithdrawalOpportunityLineItemForWithdrawal(newOpportunityList, oldOpportunityMap);
        cornerPricingCreateLineItem(newOpportunityList, oldOpportunityMap, false);
    }

    public void doAfterInsert(List<Opportunity> newOpportunityList) {
        createLineItemForStandAndPavilion(newOpportunityList, null, true);
        createContactRoleForUpgradeDowngradeWithdrawalOpportunity(newOpportunityList);
        set<String> setOfRecordType = new Set<String>();
        for(Opportunity opp :newOpportunityList ){
            system.debug('Opp Name###'+opp.name);
        }
        List<Opportunity> LstOfNewOpportunity = [SELECT Id,RecordType.Name FROM Opportunity where Id in :newOpportunityList];
        for(Opportunity opp :LstOfNewOpportunity ){
            setOfRecordType.add(opp.RecordType.Name);
        }
        if (!setOfRecordType.contains('Divcom Visitor') && !setOfRecordType.contains('Mumbrella Visitor')) {
    		cornerPricingCreateLineItem(newOpportunityList, null, true); 
            }
       
        getOpptyIdWithParentOppty(newOpportunityList);
        addPrimarySegmentToNewOpp(newOpportunityList);
    }

    /************************************************************************************************************
    * @description  : Populate the primary contact role from the Opportunity Contact Role
    * @author       : Salesfix - CI
    * @date         : 2018-03-09
    * @param        : oppList - trigger.new
    * @param        : newMap - trigger.newMap
    * @param        : oldMap - trigger.oldMap
    *************************************************************************************************************/
    public void populateAccountPrimaryContact(List<Opportunity> oppList, Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        Set<Id> validIds = getCompletedOpportunities(oppList, newMap, oldMap);
        List<Account> accountToUpdate = new List<Account>();

        if (!validIds.isEmpty()) {
            Map<Id, Id> oppIdToPrimaryContactRoleMap = groupedOpportunityContactRoles(validIds);
            if (!oppIdToPrimaryContactRoleMap.isEmpty()) {
                for (Opportunity opportunityItem : oppList) {
                    if (oppIdToPrimaryContactRoleMap.get(opportunityItem.Id) != null) {
                        Account newAccount = new Account();

                        newAccount.Id = opportunityItem.AccountId;
                        newAccount.Primary_Contact__c = oppIdToPrimaryContactRoleMap.get(opportunityItem.Id);

                        accountToUpdate.add(newAccount);
                    } 
                }


                try {
                	Database.update(accountToUpdate);
                } catch (Exception e) {
                    System.debug('Error occurred while updating: ' + e.getMessage());
                }
            }
        }
    }

    /************************************************************************************************************
    * @description  : Get the opportunities that are being closed won
    * @author       : Salesfix - CI
    * @date         : 2018-03-09
    * @param        : oppList - trigger.new
    * @param        : newMap - trigger.newMap
    * @param        : oldMap - trigger.oldMap
    * @return       : closed won opportunities' ids
    *************************************************************************************************************/
    public Set<Id> getCompletedOpportunities(List<Opportunity> oppList, Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        Set<Id> closedWonOppIds = new Set<Id>();

        for (Opportunity newOpp : oppList) {
            if (newOpp.StageName == Label.Opportunity_Stage_Closed_Won && 
                newMap.get(newOpp.Id).StageName != oldMap.get(newOpp.Id).StageName) {

                closedWonOppIds.add(newOpp.Id);
            }
        }

        return closedWonOppIds;
    }

    /************************************************************************************************************
    * @description  : Group primary contact role record per opportunity
    * @author       : Salesfix - CI
    * @date         : 2018-03-09
    * @param        : closedWonOpps - opportunities that are being closed won
    * @return       : map of contact roles primary contact
    *************************************************************************************************************/
    public Map<Id, Id> groupedOpportunityContactRoles(Set<Id> closedWonOpps) {
        Map<Id, Id> idContactRoleMap = new Map<Id, Id>();
        List<OpportunityContactRole> opportunityContactRolesList = [
            SELECT Id, 
                   IsPrimary, 
                   OpportunityId, 
                   ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :closedWonOpps AND 
                  IsPrimary = true
        ];

        if (!opportunityContactRolesList.isEmpty()) {
            for (OpportunityContactRole contactRoleItem : opportunityContactRolesList) {
                idContactRoleMap.put(contactRoleItem.OpportunityId, contactRoleItem.ContactId);
            }
        }

        return idContactRoleMap;
    }

    /************************************************************************************************************
    * @description  : Create the rebooking opportunites and the related contact roles
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : oppList - trigger.new
    * @param        : newMap - trigger.newMap
    * @param        : oldMap - trigger.oldMap
    * @History      : Updated by Salesfix Dev - RH To Cater moving of opportunity line item on creation of new oppty record
    *************************************************************************************************************/
    public void createRebookingOpportunities(List<Opportunity> oppList, Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        Savepoint sp = Database.setSavepoint();  
        Map<Id, List<OpportunityLineItem>> getProductToIdMap = new Map<Id, List<OpportunityLineItem>>();
        List<OpportunityLineItem> opptyLineItemList = new List<OpportunityLineItem>();
        QualifiedOpportunityHandler qualifiedOpportunities = getQualifiedOpportunities(oppList, newMap, oldMap);

        if (!qualifiedOpportunities.qualifiedOppIds.isEmpty()) {
            Map<Id, Opportunity> insertRebookingOpportunities = collectInsertOpportunityMap(qualifiedOpportunities);

            System.debug(insertRebookingOpportunities);

            if (!insertRebookingOpportunities.isEmpty()) {
                try {
                    insert insertRebookingOpportunities.values();   
                } catch (Exception e) {
                    System.debug('Inside the exception and the exception is '+e.getMessage());
                    sendEmailError(e.getMessage());
                    Database.rollback(sp);
                }
            }

            List<OpportunityContactRole> opportunityContactRoles = queryContactRoles(qualifiedOpportunities);

            if (!opportunityContactRoles.isEmpty()) {
                Map<Id, List<OpportunityContactRole>> oppIdToContactRoleMap = groupExistingContactRoles(opportunityContactRoles);
                List<OpportunityContactRole> insertContactRoleList = collectInsertContactRoleList(oppIdToContactRoleMap, insertRebookingOpportunities, qualifiedOpportunities);

                if (!insertContactRoleList.isEmpty()) {
                    try {
                        insert insertContactRoleList;

                    } catch (Exception e) {
                        System.debug('Inside the ContactRoleListexception and the exception is ' + e.getMessage());

                        sendEmailError(e.getMessage());

                        Database.rollback(sp);
                    }
                }
            }
        }
    }

    /**************************************************************************************************
    * @description : method to send email when there is unexpected error
    * @author      : Salesfix - CI
    * @date        : 2018-03-05
    * @param       : errorMessage - error message from try catch
    ***************************************************************************************************/
    public void sendEmailError(String errorMessage) {
        List<String> emailAddressToSend = new List<String>();
        Email_Error__c emailError = Email_Error__c.getOrgDefaults();

        if (emailError.Email_Address__c != null) {
            emailAddressToSend.add(emailError.Email_Address__c);
        }

        if (!emailAddressToSend.isEmpty()) {
            String currentClassNameUnparsed = String.valueOf(this);
            String currentClassName = 'Unknown Class';

            if (currentClassNameUnparsed != null && currentClassNameUnparsed.length() > 0 && currentClassNameUnparsed.indexOf(' : ') > -1) {
                currentClassName = currentClassNameUnparsed.substring(0, currentClassNameUnparsed.indexOf(' : '));
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

            email.setSubject(currentClassName + ' Error');
            email.setToAddresses(emailAddressToSend );
            email.setPlainTextBody(currentClassName + ' failed to execute : ' + errorMessage);

            Messaging.sendEmail(new Messaging.Email[] { email });
        }
    }

    /************************************************************************************************************
    * @description  : collect the contact roles that will be inserted
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : groupContactRolesMap - contact roles map per opportunity
    * @param        : insertedOppMap - inserted opportunities
    * @param        : qualifiedOpportunities
    * @return       : list of contact roles
    *************************************************************************************************************/
    public List<OpportunityContactRole> collectInsertContactRoleList(Map<Id, List<OpportunityContactRole>> groupContactRolesMap, Map<Id, Opportunity> insertedOppMap, QualifiedOpportunityHandler qualifiedOpportunities) {
        List<OpportunityContactRole> oppContactRoles = new List<OpportunityContactRole>();

        for (Id oldOpportunityItem : qualifiedOpportunities.qualifiedOppIds) {
            if (!groupContactRolesMap.isEmpty()) {
                if (groupContactRolesMap.get(oldOpportunityItem) != null) {
                    Boolean isFirstContact = true;

                    for (OpportunityContactRole contactRoleItem : groupContactRolesMap.get(oldOpportunityItem)) {
                        OpportunityContactRole newContactRole = new OpportunityContactRole();
                        if (isFirstContact) {
                            newContactRole.IsPrimary = true;
                            isFirstContact = false;
                        }

                        newContactRole.ContactId = contactRoleItem.ContactId;
                        newContactRole.OpportunityId = insertedOppMap.get(oldOpportunityItem).Id;
                        newContactRole.Role = contactRoleItem.Role;
                        oppContactRoles.add(newContactRole);
                    }
                }
            }
        }

        return oppContactRoles;
    }

    /************************************************************************************************************
    * @description  : group contact roles that will be carried over to the rebooking opportunities
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : existingContactRoles - contact roles from the original opportunities
    * @return       : contact roles map
    *************************************************************************************************************/
    public Map<Id, List<OpportunityContactRole>> groupExistingContactRoles(List<OpportunityContactRole> existingContactRoles) {
        Map<Id, List<OpportunityContactRole>> groupedContactRoleMap = new Map<Id, List<OpportunityContactRole>>();
        for (OpportunityContactRole oppContactRole : existingContactRoles) {
            if (!groupedContactRoleMap.containsKey(oppContactRole.OpportunityId)) {
                groupedContactRoleMap.put(oppContactRole.OpportunityId, new List<OpportunityContactRole> { oppContactRole });

            } else {
                groupedContactRoleMap.get(oppContactRole.OpportunityId).add(oppContactRole);
            }
        }

        return groupedContactRoleMap;
    }

    /************************************************************************************************************
    * @description  : collect all opportunities that can be rebooked
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : oppList - trigger.new
    * @param        : newMap - trigger.newMap
    * @param        : oldMap - trigger.oldMap
    * @return       : id and map of qualified opportunities
    *************************************************************************************************************/
    public QualifiedOpportunityHandler getQualifiedOpportunities(List<Opportunity> oppList, Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        QualifiedOpportunityHandler opportunityWrapper = new QualifiedOpportunityHandler();

        System.debug('InsidegetQualifiedOpportunities');
   
        for (Opportunity newOpp : oppList) {
            if (newOpp.Rebooked__c == true && 
                newMap.get(newOpp.Id).Rebooked__c != oldMap.get(newOpp.Id).Rebooked__c && 
                newOpp.StageName == Label.Opportunity_Stage_Closed_Won) {

                opportunityWrapper.qualifiedOppIds.add(newOpp.Id);
                opportunityWrapper.qualifiedOppMap.put(newOpp.Id, newOpp);
            }
        }

        return opportunityWrapper;
    }

    /************************************************************************************************************
    * @description  : query the contact roles that will be carried over
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : qualifiedOpportunities - id and map of opportunities that will be rebooked
    * @return       : list of contact roles
    *************************************************************************************************************/
    public List<OpportunityContactRole> queryContactRoles(QualifiedOpportunityHandler qualifiedOpportunities) {
        return [
            SELECT Id, 
                   Role, 
                   ContactId, 
                   OpportunityId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :qualifiedOpportunities.qualifiedOppIds
        ];
    }

    /************************************************************************************************************
    * @description  : collect the rebooking opportunities
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    * @param        : qualifiedOpportunities - id and map of opportunities that will be rebooked
    * @return       : map of rebooking opportunity
    *************************************************************************************************************/
    public Map<Id, Opportunity> collectInsertOpportunityMap(QualifiedOpportunityHandler qualifiedOpportunities) {
        Map<Id, Opportunity> rebookOpportunities = new Map<Id, Opportunity>();
        List<Opportunity> qualifiedopportunitiesList = [
            SELECT Id, 
                   OwnerId, 
                   AccountId, 
                   Account.Name, 
                   Trustee__c, 
                   Event__c, 
                   Event__r.Next_Event__r.Price_Book__c, 
                   Event__r.Default_Days_to_Close_Opportunities__c, 
                   Event__r.Next_Event__c, 
                   Event__r.Next_Event__r.Name, 
                   Pricebook2Id, 
                   Trading_As__c
            FROM Opportunity
            WHERE Id IN :qualifiedOpportunities.qualifiedOppIds
        ];

        for (Opportunity opp : qualifiedopportunitiesList) {
            Opportunity newOpportunity = new Opportunity();

            Integer daysToClose = Integer.valueOf(opp.Event__r.Default_Days_to_Close_Opportunities__c != null ? opp.Event__r.Default_Days_to_Close_Opportunities__c : 0);

            newOpportunity.Name = String.format(Label.Rebook_Opportunity_Name, new List<String> { opp.Account.Name, opp.Event__r.Next_Event__r.Name });
            newOpportunity.CloseDate = date.today().addDays(daysToClose);
            newOpportunity.StageName = Label.Opportunity_Stage_Negotiation;
            newOpportunity.Trading_As__c = opp.Trading_As__c;
            newOpportunity.AccountId = opp.AccountId;
            newOpportunity.Cooling_Off_Period_Active__c = true;
            newOpportunity.Description = Label.Rebook_Opportunity_Description;
            newOpportunity.Event__c = opp.Event__c != null ? opp.Event__r.Next_Event__c : null;
            newOpportunity.NextStep = Label.Rebook_Opportunity_Next_Step;
            newOpportunity.OwnerId = opp.OwnerId;
            newOpportunity.Pricebook2Id = opp.Event__c != null ? opp.Event__r.Next_Event__r.Price_Book__c : opp.Pricebook2Id;
            newOpportunity.Trustee__c = opp.Trustee__c;

            rebookOpportunities.put(opp.Id, newOpportunity);
        }

        return rebookOpportunities;
    }

    /************************************************************************************************************
    * @description  : Wrapper class to return both ids and opportunity map itself using a single method
    * @author       : Salesfix - CI
    * @date         : 2018-03-05
    *************************************************************************************************************/
    public class QualifiedOpportunityHandler{
        public Set<Id> qualifiedOppIds = new Set<Id>();
        public Map<Id, Opportunity> qualifiedOppMap = new Map<Id, Opportunity>();
    }

    /****************************************************************************************************************
    * @description  : Method to create new OpportunityLineItem
    * @author       : Salesfix - JL
    * @date         : 2018-03-16
    * @param        : newOpportunityList - trigger.new
    * @param        : oldOpportunityMap - trigger.oldMap
    *****************************************************************************************************************/
    public void createLineItemForStandAndPavilion(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldOpportunityMap, Boolean isInsert) {
        Map<Id, Id> priceBookIdToOpportunityIdStand = new Map<Id, Id>();
        Map<Id, Id> priceBookIdToOpportunityIdPaviliion = new Map<Id, Id>();
        Map<Id, Boolean> opportunityIdToPavilionAvailable = new Map<Id, Boolean>();
        Map<Id, Boolean> opportunityIdToStandAvailable = new Map<Id, Boolean>();
        Set<Id> opportunityIdsToProcess = new Set<Id>();
        Set<Id> opportunityIdsToProcessDeletion = new Set<Id>();


        for (Opportunity newOpportunity : newOpportunityList) {
            if (!newOpportunity.Is_Withdrawal__c && newOpportunity.Co_Exhibitor_Opportunity__c == null && 
                newOpportunity.StageName != Label.Opportunity_Stage_Closed_Won && newOpportunity.StageName != Label.Opportunity_Stage_Closed_Lost && 
                newOpportunity.isClosed == false && newOpportunity.StageName != Label.Opportunity_Stage_Pending_Change) {

                if (isInsert) {
                    if (newOpportunity.Stand__c != null) {
                        opportunityIdsToProcess.add(newOpportunity.Id);
                    }

                    if (newOpportunity.Pavilion__c != null) {
                        opportunityIdsToProcess.add(newOpportunity.Id);
                    }

                } else {
                    if (newOpportunity.Stand__c != oldOpportunityMap.get(newOpportunity.Id).Stand__c && newOpportunity.Pricebook2Id != null) {
                        if (newOpportunity.Stand__c != null) {
                            priceBookIdToOpportunityIdStand.put(newOpportunity.Pricebook2Id, newOpportunity.Id);
                            opportunityIdsToProcess.add(newOpportunity.Id);

                            opportunityIdsToProcessDeletion.add(newOpportunity.Id);

                            opportunityIdToStandAvailable.put(newOpportunity.Id, true);

                        } else {
                            if (newOpportunity.Pavilion__c != null) {
                                opportunityIdToPavilionAvailable.put(newOpportunity.Id, true);

                            } else {
                                opportunityIdToPavilionAvailable.put(newOpportunity.Id, false);
                            }

                            opportunityIdsToProcessDeletion.add(newOpportunity.Id);
                        }
                    }

                    if (newOpportunity.Pavilion__c != oldOpportunityMap.get(newOpportunity.Id).Pavilion__c && newOpportunity.Pricebook2Id != null) {
                        if (newOpportunity.Pavilion__c != null) {
                            priceBookIdToOpportunityIdPaviliion.put(newOpportunity.Pricebook2Id, newOpportunity.Id);
                            opportunityIdsToProcess.add(newOpportunity.Id);
                        } else {
                            if (newOpportunity.Stand__c != null) {
                                opportunityIdToStandAvailable.put(newOpportunity.Id, true);

                            } else {
                                opportunityIdToStandAvailable.put(newOpportunity.Id, false);
                            }

                            //opportunityIdsToProcessDeletion.add(newOpportunity.Id);
                        }

                        opportunityIdsToProcessDeletion.add(newOpportunity.Id);
                    }
                }
            }
        }


        if (!isInsert) {
            if (!opportunityIdsToProcessDeletion.isEmpty()) {

                removeOpportunityLineItem(opportunityIdToPavilionAvailable, opportunityIdToStandAvailable, opportunityIdsToProcessDeletion);
            }

            processAndInsertOpportunityLineItem(opportunityIdsToProcess, priceBookIdToOpportunityIdStand, priceBookIdToOpportunityIdPaviliion);

        } else {
            if (!opportunityIdsToProcess.isEmpty()) {
                futureInsertOLIforOpportunity(opportunityIdsToProcess);
            }
        }
    }

    @future
    public static void futureInsertOLIforOpportunity(Set<Id> opportunityIdsToProcess) {
        Map<Id, Id> priceBookIdToOpportunityIdStand = new Map<Id, Id>();
        Map<Id, Id> priceBookIdToOpportunityIdPaviliion = new Map<Id, Id>();

        for (Opportunity existingOpportunity : [
            SELECT Id, 
                   Stand__c, 
                   Pavilion__c, 
                   Pricebook2Id 
            FROM Opportunity 
            WHERE Id IN :opportunityIdsToProcess
        ]) {
            if (existingOpportunity.Stand__c != null) {
                priceBookIdToOpportunityIdStand.put(existingOpportunity.Pricebook2Id, existingOpportunity.Id);
                opportunityIdsToProcess.add(existingOpportunity.Id);
            }

            if (existingOpportunity.Pavilion__c != null) {
                priceBookIdToOpportunityIdPaviliion.put(existingOpportunity.Pricebook2Id, existingOpportunity.Id);
                opportunityIdsToProcess.add(existingOpportunity.Id);
            }
        }

        processAndInsertOpportunityLineItem(opportunityIdsToProcess, priceBookIdToOpportunityIdStand, priceBookIdToOpportunityIdPaviliion);
    }

    /****************************************************************************************************************
    * @description  : Method to remove oportuntiyLineItem
    * @author       : Salesfix - JL
    * @date         : 2018-03-16
    * @param        : opportunityIdToPavilionAvailable - opportunity Id to Pavilion that is available
    * @param        : opportunityIdToStandAvailable - opportunity Id to Stand that is available
    * @param        : opportunityIdsToProcessDeletion - opportunity Id to be deleted
    *****************************************************************************************************************/
    public void removeOpportunityLineItem(Map<Id, Boolean> opportunityIdToPavilionAvailable, Map<Id, Boolean> opportunityIdToStandAvailable, Set<Id> opportunityIdsToProcessDeletion) {
        List<OpportunityLineItem> opportunityLineItemToDelete = new List<OpportunityLineItem>();
        List<OpportunityLineItem> existingOpportunityLineItems = [
            SELECT Id, 
                   PricebookEntryId, 
                   OpportunityId, 
                   PricebookEntry.Default_Selected_for_Stand__c, 
                   PricebookEntry.Default_Selected_for_Pavilion__c, 
                   Product2.QuantityUnitOfMeasure
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :opportunityIdsToProcessDeletion
        ];

        if (!existingOpportunityLineItems.isEmpty()) {
            for (OpportunityLineItem opportunityLineItem : existingOpportunityLineItems) {
                if (opportunityLineItem.Product2.QuantityUnitOfMeasure == 'SQM') {
                    opportunityLineItemToDelete.add(opportunityLineItem);

                } else if (opportunityLineItem.PricebookEntry.Default_Selected_for_Stand__c && opportunityLineItem.PricebookEntry.Default_Selected_for_Pavilion__c) {
                    if (opportunityIdToPavilionAvailable.get(opportunityLineItem.OpportunityId) != null && !opportunityIdToPavilionAvailable.get(opportunityLineItem.OpportunityId)) {
                        opportunityLineItemToDelete.add(opportunityLineItem);

                    } else if (opportunityIdToStandAvailable.get(opportunityLineItem.OpportunityId) != null && !opportunityIdToStandAvailable.get(opportunityLineItem.OpportunityId)) {
                        opportunityLineItemToDelete.add(opportunityLineItem);
                    }

                } else if (opportunityLineItem.PricebookEntry.Default_Selected_for_Stand__c && !opportunityLineItem.PricebookEntry.Default_Selected_for_Pavilion__c) {
                    if (opportunityIdToPavilionAvailable.get(opportunityLineItem.OpportunityId) != null) {
                        opportunityLineItemToDelete.add(opportunityLineItem);
                    }

                } else if (opportunityLineItem.PricebookEntry.Default_Selected_for_Pavilion__c && !opportunityLineItem.PricebookEntry.Default_Selected_for_Stand__c) {
                    if (opportunityIdToStandAvailable.get(opportunityLineItem.OpportunityId) != null) {
                        opportunityLineItemToDelete.add(opportunityLineItem);
                    }
                }
            }

            if (!opportunityLineItemToDelete.isEmpty()) {
                try {
                    delete opportunityLineItemToDelete;

                } catch (Exception e) {
                    sendEmailError(e.getMessage());
                }
            }
        }
    }

    /****************************************************************************************************************
    * @description  : 
    * @author       : Salesfix - JL
    * @date         : 2018-03-16
    * @param        : mapPricebookIdToOppId - map for PricebookId to OpportunityId
    * @param        : isStand - Boolean to check if stand or pavilion
    *****************************************************************************************************************/
    public static void processAndInsertOpportunityLineItem(Set<Id> opportunityIdsToProcess, Map<Id, Id> priceBookIdToOpportunityIdStand, Map<Id, Id> priceBookIdToOpportunityIdPaviliion) {
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        Set<Id> priceBookEntryIds = queryExistingOpportunityLineItemForOpp(opportunityIdsToProcess);


        if (!priceBookIdToOpportunityIdStand.isEmpty()) {
            List<OpportunityLineItem> opportunityLineItems = findProductsToBeAddedToOpportunity(priceBookIdToOpportunityIdStand, true);


            if (!opportunityLineItems.isEmpty()) {
                for (OpportunityLineItem opportunityItem : opportunityLineItems) {
                    if (!priceBookEntryIds.contains(opportunityItem.PricebookEntryId)) {
                        opportunityLineItemsToInsert.add(opportunityItem);
                    }
                }
            }
        }

        if (!priceBookIdToOpportunityIdPaviliion.isEmpty()) {
            List<OpportunityLineItem> opportunityLineItems = findProductsToBeAddedToOpportunity(priceBookIdToOpportunityIdPaviliion, false);

            if (!opportunityLineItems.isEmpty()) {
                for (OpportunityLineItem opportunityItem : opportunityLineItems) {
                    if (!priceBookEntryIds.contains(opportunityItem.PricebookEntryId)) {
                        opportunityLineItemsToInsert.add(opportunityItem);
                    }
                }
            }
        }

        if (!opportunityLineItemsToInsert.isEmpty()) {
            List<OpportunityLineItem> finalOpportunityLineItems = removeDuplicatePriceBookEntry(opportunityLineItemsToInsert);


            if (!finalOpportunityLineItems.isEmpty()) {
                insert finalOpportunityLineItems;
            }
        }
    }

    /****************************************************************************************************************
    * @description  : 
    * @author       : Salesfix - JL
    * @date         : 2018-03-16
    * @param        : mapPricebookIdToOppId - map for PricebookId to OpportunityId
    * @param        : isStand - Boolean to check if stand or pavilion
    *****************************************************************************************************************/
    public static List<OpportunityLineItem> removeDuplicatePriceBookEntry(List<OpportunityLineItem> opportunityLineItemsToInsert) {
        List<OpportunityLineItem> finalOpportunityLineItemsList = new List<OpportunityLineItem>();
        Set<String> opportunityIdPriceBookEntry = new Set<String>();

        for (OpportunityLineItem oppLineItem : opportunityLineItemsToInsert) {
            if (!opportunityIdPriceBookEntry.contains(oppLineItem.OpportunityId + '' + oppLineItem.PricebookEntryId)) {
                finalOpportunityLineItemsList.add(oppLineItem);

                opportunityIdPriceBookEntry.add(oppLineItem.OpportunityId + '' + oppLineItem.PricebookEntryId);
            }
        }

        return finalOpportunityLineItemsList;
    }

    /****************************************************************************************************************
    * @description  : 
    * @author       : Salesfix - JL
    * @date         : 2018-03-16
    * @param        : mapPricebookIdToOppId - map for PricebookId to OpportunityId
    * @param        : isStand - Boolean to check if stand or pavilion
    *****************************************************************************************************************/
    public static Set<Id> queryExistingOpportunityLineItemForOpp(Set<Id> opportunityIds) {
        Set<Id> priceBookEntryIds = new Set<Id>();

        for (OpportunityLineItem existingOpportunityLineItem : [
            SELECT Id, 
                   PricebookEntryId 
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :opportunityIds
        ]) {
            priceBookEntryIds.add(existingOpportunityLineItem.PricebookEntryId);
        }

        return priceBookEntryIds;
    }

    /****************************************************************************************************************
    * @description  : Method to query PriceBookEntry for the products to be added as OpportunityLineItem
    * @author       : Salesfix - JL
    * @date         : 2018-03-16
    * @param        : mapPricebookIdToOppId - map for PricebookId to OpportunityId
    * @param        : isStand - Boolean to check if stand or pavilion
    *****************************************************************************************************************/
    public static List<OpportunityLineItem> findProductsToBeAddedToOpportunity(Map<Id, Id> mapPricebookIdToOppId, Boolean isStand) {
        List<OpportunityLineItem> newOpportunityLineItems = new List<OpportunityLineItem>();

        if (isStand) {
            for (PricebookEntry priceBookEntryProduct : [
                SELECT Id, 
                       Product2Id, 
                       Pricebook2Id, 
                       Default_Selected_for_Stand__c, 
                       UnitPrice 
                FROM PricebookEntry
                WHERE Pricebook2Id IN :mapPricebookIdToOppId.keySet() AND 
                      Default_Selected_for_Stand__c = true AND 
                      (Product2.Side_Count__c <= 0 OR Product2.Side_Count__c = null) AND 
                      Product2.QuantityUnitOfMeasure != 'CORNER'
            ]) {
                OpportunityLineItem newOpportunityLineItem = mapDataToOpportunityLineItem(priceBookEntryProduct, mapPricebookIdToOppId.get(priceBookEntryProduct.Pricebook2Id));
                newOpportunityLineItems.add(newOpportunityLineItem);
            }
        } else {
            for (PricebookEntry priceBookEntryProduct : [
                SELECT Id, 
                       Product2Id, 
                       Pricebook2Id, 
                       Default_Selected_for_Stand__c, 
                       UnitPrice 
                FROM PricebookEntry
                WHERE Pricebook2Id IN :mapPricebookIdToOppId.keySet() AND 
                      Default_Selected_for_Pavilion__c = true AND 
                      (Product2.Side_Count__c <= 0 OR Product2.Side_Count__c = null)
            ]) {
                OpportunityLineItem newOpportunityLineItem = mapDataToOpportunityLineItem(priceBookEntryProduct, mapPricebookIdToOppId.get(priceBookEntryProduct.Pricebook2Id));

                newOpportunityLineItems.add(newOpportunityLineItem);
            }
        }

        return newOpportunityLineItems;
    }

    /****************************************************************************************************************
    * @description  : Method to map the data to OpportunityLineItem
    * @author       : Salesfix - JL
    * @date         : 2018-03-16
    * @param        : pricebookEntryRecord - PriceBookEntry record
    * @param        : opportuntiyId - Opportunity Id
    *****************************************************************************************************************/
    public static OpportunityLineItem mapDataToOpportunityLineItem(PricebookEntry pricebookEntryRecord, Id opportuntiyId) {
        OpportunityLineItem newOpportunityLineItem = new OpportunityLineItem();

        newOpportunityLineItem.OpportunityId = opportuntiyId;
        newOpportunityLineItem.Quantity = 1;
        newOpportunityLineItem.Pricebookentryid = pricebookEntryRecord.Id;
        newOpportunityLineItem.UnitPrice = pricebookEntryRecord.UnitPrice;

        return newOpportunityLineItem;
    }

    /***************************************************************************************************************
    * @description  : Method to update Parent Opportunity
    * @author       : Salesfix - JL
    * @date         : 2018-04-09
    * @param        : newOpportunityList - trigger.new
    * @param        : oldOpportunityMap - trigger.oldMap
    ****************************************************************************************************************/
    public void updateParentOpportunityFromUpgrade(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldOpportunityMap) {
        Set<Id> setOfParentOpportunityToLostUpgrade = new Set<Id>();
        Set<Id> settOfParentOpportunityToWonUpgrade = new Set<Id>();
        Set<Id> setOfParentOpportunityToLostDowngrade = new Set<Id>();
        Set<Id> settOfParentOpportunityToWonDowngrade = new Set<Id>();
        List<Opportunity> filteredOpportunitiesList = [
            SELECT Id, 
                   StageName, 
                   Type, 
                   Parent_Upgrade_Opportunity__c, 
                   Parent_Downgrade_Opportunity__c, 
                   Parent_Upgrade_Opportunity__r.StageName, 
                   Parent_Downgrade_Opportunity__r.Stagename
            FROM Opportunity 
            WHERE Id IN :newOpportunityList
        ];

        for (Opportunity newOpportunity : filteredOpportunitiesList) {
            if (newOpportunity.Parent_Upgrade_Opportunity__c != null && newOpportunity.Type == Label.Opportunity_Type_Upgrade && 
                newOpportunity.Parent_Upgrade_Opportunity__r.StageName != Label.Opportunity_Stage_Closed_Won && 
                newOpportunity.Parent_Upgrade_Opportunity__r.StageName != Label.Opportunity_Stage_Closed_Lost) {

                if (newOpportunity.StageName != oldOpportunityMap.get(newOpportunity.Id).StageName) {
                    if (newOpportunity.StageName == Label.Opportunity_Stage_Closed_Won) {
                        setOfParentOpportunityToLostUpgrade.add(newOpportunity.Parent_Upgrade_Opportunity__c);

                    } else if (newOpportunity.StageName == Label.Opportunity_Stage_Closed_Lost) {
                        settOfParentOpportunityToWonUpgrade.add(newOpportunity.Parent_Upgrade_Opportunity__c);
                    }
                }

            } else if (newOpportunity.Parent_Downgrade_Opportunity__c != null && newOpportunity.Type == Label.Opportunity_Type_Downgrade && 
                       newOpportunity.Parent_Downgrade_Opportunity__r.StageName != Label.Opportunity_Stage_Closed_Won && 
                       newOpportunity.Parent_Downgrade_Opportunity__r.StageName != Label.Opportunity_Stage_Closed_Lost) {

                if (newOpportunity.StageName != oldOpportunityMap.get(newOpportunity.Id).StageName) {
                    if (newOpportunity.StageName == Label.Opportunity_Stage_Closed_Won) {
                        setOfParentOpportunityToLostDowngrade.add(newOpportunity.Parent_Downgrade_Opportunity__c);
                    } else if (newOpportunity.StageName == Label.Opportunity_Stage_Closed_Lost) {
                        settOfParentOpportunityToWonDowngrade.add(newOpportunity.Parent_Downgrade_Opportunity__c);
                    }
                }
            }
        }

        updateNewValueForParentOpportunityUpgrade(setOfParentOpportunityToLostUpgrade, settOfParentOpportunityToWonUpgrade);
        updateNewValueForParentOpportunityDowngrade(setOfParentOpportunityToLostDowngrade, settOfParentOpportunityToWonDowngrade);
    }

    /***************************************************************************************************************
    * @description  : Method to update Parent Opportunity
    * @author       : Salesfix - JL
    * @date         : 2018-04-09
    * @param        : setOfParentOpportunityToLost - set of opportunity ids to update to Closed Lost
    * @param        : settOfParentOpportunityToWon - set of opportunity ids to update to Closed Won
    * Updated       : Salesfix Dev - RH : Change Record Type to closed
    ****************************************************************************************************************/
    public void updateNewValueForParentOpportunityUpgrade(Set<Id> setOfParentOpportunityToLost, Set<Id> settOfParentOpportunityToWon) {
        List<Opportunity> opportunityToUpdate = new List<Opportunity>();

        for (Id opportunityId : setOfParentOpportunityToLost) {
            Opportunity updatedOpportunity = new Opportunity(Id = opportunityId);

            updatedOpportunity.RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Closed').getRecordTypeId();//ADDED BY RAY
            updatedOpportunity.StageName = Label.Opportunity_Stage_Closed_Lost;
            updatedOpportunity.Reason_Lost__c = Label.Reason_Lost_Upgraded;

            opportunityToUpdate.add(updatedOpportunity);
        }

        for (Id opportunityId : settOfParentOpportunityToWon) {
            Opportunity updatedOpportunity = new Opportunity(Id = opportunityId);

            updatedOpportunity.StageName = Label.Opportunity_Stage_Closed_Won;
            opportunityToUpdate.add(updatedOpportunity);
        }

        if (!opportunityToUpdate.isEmpty()) {
            try {
                update opportunityToUpdate;

            } catch (Exception e) {
                sendEmailError(e.getMessage());
            }
        }
    }

    /***************************************************************************************************************
    * @description  : Method to update Parent Opportunity
    * @author       : Salesfix - JL
    * @date         : 2018-04-09
    * @param        : setOfParentOpportunityToLost - set of opportunity ids to update to Closed Lost
    * @param        : settOfParentOpportunityToWon - set of opportunity ids to update to Closed Won
    ****************************************************************************************************************/
    public void updateNewValueForParentOpportunityDowngrade(Set<Id> setOfParentOpportunityToLost, Set<Id> settOfParentOpportunityToWon) {
        List<Opportunity> opportunityToUpdate = new List<Opportunity>();

        for (Id opportunityId : setOfParentOpportunityToLost) {
            Opportunity updatedOpportunity = new Opportunity(Id = opportunityId);

            updatedOpportunity.RecordTypeId = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Closed').getRecordTypeId();//ADDED BY RAY
            updatedOpportunity.StageName = Label.Opportunity_Stage_Closed_Lost;
            updatedOpportunity.Reason_Lost__c = Label.Reason_Lost_Downgraded;

            opportunityToUpdate.add(updatedOpportunity);
        }

        for (Id opportunityId : settOfParentOpportunityToWon) {
            Opportunity updatedOpportunity = new Opportunity(Id = opportunityId);

            updatedOpportunity.StageName = Label.Opportunity_Stage_Closed_Won;
            opportunityToUpdate.add(updatedOpportunity);
        }

        if (!opportunityToUpdate.isEmpty()) {
            try {
                update opportunityToUpdate;
            } catch (Exception e) {
                sendEmailError(e.getMessage());
            }
        }
    }

    /***************************************************************************************************************
    * @description  : Method to create Contact Role for Upgrade and Downgrade and Withdrawal Opportunity
    * @author       : Salesfix - JL
    * @date         : 2018-04-09
    * @param        : newOpportunityList - List of opportunity to insert
    ****************************************************************************************************************/
    public void createContactRoleForUpgradeDowngradeWithdrawalOpportunity(List<Opportunity> newOpportunityList) {
        Map<Id, Id> mapParentIdToOpportunityId = new Map<Id, Id>();
        List<OpportunityContactRole> opportunityContactRoleToInsert = new List<OpportunityContactRole>();

        for (Opportunity newOpportunity : newOpportunityList) {
            if (newOpportunity.Parent_Upgrade_Opportunity__c != null && newOpportunity.Type == Label.Opportunity_Type_Upgrade) {
                mapParentIdToOpportunityId.put(newOpportunity.Parent_Upgrade_Opportunity__c, newOpportunity.Id);

            } else if (newOpportunity.Parent_Downgrade_Opportunity__c != null && newOpportunity.Type == Label.Opportunity_Type_Downgrade) {
                mapParentIdToOpportunityId.put(newOpportunity.Parent_Downgrade_Opportunity__c, newOpportunity.Id);

            } else if (newOpportunity.Parent_Withdrawal_Opportunity__c != null && newOpportunity.Is_Withdrawal__c == true) {
                mapParentIdToOpportunityId.put(newOpportunity.Parent_Withdrawal_Opportunity__c, newOpportunity.Id);
            }
        }

        if (!mapParentIdToOpportunityId.isEmpty()) {
            List<OpportunityContactRole> contactRoles = [
                SELECT Id, 
                       Role, 
                       ContactId, 
                       OpportunityId 
                FROM OpportunityContactRole 
                WHERE OpportunityId IN :mapParentIdToOpportunityId.keySet() AND 
                      IsPrimary = true
            ];

            if (!contactRoles.isEmpty()) {
                for (OpportunityContactRole contactRole : contactRoles) {
                    if (mapParentIdToOpportunityId.get(contactRole.OpportunityId) != null) {
                        OpportunityContactRole newContactRole = new OpportunityContactRole();
                        newContactRole.OpportunityId = mapParentIdToOpportunityId.get(contactRole.OpportunityId);
                        newContactRole.Role = contactRole.Role;
                        newContactRole.ContactId = contactRole.ContactId;
                        newContactRole.IsPrimary = true;
                        opportunityContactRoleToInsert.add(newContactRole);
                    }
                }

                if (!opportunityContactRoleToInsert.isEmpty()) {
                    try {
                        insert opportunityContactRoleToInsert;
                    } catch (Exception e) {
                        sendEmailError(e.getMessage());
                    }
                }
            }
        }
    }

    /***************************************************************************************************************
    * @description  : Method to create line item for newly created Withdrawal opportunity
    * @author       : Salesfix - JL
    * @date         : 2018-04-16
    * @param        : newOpportunityList - List of opportunity to insert
    * @param        : oldOpportunityMap - old opportunity map
    ****************************************************************************************************************/
    public void createWithdrawalOpportunityLineItemForWithdrawal(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldOpportunityMap) {
        Map<Id, Id> mapPricebook2IdToOpportunityId = new Map<Id, Id>();

        for (Opportunity newOpportunity : newOpportunityList) {
            if (newOpportunity.Pricebook2Id != null && newOpportunity.Pricebook2Id != oldOpportunityMap.get(newOpportunity.Id).Pricebook2Id) {
                if (newOpportunity.Parent_Withdrawal_Opportunity__c != null && newOpportunity.Is_Withdrawal__c == true) {
                    mapPricebook2IdToOpportunityId.put(newOpportunity.Pricebook2Id, newOpportunity.Id);
                }
            }
        }

        if (!mapPricebook2IdToOpportunityId.isEmpty()) {
            queryPricebookAndInsertLineItem(mapPricebook2IdToOpportunityId);
        }
    }

    /***************************************************************************************************************
    * @description  : Method to query price book and insert line item.
    * @author       : Salesfix - JL
    * @date         : 2018-04-16
    * @param        : mapPricebook2IdToOpportunityId - map of pricebook Id to Oportunity Id
    ****************************************************************************************************************/
    public void queryPricebookAndInsertLineItem(Map<Id, Id> mapPricebook2IdToOpportunityId) {
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        List<PricebookEntry> pricebookEntries = [
            SELECT Id, 
                   Pricebook2Id, 
                   UnitPrice 
            FROM PricebookEntry 
            WHERE Pricebook2Id IN :mapPricebook2IdToOpportunityId.keySet() AND 
                  Default_Selected_for_Withdrawals__c = true
        ];

        if (!pricebookEntries.isEmpty()) {
            for (PricebookEntry pricebookEntryToInsert : pricebookEntries) {
                if (mapPricebook2IdToOpportunityId.get(pricebookEntryToInsert.Pricebook2Id) != null) {
                    opportunityLineItemsToInsert.add(mapPricebookEntryRecordToLineItem(pricebookEntryToInsert, mapPricebook2IdToOpportunityId.get(pricebookEntryToInsert.Pricebook2Id)));
                }
            }

            if (!opportunityLineItemsToInsert.isEmpty()) {
                insert opportunityLineItemsToInsert;
            }
        }
    }

    /***************************************************************************************************************
    * @description  : Method to map record to OpportunityLineItem
    * @author       : Salesfix - JL
    * @date         : 2018-04-16
    * @param        : pricebookEntryRecord - pricebook entry
    * @param        : opportunityId - opportunity id
    ****************************************************************************************************************/
    public OpportunityLineItem mapPricebookEntryRecordToLineItem(PricebookEntry pricebookEntryRecord, Id opportunityId) {
        OpportunityLineItem newOpportunityLineItem = new OpportunityLineItem();

        newOpportunityLineItem.OpportunityId = opportunityId;
        newOpportunityLineItem.Quantity = 1;
        newOpportunityLineItem.Pricebookentryid = pricebookEntryRecord.Id;
        newOpportunityLineItem.UnitPrice = pricebookEntryRecord.UnitPrice;

        return newOpportunityLineItem;
    }

    /***************************************************************************************************************
    * @description  : Method for Corner Pricing
    * @author       : Salesfix - JL
    * @date         : 2018-04-16
    * @param        : newOpportunityList - new opportunity record
    * @param        : oldOpportunityMap - old opportuntiy map
    * @param        : isInsert - Boolean if is insert.
    ****************************************************************************************************************/
    public void cornerPricingCreateLineItem(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldOpportunityMap, Boolean isInsert) {
        Set<Id> opportunityIdToAddLineItem= new  Set<Id>();
        Set<Id> opportunityIdToRemove = new  Set<Id>();
        for (Opportunity newOpportunity : newOpportunityList) {

            if (!newOpportunity.Is_Withdrawal__c && newOpportunity.Co_Exhibitor_Opportunity__c == null
                    && newOpportunity.StageName != Label.Opportunity_Stage_Closed_Won && newOpportunity.StageName != Label.Opportunity_Stage_Closed_Lost
                    && newOpportunity.isClosed == false && newOpportunity.StageName != Label.Opportunity_Stage_Pending_Change) {

                if (isInsert) {
                    if (newOpportunity.Stand__c != null) {
                        opportunityIdToAddLineItem.add(newOpportunity.Id);
                    }

                } else if (!isInsert) {
                    if (newOpportunity.Stand__c != oldOpportunityMap.get(newOpportunity.Id).Stand__c) {
                        if (newOpportunity.Stand__c != null) {
                            opportunityIdToAddLineItem.add(newOpportunity.Id);
                            if (oldOpportunityMap.get(newOpportunity.Id).Stand__c != null) {
                                opportunityIdToRemove.add(newOpportunity.Id);
                            }

                        } else {
                            opportunityIdToRemove.add(newOpportunity.Id);
                        }
                    }
                }
            }
        }

        if (isInsert) {
            futureProcessCornerAndCreateLineItem(opportunityIdToAddLineItem);
        } else if (!isInsert) {
            if (!opportunityIdToRemove.isEmpty()) {
                removeExistingLineItemForCorner(opportunityIdToRemove);
            }

            if (!opportunityIdToAddLineItem.isEmpty()) {
                processCornerAndCreateLineItem(opportunityIdToAddLineItem);
            }
        }
    }

    /***************************************************************************************************************
    * @description  : Method to process Corner Pricing
    * @author       : Salesfix - JL
    * @date         : 2018-04-16
    * @param        : opportunityIds - opportuntiyId To Process
    ****************************************************************************************************************/
    public static void processCornerAndCreateLineItem(Set<Id> opportunityIds) {
        List<OpportunityLineItem> opportunityLineItemToInsert = new List<OpportunityLineItem>();
        List<CornerWrapper> cornerWrapperList = new List<CornerWrapper>();
        Set<Decimal> openCornerSet = new Set<Decimal>();
        Set<Id> pricebookIdSet = new Set<Id>();
        List<Opportunity> opportunityToProcess = [
            SELECT Id, 
                   Name, 
                   Pricebook2Id, 
                   Stand__r.Open_Corners__c, 
                   Stand__c, 
                   Stand__r.Name 
            FROM Opportunity 
            WHERE Id IN :opportunityIds
        ];

        if (!opportunityToProcess.isEmpty()) {
            for (Opportunity opportunity : opportunityToProcess) {
                Decimal sideCountToGet = getSideCountToBeQuerying(opportunity.Stand__r.Open_Corners__c);

                if (sideCountToGet != null) {
                    CornerWrapper cornerWrapper = new CornerWrapper();

                    cornerWrapper = mapValuesTOWrapper(opportunity);
                    cornerWrapper.openCorners = sideCountToGet;

                    cornerWrapperList.add(cornerWrapper);
                    openCornerSet.add(sideCountToGet);
                    pricebookIdSet.add(opportunity.Pricebook2Id);
                }
            }
        }

        if (!cornerWrapperList.isEmpty()) {
            List<PricebookEntry> pricebookEntries = [
                SELECT Id, 
                       Product2.Name, 
                       Pricebook2Id, 
                       Product2Id, 
                       Product2.Side_Count__c, 
                       Product2.QuantityUnitOfMeasure, 
                       UnitPrice 
                FROM PricebookEntry
                WHERE Product2.QuantityUnitOfMeasure = :Label.Corner AND 
                      Default_Selected_for_Stand__c = true AND (
                          Pricebook2Id IN :pricebookIdSet OR 
                          Product2.Side_Count__c IN :openCornerSet
                      )
            ];

            if (!pricebookEntries.isEmpty()) {
                for (CornerWrapper cornerWrap : cornerWrapperList) {
                    for (PricebookEntry pricebookEntry : pricebookEntries) {
                        if (cornerWrap.pricebookId == pricebookEntry.Pricebook2Id && cornerWrap.openCorners == pricebookEntry.Product2.Side_Count__c) {
                            opportunityLineItemToInsert.add(mapDataToOpportunityLineItem(pricebookEntry, cornerWrap.opporutnityId));
                            cornerWrap.isFound = true;
                            break;
                        }
                    }
                }

                if (!opportunityLineItemToInsert.isEmpty()) {
                    List<OpportunityLineItem> finalLineItemToInsert = removeDuplicatePriceBookEntry(opportunityLineItemToInsert);

                    if (!finalLineItemToInsert.isEmpty()) {
                        insert finalLineItemToInsert;
                    }
                }

                sendEmailforNotFound(cornerWrapperList);
            }
        }
    }

    /***************************************************************************************************************
    * @description  : Method to map values to wrapper
    * @author       : Salesfix - JL
    * @date         : 2018-04-16
    * @param        : queriedOpportunity - opportunity
    ****************************************************************************************************************/
    public static CornerWrapper mapValuesTOWrapper(Opportunity queriedOpportunity) {
        CornerWrapper corner = new CornerWrapper();

        corner.opporutnityId = queriedOpportunity.Id;
        corner.pricebookId = queriedOpportunity.Pricebook2Id;
        corner.isFound = false;
        corner.standId = queriedOpportunity.Stand__c;
        corner.standName = queriedOpportunity.Stand__r.Name;
        corner.opportunityName = queriedOpportunity.Name;

        return corner;
    }

    public class CornerWrapper{
        public Id opporutnityId;
        public Id pricebookId;
        public Decimal openCorners;
        public Boolean isFound;
        public Id standId;
        public String standName;
        public String opportunityName;
    }

    /***************************************************************************************************************
    * @description  : Method to remove existing OLI
    * @author       : Salesfix - JL
    * @date         : 2018-04-16
    * @param        : opportunityIdToRemove - opportunity id to remove
    ****************************************************************************************************************/
    public static void removeExistingLineItemForCorner(Set<Id> opportunityIdToRemove) {
        List<OpportunityLineItem> opportunityLineItemToDelete = [
            SELECT Id, 
                   Product2Id 
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :opportunityIdToRemove AND 
                  Product2.QuantityUnitOfMeasure = :Label.Corner
        ];

        if (!opportunityLineItemToDelete.isEmpty()) {
            delete opportunityLineItemToDelete;
        }
    }

    /***************************************************************************************************************
    * @description  : Method to get the Side Count to get
    * @author       : Salesfix - JL
    * @date         : 2018-04-16
    * @param        : openCorner - value for Open Corners
    ****************************************************************************************************************/
    public static Decimal getSideCountToBeQuerying(Decimal openCorner) {
        if (openCorner == 0) {
            return 1;

        } else if (openCorner == 1) {
            return 2;

        } else if (openCorner == 2) {
            return 3;

        } else if (openCorner == 3 || openCorner == 4) {
            return 4;
        }

        return openCorner;
    }

    /***************************************************************************************************************
    * @description  : Future class for insert upon adding Stand
    * @author       : Salesfix - JL
    * @date         : 2018-04-16
    * @param        : opportunityIdToAddLineItem - opportu8inityId to process
    ****************************************************************************************************************/
    @future
    public static void futureProcessCornerAndCreateLineItem(Set<Id> opportunityIdToAddLineItem) {
        processCornerAndCreateLineItem(opportunityIdToAddLineItem);
    }

    /***************************************************************************************************************
    * @description  : Method to send email
    * @author       : Salesfix - JL
    * @date         : 2018-04-16
    * @param        : cornerWrapperList - Wrapper class
    ****************************************************************************************************************/
    public static void sendEmailForNotFound(List<CornerWrapper> cornerWrapperList) {
        List<Messaging.SingleEmailMessage> masterListMails = new List<Messaging.SingleEmailMessage>();

        for (CornerWrapper cornerWrapper : cornerWrapperList) {
            if (cornerWrapper.isFound == false) {
                List<String> emailAddressToSend = new List<String>();
                emailAddressToSend.add(Label.Email_Corner);

                if (!emailAddressToSend.isEmpty()) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setSubject('CORNER - Pricebook Entry product not found');
                    email.setToAddresses(emailAddressToSend);

                    String body = '<html>'+ cornerWrapper.openCorners+' Open Corners not found for Stand : ';

                    body +='<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+cornerWrapper.standId+'">'+cornerWrapper.standName+'</a> for Opportunity : ';
                    body +='<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+cornerWrapper.opporutnityId+'">'+cornerWrapper.opportunityName+'</a> </html>';
                    email.setHtmlBody(body);

                    masterListMails.add(email);
                }
            }
        }
        if (!masterListMails.isEmpty()) {
            Messaging.sendEmail(masterListMails);
        }
    }

    /***************************************************************************************************************
    * @description  : Method to get the Opportunity Line Items with OpportunityId equivalent to that of the new list's parent Oppty IDs
    * @author       : Salesfix - RH
    * @date         : July 3, 2019
    * @param        : Trigger.New
    * @History      : July 8 2019, refactored to put the querying of oppty line item to another method for reusability
    ****************************************************************************************************************/
    public static void getOpptyIdWithParentOppty(List<Opportunity> newOpportunityList) {
        Id oppId = null;
        Set<Id> opptyIds = new Set<Id>();

        for (Opportunity oppRec : newOpportunityList) {
            //IF CODE BLOCKS TO GET THE RIGHT OPPORTUNITY ID
            if (oppRec.Parent_Downgrade_Opportunity__c != null || oppRec.Parent_Upgrade_Opportunity__c != null) {
                oppId = oppRec.Parent_Downgrade_Opportunity__c != null ? oppRec.Parent_Downgrade_Opportunity__c : oppRec.Parent_Upgrade_Opportunity__c;
                opptyIds.add(oppId);
            }
        }

        if (!opptyIds.isEmpty()) {
            Map<Id, List<OpportunityLineItem>> opptyIdToLineItemMap = new Map<Id, List<OpportunityLineItem>>();
            opptyIdToLineItemMap = getProductToIdMap(opptyIds);   

            cloneOpptyLineItem(newOpportunityList, opptyIdToLineItemMap);
        }
    }

    /***************************************************************************************************************
    * @description  : Method to clone the Opportunity Line Item and links it with the new record
    * @author       : Salesfix - RH
    * @date         : July 4, 2019
    * @param        : Trigger.New, Map<Id, List<OpportunityLineItem>>
    ****************************************************************************************************************/
    public static void cloneOpptyLineItem(List<Opportunity> newOpportunityList, Map<Id, List<OpportunityLineItem>> opptyIdToLineItemMap) {
        List<OpportunityLineItem> opptyLineItemList = new List<OpportunityLineItem>();
        for (Opportunity opptyRec : newOpportunityList) {
            //ALL THE LOGIC WILL BE INSIDE THIS IF BLOCK
            //MEANS THAT IT HAS EITHER OF THE PARENT OPPTY FIELDS POPULATED
            if (opptyRec.Parent_Downgrade_Opportunity__c != null || opptyRec.Parent_Upgrade_Opportunity__c != null) {
                Id idVal = opptyRec.Parent_Downgrade_Opportunity__c != null ? opptyRec.Parent_Downgrade_Opportunity__c : opptyRec.Parent_Upgrade_Opportunity__c;
                if (opptyIdToLineItemMap.containsKey(idVal)) {
                    for (OpportunityLineItem opptyLineItemRec : opptyIdToLineItemMap.get(idVal)) {//LOOP TO GET ALL ASSOCIATED OPPTY LINE ITEM LIST
                        OpportunityLineItem opptyLineItemToClone = new OpportunityLineItem();

                        opptyLineItemToClone = opptyLineItemRec.clone(false, false, false, false);//FOR CLONING
                        opptyLineItemToClone.OpportunityId = opptyRec.Id;
                        opptyLineItemList.add(opptyLineItemToClone);
                    }
                }
            }
        }

        if (!opptyLineItemList.isEmpty()) {
            try {
                insert opptyLineItemList;

            } catch (DMLException e) {
                System.debug('Error is : '+ e);
            }
        }
    }

    /***************************************************************************************************************
    * @description  : Method to map the product ID to its Oppty Line Item (FOR Cloning)
    * @author       : Salesfix Dev - RH
    * @date         : July 8, 2019
    * @param        : Set<Id>
    ***************************************************************************************************************/
    public static Map<Id, List<OpportunityLineItem>> getProductToIdMap(Set<Id> opptyIds) {
        List<String> stringList = new List<String>();

        stringList.addAll(Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().keySet());
        String dynamicQuery = 'SELECT ';

        //GETS ALL FIELDS FOR CLONING
        for (Integer counter=0; counter<stringList.size();counter++) {
            if (stringList.get(counter) != 'totalprice') {//UNIT PRICE WILL BE USED INSTEAD OF TOTAL PRICE
                if (counter != stringList.size()-1) {
                    dynamicQuery = dynamicQuery + stringList.get(counter) + ', ';

                } else {
                    dynamicQuery = dynamicQuery + stringList.get(counter) + ' ';
                }
            }
        }

        dynamicQuery = dynamicQuery + 'FROM OpportunityLineItem WHERE OpportunityId IN :opptyIds and Product2.QuantityUnitOfMeasure != \'CORNER\' ';

        Map<Id, List<OpportunityLineItem>> opptyIdToLineItemMap = new Map<Id, List<OpportunityLineItem>>();
        List<OpportunityLineItem> opptyLineItem = new List<OpportunityLineItem>();
        opptyLineItem = database.query(dynamicQuery);

        for (OpportunityLineItem opptyLineItemRec : opptyLineItem) {
            if (opptyIdToLineItemMap.containsKey(opptyLineItemRec.OpportunityId)) {
                opptyIdToLineItemMap.get(opptyLineItemRec.OpportunityId).add(opptyLineItemRec);

            } else {
                opptyIdToLineItemMap.put(opptyLineItemRec.OpportunityId, new List<OpportunityLineItem>{opptyLineItemRec});
            }
        }

        return opptyIdToLineItemMap;
    }

    /************************************************************************************************************
    * @description : validate before moving stage to negotiation
    * @author      : Salesfix Dev - RH
    * @date        : January 7, 2020
    * @param       : newLeadListTriggerNew - trigger.new
    * @param       : oldMapLead - trigger.oldMap
    *************************************************************************************************************/
    public static void validateOnChangeToNegotiation(List<Opportunity> newOpportunityList, Map<Id, Opportunity> oldOpportunityMap) {
        List<Id> filteredOppIds = new List<Id>();
        Set<Id> parentAccIds = new Set<Id>();

        for (Opportunity opp : newOpportunityList) {
            if (opp.StageName == 'Negotiation' && opp.StageName != oldOpportunityMap.get(opp.Id).StageName && opp.AccountId != null) {
                filteredOppIds.add(opp.Id);
                parentAccIds.add(opp.AccountId);
            }
        }

        if (!filteredOppIds.isEmpty()) {
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
                SELECT Id, 
                       Event__r.Event_Category__c 
                FROM Opportunity 
                WHERE Id IN :filteredOppIds
            ]);

            List<Relevant_Segment__c> primarySegments = new List<Relevant_Segment__c>([
                SELECT Id, 
                       Primary_Segment__c, 
                       Secondary_Segment__c, 
                       Event_Category__c, 
                       Account__c, 
                       Lead__c, 
                       Lead__r.Event_Category__c, 
                       Opportunity__c, 
                       Opportunity__r.Event_Category__c 
                FROM Relevant_Segment__c 
                WHERE Opportunity__c IN :filteredOppIds AND 
                      Primary_Segment__c = true
            ]);

            //CODE BLOCK TO QUERY ALL RELATED PRIMARY SEGMENTS AND MAP TO THE ACCOUNT
            Map<Id, List<Relevant_Segment__c>> primarySegmentsByAccountId = new Map<Id, List<Relevant_Segment__c>>();
            List<Relevant_Segment__c> primarySegmentsAccount = new List<Relevant_Segment__c>([
                SELECT Id, 
                       Primary_Segment__c, 
                       Secondary_Segment__c, 
                       Event_Category__c, 
                       Account__c, 
                       Lead__c, 
                       Lead__r.Event_Category__c, 
                       Opportunity__c, 
                       Opportunity__r.Event_Category__c 
                FROM Relevant_Segment__c 
                WHERE Account__c IN :parentAccIds AND 
                      Primary_Segment__c = true
            ]);

            for (Relevant_Segment__c primarySegmentAcc : primarySegmentsAccount) {
                if (primarySegmentsByAccountId.containsKey(primarySegmentAcc.Account__c)) {
                    primarySegmentsByAccountId.get(primarySegmentAcc.Account__c).add(primarySegmentAcc);

                } else {
                    primarySegmentsByAccountId.put(primarySegmentAcc.Account__c, new List<Relevant_Segment__c> { primarySegmentAcc });
                }
            }

            if (!primarySegments.isEmpty()) {
                Map<Id, Relevant_Segment__c> primarySegmentByOppId = new Map<Id, Relevant_Segment__c>();
                List<Relevant_Segment__c> primarySegmentsForUpdate = new List<Relevant_Segment__c>();	

                for (Relevant_Segment__c primarySegment : primarySegments) {
                    //FOR MAPPING CODE BLOCK
                    if (primarySegment.Event_Category__c == primarySegment.Opportunity__r.Event_Category__c) {
                        primarySegmentByOppId.put(primarySegment.Opportunity__c, primarySegment);
                    }
                }

                for (Opportunity opp : newOpportunityList) {
                    if (opp.StageName == 'Negotiation' && opp.StageName != oldOpportunityMap.get(opp.Id).StageName && opp.AccountId != null) {
                        if (primarySegmentByOppId.containsKey(opp.Id)) {
                            Boolean hasPrimarySegmentOnAccountLevel = false;

                            if (primarySegmentsByAccountId.containsKey(opp.AccountId)) {
                                for (Relevant_Segment__c primarySegment : primarySegmentsByAccountId.get(opp.AccountId)) {
                                    //PRIMARY SEGMENT ON ACCOUNT IS SAME WITH OPPORTUNITY'S EVENT CATEGORY
                                    if (primarySegment.Event_Category__c == oppMap.get(opp.Id).event__r.event_category__c) {
                                        hasPrimarySegmentOnAccountLevel = true;

                                        break;
                                    }
                                }
                            }

                            if (hasPrimarySegmentOnAccountLevel) {
                                //DO NOTHING, OPPTY HAS PRIMARY SEGMENT ON OPP AND ACCOUNT LEVEL
                            } else {
                                opp.addError('Account must have a primary segment added for the event related to the opportunity before being able to send an agreement.');
                            }

                        } else {
                            opp.addError('Opportunity must have a primary segment added for the event related to that opportunity before being able to send an agreement');
                        }
                    }
                }

            } else {
                for (Opportunity opp : newOpportunityList) {
                    opp.addError('Opportunity must have a primary segment added for the event related to that opportunity before being able to send an agreement');
                }
            }
        }
    }

    public static void addPrimarySegmentToNewOpp(List<Opportunity> newOpportunityList) {
        System.debug('got in OpportunityTriggerHandler.addPrimarySegmentToNewOpp');

        Set<Id> accountIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();

        for (Opportunity opp : newOpportunityList) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
                opportunityIds.add(opp.Id);
            }
        }

        if (!opportunityIds.isEmpty()) {
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
                SELECT Id, 
                       Event_Category__c 
                FROM Opportunity 
                WHERE Id IN :opportunityIds
            ]);

            Map<Id, List<Relevant_Segment__c>> primarySegmentsByAccountId = new Map<Id, List<Relevant_Segment__c>>();

            for (Relevant_Segment__c relevantPrimarySegment : [
                SELECT Id, 
                       Primary_Segment__c, 
                       Secondary_Segment__c, 
                       Account__c, 
                       Event_Category__c, 
                       Segment_Option__c 
                FROM Relevant_Segment__c 
                WHERE Account__c IN :accountIds AND 
                      Primary_Segment__c = true
            ]) {
                if (!primarySegmentsByAccountId.containsKey(relevantPrimarySegment.Account__c)) {
                    primarySegmentsByAccountId.put(relevantPrimarySegment.Account__c, new List<Relevant_Segment__c> { relevantPrimarySegment });

                } else {
                    primarySegmentsByAccountId.get(relevantPrimarySegment.Account__c).add(relevantPrimarySegment);
                }
            }

            List<Relevant_Segment__c> primarySegmentsForInsert = new List<Relevant_Segment__c>();

            for (Opportunity opp : newOpportunityList) {
                if (opp.AccountId != null) {
                    System.debug('got accountId');

                    if (primarySegmentsByAccountId.containsKey(opp.AccountId)) {
                        System.debug('got primary relevant segments');

                        for (Relevant_Segment__c segmentOnAccount : primarySegmentsByAccountId.get(opp.AccountId)) {
                            if (oppMap.containsKey(opp.Id) && segmentOnAccount.Event_Category__c == oppMap.get(opp.Id).Event_Category__c) {
                                Relevant_Segment__c cloneSegment = new Relevant_Segment__c();

                                cloneSegment = segmentOnAccount.clone(false);
                                cloneSegment.Account__c = null;
                                cloneSegment.Lead__c = null;
                                cloneSegment.Opportunity__c = opp.Id;
                                cloneSegment.Primary_Segment__c = true;

                                primarySegmentsForInsert.add(cloneSegment);

                            }
                        }
                    }
                }
            }

            insert primarySegmentsForInsert;
        }
    }

}