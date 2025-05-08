public class ImportFunctionality {
    @AuraEnabled
    public static String saveFile(String base64Data, String OpportunityId) {
        try {
           // System.debug(('=== Starting file processing for Opportunity: ' + OpportunityId + ' ===');
            Opportunity opportunity = [SELECT Name, Pavilion__c, Event__c 
                                       FROM Opportunity 
                                       WHERE Id = :OpportunityId LIMIT 1];
           // System.debug(('Fetched Opportunity: ' + opportunity);
            String opportunityName = opportunity.Name;
           // System.debug(('Opportunity Name: ' + opportunityName);
            String EventId = opportunity.Event__c;
           // System.debug(('EventId--->'+EventId);
            
            String data;
            try {
                data = JSON.deserializeUntyped(base64Data).toString();
            } catch (Exception e) {
               // System.debug(('Error decoding base64: ' + e.getMessage());
                logError('Error decoding base64', e.getMessage(),    e.getLineNumber());
                return null;
            }
            
            List<String> csvLines = data.split('\n');
            List<String> cleanedCsvLines = new List<String>();
           // System.debug(('csvLines : ' + csvLines);
            for (String line : csvLines) {
                if (line.trim() != '') {
                    cleanedCsvLines.add(line);
                }
            }
            csvLines = cleanedCsvLines;
            
            if (csvLines.isEmpty()) {
               // System.debug(('No valid data found in CSV.');
                return 'Error: CSV is empty or contains only blank lines.';
            }
            
            List<String> headers = new List<String>();
            for (String header : csvLines[0].split(',')) {
                headers.add(header.trim());
            }
           // System.debug(('Formatted CSV Headers: ' + String.join(headers, ', '));
            
            Set<String> requiredHeaders = new Set<String>{
                'First Name', 'Last Name', 'Company Name', 'Email Address',
                    'Customer Coordinator Email', 'Stand Number', 'Address Line 1' ,
                    'Exhibiting As', 'Pavilion Number', 'Work Phone', 'City', 
                    'State', 'Postal Code', 'Country', 'ABN'
            };
            
            List<String> missingHeaders = new List<String>();
            for (String requiredHeader : requiredHeaders) {
                if (!headers.contains(requiredHeader)) {
                    missingHeaders.add(requiredHeader);
                   // System.debug(('Missing required header: ' + requiredHeader);
                }
            }

            if (!missingHeaders.isEmpty()) {
                String errorMessage = 'Error: The uploaded CSV is missing the following required columns:\n' 
                                        + String.join(missingHeaders, '\n') 
                                        + '\nPlease ensure your CSV includes all of these columns:\n'
                                        + String.join(requiredHeaders, '\n');
               // System.debug((errorMessage);
                return errorMessage;
            }
    
           // System.debug(('All required headers are present. Proceeding with processing...');
            
            List<Account> newAccounts = new List<Account>();
            List<Contact> newContacts = new List<Contact>();
            List<Co_Exhibitor__c> newCoExhibitors = new List<Co_Exhibitor__c>();
            List<Trading_As__c> tradingExhibitingLst = new List<Trading_As__c>();
            
            Map<String, Account> existingAccounts = new Map<String, Account>();
            Map<String, Account> newcreatedAccounts = new Map<String, Account>();
            Map<String, Stand__c> existingStands = new Map<String, Stand__c>();
            Map<String, Contact> existingContacts = new Map<String, Contact>();
            Map<String, Contact> newcreatedContacts = new Map<String, Contact>();
            Map<String, Contact> existingContactswithAccountId = new Map<String, Contact>();
            
            Set<String> standNames = new Set<String>();
            Set<String> accNames = new Set<String>();
            Set<String> accEmails = new Set<String>();
            Set<String> pavilionNumbers = new Set<String>();
            Set<String> foundStandNames = new Set<String>();
            Set<String> confirstNames = new Set<String>();
            Set<String> conLastNames = new Set<String>();
            Set<String> customerCoordinatorEmails = new Set<String>();

            for (Integer i = 1; i < csvLines.size(); i++) {
                String processedLine = replaceCommasInQuotes(csvLines[i]);
                // System.debug(('Processed CSV Line: ' + processedLine);
                
                List<String> rowValues = processedLine.split(',');
                if (rowValues.isEmpty() || String.isBlank(rowValues[0].trim())) continue;
                String firstName = 
                    rowValues[headers.indexOf('First Name')].trim().replace(':comma:', ',');
                String lastName = 
                    rowValues[headers.indexOf('Last Name')].trim().replace(':comma:', ',');
                String coExhibitorName = 
                    rowValues[headers.indexOf('Company Name')].trim().replace(':comma:', ',').replace('"','');
                String email = 
                    rowValues[headers.indexOf('Email Address')].trim().replace(':comma:', ',');
                String customerCoordinatorEmail = 
                    rowValues[headers.indexOf('Customer Coordinator Email')].trim().replace(':comma:', ',');
                String standName = 
                    rowValues[headers.indexOf('Stand Number')].trim().replace(':comma:', ',');
                String pavilionNumber = 
                    rowValues[headers.indexOf('Pavilion Number')].trim().replace(':comma:', ',');
                String country = 
                    rowValues[headers.indexOf('Country')].trim().replace(':comma:', ',').replace('"','').toLowerCase();
                String ABNNumber = 
                    rowValues[headers.indexOf('ABN')].trim().replace(':comma:', ',').replace('"','').toLowerCase();

                if (firstName == null && lastName == null && coExhibitorName == null && 
                    email == null && standName == null && pavilionNumber == null) {
                    // System.debug(('Skipping empty row.');
                    continue;
                }

                if(country == 'australia' && (ABNNumber == null || ABNNumber.trim() == '')){
                    return 'Error: ABN Number is required for Austalia Country';
                }
                standNames.add(standName);
                confirstNames.add(firstName);
                conLastNames.add(lastName);
                accNames.add(coExhibitorName);
                accEmails.add(email);
                customerCoordinatorEmails.add(customerCoordinatorEmail);
                if(pavilionNumber != null){
                    pavilionNumbers.add(pavilionNumber);
                }
            }
            
            List<Account> fetchedAccounts = new List<Account>();
            set<Id> accIds = new set<Id>();
            fetchedAccounts = [SELECT Id, Name, Email_Address_1__c, 
                               (SELECT Id,  Name from Trading_As__r) 
                               FROM Account 
                               WHERE Name IN :accNames AND Email_Address_1__c IN :accEmails];

            for (Account acc : fetchedAccounts) {
                String accountKey = (acc.Name + acc.Email_Address_1__c).toLowerCase();
                accIds.add(acc.Id);
                existingAccounts.put(accountKey, acc);
            }
            List<Contact> listOfCont = new List<Contact>();
            listOfCont = [Select Id, FirstName, LastName, Email, AccountId 
                          from Contact 
                          where AccountId IN :accIds AND Email IN:customerCoordinatorEmails 
                          AND (FIrstName IN:confirstNames OR LastName IN:conLastNames)];
            
            for(Contact con: listOfCont){
                String contactKey = (con.FirstName + con.LastName +con.Email).toLowerCase();
                existingContacts.put(contactKey, con);
            }
           // System.debug(('existingContacts-->'+existingContacts);
           // System.debug(('Existing Accounts Found: ' + existingAccounts.keySet());
            List<Stand__c> fetchedStands = new List<Stand__c>();
            String standKey;
            try {
                fetchedStands = [SELECT Id, Name, Pavilion__r.Name, Event__c 
                                 FROM Stand__c 
                                 WHERE Name IN :standNames AND Event__c =: EventId];
                for (Stand__c stand : fetchedStands) {
                    standKey  = (stand.Name  + stand.Event__c).toLowerCase();
                    if(standKey != null){
                        existingStands.put(standKey, stand);
                        foundStandNames.add(stand.Name);
                    }
                }
                standNames.removeAll(foundStandNames); 
               // System.debug(('Existing Stands Found: ' + existingStands.keySet()+'----'+standNames);
                if (!standNames.isEmpty()) {
                    return 
                        'Error: These stands are not found. Please insert new ones and upload the CSV again. Stand Numbers: ' 
                        + String.join(new List<String>(standNames), ', ');
                }
            } catch (Exception e) {
               // System.debug(('Error fetching Stands: ' + e.getMessage());
                logError('Error fetching Stands:  ', e.getMessage(),    e.getLineNumber());
            }

            for (Integer i = 1; i < csvLines.size(); i++) {
                try {
                    String processedLine = replaceCommasInQuotes(csvLines[i]);
                    
                   // System.debug(('Processed CSV Line: ' + processedLine);
                    List<String> rowValues = processedLine.split(',');
                    if (rowValues.isEmpty() || String.isBlank(rowValues[0].trim())) continue;
                    String coExhibitorName = 
                        rowValues[headers.indexOf('Company Name')].trim().replace(':comma:', ',').replace('"','');
                    String email = 
                        rowValues[headers.indexOf('Email Address')].trim().replace(':comma:', ',');
                    String city = 
                        rowValues[headers.indexOf('City')].trim().replace(':comma:', ',');
                    String state = 
                        rowValues[headers.indexOf('State')].trim().replace(':comma:', ',');
                    String postalCode = 
                        rowValues[headers.indexOf('Postal Code')].trim().replace(':comma:', ',');
                    String country = 
                        rowValues[headers.indexOf('Country')].trim().replace(':comma:', ',');
                    String phone = 
                        rowValues[headers.indexOf('Work Phone')].trim().replace(':comma:', ',');
                    String billingStreet = 
                        rowValues[headers.indexOf('Address Line 1')].trim().replace(':comma:', ',');
                    String tradingAs = 
                        rowValues[headers.indexOf('Exhibiting As')].trim().replace(':comma:', ',').replace('"','');
                    String ABNNumber = 
                        rowValues[headers.indexOf('ABN')].trim().replace(':comma:', ',').replace('"','').toLowerCase();

                    String tradingAsAssign = '';
                    
                    if (coExhibitorName != tradingAs) {
                        tradingAsAssign = tradingAs;
                    }
                    String accountKey = (coExhibitorName + email).toLowerCase();
                    Account account;

                    if (existingAccounts.containsKey(accountKey)) {
                        account = existingAccounts.get(accountKey);
                    } else if(!newcreatedAccounts.containsKey(accountKey)){
                        account = new Account(
                            Name = coExhibitorName,
                            Email_Address_1__c = email,
                            BillingCity = city,
                            BillingState = state,
                            BillingCountry = country,
                            BillingPostalCode = postalCode,
                            BillingStreet = billingStreet,
                            Phone = phone,
                            Trading_Name__c = tradingAsAssign,
                            ABN__c = ABNNumber
                        );
                        newAccounts.add(account);
                       // System.debug(('newAccounts : ' + newAccounts);
                       newcreatedAccounts.put(accountKey, account);
                    }
                } catch (Exception e) {
                   // System.debug(('Error processing CSV line ' + i + ': ' + e.getMessage());
                    logError('Error processing CSV line ' + i, e.getMessage(),   e.getLineNumber());
                    return e.getMessage();
                }
            }
            
            if (!newAccounts.isEmpty()) {
                try {
                    insert newAccounts;
                } catch (Exception e) {
                   // System.debug(('Error inserting new Accounts: ' + e.getMessage());
                    logError('Error inserting new Accounts: ' , e.getMessage(), e.getLineNumber());
                    if (e.getMessage().contains('DUPLICATES_DETECTED')) {
                        return 'Error: It looks like you are creating a duplicate Account.';
                    }
                    return 'Error: ' + e.getMessage();
                }
            }

          /*Commented by Princee
           * 
           *   List<Account> Accounts = [SELECT Id, Name, Email_Address_1__c, 
                                      (SELECT Id,  Name from Trading_As__r) 
                                      FROM Account WHERE Name IN :accNames AND Email_Address_1__c IN :accEmails];

            for (Account acc : Accounts) {
                accIds.add(acc.Id);
                existingAccounts.put((acc.Name + acc.Email_Address_1__c).toLowerCase(), acc);
            }*/

            for (Integer i = 1; i < csvLines.size(); i++) {
                try {
                    String processedLine = replaceCommasInQuotes(csvLines[i]);
                    
                   // System.debug(('Processed CSV Line: ' + processedLine);
                    List<String> rowValues = processedLine.split(',');
                    if (rowValues.isEmpty() || String.isBlank(rowValues[0].trim())) continue;
                    String firstName = 
                        rowValues[headers.indexOf('First Name')].trim().replace(':comma:', ',');
                    String lastName = 
                        rowValues[headers.indexOf('Last Name')].trim().replace(':comma:', ',');
                    String coExhibitorName = 
                        rowValues[headers.indexOf('Company Name')].trim().replace(':comma:', ',').replace('"','');
                    System.debug('check accountName::'+coExhibitorName);
                    String email = 
                        rowValues[headers.indexOf('Email Address')].trim().replace(':comma:', ',');
                    String customerCoordinatorEmail = 
                        rowValues[headers.indexOf('Customer Coordinator Email')].trim().replace(':comma:', ',');
                    String standName = 
                        rowValues[headers.indexOf('Stand Number')].trim().replace(':comma:', ',');
                    String pavilionNumber = 
                        rowValues[headers.indexOf('Pavilion Number')].trim().replace(':comma:', ',');
                    String city = 
                        rowValues[headers.indexOf('City')].trim().replace(':comma:', ',');
                    String state = 
                        rowValues[headers.indexOf('State')].trim().replace(':comma:', ',');
                    String postalCode = 
                        rowValues[headers.indexOf('Postal Code')].trim().replace(':comma:', ',');
                    String country = 
                        rowValues[headers.indexOf('Country')].trim().replace(':comma:', ',');
                    String phone = 
                        rowValues[headers.indexOf('Work Phone')].trim().replace(':comma:', ',');
                    String billingStreet = 
                        rowValues[headers.indexOf('Address Line 1')].trim().replace(':comma:', ',');
                    String tradingAs = 
                        rowValues[headers.indexOf('Exhibiting As')].trim().replace(':comma:', ',').replace('"','');
                    String accountKey = (coExhibitorName + email).toLowerCase();
                    System.debug('accountKey:' + accountKey);

                    Account account = existingAccounts.get(accountKey);
                    Contact contact;
                    String contactKey = (firstName + lastName + customerCoordinatorEmail).toLowerCase();

                    // System.debug(('contactKey:' + contactKey);
                    if(existingContacts.containsKey(contactKey)){
                        contact = existingContacts.get(contactKey);
                    }else if(!newcreatedContacts.containsKey(contactKey)){
                        contact = new Contact(
                            FirstName = firstName,
                            LastName = lastName,
                            Email = customerCoordinatorEmail,
                            Phone = phone,
                            AccountId = account.Id
                        );
                        newContacts.add(contact);
                        newcreatedContacts.put(contactKey, contact);
                    }
                } catch (Exception e) {
                   // System.debug(('Error processing CSV line ' + i + ': ' + e.getMessage());
                    logError('Error processing CSV line ' + i, e.getMessage(),   e.getLineNumber());
                    return e.getMessage();
                }
            }

            // System.debug(('newAccounts : ' + newAccounts);
            if(!newContacts.isEmpty()){
                try {
                    insert newContacts;
                } catch (Exception e) {
                    logError('Error inserting new Contacts: ' , e.getMessage(), e.getLineNumber());
                    return e.getMessage();
                }
            }
            
            List<Contact> contacts = [Select Id, FirstName, LastName, Email, AccountId 
                                      from Contact 
                                      where AccountId IN :accIds AND Email IN:customerCoordinatorEmails 
                                      AND (FIrstName IN:confirstNames OR LastName IN:conLastNames)];

            for (Contact con : contacts) {
                existingContacts.put((con.FirstName + con.LastName + con.Email).toLowerCase(), con);
                existingContactswithAccountId.put((con.FirstName + con.LastName + con.Email+ con.AccountId).toLowerCase(), con);
            }

            for (Integer i = 1; i < csvLines.size(); i++) {
                try {
                    String processedLine = replaceCommasInQuotes(csvLines[i]);
                   // System.debug(('Processed CSV Line: ' + processedLine);
                    List<String> rowValues = processedLine.split(',');
                    if (rowValues.isEmpty() || String.isBlank(rowValues[0].trim())) continue;
                    
                    String firstName = 
                        rowValues[headers.indexOf('First Name')].trim().replace(':comma:', ',');
                    String lastName = 
                        rowValues[headers.indexOf('Last Name')].trim().replace(':comma:', ',');
                    String coExhibitorName = 
                        rowValues[headers.indexOf('Company Name')].trim().replace(':comma:', ',').replace('"','');
                    String exhibitingAs = 
                        rowValues[headers.indexOf('Exhibiting As')].trim().replace(':comma:', ',').replace('"','');
                    String email = 
                        rowValues[headers.indexOf('Email Address')].trim().replace(':comma:', ',');
                    String customerCoordinatorEmail = 
                        rowValues[headers.indexOf('Customer Coordinator Email')].trim().replace(':comma:', ',');
                    String standName = 
                        rowValues[headers.indexOf('Stand Number')].trim().replace(':comma:', ',');
                    String pavilionNumber = 
                        rowValues[headers.indexOf('Pavilion Number')].trim().replace(':comma:', ',');
                    
                    Account account = existingAccounts.get((coExhibitorName + email).toLowerCase());
                    Stand__c stand = existingStands.get((standName + opportunity.Event__c).toLowerCase());
                    Contact contact = 
                        existingContacts.get((firstName + lastName + customerCoordinatorEmail).toLowerCase());

                    String accKey = (coExhibitorName + email).toLowerCase();
                    System.debug('accKey>>'+accKey);
                    
                    Trading_As__c trading;
                    Boolean isExistingTradingFound = false;
                    
                    if (account != null && account.Trading_As__r != null) {
                        for (Trading_As__c existingTrading : account.Trading_As__r) {
                            if (existingTrading != null && existingTrading.Name == exhibitingAs) { 
                                trading = new Trading_As__c();
                                trading.Id = existingTrading.Id; 
                                isExistingTradingFound = true;
                               System.debug('Existing trading record found: ' + trading.Id);
                            }
                        }
                    }
                    
                    if (!isExistingTradingFound) {
                        trading = new Trading_As__c();
                        if (account != null) {
                            trading.Account__c = account.Id; // Account Lookup Field
                        }
                        trading.Name = exhibitingAs;  
                        tradingExhibitingLst.add(trading);
                    }
                    
                } catch (Exception e) {
                    // System.debug(('Error processing Co-Exhibitor data for line ' + i + ': ' + e.getMessage());
                     logError('Error processing Co-Exhibitor data for line' , e.getMessage(),   e.getLineNumber());
                     return e.getMessage();
                }
            }

            if (!tradingExhibitingLst.isEmpty()) {
                try {
                    insert tradingExhibitingLst;
                } catch (Exception e) {
                   // System.debug(('Error inserting Co-Exhibitor As records: ' + e.getMessage());
                    logError('Error inserting Exhibiting As records:' , e.getMessage(), e.getLineNumber());
                    return 'Error inserting Exhibiting As records';
                }
            }

            for (Integer i = 1; i < csvLines.size(); i++) {
                try {
                    String processedLine = replaceCommasInQuotes(csvLines[i]);
                   // System.debug(('Processed CSV Line: ' + processedLine);
                    List<String> rowValues = processedLine.split(',');
                    if (rowValues.isEmpty() || String.isBlank(rowValues[0].trim())) continue;
                    
                    String firstName = 
                        rowValues[headers.indexOf('First Name')].trim().replace(':comma:', ',');
                    String lastName = 
                        rowValues[headers.indexOf('Last Name')].trim().replace(':comma:', ',');
                    String coExhibitorName = 
                        rowValues[headers.indexOf('Company Name')].trim().replace(':comma:', ',').replace('"','');
                    String exhibitingAs = 
                        rowValues[headers.indexOf('Exhibiting As')].trim().replace(':comma:', ',').replace('"','');
                    String email = 
                        rowValues[headers.indexOf('Email Address')].trim().replace(':comma:', ',');
                    String customerCoordinatorEmail = 
                        rowValues[headers.indexOf('Customer Coordinator Email')].trim().replace(':comma:', ',');
                    String standName = 
                        rowValues[headers.indexOf('Stand Number')].trim().replace(':comma:', ',');
                    String pavilionNumber = 
                        rowValues[headers.indexOf('Pavilion Number')].trim().replace(':comma:', ',');
                    
                    Account account = existingAccounts.get((coExhibitorName + email).toLowerCase());
                    Stand__c stand = existingStands.get((standName + opportunity.Event__c).toLowerCase());
                    Contact contact = 
                        existingContactswithAccountId.get((firstName + lastName + customerCoordinatorEmail + account.Id).toLowerCase());

                    String accKey = (coExhibitorName + email).toLowerCase();
                    System.debug('accKey>>'+accKey);

                    Trading_As__c trading;
                    
                    if (account != null && account.Trading_As__r != null) {
                        for (Trading_As__c existingTrading : account.Trading_As__r) {
                            if (existingTrading != null && existingTrading.Name == exhibitingAs) { 
                                trading = new Trading_As__c();
                                trading.Id = existingTrading.Id; 
                            }
                        }
                    }

                    if (account != null && stand != null) {
                        Co_Exhibitor__c coExhibitor = new Co_Exhibitor__c(
                            Exhibiting_As__c = trading.Id,
                            Stand__c = stand.Id,
                            Account__c = account.Id,
                            Opportunity__c = OpportunityId,
                            Event__c = opportunity.Event__c,
                            Customer_Coordinator__c = contact.Id
                        );

                        newCoExhibitors.add(coExhibitor);
                    }
                    
                } catch (Exception e) {
                   // System.debug(('Error processing Co-Exhibitor data for line ' + i + ': ' + e.getMessage());
                    logError('Error processing Co-Exhibitor data for line' , e.getMessage(),   e.getLineNumber());
                    return e.getMessage();
                }
            }

            if (!newCoExhibitors.isEmpty()) {
                try {
                    insert newCoExhibitors;
                } catch (Exception e) {
                   // System.debug(('Error inserting Co-Exhibitors: ' + e.getMessage());
                    logError('Error inserting Co-Exhibitor records:' , e.getMessage(),  e.getLineNumber());
                    return e.getMessage();
                }
                
            }    
           // System.debug(('newCoExhibitors : ' + newCoExhibitors + '::size--'+newCoExhibitors.size());
            return 'Upload Successful';
        } catch (Exception e) {
           // System.debug(('Error in saveFile method: ' + e.getMessage());
            logError('Error in saveFile method:' , e.getMessage(),   e.getLineNumber());
            return 'Upload Failed';
        }
    }
    
    public static String parseCsvLine(String csvLine) {
        try {
            List<String> result = new List<String>();
            String regex = '"([^"]*)"|([^,]+)';
            Matcher matcher = Pattern.compile(regex).matcher(csvLine);
            
            while (matcher.find()) {
                if (matcher.group(1) != null) {
                    // Remove extra quotes from values enclosed in quotes
                    result.add(matcher.group(1).trim()); 
                } else {
                    result.add(matcher.group(2).trim());
                }
            }
            
            return String.join(result, ',');
        } catch (Exception e) {
           // System.debug(('Error parsing CSV line: ' + e.getMessage());
            logError('Error parsing CSV line:', e.getMessage(), e.getLineNumber());
            return 'Error parsing CSV line: ' + e.getMessage();
        }
    }
    
    public static String replaceCommasInQuotes(String input) {
        try {
            String regex = '"(.*?)"'; // Match anything inside double quotes
            Matcher matcher = Pattern.compile(regex).matcher(input);
            while (matcher.find()) {
                String original = matcher.group(0); // The full match including quotes
                String modified = original.replace(',', ':comma:'); // Replace commas inside
                input = input.replace(original, modified); // Replace in the input string
            }
           // System.debug(('input--->'+input);
            return input;
        } catch (Exception e) {
           // System.debug(('Error replacing commas in quotes: ' + e.getMessage());
            logError('Error replacing commas in quotes: ' , e.getMessage(),    e.getLineNumber());
            return 'Error replacing commas in quotes: ' + e.getMessage();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getOpportunityName(String opportunityId) {
       // System.debug(('oppId-->'+opportunityId);
        try {
            Opportunity opp = [SELECT Name FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            return opp.Name; // Return the Opportunity Name
        } catch (Exception e) {
            logError('Error fetching Opportunity Name: ' , e.getMessage(),    e.getLineNumber());
            return 'Error fetching Opportunity Name: ' + e.getMessage();
        }
    }
    public static void logError(String errorName, String errorMessage, Integer lineNumber) {
        try {
            Error_Log__c errorLog = new Error_Log__c(
                Name = errorName,
                Error_Message__c = errorMessage,
                Line_Number__c = lineNumber
            );
            insert errorLog;
        } catch (Exception e) {
           // System.debug(('Error logging the error: ' + e.getMessage());
        }
    }
}