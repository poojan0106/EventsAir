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
    List<Product_Service_Option__c> lstInsrtProdAndServices; 
    List<Function__c> lstInsrtFun;        
    Map<String, Id> mapofConEmailAndId = new Map<String, Id>();
    Map<String, Id> mapOfEventregTypeAndSFproId = new Map<String, Id>();
    Set<String> setofProductId = new Set<String>();
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
        
        System.debug('%%% strEventId = '+strEventId);
        List<Event__c> eventData = [Select Id,Name,RecordType.Name FROM Event__c where Id =:sfeventId LIMIT 1];
        RecordType = eventData[0].RecordType.Name;
        System.debug('%%% lstcustsett[0].Offset__c = '+lstcustsett[0].Offset__c);
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
        System.debug('@@@e@ respons = '+response.getBody());
        
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
        system.debug('hi in execute');
        
        //***  create pricebook if Is_Pricebook_Created__c is false on event *** 
        List<Event__c> lstevent = [SELECT Id, Name, EventsAirID__c, Open_Date__c, Close_Date__c, New_Event_Logo__c, Is_Pricebook_Created__c,Event_Category__c
                                   FROM Event__c
                                   WHERE EventsAirID__c =: strEventId  Order By CreatedDate DESC LIMIT 1];
        List<Event__c> updteventlst = new List<Event__c>(); 
        List<Pricebook2> lstInsrtPricebook = new List<Pricebook2>();
        String evtStartDate = (String) eventmap.get('startDate');
        String evtCloseDate = (String) eventmap.get('endDate');
        String evtLogo = (String) eventmap.get('logo');
        System.debug('LOGO :-' + evtLogo);
        if (eventmap != null && !lstevent.isEmpty()) {  
            eventCategory = lstevent[0].Event_Category__c;
            if(lstevent[0].Is_Pricebook_Created__c == false) {
                //Pricebook2 field mapping
                Pricebook2 newPricebook = new Pricebook2();
                newPricebook.Name = (String) eventmap.get('name')+' Visitor'; 
                newPricebook.Events__c = lstevent[0].Id;
                newPricebook.Description = 'Description of the pricebook'; 
                newPricebook.IsActive = true; // Set the pricebook as active
                lstInsrtPricebook.add(newPricebook);
                lstevent[0].Is_Pricebook_Created__c = true; //make is created pricebook checkbox to true on event
            }                           
            updteventlst.add(lstevent[0]);
        }
        
        if (!updteventlst.isEmpty()) {     
            if (evtStartDate != null) {
                updteventlst[0].Open_Date__c = (Datetime) JSON.deserialize('"' + evtStartDate + '"', Datetime.class);     
            }
            if (evtCloseDate != null) {
                updteventlst[0].Close_Date__c = (Datetime) JSON.deserialize('"' + evtCloseDate + '"', Datetime.class);     
            }      
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
       
        
        if(lsteventsairContacts.isEmpty() && lsteventsairContacts.isEmpty()) {
            //update offset in custom setting
            System.debug('@@@ All Data Synced');
            lstcustsett[0].Is_Execute_Next__c = false; //This is used to stop batch to run in recursion
            lstcustsett[0].Offset__c = 0;
            update lstcustsett;
        }            
    }
    
    public void createRecords(List<Object> lsteventsairContacts) {
        
        lstInsrtCon = new List<Contact>();
        lstInsrtProdAndServices = new List<Product_Service_Option__c>();
        Set<String> setOfDomainName = new Set<String>();
        Map<String, Id> mapOfDomainNameAndAccId = new Map<String, Id>();
        
        system.debug('createRecords');
        //Loop through event's air contacts data to extract contact's email domain name
        for(Object objeventcon: lsteventsairContacts) {

            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;            
            String strevntconemail = (String) eventconmap.get('primaryEmail');            

            if(strevntconemail != null && strevntconemail != '') {
                String[] emailparts = strevntconemail.split('@');
                if (emailparts.size() > 1) {
                    setOfDomainName.add(emailparts[1].trim().toLowerCase());
                }
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
                    mapOfDomainNameAndAccId.put(domain.toLowerCase(), accountId);
                }
            }
        }

        Map<String, Account> existingAccountsMap = new Map<String, Account>();
        List<Account> accountToInsertList = new List<Account>();

        // Retrieve existing Accounts
        List<Account> existingAccounts = [SELECT Id, Name,Domain_Name__c FROM Account WHERE Domain_Name__c IN :setOfDomainName AND Account_Status__c != 'Inactive' and On_Hold__c = false];
        for (Account acc : existingAccounts) {
            existingAccountsMap.put(acc.Domain_Name__c.toLowerCase(), acc);
        }

        List<Event__c> eventData = [Select Id,Name,RecordType.Name FROM Event__c where Id =:sfeventId LIMIT 1];
        RecordType = eventData[0].RecordType.Name;
        // Loop through event's air contacts data to extract contact's email domain name and Insert Contact if not exist
        for (Object objeventcon : lsteventsairContacts) {
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
            String strcontEmail = (String) eventconmap.get('primaryEmail');           
            String strAccdomainname;
            
            //extract domain name from contact's email
            if(strcontEmail != null && strcontEmail != '') {
                String[] emailparts = strcontEmail.split('@');
                if (emailparts.size() > 1) {
                    strAccdomainname = emailparts[1].trim().toLowerCase();
                }
            }
            

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
            } else {
                String orgName = (String) eventconmap.get('organizationName');
                if (!existingAccountsMap.containsKey(strAccdomainname)  && strAccdomainname != '' && strAccdomainname != null) {
                   Account newAccount = new Account();
                    if (RecordType == 'Mumbrella') {
                        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mumbrella').getRecordTypeId();
                    } else {
                        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Diversified').getRecordTypeId();     
                    }
                    if(orgName != null && orgName != ''){
                        newAccount.Name = (orgName.length() > 80) ? orgName.substring(0, 80) : orgName;
                    }else{
                        newAccount.Name = strAccdomainname;
                    }
                    newAccount.AccountSource = 'EventsAir';
                    newAccount.Domain_Name__c = strAccdomainname;
                    accountToInsertList.add(newAccount);
                    existingAccountsMap.put(newAccount.Domain_Name__c, newAccount); 
                }
            }
            lstInsrtCon.add(objcon);
        }
        System.debug('lstInsrtCon :---->' + lstInsrtCon);

        // Insert Accounts
            if (!accountToInsertList.isEmpty()) {            
                insert accountToInsertList;
                Map<String, Id> MapOfDomainNameAndId = new Map<String, Id>();

                for (Account acc : accountToInsertList) {
                    MapOfDomainNameAndId.put(acc.Domain_Name__c.toLowerCase(), acc.Id);
                    
                }
                // link new account and contact based on domain name of contact email
                for (Contact con : lstInsrtCon) {
                    String ContactEmailDomainName;
                    if(con.Email != null && con.Email != '') {
                        String[] emailparts = con.Email.split('@');
                        if (emailparts.size() > 1) {
                            ContactEmailDomainName = emailparts[1].trim().toLowerCase();
                        }
                    }
                    if (ContactEmailDomainName != null && ContactEmailDomainName != '') {
                       if (MapOfDomainNameAndId.containskey(ContactEmailDomainName)) {
                            con.accountId = MapOfDomainNameAndId.get(ContactEmailDomainName);
                       } 
                    }
                }
            }

        // Insert Contacts
        if (!lstInsrtCon.isEmpty()) {            
            mapofConEmailAndId = insertContactsIfNotExist(lstInsrtCon);   
            system.debug('insertContactsIfNotExist');
        }

        // Loop through event's air contacts data to create Product & Services
        for(Object objeventcon : lsteventsairContacts) {
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
            List<Object> lsteventsairRecMarket = (List<Object>) eventconmap.get('marketingRecords');
            String strevntconId = (String) eventconmap.get('id');
            
            for(Object objEventMarketing : lsteventsairRecMarket) {
                Map<String, Object> prodAndSerMap = (Map<String, Object>) objEventMarketing;

                // Map<String, Object> lsteventsairRecMarketTag = (Map<String, Object>) prodAndSerMap.get('tag');
                // System.debug('lsteventsairRecMarketTag :---->' + lsteventsairRecMarketTag);

                String prodAndServiceName = (String) prodAndSerMap.get('name');
                
                Product_Service_Option__c prodAndService = new Product_Service_Option__c();
                prodAndService.EventsAirMarketing_Record_ID__c = (String) prodAndSerMap.get('id');
                prodAndService.Name =  prodAndServiceName;
                prodAndService.Marketing_Value__c = (String) prodAndSerMap.get('value');

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
                
                if(streventconlname != null){
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
                if(Finalstring != null && Finalstring != '') {
                    if(mapofConEmailAndId.containsKey(Finalstring)) {
                        prodAndService.Contact__c = mapofConEmailAndId.get(Finalstring);
                    }
                }

                lstInsrtProdAndServices.add(prodAndService);         
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
                
                if(streventconlname != null){
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
                if(Finalstring != null && Finalstring != '') {
                    if(mapofConEmailAndId.containsKey(Finalstring)) {
                        objreg.Contact__c = mapofConEmailAndId.get(Finalstring);
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
                
            }
        }
        
        insertRegistrationIfNotExist(lstInsrtReg);
        
    }
    
     
    
    // to insert only new Contacts if not exist in salesforce
    public static Map<String, Id> insertContactsIfNotExist(List<Contact> contactsToInsert) {
         Set<String> setOfCombinedEventsAirAttendee = new Set<String>(); 
        
        //loop through Contact list to combined the attendee data        
        for(Contact objcontact: contactsToInsert) {
            String strcombinedEventsAirAttendee= objcontact.FirstName+objcontact.LastName+objcontact.Email;
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            setOfCombinedEventsAirAttendee.add(strcombinedEventsAirAttendee);
            system.debug('@@setOfCombinedEventsAirAttendee - for new'+setOfCombinedEventsAirAttendee);
        }
        
         //fetch existing Contacts based on Combined name and email
        List<Contact> LstOfExtistingContact = [Select Id,FirstName, LastName,Email,CombinedString__c from Contact where CombinedString__c in :setOfCombinedEventsAirAttendee];
        Map<String, Id> mapOfContactStringAndId = new Map<String, Id>();
        
        //loop through existing Contacts and fill the map
        for(Contact objContact :LstOfExtistingContact){
           mapOfContactStringAndId.put(objContact.CombinedString__c, objContact.Id); 
        }
        system.debug('@@mapOfContactStringAndId'+mapOfContactStringAndId);
        List<Contact> ListOfContactToInsert = new List<Contact>();
         List<Contact> FinalListOfContactToInsert = new List<Contact>();
        Set<String> setOfCurrentContactCombinedData = new Set<String>();
        
        for(Contact objcontact :contactsToInsert){
             String strcombinedEventsAirAttendee= objcontact.FirstName+objcontact.LastName+objcontact.Email; 
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            
            //check if lead exist or not
            if(!mapOfContactStringAndId.ContainsKey(strcombinedEventsAirAttendee)){
                // this is for check current batch duplicate data
                if(!setOfCurrentContactCombinedData.contains(strcombinedEventsAirAttendee)){
                     ListOfContactToInsert.add(objcontact);
                    setOfCurrentContactCombinedData.add(strcombinedEventsAirAttendee);
                }
                else{
                    system.debug('contact alreaded added');
                }
               
            }else{
                system.debug('contact already exist in Salesforce');
            }
        }
       
        for(Contact objcontact :ListOfContactToInsert){
            /*if(isValidEmail(objcontact.Email)) {
                
                system.debug('valid');
                
            }*/
            FinalListOfContactToInsert.add(objcontact);
            
        }
        
         if(FinalListOfContactToInsert.size()>0){
            Database.insert(FinalListOfContactToInsert,false);
        }
        
        List<Contact> LstOfInnsertedCon = [Select Id,CombinedString__c from Contact where Id in :FinalListOfContactToInsert];
        system.debug('LstOfInnsertedCon- size'+LstOfInnsertedCon.size());
        // for adding the new Leads in Map
        for(Contact objcontact :LstOfInnsertedCon){
            mapOfContactStringAndId.put(objcontact.CombinedString__c, objcontact.Id); 
        }
        system.debug('@@mapOfContactStringAndId'+mapOfContactStringAndId);
         system.debug('@@mapOfContactStringAndId - size'+mapOfContactStringAndId.size());
        return mapOfContactStringAndId;
        
       
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
        
        for(Product_Service_Option__c newProdAndService: lstInsrtProdAndServices) {
            if(!mapOfEvnPrdSericeIdandSfPrdServiceId.containskey(newProdAndService.EventsAirMarketing_Record_ID__c)) {
                finallisttoinsertProdAndService.add(newProdAndService);
            }
        }
        system.debug('finallisttoinsertProdAndService'+finallisttoinsertProdAndService.size());
        if(finallisttoinsertProdAndService.size() >0) {
            system.debug('finallisttoinsertProdAndService'+finallisttoinsertProdAndService.size());
            insert finallisttoinsertProdAndService ;
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
        
        for(Registration__c newreg: lstInsrtReg) {
            if(!mapOfEvnRegIdandSfRegId.containskey(newreg.EventsAir_Regisration_ID__c)) {
                finallisttoinsertreg.add(newreg);
            }
        }
        system.debug('finallisttoinsertreg'+finallisttoinsertreg.size());
        if(finallisttoinsertreg.size() >0) {
            system.debug('finallisttoinsertreg'+finallisttoinsertreg.size());
            insert finallisttoinsertreg ;
        }
        
    }
    
    public void finish(Database.BatchableContext BC) {
        
        
        if(!test.isrunningtest()) {
            List<Manage_Eventsair_Reg_Apex_batch__c> lstcustsett2 = [SELECT Id, Name, Offset__c, Is_Execute_Next__c 
                                                                     FROM Manage_Eventsair_Reg_Apex_batch__c LIMIT 1];            
            // Your finish logic goes here
            if(lstcustsett2[0].Is_Execute_Next__c == true) {
                
                //update offset in custom setting
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