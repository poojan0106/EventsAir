public class PrinceeImportFunctionality {
    @AuraEnabled
    public static List<Account> saveFile(String base64Data, String OpportunityId) {
        System.debug('start to get Opportunity' + OpportunityId);
        list<Account>lstCCToInsert = new List<Account>();
        Opportunity opppavillion = [SELECT Pavilion__c, Event__c, Event__r.Id  FROM Opportunity WHERE Id = :OpportunityId LIMIT 1];
        
        Event__c oppEvent = opppavillion.Event__r;
        System.debug('oppEvent==>' + oppEvent + 'opppavillion.event' + opppavillion.Event__c);
        
        // Decode the base64 data into CSV data string
        String data;
        try {
            data = JSON.deserializeUntyped(base64Data).toString();
        } catch (Exception e) {
            // Log and handle base64 decode error
            System.debug('Error decoding base64: ' + e.getMessage());
            return null;
        }
        
        List<String> lstCSVLines = data.split('\n');
        System.debug('data==>' + data);
        
        // Define a map to store the column names and their values dynamically
        Map<String, String> csvRowDataMap = new Map<String, String>();
        List<String> headers = new List<String>();  // Declare headers outside the loop
        String key;
        // Initialize maps to store data
        Map<String, String> emailMap = new Map<String, String>();
        Map<String, String> coExhibitorNameMap = new Map<String, String>();
        Map<String, String> standMap = new Map<String, String>();
        
        // Initialize new maps for additional fields
        Map<String, String> cityMap = new Map<String, String>();
        Map<String, String> stateMap = new Map<String, String>();
        Map<String, String> postalCodeMap = new Map<String, String>();
        Map<String, String> countryMap = new Map<String, String>();
        Map<String, String> workPhoneMap = new Map<String, String>();
        Map<String, String> pavilionNumberMap = new Map<String, String>();
        
        
        for (Integer i = 0; i < lstCSVLines.size(); i++) {
            String csvLine = lstCSVLines[i];
            // Split the CSV line into columns
            List<String> columns = csvLine.split(',');
            System.debug('columns=>' + columns);
            
            // Check if it's the first row (header row)
            if (i == 0) {
                headers = columns;  // Store column headers for later use
                // Trim the headers to ensure no extra spaces
                for (Integer j = 0; j < headers.size(); j++) {
                    headers[j] = headers[j].trim();
                }
                System.debug('Headers: ' + headers); // Debug the headers
                continue; // Skip header row in further processing
            }
            
            Boolean isEmptyRow = true;
            
            // Check if the row is empty by verifying each column
            for (String columnValue : columns) {
                if (columnValue != null && columnValue.trim() != '') {
                    isEmptyRow = false; // Found a non-empty column, so it's not an empty row
                    break;
                }
            }
            
            // If the row is empty, stop further processing
            if (isEmptyRow) {
                System.debug('Empty row found, stopping data processing.');
                break; // Stop processing further rows if we encounter an empty row
            }
            
            // Extract values based on headers
            key = columns[0].trim(); // The first column value (key)
            
            // Find the indices of the required columns
            Integer emailIndex = headers.indexOf('Email Address');
            Integer NameIndex = headers.indexOf('Company Name');
            // Integer lastNameIndex = headers.indexOf('Last Name');
            Integer standIndex = headers.indexOf('Stand Number(Same as Opp event)');
            Integer cityIndex = headers.indexOf('City');
            Integer stateIndex = headers.indexOf('State');
            Integer postalCodeIndex = headers.indexOf('Postal Code');
            Integer countryIndex = headers.indexOf('Country');
            Integer workPhoneIndex = headers.indexOf('Work Phone');
            Integer pavilionNumberIndex = headers.indexOf('Pavilion Number');
            
            // Extract email, co-exhibitor name, stand values, and the new fields
            String email = (emailIndex != -1 && emailIndex < columns.size()) ? columns[emailIndex].trim() : '';
            String coExhibitorNameValue = '';
            if (NameIndex != -1 && NameIndex < columns.size()){
                coExhibitorNameValue = columns[NameIndex].trim();
            }
            String stand = (standIndex != -1 && standIndex < columns.size()) ? columns[standIndex].trim() : '';
            
            // Extract new fields
            String city = (cityIndex != -1 && cityIndex < columns.size()) ? columns[cityIndex].trim() : '';
            String state = (stateIndex != -1 && stateIndex < columns.size()) ? columns[stateIndex].trim() : '';
            String postalCode = (postalCodeIndex != -1 && postalCodeIndex < columns.size()) ? columns[postalCodeIndex].trim() : '';
            String country = (countryIndex != -1 && countryIndex < columns.size()) ? columns[countryIndex].trim() : '';
            String workPhone = (workPhoneIndex != -1 && workPhoneIndex < columns.size()) ? columns[workPhoneIndex].trim() : '';
            String pavilionNumber = (pavilionNumberIndex != -1 && pavilionNumberIndex < columns.size()) ? columns[pavilionNumberIndex].trim() : '';
            
            // Populate the maps with the extracted values
            emailMap.put(key, email);
            coExhibitorNameMap.put(key, coExhibitorNameValue);
            standMap.put(key, stand);
            cityMap.put(key, city);
            stateMap.put(key, state);
            postalCodeMap.put(key, postalCode);
            countryMap.put(key, country);
            workPhoneMap.put(key, workPhone);
            pavilionNumberMap.put(key, pavilionNumber);
            
            // Debugging the content of the maps
            
        }
        System.debug('emailMap=>' + emailMap);
        System.debug('coExhibitorNameMap=>' + coExhibitorNameMap);
        System.debug('standMap=>' + standMap);
        System.debug('cityMap=>' + cityMap);
        System.debug('stateMap=>' + stateMap);
        System.debug('postalCodeMap=>' + postalCodeMap);
        System.debug('countryMap=>' + countryMap);
        System.debug('workPhoneMap=>' + workPhoneMap);
        System.debug('pavilionNumberMap=>' + pavilionNumberMap);
        
        List<String>emailList = new List<String>();
        List<String> coExhibitorNameList= new List<String>();
        List<String>standList = new List<String>();
        List<String> cityList = new List<String>();
        List<String> stateList = new List<String>();
        List<String> streetList = new List<String>();
        List<String> postalCodeList = new List<String>();
        List<String> countryList = new List<String>();
        List<String> workPhoneList = new List<String>();
        List<String> pavilionNumberList = new List<String>();
        
        
        
        
        for (String keyemail : emailMap.keySet()) {
            emailList.add(emailMap.get(keyemail));  // Add the email value to the list
        }
        System.debug(emailList);
        // Iterate over the coExhibitorNameMap to populate the coExhibitorNameList
        for (String keyname : coExhibitorNameMap.keySet()) {
            coExhibitorNameList.add(coExhibitorNameMap.get(keyname));  // Add the coExhibitorName value to the list
        }
        
        // Iterate over the standMap to populate the standList
        for (String keystand : standMap.keySet()) {
            standList.add(standMap.get(keystand));  // Add the stand value to the list
        }
        for (String keycity : cityMap.keySet()) {
            cityList.add(cityMap.get(keycity));  // Add the city value to the list
        }
        
        // Populate stateList from stateMap
        for (String keystate : stateMap.keySet()) {
            stateList.add(stateMap.get(keystate));  // Add the state value to the list
        }
        
        // Populate postalCodeList from postalCodeMap
        for (String keypostal : postalCodeMap.keySet()) {
            postalCodeList.add(postalCodeMap.get(keypostal));  // Add the postal code value to the list
        }
        
        // Populate countryList from countryMap
        for (String keycountry : countryMap.keySet()) {
            countryList.add(countryMap.get(keycountry));  // Add the country value to the list
        }
        
        // Populate workPhoneList from workPhoneMap
        for (String keyworkPhone : workPhoneMap.keySet()) {
            workPhoneList.add(workPhoneMap.get(keyworkPhone));  // Add the work phone value to the list
        }
        
        // Populate pavilionNumberList from pavilionNumberMap
        for (String keypavilion : pavilionNumberMap.keySet()) {
            pavilionNumberList.add(pavilionNumberMap.get(keypavilion));  // Add the pavilion number value to the list
        }
        
        List<Account>existingAccount = [SELECT id, NAME, Email_Address_1__c  from Account where Name IN :coExhibitorNameList AND Email_Address_1__c IN :emailList ];
        List<Stand__c> activeStands = [SELECT Id, Name FROM Stand__c WHERE Pavilion__c = :opppavillion.Pavilion__c AND Event__c = :opppavillion.Event__c];
        System.debug('existingAccount==>'+existingAccount);
        List<Account>newAccounts = new List<Account>();
        Map<String, Account> existingAccountMapByName = new Map<String, Account>();
        Map<String, Account> existingAccountMapByEmail = new Map<String, Account>();
        
        for (Account acc : existingAccount) {
            existingAccountMapByName.put(acc.Name, acc);
            existingAccountMapByEmail.put(acc.Email_Address_1__c, acc);
        }
        List<Co_Exhibitor__c> lstCoExhibitorsToInsert = new List<Co_Exhibitor__c>();
        
        for (Integer i = 0; i < emailList.size(); i++) {
            String email = emailList[i];
            String coExhibitorName = coExhibitorNameList[i];
            String stand = standList[i];
            String BillingCity = cityList[i];
            String BillingState = stateList[i];
            String BillingCountry  = CountryList[i];
            String BillingPostalCode = PostalCodeList[i];
            String Phone = workPhoneList[i];
            
            if (existingAccountMapByName.get(coExhibitorName) == null && !existingAccountMapByEmail.containsKey(email)) {
                
                Account newAccount = new Account(
                    Name = coExhibitorName,
                    Email_Address_1__c = email,
                    BillingCity =BillingCity,
                    BillingState = BillingState,
                    BillingCountry = BillingCountry,
                    BillingPostalCode =BillingPostalCode,
                    BillingStreet = 'test',
                    Phone = Phone
                );
                newAccounts.add(newAccount);
                System.debug('Creating new account: ' + newAccount);
            } else {
                
                // If an existing account is found, you can handle this case (e.g., update or skip)
                System.debug('Account found for: ' + coExhibitorName);
                Co_Exhibitor__c coExhibitor = new Co_Exhibitor__c();
                coExhibitor.Account__c = existingAccount[0].Id;
                coExhibitor.stand__c = activeStands[0].Id;
                coExhibitor.Opportunity__c = OpportunityId;
                coExhibitor.Event__c = opppavillion.Event__c;
                lstCoExhibitorsToInsert.add(coExhibitor);
            }
        }
        
        // Bulk insert new accounts if there are any
        if (!newAccounts.isEmpty()) {
            insert newAccounts;
            System.debug('New accounts created: ' + newAccounts);
            
        }
        
        
        // Check if the Opportunity has a Pavilion, if not create a new Pavilion
        Set<String> pavilionsToCreate = new Set<String>();
        if (String.isEmpty(opppavillion.Pavilion__c)) {
            // Add pavilion names to the set that need to be created
            pavilionsToCreate.addAll(pavilionNumberMap.values());
        }
        // Bulk insert new pavilions if any
        List<Pavilion__c> newPavilions = new List<Pavilion__c>();
        for (String pavilionName : pavilionsToCreate) {
            Pavilion__c newPavilion = new Pavilion__c(Name = pavilionName);
            newPavilions.add(newPavilion);
            System.debug('Adding new Pavilion to be created: ' + newPavilion);
        }
        if (!newPavilions.isEmpty()) {
            insert newPavilions;
            System.debug('New pavilions created: ' + newPavilions);
        }
        
        List<Opportunity>oppoUpdation = [select Id,Name from Opportunity where id= :OpportunityId];
        List<Opportunity>opportunityListUpdate = new List<Opportunity>();
        for(Opportunity opp :oppoUpdation){
            opp.Pavilion__c = newPavilions[0].Id;
            opportunityListUpdate.add(opp);
        }
        /*(!opportunityListUpdate.isEmpty()){
update opportunityListUpdate;
}*/
        // update opportunityListUpdate;
        // Create Co-Exhibitors and assign correct Pavilion
        //List<Co_Exhibitor__c> lstCoExhibitorsToInsert = new List<Co_Exhibitor__c>();
        
        // Store existing pavilions for assignment
        Map<String, Pavilion__c> existingPavilionsMap = new Map<String, Pavilion__c>();
        
        // If Pavilion exists on Opportunity, use that
        if (!String.isEmpty(opppavillion.Pavilion__c)) {
            existingPavilionsMap.put(opppavillion.Pavilion__c, [SELECT Id, Name FROM Pavilion__c WHERE Id = :opppavillion.Pavilion__c LIMIT 1]);
            System.debug('Existing pavilion found: ' + existingPavilionsMap.get(opppavillion.Pavilion__c));
        }
        
        
        for (Account acc : newAccounts) {
            // Create or associate Co-Exhibitor record
            Co_Exhibitor__c coExhibitor = new Co_Exhibitor__c();
            coExhibitor.Account__c = acc.Id;
            coExhibitor.Opportunity__c = OpportunityId;
            coExhibitor.Event__c = opppavillion.Event__c;
            
            // Check if Stand exists or create a new one
            Boolean standExists = false;
            
            system.debug('stand list : '+ standList);
            for (Stand__c stand : activeStands) {
                
                
                
            }
            
            if (!standExists) {
                Stand__c newStand = new Stand__c();
                newStand.Name = standList[0];  // Stand Name
                newStand.Pavilion__c = opppavillion.Pavilion__c;
                newStand.Event__c = opppavillion.Event__c; 
                insert newStand;
                coExhibitor.Stand__c = newStand.Id;
            }
            
            lstCoExhibitorsToInsert.add(coExhibitor);
            System.debug('Creating CoExhibitor: ' + coExhibitor);
        }
        
        // Insert Co-Exhibitors if any were created
        if (!lstCoExhibitorsToInsert.isEmpty()) {
            insert lstCoExhibitorsToInsert;
            System.debug('Co-Exhibitors created: ' + lstCoExhibitorsToInsert);
        }
        return newAccounts;
    }
}