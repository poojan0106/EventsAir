@IsTest
public class EmailNameMismatchCSVBatchTest {

    @TestSetup
    static void createTestData() {

        // ===== Leads =====
        List<Lead> leads = new List<Lead>{
            new Lead(
                FirstName = 'Alex',
                LastName  = 'Smith',
                Company   = 'ABC',
                Email     = 'dup@test.com',
                Event_Category__c = 'Security'
            ),
            new Lead(
                FirstName = 'John',
                LastName  = 'Smith',
                Company   = 'ABC',
                Email     = 'dup@test.com',
                Event_Category__c = 'Security'
            ),
            new Lead(
                FirstName = 'Single',
                LastName  = 'Lead',
                Company   = 'ABC',
                Email     = 'single@test.com',
                Event_Category__c = 'Security'
            )
        };
        insert leads;

        // ===== Contacts =====
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        List<Contact> contacts = new List<Contact>{
            new Contact(
                FirstName = 'Anna',
                LastName  = 'Brown',
                Email     = 'contactdup@test.com',
                AccountId = acc.Id
            ),
            new Contact(
                FirstName = 'Annie',
                LastName  = 'Brown',
                Email     = 'contactdup@test.com',
                AccountId = acc.Id
            ),
            new Contact(
                FirstName = 'Solo',
                LastName  = 'Contact',
                Email     = 'singlecontact@test.com',
                AccountId = acc.Id
            )
        };
        insert contacts;
    }

    // ================= LEAD TEST =================
    @IsTest
    static void testLeadBatch() {

        Test.startTest();
        Database.executeBatch(
            new EmailNameMismatchCSVBatch(
                'Lead',
                'Lead_Email_Name_Mismatch'
            ),
            200
        );
        Test.stopTest();

        List<ContentVersion> cvs = [
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE Title = 'Lead_Email_Name_Mismatch'
        ];

       
        for (ContentVersion cv : cvs) {
            System.assertNotEquals(
                null,
                cv.VersionData,
                'CSV VersionData must not be null'
            );
        }
    }

    // ================= CONTACT TEST =================
    @IsTest
    static void testContactBatch() {

        Test.startTest();
        Database.executeBatch(
            new EmailNameMismatchCSVBatch(
                'Contact',
                'Contact_Email_Name_Mismatch'
            ),
            200
        );
        Test.stopTest();

        List<ContentVersion> cvs = [
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE Title = 'Contact_Email_Name_Mismatch'
        ];

       

        for (ContentVersion cv : cvs) {
            System.assertNotEquals(
                null,
                cv.VersionData,
                'CSV VersionData must not be null'
            );
        }
    }
}