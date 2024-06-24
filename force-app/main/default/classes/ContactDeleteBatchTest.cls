@isTest
public class ContactDeleteBatchTest {
    @testSetup
    static void setup() {
        // Create Record Type for Contacts
        RecordType visitorRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'Visitor' LIMIT 1];
        
        // Create test data
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', RecordTypeId = visitorRecordType.Id));
        contacts.add(new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', RecordTypeId = visitorRecordType.Id));
        contacts.add(new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'jane.doe@example.com', RecordTypeId = visitorRecordType.Id));
        contacts.add(new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'jane.doe@example.com', RecordTypeId = visitorRecordType.Id));
        contacts.add(new Contact(FirstName = 'Jim', LastName = 'Beam', Email = 'jim.beam@example.com', RecordTypeId = visitorRecordType.Id));
        insert contacts;
    }

    @isTest
    static void testContactDeleteBatch() {
        // Verify the setup data
        RecordType visitorRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'Visitor' LIMIT 1];
        System.assertNotEquals(null, visitorRecordType, 'Visitor Record Type should exist');

        List<Contact> initialContacts = [SELECT Id, Name, Email FROM Contact WHERE RecordTypeId = :visitorRecordType.Id];
        System.assertEquals(5, initialContacts.size(), 'There should be 5 contacts initially');

        // Start the batch process
        Test.startTest();
        ContactDeleteBatch batch = new ContactDeleteBatch();
        Database.executeBatch(batch);
        Test.stopTest();

    }
}