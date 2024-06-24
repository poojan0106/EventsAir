@isTest
public class LeadDeleterBatchTest {

    @testSetup
    static void setup() {
        // Create test data
        List<Lead> leads = new List<Lead>();
		RecordType RT = [select id,Name, DeveloperName from RecordType where Name = 'Visitor' and SobjectType = 'Lead'];
        // Add leads with duplicate names and emails
        leads.add(new Lead(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', Company = 'Test Company 1',Event_Category__c = 'Fine Food Australia',RecordTypeId = RT.Id));
        leads.add(new Lead(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', Company = 'Test Company 2',Event_Category__c = 'Fine Food Australia',RecordTypeId = RT.Id));
        leads.add(new Lead(FirstName = 'Jane', LastName = 'Doe', Email = 'jane.doe@example.com', Company = 'Test Company 3',Event_Category__c = 'Fine Food Australia',RecordTypeId = RT.Id));
        leads.add(new Lead(FirstName = 'Jane', LastName = 'Doe', Email = 'jane.doe@example.com', Company = 'Test Company 4',Event_Category__c = 'Fine Food Australia',RecordTypeId = RT.Id));

        // Add unique leads
        leads.add(new Lead(FirstName = 'Alice', LastName = 'Smith', Email = 'alice.smith@example.com', Company = 'Test Company 5',Event_Category__c = 'Fine Food Australia',RecordTypeId = RT.Id));
        leads.add(new Lead(FirstName = 'Bob', LastName = 'Smith', Email = 'bob.smith@example.com', Company = 'Test Company 6',Event_Category__c = 'Fine Food Australia',RecordTypeId = RT.Id));

        insert leads;
    }

    @isTest
    static void testBatch() {
        // Execute the batch job
        Test.startTest();
        LeadDeleterBatch batch = new LeadDeleterBatch();
        Database.executeBatch(batch, 200); // Batch size set to 200 for testing
        Test.stopTest();

        
    }
}