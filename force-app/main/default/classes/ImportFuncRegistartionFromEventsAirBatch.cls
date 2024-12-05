/*************************
* Created By : Foram 
* Cereated Date : 12-01-2024
* Description : Import Function Registration from Evntsair and 
Create Contact, Registartion, Opportunity and Opportunity Products 
**************************/

public class ImportFuncRegistartionFromEventsAirBatch implements Database.Batchable<ResponseWrapper>, Database.AllowsCallouts {
    
    //variable declartion
    public String strEventId;
    public String sfeventId;
    public String eventCategory;
    Integer contactsLimit = Integer.valueOf(System.Label.EventsAirFun_Attendee_Contact_Limit);
    Integer regLimit = Integer.valueOf(System.Label.EventsAir_Function_Registartion_Limit);
    List<Contact> lstInsrtCon;
    List<Lead> lstInsrtLead;
    List<Product_Service_Option__c> lstInsrtProdAndServices;
    List<Function__c> lstInsrtFun; 
    Map<String, Id> mapOfLeadStringAndId = new Map<String, Id>();   
    Map<String, Id> mapOfContactStringAndId = new Map<String, Id>();
    Set<String> setofProductId = new Set<String>();
    Map<String, Id> mapOfEvnproandSfId = new Map<String, Id>();
    Map<String, Id> mapOfEventRegTypeIdAndSFPBentryId = new Map<String, Id>();
    Map<String, Decimal> mapOfEventRegTypeIdAndSFPBentryPrice = new Map<String, Decimal>();
    String RecordType;

    //fetch current offset value from custom setting
    List<Manage_Eventsair_Fun_Reg_Apex_batch__c> lstcustsett = [Select Id, Name, Offset__c, Is_Execute_Next__c from Manage_Eventsair_Fun_Reg_Apex_batch__c LIMIT 1];
    
    public ImportFuncRegistartionFromEventsAirBatch(String eventId, String strsfeventId) {
        
        strEventId = eventId;      // set EventsAir Event RecordId value in strEventId
        sfeventId = strsfeventId;  // set Salesforce Event RecordId value in sfeventId
    }
    
    public Iterable<ResponseWrapper> start(Database.BatchableContext BC) {  
        
        // Query to fetch event details based on the provided event ID
        List<Event__c> eventData = [Select Id,Name,RecordType.Name FROM Event__c where Id =:sfeventId LIMIT 1];
        if(eventData.size() > 0) {
            RecordType = eventData[0].RecordType.Name;
        }

        // Get the OAuth token for the API based on the record type
        String graphqlQuery;
        String strtoken;

        if (RecordType != null) {
            strtoken = EventsAirOAuthTokenRequest.getAccessToken(RecordType);
        }

        // Prepare the GraphQL query based on the record type 
        if(RecordType != 'Mumbrella') {
            // Query for non-Mumbrella record types
            graphqlQuery = '{' +
                '"query": "query GetEventData($eventId: ID!, $contactsLimit: PaginationLimit!, $conoffset: NonNegativeInt!, $regLimit: PaginationLimit!,$input: CustomFieldSearchFilterInput!,) {' +
                'event(id: $eventId) {' +
                'id,' +
                'name,' +
                'startDate,' +
                'endDate,' + 
                'logo{' +
                'url,' +
                '},' +
                'contacts(offset: $conoffset, limit: $contactsLimit) { ' +
                'customFields(input: $input , limit:3){name, definitionId, value},' +
                'marketingRecords(limit: 15){' +
                'id,' +
                'name,' +
                'tag {' +
                'id,' +
                'name,' +
                '},' +
                'value' +
                '},' +
                'id,' +
                'lastName,' +
                'firstName,' +
                'title,' +
                'organizationName,' +
                'checkInDate,' +
                'checkOutDate,' +
                'primaryEmail,' +
                'primaryAddress {' +
                'city,' + 
                'country,' + 
                'line1,' + 
                'line2,' + 
                'line3,' + 
                'postCode,' + 
                'state,' + 
                '},' +
                'contactPhoneNumbers {' +
                'mobile,' +      
                '},' +          
                'functionRegistrations(limit: $regLimit) {' +
                'id,' +
                'tickets,' +  
                'checkInDate,' +
                'checkOutDate,' +
                'createdAt,' +
                'feeType {' +
                'id,' +            
                'name,' + 
                'uniqueCode,' + 
                'fees {' +
                'amount,' +      
                '},' +
                '},' +
                'function{' +
                'id,' +
                'name,' +
                'start,' +
                'date,' +
                'end,' +
                'overview,' +
                'details,' +
                '},' +
                'paymentDetails {' +
                'paymentStatus,' +
                'discountAmount,' +
                'adjustmentAmount,' +
                'taxAmount,' +
                'totalChargeAmount,' +     
                'discountCode {' +
                'code,' +
                '},' +
                '},' +
                '}' +            
                '}' +
                '}' +
                '}",' +
                '"variables": {' +
                '"eventId": "' + strEventId + '",' +
                '"contactsLimit": ' + contactsLimit + ',' +
                '"conoffset": ' + lstcustsett[0].Offset__c + ',' +
                '"regLimit": ' + regLimit +  ','+
                '"input": { "names": ["Industry" , "Company Size" , "Job Function"] }'  +            
                '}' +
                '}';
        } else {
            // Query for Mumbrella record type
            graphqlQuery = '{' +
            '"query": "query GetEventData($eventId: ID!, $contactsLimit: PaginationLimit!, $conoffset: NonNegativeInt!, $regLimit: PaginationLimit!,) {' +
            'event(id: $eventId) {' +
            'id,' +
            'name,' +
            'startDate,' +
            'endDate,' + 
            'logo{' +
            'url,' +
            '},' +
            'contacts(offset: $conoffset, limit: $contactsLimit) { ' +
            'marketingRecords(limit: 15){' +
            'id,' +
            'name,' +
            'tag {' +
            'id,' +
            'name,' +
            '},' +
            'value' +
            '},' +
            'id,' +
            'lastName,' +
            'firstName,' +
            'title,' +
            'organizationName,' +
            'checkInDate,' +
            'checkOutDate,' +
            'primaryEmail,' +
            'primaryAddress {' +
            'city,' + 
            'country,' + 
            'line1,' + 
            'line2,' + 
            'line3,' + 
            'postCode,' + 
            'state,' + 
            '},' +
            'contactPhoneNumbers {' +
            'mobile,' +      
            '},' +          
            'functionRegistrations(limit: $regLimit) {' +
            'id,' +
            'tickets,' +  
            'checkInDate,' +
            'checkOutDate,' +
            'createdAt,' +
            'feeType {' +
            'id,' +            
            'name,' + 
            'uniqueCode,' + 
            'fees {' +
            'amount,' +      
            '},' +
            '},' +
            'function{' +
            'id,' +
            'name,' +
            'start,' +
            'date,' +
            'end,' +
            'overview,' +
            'details,' +
            '},' +
            'paymentDetails {' +
            'paymentStatus,' +
            'discountAmount,' +
            'adjustmentAmount,' +
            'taxAmount,' +
            'totalChargeAmount,' +     
            'discountCode {' +
            'code,' +
            '},' +
            '},' +
            '}' +            
            '}' +
            '}' +
            '}",' +
            '"variables": {' +
            '"eventId": "' + strEventId + '",' +
            '"contactsLimit": ' + contactsLimit + ',' +
            '"conoffset": ' + lstcustsett[0].Offset__c + ',' +
            '"regLimit": ' + regLimit +            
            '}' +
            '}';
        }

        // Prepare the HTTP request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(120000);
        request.setEndpoint(System.Label.EventsAir_API_Base_URL);
        request.setMethod('POST');
        request.setBody(graphqlQuery); // Set the body with the GraphQL query
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + strtoken);
        
        // Send the HTTP request
        HttpResponse response = http.send(request);
        System.debug('@@@@ response = ' + response.getBody());
        
        // List to hold the deserialized response
        List<ResponseWrapper> lstofresponseWrapper = new List<ResponseWrapper>();
        ResponseWrapper responseWrapper = new ResponseWrapper();
        
        // Check for successful response
        if (response.getStatusCode() == 200) {
            
            // Parse the response body and replace reserved keywords
            String responseBody = response.getBody(); 
            responseBody = responseBody.replace('"dateTime"', '"registrationDateTime"');
            responseBody = responseBody.replace('"date"', '"functiondate"');
            responseBody = responseBody.replace('"end"', '"functionend"');
            
            // Deserialize the response into the ResponseWrapper object
            responseWrapper = (ResponseWrapper) JSON.deserialize(responseBody, ResponseWrapper.class);
            lstofresponseWrapper.add(responseWrapper);
        } else {
            // Update custom settings if the response contains an error
            if(lstcustsett.size() > 0) {
                lstcustsett[0].Is_Execute_Next__c = false;
                lstcustsett[0].Offset__c = 0;
                update lstcustsett;
            }
        } 
        
