public class ImportRegSeprateSecAndInteBatch implements Database.Batchable<ResponseWrapper>, Database.AllowsCallouts {
    //variable declartion
    public String strEventId;
    public String sfeventId;
    public String eventCategory;
    Integer contactsLimit = Integer.valueOf(System.Label.EventsAir_Attendee_Contact_Limit);
    Integer regLimit = Integer.valueOf(System.Label.EventsAir_Registartion_Limit);
    List<Contact> lstInsrtCon;
    List<Contact> lstUpdateCon;
    List<Lead> lstInsrtLead;
    List<Lead> lstUpdateLead;
    List<Product_Service_Option__c> lstInsrtProdAndServices;
    public List<Event__c> eventData = new List<Event__c>();
    Map<String, Id> mapOfLeadStringAndId = new Map<String, Id>();
    Map<String, Id> mapOfContactStringAndId = new Map<String, Id>();
    Set<String> setofProductId = new Set<String>();
    Map<String, Id> mapOfEvnproandSfId = new Map<String, Id>();
    Map<String, String> selectedValuesMap = new Map<String, String>();
    Map<String, Id> mapOfEventRegTypeIdAndSFPBentryId = new Map<String, Id>();
    public String RecordType;
    private static Set<String> leadOrganisationTypeValues;
    private static Set<String> contactOrganisationTypeValues;
    
    //fetch current offset value from custom setting
    List<Manage_Eventsair_Sec_And_Int_Reg_batch__c> lstcustsett = [SELECT Id, Name, Offset__c, Is_Execute_Next__c,Generic_Email_Domains__c 
                                                                   FROM Manage_Eventsair_Sec_And_Int_Reg_batch__c LIMIT 1];
    public ImportRegSeprateSecAndInteBatch() {
    }
    public ImportRegSeprateSecAndInteBatch(String strsfeventId ) {        
        this.eventData = [SELECT Id, Name, Open_Date__c, New_Event_Logo__c, Is_Pricebook_Created__c, Registration_Types__c, Event_Category__c, EventsAirID__c, Close_Date__c, Next_Date__c, RecordType.Name FROM Event__c WHERE Id =:strsfeventId AND Registration_Types__c != null
                          AND EventsAirID__c != null limit 1 ];
        if (eventData != null && eventData.size() > 0) {
            
            sfeventId = strsfeventId;
            strEventId = eventData[0].EventsAirID__c;
            RecordType = eventData[0].RecordType.Name;
            
            if(eventData[0].Event_Category__c != null){
                eventCategory = eventData[0].Event_Category__c; 
            }
        }
    }
    
    public Iterable<ResponseWrapper> start(Database.BatchableContext BC) {  
        
        String graphqlQuery;
        String strtoken;
        
        // Get the OAuth token for the API based on the record type
        if (RecordType != null) {
            strtoken = EventsAirOAuthTokenRequest.getAccessToken(RecordType);
        } 
        
        // Prepare the GraphQL query based on the record type
        String commonQueryTemplate = '{' +
            '"query": "query GetEventData($eventId: ID!, $contactsLimit: PaginationLimit!, $conoffset: NonNegativeInt!, $regLimit: PaginationLimit!${customFieldParam}) {' +
            'event(id: $eventId) {' +
            'id,' +
            'name,' +
            'startDate,' +
            'endDate,' + 
            'logo{' +
            'url,' +
            '},' + 
            'contacts(offset: $conoffset, limit: $contactsLimit) { ' +
            '${customFieldsSection}' + // Placeholder for custom fields
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
            'jobTitle,' +
            'lastModifiedAt,' +
            'organizationName,' +
            'checkInDate,' +
            'checkOutDate,' +
            'primaryEmail,' +
            'workPhone,' +
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
            'registrations(limit: $regLimit) {' +
            'id,' +
            'dateTime,' +   
            'type {' +
            'id,' +
            'name,' +   
            'uniqueCode,' + 
            'fees {' +
            'amount,' +      
            '},' +
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
            '},' +            
            '}' +
            '}' +
            '}",' +
            '"variables": {' +
            '"eventId": "' + strEventId + '",' +
            '"contactsLimit": ' + contactsLimit + ',' +
            '"conoffset": ' + lstcustsett[0].Offset__c + ',' +
            '"regLimit": ' + regLimit +
            '${customVariables}' + // Placeholder for custom variables
            '}' +
            '}';
        
        String customFieldsSection = '';
        String customFieldParam = '';
        String customVariables = '';
        
        if (RecordType != 'Mumbrella') {
            customFieldParam = ', $input: CustomFieldSearchFilterInput!';
            customFieldsSection = 'customFields(input: $input , limit:10){name, definitionId, type, value},';
            /*if (eventCategory == 'Security') {
                customVariables = ', "input": { "names": ["Industry SEC" , "Job Function SEC" , "Company Size"] }';
            } else if (eventCategory == 'Integrate') {
                customVariables = ', "input": { "names": ["Industry INT" , "Job Function INT" , "Company Size"] }';
            }else if (eventCategory == 'Fire') {
                customVariables = ', "input": { "names": ["Industry FIRE" , "Job Function FIRE" , "Company Size"] }';
            }else {
                customVariables = ', "input": { "names": ["Industry SEC" , "Job Function SEC" , "Company Size"] }';
            } */
            
            customVariables = ', "input": { "names": [' +
                '"Industry SEC", ' +
                '"Job Function SEC", ' +
                '"Industry INT", ' +
                '"Job Function INT", ' +
                '"Industry FIRE", ' +
                '"Job Function FIRE", ' +
                '"Company Size", ' +
                '"Organisation Type SEC", ' +
                '"Organisation Type INT", ' +
                '"Organisation Type FIRE"' +
                '] }';
        }
        
        // Replace placeholders in the template
        graphqlQuery = commonQueryTemplate.replace('${customFieldParam}', customFieldParam).replace('${customFieldsSection}', customFieldsSection).replace('${customVariables}', customVariables);
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(120000);
        request.setEndpoint(System.Label.EventsAir_API_Base_URL);
        request.setMethod('POST');
        request.setBody(graphqlQuery);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + strtoken);
        
        // Send the HTTP request
        HttpResponse response = http.send(request);
        System.debug('@@@@ response = ' + response.getBody());
        
        List<ResponseWrapper> lstofresponseWrapper = new List<ResponseWrapper>();
        ResponseWrapper responseWrapper = new ResponseWrapper();
        
        if (response.getStatusCode() == 200) {
            
            String responseBody = response.getBody(); 
            responseBody = responseBody.replace('"dateTime"', '"registrationDateTime"');
            responseBody = responseBody.replace('"date"', '"functiondate"');
            responseBody = responseBody.replace('"end"', '"functionend"');
            
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
        
        return lstofresponseWrapper;
    }

    @TestVisible
    private static void applyOrganisationType(Contact contactRecord, String eventsAirFieldName, Object rawValue) {
        String organisationType = getOrganisationType(eventsAirFieldName, rawValue);
        if (organisationType != null && getContactOrganisationTypeValues().contains(organisationType)) {
            contactRecord.Organisation_Type__c = organisationType;
        }
    }

    @TestVisible
    private static void applyOrganisationType(Lead leadRecord, String eventsAirFieldName, Object rawValue) {
        String organisationType = getOrganisationType(eventsAirFieldName, rawValue);
        if (organisationType != null && getLeadOrganisationTypeValues().contains(organisationType)) {
            leadRecord.Organisation_Type__c = organisationType;
        }
    }

    private static String getOrganisationType(String eventsAirFieldName, Object rawValue) {
        if (rawValue == null) {
            return null;
        }

        Set<String> supportedFieldNames = new Set<String>{
            'Organisation Type',
            'Organisation Type FIRE',
            'Organisation Type INT',
            'Organisation Type SEC'
        };
        if (!supportedFieldNames.contains(eventsAirFieldName)) {
            return null;
        }

        String organisationType = String.valueOf(rawValue).trim();
        return String.isBlank(organisationType) ? null : organisationType;
    }

    private static Set<String> getLeadOrganisationTypeValues() {
        if (leadOrganisationTypeValues == null) {
            leadOrganisationTypeValues = getActivePicklistValues(Lead.Organisation_Type__c);
        }
        return leadOrganisationTypeValues;
    }

    private static Set<String> getContactOrganisationTypeValues() {
        if (contactOrganisationTypeValues == null) {
            contactOrganisationTypeValues = getActivePicklistValues(Contact.Organisation_Type__c);
        }
        return contactOrganisationTypeValues;
    }

    private static Set<String> getActivePicklistValues(Schema.SObjectField fieldToken) {
        Set<String> values = new Set<String>();
        for (Schema.PicklistEntry picklistEntry : fieldToken.getDescribe().getPicklistValues()) {
            if (picklistEntry.isActive()) {
                values.add(picklistEntry.getValue());
            }
        }
        return values;
    }

    private void applyIndustryAndJobFunction(Contact contactRecord, String eventsAirFieldName, Object rawValue) {
        String fieldValue = getCustomFieldValue(rawValue);
        if (fieldValue == null) {
            return;
        }

        if (isIndustryField(eventsAirFieldName) && shouldApplyEventCategoryField(eventsAirFieldName, contactRecord.Industry__c)) {
            contactRecord.Industry__c = fieldValue;
        }
        if (isJobFunctionField(eventsAirFieldName) && shouldApplyEventCategoryField(eventsAirFieldName, contactRecord.Job_Function__c)) {
            contactRecord.Job_Function__c = fieldValue;
        }
    }

