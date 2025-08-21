@isTest
public class CSVimportfunctionalityTest {
    @testSetup
    static void setupTestData() {
        Event__c event = new Event__c(Name = 'Test Event',Event_Portfolio__c = 'Technology');
        insert event;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', Event__c = event.Id, StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;
        
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Test Account 1', BillingCity = 'City1', ABN__c = '12345678910'),
                new Account(Name = 'Test Account 2', BillingCity = 'City2', ABN__c = '98765432111')
                };
                    insert testAccounts;
        
        // Create test Contacts
        List<Contact> testContacts = new List<Contact>{
            new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john@example.com', AccountId = testAccounts[0].Id),
                new Contact(FirstName = 'Jane', LastName = 'Smith', Email = 'jane@example.com', AccountId = testAccounts[1].Id)
                };
                    insert testContacts;
        
        // Create test Trading_As__c records
        List<Trading_As__c> testTradingAs = new List<Trading_As__c>{
            new Trading_As__c(Name = 'Trade Name 1', Account__c = testAccounts[0].Id),
                new Trading_As__c(Name = 'Trade Name 2', Account__c = testAccounts[1].Id)
                };
                    insert testTradingAs;
        Account acc = new Account(
            Name = 'Test Account',
            BillingCity = '',
            BillingState = 'CA',
            BillingCountry = '',
            BillingPostalCode = '12345',
            Phone = '123-456-7890'
        );
        insert acc;
        