        // Return the response list
        return lstofresponseWrapper;
    }
    
    public void execute(Database.BatchableContext BC, List<ResponseWrapper> responseWrapper) {
        
        // Serialize the ResponseWrapper to a JSON string
        String serializedResponseWrapper = JSON.serialize(responseWrapper[0]);
        
        // Deserialize the JSON string into a map
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(serializedResponseWrapper);
            
        // Extract the 'data' map from the JSON response
        Map<String, Object> eventDatamap = (Map<String, Object>) jsonResponse.get('data');        
        
        Map<String, Object> eventmap;
        // Extract the 'event' map from the 'data' map, if present
        if(eventDatamap != null) {
            eventmap = (Map<String, Object>) eventDatamap.get('event');   
        }

        // Query for the event record based on the specified Event ID
        List<Event__c> lstevent = [SELECT Id, Name, EventsAirID__c, Open_Date__c, Close_Date__c, New_Event_Logo__c, Is_Pricebook_Created__c,Event_Category__c
                                   FROM Event__c
                                   WHERE Id =: sfeventId  ORDER BY CreatedDate DESC LIMIT 1];
        
        // Initialize lists to update events and insert pricebooks
        List<Event__c> updteventlst = new List<Event__c>();
        List<Pricebook2> lstInsrtPricebook = new List<Pricebook2>();
        
        // Extract event-related data from the event map
        String evtStartDate = (String) eventmap.get('startDate');
        String evtCloseDate = (String) eventmap.get('endDate');
        Map<String, Object> logoMap = (Map<String, Object>) eventmap.get('logo');
        String evtLogo = logoMap != null ? (String) logoMap.get('url') : null;

        // Set the values on event fields
        if (eventmap != null && !lstevent.isEmpty()) {

            // Query for existing pricebooks associated with the event
            List<Pricebook2> lstPriceook = [SELECT Id FROM Pricebook2 WHERE Events__c =: sfeventId];

            // Check if the pricebook is already created or missing and needs to be created
            if(lstevent[0].Is_Pricebook_Created__c == false || (lstevent[0].Is_Pricebook_Created__c == true && lstPriceook.size() == 0)) {
               
                // Create a new Pricebook2 record
                Pricebook2 newPricebook = new Pricebook2();
                newPricebook.Name = (String) eventmap.get('name') + ' Visitor'; 
                newPricebook.Events__c = sfeventId;
                newPricebook.Description = 'Description of the pricebook'; 
                newPricebook.IsActive = true; // Set the pricebook as active
                lstInsrtPricebook.add(newPricebook);
                
                // Mark the event as having its pricebook created
                lstevent[0].Is_Pricebook_Created__c = true;
            }

            if(lstevent[0].Event_Category__c != null){
                eventCategory = lstevent[0].Event_Category__c; 
            }

            if(evtLogo != null) {
                lstevent[0].Event_Logo__c = evtLogo;
            }

            if (evtStartDate != null) {
                lstevent[0].Open_Date__c = (Datetime) JSON.deserialize('"' + evtStartDate + '"', Datetime.class);     
            }

            if (evtCloseDate != null) {
                lstevent[0].Close_Date__c = (Datetime) JSON.deserialize('"' + evtCloseDate + '"', Datetime.class);     
            }
            
            updteventlst.add(lstevent[0]);
        }
        
        //update event list
        if (!updteventlst.isEmpty()) {        
            update updteventlst;              
        }  
        
        // Insert new pricebooks
        if(!lstInsrtPricebook.isEmpty()) {
            insert lstInsrtPricebook;
        }

        // Extract the list of contacts from the event map
        List<Object> lsteventsairContacts = new List<Object>();
        if(eventmap != null){
            lsteventsairContacts = (List<Object>) eventmap.get('contacts'); 
        }

        // If contacts are found, create records for them
        if(lsteventsairContacts.size() > 0){
            createRecords(lsteventsairContacts); 
        }
        
        // If no contacts are found, update the custom setting to stop recursion
        if(lsteventsairContacts.isEmpty()) {
            System.debug('@@@ All Data Synced');
            lstcustsett[0].Is_Execute_Next__c = false; // Stop batch recursion
            lstcustsett[0].Offset__c = 0;
            update lstcustsett;
        }        
    }
    
    public void createRecords(List<Object> lsteventsairContacts) {
        
        // Lists to store records for insertion
        lstInsrtLead = new List<Lead>();
        lstInsrtCon = new List<Contact>();
        lstInsrtProdAndServices = new List<Product_Service_Option__c>();

        // Sets and Maps for handling domain names and account information
        Set<String> setOfDomainName = new Set<String>();
        Set<String> AccountNamesForCheckCreation = new Set<String>();
        Map<String, Id> mapOfDomainNameAndAccId = new Map<String, Id>();
        Map<String, Id> mapOfDomainNameAndAccOwnerId = new Map<String, Id>();
        Map<String, String> accNeedToCreatePreName = new Map<String, String>();
        
        // Loop through event contacts to process email domain and organization names
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;            
            String strevntconemail = (String) eventconmap.get('primaryEmail');            
            String orgNameForAccCreation = (String) eventconmap.get('organizationName');
            String orgNameOfAccountInSF;  // Holds sanitized account name
            String domainname;

            // Extract domain name from email and add to the set
            if(strevntconemail != null && strevntconemail != '') {
                String[] emailparts = strevntconemail.split('@');
                String AccountName;
                if (emailparts.size() > 1) {
                    domainname = emailparts[1].trim().toLowerCase();
                    setOfDomainName.add(domainname);
                    
                    // If organization name is missing, add domain name for account creation
                    if (orgNameForAccCreation == null || orgNameForAccCreation == '') {
                        AccountName = domainname;
                        AccountNamesForCheckCreation.add(emailparts[1].trim().toLowerCase());
                        accNeedToCreatePreName.put(AccountName, domainname);
                    }
                }
            }

            // Process organization name for account creation if it exists
            if(orgNameForAccCreation != null && orgNameForAccCreation != '') {
                if (orgNameForAccCreation.length() > 80) {
                    orgNameOfAccountInSF = orgNameForAccCreation.substring(0, 80);    
                } else{
                    orgNameOfAccountInSF = orgNameForAccCreation;
                }
                accNeedToCreatePreName.put(orgNameOfAccountInSF.toLowerCase(), domainname);
                AccountNamesForCheckCreation.add(orgNameOfAccountInSF.toLowerCase());
            }
        }

        System.debug('accNeedToCreatePreName :-'+ accNeedToCreatePreName);
        System.debug('AccountNamesForCheckCreation :-'+ AccountNamesForCheckCreation);
        System.debug('AccountNamesForCheckCreation size :-'+ AccountNamesForCheckCreation.size());
        
        // Remove already existing accounts from the list by existing account name And domain name
        if (accNeedToCreatePreName.size() > 0) {

            List<Account> existingAccountsList = [SELECT Id, Name, Domain_Name__c 
                                                            FROM Account 
                                                            WHERE (Name IN :accNeedToCreatePreName.keySet() OR Domain_Name__c IN :setOfDomainName) 
                                                            AND Account_Status__c != 'Inactive' 
                                                            AND On_Hold__c = FALSE];

            // Remove accounts by name and domain name         
            if(existingAccountsList.size() > 0) {
                for(Account acc : existingAccountsList) {
                    accNeedToCreatePreName.remove(acc.Name.toLowerCase());
                }
            }
        }

        // Remove accounts where associated contact has unpaid function registrations
        if(accNeedToCreatePreName.size() > 0){

            for(Object objeventcon: lsteventsairContacts) {
                Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
                List<Object> lsteventsairfunReg = (List<Object>) eventconmap.get('functionRegistrations');
                
                if(lsteventsairfunReg != null && lsteventsairfunReg.size() > 0) {
                    Boolean hasCharge = false; //  Tracks if any function registration is paid
                    String orgNameForAccCreation = (String) eventconmap.get('organizationName');
                    String orgNameOfAccountInSF;
        
                    if(orgNameForAccCreation != null && orgNameForAccCreation != ''){
                        if (orgNameForAccCreation.length() > 80) {
                            orgNameOfAccountInSF = orgNameForAccCreation.substring(0, 80);    
                        } else {
                            orgNameOfAccountInSF = orgNameForAccCreation;
                        }
                    } else {
                        // Process domain name from email if organization name is missing
                        String strevntconemail = (String) eventconmap.get('primaryEmail');
                        if(strevntconemail != null && strevntconemail != '') {
                            String[] emailparts = strevntconemail.split('@');
                            if (emailparts.size() > 1) {
                                orgNameOfAccountInSF = emailparts[1].trim().toLowerCase();
                            }
                        }
                    }
        
                    // Check function registration payment details
                    for(Object objEventReg : lsteventsairfunReg) {
                        Map<String, Object> eventReg = (Map<String, Object>) objEventReg;
                        Map<String, Object> eventregPaymentdetails = (Map<String, Object>) eventReg.get('paymentDetails');
                        Decimal totalcharge = (Decimal) eventregPaymentdetails.get('totalChargeAmount');
        
                        if(totalcharge > 0) {
                            hasCharge = true; // if true it means contact has paid function registrations
                            break;            // Exit loop once paid function registration is found
                        }  
                    }

                    if(!hasCharge){
                        if (orgNameOfAccountInSF != null && orgNameOfAccountInSF != '') {
                            accNeedToCreatePreName.remove(orgNameOfAccountInSF.toLowerCase());
                        }
                    }
                }
            }
        }

        // Create accounts for paid function registration
        if (accNeedToCreatePreName.size() > 0) {
            List<Account> listAccPreCreate = new List<Account>();

            for(String accName: accNeedToCreatePreName.keySet()) {

                Account newAccount = new Account();

                if (RecordType == 'Mumbrella') {
                    newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mumbrella').getRecordTypeId();
                } else {
                    newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Diversified').getRecordTypeId();     
                }

                if(accName != null && accName != ''){
                    newAccount.Name = (accName.length() > 80) ? accName.substring(0, 80) : accName;
                } else {
                    newAccount.Name = 'UNKNOWN';
                }

                newAccount.AccountSource = 'EventsAir';

                if(accNeedToCreatePreName.containskey(accName)) {
					newAccount.Domain_Name__c = accNeedToCreatePreName.get(accName);
                }

                listAccPreCreate.add(newAccount);
            }

            if (listAccPreCreate.size() > 0) {
                insert listAccPreCreate;
            }
            System.debug('Account Inserted Successfully');
        }

        // if domain not match, check for account name and create map for account name with account Id
        Map<String, String> MapOfexistingAccountsOrgNameAndAccountId = new Map<String, String>();
        if (AccountNamesForCheckCreation != null) {
            List<Account> exitingAccListOfOrgNames = [SELECT Id,Name,Domain_Name__c From Account Where Name IN :AccountNamesForCheckCreation 
                                                      AND Account_Status__c != 'Inactive' and On_Hold__c = false];
        
            for (Account acct : exitingAccListOfOrgNames) {
                // map of organization name and accountId based on organization name for mapping with contact
                MapOfexistingAccountsOrgNameAndAccountId.put(acct.Name.toLowerCase(),acct.Id);
            }
        }

        //if set contains any value then do soql on account and fill the mapOfDomainNameAndAccId Map
        if(setOfDomainName != null) {

            for (AggregateResult aggregateResult : [
                SELECT MAX(CreatedDate) latestCreatedDate, Domain_Name__c, MAX(Id) accountId, MAX(OwnerId) ownerId
                FROM Account
                WHERE Domain_Name__c IN: setOfDomainName and Account_Status__c != 'Inactive' and On_Hold__c = false
                GROUP BY Domain_Name__c
            ]) {
                String domain = (String)aggregateResult.get('Domain_Name__c');
                Id accountId = (Id)aggregateResult.get('accountId');
                Id OwnerId = (Id)aggregateResult.get('ownerId');
                
                if (accountId != null) {
                    // map of domain name and accountId for mapping based on domain name with contact
                    mapOfDomainNameAndAccId.put(domain.toLowerCase(), accountId);
                }
                
                if (OwnerId != null) {
                    // map of domain name and ownerId for mapping based on domain name with opportunity field
                    mapOfDomainNameAndAccOwnerId.put(domain.toLowerCase(),OwnerId);
                }
            }
        }

        // fill the list of firstname + lastName + email for fetch lead and contact based on combined string
        Set<String> setOfCombinedEventsAirAttendee = new Set<String>(); 
        for (Object objeventcon : lsteventsairContacts) {
            String CombinedString = getCombinedString(objeventcon);
            setOfCombinedEventsAirAttendee.add(CombinedString);
        }
        
        // fetch contact from sf based on combined String
        List<Contact> listOfAllContact = [SELECT Id, FirstName, LastName, Email, CombinedString__c FROM Contact
                                             WHERE CombinedString__c in :setOfCombinedEventsAirAttendee];
        Map<String, Contact> mapOfContactStringAndContact = new Map<String, Contact>();
            
        //loop through existing Contacts and fill the map to use for mapping with function registration
        for(Contact objContact :listOfAllContact){
            mapOfContactStringAndContact.put(objContact.CombinedString__c, objContact); 
        }

        // fetch Lead from sf based on combined String
        List<Lead> listOfAllLead = [SELECT Id,FirstName, LastName,Email,CombinedString__c FROM Lead
                                          WHERE CombinedString__c in :setOfCombinedEventsAirAttendee];
        Map<String, Lead> mapOfLeadStringAndLead = new Map<String, Lead>();
            
        //loop through existing Leads and fill the map to use for mapping with function registration
        for(Lead objLead :listOfAllLead){
            mapOfLeadStringAndLead.put(objLead.CombinedString__c, objLead); 
        }

        // loop through event's air contact for create Lead/Contact based on Paid/Unpaid function registrations
        for (Object objeventcon : lsteventsairContacts) {
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
            String strcontEmail = (String) eventconmap.get('primaryEmail');           
            String strAccdomainname;
            String orgNameForMap = (String) eventconmap.get('organizationName');
            List<Object> lsteventsairfunReg = (List<Object>) eventconmap.get('functionRegistrations');

            //extract domain name from contact's email
            if(strcontEmail != null && strcontEmail != '') {
                String[] emailparts = strcontEmail.split('@');
                if (emailparts.size() > 1) {
                    strAccdomainname = emailparts[1].trim().toLowerCase();
                }
            }
            
            if(orgNameForMap != null && orgNameForMap != ''){
                if (orgNameForMap.length() > 80) {
                    orgNameForMap = orgNameForMap.substring(0, 80).toLowerCase();    
                } else{
                    orgNameForMap = orgNameForMap.toLowerCase();
                }
            }else {
                if (strAccdomainname != '' && strAccdomainname != null) {
                    orgNameForMap = strAccdomainname.toLowerCase();
                }else {
                    System.debug('Organization Name and domain both are null which is not preferable for con');
                }
            }

            if(lsteventsairfunReg.size() > 0){
                //loop through contact's eventsAir function registration data
                for(Object funReg : lsteventsairfunReg) {
                    
                    Map<String, Object> eventFunReg = (Map<String, Object>) funReg;
                    Map<String, Object> eventFunregPaymentdetails = (Map<String, Object>) eventFunReg.get('paymentDetails');
                    Decimal totalcharge = (Decimal) eventFunregPaymentdetails.get('totalChargeAmount');
                    String CombinedString = getCombinedString(objeventcon);
                
                    //create contact and account in salesforce if not exist for paid registartions
                    if(totalcharge > 0 && !mapOfContactStringAndContact.containsKey(CombinedString)) {
                    
                        // contact creation for paid function registrations
                        Contact objcon = new Contact();
                        objcon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Visitor').getRecordTypeId();  
            
                        if (RecordType == 'Mumbrella') {
                            objcon.Business_Unit__c = 'Mumbrella';
                        } else {
                            List<Object> lsteventsairCustomFields = (List<Object>) eventconmap.get('customFields');
                            for (Object fields : lsteventsairCustomFields) {
                                Map<String, Object> customFieldsMap = (Map<String, Object>) fields;
                                String FieldName = (String) customFieldsMap.get('name');
                                if (FieldName != '' && FieldName != null) {
                                    if (FieldName =='Industry') {
                                        objcon.Industry__c =(String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Company Size'){
                                        objcon.Company_Size__c = (String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Job Function'){
                                        objcon.Job_Function__c = (String) customFieldsMap.get('value');
                                    }
                                }
                            }
                            objcon.Business_Unit__c = 'Divcom'; 
                        }

                        objcon.Organization_Name__c = (String) eventconmap.get('organizationName');
                        objcon.EventsAir_Con_ID__c = (String) eventconmap.get('id');
                        String strFirstName = (String) eventconmap.get('firstName');

                        if (strFirstName != null )  {
                            if(strFirstName.length() <= 40) {
                                objCon.FirstName = strFirstName.trim();
                            } else {
                                objCon.FirstName = strFirstName.substring(0,40).trim();
                            }
                        } else {
                            objCon.FirstName = '';
                        }
            
                        String strLastName = (String) eventconmap.get('lastName');
                        if(strLastName == null || strLastName == '') {
                            objcon.LastName = 'UnKnown';
                        } else {
                            objcon.LastName = strLastName.trim();
                        }     
            
                        //objCon.Events_Air_Contact_Id__c = (String) eventconmap.get('id');
                        String stremail = (String) eventconmap.get('primaryEmail');
                        if(stremail != null && stremail != '') {
                            stremail = stremail.trim();
                            objcon.Email = stremail;
                        } else {
                            objcon.Email = ''; 
                        }    
                        Object eventconphone = eventconmap.get('contactPhoneNumbers');
                        Map<String, Object> eventconphonemap = (Map<String, Object>) eventconphone;
                        if(eventconphonemap != null) {
                            objcon.MobilePhone = (String) eventconphonemap.get('mobile');
                        } 
                                        
                        // Assign AccountId to contact Prioirty :-  1) domain name match 2) organization name match                       
                        if(mapOfDomainNameAndAccId.containsKey(strAccdomainname)) {
                            objcon.AccountId = mapOfDomainNameAndAccId.get(strAccdomainname);
                        } else if(MapOfexistingAccountsOrgNameAndAccountId.containsKey(orgNameForMap)){
                            System.debug('coming for organization Name :-' + MapOfexistingAccountsOrgNameAndAccountId.get(orgNameForMap));
                            objcon.AccountId = MapOfexistingAccountsOrgNameAndAccountId.get(orgNameForMap);
                        }  
                        lstInsrtCon.add(objcon);
                    } else {
                        // create lead for unpaid function registration if CombinedString is not found in exiting contact OR in lead
                        if(!mapOfContactStringAndContact.containsKey(CombinedString) && !mapOfLeadStringAndLead.containsKey(CombinedString)){
        
                            //lead field mapping
                            Lead newLead = new Lead();
                            newLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Visitor').getRecordTypeId();
                            String strFirstName = (String) eventconmap.get('firstName');
                            if (strFirstName != null )  {
                                if(strFirstName.length() <= 40) {
                                    newLead.FirstName= strFirstName.trim();
                                } else {
                                    newLead.FirstName = strFirstName.substring(0,40).trim();
                                }
                            } else {
                                strFirstName = ''; 
                            }

                            String strLastName = (String) eventconmap.get('lastName');
                            if(strLastName == null || strLastName == '' ) {
                                newLead.LastName = 'UnKnown';
                            } else {
                                newLead.LastName = strLastName.trim();
                            }

                            //newLead.EventsAir_Contact_Id__c = (String) eventconmap.get('id');
                            String stremail = (String) eventconmap.get('primaryEmail');
                            if(stremail != null && stremail != '') {
                                stremail = stremail.trim();
                                newLead.Email = stremail;
                            } else {
                                newLead.Email = '';
                            }

                            newLead.Event_Category__c = eventCategory;
                            newLead.Business_Unit__c = 'Divcom';

                            if (RecordType != 'Mumbrella') {
                                List<Object> lsteventsairCustomFields = (List<Object>) eventconmap.get('customFields');
                                
                                for (Object fields : lsteventsairCustomFields) {
                                    Map<String, Object> customFieldsMap = (Map<String, Object>) fields;
                                    String FieldName = (String) customFieldsMap.get('name');
                                    if (FieldName != '' && FieldName != null) {
                                        if (FieldName =='Industry') {
                                            newLead.Industry__c =(String) customFieldsMap.get('value');
                                        }
                                        if(FieldName == 'Company Size'){
                                            newLead.Company_Size__c = (String) customFieldsMap.get('value');
                                        }
                                        if(FieldName == 'Job Function'){
                                            newLead.Job_Function__c = (String) customFieldsMap.get('value');
                                        }
                                    }
                                }  
                            }
                            Object eventconphone = eventconmap.get('contactPhoneNumbers');
                            Map<String, Object> eventconphonemap = (Map<String, Object>) eventconphone; 
                            if(eventconphonemap != null) {
                                newLead.MobilePhone = (String) eventconphonemap.get('mobile'); 
                            }            
                            String strOrganization = (String) eventconmap.get('organizationName');
                            if(strOrganization != null && strOrganization != '') {
                                newLead.Company = strOrganization;
                            }
                            else{
                                newLead.Company = 'Unknown';
                            }
                            newLead.Status = 'New';
                            lstInsrtLead.add(newLead);
                            mapOfLeadStringAndLead.put(newLead.CombinedString__c , newLead);
                        }
                    }
                }
            }
        }


        // Insert Contacts
        if (!lstInsrtCon.isEmpty()) {            
            insertContactsIfNotExist(lstInsrtCon, setOfCombinedEventsAirAttendee);   
            system.debug('insertContactsIfNotExist');
        }

        // fetch all contact
        List<Contact> LstOfExtistingContact = [SELECT Id,FirstName, LastName,Email,CombinedString__c FROM Contact 
                                                WHERE CombinedString__c in :setOfCombinedEventsAirAttendee];            
        
        for(Contact objContact :LstOfExtistingContact){
            mapOfContactStringAndId.put(objContact.CombinedString__c, objContact.Id); 
        }
        
        // Insert Lead
        if (!lstInsrtLead.isEmpty()) {
            insertLeadsIfNotExist(lstInsrtLead, setOfCombinedEventsAirAttendee); 
            system.debug('insertLeadsIfNotExist');
        }

        // fetch all Lead
        List<Lead> LstOfExtistingLead = [SELECT Id,FirstName, LastName,Email,CombinedString__c FROM Lead 
                                            WHERE CombinedString__c in :setOfCombinedEventsAirAttendee];
    
        for(Lead objLead :LstOfExtistingLead) {
            mapOfLeadStringAndId.put(objLead.CombinedString__c, objLead.Id); 
        }
        
        // Loop through event's air contacts data to create Product & Services
        for(Object objeventcon : lsteventsairContacts) {
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
            List<Object> lsteventsairfunReg = (List<Object>) eventconmap.get('functionRegistrations');
            if (lsteventsairfunReg.size() > 0) {
                
                List<Object> lsteventsairRecMarket = (List<Object>) eventconmap.get('marketingRecords');
                String strevntconId = (String) eventconmap.get('id');
                
                // loop through marketing records to create Product & Services
                for(Object objEventMarketing : lsteventsairRecMarket) {
                    Map<String, Object> prodAndSerMap = (Map<String, Object>) objEventMarketing;

                    String prodAndServiceName = (String) prodAndSerMap.get('name');
                    
                    Product_Service_Option__c prodAndService = new Product_Service_Option__c();
                    prodAndService.EventsAirMarketing_Record_ID__c = (String) prodAndSerMap.get('id');
                    if(prodAndServiceName != null){
                        if(prodAndServiceName.length() <= 80) {
                            prodAndServiceName = prodAndServiceName.trim();
                        } else {
                            prodAndServiceName = prodAndServiceName.substring(0,80).trim();
                        }
                    }
                    prodAndService.Name =  prodAndServiceName;
                    prodAndService.Marketing_Value__c = (String) prodAndSerMap.get('value');
                    
                    // Finalstring is the combination of first name + last name + email
                    string Finalstring = getCombinedString(objeventcon);
                    if(Finalstring != null && Finalstring != '') {
                        if(mapOfContactStringAndId.containsKey(Finalstring)) {
                            prodAndService.Contact__c = mapOfContactStringAndId.get(Finalstring);
                        }else{
                            // connect with exiting or newly created lead
                            if(mapOfLeadStringAndId.containsKey(Finalstring)) {
                                prodAndService.Lead__c = mapOfLeadStringAndId.get(Finalstring);
                            }
                        }
                    }

                    lstInsrtProdAndServices.add(prodAndService);
                }
            }
        }

        System.debug('lstInsrtProdAndServices :-->' + lstInsrtProdAndServices);   
        insertProdAndServicesIfNotExist(lstInsrtProdAndServices);

        List<Registration__c> lstInsrtReg = new List<Registration__c>(); 
        List<Opportunity> lstInsrtOpp = new List<Opportunity>();
        
        // fetch pricebook related to the event Record  
        List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: sfeventId];

        // Loop through event's air contacts data to create function registration
        for(Object objeventcon : lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;  
            List<Object> lsteventsairfunReg = (List<Object>) eventconmap.get('functionRegistrations');
            String strevntconId = (String) eventconmap.get('id');
            String strcontEmail = (String) eventconmap.get('primaryEmail');           
            // boolean isexecuted = false;
            String strAccdomainname;            
            
            
            //extract domain name from contact's email
            if(strcontEmail != null && strcontEmail != '') {
                String[] emailparts = strcontEmail.split('@');
                if (emailparts.size() > 1) {
                    strAccdomainname = emailparts[1].trim().toLowerCase();
                }
            }
            
            // create functions
            if(!lsteventsairfunReg.isEmpty()) {
                setupForFunctionReg(lsteventsairfunReg);                
            }
            
            if(lsteventsairfunReg.size() > 0){
                //loop through event'sair function registration data
                for(Object objEventReg: lsteventsairfunReg) {
                    
                    Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                    Map<String, Object> eventregtypemap = (Map<String, Object>) eventReg.get('feeType');
                    Map<String, Object> eventregPaymentdetails = (Map<String, Object>) eventReg.get('paymentDetails');
                    String strRegDate = (String) eventReg.get('registrationDateTime'); 
                    Decimal totalcharge = (Decimal)eventregPaymentdetails.get('totalChargeAmount');
                    
                    String strtickets = (String) eventReg.get('tickets');
                    Map<String, Object> tempfunmap = (Map<String, Object>)(eventReg.get('function'));                                
                    String checkInDate = (String) eventReg.get('checkInDate');
                    String createdAtDate = (String) eventReg.get('createdAt');
                    String checkOutDate = (String) eventReg.get('checkOutDate'); 

                    //Registartion field mapping start
                    Registration__c objreg = new Registration__c(); 

                    objreg.RecordTypeId = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Function_Registration').getRecordTypeId(); 
                    
                    if(strRegDate != null) {
                        objreg.Date_Registered__c = (Datetime) JSON.deserialize('"' + strRegDate + '"', Datetime.class);
                    }

                    objreg.EventsAir_Regisration_ID__c = (String) eventReg.get('id');
                    objreg.EventsAir_Contact_Id__c = (String) eventconmap.get('id');
                    objreg.Event__c = sfeventId; 

                    if(checkInDate != null) {
                        objreg.CheckInDate__c = (Datetime) JSON.deserialize('"' + checkInDate + '"', Datetime.class);                  
                    }

                    if(checkOutDate != null) {
                        objreg.CheckOutDate__c  = (Datetime) JSON.deserialize('"' + checkOutDate + '"', Datetime.class);                     
                    }

                    objreg.Number_of_Tickets__c = Decimal.valueOf(strtickets);
                    objreg.EventsAir_Function_Id__c = (String) tempfunmap.get('id');

                    // Finalstring is the combination of first name + last name + email
                    String Finalstring = getCombinedString(objeventcon);
                    if(Finalstring != null && Finalstring != '') {
                        
                        // connect contact with paid function registrations
                        if( totalcharge > 0 && mapOfContactStringAndId.containsKey(Finalstring)) {
                            objreg.Contact__c = mapOfContactStringAndId.get(Finalstring);
                        }else {
                            // connect contact if it is created before
                            if(mapOfContactStringAndId.containsKey(Finalstring)) {
                                objreg.Contact__c = mapOfContactStringAndId.get(Finalstring);
                            }else{
                                // connect with exiting or newly created lead
                                if(mapOfLeadStringAndId.containsKey(Finalstring)) {
                                    objreg.Lead__c = mapOfLeadStringAndId.get(Finalstring);
                                }   
                            }
                        }
                    }

                    if(eventregtypemap.get('name') != null) {
                        if(!Test.isRunningTest()) {
                            objreg.Registration_Type__c = (String) eventregtypemap.get('name'); 
                        }
                    }  

                    if(eventregPaymentdetails.get('paymentStatus') != null) {
                        objreg.Payment_Status__c = (String) eventregPaymentdetails.get('paymentStatus');                     
                    } 
                    
                    lstInsrtReg.add(objreg); 
                    
                    // for paid function registration for create opportunity and it's opportunity products
                    if(totalcharge > 0 ) {   
                        // isexecuted = true;
                        system.debug('totalcharge'+totalcharge);
                        String OrganizationName;

                        if(eventconmap.get('organizationName') != null){
                            String orgName = (String) eventconmap.get('organizationName');
                            OrganizationName = (orgName.length() > 80) ? orgName.substring(0, 80).trim().toLowerCase() : orgName.trim().toLowerCase();  
                        }

                        //Opportunity field Mapping
                        Opportunity objOpp = new Opportunity();
                        String strOppName = 'Opportunity created for '+(String) eventconmap.get('firstName')+' '+(String) eventconmap.get('lastName');
                        objOpp.Name = strOppName;
                        if(mapOfDomainNameAndAccId.containsKey(strAccdomainname)){
                            objOpp.AccountId = mapOfDomainNameAndAccId.get(strAccdomainname);
                        }else if(MapOfexistingAccountsOrgNameAndAccountId.containsKey(OrganizationName)){
                            objOpp.AccountId = MapOfexistingAccountsOrgNameAndAccountId.get(OrganizationName);
                        }
                        
                        if(mapOfDomainNameAndAccOwnerId.containsKey(strAccdomainname)){
                            objOpp.OwnerId = mapOfDomainNameAndAccOwnerId.get(strAccdomainname);
                        }
                        
                        objOpp.Is_Private__c = false;	
                        objOpp.LeadSource = 'EventsAir';
                        if(checkInDate != null) {
                            objOpp.Closedate = Date.valueOf(checkInDate);                  
                        }else{
                            objOpp.Closedate =  Date.valueOf(createdAtDate);
                        }

                        if (RecordType == 'Mumbrella') {
                            objOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mumbrella_Visitor').getRecordTypeId();                          
                        } else {
                            objOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Divcom_Visitor').getRecordTypeId();
                        }                       
                        objOpp.Event__c = sfeventId;
                        objOpp.EventsAir_Contact_Id__c = strevntconId;
                        if(lstPriceook.size()>0){
                            objOpp.Pricebook2Id =lstPriceook[0].Id;
                        }
                        objOpp.stageName = 'Closed Won'; 
                        
                        objOpp.NetSuite_Integration_Status__c = 'DoNotSync';
                        lstInsrtOpp.add(objOpp); 
                        System.debug('objOpp '+objOpp);   
                    }
                }
            }       
        }
        
        List<Registration__c> regListForFunctionMapping = insertRegistrationIfNotExist(lstInsrtReg);
        LinkFunctionToRegistration(regListForFunctionMapping);
        List<Opportunity> allOpportunitiyList = insertOpportunityIfNotExist(lstInsrtOpp);
        createOpportunityProduct(lsteventsairContacts, allOpportunitiyList);
    }

    // Method for create combined String
    public static String getCombinedString(Object objeventcon){
        Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
        String streventconEmail = (String) eventconmap.get('primaryEmail');
        String streventconfname = (String) eventconmap.get('firstName');
        String streventconlname = (String) eventconmap.get('lastName');

        if(streventconlname == null || streventconlname == '') {
            streventconlname = '';
        }
        
        string fname;
        string lname; 
        string email ;
        
        if(streventconfname != null){
            if(streventconfname.length() <= 40) {
                fname = streventconfname.trim();
            } else {
                fname = streventconfname.substring(0,40).trim();
            }
        }
        else{
        fname = ''; 
        }
        
        if(streventconlname != null && streventconlname != '' ){
            lname = streventconlname.trim(); 
        }else{
        lname = 'UnKnown'; 
        }
        
        if(streventconEmail != null){
            email = streventconEmail.trim(); 
        }else{
        email = ''; 
        }
    
        string Finalstring = fname + lname + email;
        Finalstring = Finalstring.toLowerCase();
        return Finalstring;
    }  

    // Method for insert only new Contacts if not exist in salesforce
    public static void insertContactsIfNotExist(List<Contact> contactsToInsert , Set<String> setOfCombinedEventsAirAttendee) {

        //fetch existing Contacts based on Combined name
        List<Contact> LstOfExtistingContact = [Select Id,FirstName, LastName,Email,CombinedString__c from Contact where CombinedString__c in :setOfCombinedEventsAirAttendee];
        
        Map<String, Id> mapOfContactStringAndIds = new Map<String, Id>();
        //loop through existing Contacts and fill the map
        for(Contact objContact :LstOfExtistingContact){
           mapOfContactStringAndIds.put(objContact.CombinedString__c, objContact.Id); 
        }

        List<Contact> FinalListOfContactToInsert = new List<Contact>();
        Set<String> setOfCurrentContactCombinedData = new Set<String>();
        
        //loop through the passed data of contact for insert and extract unique contacts for insert
        for(Contact objcontact :contactsToInsert){

            String strcombinedEventsAirAttendee = objcontact.FirstName + objcontact.LastName + objcontact.Email; 
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            
            // check if contact is exist or not
            if(!mapOfContactStringAndIds.ContainsKey(strcombinedEventsAirAttendee)){
                // for prevent adding duplicate contact in list
                if(!setOfCurrentContactCombinedData.contains(strcombinedEventsAirAttendee)){
                    FinalListOfContactToInsert.add(objcontact);
                    setOfCurrentContactCombinedData.add(strcombinedEventsAirAttendee);
                }
            }
        }
        
        if(FinalListOfContactToInsert.size()>0){
            Database.insert(FinalListOfContactToInsert,false);
        } 
    }

    // Method for insert only new Leads if not exist in salesforce
    public static void insertLeadsIfNotExist(List<Lead> leadsToInsert, Set<String> setOfCombinedEventsAirAttendee) {
    
        //fetch existing leads based on Combined name
        List<Lead> LstOfExtistingLead = [Select Id,FirstName, LastName,Email,CombinedString__c from Lead where CombinedString__c in :setOfCombinedEventsAirAttendee];
        
        Map<String, Id> mapOfLeadStringAndId = new Map<String, Id>();
        //loop through existing leads and fill the map
        for(Lead objLead :LstOfExtistingLead){
            mapOfLeadStringAndId.put(objLead.CombinedString__c, objLead.Id); 
        }

        List<Lead> FinalListOfLeadToInsert = new List<Lead>();
        Set<String> setOfCurrentleadCombinedData = new Set<String>();
        
        for(Lead objLead :leadsToInsert){
            String strcombinedEventsAirAttendee= objLead.FirstName+objLead.LastName+objLead.Email; 
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            
            // check if lead exist or not
            if(!mapOfLeadStringAndId.ContainsKey(strcombinedEventsAirAttendee)){
                // for prevent adding duplicate lead in list
                if(!setOfCurrentleadCombinedData.contains(strcombinedEventsAirAttendee)){
                    FinalListOfLeadToInsert.add(objLead);
                    setOfCurrentleadCombinedData.add(strcombinedEventsAirAttendee);
                }
            }
        }
        
        if(FinalListOfLeadToInsert.size()>0){
            insert FinalListOfLeadToInsert;
        } 
    }

    // Method for insert only new Product_Service_Option if not exist in salesforce
    public void insertProdAndServicesIfNotExist(List<Product_Service_Option__c> lstInsrtProdAndServices) {
        
        system.debug('insertProdAndServicesIfNotExist'+ lstInsrtProdAndServices.size());
        
        Map<String, Id> mapOfEvnPrdSericeIdandSfPrdServiceId = new Map<String, Id>(); // holds map of eventsAir marketing record id and SF recordId
        set<String> setOfEvnProdServiceIds = new set<String>();  // holds marketing record id
        
        for(Product_Service_Option__c prodAndService: lstInsrtProdAndServices) {
            setOfEvnProdServiceIds.add(prodAndService.EventsAirMarketing_Record_ID__c);
        }
        
        //fetch all product service options record which match EventsAirMarketing_Record_ID__c with setOfEvnProdServiceIds
        List<Product_Service_Option__c> lstexistingProdAndService = [SELECT Id, EventsAirMarketing_Record_ID__c
                                                          FROM Product_Service_Option__c 
                                                          WHERE EventsAirMarketing_Record_ID__c IN: setOfEvnProdServiceIds];
        system.debug('lstexistingProdAndService'+lstexistingProdAndService.size());
        
        // if records found create a map of it and used for ensure duplicate is not create
        if(lstexistingProdAndService.size() > 0) {
            for(Product_Service_Option__c existingProdAndService: lstexistingProdAndService) {
                mapOfEvnPrdSericeIdandSfPrdServiceId.put(existingProdAndService.EventsAirMarketing_Record_ID__c, existingProdAndService.Id);
            }
        }
        
        List<Product_Service_Option__c> finallisttoinsertProdAndService = new List<Product_Service_Option__c>();
        List<Product_Service_Option__c> finallisttoUpdateProdAndService = new List<Product_Service_Option__c>();

        // loop through all extracted product service option record from EventsAir Contacts
        for(Product_Service_Option__c newProdAndService: lstInsrtProdAndServices) {
            // if found new add it in record insert List else for update
            if(!mapOfEvnPrdSericeIdandSfPrdServiceId.containskey(newProdAndService.EventsAirMarketing_Record_ID__c)) {
                finallisttoinsertProdAndService.add(newProdAndService);
            }else{
                newProdAndService.Id = mapOfEvnPrdSericeIdandSfPrdServiceId.get(newProdAndService.EventsAirMarketing_Record_ID__c);
                finallisttoUpdateProdAndService.add(newProdAndService);
            }
        }

        if(finallisttoinsertProdAndService.size() >0) {
            system.debug('finallisttoinsertProdAndService'+finallisttoinsertProdAndService.size());
            insert finallisttoinsertProdAndService ;
        }

        if(finallisttoUpdateProdAndService.size() >0) {
            system.debug('finallisttoUpdateProdAndService'+finallisttoUpdateProdAndService.size());
            update finallisttoUpdateProdAndService ;
        }
    }   
    
    // Method for insert only new function registration if not exist in salesforce
    public List<Registration__c> insertRegistrationIfNotExist(List<Registration__c> lstInsrtReg) {
    
        Map<String, Id> mapOfEvnRegIdandSfRegId = new Map<String, Id>();
        set<String> setOfEvnRegIds = new set<String>(); // holds eventsAir function registration record Id
        
        for(Registration__c reg: lstInsrtReg) {
            setOfEvnRegIds.add(reg.EventsAir_Regisration_ID__c);
        }
        
        //do soql on registartion to fetch data based on eventsair function registration id
        List<Registration__c> lstexistingRegistrations = [SELECT Id, EventsAir_Regisration_ID__c
                                                          FROM Registration__c 
                                                          WHERE EventsAir_Regisration_ID__c IN: setOfEvnRegIds and Event__c =:sfeventId];
        system.debug('lstexistingRegistrations'+lstexistingRegistrations.size());
        system.debug('sfeventId'+sfeventId);

        // if exiting function registration found in SF fill the map for prevent duplicate
        if(lstexistingRegistrations.size() > 0) {
            for(Registration__c existingreg: lstexistingRegistrations) {
                mapOfEvnRegIdandSfRegId.put(existingreg.EventsAir_Regisration_ID__c, existingreg.Id);
            }
        }
        
        List<Registration__c> finallisttoinsertreg = new List<Registration__c>();
        // List<Registration__c> listtoUpdatereg = new List<Registration__c>();
        List<Registration__c> listRegForConnectWithFunction = new List<Registration__c>();
        
        for(Registration__c newreg: lstInsrtReg) {
            // check if exiting function registration record if not found than add for insert
            if(!mapOfEvnRegIdandSfRegId.containskey(newreg.EventsAir_Regisration_ID__c)) {
                finallisttoinsertreg.add(newreg);
            } else {
                newreg.Id = mapOfEvnRegIdandSfRegId.get(newreg.EventsAir_Regisration_ID__c);
                // listtoUpdatereg.add(newreg);
                listRegForConnectWithFunction.add(newreg);
            }
        }

        if(finallisttoinsertreg.size() >0) {
            insert finallisttoinsertreg ;
            listRegForConnectWithFunction.addAll(finallisttoinsertreg);
        }

        /*if (listtoUpdatereg.size() > 0) {
             update listtoUpdatereg;
        }*/
        return listRegForConnectWithFunction;
    }

    // method to insert new Opportunity(no duplicates) in salesforce
    public List<Opportunity> insertOpportunityIfNotExist(List<Opportunity> lstInsrtOpp) {
    
        Map<String, Id> mapOfEvnconIdandSfOppId = new Map<String, Id>();
        set<String> setOfEvnconIds = new set<String>(); // holds eventsAir contact recrod Id
        List<Opportunity> allOpportunityList = new List<Opportunity>();

        for(Opportunity opp: lstInsrtOpp) {
            setOfEvnconIds.add(opp.EventsAir_Contact_Id__c);
        }
        
        //do soql on opportunity and contact to fetch data based on eventsair contact id
        List<Opportunity> lstexistingOpps = [SELECT Id, EventsAir_Contact_Id__c
                                                FROM Opportunity 
                                                WHERE EventsAir_Contact_Id__c IN: setOfEvnconIds];

        List<Contact> lstexistingContacts = [SELECT Id, EventsAir_Con_ID__c,AccountId
                                                FROM Contact 
                                                WHERE EventsAir_Con_ID__c IN: setOfEvnconIds];
        
        Map<String, Id> mapOfEvtAirContactIdAndAccountId = new Map<String, Id>();

        if(lstexistingContacts.size() > 0) {
            for (Contact con : lstexistingContacts) {
                mapOfEvtAirContactIdAndAccountId.put(con.EventsAir_Con_ID__c, con.accountId);
            }
        }
        System.debug('mapOfEvtAirContactIdAndAccountId :->' + mapOfEvtAirContactIdAndAccountId);
        
        if(lstexistingOpps.size() > 0) {
            allOpportunityList.addAll(lstexistingOpps);
            for(Opportunity existingOpp: lstexistingOpps) {
                mapOfEvnconIdandSfOppId.put(existingOpp.EventsAir_Contact_Id__c, existingOpp.Id);
            }
        }
        
        List<Opportunity> finallisttoinsertOpp = new List<Opportunity>();
        Set<String> oppNames = new Set<String>();
        
        for(Opportunity newopp: lstInsrtOpp) {
            // add opportunity if opportunity record not found with  eventsAir contact Id in Salesforce AND add new Opportunity Name in set
            if(!mapOfEvnconIdandSfOppId.containskey(newopp.EventsAir_Contact_Id__c) && !oppNames.contains(newopp.Name)) {
                // Assign accountId by finding contact with same EventsAir contact id in map
                if (( newopp.accountId != null) && mapOfEvtAirContactIdAndAccountId.containsKey(newopp.EventsAir_Contact_Id__c) ) {
                    newopp.accountId = mapOfEvtAirContactIdAndAccountId.get(newopp.EventsAir_Contact_Id__c);
                } 
                finallisttoinsertOpp.add(newopp);
                oppNames.add(newopp.Name);
            }
        }
        
        if(finallisttoinsertOpp.size() > 0  && !test.isrunningtest()) {
            allOpportunityList.addAll(finallisttoinsertOpp);
            insert finallisttoinsertOpp;
        }
        return allOpportunityList;
    }

    // Method for insert new opportunityLineItem only
    public void createOpportunityProduct(List<Object> lsteventsairContacts,List<Opportunity> allOpportunitiyList) {
        
        // variable, list, set and Map declaration
        Set<String> setOfProdId = new Set<String>();
        List<OpportunityLineItem> lstInsertOppProduct = new List<OpportunityLineItem>();
        List<Product2> lstInsertproduct = new List<Product2>();
        List<PricebookEntry> lstInsertPricebookEntry = new  List<PricebookEntry>(); 
        Map<String, Id> mapOfEventConAndSFOppId = new Map<String, Id>();
        
        //fetch pricebook
        List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: sfeventId];
        Pricebook2 standardPriceBook = [ SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
        
        //fetch opportunity which is inserted before
        List<Opportunity> lstofOpportunity = [select id,Name,CreatedDate,EventsAir_Contact_Id__c from Opportunity where id in :allOpportunitiyList];
        
        for(Opportunity opp: lstofOpportunity) {
            mapOfEventConAndSFOppId.put(opp.EventsAir_Contact_Id__c, opp.Id);
            system.debug('mapOfEventConAndSFOppId'+mapOfEventConAndSFOppId);
        }
        
        // loop through eventsAir contact data
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;  
            List<Object> lsteventsairfunReg = (List<Object>) eventconmap.get('functionRegistrations');
            String strevntconId = (String) eventconmap.get('id'); 
            
            if(lsteventsairfunReg.size() > 0){
                //loop through event'sair function registration data
                for(Object objEventReg: lsteventsairfunReg) {
                    
                    Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                    Object eventfunregtype = eventReg.get('feeType');                    
                    Map<String, Object> eventregtypemap = (Map<String, Object>)eventfunregtype;
                    String strRegTypeId = (String) eventregtypemap.get('id');
                    
                    List<Object> lstfee;
                    string funregid = (String) eventReg.get('id');
                    
                    // create product based on function registration type
                    if(eventregtypemap != null && !setOfProdId.contains(strRegTypeId)) {
                        //Product2 field mapping start
                        Product2 newProduct = new Product2();
                        system.debug('name '+ (String) eventregtypemap.get('name'));
                        newProduct.Name = (String) eventregtypemap.get('name');
                        newProduct.EventsAir_ID__c = strRegTypeId;
                        newProduct.ProductCode = (String) eventregtypemap.get('uniqueCode');
                        newProduct.Description = 'This is a product from eventsair';
                        newProduct.IsActive = true;
                        newProduct.Family = 'Sample Family';
                        newProduct.IsActive = true;                    
                        lstInsertproduct.add(newProduct);
                        setOfProdId.add(strRegTypeId);
                    }
                }
            }         
        }
        
        if (!lstInsertproduct.isEmpty()) {

            set<String> setOfEvnproIds = new set<String>();
            
            for(Product2 p: lstInsertproduct) {
                setOfEvnproIds.add(p.EventsAir_ID__c);
            }
            
            //do soql on product to fetch data based on product EventsAir_ID
            List<Product2> lstexistingproducts = [SELECT Id, EventsAir_ID__c
                                                  FROM Product2 
                                                  WHERE EventsAir_ID__c IN: setOfEvnproIds];
            
            if(lstexistingproducts.size() > 0) {
                for(Product2 existingpr: lstexistingproducts) {
                    mapOfEvnproandSfId.put(existingpr.EventsAir_ID__c, existingpr.Id);
                }
            }
            
            List<Product2> finallisttoinsertproduct= new List<Product2>();
            
            // prevent duplicate product insertion
            for(Product2 newpr: lstInsertproduct) {
                if(!mapOfEvnproandSfId.containskey(newpr.EventsAir_ID__c)) {
                    finallisttoinsertproduct.add(newpr);
                }
            }
            
            if(finallisttoinsertproduct.size() >0) {
                system.debug(' finallisttoinsertproduct'+finallisttoinsertproduct);
                insert finallisttoinsertproduct;
            }

            // fill map with product events air Id and sf product Id
            for(Product2 prod: finallisttoinsertproduct) {
                mapOfEvnproandSfId.put(prod.EventsAir_ID__c, prod.Id);
            }
            system.debug(' mapOfEvnproandSfId'+mapOfEvnproandSfId);
        }
        
        // loop through eventsAir contact
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;  
            List<Object> lsteventsairfunReg = (List<Object>) eventconmap.get('functionRegistrations');
            
            if(lsteventsairfunReg.size() > 0){
                //loop through event'sair function registration data
                for(Object objEventReg: lsteventsairfunReg) {

                    Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                    string funregid = (String) eventReg.get('id');
                    Object eventfunregtype = eventReg.get('feeType');                    
                    Map<String, Object> eventregtypemap = (Map<String, Object>)eventfunregtype;
                    String strRegTypeId = (String) eventregtypemap.get('id');
                    List<Object> lstfee = (List<Object>) eventregtypemap.get('fees'); 
                    
                    if(lstfee.size() > 0){
                        // loop through eventsAir fee Data for creation of Pricebook entry
                        for(Object objfee: lstfee) {
                            
                            Map<String, Object> feemap = (Map<String, Object>)objfee;
                            
                            // check for eventsAir strRegTypeId (Product Events Air Id) for prevent duplicate for pricebookEntry
                            if(mapOfEvnproandSfId.containsKey(strRegTypeId) && !setofProductId.contains(strRegTypeId)) {
                                
                                //add to standard pricebook
                                PricebookEntry pbEntry = new PricebookEntry();
                                pbEntry.Product2Id = mapOfEvnproandSfId.get(strRegTypeId);

                                if(standardPriceBook != null){
                                    pbEntry.Pricebook2Id = standardPriceBook.Id;  
                                }
                                
                                pbEntry.UnitPrice = (decimal) feemap.get('amount');
                                pbEntry.IsActive = true;
                                pbEntry.UseStandardPrice = false;
                                system.debug(' pricebook'+pbEntry);
                                lstInsertPricebookEntry.add(pbEntry); 
                                
                                //add to custom pricebook
                                PricebookEntry pbEntry2 = new PricebookEntry();

                                if(mapOfEvnproandSfId.containsKey(strRegTypeId)){
                                    pbEntry2.Product2Id = mapOfEvnproandSfId.get(strRegTypeId);                         
                                }

                                if(lstPriceook.size()>0){
                                    pbEntry2.Pricebook2Id = lstPriceook[0].Id; 
                                }  

                                if(strRegTypeId != null) {
                                    pbEntry2.EventsAir_Type_ID__c = strRegTypeId;
                                }  
                                pbEntry2.UnitPrice = (decimal) feemap.get('amount');
                                pbEntry2.IsActive = true;
                                pbEntry2.UseStandardPrice = false;
                                setofProductId.add(strRegTypeId);
                                lstInsertPricebookEntry.add(pbEntry2); 
                                
                                system.debug(' mapOfEvnproandSfId'+mapOfEvnproandSfId);
                                system.debug(' strRegTypeId'+strRegTypeId);
                            }                    
                        }
                    }
                }  
            }          
        }
        
        //create pricebbook entry
        if(!lstInsertPricebookEntry.isEmpty()) {
            
            //check for existing pricebookentry start
            Set<String> setOfPricebookProductIds = new Set<String>();
            for (PricebookEntry newpricebookentry : lstInsertPricebookEntry) {
                setOfPricebookProductIds.add(newpricebookentry.Product2Id);
            }
            List<PricebookEntry> lstexistingPricebookentry = [SELECT Id, Name, Product2.Name, EventsAir_Type_ID__c, UnitPrice
                                                              FROM PricebookEntry 
                                                              WHERE Product2Id IN: setOfPricebookProductIds];
            
            Map<String, Boolean> mapofpricebookentry = new Map<String, Boolean>();
            
            for(PricebookEntry pb: lstexistingPricebookentry) {
                mapofpricebookentry.put(pb.Product2Id, true);
            }
            
            List<PricebookEntry> finallsttoinsrtPB = new List<PricebookEntry>();
            
            for(PricebookEntry objPB: lstInsertPricebookEntry) {
                if(!mapofpricebookentry.containsKey(objPB.Product2Id)) {
                    finallsttoinsrtPB.add(objPB);
                }
            }
            
            if(!finallsttoinsrtPB.isEmpty()) {
                insert finallsttoinsrtPB;
            }
            
            //fill mapOfEventRegTypeIdAndSFPBentryId Map
            //loop through existing pricebookentry list
            for(PricebookEntry objexistingPBEntry: lstexistingPricebookentry) {
                mapOfEventRegTypeIdAndSFPBentryId.put(objexistingPBEntry.EventsAir_Type_ID__c, objexistingPBEntry.Id);
                mapOfEventRegTypeIdAndSFPBentryPrice.put(objexistingPBEntry.EventsAir_Type_ID__c, objexistingPBEntry.UnitPrice);                        
            }
            
            //loop through new pricebookentry list
            for(PricebookEntry objnewPBEntry: finallsttoinsrtPB) {
                mapOfEventRegTypeIdAndSFPBentryId.put(objnewPBEntry.EventsAir_Type_ID__c, objnewPBEntry.Id);
                mapOfEventRegTypeIdAndSFPBentryPrice.put(objnewPBEntry.EventsAir_Type_ID__c, objnewPBEntry.UnitPrice);
            }
            
        }  
        
        // loop through eventsAir contacts
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;  
            
            List<Object> lsteventsairfunReg = (List<Object>) eventconmap.get('functionRegistrations');
            String strevntconId = (String) eventconmap.get('id'); 

            if(lsteventsairfunReg.size() > 0){
                
                //loop through event'sair function registration data
                for(Object objEventReg: lsteventsairfunReg) {

                    Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                    string funregid = (String) eventReg.get('id');
                    Object eventregPaydetail = eventReg.get('paymentDetails');                    
                    Object eventfunregtype = eventReg.get('feeType');                    
                    
                    Map<String, Object> eventregPaymentdetails = (Map<String, Object>)eventregPaydetail;
                    Decimal totalcharge = (Decimal)eventregPaymentdetails.get('totalChargeAmount');

                    Map<String, Object> eventregtypemap = (Map<String, Object>)eventfunregtype;
                    String strRegTypeId = (String) eventregtypemap.get('id');
                    
                    String discountcodeval;
                    Map<String, Object> eventregPaydetailcodedetail;
                    String strtickets = (String) eventReg.get('tickets');

                    // check for function registration payment details
                    if(eventregPaymentdetails.get('discountCode') != null){
                        Object eventregPaydetailcode = eventregPaymentdetails.get('discountCode');
                        eventregPaydetailcodedetail = (Map<String, Object>)eventregPaydetailcode;
                        
                        system.debug('eventregPaydetailcodedetail'+eventregPaydetailcodedetail);
                        system.debug('eventregPaydetailcodedetail.get'+eventregPaydetailcodedetail.get('code'));
                        if(eventregPaydetailcodedetail.get('code') != null){
                            discountcodeval = (String)eventregPaydetailcodedetail.get('code');
                        } 
                    }
                    
                    // check for paid function registration
                    if(totalcharge > 0){

                        system.debug('totalcharge'+totalcharge);
                        //  " mapOfEventConAndSFOppId " check if the contact with eventsAir ID is exist or not in salesforce
                        // " mapOfEventRegTypeIdAndSFPBentryId " check if the pricebookentry for the product is created or not in salesforce
                        if( mapOfEventConAndSFOppId.containsKey(strevntconId)  && mapOfEventRegTypeIdAndSFPBentryId.containskey(strRegTypeId)) {
                            
                            // Finalstring is the combination of first name + last name + email
                            String Finalstring = getCombinedString(objeventcon);

                            //OpportunityLineItem field mapping start
                            OpportunityLineItem oli = new OpportunityLineItem();
                            oli.OpportunityId = mapOfEventConAndSFOppId.get(strevntconId);                    
                            oli.PricebookEntryId = mapOfEventRegTypeIdAndSFPBentryId.get(strRegTypeId);
                            oli.Quantity = Integer.valueOf(strtickets);
                            oli.Product2Id =mapOfEvnproandSfId.get(strRegTypeId); 
                            oli.EventsAir_Adjustment__c = (Decimal) eventregPaymentdetails.get('adjustmentAmount');
                            oli.EventsAir_Discount_Amount__c = (Decimal) eventregPaymentdetails.get('discountAmount');
                            
                            if(discountcodeval != null){
                                oli.EventsAir_Discount_Code__c = discountcodeval;  
                            }

                            oli.EventsAir_Tax__c = (Decimal) eventregPaymentdetails.get('taxAmount');
                            oli.EventsAir_Payment_Status__c = (String) eventregPaymentdetails.get('paymentStatus');
                            oli.Function_Registration_Id__c = funregid;
                            oli.EventsAir_Regisration_ID__c = funregid;

                            if(Finalstring != null && Finalstring != '') {
                    
                                if(mapOfContactStringAndId.containsKey(Finalstring)) {
                                    oli.Contact__c = mapOfContactStringAndId.get(Finalstring);
                                }
                            }    
                            oli.TotalPrice = (Decimal) eventregPaymentdetails.get('totalChargeAmount');
                            System.debug('@@@ eventregPaymentdetails = '+eventregPaymentdetails);
                            system.debug('oli'+oli);
                            lstInsertOppProduct.add(oli);
                        }
                    }
                }
            }
        }

        // process for insert OpportuniyLineItem And link opportunityLineItem with function registration in Salesforce
        List<OpportunityLineItem> listOliForLinkOppWithReg = new List<OpportunityLineItem>();                
        Map<String, Id> mapOfEvnOLIandSfId = new Map<String, Id>();
        set<String> setOfEvnOLIIds = new set<String>();
        
        for(OpportunityLineItem oli: lstInsertOppProduct) {
            setOfEvnOLIIds.add(oli.Function_Registration_Id__c);
        }

        //do soql on con to fetch data based on eventsair function registration id
        List<OpportunityLineItem> lstexistingOlis = [SELECT Id, Function_Registration_Id__c, EventsAir_Regisration_ID__c, OpportunityId
                                                        FROM OpportunityLineItem 
                                                        WHERE Function_Registration_Id__c IN: setOfEvnOLIIds];
        
        // fill the map of eventsAir function registration Id and SF OpportunityLineItem Id
        if(lstexistingOlis.size() > 0) {
            for(OpportunityLineItem existingoli: lstexistingOlis) {
                mapOfEvnOLIandSfId.put(existingoli.Function_Registration_Id__c, existingoli.Id);
            }
        }

        if(!lstInsertOppProduct.isEmpty()) {
            List<OpportunityLineItem> finallisttoinsertoli= new List<OpportunityLineItem>();
            
            for(OpportunityLineItem newoli: lstInsertOppProduct) {
                // check for duplicates and ignor it if found
                if(!mapOfEvnOLIandSfId.containskey(newoli.Function_Registration_Id__c)) {
                    finallisttoinsertoli.add(newoli);
                }
            }
            
            if(finallisttoinsertoli.size() >0) {
                system.debug('Oli'+finallisttoinsertoli.size());
                insert finallisttoinsertoli;
                listOliForLinkOppWithReg.addAll(finallisttoinsertoli);
            }
        }
        // add all the newely created OpportunityLineItems In the list for link them with function registration
        listOliForLinkOppWithReg.addAll(lstexistingOlis);
        UpdateRegistrationsOLI(listOliForLinkOppWithReg);
        
    }

    // Method for link OpportunityLineItem With Registrtion
    public static void UpdateRegistrationsOLI(List<OpportunityLineItem> listOliForLinkOppWithReg){
        
        List<string> LstOfEventsairRegId = new List<string>(); 
        Map<string,OpportunityLineItem> MapOfEventsairRegIdandOLI = new Map<string,OpportunityLineItem>();
        
        for(OpportunityLineItem oli : listOliForLinkOppWithReg){
            LstOfEventsairRegId.add(oli.EventsAir_Regisration_ID__c);
            MapOfEventsairRegIdandOLI.put(oli.EventsAir_Regisration_ID__c,oli);    
        }

        // fetch all function registration with eventsAir function registration Id found in List " LstOfEventsairRegId "
        List<Registration__c> lstOfRegistrationtoLink = [select id,EventsAir_Regisration_ID__c,Opportunity_Product__c from Registration__c where EventsAir_Regisration_ID__c in:LstOfEventsairRegId ];
        
        for(Registration__c reg : lstOfRegistrationtoLink){

            // Linking opportunity and OpportunityLineItem with function registration
            reg.Opportunity_Product__c = MapOfEventsairRegIdandOLI.get(reg.EventsAir_Regisration_ID__c).Id;
            reg.Opportunity__c = MapOfEventsairRegIdandOLI.get(reg.EventsAir_Regisration_ID__c).OpportunityId;
        }
        Database.update(lstOfRegistrationtoLink,false);
        
    }

    // Method to link function with function registrations
    public void LinkFunctionToRegistration(List<Registration__c> lstRegistration) {
        
        Set<String> setOfEventFunId = new Set<String>();
        List<Function__c> lstFunction;
        
        for(Registration__c objReg: lstRegistration) {
            if(objReg.EventsAir_Function_Id__c != null) {
                setOfEventFunId.add(objReg.EventsAir_Function_Id__c);
            }
        }
        if(!setOfEventFunId.isEmpty()) {
            // fetch function records from salesforce
            lstFunction = [SELECT Id, EventsAir_ID__c
                           FROM Function__c
                           WHERE EventsAir_ID__c IN: setOfEventFunId];
        }

        Map<String,Id> mapOfEventFunIdAndFunId = new Map<String, Id>();
        List<Registration__c> lstupdtReg = new List<Registration__c>();
        
        if(lstFunction != null) {
            for(Function__c objFun: lstFunction) {
                mapOfEventFunIdAndFunId.put(objFun.EventsAir_ID__c, objFun.Id);
            }
        }
        
        if(mapOfEventFunIdAndFunId != null) {
            for(Registration__c objReg: lstRegistration) {
                //logic for link function wih function registration record
                if(mapOfEventFunIdAndFunId.containsKey(objReg.EventsAir_Function_Id__c)) {
                    Registration__c reg = new Registration__c();
                    reg.id = objReg.id;
                    reg.Function__c = mapOfEventFunIdAndFunId.get(objReg.EventsAir_Function_Id__c);
                    lstupdtReg.add(reg);
                }                
            }

            if(!lstupdtReg.isEmpty()) {
                update lstupdtReg;
            }
        }
    }
    
    // method to generate  key string(Firstname + Lastname + Email)
    public static string generatestringMethod(string FName, String LName , String email){
        
        string firstName;
        string lastName;
        string eemail;
        string Finalstring;
        
        if(FName != null){
            firstName = FName.trim(); 
        }
        
        if(LName != null){
            lastName = LName.trim();  
        }
        
        if(email != null){
            eemail = email.trim();   
        }
        
        Finalstring = firstName + lastName + eemail;
        
        return Finalstring;
        
    }

    // helper method for create function
    public void setupForFunctionReg(List<Object> lstobject) {
        
        List<Map<String, Object>> listOfFunctioninfomap = new List<Map<String, Object>>();
        
        //loop through event'sair function registration data for setup function start
        for(Object objEventReg: lstobject) {            
            Map<String, Object> eventReg = (Map<String, Object>)objEventReg;            
            Map<String, Object> tempfunmap = (Map<String, Object>)(eventReg.get('function'));            
            listOfFunctioninfomap.add(tempfunmap);            
        }   
        createFunction(listOfFunctioninfomap);
        
    }

    // Method to insert function in salesforce
    public void createFunction(List<Map<String, Object>> listOfFunctioninfomap) {
        
        lstInsrtFun = new List<Function__c>();
        Set<String> setofeventfuncId = new Set<String>();
        Set<String> setofexistfuncId = new Set<String>();
        Map<String,Id> mapOfExistingFunction = new  Map<String,Id>();
        
        // loop through function registration's function records
        for(integer i= 0 ; i< listOfFunctioninfomap.size(); i++) {
            Map<String,object> mapOfFunction = (Map<String,object>)listOfFunctioninfomap[i];
            Function__c func = new Function__c(); 
            if(!setofexistfuncId.contains(func.EventsAir_ID__c)) {
                setofexistfuncId.add(func.EventsAir_ID__c);
            }  
        }

        List<Function__c> LstOfExistingFunc = [SELECT Id,EventsAir_ID__c from Function__c where EventsAir_ID__c In :setofexistfuncId];
        
        for(Function__c func :LstOfExistingFunc){
            mapOfExistingFunction.put(func.EventsAir_ID__c, func.Id);
        }
        
        //get function details from function registration
        for(integer i= 0 ; i< listOfFunctioninfomap.size(); i++) {
            
            Map<String,object> mapOfFunction = (Map<String,object>)listOfFunctioninfomap[i];
            
            Function__c func = new Function__c();
            
            if(mapOfFunction.get('start') != null){

                string Starttime = (string)mapOfFunction.get('start');
                List<String> timeComponents = Starttime.split(':');
                Time StTime = Time.newInstance(Integer.valueOf(timeComponents[0]), Integer.valueOf(timeComponents[1]),0,0);
                func.Function_Start__c = StTime;
            } 

            if(mapOfFunction.get('functionend')!= null){

                string Starttime = (string)mapOfFunction.get('functionend');
                List<String> timeComponents = Starttime.split(':');
                Time endTime = Time.newInstance(Integer.valueOf(timeComponents[0]), Integer.valueOf(timeComponents[1]),0,0);
                func.Function_End__c = endTime;
            } 

            String strFunName = (string)mapOfFunction.get('name');
            if(strFunName.length() <= 80) {
                func.Name = strFunName;    
            } else {
                func.Name = strFunName.substring(0,80);    
            }   
                    
            func.EventsAir_ID__c = (string)mapOfFunction.get('id');
            func.Function_Overview__c = (string)mapOfFunction.get('overview');
            func.Function_Details__c = (string)mapOfFunction.get('details');
            func.Events__c = sfeventId;

            if(mapOfFunction.get('functiondate') != null){

                string funcDate = (string)mapOfFunction.get('functiondate');                
                funcDate = funcDate.trim(); 
                funcDate = funcDate.replaceAll('[^0-9\\-]', ''); 
                Date fnctDate = Date.valueOf(funcDate);
                func.Function_Date__c = fnctDate;
            } 

            if(!setofeventfuncId.contains(func.EventsAir_ID__c)) {
                setofeventfuncId.add(func.EventsAir_ID__c);
                lstInsrtFun.add(func);
            }                
            
        }

        if(!lstInsrtFun.isEmpty()) {
            Database.upsert(lstInsrtFun, Function__c.Fields.EventsAir_ID__c, true);            
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
        if(!test.isrunningtest()) {
            List<Manage_Eventsair_Fun_Reg_Apex_batch__c> lstcustsett2 = [SELECT Id, Name, Offset__c, Is_Execute_Next__c 
                                                                         FROM Manage_Eventsair_Fun_Reg_Apex_batch__c LIMIT 1];            
            // Your finish logic goes here
            if(lstcustsett2[0].Is_Execute_Next__c == true) {
                
                //update offset in custom setting
                lstcustsett2[0].Offset__c = lstcustsett[0].Offset__c + contactsLimit;
                update lstcustsett2;
                
                ImportFuncRegistartionFromEventsAirBatch newBatch = new ImportFuncRegistartionFromEventsAirBatch(strEventId, sfeventId);
                Database.executeBatch(newBatch, 500);
            }
            else {
                lstcustsett2[0].Is_Execute_Next__c = true;
                update lstcustsett2;
                
                System.debug('### sfeventId  = '+sfeventId);
                FeedItem post = new FeedItem();
                post.ParentId = sfeventId; //eg. Opportunity id, custom object id..
                post.Body = 'Apex batch End for fetching function Registration EventsAir Data';
                insert post;                
            }
        } 
        
        
    }
}