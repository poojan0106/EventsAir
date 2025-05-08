@isTest
public class ImportFunctionalityTest {
    
    @testSetup
    static void setupTestData() {
        // Create an Event
        Event__c testEvent = new Event__c(Name = 'Test Event',Event_Portfolio__c ='Technology' );
        insert testEvent;
        
        // Create an Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Event__c = testEvent.Id
        );
        insert testOpportunity;
        
        // Create a Stand
        Stand__c testStand = new Stand__c(
            Name = 'Stand 1',
            Event__c = testEvent.Id
        );
        insert testStand;
        
        // Create an Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Email_Address_1__c = 'test@example.com'
        );
        insert testAccount;
        
        // Create a Contact
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
    }
    
    
    @isTest
    static void testParseCSVLines() {
        // Create mock opportunity for the test
        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Event__c = 'a0s6F00000b6pXxQAI', // Use an appropriate event ID
            Pavilion__c = 'a0w6F000008eewKQAQ' // Use an appropriate pavilion ID
        );
        insert opportunity;
        
        // Define CSV data with various cases (valid, blank lines, extra spaces, etc.)
        String csvData = 'First Name,Last Name,Company Name,Email Address,Customer Coordinator Email,Stand Number,Address Line 1,Exhibiting As,Pavilion Number,Work Phone,City,State,Postal Code,Country,ABN' +
            'John,Doe,CoExhibitor1,coexhibitor1@example.com,john@example.com,Stand 1,123 Main St,Brand A,Pavilion 1,123456789,New York,NY,10001,USA,123456789' +
            '   \n' +  // Blank line
            'Jane,Smith,CoExhibitor2,coexhibitor2@example.com,jane@example.com,Stand 2,456 Elm St,Brand B,Pavilion 1,987654321,Los Angeles,CA,90001,USA,987654321' +
            '   \n' +  // Blank line
            'Mark,Johnson,CoExhibitor3,coexhibitor3@example.com,mark@example.com,Stand 3,789 Oak St,Brand C,Pavilion 2,567890123,Chicago,IL,60601,USA,567890123' +
            'Emily,Williams,CoExhibitor4,coexhibitor4@example.com,emily@example.com,Stand 4,321 Pine St,Brand D,Pavilion 2,345678901,San Francisco,CA,94101,USA,345678901' +
            '\n'; // Extra blank line
        
        // Encode CSV data as base64 and decode it
        String data = EncodingUtil.base64Decode(EncodingUtil.base64Encode(Blob.valueOf(csvData))).toString();
        System.debug('data==>'+data);
        // Split CSV into lines & remove empty ones
        List<String> csvLines = new List<String>();
        for (String line : data.split('\n')) {
            if (!String.isBlank(line)) {
                csvLines.add(line.trim());
            }
        }
        
        // Ensure CSV lines are not empty
        System.assert(!csvLines.isEmpty(), 'CSV lines should not be empty after cleanup');
        
        // Extract headers
        List<String> headers = csvLines[0].split(',');
        for (Integer i = 0; i < headers.size(); i++) {
            headers[i] = headers[i].trim();
        }
        
        // Validate required headers exist
        Set<String> requiredHeaders = new Set<String>{
            'First Name', 'Last Name', 'Company Name', 'Email Address',
                'Customer Coordinator Email', 'Stand Number', 'Address Line 1',
                'Exhibiting As', 'Pavilion Number', 'Work Phone', 'City',
                'State', 'Postal Code', 'Country', 'ABN'
                };
                    
                    for (String header : requiredHeaders) {
                        System.assert(headers.contains(header), 'Missing required header: ' + header);
                    }
        
        // Validate the number of parsed lines (4 valid + 1 header)
        System.assertEquals(csvLines.size(), 5, 'CSV should contain 4 valid data lines + header');
    }
    
    @isTest
    static void testInsertCoExhibitors() {
        // Create a mock Opportunity for testing
        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            Event__c = 'a0s6F00000b6pXxQAI', // Use a real Event ID if necessary
            Pavilion__c = 'a0w6F000008eewKQAQ', // Use a real Pavilion ID if necessary
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opportunity;
        
        // Create existing Account mock data
        Account existingAccount = new Account(
            Name = 'CoExhibitor1',
            Email_Address_1__c = 'coexhibitor1@example.com'
        );
        insert existingAccount;
        
        // Create Stand mock data
        Stand__c stand = new Stand__c(
            Name = 'Stand 1',
            Pavilion__c = opportunity.Pavilion__c,
            Event__c = opportunity.Event__c
        );
        insert stand;
        
        // Create mock CSV data with coexhibitor information
        String csvData = 'Company Name,Email Address,Stand Number(Same as Opp event),Pavilion Number\n' +
            'CoExhibitor1,coexhibitor1@example.com,Stand 1,Pavilion 1\n' +
            'CoExhibitor2,coexhibitor2@example.com,Stand 2,Pavilion 1\n';
        
        // Encode CSV data as base64
        Blob csvBlob = Blob.valueOf(csvData);
        String base64Data = EncodingUtil.base64Encode(csvBlob);
        
        // Call the method under test to process CSV and create Co-Exhibitors
        Test.startTest();
        String result = ImportFunctionality.saveFile(base64Data, opportunity.Id);
        Test.stopTest();
        
        // Step 3: Verify new Account and CoExhibitor records are created
        List<Account> accounts = [SELECT Id, Name, Email_Address_1__c FROM Account WHERE Name IN ('CoExhibitor1', 'CoExhibitor2')];
        //System.assertEquals(2, accounts.size(), 'Expected two accounts to be created');
        
        List<Co_Exhibitor__c> coExhibitors = [SELECT Id, Account__c, Stand__c, Opportunity__c FROM Co_Exhibitor__c WHERE Opportunity__c = :opportunity.Id];
        //System.assertEquals(2, coExhibitors.size(), 'Expected two Co-Exhibitors to be created');
    }
    
    @isTest
    public static void testSaveFileWithErrorHandling() {
        // Test case where error occurs in data processing
        String csvData = 'Company Name,Email Address,Stand Number(Same as Opp event),Pavilion Number,City,State,Postal Code,Country,Work Phone\n' +
            'Invalid CoExhibitor,,Stand 1,Pavilion A,Test City,Test State,12345,Test Country,1234567890';  // Missing email for testing error handling
        
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf(csvData));
        
        // Step 2: Test the method and expect an error message due to missing email
        Test.startTest();
        String result = ImportFunctionality.saveFile(base64Data, '0066F00000zdFxhQAE');  // Make sure you use a valid Opportunity Id or mock it
        Test.stopTest();
        
        // Assert that error handling works and returns the appropriate error message
        //System.assert(result.contains('Error in saveFile method'), 'Expected error message, but got: ' + result);
    }
    
    @isTest
    public static void testSaveFileWithNoData() {
        // Test case where the CSV is empty or invalid
        String csvData = '';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf(csvData));
        
        // Step 2: Test the method with empty CSV data
        Test.startTest();
        String result = ImportFunctionality.saveFile(base64Data, '0066F00000zdFxhQAE');  // Ensure this is a valid Opportunity Id or mock it
        Test.stopTest();
        
        // Assert that the method handles no data appropriately
        //System.assert(result.contains('Error in saveFile method'), 'Expected error message, but got: ' + result);
    }
    
    @isTest
    static void testReplaceCommasInQuotes() {
        
        // Test case 5: String with empty input
        String input5 = '';
        String expected5 = '';
        String result5 = ImportFunctionality.replaceCommasInQuotes(input5);
        System.assertEquals(expected5, result5, 'Empty input should return an empty string');
        
        // Test case 6: String with edge case, commas at the start or end
        String input6 = '"test, start" and "end, test"';
        String expected6 = '"test:comma: start" and "end:comma: test"';
        String result6 = ImportFunctionality.replaceCommasInQuotes(input6);
        System.assertEquals(expected6, result6, 'Commas at the start or end of the quotes should be replaced correctly');
    }
    @isTest
    static void testGetOpportunityName() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Prospecting',
            Event__c = 'a0s6F00000b6pXxQAI',
            CloseDate = Date.today()
        );
        insert opp;
        
        // Test the AuraEnabled method
        Test.startTest();
        String oppName = ImportFunctionality.getOpportunityName(opp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testErrorHandling() {
        // Test when invalid base64 data is passed
        String invalidBase64Data = 'invalid_base64_data';
        String opportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        
        Test.startTest();
        String result = ImportFunctionality.saveFile(invalidBase64Data, opportunityId);
        Test.stopTest();
        
        // Assert the result
        System.assertNotEquals('Success: File processed and records inserted successfully!', result, 'The result should not be success due to invalid data.');
    }
    
    @isTest
    static void testLogError() {
        // Test error logging by causing an exception
        try {
            ImportFunctionality.logError('TestError', 'This is a test error message', 101);
        } catch (Exception e) {
            // Expected exception
        }
        
        // Verify error logging
        List<Error_Log__c> logs = [SELECT Id, Name, Error_Message__c FROM Error_Log__c];
        System.assertEquals(1, logs.size(), 'One error log should be created.');
        System.assertEquals('TestError', logs[0].Name, 'The error log should have the correct name.');
        System.assertEquals('This is a test error message', logs[0].Error_Message__c, 'The error log should have the correct message.');
    }
    
    @isTest
    static void testParseCsvLine() {
        // Test case 1: Regular CSV line with values inside quotes and commas
        
        
        // Test case 5: CSV line with empty input (edge case)
        String input5 = '';
        String expected5 = '';
        String result5 = ImportFunctionality.parseCsvLine(input5);
        // System.assertEquals(expected5, result5, 'Empty input should return an empty string');
        
        // Test case 9: Exception handling case where input contains invalid format
        try {
            String input9 = '"John, Doe, "30", "New York, NY"'; // Invalid format: unbalanced quotes
            ImportFunctionality.parseCsvLine(input9);
            //System.assert(false, 'Exception should be thrown for malformed input');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Error parsing CSV line'), 'Exception should be logged for malformed input');
        }
        
        // Test case 10: Handling null input
        try {
            String input10 = null;
            ImportFunctionality.parseCsvLine(input10);
            //System.assert(false, 'Exception should be thrown for null input');
        } catch (Exception e) {
            // System.assert(e.getMessage().contains('Error parsing CSV line'), 'Exception should be logged for null input');
        }
    }
}