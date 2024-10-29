/*************************
* Created By : Foram 
* Cereated Date : 12-09-2023
* Description : Import Registration from Evntsair and 
Create Contact/Lead, Registartion
**************************/

public class ImportRegistartionFromEventsAirBatch implements Database.Batchable<ResponseWrapper>, Database.AllowsCallouts {
    
    //variable declartion
    public String strEventId;
    public String sfeventId;
    public String eventCategory;
    Integer contactsLimit = Integer.valueOf(System.Label.EventsAir_Attendee_Contact_Limit);
    Integer regLimit = Integer.valueOf(System.Label.EventsAir_Registartion_Limit);
    List<Contact> lstInsrtCon;
    List<Lead> lstInsrtLead;
    List<Product_Service_Option__c> lstInsrtProdAndServices;
    List<Function__c> lstInsrtFun;
    Map<String, Id> mapOfLeadStringAndId = new Map<String, Id>();
    Map<String, Id> mapOfContactStringAndId = new Map<String, Id>();
    Map<String, Id> mapOfEventregTypeAndSFproId = new Map<String, Id>();
    Set<String> setofProductId = new Set<String>();
    Map<String, Id> mapOfEvnproandSfId = new Map<String, Id>();
    Map<String, Id> mapOfEventRegTypeIdAndSFPBentryId = new Map<String, Id>();
    Map<String, Decimal> mapOfEventRegTypeIdAndSFPBentryPrice = new Map<String, Decimal>();
    String RecordType;
    //fetch current offset value from custom setting
    List<Manage_Eventsair_Reg_Apex_batch__c> lstcustsett = [Select Id, Name, Offset__c, Is_Execute_Next__c 
                                                            from Manage_Eventsair_Reg_Apex_batch__c LIMIT 1];
    
    public ImportRegistartionFromEventsAirBatch(String eventId, String strsfeventId) {        
        strEventId = eventId;
        sfeventId = strsfeventId;
    }
    
    public Iterable<ResponseWrapper> start(Database.BatchableContext BC) {  
        
        List<Event__c> eventData = [Select Id,Name,RecordType.Name FROM Event__c where Id =:sfeventId LIMIT 1];
        RecordType = eventData[0].RecordType.Name;
        //get access token
        String strtoken = EventsAirOAuthTokenRequest.getAccessToken(RecordType);
        String graphqlQuery;
        //Prepare API Query    
        if(RecordType != 'Mumbrella'){   
         graphqlQuery = '{' +
            '"query": "query GetEventData($eventId: ID!, $contactsLimit: PaginationLimit!, $conoffset: NonNegativeInt!, $regLimit: PaginationLimit!,$input: CustomFieldSearchFilterInput!,) {' +
            'event(id: $eventId) {' +
            'id,' +
            'name,' +
            'startDate,'+
            'endDate,'+ 
            'logo{'+
            'url,'+
            '},'+ 
            'contacts(offset: $conoffset, limit: $contactsLimit) { ' +
    		'customFields(input: $input , limit:3){name, definitionId,value},'+
            'marketingRecords(limit: 15){'+
            'id,' +
            'name,' +
            'tag {'+
            'id,' +
            'name,' +
            '},' +
            'value' +
            '},' +
            'id,' +
            'lastName,' +
            'firstName,' +
            'title,' +
            'lastModifiedAt,'+
            'organizationName,'+
            'checkInDate,'+
            'checkOutDate,'+
            'primaryEmail,'+
            'primaryAddress {' +
            'city,' + 
            'country,' + 
            'line1,' + 
            'line2,' + 
            'line3,' + 
            'postCode,' + 
            'state,' + 
            '},'+
            'contactPhoneNumbers {' +
            'mobile,' +      
            '},'+          
            'registrations(limit: $regLimit) {' +
            'id,' +
            'dateTime,' +   
            'type {' +
            'id,' +
            'name,' +   
            'uniqueCode,' + 
            'fees {' +
            'amount,' +      
            '},'+
            '},'+
            'paymentDetails {' +
            'paymentStatus,'+
              'discountAmount,'+
             'adjustmentAmount,'+
             'taxAmount,'+
            'totalChargeAmount,'+
             'discountCode {' +
            'code,' +
            '},'+
            '},'+
            '},' +            
            '}' +
            '}' +
            '}",' +
            '"variables": {' +
            '"eventId": "' + strEventId + '",' +
            '"contactsLimit": ' + contactsLimit + ',' +
            '"conoffset": ' + lstcustsett[0].Offset__c + ',' +
            '"regLimit": ' + regLimit  +  ','+
            '"input": { "names": ["Industry" ,"Company Size" , "Job Function"] }'  +           
            '}' +
            '}';
        }else {
            graphqlQuery = '{' +
            '"query": "query GetEventData($eventId: ID!, $contactsLimit: PaginationLimit!, $conoffset: NonNegativeInt!, $regLimit: PaginationLimit!,) {' +
            'event(id: $eventId) {' +
            'id,' +
            'name,' +
            'startDate,'+
            'endDate,'+ 
            'logo{'+
            'url,'+
            '},'+ 
            'contacts(offset: $conoffset, limit: $contactsLimit) { ' +
            'marketingRecords(limit: 15){'+
            'id,' +
            'name,' +
            'tag {'+
            'id,' +
            'name,' +
            '},' +
            'value' +
            '},' +
            'id,' +
            'lastName,' +
            'firstName,' +
            'title,' +
            'lastModifiedAt,'+
            'organizationName,'+
            'checkInDate,'+
            'checkOutDate,'+
            'primaryEmail,'+
            'primaryAddress {' +
            'city,' + 
            'country,' + 
            'line1,' + 
            'line2,' + 
            'line3,' + 
            'postCode,' + 
            'state,' + 
            '},'+
            'contactPhoneNumbers {' +
            'mobile,' +      
            '},'+          
            'registrations(limit: $regLimit) {' +
            'id,' +
            'dateTime,' +   
            'type {' +
            'id,' +
            'name,' +   
            'uniqueCode,' + 
            'fees {' +
            'amount,' +      
            '},'+
            '},'+
            'paymentDetails {' +
            'paymentStatus,'+
              'discountAmount,'+
             'adjustmentAmount,'+
             'taxAmount,'+
            'totalChargeAmount,'+
             'discountCode {' +
            'code,' +
            '},'+
            '},'+
            '},' +            
            '}' +
            '}' +
            '}",' +
            '"variables": {' +
            '"eventId": "' + strEventId + '",' +
            '"contactsLimit": ' + contactsLimit + ',' +
            '"conoffset": ' + lstcustsett[0].Offset__c + ',' +
            '"regLimit": ' + regLimit  +                        
            '}' +
            '}';
        }
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(120000);
        request.setEndpoint(System.Label.EventsAir_API_Base_URL);
        request.setMethod('POST');
        request.setBody(graphqlQuery);
        request.setHeader('Content-Type', 'application/json');
        
        // Set the Authorization header
        request.setHeader('Authorization', 'Bearer ' + strtoken);
        
        HttpResponse response = http.send(request);
        System.debug('@@@@ response = '+response.getBody());
        
        List<ResponseWrapper> lstofresponseWrapper = new List<ResponseWrapper>();
        ResponseWrapper responseWrapper = new ResponseWrapper();
        
        if (response.getStatusCode() == 200) {
            
            String responseBody = response.getBody(); 
            // Replace the with the correct format (reserved keyword)
            responseBody = responseBody.replace('"dateTime"', '"registrationDateTime"');
            responseBody = responseBody.replace('"date"', '"functiondate"');
            responseBody = responseBody.replace('"end"', '"functionend"');
            
            responseWrapper = (ResponseWrapper) JSON.deserialize(responseBody, ResponseWrapper.class);
            lstofresponseWrapper.add(responseWrapper);
        }        
        else{
            //update offset in custom setting if getting error in response
            lstcustsett[0].Is_Execute_Next__c = false;
            lstcustsett[0].Offset__c = 0;
            update lstcustsett;
        }        
        return lstofresponseWrapper;
    }
    