    private void applyIndustryAndJobFunction(Lead leadRecord, String eventsAirFieldName, Object rawValue) {
        String fieldValue = getCustomFieldValue(rawValue);
        if (fieldValue == null) {
            return;
        }

        if (isIndustryField(eventsAirFieldName) && shouldApplyEventCategoryField(eventsAirFieldName, leadRecord.Industry__c)) {
            leadRecord.Industry__c = fieldValue;
        }
        if (isJobFunctionField(eventsAirFieldName) && shouldApplyEventCategoryField(eventsAirFieldName, leadRecord.Job_Function__c)) {
            leadRecord.Job_Function__c = fieldValue;
        }
    }

    private static String getCustomFieldValue(Object rawValue) {
        if (rawValue == null) {
            return null;
        }

        String fieldValue = String.valueOf(rawValue).trim();
        return String.isBlank(fieldValue) ? null : fieldValue;
    }

    private static Boolean isIndustryField(String eventsAirFieldName) {
        return eventsAirFieldName == 'Industry SEC'
            || eventsAirFieldName == 'Industry INT'
            || eventsAirFieldName == 'Industry FIRE';
    }

    private static Boolean isJobFunctionField(String eventsAirFieldName) {
        return eventsAirFieldName == 'Job Function SEC'
            || eventsAirFieldName == 'Job Function INT'
            || eventsAirFieldName == 'Job Function FIRE';
    }

    private Boolean shouldApplyEventCategoryField(String eventsAirFieldName, String currentValue) {
        return String.isBlank(currentValue) || isPreferredEventCategoryField(eventsAirFieldName);
    }

    private Boolean isPreferredEventCategoryField(String eventsAirFieldName) {
        if (eventCategory == 'Security') {
            return eventsAirFieldName == 'Industry SEC' || eventsAirFieldName == 'Job Function SEC';
        }
        if (eventCategory == 'Integrate') {
            return eventsAirFieldName == 'Industry INT' || eventsAirFieldName == 'Job Function INT';
        }
        if (eventCategory == 'Fire') {
            return eventsAirFieldName == 'Industry FIRE' || eventsAirFieldName == 'Job Function FIRE';
        }
        return false;
    }

    @TestVisible
    private static void applyAddressFields(Contact contactRecord, Map<String, Object> eventContactMap) {
        Map<String, Object> eventAddressMap = getEventAddressMap(eventContactMap);
        if (eventAddressMap == null || !areCoreAddressFieldsBlank(contactRecord)) {
            return;
        }

        contactRecord.MailingCountry = getCustomFieldValue(eventAddressMap.get('country'));
        contactRecord.MailingState = getCustomFieldValue(eventAddressMap.get('state'));
    }

    @TestVisible
    private static void applyAddressFields(Lead leadRecord, Map<String, Object> eventContactMap) {
        Map<String, Object> eventAddressMap = getEventAddressMap(eventContactMap);
        if (eventAddressMap == null || !areCoreAddressFieldsBlank(leadRecord)) {
            return;
        }

        leadRecord.Country = getCustomFieldValue(eventAddressMap.get('country'));
        leadRecord.State = getCustomFieldValue(eventAddressMap.get('state'));
    }

    private static Boolean areCoreAddressFieldsBlank(Contact contactRecord) {
        return String.isBlank(contactRecord.MailingStreet)
            && String.isBlank(contactRecord.MailingCity)
            && String.isBlank(contactRecord.MailingPostalCode);
    }

    private static Boolean areCoreAddressFieldsBlank(Lead leadRecord) {
        return String.isBlank(leadRecord.Street)
            && String.isBlank(leadRecord.City)
            && String.isBlank(leadRecord.PostalCode);
    }

    private static Map<String, Object> getEventAddressMap(Map<String, Object> eventContactMap) {
        Object eventAddress = eventContactMap.get('primaryAddress');
        return eventAddress == null ? null : (Map<String, Object>) eventAddress;
    }

    public void execute(Database.BatchableContext BC, List<ResponseWrapper> responseWrapper) {
        system.debug('responseWrapper-->'+responseWrapper);
        // Serialize the ResponseWrapper to a JSON string
        String serializedResponseWrapper;
        Map<String, Object> jsonResponse;
        Map<String, Object> eventDatamap;
        
        try{   
            System.debug('@@@ eventData = '+eventData);
            if(eventData.size() > 0) {
                if (String.isNotBlank(eventData[0].Registration_Types__c)) {
                    List<String> selectedValues = eventData[0].Registration_Types__c.split(';');
                    for (String value : selectedValues) {
                        selectedValuesMap.put(value, value);
                    }
                }
            }
            
            if (responseWrapper.size() > 0) {
                serializedResponseWrapper = JSON.serialize(responseWrapper[0]);
                jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(serializedResponseWrapper);
                system.debug('jsonResponse-->'+jsonResponse);
            }
            system.debug('eventDatamap -->'+eventDatamap);
            if (jsonResponse != null) {
                // Extract the 'data' map from the JSON response
                if (jsonResponse.containsKey('data') && jsonResponse.get('data') != null) {
                    eventDatamap = (Map<String, Object>) jsonResponse.get('data');
                    system.debug('eventDatamap inside if-->'+eventDatamap);
                }
            }     
            Map<String, Object> eventmap;
            if(eventDatamap != null) {
                eventmap = (Map<String, Object>) eventDatamap.get('event');   
            }
            
            // Initialize lists to update events and insert pricebooks
            List<Event__c> updteventlst = new List<Event__c>(); 
            List<Pricebook2> lstInsrtPricebook = new List<Pricebook2>();
            
            // Extract event-related data from the event map
            String evtStartDate = (String) eventmap.get('startDate');
            String evtCloseDate = (String) eventmap.get('endDate');
            Map<String, Object> logoMap = (Map<String, Object>) eventmap.get('logo');
            String evtLogo = logoMap != null ? (String) logoMap.get('url') : null;
            
            // Set the values on event fields
            if (eventmap != null && !eventData.isEmpty()) { 
                
                // Query for existing pricebooks associated with the event
                List<Pricebook2> lstPriceook = [SELECT Id FROM Pricebook2 WHERE Events__c =: sfeventId LIMIT 50000];
                
                for (Event__c eventRec : eventData) {
                    
                    // Check if the pricebook is already created or missing and needs to be created
                    if(eventRec.Is_Pricebook_Created__c == false || (eventRec.Is_Pricebook_Created__c == true && lstPriceook.size() == 0)) {
                        
                        // Create a new Pricebook2 record
                        Pricebook2 newPricebook = new Pricebook2();
                        newPricebook.Name = (String) eventmap.get('name') + ' Visitor'; 
                        newPricebook.Events__c = eventRec.Id;
                        newPricebook.Description = 'Description of the pricebook'; 
                        newPricebook.IsActive = true; // Set the pricebook as active
                        lstInsrtPricebook.add(newPricebook);
                        
                        // Mark the event as having its pricebook created
                        eventRec.Is_Pricebook_Created__c = true;
                    }
                    
                    if(evtLogo != null) {
                        eventRec.Event_Logo__c = evtLogo;
                    } 
                    
                    if (evtStartDate != null) {
                        eventRec.Open_Date__c = (Datetime) JSON.deserialize('"' + evtStartDate + '"', Datetime.class);     
                    }
                    
                    if (evtCloseDate != null) {
                        eventRec.Close_Date__c = (Datetime) JSON.deserialize('"' + evtCloseDate + '"', Datetime.class);     
                    } 
                    updteventlst.add(eventRec);
                }
            }
            
            //update event list
            if (!updteventlst.isEmpty()) {     
                update updteventlst;              
            }  
            
            // Insert new pricebooks
            if(!lstInsrtPricebook.isEmpty()) {
                insert lstInsrtPricebook;
            }
            
            List<Object> lsteventsairContacts = new List<Object>();
            if(eventmap != null){
                lsteventsairContacts = (List<Object>) eventmap.get('contacts');
            }
            
            if(lsteventsairContacts.size() > 0) {
                createRecords(lsteventsairContacts);
            }
            
            if(lsteventsairContacts.isEmpty()) {
                System.debug('@@@ All Data Synced');
                lstcustsett[0].Is_Execute_Next__c = false;
                lstcustsett[0].Offset__c = 0;
                update lstcustsett;
            }
            
        }catch(Exception e) {
            System.debug('ERROR==>'+ e.getMessage());
            FeedItem post = new FeedItem();
            post.ParentId = sfeventId; //eg. Opportunity id, custom object id..
            post.Body = 'Unable to import Registrations For Security And Integrate Seperate \nError: '+e.getMessage();
            insert post;    
        }           
    }
    
