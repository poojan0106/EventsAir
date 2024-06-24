/*
 * Created BY Jignasha patel 27-05-2024
 * Desc - TO remove duplicate leads based on the recordwa type Name and Email
 */
public class LeadDeleterBatch implements Database.Batchable<sObject> {

    // Start method to query leads
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name, Email FROM Lead WHERE RecordType.Name = \'Visitor\' ORDER BY Name ASC');
    }

    // Execute method to process each batch
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        // Map to track duplicates within the batch
        Map<String, List<Lead>> leadMap = new Map<String, List<Lead>>();
        List<LeadBackup__c> leadbackup = new List<LeadBackup__c>();
        // Process each lead in the batch
        for (Lead lead : scope) {
            String key = lead.Name + ',' + lead.Email;
            if (!leadMap.containsKey(key)) {
                leadMap.put(key, new List<Lead>());
            }
            leadMap.get(key).add(lead);
        }

        // Collect all duplicate leads
        List<Lead> leadsToDelete = new List<Lead>();
        for (List<Lead> leads : leadMap.values()) {
            if (leads.size() > 1) {
                leadsToDelete.addAll(leads);
            }
        }
        for(Lead led : leadsToDelete){
         	LeadBackup__c ledbackup = new LeadBackup__c();
            ledbackup.Lead_Ids__c = led.Id;
            leadbackup.add(ledbackup);
        }
        // Delete duplicate leads and create LeadIds into customobject 
        if (leadbackup.size() > 0) {
        	Insert leadbackup;    
        }
        if (leadsToDelete.size() > 0) {
            delete leadsToDelete;
        }
    }

    // Finish method to handle post-processing
    public void finish(Database.BatchableContext bc) {
        // Optional: Add logging or send an email notification about the deletion
        System.debug('Batch processing complete.');
    }
}