    public void execute(Database.BatchableContext BC, List<ResponseWrapper> responseWrapper) {
        
        String serializedResponseWrapper = JSON.serialize(responseWrapper[0]);
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(serializedResponseWrapper);
        Map<String, Object> eventDatamap = (Map<String, Object>) jsonResponse.get('data');        
        Map<String, Object> eventmap;
        if(eventDatamap != null) {
            eventmap = (Map<String, Object>) eventDatamap.get('event');   
        }
        
        //***  create pricebook if Is_Pricebook_Created__c is false on event *** 
        List<Event__c> lstevent = [SELECT Id, Name, EventsAirID__c, Open_Date__c, Close_Date__c, New_Event_Logo__c, Is_Pricebook_Created__c,Event_Category__c
                                   FROM Event__c
                                   WHERE Id =: sfeventId  Order By CreatedDate DESC LIMIT 1];
        List<Event__c> updteventlst = new List<Event__c>(); 
        List<Pricebook2> lstInsrtPricebook = new List<Pricebook2>();
        List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: sfeventId];
        String evtStartDate = (String) eventmap.get('startDate');
        String evtCloseDate = (String) eventmap.get('endDate');
        Map<String, Object> logoMap = (Map<String, Object>) eventmap.get('logo');
        String evtLogo = logoMap != null ? (String) logoMap.get('url') : null;