        List<Stand__c> stands = new List<Stand__c>();
        for (Integer i = 1; i <= 3; i++) {
            stands.add(new Stand__c(Name = 'Stand' + i, Event__c = event.id));
        }
        insert stands;
        // Create a Contact related to the Account
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            Phone = '9876543210',
            AccountId = acc.Id
        );
        insert con;
        
        // Create a Trading_As__c record
        Trading_As__c ta = new Trading_As__c(
            Name = 'Test Trading Name',
            Account__c = acc.Id
        );
        insert ta;
    }
    
    @isTest
    static void testSaveFileSuccess() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64Data = '\"First Name,Last Name,Email Address,Customer Coordinator,Company Name,Exhibiting As,ABN,Address Line 1,City,State,Postal Code,Country,Work Phone,Stand Number\r\nPattaraporn,Kongsagoonwong,Marketing-admin@royalplus.co.th,Pattaraporn Kongsagoonwong,Test Account,Test Account,,84/3-7 Rama ll Soi 69,Samae Dam,Bang Kung Thain,10150,\"Bangkok,Thailand\",616394255,HT12\r\n,,,,,,,,,,,,,\r\n,,,,,,,,,,,,,\r\n\"';
        /*String base64Data =  '"First Name","Last Name","Email Address","Customer Coordinator","Company Name","Exhibiting As","ABN","Address Line 1","City","State","Postal Code","Country","Work Phone","Stand Number"\n' +
'"Pattaraporn","Kongsagoonwong","Marketing-admin@royalplus.co.th","Pattaraporn Kongsagoonwong","Royal Plus Public Company Limited","Royal Plus Public Company Limited","","84/3-7 Rama ll Soi 69","Samae Dam","Bang Kung Thain","10150","Bangkok,Thailand","616394255","HT12"\n';*/
        String base64Encoded = EncodingUtil.base64Encode(Blob.valueOf(base64Data));
        Test.startTest();
        String result = CSVimportfunctionality.saveFile(base64Encoded, opp.Id);
        Test.stopTest();
        System.assertNotEquals(result, 'Error', 'Expected a successful file processing result.');
    }
    
    @isTest
    static void testSaveFileSuccess2() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64Data ='\"First Name,Last Name,Email Address,Customer Coordinator,Company Name,Exhibiting As,ABN,Address Line 1,City,State,Postal Code,Country,Work Phone,Stand Number\r\nPattaraporn,Kongsagoonwong,Marketing-admin@royalplus.co.th,Pattaraporn Kongsagoonwong,Royal Plus Public Company Limited,Royal Plus Public Company Limited,,84/3-7 Rama ll Soi 69,Samae Dam,Bang Kung Thain,10150,\"Bangkok,Thailand\",616394255,HT12\r\n,,,,,,,,,,,,,\r\n,,,,,,,,,,,,,\r\n\"';
        String base64Encoded = EncodingUtil.base64Encode(Blob.valueOf(base64Data));
        Test.startTest();
        String result = CSVimportfunctionality.saveFile(base64Encoded, opp.Id);
        Test.stopTest();
        System.assertNotEquals(result, 'Error', 'Expected a successful file processing result.');
    }
    @isTest
    static void testSaveFileMissingHeaders() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64Data = '\"First Name,Last Name,Email Address\r\nPattaraporn,Kongsagoonwong,Marketing-admin@royalplus.co.th\r\n,,,,,,,,,,,,,\r\n,,,,,,,,,,,,,\r\n\"';
        String base64Encoded = EncodingUtil.base64Encode(Blob.valueOf(base64Data));
        Test.startTest();
        String result = CSVimportfunctionality.saveFile(base64Encoded, opp.Id);
        Test.stopTest();
        //System.assert(result.contains('missing the following required columns'), 'Expected missing headers error.');
    }
    @isTest
    static void testFetchAccounts() {
        
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64Data = '\"First Name,Last Name,Email Address,Customer Coordinator,Company Name,Exhibiting As,ABN,Address Line 1,City,State,Postal Code,Country,Work Phone,Stand Number\r\nPattaraporn,Kongsagoonwong,Marketing-admin@royalplus.co.th,Pattaraporn Kongsagoonwong,Test Account,Test Account,,84/3-7 Rama ll Soi 69,Samae Dam,Bang Kung Thain,10150,\"Bangkok,Thailand\",616394255,HT12\r\n,,,,,,,,,,,,,\r\n,,,,,,,,,,,,,\r\n\"';
        String base64Encoded = EncodingUtil.base64Encode(Blob.valueOf(base64Data));
        Test.startTest();
        String result = CSVimportfunctionality.saveFile(base64Encoded, opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSaveFileSuccess3() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64Data =  '\"First Name,Last Name,Email Address,Customer Coordinator,Company Name,Exhibiting As,ABN,Address Line 1,City,State,Postal Code,Country,Work Phone,Stand Number\r\n'
            + 'Pattaraporn,Kongsagoonwong,Marketing-admin@royalplus.co.th,Pattaraporn Kongsagoonwong,Test Account,Royal Plus Public Company Limited,12365487421,84/3-7 Rama ll Soi 69,Samae Dam,Bang Kung Thain,10150,"Bangkok,Thailand",616394255,Stand1\r\n'
            + ',,,,,,,,,,,,,\r\n' // Empty row (should be skipped)
            + ',,,,,,,,,,,,,\r\n';
        String base64Encoded = EncodingUtil.base64Encode(Blob.valueOf(base64Data));
        Test.startTest();
        String result = CSVimportfunctionality.saveFile(base64Encoded, opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(result, 'Error', 'Expected a successful file processing result.');
    }
    
    
    @isTest
    static void testSaveFileSuccess4() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64Data = '\"First Name,Last Name,Email Address,Customer Coordinator,Company Name,Exhibiting As,ABN,Address Line 1,City,State,Postal Code,Country,Work Phone,Stand Number\r\n'
            + 'Pattaraporn,Kongsagoonwong,Marketing-admin@royalplus.co.th,Pattaraporn Kongsagoonwong,Royal Plus Public Company Limited,Royal Plus Public Company Limited,12365487421,84/3-7 Rama ll Soi 69,Samae Dam,Bang Kung Thain,10150,"Bangkok,Thailand",Stand2,Stand1\r\n'
            + ',,,,,,,,,,,,,\r\n' // Empty row (should be skipped)
            + ',,,,,,,,,,,,,\r\n';
        String base64Encoded = EncodingUtil.base64Encode(Blob.valueOf(base64Data));
        Test.startTest();
        String result = CSVimportfunctionality.saveFile(base64Encoded, opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(result, 'Error', 'Expected a successful file processing result.');
    }
    
    
    @isTest
    public static void testReplaceCommasInQuotes() {
        // Test case 1: String with commas inside quotes
        String input = 'Hello, "Salesforce, Developer", Welcome';
        String expectedOutput = 'Hello, "Salesforce:comma: Developer", Welcome';
        String actualOutput = CSVimportfunctionality.replaceCommasInQuotes(input);
        System.assertEquals(expectedOutput, actualOutput, 'The commas inside quotes should be replaced');
        
        // Test case 2: String without quotes
        String input2 = 'Hello, Salesforce Developer, Welcome';
        String expectedOutput2 = 'Hello, Salesforce Developer, Welcome';
        String actualOutput2 = CSVimportfunctionality.replaceCommasInQuotes(input2);
        System.assertEquals(expectedOutput2, actualOutput2, 'String without quotes should remain unchanged');
        
        // Test case 3: Empty string
        String input3 = '';
        String expectedOutput3 = '';
        String actualOutput3 = CSVimportfunctionality.replaceCommasInQuotes(input3);
        System.assertEquals(expectedOutput3, actualOutput3, 'Empty string should return empty string');
    }
    
    @isTest
    public static void testLogError() {
        Test.startTest();
        CSVimportfunctionality.logError('Test Error', 'This is a test error message', 10);
        Test.stopTest();
        
        Error_Log__c[] logs = [SELECT Name, Error_Message__c, Line_Number__c FROM Error_Log__c WHERE Name = 'Test Error'];
        System.assertEquals(1, logs.size(), 'An error log should have been inserted');
        System.assertEquals('This is a test error message', logs[0].Error_Message__c, 'Error message should match');
        System.assertEquals(10, logs[0].Line_Number__c, 'Line number should match');
    }
}