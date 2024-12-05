@isTest
public class BatchForContactUpdateTest {
    
    @isTest
    public static void testBatchProcessing() {
        // Fetch existing record types or create new record types if necessary
        RecordType exhibitorRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Exhibitor_Sponsor' LIMIT 1];
        RecordType visitorRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Visitor' LIMIT 1];
        
        Account objAcc = new Account();
        objAcc.Name = 'Test Acc';
        insert objAcc;
        
        // Create test contacts
        List<Contact> contactList = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Test',
                LastName = 'Contact last ' ,
                RecordTypeId = exhibitorRecordType.Id , // or visitorRecordType.Id based on your needs
                AccountId = objAcc.Id,
                Readt_to_process__c = true
                //OwnerId = '0056F000007lCj0QAE' // Ensure valid OwnerId
            );
            contactList.add(con);
        }
        insert contactList;
        
        List<ContactHistory> historyList = new List<ContactHistory>();
       
            ContactHistory conHistory = new ContactHistory(
                ContactId = contactList[0].Id,
                Field = 'FirstName'
            );
            historyList.add(conHistory);
             ContactHistory conHistory1 = new ContactHistory(
                ContactId = contactList[1].Id,
                Field = 'Title'
            );
            historyList.add(conHistory1);
            ContactHistory conHistory2 = new ContactHistory(
                ContactId = contactList[2].Id,
                Field = 'created'
            );
            historyList.add(conHistory2);
            ContactHistory conHistory3 = new ContactHistory(
                ContactId = contactList[3].Id,
                Field = 'Salutation'
            );
        ContactHistory conHistory4 = new ContactHistory(
                ContactId = contactList[3].Id,
                Field = 'Account'
            );
            historyList.add(conHistory3);
        
        insert historyList; // Note: This is a simplified approach

        List<Contact> updatedContacts = [SELECT Id, LastName,FirstName FROM Contact WHERE Id IN :contactList];
        for (Contact con : updatedContacts) {
            con.FirstName = 'Updated LastName'; 
            con.AccountId = null; // Simulate updated LastName
        }
        update updatedContacts;

        // Verify that the records are updated
        List<Contact> postUpdateContacts = [SELECT Id, LastName,FirstName FROM Contact WHERE Id IN :contactList];
        for (Contact con : postUpdateContacts) {
            System.assertEquals('Updated LastName', con.FirstName, 'The LastName should be updated to "Updated LastName".');
        }

        Test.startTest();
        
        ApexPages.StandardController controller = new ApexPages.StandardController(contactList[0]);
        BatchForContactUpdate batch = new BatchForContactUpdate();
        batch.dumyy();
        Database.executeBatch(batch); // Specify the batch size
        
        Test.stopTest();

    }

    }