        if (eventmap != null && !lstevent.isEmpty()) {  
            if(lstevent[0].Event_Category__c != null){
                eventCategory = lstevent[0].Event_Category__c;
            }
            if(lstevent[0].Is_Pricebook_Created__c == false || (lstevent[0].Is_Pricebook_Created__c == true && lstPriceook.size() == 0)) {
                //Pricebook2 field mapping
                Pricebook2 newPricebook = new Pricebook2();
                newPricebook.Name = (String) eventmap.get('name')+' Visitor'; 
                newPricebook.Events__c = sfeventId;
                newPricebook.Description = 'Description of the pricebook'; 
                newPricebook.IsActive = true; // Set the pricebook as active
                lstInsrtPricebook.add(newPricebook);
                lstevent[0].Is_Pricebook_Created__c = true; //make is created pricebook checkbox to true on event
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
        
        if (!updteventlst.isEmpty()) {     
            update updteventlst;              
        }  
        
        if(!lstInsrtPricebook.isEmpty()) {
            insert lstInsrtPricebook;
        }

        List<Object> lsteventsairContacts = new List<Object>();
        if(eventmap != null){
           lsteventsairContacts = (List<Object>) eventmap.get('contacts'); //extract list of contas from event query
 		 }
        System.debug('### lsteventsairContacts size = '+lsteventsairContacts.size());
        if(lsteventsairContacts.size()>0){
             createRecords(lsteventsairContacts);
        }       
        
        if(lsteventsairContacts.isEmpty()) {
            //Update the offset in the custom setting to exit from the recursive batch.
            System.debug('@@@ All Data Synced');
            lstcustsett[0].Is_Execute_Next__c = false; //This is used to stop batch to run in recursion
            lstcustsett[0].Offset__c = 0;
            update lstcustsett;
        }            
    }
    
    public void createRecords(List<Object> lsteventsairContacts) {
 
        lstInsrtLead = new List<Lead>();
        lstInsrtCon = new List<Contact>();
        lstInsrtProdAndServices = new List<Product_Service_Option__c>();
        Set<String> setOfDomainName = new Set<String>();
        Map<String, Id> mapOfDomainNameAndAccId = new Map<String, Id>();
        Map<String, Id> mapOfDomainNameAndAccOwnerId = new Map<String, Id>();
        Set<String> AccountNamesForCheckCreation = new Set<String>();
        Map<String, String> accNeedToCreatePreName = new Map<String, String>();

        //Loop through event's air contacts data to extract contact's email domain name
        for(Object objeventcon: lsteventsairContacts) {

            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;            
            String strevntconemail = (String) eventconmap.get('primaryEmail');
            String orgNameForAccCreation = (String) eventconmap.get('organizationName');
            String orgNameOfAccountInSF;  //  used for check account name in salesforce
            String domainname;

            //add contact's domain name into set
            if(strevntconemail != null && strevntconemail != '') {
                String[] emailparts = strevntconemail.split('@');
                if (emailparts.size() > 1) {
                    setOfDomainName.add(emailparts[1].trim().toLowerCase());
                    
                    if (orgNameForAccCreation == null || orgNameForAccCreation == '') {
                        AccountNamesForCheckCreation.add(emailparts[1].trim().toLowerCase());
                        accNeedToCreatePreName.put(domainname, domainname);
                    }
                }
            }
           /* else {
                //add contact's organization name into set if con's domain name is null
                if(orgNameForAccCreation != null && orgNameForAccCreation != ''){
                    if (orgNameForAccCreation.length() > 80) {
                        orgNameOfAccountInSF = (orgNameForAccCreation.length() > 80) ? orgNameForAccCreation.substring(0, 80) : orgNameForAccCreation;    
                    } else{
                        orgNameOfAccountInSF = orgNameForAccCreation;
                    }
                    accNeedToCreatePreName.add(orgNameOfAccountInSF.toLowerCase());
                }
            } */

            // adding all organization name to the list and fetch account based on Organization name from Salesforce
            if(orgNameForAccCreation != null && orgNameForAccCreation != ''){
                if (orgNameForAccCreation.length() > 80) {
                    orgNameOfAccountInSF = (orgNameForAccCreation.length() > 80) ? orgNameForAccCreation.substring(0, 80) : orgNameForAccCreation;    
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

        //remove those account name from the list where it is already created before
        if (accNeedToCreatePreName.size() > 0) {
            List<Account> newCreateAccListOfOrgNames = [SELECT Id, Name, Domain_Name__c FROM Account 
                                                        WHERE Name IN :accNeedToCreatePreName.keySet()  AND 
                                                        Account_Status__c != 'Inactive' AND On_Hold__c = FALSE];

            List<Account> existingAccountsWithDomainName = [SELECT Id, Name,Domain_Name__c FROM Account WHERE Domain_Name__c IN :setOfDomainName AND Account_Status__c != 'Inactive' and On_Hold__c = false];
  
            if(newCreateAccListOfOrgNames.size() > 0){
                for(Account acc : newCreateAccListOfOrgNames){
                    accNeedToCreatePreName.remove(acc.Name.toLowerCase());
                }
            }

            if(existingAccountsWithDomainName.size() > 0){
                for(Account acc : existingAccountsWithDomainName){
                    accNeedToCreatePreName.remove(acc.Name.toLowerCase());
                }
            }
        }

        // remove those account name from the list (" accNeedToCreatePreName ") which contact has unpaid registrations 
        if(accNeedToCreatePreName.size() > 0){
            // Loop over each contact to check if registartion is paid or unpaid
            for(Object objeventcon: lsteventsairContacts) {
                Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
                List<Object> lsteventsairReg = (List<Object>) eventconmap.get('registrations');
                Boolean hasCharge = false; // Flag to track if any registration has totalChargeAmount > 0
                String orgNameForAccCreation = (String) eventconmap.get('organizationName');
                String orgNameOfAccountInSF;

                if(orgNameForAccCreation != null && orgNameForAccCreation != ''){
                    if (orgNameForAccCreation.length() > 80) {
                        orgNameOfAccountInSF = (orgNameForAccCreation.length() > 80) ? orgNameForAccCreation.substring(0, 80) : orgNameForAccCreation;    
                    } else{
                        orgNameOfAccountInSF = orgNameForAccCreation;
                    }
                }else {
                    String strevntconemail = (String) eventconmap.get('primaryEmail');
                    if(strevntconemail != null && strevntconemail != '') {
                        String[] emailparts = strevntconemail.split('@');
                        if (emailparts.size() > 1) {
                            orgNameOfAccountInSF = emailparts[1].trim().toLowerCase();
                        }
                    }
                }

                for(Object objEventReg : lsteventsairReg) {
                    Map<String, Object> eventReg = (Map<String, Object>) objEventReg;
                    Map<String, Object> eventregPaymentdetails = (Map<String, Object>) eventReg.get('paymentDetails');
                    Decimal totalcharge = (Decimal) eventregPaymentdetails.get('totalChargeAmount');

                    if(totalcharge > 0) {
                        hasCharge = true;
                        break; // Exit the loop as soon as we find a charge greater than 0
                    }  
                }
                if(!hasCharge){
                    if (orgNameOfAccountInSF != null && orgNameOfAccountInSF != '') {
                        accNeedToCreatePreName.remove(orgNameOfAccountInSF.toLowerCase());
                    }
                } 
            }
        }

        // fill the basic information for account creation and create account in sf for remaining organization name/domain name
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
                }else{
                    newAccount.Name = 'UNKNOWN';
                }
                newAccount.AccountSource = 'EventsAir';
                newAccount.Domain_Name__c = accNeedToCreatePreName.get(accName);
                listAccPreCreate.add(newAccount);
            }
            if (listAccPreCreate.size() > 0) {
                insert listAccPreCreate;
            }
            System.debug('Account Inserted SuccessFully');
        }
        

        //create map for if domain not match check for account name with organization name of event's Air data
        Map<String, String> MapOfexistingAccountsOrgNameAndAccountId = new Map<String, String>();
        if (AccountNamesForCheckCreation != null) {
            List<Account> exitingAccListOfOrgNames = [SELECT Id,Name,Domain_Name__c From Account Where Name IN :AccountNamesForCheckCreation  AND Account_Status__c != 'Inactive' and On_Hold__c = false];
        
            for (Account acct : exitingAccListOfOrgNames) {
                // map of organization name and accountId based on organization name for mapping with contact
                MapOfexistingAccountsOrgNameAndAccountId.put(acct.Name.toLowerCase(),acct.Id);
            }
        }

        //if set contains any value then do soql on account and fill the mapOfDomainNameAndAccId Map
        if(setOfDomainName != null) {
            for (AggregateResult aggregateResult : [
                SELECT MAX(CreatedDate) latestCreatedDate, Domain_Name__c, MAX(Id) accountId
                FROM Account
                WHERE Domain_Name__c IN: setOfDomainName and Account_Status__c != 'Inactive' and On_Hold__c = false
                GROUP BY Domain_Name__c
            ]) {
                String domain = (String)aggregateResult.get('Domain_Name__c');
                Id accountId = (Id)aggregateResult.get('accountId');
                
                if (accountId != null) {
                    // map of domain name and accountId for mapping based on domain name with contact
                    mapOfDomainNameAndAccId.put(domain.toLowerCase(), accountId);
                }
            }
            List<Account> LstOfAccount = [SELECT Id,OwnerId,Domain_Name__c from Account WHERE Domain_Name__c IN: setOfDomainName
                                            and Account_Status__c != 'Inactive' and On_Hold__c = false ];
            for(Account acc :LstOfAccount ){
                // used to give ownerId to opportunity based on domain name
                mapOfDomainNameAndAccOwnerId.put(acc.Domain_Name__c.toLowerCase(),acc.OwnerId);
            }
        }

        // fill the list of firstname + lastName + email for fetch lead and contact based on combined string
        Set<String> setOfCombinedEventsAirAttendee = new Set<String>(); 
        for (Object objeventcon : lsteventsairContacts) {
            String CombinedString = getCombinedString(objeventcon);
            setOfCombinedEventsAirAttendee.add(CombinedString);
        }
        
        // fetch contact from sf based on combined String
        List<Contact> checkforUnpaidRegis = [SELECT Id, FirstName, LastName, Email, CombinedString__c FROM Contact
                                             WHERE CombinedString__c in :setOfCombinedEventsAirAttendee];
        Map<String, Contact> mapOfContactStringAndContact = new Map<String, Contact>();
            
        //loop through existing Contacts and fill the map to use for mapping with registration
        for(Contact objContact :checkforUnpaidRegis){
            mapOfContactStringAndContact.put(objContact.CombinedString__c, objContact); 
        }

        // fetch Lead from sf based on combined String
        List<Lead> checkforUnpaidLeads = [SELECT Id,FirstName, LastName,Email,CombinedString__c FROM Lead
                                          WHERE CombinedString__c in :setOfCombinedEventsAirAttendee];
        Map<String, Lead> mapOfLeadStringAndLead = new Map<String, Lead>();
            
        //loop through existing Leads and fill the map to use for mapping with registration
        for(Lead objLead :checkforUnpaidLeads){
            mapOfLeadStringAndLead.put(objLead.CombinedString__c, objLead); 
        }

        // loop through event's air contact for create Lead/Contact based on Paid/Unpaid registrations
        for (Object objeventcon : lsteventsairContacts) {
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
            String strcontEmail = (String) eventconmap.get('primaryEmail');           
            String strAccdomainname;
            String orgNameForMap = (String) eventconmap.get('organizationName');
            List<Object> lsteventsairReg = (List<Object>) eventconmap.get('registrations');

            //extract domain name from contact's email
            if(strcontEmail != null && strcontEmail != '') {
                String[] emailparts = strcontEmail.split('@');
                if (emailparts.size() > 1) {
                    strAccdomainname = emailparts[1].trim().toLowerCase();
                }
            }
            if(orgNameForMap != null && orgNameForMap != ''){
                if (orgNameForMap.length() > 80) {
                    orgNameForMap = (orgNameForMap.length() > 80) ? orgNameForMap.substring(0, 80).toLowerCase() : orgNameForMap.toLowerCase();    
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

            for(Object reg : lsteventsairReg) {
                
                Map<String, Object> eventReg = (Map<String, Object>) reg;
                Map<String, Object> eventregPaymentdetails = (Map<String, Object>) eventReg.get('paymentDetails');
                Decimal totalcharge = (Decimal) eventregPaymentdetails.get('totalChargeAmount');
                String CombinedString = getCombinedString(objeventcon);
                
                // check for paid registration and it is not created before in salesforce than create contact and account
                if(totalcharge > 0 && !mapOfContactStringAndContact.containsKey(CombinedString)) {

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
                    }else{
                        objCon.FirstName = '';
                    }

                    String strLastName = (String) eventconmap.get('lastName');
                    if(strLastName == null || strLastName == '') {
                        objcon.LastName = 'UnKnown';
                    }
                    else{
                        objcon.LastName = strLastName.trim();
                    }     

                    //objCon.Events_Air_Contact_Id__c = (String) eventconmap.get('id');
                    String stremail = (String) eventconmap.get('primaryEmail');
                    if(stremail != null && stremail != '') {
                        stremail = stremail.trim();
                        objcon.Email = stremail;
                    }else{
                        objcon.Email = ''; 
                    }    
                    Object eventconphone = eventconmap.get('contactPhoneNumbers');
                    Map<String, Object> eventconphonemap = (Map<String, Object>) eventconphone;
                    if(eventconphonemap != null) {
                        objcon.MobilePhone = (String) eventconphonemap.get('mobile');
                    } 

                    //create contact if found the exiting account based on domain name and create account and contact if not found                        
                    if(mapOfDomainNameAndAccId.containsKey(strAccdomainname)) {
                        objcon.AccountId = mapOfDomainNameAndAccId.get(strAccdomainname);
                    }else if(MapOfexistingAccountsOrgNameAndAccountId.containsKey(orgNameForMap)){
                        System.debug('coming for organization Name :-' + MapOfexistingAccountsOrgNameAndAccountId.get(orgNameForMap));
                        objcon.AccountId = MapOfexistingAccountsOrgNameAndAccountId.get(orgNameForMap);
                    }
                    lstInsrtCon.add(objcon);
                }
                else{
                    // create lead if unpaid registration and it is not found in contact as well as lead
                    if(!mapOfContactStringAndContact.containsKey(CombinedString) && !mapOfLeadStringAndLead.containsKey(CombinedString)){

                        //create lead field mapping start
                        Lead newLead = new Lead();
                        newLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Visitor').getRecordTypeId();
                        String strFirstName = (String) eventconmap.get('firstName');
                        if (strFirstName != null )  {
                            if(strFirstName.length() <= 40) {
                                newLead.FirstName= strFirstName.trim();
                            } else {
                                newLead.FirstName = strFirstName.substring(0,40).trim();
                            }
                        }   
                        else{
                            strFirstName = ''; 
                        }
                        String strLastName = (String) eventconmap.get('lastName');
                        if(strLastName == null || strLastName == '' ) {
                            newLead.LastName = 'UnKnown';
                        }
                        else{
                            newLead.LastName = strLastName.trim();
                        }
                        //newLead.EventsAir_Contact_Id__c = (String) eventconmap.get('id');
                        String stremail = (String) eventconmap.get('primaryEmail');
                        if(stremail != null && stremail != '') {
                            stremail = stremail.trim();
                            newLead.Email = stremail;
                        }else{
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

        // Insert Contacts
        if (!lstInsrtCon.isEmpty()) {            
            insertContactsIfNotExist(lstInsrtCon, setOfCombinedEventsAirAttendee);   
            system.debug('insertContactsIfNotExist');
        }

        List<Contact> LstOfExtistingContact = [SELECT Id,FirstName, LastName,Email,CombinedString__c FROM Contact 
                                                WHERE CombinedString__c in :setOfCombinedEventsAirAttendee];            
        //loop through existing Contacts and fill the map
        for(Contact objContact :LstOfExtistingContact){
            mapOfContactStringAndId.put(objContact.CombinedString__c, objContact.Id); 
        }
        

        // Insert Lead
        if (!lstInsrtLead.isEmpty()) {
            insertLeadsIfNotExist(lstInsrtLead, setOfCombinedEventsAirAttendee); 
            system.debug('insertLeadsIfNotExist');
        }

            List<Lead> LstOfExtistingLead = [SELECT Id,FirstName, LastName,Email,CombinedString__c FROM Lead 
                                                WHERE CombinedString__c in :setOfCombinedEventsAirAttendee];
        
            //loop through existing leads and fill the map
            for(Lead objLead :LstOfExtistingLead) {
                mapOfLeadStringAndId.put(objLead.CombinedString__c, objLead.Id); 
            }
            
        
            // Loop through event's air contacts data to create Product & Services
            for(Object objeventcon : lsteventsairContacts) {
                Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
                List<Object> lsteventsairReg = ((List<Object>) eventconmap.get('registrations'));
                if (lsteventsairReg.size() > 0) {
                
                    List<Object> lsteventsairRecMarket = (List<Object>) eventconmap.get('marketingRecords');
                    String strevntconId = (String) eventconmap.get('id');
                    
                    for(Object objEventMarketing : lsteventsairRecMarket) {
                        Map<String, Object> prodAndSerMap = (Map<String, Object>) objEventMarketing;

                        // Map<String, Object> lsteventsairRecMarketTag = (Map<String, Object>) prodAndSerMap.get('tag');
                        // System.debug('lsteventsairRecMarketTag :---->' + lsteventsairRecMarketTag);

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
            System.debug('lstInsrtProdAndServices from mumbrella:-->' + lstInsrtProdAndServices);   
            insertProdAndServicesIfNotExist(lstInsrtProdAndServices);


            List<Registration__c> lstInsrtReg = new List<Registration__c>(); 
            List<Opportunity> lstInsrtOpp = new List<Opportunity>();        
            List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: sfeventId];
            Pricebook2 standardPriceBook = [ SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
            
            // Loop through event's air contacts data to create registration
            for(Object objeventcon : lsteventsairContacts) {
                Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
                List<Object> lsteventsairReg = (List<Object>) eventconmap.get('registrations');
                String strevntconId = (String) eventconmap.get('id');
                String checkInDate = (String) eventconmap.get('checkInDate');
                String checkOutDate = (String) eventconmap.get('checkOutDate');
                boolean isexecuted = false;
                
                String strcontEmail = (String) eventconmap.get('primaryEmail');           
                String strAccdomainname;
                
                //extract domain name from contact's email
                if(strcontEmail != null && strcontEmail != '') {
                    String[] emailparts = strcontEmail.split('@');
                    if (emailparts.size() > 1) {
                        strAccdomainname = emailparts[1].trim().toLowerCase();
                    }
                }
                
                for(Object objEventReg : lsteventsairReg) {
                    Map<String, Object> eventReg = (Map<String, Object>) objEventReg;
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
                    if (checkOutDate != null) {
                        objreg.CheckOutDate__c	 = (Datetime) JSON.deserialize('"' + checkOutDate + '"', Datetime.class);  
                    }
                    String Finalstring = getCombinedString(objeventcon);

                    if(Finalstring != null && Finalstring != '') {
                        // connect contact with paid registrations
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
                    
                    Map<String, Object> eventregtype = (Map<String, Object>) eventReg.get('type');
                    if(eventregtype.get('name') != null) {
                        if(!Test.isRunningTest()) {
                            objreg.Registration_Type__c = (String) eventregtype.get('name');
                        }
                    }
                    
                    if(eventregPaymentdetails.get('paymentStatus') != null) {
                        objreg.Payment_Status__c = (String) eventregPaymentdetails.get('paymentStatus');
                    }
                    
                    lstInsrtReg.add(objreg);
                    String OrganizationName;
                    if(eventconmap.get('organizationName') != null){
                        String orgName = (String) eventconmap.get('organizationName');
                        OrganizationName = (orgName.length() > 80) ? orgName.substring(0, 80).trim().toLowerCase() : orgName.trim().toLowerCase();
                    }
                    if(totalcharge > 0 ) {
                        //if(mapOfDomainNameAndAccId.containsKey(strAccdomainname)) {
                            
                            isexecuted = true;
                            system.debug('totalcharge'+totalcharge);
                            //Opportunity field Mapping start
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
                            objOpp.Pricebook2Id =lstPriceook[0].Id;
                            objOpp.stageName = 'Closed Won'; 
                            
                            objOpp.NetSuite_Integration_Status__c = 'DoNotSync';
                            lstInsrtOpp.add(objOpp); 
                            System.debug('objOpp '+objOpp);                    
                        //} 
                    }
                    
                }
            }
            
            insertRegistrationIfNotExist(lstInsrtReg);
            insertOpportunityIfNotExist(lstInsrtOpp);
            createOpportunityProduct(lsteventsairContacts, lstInsrtOpp);        
    }
    
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
    
    // to insert only new Contacts if not exist in salesforce
    public static void insertContactsIfNotExist(List<Contact> contactsToInsert , Set<String> setOfCombinedEventsAirAttendee) {

         //fetch existing Contacts based on Combined name and email
        List<Contact> LstOfExtistingContact = [Select Id,FirstName, LastName,Email,CombinedString__c from Contact where CombinedString__c in :setOfCombinedEventsAirAttendee];
        Map<String, Id> mapOfContactStringAndIds = new Map<String, Id>();
        
        //loop through existing Contacts and fill the map
        for(Contact objContact :LstOfExtistingContact){
           mapOfContactStringAndIds.put(objContact.CombinedString__c, objContact.Id); 
        }

        // List<Contact> ListOfContactToInsert = new List<Contact>();
        List<Contact> FinalListOfContactToInsert = new List<Contact>();
        // List<Contact> ListOfContactToUpdate = new List<Contact>();
        // Set<String> setOfCurrentContactCombinedDataToCheckForUpdate = new Set<String>();
        Set<String> setOfCurrentContactCombinedData = new Set<String>();
        
        for(Contact objcontact :contactsToInsert){
             String strcombinedEventsAirAttendee= objcontact.FirstName+objcontact.LastName+objcontact.Email; 
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            
            if(!mapOfContactStringAndIds.ContainsKey(strcombinedEventsAirAttendee)){
                // this is for check current batch duplicate data
                if(!setOfCurrentContactCombinedData.contains(strcombinedEventsAirAttendee)){
                    //  ListOfContactToInsert.add(objcontact);
                    FinalListOfContactToInsert.add(objcontact);
                    setOfCurrentContactCombinedData.add(strcombinedEventsAirAttendee);
                }
            }
            // else{
            //     system.debug('contact already exist in Salesforce');
            //     if(!setOfCurrentContactCombinedDataToCheckForUpdate.contains(strcombinedEventsAirAttendee)){
            //         objcontact.Id = mapOfContactStringAndIds.get(strcombinedEventsAirAttendee);
            //         ListOfContactToUpdate.add(objcontact);
            //         setOfCurrentContactCombinedDataToCheckForUpdate.add(strcombinedEventsAirAttendee);
            //     }else {
            //         System.debug('attendee already added');
            //     }
            // }
        }
       
        // for(Contact objcontact :ListOfContactToInsert){
        //     FinalListOfContactToInsert.add(objcontact);   
        // }
        
         if(FinalListOfContactToInsert.size()>0){
            Database.insert(FinalListOfContactToInsert,false);
        }

        // if(ListOfContactToUpdate.size() > 0){
            // Database.SaveResult[] updateResults = Database.update(ListOfContactToUpdate, false);
            // for (Database.SaveResult sr : updateResults) {
            //     if (!sr.isSuccess()) {
            //         system.debug('Failed to update Contact Id: ' + sr.getId() + ', Error: ' + sr.getErrors()[0].getMessage());
            //     }
            // }
        // }
        
        // List<Contact> LstConForMapping = [Select Id,CombinedString__c from Contact where CombinedString__c in :setOfCombinedEventsAirAttendee];
        // // for adding the new Leads in Map
        // for(Contact objcontact :LstConForMapping){
        //     mapOfContactStringAndIds.put(objcontact.CombinedString__c, objcontact.Id); 
        // }
        // return mapOfContactStringAndIds;
        
       
    }

    // to insert only new Leads if not exist in salesforce
    public static void insertLeadsIfNotExist(List<Lead> leadsToInsert, Set<String> setOfCombinedEventsAirAttendee) {
    
        //fetch existing leads based on Combined name and email
        List<Lead> LstOfExtistingLead = [Select Id,FirstName, LastName,Email,CombinedString__c from Lead where CombinedString__c in :setOfCombinedEventsAirAttendee];
        Map<String, Id> mapOfLeadStringAndId = new Map<String, Id>();
        
        //loop through existing leads and fill the map
        for(Lead objLead :LstOfExtistingLead){
            mapOfLeadStringAndId.put(objLead.CombinedString__c, objLead.Id); 
        }

        // List<Lead> ListOfLeadToInsert = new List<Lead>();
        List<Lead> FinalListOfLeadToInsert = new List<Lead>();
        Set<String> setOfCurrentleadCombinedData = new Set<String>();
        
        for(Lead objLead :leadsToInsert){
            String strcombinedEventsAirAttendee= objLead.FirstName+objLead.LastName+objLead.Email; 
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            //check if lead exist or not
            if(!mapOfLeadStringAndId.ContainsKey(strcombinedEventsAirAttendee)){
                // this is for check current batch duplicate data
                if(!setOfCurrentleadCombinedData.contains(strcombinedEventsAirAttendee)){
                        // ListOfLeadToInsert.add(objLead);
                        FinalListOfLeadToInsert.add(objLead);
                    setOfCurrentleadCombinedData.add(strcombinedEventsAirAttendee);
                }
            }
        }
        
        if(FinalListOfLeadToInsert.size()>0){
            insert FinalListOfLeadToInsert;
        }
         
    }

    public void insertProdAndServicesIfNotExist(List<Product_Service_Option__c> lstInsrtProdAndServices) {
        system.debug('insertProdAndServicesIfNotExist'+ lstInsrtProdAndServices.size());
        Map<String, Id> mapOfEvnPrdSericeIdandSfPrdServiceId = new Map<String, Id>();
        set<String> setOfEvnProdServiceIds = new set<String>();
        
        for(Product_Service_Option__c prodAndService: lstInsrtProdAndServices) {
            setOfEvnProdServiceIds.add(prodAndService.EventsAirMarketing_Record_ID__c);
        }
        
        //do soql on registartion to fetch data based on eventsair registration id
        List<Product_Service_Option__c> lstexistingProdAndService = [SELECT Id, EventsAirMarketing_Record_ID__c
                                                          FROM Product_Service_Option__c 
                                                          WHERE EventsAirMarketing_Record_ID__c IN: setOfEvnProdServiceIds];
        system.debug('lstexistingProdAndService'+lstexistingProdAndService.size());
        if(lstexistingProdAndService.size() > 0) {
            for(Product_Service_Option__c existingProdAndService: lstexistingProdAndService) {
                mapOfEvnPrdSericeIdandSfPrdServiceId.put(existingProdAndService.EventsAirMarketing_Record_ID__c, existingProdAndService.Id);
            }
        }
        
        List<Product_Service_Option__c> finallisttoinsertProdAndService = new List<Product_Service_Option__c>();
        List<Product_Service_Option__c> finallisttoUpdateProdAndService = new List<Product_Service_Option__c>();

        for(Product_Service_Option__c newProdAndService: lstInsrtProdAndServices) {
            if(!mapOfEvnPrdSericeIdandSfPrdServiceId.containskey(newProdAndService.EventsAirMarketing_Record_ID__c)) {
                finallisttoinsertProdAndService.add(newProdAndService);
            }else{
                newProdAndService.Id = mapOfEvnPrdSericeIdandSfPrdServiceId.get(newProdAndService.EventsAirMarketing_Record_ID__c);
                finallisttoUpdateProdAndService.add(newProdAndService);
            }
        }
        system.debug('finallisttoinsertProdAndService'+finallisttoinsertProdAndService.size());
        if(finallisttoinsertProdAndService.size() >0) {
            system.debug('finallisttoinsertProdAndService'+finallisttoinsertProdAndService.size());
            insert finallisttoinsertProdAndService ;
        }
        if(finallisttoUpdateProdAndService.size() >0) {
            system.debug('finallisttoUpdateProdAndService'+finallisttoUpdateProdAndService.size());
            update finallisttoUpdateProdAndService ;
        }
        
    }
    
    public void insertRegistrationIfNotExist(List<Registration__c> lstInsrtReg) {
        system.debug('insertRegistrationIfNotExist'+lstInsrtReg.size());
        Map<String, Id> mapOfEvnRegIdandSfRegId = new Map<String, Id>();
        set<String> setOfEvnRegIds = new set<String>();
        
        for(Registration__c reg: lstInsrtReg) {
            setOfEvnRegIds.add(reg.EventsAir_Regisration_ID__c);
        }
        
        //do soql on registartion to fetch data based on eventsair registration id
        List<Registration__c> lstexistingRegistrations = [SELECT Id, EventsAir_Regisration_ID__c
                                                          FROM Registration__c 
                                                          WHERE EventsAir_Regisration_ID__c IN: setOfEvnRegIds and Event__c =:sfeventId];
        system.debug('lstexistingRegistrations'+lstexistingRegistrations.size());
        system.debug('sfeventId'+sfeventId);
        if(lstexistingRegistrations.size() > 0) {
            for(Registration__c existingreg: lstexistingRegistrations) {
                mapOfEvnRegIdandSfRegId.put(existingreg.EventsAir_Regisration_ID__c, existingreg.Id);
            }
        }
        
        List<Registration__c> finallisttoinsertreg = new List<Registration__c>();
        List<Registration__c> listtoUpdatereg = new List<Registration__c>();
        
        for(Registration__c newreg: lstInsrtReg) {
            if(!mapOfEvnRegIdandSfRegId.containskey(newreg.EventsAir_Regisration_ID__c)) {
                finallisttoinsertreg.add(newreg);
            }else {
                newreg.Id = mapOfEvnRegIdandSfRegId.get(newreg.EventsAir_Regisration_ID__c);
                listtoUpdatereg.add(newreg);
            }
        }

        if(finallisttoinsertreg.size() >0) {
            // system.debug('finallisttoinsertreg'+finallisttoinsertreg.size());
            insert finallisttoinsertreg ;
        }
        if (listtoUpdatereg.size() > 0) {
           // update listtoUpdatereg;
        }
        
    }
    // method to insert new Opportunity(no duplicates) in salesforce
    public void insertOpportunityIfNotExist(List<Opportunity> lstInsrtOpp) {
    
        Map<String, Id> mapOfEvnconIdandSfOppId = new Map<String, Id>();
        set<String> setOfEvnconIds = new set<String>();
        
        for(Opportunity opp: lstInsrtOpp) {
            setOfEvnconIds.add(opp.EventsAir_Contact_Id__c);
        }
        
        //do soql on opportunity to fetch data based on eventsair contact id
        List<Opportunity> lstexistingOpps = [SELECT Id, EventsAir_Contact_Id__c
                                                FROM Opportunity 
                                                WHERE EventsAir_Contact_Id__c IN: setOfEvnconIds];

        List<Contact> lstexistingContacts = [SELECT Id, EventsAir_Con_ID__c,AccountId
                                                FROM Contact 
                                                WHERE EventsAir_Con_ID__c IN: setOfEvnconIds];
        
        Map<String, Id> mapOfContactevtAirIdAndContact = new Map<String, Id>();

        for (Contact con : lstexistingContacts) {
            mapOfContactevtAirIdAndContact.put(con.EventsAir_Con_ID__c, con.accountId);
        }
        System.debug('mapOfContactevtAirIdAndContact :->' + mapOfContactevtAirIdAndContact);
        if(lstexistingOpps.size() > 0) {
            for(Opportunity existingOpp: lstexistingOpps) {
                mapOfEvnconIdandSfOppId.put(existingOpp.EventsAir_Contact_Id__c, existingOpp.Id);
            }
        }
        
        List<Opportunity> finallisttoinsertOpp = new List<Opportunity>();
        Set<String> oppNames = new Set<String>();
        
        for(Opportunity newopp: lstInsrtOpp) {
            if(!mapOfEvnconIdandSfOppId.containskey(newopp.EventsAir_Contact_Id__c) && !oppNames.contains(newopp.Name)) {
                System.debug('mapOfContactevtAirIdAndContact.get(newopp.EventsAir_Contact_Id__c) :->' + mapOfContactevtAirIdAndContact.get(newopp.EventsAir_Contact_Id__c));
                System.debug('newopp.accountId' + newopp.accountId);
                if (( newopp.accountId != null) && mapOfContactevtAirIdAndContact.containsKey(newopp.EventsAir_Contact_Id__c) ) {
                    newopp.accountId =mapOfContactevtAirIdAndContact.get(newopp.EventsAir_Contact_Id__c);
                } 
                finallisttoinsertOpp.add(newopp);
                oppNames.add(newopp.Name);
            }
        }
        
        if(finallisttoinsertOpp.size() >0  && !test.isrunningtest()) {
            insert finallisttoinsertOpp;
        }
        for(Opportunity newopp: finallisttoinsertOpp) {
            mapOfEvnconIdandSfOppId.put(newopp.EventsAir_Contact_Id__c, newopp.Id);
        }
    }
    
    public void createOpportunityProduct(List<Object> lsteventsairContacts,List<Opportunity> lstInsrtOpp) {
        
        List<OpportunityLineItem> lstInsertOppProduct = new List<OpportunityLineItem>();
        Set<String> setOfProdId = new Set<String>();
        List<Product2> lstInsertproduct = new List<Product2>();
        List<PricebookEntry> lstInsertPricebookEntry = new  List<PricebookEntry>(); 
        Map<String, Id> mapOfEventConAndSFOppId = new Map<String, Id>();
        Map<String, Object> eventregPaymentdetails;
        Decimal totalcharge;
        // String strtickets;
        //String strRegTypeId;
        //ring strevntconId;
        
        //fetch pricebook
        List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: sfeventId];
        Pricebook2 standardPriceBook = [ SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
        
        List<Opportunity> lstofOpportunity = [select id,Name,CreatedDate,EventsAir_Contact_Id__c from Opportunity where id in :lstInsrtOpp];
        
        for(Opportunity opp: lstofOpportunity) {
            mapOfEventConAndSFOppId.put(opp.EventsAir_Contact_Id__c, opp.Id);
            system.debug('mapOfEventConAndSFOppId'+mapOfEventConAndSFOppId);
        }
        
        
        
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;  
            
            List<Object> lsteventsairRegistrations = (List<Object>) eventconmap.get('registrations');
            String strevntconId = (String) eventconmap.get('id'); 
            // System.debug('@@@ lsteventsairRegistrations = '+lsteventsairRegistrations);
            
            //loop through event'sair registration data
            for(Object objEventReg: lsteventsairRegistrations) {
                //Registartion field mapping start
                Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                
                Map<String, Object> eventregtypemap;
                List<Object> lstfee;
                string funregid = (String) eventReg.get('id');
                 Object eventregtype = eventReg.get('type');                    
                 eventregtypemap = (Map<String, Object>)eventregtype; 
                //Object eventfunregtype = eventReg.get('feeType');                    
               // eventregtypemap = (Map<String, Object>)eventfunregtype;
               String strRegTypeId = (String) eventregtypemap.get('id');
              string strRegTypeName = (String) eventregtypemap.get('Name');
                
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
        
        if (!lstInsertproduct.isEmpty()) {
            //Database.insert(lstInsertproduct, Product2.Fields.EventsAir_ID__c, true);
            System.debug('### lstInsertproduct = '+lstInsertproduct);
            //insert lstInsertproduct;
            //============================
            
            //Map<String, Id> mapOfEvnproandSfId = new Map<String, Id>();
            set<String> setOfEvnproIds = new set<String>();
            
            for(Product2 p: lstInsertproduct) {
                setOfEvnproIds.add(p.EventsAir_ID__c);
            }
            
            //do soql on con to fetch data based on eventsair contact id
            List<Product2> lstexistingproducts = [SELECT Id, EventsAir_ID__c
                                                  FROM Product2 
                                                  WHERE EventsAir_ID__c IN: setOfEvnproIds];
            
            if(lstexistingproducts.size() > 0) {
                for(Product2 existingpr: lstexistingproducts) {
                    mapOfEvnproandSfId.put(existingpr.EventsAir_ID__c, existingpr.Id);
                }
            }
            
            List<Product2> finallisttoinsertproduct= new List<Product2>();
            
            for(Product2 newpr: lstInsertproduct) {
                if(!mapOfEvnproandSfId.containskey(newpr.EventsAir_ID__c)) {
                    finallisttoinsertproduct.add(newpr);
                }
            }
            
            if(finallisttoinsertproduct.size() >0) {
                system.debug(' finallisttoinsertproduct'+finallisttoinsertproduct);
                insert finallisttoinsertproduct;
            }
            //================================
            for(Product2 prod: finallisttoinsertproduct) {
                mapOfEvnproandSfId.put(prod.EventsAir_ID__c, prod.Id);
            }
            system.debug(' mapOfEvnproandSfId'+mapOfEvnproandSfId);
        }
        
        
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;  
            
            List<Object> lsteventsairRegistrations = (List<Object>) eventconmap.get('registrations');
            String strevntconId = (String) eventconmap.get('id'); 
           // System.debug('@@@ lsteventsairRegistrations = '+lsteventsairRegistrations);
            
            //loop through event'sair registration data
            for(Object objEventReg: lsteventsairRegistrations) {
                //Registartion field mapping start
                Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                
                Map<String, Object> eventregtypemap;
                List<Object> lstfee;
                string funregid = (String) eventReg.get('id');
                
                Object eventfunregtype = eventReg.get('type');                    
                eventregtypemap = (Map<String, Object>)eventfunregtype;
                String strRegTypeId = (String) eventregtypemap.get('id');
                List<Map<String, Object>> listOfFunFeetypemap = new List<Map<String, Object>>();
                lstfee = (List<Object>) eventregtypemap.get('fees'); 
                
                for(Object objfee: lstfee) {
                    
                    Map<String, Object> feemap = (Map<String, Object>)objfee;
                    
                    if(mapOfEvnproandSfId.containsKey(strRegTypeId) && !setofProductId.contains(strRegTypeId)) {
                        system.debug(' pricebook');
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
                        system.debug(' mapOfEvnproandSfId'+mapOfEvnproandSfId);
                        system.debug(' strRegTypeId'+strRegTypeId);
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
            //check for existing pricebookentry end
            
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
        
        
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;  

            List<Object> lsteventsairRegistrations = (List<Object>) eventconmap.get('registrations');
            String strevntconId = (String) eventconmap.get('id'); 
            // System.debug('@@@ lsteventsairRegistrations = '+lsteventsairRegistrations);
            if(lsteventsairRegistrations.size()>0){
                //loop through event'sair registration data
                for(Object objEventReg: lsteventsairRegistrations) {
                    //Registartion field mapping start
                    Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                    String discountcodeval;
                    Map<String, Object> eventregtypemap;
                    Map<String, Object> eventregPaydetailcodedetail;
                    string funregid = (String) eventReg.get('id');
                      Object eventfunregtype = eventReg.get('type');                    
                eventregtypemap = (Map<String, Object>)eventfunregtype;
                String strRegTypeId = (String) eventregtypemap.get('id');
                    // System.debug('@@@ strRegTypeId = '+strRegTypeId);
                    Object eventregPaydetail = eventReg.get('paymentDetails');                    
                    eventregPaymentdetails = new Map<String, Object>();
                    eventregPaymentdetails = (Map<String, Object>)eventregPaydetail;
                    totalcharge = (Decimal)eventregPaymentdetails.get('totalChargeAmount');
                    // strtickets = (String) eventReg.get('tickets');
                    if(eventregPaymentdetails.get('discountCode') != null){
                        Object eventregPaydetailcode = eventregPaymentdetails.get('discountCode');
                        eventregPaydetailcodedetail = (Map<String, Object>)eventregPaydetailcode;
                        system.debug('eventregPaydetailcodedetail'+eventregPaydetailcodedetail);
                        system.debug('eventregPaydetailcodedetail.get'+eventregPaydetailcodedetail.get('code'));
                        if(eventregPaydetailcodedetail.get('code') != null){
                            discountcodeval = (String)eventregPaydetailcodedetail.get('code');
                        } 
                    }
                     
                    
                    // system.debug('totalcharge'+totalcharge);
                    
                    if(totalcharge > 0){
                        //OpportunityLineItem field mapping start
                        system.debug('totalcharge'+totalcharge);
                        if( mapOfEventConAndSFOppId.containsKey(strevntconId)  && mapOfEventRegTypeIdAndSFPBentryId.containskey(strRegTypeId)) {

                            String Finalstring = getCombinedString(objeventcon);

                            OpportunityLineItem oli = new OpportunityLineItem();
                            system.debug('mapOfEventConAndSFOppId.get(strevntconId)'+mapOfEventConAndSFOppId.get(strevntconId)+' '+strevntconId);
                            system.debug(' mapOfEventRegTypeIdAndSFPBentryId.get(strRegTypeId)'+ mapOfEventRegTypeIdAndSFPBentryId.get(strRegTypeId));
                            oli.OpportunityId = mapOfEventConAndSFOppId.get(strevntconId);                    
                            oli.PricebookEntryId = mapOfEventRegTypeIdAndSFPBentryId.get(strRegTypeId);
                            oli.Quantity = 1;
                            oli.Product2Id =mapOfEvnproandSfId.get(strRegTypeId); 
                            oli.EventsAir_Adjustment__c = (Decimal) eventregPaymentdetails.get('adjustmentAmount');
                            oli.EventsAir_Discount_Amount__c = (Decimal) eventregPaymentdetails.get('discountAmount');
                            if(discountcodeval != null){
                                oli.EventsAir_Discount_Code__c = discountcodeval;  
                            }
                            System.debug('@@@ eventregPaymentdetails = '+eventregPaymentdetails);
                            System.debug('@@@ eventregPaymentdetail ='+eventregPaymentdetails.get('taxAmount') );
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
                            /* if(mapOfEventRegTypeIdAndSFPBentryPrice.containskey(strRegTypeId)) {
                        oli.TotalPrice = oli.Quantity * (mapOfEventRegTypeIdAndSFPBentryPrice.get(strRegTypeId));   
                        } */
                            system.debug('oli'+oli);
                            lstInsertOppProduct.add(oli);
                        }
                    }
                }
            }
        }
        List<OpportunityLineItem> listOliForLinkOppWithReg = new List<OpportunityLineItem>();

        //Database.upsert(lstInsertOppProduct, OpportunityLineItem.Function_Registration_Id__c, false);
        
        Map<String, Id> mapOfEvnOLIandSfId = new Map<String, Id>();
        set<String> setOfEvnOLIIds = new set<String>();
        
        for(OpportunityLineItem oli: lstInsertOppProduct) {
            setOfEvnOLIIds.add(oli.Function_Registration_Id__c);
        }
        
        //do soql on con to fetch data based on eventsair contact id
        List<OpportunityLineItem> lstexistingOlis = [SELECT Id, Function_Registration_Id__c
                                                        FROM OpportunityLineItem 
                                                        WHERE Function_Registration_Id__c IN: setOfEvnOLIIds];
        
        if(lstexistingOlis.size() > 0) {
            for(OpportunityLineItem existingoli: lstexistingOlis) {
                mapOfEvnOLIandSfId.put(existingoli.Function_Registration_Id__c, existingoli.Id);
            }
        }
        if(!lstInsertOppProduct.isEmpty()) {
 
            List<OpportunityLineItem> finallisttoinsertoli= new List<OpportunityLineItem>();
            
            for(OpportunityLineItem newoli: lstInsertOppProduct) {
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
        listOliForLinkOppWithReg.addAll(lstexistingOlis);
        UpdateRegistrationsOLI(listOliForLinkOppWithReg);
    }

    public static void UpdateRegistrationsOLI(List<OpportunityLineItem> listOliForLinkOppWithReg){
        system.debug(listOliForLinkOppWithReg);
        List<string> LstOfEventsairRegId = new List<string>(); 
        Map<string,OpportunityLineItem> MapOfEventsairRegIdandOLI = new Map<string,OpportunityLineItem>();
        for(OpportunityLineItem oli : listOliForLinkOppWithReg){
            LstOfEventsairRegId.add(oli.EventsAir_Regisration_ID__c);
            MapOfEventsairRegIdandOLI.put(oli.EventsAir_Regisration_ID__c,oli);
            
        }
        
        List<Registration__c> lstOfRegistrationtoLink = [select id,EventsAir_Regisration_ID__c,Opportunity_Product__c from Registration__c where EventsAir_Regisration_ID__c in:LstOfEventsairRegId ];
        
        for(Registration__c reg : lstOfRegistrationtoLink){
            reg.Opportunity_Product__c = MapOfEventsairRegIdandOLI.get(reg.EventsAir_Regisration_ID__c).Id;
            reg.Opportunity__c = MapOfEventsairRegIdandOLI.get(reg.EventsAir_Regisration_ID__c).OpportunityId;
        }   
        //update lstOfRegistrationtoLink;
        Database.update(lstOfRegistrationtoLink,false);
        
    }    
  
    
    public void finish(Database.BatchableContext BC) {
        
        
        if(!test.isrunningtest()) {
            List<Manage_Eventsair_Reg_Apex_batch__c> lstcustsett2 = [SELECT Id, Name, Offset__c, Is_Execute_Next__c 
                                                                     FROM Manage_Eventsair_Reg_Apex_batch__c LIMIT 1];            
            // Your finish logic goes here
            if(lstcustsett2[0].Is_Execute_Next__c == true) {
                
                // update offset in custom setting
                lstcustsett2[0].Offset__c = lstcustsett[0].Offset__c + contactsLimit;
                update lstcustsett2;
                
                ImportRegistartionFromEventsAirBatch newBatch = new ImportRegistartionFromEventsAirBatch(strEventId, sfeventId);
                Database.executeBatch(newBatch, 500);
            }
            else {
                lstcustsett2[0].Is_Execute_Next__c = true;
                update lstcustsett2;
                
                System.debug('### sfeventId  = '+sfeventId);
                FeedItem post = new FeedItem();
                post.ParentId = sfeventId; //eg. Opportunity id, custom object id..
                post.Body = 'Apex batch End for fetching EventsAir Registration Data';
                insert post;                
            }
        }            
    }
}