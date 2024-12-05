public class RebookingOpportunitiesBatch implements Database.Batchable<SObject> {
    private String eventId;

    public RebookingOpportunitiesBatch(String eventId) {
        this.eventId = eventId;
    }

    // Start method: Query the opportunities to process
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Rebooked__c, StageName
            FROM Opportunity
            WHERE Event__c =:eventId 
            AND Rebooked__c = false
            AND StageName = :Label.Opportunity_Stage_Closed_Won
        ]);
    }

    // Execute method: Process each batch of opportunities
    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Update the Rebooked__c field to true for all opportunities in this scope.
            for (Opportunity opp : scope) {
                opp.Rebooked__c = true;
            }
            System.debug('scope ' + scope);
            // Proceed with creating rebooking opportunities.
            Map<Id, Opportunity> insertRebookingOpportunities = new Map<Id, Opportunity>();

            // Get qualified opportunities
            QualifiedOpportunityHandler qualifiedOpportunities = getQualifiedOpportunities(scope);

            if (!qualifiedOpportunities.qualifiedOppIds.isEmpty()) {
                insertRebookingOpportunities = collectInsertOpportunityMap(qualifiedOpportunities);

                if (!insertRebookingOpportunities.isEmpty()) {
                    insert insertRebookingOpportunities.values();
                }
                System.debug('insertRebookingOpportunities ' + insertRebookingOpportunities);

                List<OpportunityContactRole> opportunityContactRoles = queryContactRoles(qualifiedOpportunities);

                if (!opportunityContactRoles.isEmpty()) {
                    Map<Id, List<OpportunityContactRole>> oppIdToContactRoleMap = groupExistingContactRoles(opportunityContactRoles);
                    List<OpportunityContactRole> insertContactRoleList = collectInsertContactRoleList(
                        oppIdToContactRoleMap, 
                        insertRebookingOpportunities, 
                        qualifiedOpportunities
                    );

                    if (!insertContactRoleList.isEmpty()) {
                        insert insertContactRoleList;
                    }
                }
            }

            
            // Update the opportunities to set Rebooked__c to true.
            update scope;
        } catch (Exception e) {
            System.debug('Error in batch: ' + e.getMessage());
            sendEmailError(e.getMessage());
            Database.rollback(sp);
        }
    }

    // Finish method: Called when all batches are processed
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch process completed.');
    }

    // Adjusted helper methods to remove oldMap
    private QualifiedOpportunityHandler getQualifiedOpportunities(List<Opportunity> oppList) {
        QualifiedOpportunityHandler opportunityWrapper = new QualifiedOpportunityHandler();
        for (Opportunity newOpp : oppList) {
            if (newOpp.StageName == Label.Opportunity_Stage_Closed_Won) {
                opportunityWrapper.qualifiedOppIds.add(newOpp.Id);
                opportunityWrapper.qualifiedOppMap.put(newOpp.Id, newOpp);
            }
        }
        return opportunityWrapper;
    }

    private Map<Id, Opportunity> collectInsertOpportunityMap(QualifiedOpportunityHandler qualifiedOpportunities) {
        Map<Id, Opportunity> rebookOpportunities = new Map<Id, Opportunity>();
        List<Opportunity> qualifiedOpportunitiesList = [
            SELECT Id, OwnerId, AccountId, Account.Name, Trustee__c, Event__c, 
                   Event__r.Next_Event__r.Price_Book__c, 
                   Event__r.Default_Days_to_Close_Opportunities__c, 
                   Event__r.Next_Event__c, 
                   Event__r.Next_Event__r.Name, 
                   Pricebook2Id, Trading_As__c
            FROM Opportunity
            WHERE Id IN :qualifiedOpportunities.qualifiedOppIds
        ];

        for (Opportunity opp : qualifiedOpportunitiesList) {
            Opportunity newOpportunity = new Opportunity();
            Integer daysToClose = Integer.valueOf(opp.Event__r.Default_Days_to_Close_Opportunities__c != null ? opp.Event__r.Default_Days_to_Close_Opportunities__c : 0);

            newOpportunity.Name = String.format(Label.Rebook_Opportunity_Name, new List<String> { opp.Account.Name, opp.Event__r.Next_Event__r.Name });
            newOpportunity.CloseDate = Date.today().addDays(daysToClose);
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

    private List<OpportunityContactRole> queryContactRoles(QualifiedOpportunityHandler qualifiedOpportunities) {
        return [
            SELECT Id, Role, ContactId, OpportunityId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :qualifiedOpportunities.qualifiedOppIds
        ];
    }

    private Map<Id, List<OpportunityContactRole>> groupExistingContactRoles(List<OpportunityContactRole> existingContactRoles) {
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

    private List<OpportunityContactRole> collectInsertContactRoleList(
        Map<Id, List<OpportunityContactRole>> groupContactRolesMap, 
        Map<Id, Opportunity> insertedOppMap, 
        QualifiedOpportunityHandler qualifiedOpportunities
    ) {
        List<OpportunityContactRole> oppContactRoles = new List<OpportunityContactRole>();

        for (Id oldOpportunityItem : qualifiedOpportunities.qualifiedOppIds) {
            if (!groupContactRolesMap.isEmpty() && groupContactRolesMap.get(oldOpportunityItem) != null) {
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

        return oppContactRoles;
    }

    private void sendEmailError(String errorMessage) {
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
            email.setToAddresses(emailAddressToSend);
            email.setPlainTextBody(currentClassName + ' failed to execute: ' + errorMessage);

            Messaging.sendEmail(new Messaging.Email[] { email });
        }
    }

    // Helper class for storing qualified opportunities
    public class QualifiedOpportunityHandler {
        public Set<Id> qualifiedOppIds = new Set<Id>();
        public Map<Id, Opportunity> qualifiedOppMap = new Map<Id, Opportunity>();
    }
}