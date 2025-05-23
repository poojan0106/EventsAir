public class ImportFunRegSeprateSecAndInteBatch implements Database.Batchable<ResponseWrapper>, Database.AllowsCallouts {
    
    //variable declartion
    public String strEventId;
    public String sfeventId;
    public String eventCategory;
    Integer contactsLimit = Integer.valueOf(System.Label.EventsAirFun_Attendee_Contact_Limit);
    Integer regLimit = Integer.valueOf(System.Label.EventsAir_Function_Registartion_Limit);
    List<Contact> lstInsrtCon;
    List<Contact> lstUpdateCon;
    List<Lead> lstInsrtLead;
    List<Lead> lstUpdateLead;
    List<Product_Service_Option__c> lstInsrtProdAndServices;
    List<Function__c> lstInsrtFun; 
    public List<Event__c> eventData = new List<Event__c>();
    Map<String, Id> mapOfLeadStringAndId = new Map<String, Id>();   
    Map<String, Id> mapOfContactStringAndId = new Map<String, Id>();
    Set<String> setofProductId = new Set<String>();
    Map<String, Id> mapOfEvnproandSfId = new Map<String, Id>();
    Map<String, String> selectedValuesMap = new Map<String, String>();
    Map<String, Id> mapOfEventRegTypeIdAndSFPBentryId = new Map<String, Id>();
    public String RecordType;

    //fetch current offset value from custom setting
    List<Manage_EvtAir_Fun_Reg_Sec_And_Inte_Batch__c> lstcustsett = [Select Id, Name, Offset__c, Is_Execute_Next__c,Generic_Email_Domains__c from Manage_EvtAir_Fun_Reg_Sec_And_Inte_Batch__c LIMIT 1];
    
    public ImportFunRegSeprateSecAndInteBatch(String strsfeventId) {
        this.eventData = [SELECT Id, Name, EventsAirID__c, Open_Date__c, Close_Date__c, Event_Logo__c,New_Event_Logo__c, Is_Pricebook_Created__c, Next_Date_For_Function_Registration__c, Event_Category__c, RecordType.Name,Function_Registration_Types__c FROM Event__c WHERE Id =:strsfeventId AND Function_Registration_Types__c != null AND Function_Registration_Types__c != ''
                                   AND EventsAirID__c != null limit 1 ];
        system.debug('this.eventData--->'+this.eventData);
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
            '${customVariables}' + // Placeholder for custom variables        
            '}' +
            '}';
        
        String customFieldsSection = '';
        String customFieldParam = '';
        String customVariables = '';
        
        if (RecordType != 'Mumbrella') {
            customFieldParam = ', $input: CustomFieldSearchFilterInput!';
            customFieldsSection = 'customFields(input: $input , limit:3){name, definitionId, value},';
            if (eventCategory == 'Security') {
                customVariables = ', "input": { "names": ["Industry SEC" , "Job Function SEC" , "Company Size"] }';
            } else {
                customVariables = ', "input": { "names": ["Industry INT" , "Job Function INT" , "Company Size"] }';
            }
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
    
    public void execute(Database.BatchableContext BC, List<ResponseWrapper> responseWrapper) {
        try{    
            // Serialize the ResponseWrapper to a JSON string
            String serializedResponseWrapper;
            Map<String, Object> jsonResponse;
            Map<String, Object> eventDatamap;

            if (String.isNotBlank(eventData[0].Function_Registration_Types__c)) {
                List<String> selectedValues = eventData[0].Function_Registration_Types__c.split(';');
                for (String value : selectedValues) {
                    selectedValuesMap.put(value, value);
                    System.debug('value = ' + value);
                }
            }
            if (responseWrapper.size() > 0) {
                serializedResponseWrapper = JSON.serialize(responseWrapper[0]);
                
                jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(serializedResponseWrapper);
            }
            
            if (jsonResponse != null) {
                // Extract the 'data' map from the JSON response
                if (jsonResponse.containsKey('data') && jsonResponse.get('data') != null) {
                    eventDatamap = (Map<String, Object>) jsonResponse.get('data');
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
            post.Body = 'Unable to import Function Registartions For Security And Integrate Batch. \nError : '+ e.getMessage();
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
            List<Object> lsteventsairfunReg = (List<Object>) eventConMap.get('functionRegistrations');
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
            if (lsteventsairfunReg != null && lsteventsairfunReg.size() > 0) {
                for (Object objEventReg : lsteventsairfunReg) {
                    Map<String, Object> eventReg = (Map<String, Object>) objEventReg;
                    Map<String, Object> paymentDetails = (Map<String, Object>) eventReg.get('paymentDetails');
                    Decimal totalCharge = (Decimal) paymentDetails.get('totalChargeAmount');
                    
                    if (totalCharge != null && totalCharge > 0) {
                        hasPaidRegistration = true;
                        break;
                    }
                }
            }
            
            // Determine account name and track unpaid functionRegistrations
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
                if (!setOfExistingAccountNameAndDomain.contains(accName.toLowerCase())) {
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
        Map<String, String> MapOfexistingAccountsOrgNameAndAccountId = new Map<String, String>();
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
        
        // fetch contact from sf based on combined String
        List<Contact> listOfAllContact = [SELECT Id, Title, Organization_Name__c, Industry__c, Job_Function__c, Company_Size__c, FirstName, LastName, Email, CombinedString__c FROM Contact
                                          WHERE CombinedString__c in :setOfCombinedEventsAirAttendee LIMIT 50000];
        Map<String, Boolean> mapOfUniqueContactString = new Map<String, Boolean>();
        Map<String, Contact> mapOfUniqueContactStringToUpdate = new Map<String, Contact>();
        
        //loop through existing Contacts and fill the map to use for mapping with function registration
        for(Contact objContact :listOfAllContact){
            mapOfUniqueContactString.put(objContact.CombinedString__c, true); 
            mapOfUniqueContactStringToUpdate.put(objContact.CombinedString__c, objContact); 
        }
        
        // fetch Lead from sf based on combined String
        List<Lead> listOfAllLead = [SELECT Id, Title, Company , Industry__c, Job_Function__c, Company_Size__c, FirstName, LastName , Email, CombinedString__c FROM Lead
                                    WHERE CombinedString__c in :setOfCombinedEventsAirAttendee LIMIT 50000];
        Map<String, Boolean> mapOfUniqueLeadString = new Map<String, Boolean>();
        Map<String, Lead> mapOfUniqueLeadStringToUpdate = new Map<String, Lead>();
        
        //loop through existing Leads and fill the map to use for mapping with function registration
        for(Lead objLead :listOfAllLead){
            mapOfUniqueLeadString.put(objLead.CombinedString__c, true); 
            mapOfUniqueLeadStringToUpdate.put(objLead.CombinedString__c, objLead); 
        }
        
        // loop through event's air contact for create Lead/Contact based on Paid/Unpaid function registrations
        for (Object objEventCon : lsteventsairContacts) {
            Map<String, Object> eventConMap = (Map<String, Object>) objEventCon;
            String email = (String) eventConMap.get('primaryEmail');           
            String strAccdomainname;
            String orgName = (String) eventConMap.get('organizationName');
            List<Object> lsteventsairfunReg = (List<Object>) eventConMap.get('functionRegistrations');
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
            
            if(lsteventsairfunReg != null && lsteventsairfunReg.size() > 0){
                //loop through contact's eventsAir function registration data
                for(Object funReg : lsteventsairfunReg) {
                    
                    Map<String, Object> eventFunReg = (Map<String, Object>) funReg;
                    Map<String, Object> eventFunregPaymentdetails = (Map<String, Object>) eventFunReg.get('paymentDetails');
                    Decimal totalcharge = (Decimal) eventFunregPaymentdetails.get('totalChargeAmount');
                    
                    //create contact and account in salesforce if not exist for paid registartions
                    if (totalcharge > 0 && !mapOfUniqueContactString.containsKey(CombinedString)) {
                        
                        // contact creation for paid function registrations
                        Contact objcon = new Contact();
                        objcon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Visitor').getRecordTypeId();  
                        
                        if (RecordType == 'Mumbrella') {
                            objcon.Business_Unit__c = 'Mumbrella';
                        } else {
                            List<Object> lsteventsairCustomFields = (List<Object>) eventConMap.get('customFields');
                            for (Object fields : lsteventsairCustomFields) {
                                Map<String, Object> customFieldsMap = (Map<String, Object>) fields;
                                String FieldName = (String) customFieldsMap.get('name');
                                if (FieldName != '' && FieldName != null) {
                                    if (FieldName =='Industry INT') {
                                        objcon.Industry__c =(String) customFieldsMap.get('value');
                                    }
                                    if (FieldName =='Industry SEC') {
                                        objcon.Industry__c =(String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Company Size'){
                                        objcon.Company_Size__c = (String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Job Function INT'){
                                        objcon.Job_Function__c = (String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Job Function SEC'){
                                        objcon.Job_Function__c = (String) customFieldsMap.get('value');
                                    }
                                }
                            }
                            objcon.Business_Unit__c = 'Divcom'; 
                        }
                        
                        objcon.Organization_Name__c = (String) eventConMap.get('organizationName');
                        objcon.EventsAir_Con_ID__c = (String) eventConMap.get('id');
                        String strFirstName = (String) eventConMap.get('firstName');
                        
                        if (strFirstName != null )  {
                            if(strFirstName.length() <= 40) {
                                objCon.FirstName = strFirstName.trim();
                            } else {
                                objCon.FirstName = strFirstName.substring(0,40).trim();
                            }
                        } else {
                            objCon.FirstName = '';
                        }
                        
                        String strLastName = (String) eventConMap.get('lastName');
                        if(strLastName == null || strLastName == '') {
                            objcon.LastName = 'UnKnown';
                        } else {
                            objcon.LastName = strLastName.trim();
                        }     
                        
                        String strjobTitle = (String) eventConMap.get('jobTitle');
                        if(strjobTitle == null || strjobTitle == '' ) {
                            objcon.Title = 'UnKnown';
                        } else {
                            objcon.Title = strjobTitle.trim();
                        }

                        //objCon.Events_Air_Contact_Id__c = (String) eventConMap.get('id');
                        String stremail = (String) eventConMap.get('primaryEmail');
                        if(stremail != null && stremail != '') {
                            stremail = stremail.trim();
                            objcon.Email = stremail;
                        } else {
                            objcon.Email = ''; 
                        }    
                        Object eventconphone = eventConMap.get('contactPhoneNumbers');
                        Map<String, Object> eventconphonemap = (Map<String, Object>) eventconphone;
                        if(eventconphonemap != null) {
                            objcon.MobilePhone = (String) eventconphonemap.get('mobile');
                        } 
                        if(setOfGenericDomain.contains(strAccdomainname)) {
                            // Assign AccountId to contact Prioirty :- organization name match                       
                            
                            if(MapOfexistingAccountsOrgNameAndAccountId.containsKey(orgName)){
                                objcon.AccountId = MapOfexistingAccountsOrgNameAndAccountId.get(orgName);
                            }
                        } else {              
                            // Assign AccountId to contact Prioirty :-  1) domain name match 2) organization name match                       
                            if(mapOfDomainNameAndAccId.containsKey(strAccdomainname)) {
                                objcon.AccountId = mapOfDomainNameAndAccId.get(strAccdomainname);
                            } else if(MapOfexistingAccountsOrgNameAndAccountId.containsKey(orgName)){
                                objcon.AccountId = MapOfexistingAccountsOrgNameAndAccountId.get(orgName);
                            }  
                        }
                        lstInsrtCon.add(objcon);

                    } else if (totalcharge > 0 && mapOfUniqueContactStringToUpdate.containsKey(CombinedString)) {
                        // update contact for paid function registration
                        Contact objCon = mapOfUniqueContactStringToUpdate.get(CombinedString);

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
                                    if (FieldName =='Industry INT' && (objCon.Industry__c == null || objCon.Industry__c == '')) {
                                        objcon.Industry__c =(String) customFieldsMap.get('value');
                                    }
                                    if (FieldName =='Industry SEC' && (objCon.Industry__c == null || objCon.Industry__c == '')) {
                                        objcon.Industry__c =(String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Company Size' && (objCon.Company_Size__c == null || objCon.Company_Size__c == '')){
                                        objcon.Company_Size__c = (String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Job Function INT' && (objCon.Job_Function__c == null || objCon.Job_Function__c == '')){
                                        objcon.Job_Function__c = (String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Job Function SEC' && (objCon.Job_Function__c == null || objCon.Job_Function__c == '')){
                                        objcon.Job_Function__c = (String) customFieldsMap.get('value');
                                    }
                                }
                            }
                        }

                        lstupdateCon.add(objCon);

                    } else if (!mapOfUniqueLeadString.containsKey(CombinedString)) {
                            
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
                        
                        newLead.Event_Category__c = eventCategory;
                        
                        if (RecordType == 'Mumbrella') {
                            newLead.Business_Unit__c = 'Mumbrella';
                        } else {
                            List<Object> lsteventsairCustomFields = (List<Object>) eventConMap.get('customFields');
                            
                            for (Object fields : lsteventsairCustomFields) {
                                Map<String, Object> customFieldsMap = (Map<String, Object>) fields;
                                String FieldName = (String) customFieldsMap.get('name');
                                if (FieldName != '' && FieldName != null) {
                                    if (FieldName =='Industry INT') {
                                        newLead.Industry__c =(String) customFieldsMap.get('value');
                                    }
                                    if (FieldName =='Industry SEC') {
                                        newLead.Industry__c =(String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Company Size'){
                                        newLead.Company_Size__c = (String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Job Function INT'){
                                        newLead.Job_Function__c = (String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Job Function SEC'){
                                        newLead.Job_Function__c = (String) customFieldsMap.get('value');
                                    }
                                }
                            }  
                            newLead.Business_Unit__c = 'Divcom';

                        }
                        Object eventconphone = eventConMap.get('contactPhoneNumbers');
                        Map<String, Object> eventconphonemap = (Map<String, Object>) eventconphone; 
                        if(eventconphonemap != null) {
                            newLead.MobilePhone = (String) eventconphonemap.get('mobile'); 
                        }            
                        String strOrganization = (String) eventConMap.get('organizationName');
                        if(strOrganization != null && strOrganization != '') {
                            newLead.Company = strOrganization;
                        }
                        else{
                            newLead.Company = 'Unknown';
                        }
                        newLead.Status = 'New';
                        lstInsrtLead.add(newLead);

                    } else if (mapOfUniqueLeadStringToUpdate.containsKey(CombinedString)) {
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
                                    if (FieldName =='Industry INT' && (newLead.Industry__c == null || newLead.Industry__c == '')) {
                                        newLead.Industry__c =(String) customFieldsMap.get('value');
                                    }
                                    if (FieldName =='Industry SEC' && (newLead.Industry__c == null || newLead.Industry__c == '')) {
                                        newLead.Industry__c =(String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Company Size' && (newLead.Company_Size__c == null || newLead.Company_Size__c == '')){
                                        newLead.Company_Size__c = (String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Job Function INT' && (newLead.Job_Function__c == null || newLead.Job_Function__c == '')){
                                        newLead.Job_Function__c = (String) customFieldsMap.get('value');
                                    }
                                    if(FieldName == 'Job Function SEC' && (newLead.Job_Function__c == null || newLead.Job_Function__c == '')){
                                        newLead.Job_Function__c = (String) customFieldsMap.get('value');
                                    }
                                }
                            }
                        }
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
        
        // fetch all contact after creating new contact records
        List<Contact> LstOfExtistingContact = [SELECT Id,FirstName, LastName,Email,CombinedString__c FROM Contact 
                                               WHERE CombinedString__c in :setOfCombinedEventsAirAttendee LIMIT 50000];            
        
        for(Contact objContact :LstOfExtistingContact){
            mapOfContactStringAndId.put(objContact.CombinedString__c, objContact.Id); 
        }
        
        // Insert Lead
        if (!lstInsrtLead.isEmpty() || !lstUpdateLead.isEmpty()) {
            insertLeadsIfNotExist(lstInsrtLead, mapOfUniqueLeadString, lstUpdateLead); 
            system.debug('insertLeadsIfNotExist');
        }
        
        // fetch all Lead
        List<Lead> LstOfExtistingLead = [SELECT Id,FirstName, LastName,Email,CombinedString__c FROM Lead 
                                         WHERE CombinedString__c in :setOfCombinedEventsAirAttendee LIMIT 50000];
        
        for(Lead objLead :LstOfExtistingLead) {
            mapOfLeadStringAndId.put(objLead.CombinedString__c, objLead.Id); 
        }
        
        
        
        List<Registration__c> lstInsrtReg = new List<Registration__c>(); 
        List<Opportunity> lstInsrtOpp = new List<Opportunity>();
        
        // fetch pricebook related to the event Record  
        List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: sfeventId LIMIT 50000];
        
        // Loop through event's air contacts data to create registration & product & Services
        for(Object objEventCon : lsteventsairContacts) {
            
            Map<String, Object> eventConMap = (Map<String, Object>) objEventCon;  
            List<Object> lsteventsairfunReg = (List<Object>) eventConMap.get('functionRegistrations');
            String strevntconId = (String) eventConMap.get('id');
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
            
            // create functions
            if(!lsteventsairfunReg.isEmpty()) {
                setupForFunctionReg(lsteventsairfunReg);                
            }
            
            if(lsteventsairfunReg != null && lsteventsairfunReg.size() > 0) {
                
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
                        if(mapOfContactStringAndId.containsKey(Finalstring) && mapOfLeadStringAndId.containsKey(Finalstring)) {
                            prodAndService.Lead__c = mapOfLeadStringAndId.get(Finalstring);
                        }else if(mapOfContactStringAndId.containsKey(Finalstring)){
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
                    objreg.EventsAir_Contact_Id__c = (String) eventConMap.get('id');
                    objreg.Event__c = sfeventId; 
                    
                    if(checkInDate != null) {
                        objreg.CheckInDate__c = (Datetime) JSON.deserialize('"' + checkInDate + '"', Datetime.class);                  
                    }
                    
                    if(checkOutDate != null) {
                        objreg.CheckOutDate__c  = (Datetime) JSON.deserialize('"' + checkOutDate + '"', Datetime.class);                     
                    }
                    
                    objreg.Number_of_Tickets__c = Decimal.valueOf(strtickets);
                    objreg.EventsAir_Function_Id__c = (String) tempfunmap.get('id');
                    
                    if(Finalstring != null && Finalstring != '') {
                        
                        // connect contact with paid function registrations
                        if( totalcharge > 0 && mapOfContactStringAndId.containsKey(Finalstring)) {
                            objreg.Contact__c = mapOfContactStringAndId.get(Finalstring);
                        }else {
                            // connect contact if it is created before
                            // if(mapOfContactStringAndId.containsKey(Finalstring)) {
                            //     objreg.Contact__c = mapOfContactStringAndId.get(Finalstring);
                            // }else{
                            // connect with exiting or newly created lead
                            if(mapOfLeadStringAndId.containsKey(Finalstring)) {
                                objreg.Lead__c = mapOfLeadStringAndId.get(Finalstring);
                            }   
                            // }
                        }
                    }
                    
                    if(eventregtypemap.get('name') != null) {
                        //if(!Test.isRunningTest()) {
                            objreg.Registration_Type__c = (String) eventregtypemap.get('name'); 
                        //}
                    }  
                    
                    if(eventregPaymentdetails.get('paymentStatus') != null) {
                        objreg.Payment_Status__c = (String) eventregPaymentdetails.get('paymentStatus');                     
                    } 
                    
                    if(objreg.Registration_Type__c != null) {
                        System.debug('objreg.Registration_Type__c '+objreg.Registration_Type__c);
                        System.debug('objreg.Registration_Type__c Containes :-> '+selectedValuesMap.containsKey(objreg.Registration_Type__c.trim()));
                		System.debug('selectedValuesMap :-> '+selectedValuesMap);
                        if (selectedValuesMap.containsKey(objreg.Registration_Type__c.trim())) {                            
                            lstInsrtReg.add(objreg);
                        }
                    }
                    // for paid function registration for create opportunity and it's opportunity products
                    if(totalcharge > 0 && selectedValuesMap.containsKey(objreg.Registration_Type__c.trim())) {   
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
        System.debug('lstInsrtReg '+lstInsrtReg.size());
        insertProdAndServicesIfNotExist(lstInsrtProdAndServices);
        List<Registration__c> regListForFunctionMapping = insertRegistrationIfNotExist(lstInsrtReg);
        LinkFunctionToRegistration(regListForFunctionMapping);
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
                                                          WHERE EventsAir_Regisration_ID__c IN: setOfEvnRegIds and Event__c =:sfeventId LIMIT 50000];
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
        
        if(finallisttoinsertOpp.size() > 0  && !test.isrunningtest()) {
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
            List<Object> lsteventsairfunReg = (List<Object>) eventConMap.get('functionRegistrations');
            String strevntconId = (String) eventConMap.get('id'); 
            
            if(lsteventsairfunReg != null && lsteventsairfunReg.size() > 0){
                //loop through event'sair function registration data
                for(Object objEventReg: lsteventsairfunReg) {
                    
                    Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                    Object eventfunregtype = eventReg.get('feeType');                    
                    Map<String, Object> eventregtypemap = (Map<String, Object>)eventfunregtype;
                    String strRegTypeId = (String) eventregtypemap.get('id');
                    
                    List<Object> lstfee;
                    string funregid = (String) eventReg.get('id');
                    
                    // create product based on function registration type
                    if(eventregtypemap != null && !setOfProdId.contains(strRegTypeId) && selectedValuesMap.containsKey((String) eventregtypemap.get('name'))) {
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
            List<Object> lsteventsairfunReg = (List<Object>) eventConMap.get('functionRegistrations');
            
            if(lsteventsairfunReg != null && lsteventsairfunReg.size() > 0){
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
                            if(mapOfEvnproandSfId.containsKey(strRegTypeId) && !setofProductId.contains(strRegTypeId) && selectedValuesMap.containsKey((String) eventregtypemap.get('name'))) {
                                
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
            
            List<Object> lsteventsairfunReg = (List<Object>) eventConMap.get('functionRegistrations');
            String strevntconId = (String) eventConMap.get('id'); 
            
            if(lsteventsairfunReg != null && lsteventsairfunReg.size() > 0){
                
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
                    if(totalcharge > 0 && selectedValuesMap.containsKey((String) eventregtypemap.get('name'))) {
                        
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
                            // oli.EventsAir_Regisration_ID__c = funregid;
                            
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
        List<OpportunityLineItem> lstexistingOlis = [SELECT Id, Function_Registration_Id__c, OpportunityId
                                                     FROM OpportunityLineItem 
                                                     WHERE Function_Registration_Id__c IN: setOfEvnOLIIds LIMIT 50000];
        
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
            LstOfEventsairRegId.add(oli.Function_Registration_Id__c);
            MapOfEventsairRegIdandOLI.put(oli.Function_Registration_Id__c,oli);    
        }
        
        // fetch all function registration with eventsAir function registration Id found in List " LstOfEventsairRegId "
        List<Registration__c> lstOfRegistrationtoLink = [select id,EventsAir_Regisration_ID__c,Opportunity_Product__c from Registration__c where EventsAir_Regisration_ID__c in:LstOfEventsairRegId LIMIT 50000 ];
        
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
                           WHERE EventsAir_ID__c IN: setOfEventFunId LIMIT 50000];
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

    // helper method for create function
    public void setupForFunctionReg(List<Object> lstobject) {
        
        List<Map<String, Object>> listOfFunctioninfomap = new List<Map<String, Object>>();
        
        //loop through event'sair function registration data for setup function start
        for(Object objEventReg: lstobject) {            
            Map<String, Object> eventReg = (Map<String, Object>)objEventReg;            
            Map<String, Object> tempfunmap = (Map<String, Object>)(eventReg.get('function')); 
            Map<String, Object> eventregtypemap = (Map<String, Object>) eventReg.get('feeType');

            if(String.isNotBlank(eventData[0].Function_Registration_Types__c) && eventregtypemap.get('name') != null && selectedValuesMap.containsKey((String) eventregtypemap.get('name'))) {          
                listOfFunctioninfomap.add(tempfunmap);            
            }else if(String.isBlank(eventData[0].Function_Registration_Types__c)) {
                listOfFunctioninfomap.add(tempfunmap);
            }        
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
        
        List<Function__c> LstOfExistingFunc = [SELECT Id,EventsAir_ID__c from Function__c where EventsAir_ID__c In :setofexistfuncId LIMIT 50000];
        
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
            List<Manage_EvtAir_Fun_Reg_Sec_And_Inte_Batch__c> lstcustsett2 = [SELECT Id, Name, Offset__c, Is_Execute_Next__c 
                                                                         FROM Manage_EvtAir_Fun_Reg_Sec_And_Inte_Batch__c LIMIT 1];            
            // Your finish logic goes here
            if(lstcustsett2[0].Is_Execute_Next__c == true) {
                
                //update offset in custom setting
                lstcustsett2[0].Offset__c = lstcustsett[0].Offset__c + contactsLimit;
                update lstcustsett2;
                
                ImportFunRegSeprateSecAndInteBatch newBatch = new ImportFunRegSeprateSecAndInteBatch(sfeventId);
                Database.executeBatch(newBatch, 500);
            }
            else {
                lstcustsett2[0].Is_Execute_Next__c = true;
                update lstcustsett2;
                
                System.debug('### sfeventId  = '+sfeventId);
                if(sfeventId != null){
                
                    FeedItem post = new FeedItem();
                    post.ParentId = sfeventId; //eg. Opportunity id, custom object id..
                    post.Body = 'Apex batch End for fetching EventsAir Function Registration Data';
                    insert post;   
                }             
            }
        }
        
        
    }
}