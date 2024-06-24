/*
 * Created BY Jignasha patel 27-05-2024
 * Desc - TO remove duplicate Contacts based on the recordwa type Name and Email
 */
public class ContactDeleteBatch implements Database.Batchable<sObject> {

    // Start method to query Contacts
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name, Email FROM Contact WHERE RecordType.Name = \'Visitor\' ORDER BY Name ASC');
    }

    // Execute method to process each batch
    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        // Map to track duplicates within the batch
        Map<String, List<Contact>> contactMap = new Map<String, List<Contact>>();

        // Process each contact in the batch
        for (Contact con : scope) {
            String key = con.Name + ',' + con.Email;
            if (!contactMap.containsKey(key)) {
                contactMap.put(key, new List<Contact>());
            }
            contactMap.get(key).add(con);
        }

        // Collect all duplicate contacts
        List<Contact> contactsToDelete = new List<Contact>();
        for (List<Contact> contacts : contactMap.values()) {
            if (contacts.size() > 1) {
                contactsToDelete.addAll(contacts);
            }
        }

        // Delete duplicate contacts
        if (contactsToDelete.size() > 0) {
            delete contactsToDelete;
        }
    }

    // Finish method to handle post-processing
    public void finish(Database.BatchableContext bc) {
        // Optional: Add logging or send an email notification about the deletion
        System.debug('Batch processing complete.');
    }
}