    public void createRecords(List<Object> lsteventsairContacts) {
        // Lists to store records for insertion
        lstInsrtLead = new List<Lead>();
        lstUpdateLead = new List<Lead>();
        lstInsrtCon = new List<Contact>();
        lstUpdateCon = new List<Contact>();
        lstInsrtProdAndServices = new List<Product_Service_Option__c>();
        
        // Sets and Maps for handling domain names and account information 
        Set<String> setOfDomainNames = new Set<String>();
        Set<String> setOfOrgNames = new Set<String>();
        Set<String> paidAccountNames= new Set<String>();
        Set<String> setOfCombinedEventsAirAttendee = new Set<String>(); 
        Map<String, String> accountNameMap = new Map<String, String>();
        Map<String, Id> mapOfDomainNameAndAccId = new Map<String, Id>();
        Map<String, Id> mapOfDomainNameAndAccOwnerId = new Map<String, Id>();
        
        Set<String> setOfGenericDomain = new Set<String>();
        if (lstcustsett.size() > 0 && lstcustsett[0].Generic_Email_Domains__c != null && lstcustsett[0].Generic_Email_Domains__c != '') {
            setOfGenericDomain = new Set<String>(lstcustsett[0].Generic_Email_Domains__c.split(','));
        }
        // Loop through event contacts to process email domain and organization names
        for (Object objEventCon : lsteventsairContacts) {
            Map<String, Object> eventConMap = (Map<String, Object>) objEventCon;
            String email = (String) eventConMap.get('primaryEmail');
            String orgName = (String) eventConMap.get('organizationName');
            List<Object> lsteventsairReg = (List<Object>) eventConMap.get('registrations');
            String domainName = '';
            Boolean hasPaidRegistration = false;
            
            String CombinedString = getCombinedString(objEventCon);
            setOfCombinedEventsAirAttendee.add(CombinedString);
            // Extract domain from email
            if (email != null && email != '') {
                String[] emailParts = email.split('@');
                if (emailParts.size() > 1) {
                    domainName = emailParts[1].trim().toLowerCase();
                    setOfDomainNames.add(domainName);
                    
                    if(orgName == null || orgName == '') {
                        orgName = domainName;
                    }
                }
            }
            
            // Trim organization name if it exceeds 80 characters
            if (orgName != null && orgName != '') {
                orgName = orgName.length() > 80 ? orgName.substring(0, 80) : orgName;
                setOfOrgNames.add(orgName.toLowerCase());
            }
            
            // Check if registration has been paid
            if (lsteventsairReg != null && lsteventsairReg.size() > 0) {
                for (Object objEventReg : lsteventsairReg) {
                    Map<String, Object> eventReg = (Map<String, Object>) objEventReg;
                    Map<String, Object> paymentDetails = (Map<String, Object>) eventReg.get('paymentDetails');
                    Decimal totalCharge = (Decimal) paymentDetails.get('totalChargeAmount');
                    
                    if (totalCharge != null && totalCharge > 0) {
                        hasPaidRegistration = true;
                        break;
                    }
                }
            }
            
            // Determine account name and track unpaid registrations
            String accountName = (orgName != null && orgName != '') ? orgName : domainName;
            if (accountName != null) {
                accountNameMap.put(accountName, domainName);
                if (hasPaidRegistration) {
                    paidAccountNames.add(accountName.toLowerCase());
                }
            }
        }
        
        // retrive existing Account based on domain name and organization name And fill set to exclude it from create new
        Set<String> setOfExistingAccountNameAndDomain = new Set<String>();
        for (Account acc : [SELECT Name, Domain_Name__c FROM Account 
                            WHERE (Domain_Name__c IN :setOfDomainNames OR Name IN :setOfOrgNames) 
                            AND Account_Status__c != 'Inactive' AND On_Hold__c = FALSE LIMIT 50000]) {
                                if (acc.Domain_Name__c != null) {
                                    setOfExistingAccountNameAndDomain.add(acc.Domain_Name__c.toLowerCase());
                                }
                                if (acc.Name != null) {
                                    setOfExistingAccountNameAndDomain.add(acc.Name.toLowerCase());
                                }
                            }
        
        // Create accounts for paid registartion
        List<Account> listAccPreCreate = new List<Account>();
        for (String accName : accountNameMap.keySet()) {
            String newDomain = accountNameMap.get(accName);
            if(!setOfGenericDomain.contains(newDomain)) {
                
                if ((!setOfExistingAccountNameAndDomain.contains(newDomain.toLowerCase()) && !setOfExistingAccountNameAndDomain.contains(accName.toLowerCase())) 
                    && paidAccountNames.contains(accName.toLowerCase())) {
                        Account newAccount = new Account();
                        newAccount.RecordTypeId = (RecordType == 'Mumbrella') ? 
                            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mumbrella').getRecordTypeId() : 
                        Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Diversified').getRecordTypeId();
                        newAccount.Domain_Name__c = accountNameMap.get(accName);
                        newAccount.AccountSource = 'EventsAir';
                        newAccount.Name = accName;
                        listAccPreCreate.add(newAccount);
                    }
            }else {
                System.debug('Generic Domain Name found in the list');
                if (!setOfExistingAccountNameAndDomain.contains(accName.toLowerCase())
                    && paidAccountNames.contains(accName.toLowerCase())) {
                    Account newAccount = new Account();
                    newAccount.RecordTypeId = (RecordType == 'Mumbrella') ? 
                        Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mumbrella').getRecordTypeId() : 
                    Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Diversified').getRecordTypeId();
                    newAccount.Domain_Name__c = accountNameMap.get(accName);
                    newAccount.AccountSource = 'EventsAir';
                    newAccount.Name = accName;
                    listAccPreCreate.add(newAccount);
                    
                }
            }
        }
        
        // Step 4: Insert new accounts
        if (!listAccPreCreate.isEmpty()) {
            insert listAccPreCreate;
            System.debug('Accounts Inserted Successfully: ' + listAccPreCreate.size());
        }
        
        // if domain not match, check for account name and create map for account name with account Id
        Map<String, Id> MapOfexistingAccountsOrgNameAndAccountId = new Map<String, Id>();
        if (setOfOrgNames != null) {
            
            List<Account> exitingAccListOfOrgNames = [SELECT Id,Name,Domain_Name__c From Account Where Name IN :setOfOrgNames
                                                      AND Account_Status__c != 'Inactive' and On_Hold__c = false LIMIT 50000];
            
            for (Account acct : exitingAccListOfOrgNames) {
                // map of organization name and accountId based on organization name for mapping with contact
                MapOfexistingAccountsOrgNameAndAccountId.put(acct.Name.toLowerCase(),acct.Id);
            }
        }
        
        //if set contains any value then do soql on account and fill the mapOfDomainNameAndAccId Map
        if(setOfDomainNames != null) {
            
            for (AggregateResult aggregateResult : [
                SELECT MAX(CreatedDate) latestCreatedDate, Domain_Name__c, MAX(Id) accountId, MAX(OwnerId) ownerId
                FROM Account
                WHERE Domain_Name__c IN: setOfDomainNames and Account_Status__c != 'Inactive' and On_Hold__c = false
                GROUP BY Domain_Name__c
                LIMIT 50000
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
        
        Map<String, Id> mapOfLeadStringAndConvertedContactId = new Map<String, Id>();
        Map<Id, String> convertedContactIdToLeadString = new Map<Id, String>();
        Set<Id> convertedContactIds = new Set<Id>();

        // fetch Leads once; converted Leads only provide converted Contact, open Leads remain import candidates
        List<Lead> listOfAllLead = [SELECT Id, RecordTypeId, Title, Company , Industry__c, Job_Function__c, Company_Size__c, FirstName, LastName , Email, CombinedString__c, PostalCode, State, Country, Street, City, IsConverted, ConvertedContactId FROM Lead
                                    WHERE CombinedString__c in :setOfCombinedEventsAirAttendee LIMIT 50000];
        Map<String, Boolean> mapOfUniqueLeadString = new Map<String, Boolean>();
        Map<String, Lead> mapOfUniqueLeadStringToUpdate = new Map<String, Lead>();

        //loop through existing Leads and fill the map to use for mapping with registration
        for(Lead objLead :listOfAllLead){
            if (objLead.IsConverted && objLead.ConvertedContactId != null) {
                mapOfLeadStringAndConvertedContactId.put(objLead.CombinedString__c, objLead.ConvertedContactId);
                convertedContactIdToLeadString.put(objLead.ConvertedContactId, objLead.CombinedString__c);
                convertedContactIds.add(objLead.ConvertedContactId);
            } else if (!objLead.IsConverted) {
                mapOfUniqueLeadString.put(objLead.CombinedString__c, true);
                mapOfUniqueLeadStringToUpdate.put(objLead.CombinedString__c, objLead);
            }
        }

        // fetch Contacts once; includes direct matches and converted Lead contacts
        List<Contact> listOfAllContact = [SELECT Id, AccountId, RecordTypeId, Title, Organization_Name__c, Industry__c, Job_Function__c, Company_Size__c, FirstName, LastName, Email, CombinedString__c, MailingCity, MailingCountry, MailingState, MailingStreet, MailingPostalCode, EventsAir_Con_ID__c FROM Contact
                                          WHERE CombinedString__c in :setOfCombinedEventsAirAttendee
                                          OR Id IN :convertedContactIds LIMIT 50000];
        Map<String, Boolean> mapOfUniqueContactString = new Map<String, Boolean>();
        Map<String, Contact> mapOfUniqueContactStringToUpdate = new Map<String, Contact>();

        //loop through existing Contacts and fill the map to use for mapping with registration
        for(Contact objContact :listOfAllContact){
            String contactCombinedString = objContact.CombinedString__c;
            if (String.isBlank(contactCombinedString)) {
                contactCombinedString = convertedContactIdToLeadString.get(objContact.Id);
            }

            if (String.isNotBlank(contactCombinedString)) {
                mapOfUniqueContactString.put(contactCombinedString, true);
                mapOfUniqueContactStringToUpdate.put(contactCombinedString, objContact);
            }

            String existingContactKey = buildContactKey(objContact);
            if (String.isNotBlank(existingContactKey)) {
                mapOfUniqueContactString.put(existingContactKey, true);
            }
        }

        Map<String, Id> leadStringToAccountIdForConversion = new Map<String, Id>();
        
        // loop through event's air contact for create Lead/Contact based on Paid/Unpaid registrations
        for (Object objEventCon : lsteventsairContacts) {
            
            Map<String, Object> eventConMap = (Map<String, Object>) objEventCon;
            String email = (String) eventConMap.get('primaryEmail');           
            String strAccdomainname;
            String orgName = (String) eventConMap.get('organizationName');
            List<Object> lsteventsairReg = (List<Object>) eventConMap.get('registrations');
            String CombinedString = getCombinedString(objEventCon);
            
            //extract domain name from contact's email
            if(email != null && email != '') {
                String[] emailparts = email.split('@');
                if (emailparts.size() > 1) {
                    strAccdomainname = emailparts[1].trim().toLowerCase();
                }
            }
            if(orgName != null && orgName != ''){
                if (orgName.length() > 80) {
                    orgName = orgName.substring(0, 80).toLowerCase();    
                } else{
                    orgName = orgName.toLowerCase();
                }
            }else {
                if (strAccdomainname != '' && strAccdomainname != null) {
                    orgName = strAccdomainname.toLowerCase();
                }else {
                    System.debug('Organization Name and domain both are null which is not preferable for con');
                }
            }
            
            if(lsteventsairReg != null && lsteventsairReg.size() > 0){
                //loop through contact's eventsAir registration data
                for(Object reg : lsteventsairReg) {
                    
                    Map<String, Object> eventReg = (Map<String, Object>) reg;
                    Map<String, Object> eventregPaymentdetails = (Map<String, Object>) eventReg.get('paymentDetails');
                    Decimal totalcharge = (Decimal) eventregPaymentdetails.get('totalChargeAmount');
                    
                    Id matchedAccountId = getMatchedAccountId(strAccdomainname, orgName, mapOfDomainNameAndAccId, MapOfexistingAccountsOrgNameAndAccountId);
                    // update existing contact for paid registrations; otherwise use/create a Lead
                    if (totalcharge > 0 && mapOfUniqueContactStringToUpdate.containsKey(CombinedString)) {
                        // update contact for paid function registration
                        Contact objCon = mapOfUniqueContactStringToUpdate.get(CombinedString);
                        objCon.EventsAir_Con_ID__c = (String) eventConMap.get('id');
                        if (objCon.AccountId == null && matchedAccountId != null) {
                            objCon.AccountId = matchedAccountId;
                        }

                        if (objCon.Organization_Name__c == null || objCon.Organization_Name__c == '') {
                            objCon.Organization_Name__c = (String) eventConMap.get('organizationName');
                        }
                        if (objCon.Title == null || objCon.Title == '') {
                            String strjobTitle = (String) eventConMap.get('jobTitle');
                            if(strjobTitle == null || strjobTitle == '' ) {
                                objCon.Title = 'UnKnown';
                            } else {
                                objCon.Title = strjobTitle.trim();
                            }
                        }
                        
                        if (RecordType != 'Mumbrella') {
                            List<Object> lsteventsairCustomFields = (List<Object>) eventConMap.get('customFields');
                            for (Object fields : lsteventsairCustomFields) {
                                Map<String, Object> customFieldsMap = (Map<String, Object>) fields;
                                String FieldName = (String) customFieldsMap.get('name');
                                if (FieldName != '' && FieldName != null) {

                                    applyIndustryAndJobFunction(objcon, FieldName, customFieldsMap.get('value'));
                                    if(FieldName == 'Company Size'){
                                        objcon.Company_Size__c = (String) customFieldsMap.get('value');
                                    }
                                    applyOrganisationType(objcon, FieldName, customFieldsMap.get('value'));
                                }
                            }
                        }
                        
                        applyAddressFields(objcon, eventconmap);
                        lstupdateCon.add(objCon);

                    } else if(totalcharge > 0 && !mapOfUniqueContactString.containsKey(CombinedString) && mapOfUniqueLeadStringToUpdate.containsKey(CombinedString)) {
                        Lead newLead = mapOfUniqueLeadStringToUpdate.get(CombinedString);

                        if (newLead.Company == null || newLead.Company == '') {
                            newLead.Company = (String) eventConMap.get('organizationName');
                        }
                        if (newLead.Title == null || newLead.Title == '') {
                            String strjobTitle = (String) eventConMap.get('jobTitle');
                            if(strjobTitle == null || strjobTitle == '' ) {
                                newLead.Title = 'UnKnown';
                            } else {
                                newLead.Title = strjobTitle.trim();
                            }
                        }
                        
                        if (RecordType != 'Mumbrella') {
                            List<Object> lsteventsairCustomFields = (List<Object>) eventConMap.get('customFields');
                            for (Object fields : lsteventsairCustomFields) {
                                Map<String, Object> customFieldsMap = (Map<String, Object>) fields;
                                String FieldName = (String) customFieldsMap.get('name');
                                if (FieldName != '' && FieldName != null) {

                                    applyIndustryAndJobFunction(newLead, FieldName, customFieldsMap.get('value'));
                                    if(FieldName == 'Company Size'){
                                        newLead.Company_Size__c = (String) customFieldsMap.get('value');
                                    }
                                    applyOrganisationType(newLead, FieldName, customFieldsMap.get('value'));
                                }
                            }
                        }

                        applyAddressFields(newLead, eventconmap);
                        lstupdateLead.add(newLead);
                        if (matchedAccountId != null) {
                            leadStringToAccountIdForConversion.put(CombinedString, matchedAccountId);
                        }

                    } else if(totalcharge > 0 && !mapOfUniqueContactString.containsKey(CombinedString) && !mapOfUniqueLeadString.containsKey(CombinedString)) {
                        Contact newContact = buildPaidContact(eventConMap, eventconmap, matchedAccountId);
                        lstInsrtCon.add(newContact);

                    } else if(!mapOfUniqueContactString.containsKey(CombinedString) && !mapOfUniqueLeadString.containsKey(CombinedString)){
                        
                        //lead field mapping
                        Lead newLead = new Lead();
                        newLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Visitor').getRecordTypeId();
                        
                        String strFirstName = (String) eventConMap.get('firstName');
                        if (strFirstName != null )  {
                            if(strFirstName.length() <= 40) {
                                newLead.FirstName= strFirstName.trim();
                            } else {
                                newLead.FirstName = strFirstName.substring(0,40).trim();
                            }
                        } else {
                            strFirstName = ''; 
                        }
                        
                        String strLastName = (String) eventConMap.get('lastName');
                        if(strLastName == null || strLastName == '' ) {
                            newLead.LastName = 'UnKnown';
                        } else {
                            newLead.LastName = strLastName.trim();
                        }
                        
                        String strjobTitle = (String) eventConMap.get('jobTitle');
                        if(strjobTitle == null || strjobTitle == '' ) {
                            newLead.Title = 'UnKnown';
                        } else {
                            newLead.Title = strjobTitle.trim();
                        }
                        
                        //newLead.EventsAir_Contact_Id__c = (String) eventConMap.get('id');
                        String stremail = (String) eventConMap.get('primaryEmail');
                        if(stremail != null && stremail != '') {
                            stremail = stremail.trim();
                            newLead.Email = stremail;
                        } else {
                            newLead.Email = '';
                        }

                        String strWorkPhone = (String) eventConMap.get('workPhone');
                        if(strWorkPhone != null && strWorkPhone != '') {
                            strWorkPhone = strWorkPhone.trim();
                            newLead.MobilePhone = strWorkPhone;
                            newLead.Phone = strWorkPhone;
                        }

                        newLead.Event_Category__c = eventCategory;
                        
                        if (RecordType == 'Mumbrella') {
                            newLead.Business_Unit__c = 'Mumbrella';
                        } else {
                            List<Object> lsteventsairCustomFields = (List<Object>) eventConMap.get('customFields');
                            
                            for (Object fields : lsteventsairCustomFields) {
                                Map<String, Object> customFieldsMap = (Map<String, Object>) fields;
                                String FieldName = (String) customFieldsMap.get('name');
                                if (FieldName != '' && FieldName != null) {

                                    applyIndustryAndJobFunction(newLead, FieldName, customFieldsMap.get('value'));
                                    if(FieldName == 'Company Size'){
                                        newLead.Company_Size__c = (String) customFieldsMap.get('value');
                                    }
                                    applyOrganisationType(newLead, FieldName, customFieldsMap.get('value'));
                                }
                            }
                            newLead.Business_Unit__c = 'Divcom';
                            
                        }
                        
                        String strOrganization = (String) eventConMap.get('organizationName');
                        if(strOrganization != null && strOrganization != '') {
                            newLead.Company = strOrganization;
                        }
                        else{
                            newLead.Company = 'Unknown';
                        }
                        
                        newLead.Status = 'New';

                        applyAddressFields(newLead, eventconmap);
                        lstInsrtLead.add(newLead);
                        
                    } else if(!mapOfUniqueContactString.containsKey(CombinedString) && mapOfUniqueLeadStringToUpdate.containsKey(CombinedString)) {
                        // update lead for unpaid function registration
                        Lead newLead = mapOfUniqueLeadStringToUpdate.get(CombinedString);
                        
                        if (newLead.Company == null || newLead.Company == '') {
                            newLead.Company = (String) eventConMap.get('organizationName');
                        }
                        if (newLead.Title == null || newLead.Title == '') {
                            String strjobTitle = (String) eventConMap.get('jobTitle');
                            if(strjobTitle == null || strjobTitle == '' ) {
                                newLead.Title = 'UnKnown';
                            } else {
                                newLead.Title = strjobTitle.trim();
                            }
                        }
                        
                        if (RecordType != 'Mumbrella') {
                            List<Object> lsteventsairCustomFields = (List<Object>) eventConMap.get('customFields');
                            for (Object fields : lsteventsairCustomFields) {
                                Map<String, Object> customFieldsMap = (Map<String, Object>) fields;
                                String FieldName = (String) customFieldsMap.get('name');
                                if (FieldName != '' && FieldName != null) {

                                    applyIndustryAndJobFunction(newLead, FieldName, customFieldsMap.get('value'));
                                    if(FieldName == 'Company Size'){
                                        newLead.Company_Size__c = (String) customFieldsMap.get('value');
                                    }
                                    applyOrganisationType(newLead, FieldName, customFieldsMap.get('value'));
                                }
                            }
                        }

                        applyAddressFields(newLead, eventconmap);
                        lstupdateLead.add(newLead);
                    }
                }
            }
        }
        
        // Insert Contacts
        if (!lstInsrtCon.isEmpty() || !lstUpdateCon.isEmpty()) {            
            insertContactsIfNotExist(lstInsrtCon, mapOfUniqueContactString, lstUpdateCon);   
            system.debug('insertContactsIfNotExist');
        }
        
        // Insert Lead
        if (!lstInsrtLead.isEmpty() || !lstUpdateLead.isEmpty()) {
            insertLeadsIfNotExist(lstInsrtLead, mapOfUniqueLeadString, lstUpdateLead); 
            system.debug('insertLeadsIfNotExist');
        }

        if (!leadStringToAccountIdForConversion.isEmpty()) {
            mapOfLeadStringAndConvertedContactId.putAll(convertLeadsToContacts(mapOfUniqueLeadStringToUpdate, leadStringToAccountIdForConversion));
        }

        // fill Contact map from preloaded, inserted, and converted Contacts; no extra SOQL needed
        for(Contact objContact :listOfAllContact){
            if (String.isNotBlank(objContact.CombinedString__c)) {
                mapOfContactStringAndId.put(objContact.CombinedString__c, objContact.Id);
            }
        }
        for(Contact objContact :lstInsrtCon){
            if (objContact.Id != null) {
                mapOfContactStringAndId.put(buildContactKey(objContact), objContact.Id);
            }
        }
        for (String combinedString : mapOfLeadStringAndConvertedContactId.keySet()) {
            if (!mapOfContactStringAndId.containsKey(combinedString)) {
                mapOfContactStringAndId.put(combinedString, mapOfLeadStringAndConvertedContactId.get(combinedString));
            }
        }

        // fill Lead map from preloaded and inserted Leads; converted Leads stay ignored
        for(Lead objLead :listOfAllLead) {
            if (!objLead.IsConverted && !mapOfLeadStringAndConvertedContactId.containsKey(objLead.CombinedString__c)) {
                mapOfLeadStringAndId.put(objLead.CombinedString__c, objLead.Id);
            }
        }
        for(Lead objLead :lstInsrtLead) {
            if (objLead.Id != null) {
                mapOfLeadStringAndId.put(buildLeadKey(objLead), objLead.Id);
            }
        }
        
        List<Registration__c> lstInsrtReg = new List<Registration__c>(); 
        List<Opportunity> lstInsrtOpp = new List<Opportunity>();
        Map<String,String> mapOfEventsairRegIdandCheckidDate = new Map<String,String>();
        // fetch pricebook related to the event Record
        List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: sfeventId LIMIT 50000];
        
        // Loop through event's air contacts data to create registration & product & Services
        for(Object objEventCon : lsteventsairContacts) {
            
            Map<String, Object> eventConMap = (Map<String, Object>) objEventCon;
            List<Object> lsteventsairReg = (List<Object>) eventConMap.get('registrations');
            String strevntconId = (String) eventConMap.get('id');
            String checkInDate = (String) eventConMap.get('checkInDate');
            String checkOutDate = (String) eventConMap.get('checkOutDate');
            String email = (String) eventConMap.get('primaryEmail');           
            // boolean isexecuted = false;
            String strAccdomainname;
            
            //extract domain name from contact's email
            if(email != null && email != '') {
                String[] emailparts = email.split('@');
                if (emailparts.size() > 1) {
                    strAccdomainname = emailparts[1].trim().toLowerCase();
                }
            }
            
            if(lsteventsairReg != null && lsteventsairReg.size() > 0) {
                
                List<Object> lsteventsairRecMarket = (List<Object>) eventConMap.get('marketingRecords');
                string Finalstring = getCombinedString(objEventCon);
                
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
                    
                    
                    if(Finalstring != null && Finalstring != '') {
                        if(mapOfContactStringAndId.containsKey(Finalstring)){
                            prodAndService.Contact__c = mapOfContactStringAndId.get(Finalstring);
                        }else {
                            // connect with exiting or newly created lead
                            if(mapOfLeadStringAndId.containsKey(Finalstring)) {
                                prodAndService.Lead__c = mapOfLeadStringAndId.get(Finalstring);
                            }
                        }
                    }
                    
                    lstInsrtProdAndServices.add(prodAndService);         
                }
                
                for(Object objEventReg : lsteventsairReg) {
                    Map<String, Object> eventReg = (Map<String, Object>) objEventReg;
                    Map<String, Object> eventregtype = (Map<String, Object>) eventReg.get('type');
                    Map<String, Object> eventregPaymentdetails = (Map<String, Object>) eventReg.get('paymentDetails');
                    String strRegDate = (String) eventReg.get('registrationDateTime');
                    Decimal totalcharge = (Decimal) eventregPaymentdetails.get('totalChargeAmount');
                    
                    Registration__c objreg = new Registration__c();
                    objreg.RecordTypeId = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Registration').getRecordTypeId();
                    if(strRegDate != null) {
                        objreg.Date_Registered__c = (Datetime) JSON.deserialize('"' + strRegDate + '"', Datetime.class);
                    }
                    objreg.EventsAir_Regisration_ID__c = (String) eventReg.get('id');
                    objreg.EventsAir_Contact_Id__c = strevntconId;
                    objreg.Event__c = sfeventId;
                    
                    if (checkInDate != null) {
                        objreg.CheckInDate__c = (Datetime) JSON.deserialize('"' + checkInDate + '"', Datetime.class);     
                    }
                    mapOfEventsairRegIdandCheckidDate.put((string)eventReg.get('id'),checkInDate);
                    if (checkOutDate != null) {
                        objreg.CheckOutDate__c   = (Datetime) JSON.deserialize('"' + checkOutDate + '"', Datetime.class);  
                    }
                    
                    if(Finalstring != null && Finalstring != '') {
                        
                        if( mapOfContactStringAndId.containsKey(Finalstring)) {
                            objreg.Contact__c = mapOfContactStringAndId.get(Finalstring);
                        }else {
                            if(mapOfLeadStringAndId.containsKey(Finalstring)) {
                                objreg.Lead__c = mapOfLeadStringAndId.get(Finalstring);
                            }
                        }
                    }
                    
                    if(eventregtype.get('name') != null) {
                        if(!Test.isRunningTest()) {
                            objreg.Registration_Type__c = (String) eventregtype.get('name');
                        }  
                    }
                    
                    if(eventregPaymentdetails.get('paymentStatus') != null) {
                        objreg.Payment_Status__c = (String) eventregPaymentdetails.get('paymentStatus');
                    }
                    System.debug('@@@ test333 = '+objreg.Registration_Type__c);
                    System.debug('@@@ selectedValuesMap = '+selectedValuesMap);
                    System.debug('@@@ selectedValuesMap11 = '+selectedValuesMap.containsKey(objreg.Registration_Type__c));
                    if(objreg.Registration_Type__c != null) {
                        if (selectedValuesMap.containsKey(objreg.Registration_Type__c.trim())) {                            
                            lstInsrtReg.add(objreg);
                        }
                    }
                    
                    
                    //  system.debug('totalcharge'+totalcharge);
                    if(totalcharge > 0) {
                        
                        // isexecuted = true;
                        system.debug('totalcharge'+totalcharge);
                        String OrganizationName;
                        
                        if(eventConMap.get('organizationName') != null){
                            String orgName = (String) eventConMap.get('organizationName');
                            OrganizationName = (orgName.length() > 80) ? orgName.substring(0, 80).trim().toLowerCase() : orgName.trim().toLowerCase();
                        }
                        
                        //Opportunity field Mapping
                        Opportunity objOpp = new Opportunity();
                        
                        String strOppName = 'Opportunity created for '+(String) eventConMap.get('firstName')+' '+(String) eventConMap.get('lastName');
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
                        if(strRegDate != null) {
                            objOpp.Closedate = Date.valueOF(strRegDate);
                        }
                        
                        if (RecordType == 'Mumbrella') {
                            objOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mumbrella_Visitor').getRecordTypeId();                          
                        } else {
                            objOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Divcom_Visitor').getRecordTypeId();
                        } 
                        objOpp.Event__c = sfeventId;
                        objOpp.EventsAir_Contact_Id__c = strevntconId;
                        if(lstPriceook.size()>0) {
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
        
        insertProdAndServicesIfNotExist(lstInsrtProdAndServices);
        insertRegistrationIfNotExist(lstInsrtReg,mapOfEventsairRegIdandCheckidDate);
        List<Opportunity> allOpportunitiyList = insertOpportunityIfNotExist(lstInsrtOpp);
        createOpportunityProduct(lsteventsairContacts, allOpportunitiyList); 
    }
    
    // Method for create combined String
    public static String getCombinedString(Object objEventCon){
        Map<String, Object> eventConMap = (Map<String, Object>) objEventCon;
        String streventconEmail = (String) eventConMap.get('primaryEmail');
        String streventconfname = (String) eventConMap.get('firstName');
        String streventconlname = (String) eventConMap.get('lastName');
        
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

    private Id getMatchedAccountId(String domainName, String orgName, Map<String, Id> mapOfDomainNameAndAccId, Map<String, Id> mapOfOrgNameAndAccId) {
        if (String.isNotBlank(domainName) && mapOfDomainNameAndAccId.containsKey(domainName)) {
            return mapOfDomainNameAndAccId.get(domainName);
        }
        if (String.isNotBlank(orgName) && mapOfOrgNameAndAccId.containsKey(orgName)) {
            return mapOfOrgNameAndAccId.get(orgName);
        }
        return null;
    }

    private static String buildContactKey(Contact contactRecord) {
        String firstName = contactRecord.FirstName == null ? '' : contactRecord.FirstName;
        String lastName = contactRecord.LastName == null ? 'UnKnown' : contactRecord.LastName;
        String email = contactRecord.Email == null ? '' : contactRecord.Email;
        return (firstName + lastName + email).toLowerCase();
    }

    private static String buildLeadKey(Lead leadRecord) {
        String firstName = leadRecord.FirstName == null ? '' : leadRecord.FirstName;
        String lastName = leadRecord.LastName == null ? 'UnKnown' : leadRecord.LastName;
        String email = leadRecord.Email == null ? '' : leadRecord.Email;
        return (firstName + lastName + email).toLowerCase();
    }

    private Contact buildPaidContact(Map<String, Object> eventConMap, Map<String, Object> eventContactMap, Id accountId) {
        Contact newContact = new Contact();
        newContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Visitor').getRecordTypeId();
        newContact.AccountId = accountId;
        newContact.EventsAir_Con_ID__c = (String) eventConMap.get('id');

        String firstName = (String) eventConMap.get('firstName');
        if (String.isNotBlank(firstName)) {
            newContact.FirstName = firstName.length() <= 40 ? firstName.trim() : firstName.substring(0, 40).trim();
        }

        String lastName = (String) eventConMap.get('lastName');
        newContact.LastName = String.isBlank(lastName) ? 'UnKnown' : lastName.trim();

        String email = (String) eventConMap.get('primaryEmail');
        newContact.Email = String.isBlank(email) ? '' : email.trim();
        String jobTitle = (String) eventConMap.get('jobTitle');
        newContact.Title = String.isBlank(jobTitle) ? 'UnKnown' : jobTitle.trim();
        newContact.Organization_Name__c = (String) eventConMap.get('organizationName');

        String workPhone = (String) eventConMap.get('workPhone');
        if (String.isNotBlank(workPhone)) {
            newContact.Phone = workPhone.trim();
        }

        List<Object> phoneNumbers = (List<Object>) eventConMap.get('contactPhoneNumbers');
        if (phoneNumbers != null) {
            for (Object phoneNumber : phoneNumbers) {
                Map<String, Object> phoneNumberMap = (Map<String, Object>) phoneNumber;
                if (phoneNumberMap.get('mobile') != null) {
                    newContact.MobilePhone = (String) phoneNumberMap.get('mobile');
                    break;
                }
            }
        }

        if (RecordType != 'Mumbrella') {
            List<Object> customFields = (List<Object>) eventConMap.get('customFields');
            if (customFields != null) {
                for (Object field : customFields) {
                    Map<String, Object> customFieldsMap = (Map<String, Object>) field;
                    String fieldName = (String) customFieldsMap.get('name');
                    if (String.isNotBlank(fieldName)) {
                        applyIndustryAndJobFunction(newContact, fieldName, customFieldsMap.get('value'));
                        if (fieldName == 'Company Size') {
                            newContact.Company_Size__c = (String) customFieldsMap.get('value');
                        }
                        applyOrganisationType(newContact, fieldName, customFieldsMap.get('value'));
                    }
                }
            }
            newContact.Business_Unit__c = 'Divcom';
        } else {
            newContact.Business_Unit__c = 'Mumbrella';
        }

        applyAddressFields(newContact, eventContactMap);
        return newContact;
    }

    private static Map<String, Id> convertLeadsToContacts(Map<String, Lead> mapOfLeadStringAndLead, Map<String, Id> leadStringToAccountId) {
        Map<String, Id> convertedContactsByCombinedString = new Map<String, Id>();
        if (leadStringToAccountId.isEmpty()) {
            return convertedContactsByCombinedString;
        }

        LeadStatus convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        Map<Id, String> leadIdToCombinedString = new Map<Id, String>();

        for (String combinedString : leadStringToAccountId.keySet()) {
            Lead leadToConvert = mapOfLeadStringAndLead.get(combinedString);
            Id accountId = leadStringToAccountId.get(combinedString);
            if (leadToConvert != null && accountId != null) {
                Database.LeadConvert leadConvert = new Database.LeadConvert();
                leadConvert.setLeadId(leadToConvert.Id);
                leadConvert.setAccountId(accountId);
                leadConvert.setConvertedStatus(convertedStatus.MasterLabel);
                leadConvert.setDoNotCreateOpportunity(true);
                leadConverts.add(leadConvert);
                leadIdToCombinedString.put(leadToConvert.Id, combinedString);
            }
        }

        if (leadConverts.isEmpty()) {
            return convertedContactsByCombinedString;
        }

        List<Database.LeadConvertResult> results = Database.convertLead(leadConverts, false);
        Map<Id, Id> leadIdToContactId = new Map<Id, Id>();
        for (Database.LeadConvertResult result : results) {
            if (result.isSuccess() && result.getContactId() != null) {
                leadIdToContactId.put(result.getLeadId(), result.getContactId());
                convertedContactsByCombinedString.put(leadIdToCombinedString.get(result.getLeadId()), result.getContactId());
            }
        }

        relinkLeadRecordsToContacts(leadIdToContactId);
        return convertedContactsByCombinedString;
    }

    private static void relinkLeadRecordsToContacts(Map<Id, Id> leadIdToContactId) {
        if (leadIdToContactId.isEmpty()) {
            return;
        }

        List<Registration__c> registrationsToUpdate = new List<Registration__c>();
        for (Registration__c registrationRecord : [SELECT Id, Lead__c, Contact__c FROM Registration__c WHERE Lead__c IN :leadIdToContactId.keySet() LIMIT 50000]) {
            registrationRecord.Contact__c = leadIdToContactId.get(registrationRecord.Lead__c);
            registrationRecord.Lead__c = null;
            registrationsToUpdate.add(registrationRecord);
        }
        if (!registrationsToUpdate.isEmpty()) {
            update registrationsToUpdate;
        }

        List<Product_Service_Option__c> productsAndServicesToUpdate = new List<Product_Service_Option__c>();
        for (Product_Service_Option__c productService : [SELECT Id, Lead__c, Contact__c FROM Product_Service_Option__c WHERE Lead__c IN :leadIdToContactId.keySet() LIMIT 50000]) {
            productService.Contact__c = leadIdToContactId.get(productService.Lead__c);
            productService.Lead__c = null;
            productsAndServicesToUpdate.add(productService);
        }
        if (!productsAndServicesToUpdate.isEmpty()) {
            update productsAndServicesToUpdate;
        }
    }
    
    // Method for insert only new Contacts if not exist in salesforce
    public static void insertContactsIfNotExist(List<Contact> contactsToInsert , Map<String, Boolean> mapOfUniqueContactString , List<Contact> lstUpdateCon) {
        
        List<Contact> FinalListOfContactToInsert = new List<Contact>();
        Set<String> setOfCurrentContactCombinedData = new Set<String>();
        
        //loop through the passed data of contact for insert and extract unique contacts for insert
        for(Contact objcontact :contactsToInsert){
            
            String strcombinedEventsAirAttendee = objcontact.FirstName + objcontact.LastName + objcontact.Email; 
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            
            // check if contact is exist or not
            if(!mapOfUniqueContactString.ContainsKey(strcombinedEventsAirAttendee)){
                // for prevent adding duplicate contact in list
                if(!setOfCurrentContactCombinedData.contains(strcombinedEventsAirAttendee)){
                    FinalListOfContactToInsert.add(objcontact);
                    setOfCurrentContactCombinedData.add(strcombinedEventsAirAttendee);
                }
            }
        }
        
        if(FinalListOfContactToInsert.size()>0){
            insert FinalListOfContactToInsert;
        }
        
        // update contact
        List<Contact> FinalListOfContactToUpdate = new List<Contact>();
        Set<String> setOfCurrentContactCombinedDataForUpdate = new Set<String>();
        
        //loop through the passed data of contact for update and extract unique contacts for update
        for(Contact objcontact :lstUpdateCon){
            String strcombinedEventsAirAttendee = objcontact.FirstName + objcontact.LastName + objcontact.Email; 
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            
            // check if contact is exist or not
            if(mapOfUniqueContactString.ContainsKey(strcombinedEventsAirAttendee)){
                // for prevent adding duplicate contact in list
                if(!setOfCurrentContactCombinedDataForUpdate.contains(strcombinedEventsAirAttendee)){
                    FinalListOfContactToUpdate.add(objcontact);
                    setOfCurrentContactCombinedDataForUpdate.add(strcombinedEventsAirAttendee);
                }
            }
        }
        
        if(FinalListOfContactToUpdate.size()>0){
            update FinalListOfContactToUpdate;
        }
        
    }
    
    // Method for insert only new Leads if not exist in salesforce
    public static void insertLeadsIfNotExist(List<Lead> leadsToInsert, Map<String, Boolean> mapOfUniqueLeadString , List<Lead> lstUpdateLead) {
        
        List<Lead> FinalListOfLeadToInsert = new List<Lead>();
        Set<String> setOfCurrentleadCombinedData = new Set<String>();
        
        for(Lead objLead :leadsToInsert){
            String strcombinedEventsAirAttendee= objLead.FirstName+objLead.LastName+objLead.Email; 
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            
            // check if lead exist or not
            if(!mapOfUniqueLeadString.ContainsKey(strcombinedEventsAirAttendee)){
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
        
        // update lead
        List<Lead> FinalListOfLeadToUpdate = new List<Lead>();
        Set<String> setOfCurrentleadCombinedDataForUpdate = new Set<String>();
        
        for(Lead objLead :lstUpdateLead){
            String strcombinedEventsAirAttendee= objLead.FirstName+objLead.LastName+objLead.Email; 
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            
            // check if lead exist or not
            if(mapOfUniqueLeadString.ContainsKey(strcombinedEventsAirAttendee)){
                // for prevent adding duplicate lead in list
                if(!setOfCurrentleadCombinedDataForUpdate.contains(strcombinedEventsAirAttendee)){
                    FinalListOfLeadToUpdate.add(objLead);
                    setOfCurrentleadCombinedDataForUpdate.add(strcombinedEventsAirAttendee);
                }
            }
        }
        
        if(FinalListOfLeadToUpdate.size()>0){
            update FinalListOfLeadToUpdate;
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
                                                                     WHERE EventsAirMarketing_Record_ID__c IN: setOfEvnProdServiceIds LIMIT 50000];
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
    
    // Method for insert only new Registration if not exist in salesforce
    public void insertRegistrationIfNotExist(List<Registration__c> lstInsrtReg,Map<String,String> mapOfEventsairRegIdandCheckidDate) {
        
        Map<String, Id> mapOfEvnRegIdandSfRegId = new Map<String, Id>();
        Map<String, Datetime> mapOfExistingEvnRegIdandCheckinDate = new Map<String, Datetime>();
        set<String> setOfEvnRegIds = new set<String>(); // holds eventsAir registration record Id
        
        for(Registration__c reg: lstInsrtReg) {
            setOfEvnRegIds.add(reg.EventsAir_Regisration_ID__c);
        }
        
        //do soql on registartion to fetch data based on eventsair registration id
        List<Registration__c> lstexistingRegistrations = [SELECT Id, EventsAir_Regisration_ID__c,CheckInDate__c
                                                          FROM Registration__c 
                                                          WHERE EventsAir_Regisration_ID__c IN: setOfEvnRegIds and Event__c =:sfeventId LIMIT 50000];
        system.debug('lstexistingRegistrations'+lstexistingRegistrations.size());
        system.debug('sfeventId'+sfeventId);
        
        // if exiting registration found in SF fill the map for prevent duplicate
        if(lstexistingRegistrations.size() > 0) {
            for(Registration__c existingreg: lstexistingRegistrations) {
                mapOfEvnRegIdandSfRegId.put(existingreg.EventsAir_Regisration_ID__c, existingreg.Id);
                mapOfExistingEvnRegIdandCheckinDate.put(existingreg.EventsAir_Regisration_ID__c,existingreg.CheckInDate__c);
            }
        }
        
        List<Registration__c> finallisttoinsertreg = new List<Registration__c>();
        List<Registration__c> listtoUpdatereg = new List<Registration__c>();
        
        for(Registration__c newreg: lstInsrtReg) {
            // check if exiting registration record if not found than add for insert
            if(!mapOfEvnRegIdandSfRegId.containskey(newreg.EventsAir_Regisration_ID__c)) {
                finallisttoinsertreg.add(newreg);
            }
            /*else {
newreg.Id = mapOfEvnRegIdandSfRegId.get(newreg.EventsAir_Regisration_ID__c);
listtoUpdatereg.add(newreg);
}*/
            if(mapOfExistingEvnRegIdandCheckinDate.containskey(newreg.EventsAir_Regisration_ID__c)){
                
                if(mapOfExistingEvnRegIdandCheckinDate.get(newreg.EventsAir_Regisration_ID__c) == null){
                    if(mapOfEventsairRegIdandCheckidDate.containskey(newreg.EventsAir_Regisration_ID__c)){
                        if(mapOfEventsairRegIdandCheckidDate.get(newreg.EventsAir_Regisration_ID__c) != null ||
                           mapOfEventsairRegIdandCheckidDate.get(newreg.EventsAir_Regisration_ID__c) !=''){
                               
                               Registration__c regtoUpdt = new Registration__c();
                               if(mapOfEvnRegIdandSfRegId.containskey(newreg.EventsAir_Regisration_ID__c) && mapOfEvnRegIdandSfRegId.get(newreg.EventsAir_Regisration_ID__c) != null ){
                                   regtoUpdt.id = mapOfEvnRegIdandSfRegId.get(newreg.EventsAir_Regisration_ID__c);
                               }
                               string checkInDate =mapOfEventsairRegIdandCheckidDate.get(newreg.EventsAir_Regisration_ID__c);
                               if(checkInDate != null){
                                   regtoUpdt.CheckInDate__c = (Datetime) JSON.deserialize('"' + checkInDate + '"', Datetime.class); 
                               }
                               listtoUpdatereg.add(regtoUpdt);
                           }
                    }
                    
                }
            }
        }
        
        if(finallisttoinsertreg.size() >0) {
            insert finallisttoinsertreg ;
        }
        
        if (listtoUpdatereg.size() > 0) {
            system.debug('@@listtoUpdatereg--'+listtoUpdatereg.size());
            update listtoUpdatereg;
        }
        
    }
    
    //Method for insert only new Opportunity if not exist in salesforce
    public List<Opportunity> insertOpportunityIfNotExist(List<Opportunity> lstInsrtOpp) {
        
        Set<String> setOfprocessedEventsAirContactIds = new Set<String>();
        Map<String, Id> mapOfEvnconIdandSfOppId = new Map<String, Id>();
        set<String> setOfEvnconIds = new set<String>(); // holds eventsAir contact recrod Id
        List<Opportunity> allOpportunityList = new List<Opportunity>();
        
        for(Opportunity opp: lstInsrtOpp) {
            setOfEvnconIds.add(opp.EventsAir_Contact_Id__c);
        }
        
        //do soql on opportunity and contact to fetch data based on eventsair contact id
        List<Opportunity> lstexistingOpps = [SELECT Id, EventsAir_Contact_Id__c
                                             FROM Opportunity 
                                             WHERE EventsAir_Contact_Id__c IN: setOfEvnconIds LIMIT 50000];
        
        List<Contact> lstexistingContacts = [SELECT Id, EventsAir_Con_ID__c,AccountId
                                             FROM Contact 
                                             WHERE EventsAir_Con_ID__c IN: setOfEvnconIds LIMIT 50000];
        
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
                setOfprocessedEventsAirContactIds.add(existingOpp.EventsAir_Contact_Id__c);
            }
        }
        
        List<Opportunity> finallisttoinsertOpp = new List<Opportunity>();
        
        for(Opportunity newopp: lstInsrtOpp) {
            // add opportunity if opportunity record not found with  eventsAir contact Id in Salesforce AND add new Opportunity EventsAir_Contact_Id__c in set
            if(!mapOfEvnconIdandSfOppId.containskey(newopp.EventsAir_Contact_Id__c) && !setOfprocessedEventsAirContactIds.contains(newopp.EventsAir_Contact_Id__c)) {
                // Assign accountId by finding contact with same EventsAir contact id in map
                if (( newopp.accountId != null) && mapOfEvtAirContactIdAndAccountId.containsKey(newopp.EventsAir_Contact_Id__c) ) {
                    newopp.accountId = mapOfEvtAirContactIdAndAccountId.get(newopp.EventsAir_Contact_Id__c);
                } 
                
                finallisttoinsertOpp.add(newopp);
                setOfprocessedEventsAirContactIds.add(newopp.EventsAir_Contact_Id__c);
            }
        }
        
        if(finallisttoinsertOpp.size() > 0 ) {
            insert finallisttoinsertOpp;
            allOpportunityList.addAll(finallisttoinsertOpp);
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
        List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: sfeventId LIMIT 50000];
        List<Pricebook2> lstStandardPriceBook = [ SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
        
        for(Opportunity opp: allOpportunitiyList) {
            mapOfEventConAndSFOppId.put(opp.EventsAir_Contact_Id__c, opp.Id);
            system.debug('mapOfEventConAndSFOppId'+mapOfEventConAndSFOppId);
        }
        
        // loop through eventsAir contact data
        for(Object objEventCon: lsteventsairContacts) {
            
            Map<String, Object> eventConMap = (Map<String, Object>) objEventCon;  
            List<Object> lsteventsairReg = (List<Object>) eventConMap.get('registrations');
            String strevntconId = (String) eventConMap.get('id'); 
            
            if(lsteventsairReg != null && lsteventsairReg.size() > 0){
                //loop through event'sair registration data
                for(Object objEventReg: lsteventsairReg) {
                    
                    Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                    Object eventregtype = eventReg.get('type');                    
                    Map<String, Object> eventregtypemap = (Map<String, Object>)eventregtype; 
                    String strRegTypeId = (String) eventregtypemap.get('id');
                    
                    // create product based on registration type
                    if(eventregtypemap != null && !setOfProdId.contains(strRegTypeId)) {
                        //Product2 field mapping start
                        Product2 newProduct = new Product2();
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
            
            //do soql on product to fetch data based on product eventsair EventsAir_ID
            List<Product2> lstexistingproducts = [SELECT Id, EventsAir_ID__c
                                                  FROM Product2 
                                                  WHERE EventsAir_ID__c IN: setOfEvnproIds LIMIT 50000];
            
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
                
                // fill map with product events air Id and sf product Id
                for(Product2 prod: finallisttoinsertproduct) {
                    mapOfEvnproandSfId.put(prod.EventsAir_ID__c, prod.Id);
                }
            }
            system.debug(' mapOfEvnproandSfId'+mapOfEvnproandSfId);
        }
        
        // loop through eventsAir contact
        for(Object objEventCon: lsteventsairContacts) {
            
            Map<String, Object> eventConMap = (Map<String, Object>) objEventCon;  
            List<Object> lsteventsairReg = (List<Object>) eventConMap.get('registrations');
            
            if(lsteventsairReg != null && lsteventsairReg.size() > 0){
                //loop through event's air registration data
                for(Object objEventReg: lsteventsairReg) {
                    
                    Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                    string registrationId = (String) eventReg.get('id');
                    Object eventfunregtype = eventReg.get('type');                    
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
                                
                                if(lstStandardPriceBook.size() > 0){
                                    pbEntry.Pricebook2Id = lstStandardPriceBook[0].Id;  
                                }
                                
                                pbEntry.UnitPrice = (decimal) feemap.get('amount');
                                pbEntry.IsActive = true;
                                pbEntry.UseStandardPrice = false;
                                if(strRegTypeId != null) {
                                    pbEntry.EventsAir_Type_ID__c = strRegTypeId;
                                }  
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
            Set<String> setOfPBEntryRegTypeIds = new Set<String>();
            for (PricebookEntry newpricebookentry : lstInsertPricebookEntry) {
                setOfPBEntryRegTypeIds.add(newpricebookentry.EventsAir_Type_ID__c);
            }
            
            List<PricebookEntry> lstexistingPricebookentry = [SELECT Id, Name, Product2.Name, EventsAir_Type_ID__c, UnitPrice
                                                              FROM PricebookEntry 
                                                              WHERE  Pricebook2.isStandard = false AND EventsAir_Type_ID__c IN: setOfPBEntryRegTypeIds LIMIT 50000];
            
            Map<String, Boolean> mapofpricebookentry = new Map<String, Boolean>();
            
            for(PricebookEntry pb: lstexistingPricebookentry) {
                mapofpricebookentry.put(pb.EventsAir_Type_ID__c, true);
            }
            
            List<PricebookEntry> finallsttoinsrtPB = new List<PricebookEntry>();
            
            for(PricebookEntry objPB: lstInsertPricebookEntry) {
                if(!mapofpricebookentry.containsKey(objPB.EventsAir_Type_ID__c)) {
                    finallsttoinsrtPB.add(objPB);
                }
            }
            
            if(!finallsttoinsrtPB.isEmpty()) {
                insert finallsttoinsrtPB;
                lstexistingPricebookentry.addAll(finallsttoinsrtPB);  
            }
            
            //fill mapOfEventRegTypeIdAndSFPBentryId Map
            //loop through pricebookentry list
            for(PricebookEntry objexistingPBEntry: lstexistingPricebookentry) {
                mapOfEventRegTypeIdAndSFPBentryId.put(objexistingPBEntry.EventsAir_Type_ID__c, objexistingPBEntry.Id);
            }
        }  
        
        // loop through eventsAir contacts
        for(Object objEventCon: lsteventsairContacts) {
            
            Map<String, Object> eventConMap = (Map<String, Object>) objEventCon;  
            
            List<Object> lsteventsairReg = (List<Object>) eventConMap.get('registrations');
            String strevntconId = (String) eventConMap.get('id');
            
            if(lsteventsairReg != null && lsteventsairReg.size() > 0){
                
                //loop through event'sair registration data
                for(Object objEventReg: lsteventsairReg) {
                    
                    Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                    string registrationId = (String) eventReg.get('id');
                    Object eventregPaydetail = eventReg.get('paymentDetails');                    
                    Object eventfunregtype = eventReg.get('type');  
                    
                    Map<String, Object> eventregPaymentdetails = (Map<String, Object>)eventregPaydetail;
                    Decimal totalcharge = (Decimal)eventregPaymentdetails.get('totalChargeAmount');
                    
                    Map<String, Object> eventregtypemap = (Map<String, Object>)eventfunregtype;
                    String strRegTypeId = (String) eventregtypemap.get('id');
                    
                    String discountcodeval;
                    Map<String, Object> eventregPaydetailcodedetail;
                    
                    // check for registration payment details
                    if(eventregPaymentdetails.get('discountCode') != null){
                        Object eventregPaydetailcode = eventregPaymentdetails.get('discountCode');
                        eventregPaydetailcodedetail = (Map<String, Object>)eventregPaydetailcode;
                        
                        system.debug('eventregPaydetailcodedetail'+eventregPaydetailcodedetail);
                        system.debug('eventregPaydetailcodedetail.get'+eventregPaydetailcodedetail.get('code'));
                        if(eventregPaydetailcodedetail.get('code') != null){
                            discountcodeval = (String)eventregPaydetailcodedetail.get('code');
                        } 
                    }
                    
                    // check for paid registration
                    if(totalcharge > 0){
                        
                        system.debug('totalcharge'+totalcharge);
                        //  " mapOfEventConAndSFOppId " check if the contact with eventsAir ID is exist or not in salesforce
                        // " mapOfEventRegTypeIdAndSFPBentryId " check if the pricebookentry for the product is created or not in salesforce
                        if( mapOfEventConAndSFOppId.containsKey(strevntconId)  && mapOfEventRegTypeIdAndSFPBentryId.containskey(strRegTypeId)) {
                            
                            // Finalstring is the combination of first name + last name + email
                            String Finalstring = getCombinedString(objEventCon);
                            
                            //OpportunityLineItem field mapping start
                            OpportunityLineItem oli = new OpportunityLineItem();
                            oli.OpportunityId = mapOfEventConAndSFOppId.get(strevntconId);                    
                            oli.PricebookEntryId = mapOfEventRegTypeIdAndSFPBentryId.get(strRegTypeId);
                            oli.Quantity = 1;
                            oli.Product2Id =mapOfEvnproandSfId.get(strRegTypeId); 
                            oli.EventsAir_Adjustment__c = (Decimal) eventregPaymentdetails.get('adjustmentAmount');
                            oli.EventsAir_Discount_Amount__c = (Decimal) eventregPaymentdetails.get('discountAmount');
                            
                            if(discountcodeval != null){
                                oli.EventsAir_Discount_Code__c = discountcodeval;  
                            }
                            
                            oli.EventsAir_Tax__c = (Decimal) eventregPaymentdetails.get('taxAmount');
                            oli.EventsAir_Payment_Status__c = (String) eventregPaymentdetails.get('paymentStatus');
                            // oli.Function_Registration_Id__c = registrationId;
                            oli.EventsAir_Regisration_ID__c = registrationId;
                            
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
        
        // process for insert OpportuniyLineItem And link opportunityLineItem with Registration in Salesforce
        List<OpportunityLineItem> listOliForLinkOppWithReg = new List<OpportunityLineItem>();        
        Map<String, Id> mapOfEvnOLIandSfId = new Map<String, Id>();
        set<String> setOfEvnOLIIds = new set<String>();
        
        for(OpportunityLineItem oli: lstInsertOppProduct) {
            setOfEvnOLIIds.add(oli.EventsAir_Regisration_ID__c);
        }
        
        //do soql on con to fetch data based on eventsair registration id
        List<OpportunityLineItem> lstexistingOlis = [SELECT Id,  EventsAir_Regisration_ID__c, OpportunityId
                                                     FROM OpportunityLineItem 
                                                     WHERE EventsAir_Regisration_ID__c IN: setOfEvnOLIIds LIMIT 50000];
        
        // fill the map of eventsAir Registration Id and SF OpportunityLineItem Id
        if(lstexistingOlis.size() > 0) {
            for(OpportunityLineItem existingoli: lstexistingOlis) {
                mapOfEvnOLIandSfId.put(existingoli.EventsAir_Regisration_ID__c, existingoli.Id);
            }
        }
        
        if(!lstInsertOppProduct.isEmpty()) {
            
            List<OpportunityLineItem> finallisttoinsertoli= new List<OpportunityLineItem>();
            for(OpportunityLineItem newoli: lstInsertOppProduct) {
                // check for duplicates and ignor it if found
                if(!mapOfEvnOLIandSfId.containskey(newoli.EventsAir_Regisration_ID__c)) {
                    finallisttoinsertoli.add(newoli);
                }
            }
            
            if(finallisttoinsertoli.size() >0) {
                system.debug('Oli'+finallisttoinsertoli.size());
                insert finallisttoinsertoli;
                listOliForLinkOppWithReg.addAll(finallisttoinsertoli);
            }
        }
        
        // add all the newely created OpportunityLineItems In the list for link them with registration
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
        
        // fetch all registration with eventsAir registration Id found in List " LstOfEventsairRegId "
        List<Registration__c> lstOfRegistrationtoLink = [select id,EventsAir_Regisration_ID__c,Opportunity_Product__c from Registration__c where EventsAir_Regisration_ID__c in:LstOfEventsairRegId LIMIT 50000 ];
        
        for(Registration__c reg : lstOfRegistrationtoLink){
            
            // Linking opportunity and OpportunityLineItem with registration
            reg.Opportunity_Product__c = MapOfEventsairRegIdandOLI.get(reg.EventsAir_Regisration_ID__c).Id;
            reg.Opportunity__c = MapOfEventsairRegIdandOLI.get(reg.EventsAir_Regisration_ID__c).OpportunityId;
        }   
        Database.update(lstOfRegistrationtoLink,false);   
    }    
    
    public void finish(Database.BatchableContext BC) {
        
        if(!test.isrunningtest()) {
            List<Manage_Eventsair_Sec_And_Int_Reg_batch__c> lstcustsett2 = [SELECT Id, Name, Offset__c, Is_Execute_Next__c 
                                                                            FROM Manage_Eventsair_Sec_And_Int_Reg_batch__c LIMIT 1];            
            // Your finish logic goes here
            if(lstcustsett2[0].Is_Execute_Next__c == true) {
                
                //update offset in custom setting
                lstcustsett2[0].Offset__c = lstcustsett[0].Offset__c + contactsLimit;
                update lstcustsett2;
                
                ImportRegSeprateSecAndInteBatch newBatch = new ImportRegSeprateSecAndInteBatch(sfeventId);
                Database.executeBatch(newBatch, 500);
            }
            else {
                lstcustsett2[0].Is_Execute_Next__c = true;
                update lstcustsett2;                                
                System.debug('### sfeventId  = '+sfeventId);
                
                if(sfeventId != null) {
                    FeedItem post = new FeedItem();
                    post.ParentId = sfeventId; //eg. Opportunity id, custom object id..
                    post.Body = 'Apex batch End for fetching EventsAir Registration Data';
                    insert post; 
                }                               
            }
        } 
    }
}