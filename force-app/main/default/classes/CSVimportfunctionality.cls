public class CSVimportfunctionality{
    @AuraEnabled(cacheable=true)
    public static String getOpportunityName(String opportunityId) {
        try {
            Opportunity opp = [SELECT Name FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            return opp.Name; // Return the Opportunity Name
        } catch (Exception e) {
            logError('Error fetching Opportunity Name: ' , e.getMessage(),    e.getLineNumber());
            return 'Error fetching Opportunity Name: ' + e.getMessage();
        }
    }
    
    @AuraEnabled
    public static String saveFile(String base64Data, String OpportunityId) {
        Savepoint sp = Database.setSavepoint();
        try{ 
            Opportunity opportunity = [SELECT Name, Pavilion__c, Event__c 
                                       FROM Opportunity 
                                       WHERE Id = :OpportunityId LIMIT 1];
            String opportunityName = opportunity.Name;
            String EventId = opportunity.Event__c;
            
            String data;
            //Boolean useSpaceForMalformedJoin = true;
            try {
                data = JSON.deserializeUntyped(base64Data).toString();
            } catch (Exception e) {
                Database.rollback(sp); 
                logError('Error decoding base64', e.getMessage(),    e.getLineNumber());
                System.debug('e.getMessage() = ' + e.getMessage());
                return null;
            }
            List<String> lines = data.replaceAll('\r\n', '\n').split('\n');
            System.debug('lines---->'+JSON.serializePretty(lines));
            List<String> formattedLines = new List<String>();
            
            String tempLine = '';
            Boolean isMalformed = false;
            
            for (Integer i = 0; i < lines.size(); i++) {
                String line = lines[i];
                if (i == 0) {
                    // Skip header row, add it directly
                    formattedLines.add(line);
                    continue;
                }
                if (line.countMatches(',') < 12) { // Assuming there should be 13 commas per valid row
                    tempLine += (tempLine == '' ? '' : ' ') + line;
                    isMalformed = true;
                } else {
                    if (isMalformed) {
                        tempLine += '\n' + line;
                        formattedLines.add(tempLine);
                        tempLine = '';
                        isMalformed = false;
                    }
                    formattedLines.add(line);
                }
            }
            
            // Add any remaining malformed data
            if (tempLine != '') {
                formattedLines.add(tempLine);
            }
            
            String finaldata = String.join(formattedLines, '\n');
            List<String> csvLines = finaldata.replaceAll('\r\n', '\n').split('\n');
            List<String> cleanedCsvLines = new List<String>();
            for (String line : csvLines) {
                if (line.trim() != '') {
                    cleanedCsvLines.add(line);
                }
            }
            csvLines = cleanedCsvLines;
            if (csvLines.isEmpty()) {
                return 'Error: CSV is empty or contains only blank lines.';
            }
            
            List<String> headers = new List<String>();
            for (String header : csvLines[0].split(',')) {
                headers.add(header.trim().replace('"',''));
            }
            Set<String> requiredHeaders = new Set<String>{
                'First Name', 
                'Last Name', 
                'Email Address', 
                'Customer Coordinator',
                'Company Name' , 
                'Exhibiting As', 
                'Address Line 1',
                'City', 
                'State', 
                'Postal Code', 
                'Country', 
                'Work Phone',    
                'Stand Number'
            };
                        
            List<String> missingHeaders = new List<String>();
            for (String requiredHeader : requiredHeaders) {
                if (!headers.contains(requiredHeader)) {
                    missingHeaders.add(requiredHeader);
                }
            }
            
            if (!missingHeaders.isEmpty()) {
                String errorMessage = 'Error: The uploaded CSV is missing the following required columns:\n' 
                    + String.join(missingHeaders, '\n') 
                    + '\nPlease ensure your CSV includes all of these columns:\n'
                    + String.join(requiredHeaders, '\n');
                return errorMessage;
            }
            
            
            List<Account> newAccounts = new List<Account>();
            List<Contact> newContacts = new List<Contact>();
            List<Trading_As__c> newTradings = new List<Trading_As__c>();
            
            Map<String, Account> existingAccounts = new Map<String, Account>();
            Map<String, Account> newcreatedAccounts = new Map<String, Account>();
            
            Set<String> standNames = new Set<String>();
            Set<String> accNames = new Set<String>();
            
            Map<String, Account> finalAccountMap = new Map<String, Account>();
            Map<String, Contact> finalContactMap = new Map<String, Contact>();
            Map<String, Trading_As__c> finalTradingMap = new  Map<String, Trading_As__c>();
            
            for (Integer i = 1; i < csvLines.size(); i++) {
                String processedLine = replaceCommasInQuotes(csvLines[i]);
                List<String> rowValues = processedLine.split(',');
                if (rowValues.isEmpty() || String.isBlank(rowValues[0].trim())) continue;
                String firstName = 
                    rowValues[headers.indexOf('First Name')].trim().replace(':comma:', ',').replace('"','');
                String lastName = 
                    rowValues[headers.indexOf('Last Name')].trim().replace(':comma:', ',').replace('"','');
                String coExhibitorName = 
                    rowValues[headers.indexOf('Company Name')].trim().replace(':comma:', ',').replace('"','');

                String email = 
                    rowValues[headers.indexOf('Email Address')].trim().replace(':comma:', ',').replace('"','');
                String customerCoordinator = 
                    rowValues[headers.indexOf('Customer Coordinator')].trim().replace(':comma:', ',').replace('"','');
                String standName =  rowValues[headers.indexOf('Stand Number')].trim().replace(':comma:', ',').replace('"','');
                String country = 
                    rowValues[headers.indexOf('Country')].trim().replace(':comma:', ',').replace('"','');
                
                if (firstName == null && lastName == null && coExhibitorName == null && 
                    email == null && standName == null) {
                        continue;
                    }
                
                standNames.add(standName);
                if (accNames.contains(coExhibitorName)) {
                    return 
                        'Error: A duplicate company name was found. Please ensure each company name in the CSV is unique.';
                }              
                else
                    accNames.add(coExhibitorName);
            }
            
            List<Stand__c> fetchedStands = new List<Stand__c>();
            List<Stand__c> newStandsToInsert = new List<Stand__c>();
            Map<String, Stand__c> existingStands = new Map<String, Stand__c>();
            String standKey;
            fetchedStands = [SELECT Id, Name, Pavilion__r.Name, Event__c 
                                FROM Stand__c 
                                WHERE Name IN :standNames AND Event__c =: EventId];
            for (Stand__c stand : fetchedStands) {
                standKey  = (stand.Name  + stand.Event__c).toLowerCase();
                if(standKey != null){
                    existingStands.put(standKey, stand);
                }
            }

            for (String standName : standNames) {
                String key = (standName + EventId).toLowerCase();
                if (!existingStands.containsKey(key)) {
                    Stand__c newStand = new Stand__c(
                        Name = standName,
                        Event__c = EventId
                    );
                    newStandsToInsert.add(newStand);
                }
            }
            
            if(!newStandsToInsert.isEmpty()){
                try {
                    System.debug('newStandsToInsert--->'+newStandsToInsert);
                    insert newStandsToInsert;
                    for (Stand__c stand : newStandsToInsert) {
                        String newKey = (stand.Name + stand.Event__c).toLowerCase();
                        existingStands.put(newKey, stand);
                    }
                } catch (DmlException e) {
                    Database.rollback(sp); 
                    logError('Error inserting newStands : ' , e.getMessage(), e.getLineNumber());
                    return 'Error: ' + e.getMessage();
                }
            }

            List<Account> fetchedAccounts = new List<Account>();
            set<Id> accIds = new set<Id>();
            fetchedAccounts = [SELECT Id, Name, Email_Address_1__c, BillingStreet,BillingCity,BillingState,BillingCountry,
                               BillingPostalCode,
                               (SELECT Id,  Name,Account__r.id from Trading_As__r),
                               (Select Id, FirstName, LastName, Email, AccountId from Contacts) 
                               FROM Account 
                               WHERE Name IN :accNames];
            
            for (Account acc : fetchedAccounts) {
                String accountKey = acc.Name.toLowerCase();
                accIds.add(acc.Id);
                existingAccounts.put(accountKey, acc);
            }
            
            Map<String,Contact> dummyNewContactMap = new Map<String,Contact>();
            Map<String,Trading_As__c> dummyNewTradingAsMap = new Map<String,Trading_As__c>();
            
            List<Account> lstExistingAccUpdate = new List<Account>();
            Map<String,Account> mapExistingAccUpdate = new Map<String,Account>();
            
            for (Integer i = 1; i < csvLines.size(); i++) {
                try {
                    String processedLine = replaceCommasInQuotes(csvLines[i]);
                    List<String> rowValues = processedLine.split(',');
                    if (rowValues.isEmpty() || String.isBlank(rowValues[0].trim())) continue;
                    String firstName = 
                        rowValues[headers.indexOf('First Name')].trim().replace(':comma:', ',').replace('"','');
                    String lastName = 
                        rowValues[headers.indexOf('Last Name')].trim().replace(':comma:', ',').replace('"','');
                    String customerCoordinator = 
                        rowValues[headers.indexOf('Customer Coordinator')].trim().replace(':comma:', ',').replace('"','');
                    String exhibitingAs = 
                        rowValues[headers.indexOf('Exhibiting As')].trim().replace(':comma:', ',').replace('"','');                  
                    String coExhibitorName = 
                        rowValues[headers.indexOf('Company Name')].trim().replace(':comma:', ',').replace('"','');
                    String email = 
                        rowValues[headers.indexOf('Email Address')].trim().replace(':comma:', ',').replace('"','');
                    String city = 
                        rowValues[headers.indexOf('City')].trim().replace(':comma:', ',').replace('"','');
                    String state = 
                        rowValues[headers.indexOf('State')].trim().replace(':comma:', ',').replace('"','');
                    String postalCode = 
                        rowValues[headers.indexOf('Postal Code')].trim().replace(':comma:', ',').replace('"','');
                    String country = 
                        rowValues[headers.indexOf('Country')].trim().replace(':comma:', ',').replace('"','');
                    String phone = 
                        rowValues[headers.indexOf('Work Phone')].trim().replace(':comma:', ',').replace('"','');
                    String billingStreet = 
                        rowValues[headers.indexOf('Address Line 1')].trim().replace(':comma:', ',').replace('"','');
                    String tradingAs = 
                        rowValues[headers.indexOf('Exhibiting As')].trim().replace(':comma:', ',').replace('"','');
                    
                    String tradingAsAssign = '';
                    
                    if (coExhibitorName.toLowerCase() != tradingAs.toLowerCase()) {
                        tradingAsAssign = tradingAs;
                    }
                    String accountKey = (coExhibitorName).toLowerCase();
                    Account account;
                    
                    if (existingAccounts.containsKey(accountKey)) {
                        account = existingAccounts.get(accountKey);
                        if (account != null && (
                            String.isBlank(account.BillingStreet) || 
                            String.isBlank(account.BillingCity) || 
                            String.isBlank(account.BillingState) || 
                            String.isBlank(account.BillingCountry) || 
                            String.isBlank(account.BillingPostalCode)
                        )) {
                            // Update only the blank fields
                            if (String.isBlank(account.BillingStreet)) account.BillingStreet = billingStreet;
                            if (String.isBlank(account.BillingCity)) account.BillingCity = city;
                            if (String.isBlank(account.BillingState)) account.BillingState = state;
                            if (String.isBlank(account.BillingCountry)) account.BillingCountry = country;
                            if (String.isBlank(account.BillingPostalCode)) account.BillingPostalCode = postalcode;
                            
                            lstExistingAccUpdate.add(account);
                        }
                        
                        
                        Boolean contactExists = false;
                        Boolean tradingAsExists = false;
                        System.debug(account.Contacts.size() + '  Contact size');
                        for (Contact con : account.Contacts) {
                            if(con.FirstName != null && con.LastName != null && con.Email != null ){
                                if (con.FirstName.toLowerCase() == firstName.toLowerCase() && con.LastName.toLowerCase() == lastName.toLowerCase() && con.Email.toLowerCase() == email.toLowerCase()) {
                                    contactExists = true;
                                    String contactKey = (account.Id + con.FirstName + con.LastName + con.email).toLowerCase();
                                    finalContactMap.put(contactKey, con);
                                    break;
                                }
                            }
                        }
                        if (!contactExists) {
                            newContacts.add(new Contact(
                                FirstName = firstName, 
                                LastName = lastName, 
                                AccountId = account.Id, 
                                Email = email,
                                Phone = phone,
                                MailingStreet = billingStreet,
                                MailingState = state,
                                MailingCity = city,
                                MailingCountry = country,
                                MailingPostalCode = postalCode
                            ));
                        }
                        
                        for (Trading_As__c ta : account.Trading_As__r) {
                            if (ta.Name.toLowerCase() == exhibitingAs.toLowerCase()) {
                                tradingAsExists = true;
                                finalTradingMap.put(account.Id, ta);
                                break;
                            }
                        }
                        if (!tradingAsExists) {
                            newTradings.add(new Trading_As__c(Name = exhibitingAs, Account__c = account.Id));
                        }
                        finalAccountMap.put(accountKey, account);
                    } 
                    
                    else if(!newcreatedAccounts.containsKey(accountKey)){
                        System.debug('In else if-->'+accountKey);
                        account = new Account(
                            Name = coExhibitorName,
                            BillingCity = city,
                            BillingState = state,
                            BillingCountry = country,
                            BillingPostalCode = postalCode,
                            BillingStreet = billingStreet,
                            Phone = phone,
                            Trading_Name__c = tradingAsAssign
                        );
                        newAccounts.add(account);
                        
                        Contact myContact = new Contact(
                            FirstName = firstName,
                            LastName = lastName,
                            Email = email,
                            Phone = phone,
                            MailingStreet = billingStreet,
                            MailingState = state,
                            MailingCity = city,
                            MailingCountry = country,
                            MailingPostalCode = postalCode);
                        dummyNewContactMap.put(accountKey, myContact);
                        
                        Trading_As__c myTradingAs = new Trading_As__c();                    
                        myTradingAs.Name = exhibitingAs;  
                        dummyNewTradingAsMap.put(accountKey, myTradingAs);
                        
                    }
                } catch (Exception e) {
                    Database.rollback(sp); 
                    logError('Error processing CSV line ' + i, e.getMessage(),   e.getLineNumber());
                    return e.getMessage();
                }
            }
            
            if (!lstExistingAccUpdate.isEmpty()) 
            {
                try {
                    update lstExistingAccUpdate;
                    
                } catch (DmlException e) {
                    Database.rollback(sp); 
                    logError('Error inserting new Accounts: ' , e.getMessage(), e.getLineNumber());
                    if (e.getMessage().contains('DUPLICATES_DETECTED')) {
                        return 'Error: It looks like you are creating a duplicate Account.';
                    }
                    return 'Error: ' + e.getMessage();
                }
            }
            if (!newAccounts.isEmpty()){
                try {
                    Database.DMLOptions dml = new Database.DMLOptions(); 
                    dml.DuplicateRuleHeader.AllowSave = true;
                    List<Database.SaveResult> sr = Database.insert(newAccounts, dml);
                    Set<Id> newAccountIds = new Set<Id>();
                    for (Account acc : newAccounts) {
                        newAccountIds.add(acc.Id);
                    }
                    
                    if (!newAccountIds.isEmpty()) {
                        List<Trading_As__c> newTradingAsTobeInserted = [
                            SELECT Id, Name, Account__c 
                            FROM Trading_As__c 
                            WHERE Account__c IN :newAccountIds
                        ];
                        
                        for (Trading_As__c ta : newTradingAsTobeInserted) {
                            finalTradingMap.put(ta.Account__c, ta);
                        }
                    }
                    
                } catch (DmlException e) {
                    Database.rollback(sp); 
                    logError('Error inserting new Accounts: ' , e.getMessage(), e.getLineNumber());
                    if (e.getMessage().contains('DUPLICATES_DETECTED')) {
                        return 'Error: It looks like you are creating a duplicate Account.';
                    }
                    return 'Error: ' + e.getMessage();
                }
            }
            
            List<Contact> newContTobeInserted = new List<Contact>();
            for(Account acc:newAccounts){
                String accountKey = acc.name.toLowerCase();
                finalAccountMap.put(accountKey, acc);  
                Contact con = dummyNewContactMap.get(accountKey);
                con.AccountId = acc.Id;
                newContTobeInserted.add(con);
            }
            
            if (!newContTobeInserted.isEmpty()){
                try {
                    insert newContTobeInserted;
                    
                } catch (DmlException e) {
                    Database.rollback(sp); 
                    logError('Error inserting newContTobeInserted: ' , e.getMessage(), e.getLineNumber());
                    if (e.getMessage().contains('DUPLICATES_DETECTED')) {
                        return 'Error: It looks like you are creating a duplicate Contact.';
                    }
                    return 'Error: ' + e.getMessage();
                }
            }
            for(Contact con: newContTobeInserted){
                String contactKey = (con.AccountId + con.FirstName + con.LastName + con.email).toLowerCase();
                finalContactMap.put(contactKey, con);
            }
            
            if (!newContacts.isEmpty()){
                try {
                    insert newContacts;
                    
                } catch (DmlException e) {
                    Database.rollback(sp); 
                    logError('Error inserting newContacts: ' , e.getMessage(), e.getLineNumber());
                    if (e.getMessage().contains('DUPLICATES_DETECTED')) {
                        return 'Error: It looks like you are creating a duplicate Contact.';
                    }
                    return 'Error: ' + e.getMessage();
                }
            }
            for(Contact con: newContacts){
                String contactKey = (con.AccountId + con.FirstName + con.LastName + con.email).toLowerCase();
                finalContactMap.put(contactKey, con);
            }
            if (!newTradings.isEmpty()){
                try {
                    insert newTradings;
                    
                } catch (DmlException e) {
                    Database.rollback(sp); 
                    logError('Error inserting newTradings : ' , e.getMessage(), e.getLineNumber());
                    if (e.getMessage().contains('DUPLICATES_DETECTED')) {
                        return 'Error: It looks like you are creating a duplicate Exhibing As.';
                    }
                    return 'Error: ' + e.getMessage();
                }
            }       
            for(Trading_As__c ta: newTradings){
                finalTradingMap.put(ta.Account__c, ta);            
            }
            
            List<Co_Exhibitor__c> newCoExhibitors = new List<Co_Exhibitor__c>();
            
            for (Integer i = 1; i < csvLines.size(); i++) {
                try {
                    String processedLine = replaceCommasInQuotes(csvLines[i]);
                    List<String> rowValues = processedLine.split(',');
                    if (rowValues.isEmpty() || String.isBlank(rowValues[0].trim())) continue;
                    
                    String firstName = 
                        rowValues[headers.indexOf('First Name')].trim().replace(':comma:', ',').replace('"','');
                    String lastName = 
                        rowValues[headers.indexOf('Last Name')].trim().replace(':comma:', ',').replace('"','');
                    String coExhibitorName = 
                        rowValues[headers.indexOf('Company Name')].trim().replace(':comma:', ',').replace('"','');
                    String exhibitingAs = 
                        rowValues[headers.indexOf('Exhibiting As')].trim().replace(':comma:', ',').replace('"','');
                    String email = 
                        rowValues[headers.indexOf('Email Address')].trim().replace(':comma:', ',').replace('"','');
                    String customerCoordinator = 
                        rowValues[headers.indexOf('Customer Coordinator')].trim().replace(':comma:', ',').replace('"','');
                    String standName = 
                        rowValues[headers.indexOf('Stand Number')].trim().replace(':comma:', ',').replace('"','');
                    
                    Account account = finalAccountMap.get(coExhibitorName.toLowerCase());
                    Stand__c stand = existingStands.get((standName + opportunity.Event__c).toLowerCase());
                    Contact contact = finalContactMap.get((account.Id + firstName + lastName + email).toLowerCase());
                    Trading_As__c tradingas = finalTradingMap.get((account.Id));
                    if (account != null && stand != null && contact!=null && tradingas!=null) {
                        Co_Exhibitor__c coExhibitor = new Co_Exhibitor__c(
                            Exhibiting_As__c = tradingas.Id,
                            Stand__c = stand.Id,
                            Account__c = account.Id,
                            Opportunity__c = OpportunityId,
                            Event__c = opportunity.Event__c,
                            Customer_Coordinator__c = contact.Id
                        );
                        
                        newCoExhibitors.add(coExhibitor);
                    }
                    else{
                        Database.rollback(sp);
                        return 'Error: Upload Failed';  
                    }
                } catch (Exception e) {
                    Database.rollback(sp); 
                    logError('Error processing Co-Exhibitor data for line' , e.getMessage(),   e.getLineNumber());
                    return e.getMessage();
                }
            }
            
            if (!newCoExhibitors.isEmpty()) {
                try {
                    System.debug('newCoExhibitors-->'+newCoExhibitors);
                    insert newCoExhibitors;
                    return 'Upload Successful';
                } catch (DmlException e) {
                    Database.rollback(sp); 
                    logError('Error inserting Co-Exhibitor records:' , e.getMessage(),  e.getLineNumber());
                    return e.getMessage();
                }
            }  
            return 'Error: Upload Failed';  
        } catch (Exception e) {
            Database.rollback(sp); 
            logError('Error in saveFile method:' , e.getMessage(),   e.getLineNumber());
            return 'Upload Failed';
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
            return input;
        } catch (Exception e) {
            logError('Error replacing commas in quotes: ' , e.getMessage(),    e.getLineNumber());
            return 'Error replacing commas in quotes: ' + e.getMessage();
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
            
        }
    }
}