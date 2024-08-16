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
    List<Product_Service_Option__c> lstInsrtProdAndServices;
    List<Function__c> lstInsrtFun; 
    List<Function__c> ListToFinalInsert;
    Map<String, Id> mapofConEmailAndId = new Map<String, Id>();
    Map<String, Id> mapOfEventregTypeAndSFproId = new Map<String, Id>();
    Map<String, Id> mapOfEvnproandSfId = new Map<String, Id>();
    Map<String, Id> mapOfFunctandSfId = new Map<String, Id>();
    Set<String> setofProductId = new Set<String>();
    Map<String, Id> mapOfEventRegTypeIdAndSFPBentryId = new Map<String, Id>();
    Map<String, Decimal> mapOfEventRegTypeIdAndSFPBentryPrice = new Map<String, Decimal>();
    String RecordType;
    //fetch current offset value from custom setting
    List<Manage_Eventsair_Fun_Reg_Apex_batch__c> lstcustsett = [Select Id, Name, Offset__c, Is_Execute_Next__c 
                                                                from Manage_Eventsair_Fun_Reg_Apex_batch__c LIMIT 1];
    public ImportFuncRegistartionFromEventsAirBatch(String eventId, String strsfeventId) {
        // List<Event__c> lstEvent = [Select Id, EventsAirID__c from Event__c where Batch_Execution_Time__c != null Limit 1];
        
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
                'functionRegistrations(limit: $regLimit) {' +
                'id,' +
                'tickets,'+  
                'checkInDate,' +
                'checkOutDate,' +
                'feeType {' +
                'id,' +            
                'name,' + 
                'uniqueCode,' + 
                'fees {' +
                'amount,' +      
                '},'+
                '},'+
                'function{' +
                'id,' +
                'name,' +
                'start,' +
                'date,' +
                'end,' +
                'overview,' +
                'details,' +
                '},'+
                'paymentDetails {' +
                'paymentStatus,'+
                'discountAmount,' +
                'adjustmentAmount,' +
                'taxAmount,' +
                'totalChargeAmount,'+     
                'discountCode {' +
                'code,' +
                '},'+
                '},'+
                '}'+            
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
            'functionRegistrations(limit: $regLimit) {' +
            'id,' +
            'tickets,'+  
            'checkInDate,' +
            'checkOutDate,' +
            'feeType {' +
            'id,' +            
            'name,' + 
            'uniqueCode,' + 
            'fees {' +
            'amount,' +      
            '},'+
            '},'+
            'function{' +
            'id,' +
            'name,' +
            'start,' +
            'date,' +
            'end,' +
            'overview,' +
            'details,' +
            '},'+
            'paymentDetails {' +
            'paymentStatus,'+
            'discountAmount,' +
            'adjustmentAmount,' +
            'taxAmount,' +
            'totalChargeAmount,'+     
            'discountCode {' +
            'code,' +
            '},'+
            '},'+
            '}'+            
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
        System.debug('@@@ response = '+response);
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
        System.debug('strEventId '+strEventId);
        //***  create pricebook if Is_Pricebook_Created__c is false on event *** 
        List<Event__c> lstevent = [SELECT Id, Name, EventsAirID__c, Open_Date__c, Close_Date__c, New_Event_Logo__c, Is_Pricebook_Created__c,Event_Category__c
                                   FROM Event__c
                                   WHERE EventsAirID__c =: strEventId   Order By CreatedDate DESC LIMIT 1];
        List<Event__c> updteventlst = new List<Event__c>(); 
        List<Pricebook2> lstInsrtPricebook = new List<Pricebook2>();
        System.debug('lsteventsairContacts '+lstevent[0].Event_Category__c);
        
        String evtStartDate = (String) eventmap.get('startDate');
        String evtCloseDate = (String) eventmap.get('endDate');
        String evtLogo = (String) eventmap.get('logo');
        System.debug('LOGO :-' + evtLogo);

        if (eventmap != null && !lstevent.isEmpty()) {
            if(lstevent[0].Event_Category__c != null){
                eventCategory = lstevent[0].Event_Category__c; 
            }
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
            system.debug('lstInsrtPricebook'+lstInsrtPricebook);  
            insert lstInsrtPricebook;
        }
        
        List<Object> lsteventsairContacts = new List<Object>();
        if(eventmap != null){
            lsteventsairContacts = (List<Object>) eventmap.get('contacts'); 
        }
        
        System.debug('lsteventsairContacts '+lsteventsairContacts);
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
        List<Registration__c> lstInsrtReg = new List<Registration__c>(); 
        List<Opportunity> lstInsrtOpp = new List<Opportunity>();
        Set<String> setOfDomainName = new Set<String>();
        Map<String, Id> mapOfDomainNameAndAccId = new Map<String, Id>();
        Map<String, Id> mapOfDomainNameAndAccOwnerId = new Map<String, Id>();
        
        
        //Loop through event's air contacts data to extract contact's email domain name
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;            
            String strevntconemail = (String) eventconmap.get('primaryEmail');            
            
            System.debug('@@@ strevntconemail = '+strevntconemail);
            if(strevntconemail != null && strevntconemail != '') {
                String[] emailparts = strevntconemail.split('@');
                if (emailparts.size() > 1) {
                    setOfDomainName.add(emailparts[1].trim().toLowerCase());
                }
            }
        }
        
        System.debug('@@@ setOfDomainName = '+setOfDomainName);
        System.debug('@@@ setOfDomainName size = '+setOfDomainName.size());
        
        //if set contains any value then do soql on account and fill the mapOfDomainNameAndAccId Map
        if(setOfDomainName != null) {
            for (AggregateResult aggregateResult : [
                SELECT MAX(CreatedDate) latestCreatedDate, Domain_Name__c, MAX(Id) accountId
                FROM Account
                WHERE Domain_Name__c IN: setOfDomainName  and Account_Status__c != 'Inactive' and On_Hold__c = false 
                GROUP BY Domain_Name__c
            ]) {
                String domain = (String)aggregateResult.get('Domain_Name__c');
                Id accountId = (Id)aggregateResult.get('accountId');
                
                if (accountId != null) {
                    mapOfDomainNameAndAccId.put(domain.toLowerCase(), accountId);
                }
            }
            List<Account> LstOfAccount = [SELECT Id,OwnerId,Domain_Name__c from Account WHERE Domain_Name__c IN: setOfDomainName
                                          and Account_Status__c != 'Inactive' and On_Hold__c = false ];
            for(Account acc :LstOfAccount ){
                mapOfDomainNameAndAccOwnerId.put(acc.Domain_Name__c,acc.OwnerId);
            }
        }
        System.debug('@@@ mapOfDomainNameAndAccId ='+mapOfDomainNameAndAccId);
        
        List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: sfeventId];
        Pricebook2 standardPriceBook = [ SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
        Map<String, Account> existingAccountsMap = new Map<String, Account>();
        List<Account> accountToInsertList = new List<Account>();

        // Retrieve existing Accounts
        List<Account> existingAccounts = [SELECT Id, Name,Domain_Name__c FROM Account WHERE Domain_Name__c IN :setOfDomainName AND Account_Status__c != 'Inactive' and On_Hold__c = false];
        for (Account acc : existingAccounts) {
            existingAccountsMap.put(acc.Domain_Name__c.toLowerCase(), acc);
        }

        List<Event__c> eventData = [Select Id,Name,RecordType.Name FROM Event__c where Id =:sfeventId LIMIT 1];
        RecordType = eventData[0].RecordType.Name;

        //Loop through event's air contacts data to check if need to create contact and Account based on account's domain name
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
        
        System.debug('@@@ lstInsrtCon = '+lstInsrtCon);
        System.debug('@@@2 lstInsrtCon Size = '+lstInsrtCon.size());

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
            //List<Contact> lstContacts = removeContactsDuplicates(lstInsrtCon);
            mapofConEmailAndId = insertContactsIfNotExist(lstInsrtCon);   
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

        System.debug('lstInsrtProdAndServices :-->' + lstInsrtProdAndServices);   
        insertProdAndServicesIfNotExist(lstInsrtProdAndServices);
            
        //Loop through event's air contacts data to create registartion and prepare list of function registration list for all contact
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;  
            Map<String, Object> eventregtypemap = new Map<String, Object>();            
            List<Object> lsteventsairfunReg = ((List<Object>) eventconmap.get('functionRegistrations'));
            String strevntconId = (String) eventconmap.get('id');
            boolean isexecuted = false;
            
            String strcontEmail = (String) eventconmap.get('primaryEmail');           
            String strAccdomainname;
            
            //extract domain name from contact's email
            if(strcontEmail != null && strcontEmail != '') {
                String[] emailparts = strcontEmail.split('@');
                if (emailparts.size() > 1) {
                    strAccdomainname = emailparts[1].trim();
                }
            }
            
            if(!lsteventsairfunReg.isEmpty()) {
                setupForFunctionReg(lsteventsairfunReg);                
            }
            
            //loop through event'sair registration data
            for(Object objEventReg: lsteventsairfunReg) {
                
                Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                Map<String, Object> eventregPaymentdetails;
                Map<String, Object> eventregPaydetailcodedetail;
                Object eventfunregtype = eventReg.get('feeType');                    
                eventregtypemap = (Map<String, Object>)eventfunregtype;                
                Object eventregPaydetail = eventReg.get('paymentDetails');                    
                eventregPaymentdetails = (Map<String, Object>)eventregPaydetail;                
                String strRegDate = (String) eventReg.get('registrationDateTime'); 
                Decimal totalcharge = (Decimal)eventregPaymentdetails.get('totalChargeAmount');
                
                
                //Registartion field mapping start
                Registration__c objreg = new Registration__c();                
                objreg.RecordTypeId = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Function_Registration').getRecordTypeId(); 
                objreg.EventsAir_Regisration_ID__c = (String) eventReg.get('id');
                objreg.EventsAir_Contact_Id__c = (String) eventconmap.get('id');
                objreg.Event__c = sfeventId; 
                String strtickets = (String) eventReg.get('tickets');
                string FunctionId;
                objreg.Number_of_Tickets__c = Decimal.valueOf(strtickets);
                Map<String, Object> tempfunmap = (Map<String, Object>)(eventReg.get('function'));
                /* if(tempfunmap.containsKey('id')) {
FunctionId =(String) tempfunmap.get('id');
objreg.EventsAir_Function_Id__c =  mapOfFunctandSfId.get(FunctionId);
} */
                objreg.EventsAir_Function_Id__c = (String) tempfunmap.get('id');
                String streventconEmail = (String) eventconmap.get('primaryEmail');
                String streventconfname = (String) eventconmap.get('firstName');
                String streventconlname = (String) eventconmap.get('lastName');  
                String checkInDate = (String) eventReg.get('checkInDate');
                String checkOutDate = (String) eventReg.get('checkOutDate');             
                if(streventconlname == null || streventconlname == '') {
                    streventconlname = '';
                }
                string fname;
                string lname; 
                string email;
                
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
                if(eventregtypemap.get('name') != null){
                    if(!Test.isRunningTest()){
                        objreg.Registration_Type__c = (String) eventregtypemap.get('name'); 
                    }
                }                
                if(eventregPaymentdetails.get('paymentStatus') != null) {
                    objreg.Payment_Status__c = (String) eventregPaymentdetails.get('paymentStatus');                     
                } 
                if(checkInDate != null) {
                    objreg.CheckInDate__c =  (Datetime) JSON.deserialize('"' + checkInDate + '"', Datetime.class);                  
                }
                if(checkOutDate != null) {
                    objreg.CheckOutDate__c = (Datetime) JSON.deserialize('"' + checkOutDate + '"', Datetime.class);                     
                }
                lstInsrtReg.add(objreg); 
                
               
                System.debug('@@@ isexecuted = '+isexecuted);
                System.debug('@@@ totalcharge = '+totalcharge);
                
                if(totalcharge > 0 && isexecuted == false) {
                    if(mapOfDomainNameAndAccId.containsKey(strAccdomainname)) {
                        
                        isexecuted = true;
                        system.debug('totalcharge'+totalcharge);
                        system.debug('eventconmap.get(firstName)'+eventconmap.get('firstName'));
                        system.debug('eventconmap.get(lastName)'+eventconmap.get('lastName'));
                        //Opportunity field Mapping start
                        Opportunity objOpp = new Opportunity();
                        String strOppName = 'Opportunity created for '+(String) eventconmap.get('firstName')+' '+(String) eventconmap.get('lastName');
                        objOpp.Name = strOppName;
                        objOpp.AccountId = mapOfDomainNameAndAccId.get(strAccdomainname);
                        
                        if(mapOfDomainNameAndAccOwnerId.containsKey(strAccdomainname)){
                            objOpp.OwnerId = mapOfDomainNameAndAccOwnerId.get(strAccdomainname);
                        }
                        
                        objOpp.Is_Private__c = false;	
                        objOpp.LeadSource = 'EventsAir';
                        objOpp.Closedate = System.today();
                        objOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Divcom_Visitor').getRecordTypeId();
                        objOpp.Event__c = sfeventId;
                        objOpp.EventsAir_Contact_Id__c = strevntconId;
                        objOpp.Pricebook2Id =lstPriceook[0].Id;
                        objOpp.stageName = 'Closed Won'; 
                        
                        objOpp.NetSuite_Integration_Status__c = 'DoNotSync';
                        lstInsrtOpp.add(objOpp); 
                        System.debug('objOpp '+objOpp);                    
                    } 
                }
            }            
        }        
        // insertRegistration(lstInsrtReg);   
        // createOpportunities(lstInsrtOpp);
        // createOpportunityProduct(lsteventsairContacts,lstInsrtOpp);
        
        insertRegistrationIfNotExist(lstInsrtReg);
        insertOpportunityIfNotExist(lstInsrtOpp);
        createOpportunityProduct(lsteventsairContacts, lstInsrtOpp);
    }
    
    public void createOpportunityProduct(List<Object> lsteventsairContacts,List<Opportunity> lstInsrtOpp) {
        
        List<OpportunityLineItem> lstInsertOppProduct = new List<OpportunityLineItem>();
        Set<String> setOfProdId = new Set<String>();
        List<Product2> lstInsertproduct = new List<Product2>();
        List<PricebookEntry> lstInsertPricebookEntry = new  List<PricebookEntry>(); 
        Map<String, Id> mapOfEventConAndSFOppId = new Map<String, Id>();
        Map<String, Object> eventregPaymentdetails;
        Decimal totalcharge;
        String strtickets;
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
            
            List<Object> lsteventsairRegistrations = (List<Object>) eventconmap.get('functionRegistrations');
            String strevntconId = (String) eventconmap.get('id'); 
            System.debug('@@@ lsteventsairRegistrations = '+lsteventsairRegistrations);
            
            //loop through event'sair registration data
            for(Object objEventReg: lsteventsairRegistrations) {
                //Registartion field mapping start
                Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                
                Map<String, Object> eventregtypemap;
                List<Object> lstfee;
                string funregid = (String) eventReg.get('id');
                // Object eventregtype = eventReg.get('type');                    
                // eventregtypemap = (Map<String, Object>)eventregtype; 
                Object eventfunregtype = eventReg.get('feeType');                    
                eventregtypemap = (Map<String, Object>)eventfunregtype;
               String strRegTypeId = (String) eventregtypemap.get('id');
                //strRegTypeName = (String) eventregtypemap.get('Name');
                
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
            
            List<Object> lsteventsairRegistrations = (List<Object>) eventconmap.get('functionRegistrations');
            String strevntconId = (String) eventconmap.get('id'); 
            System.debug('@@@ lsteventsairRegistrations = '+lsteventsairRegistrations);
            
            //loop through event'sair registration data
            for(Object objEventReg: lsteventsairRegistrations) {
                //Registartion field mapping start
                Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                
                Map<String, Object> eventregtypemap;
                List<Object> lstfee;
                string funregid = (String) eventReg.get('id');
                
                Object eventfunregtype = eventReg.get('feeType');                    
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
                            system.debug(' inside');
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
            
            List<Object> lsteventsairRegistrations = (List<Object>) eventconmap.get('functionRegistrations');
            String strevntconId = (String) eventconmap.get('id'); 
            System.debug('@@@ lsteventsairRegistrations = '+lsteventsairRegistrations);
            if(lsteventsairRegistrations.size()>0){
                //loop through event'sair registration data
                for(Object objEventReg: lsteventsairRegistrations) {
                    //Registartion field mapping start
                    Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                    String discountcodeval;
                    Map<String, Object> eventregtypemap;
                    Map<String, Object> eventregPaydetailcodedetail;
                    string funregid = (String) eventReg.get('id');
                      Object eventfunregtype = eventReg.get('feeType');                    
                eventregtypemap = (Map<String, Object>)eventfunregtype;
                String strRegTypeId = (String) eventregtypemap.get('id');
                    System.debug('@@@ strRegTypeId = '+strRegTypeId);
                    Object eventregPaydetail = eventReg.get('paymentDetails');                    
                    eventregPaymentdetails = new Map<String, Object>();
                    eventregPaymentdetails = (Map<String, Object>)eventregPaydetail;
                    totalcharge = (Decimal)eventregPaymentdetails.get('totalChargeAmount');
                    strtickets = (String) eventReg.get('tickets');
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
                            OpportunityLineItem oli = new OpportunityLineItem();
                            system.debug('mapOfEventConAndSFOppId.get(strevntconId)'+mapOfEventConAndSFOppId.get(strevntconId)+' '+strevntconId);
                            system.debug(' mapOfEventRegTypeIdAndSFPBentryId.get(strRegTypeId)'+ mapOfEventRegTypeIdAndSFPBentryId.get(strRegTypeId));
                            oli.OpportunityId = mapOfEventConAndSFOppId.get(strevntconId);                    
                            oli.PricebookEntryId = mapOfEventRegTypeIdAndSFPBentryId.get(strRegTypeId);
                            oli.Quantity = Integer.valueOf(strtickets);
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
        
        if(!lstInsertOppProduct.isEmpty()) {
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
            
            List<OpportunityLineItem> finallisttoinsertoli= new List<OpportunityLineItem>();
            
            for(OpportunityLineItem newoli: lstInsertOppProduct) {
                if(!mapOfEvnOLIandSfId.containskey(newoli.Function_Registration_Id__c)) {
                    finallisttoinsertoli.add(newoli);
                }
            }
            
            if(finallisttoinsertoli.size() >0) {
                system.debug('Oli'+finallisttoinsertoli.size());
                insert finallisttoinsertoli;
            }
        }
        
    }
    
    // commented by Vandana 5/4/24 as this method is not used anywhere
    /* public static List<Contact> removeContactsDuplicates(List<Contact> contactList) {
Set<String> uniqueEmails = new Set<String>();
List<Contact> filteredContacts = new List<Contact>();

// Iterate through the contact list
for (Contact con : contactList) {
// Check if the email address is unique
if (uniqueEmails.add(con.Email)) {
// If unique, add to the filtered list
filteredContacts.add(con);
}
}
return filteredContacts;
}*/
   
    // method to insert new contacts(no duplicates) in salesforce
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
    
    
    public static Boolean isValidEmail(String email) {
        
        // Regular expression pattern for email validation
        
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        
        
        
        // Compile the pattern
        
        Pattern pattern = Pattern.compile(emailRegex);
        
        boolean returnval;
        
        // Match the email against the pattern
        
        if(email != null && email !=''){
            
            Matcher matcher = pattern.matcher(email);
            
            returnval =  matcher.matches();
            
        }else if(email == null){
            
            returnval = true;
            
        }
        
        return returnval;
        
        // Return true if email matches the pattern, false otherwise
        
        
        
    }
    
    
    // method to insert new Registration__c(no duplicates) in salesforce
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
    public void LinkFunctionToRegistration(List<Registration__c> lstRegistration) {
        
        Set<String> setOfEventFunId = new Set<String>();
        List<Function__c> lstFunction;
        
        for(Registration__c objReg: lstRegistration) {
            if(objReg.EventsAir_Function_Id__c != null) {
                setOfEventFunId.add(objReg.EventsAir_Function_Id__c);
            }
        }
        if(!setOfEventFunId.isEmpty()) {
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
        
        if(lstexistingOpps.size() > 0) {
            for(Opportunity existingOpp: lstexistingOpps) {
                mapOfEvnconIdandSfOppId.put(existingOpp.EventsAir_Contact_Id__c, existingOpp.Id);
            }
        }
        
        List<Opportunity> finallisttoinsertOpp = new List<Opportunity>();
        
        for(Opportunity newopp: lstInsrtOpp) {
            if(!mapOfEvnconIdandSfOppId.containskey(newopp.EventsAir_Contact_Id__c)) {
                finallisttoinsertOpp.add(newopp);
            }
        }
        
        if(finallisttoinsertOpp.size() >0) {
            insert finallisttoinsertOpp;
        }
        for(Opportunity newopp: finallisttoinsertOpp) {
            mapOfEvnconIdandSfOppId.put(newopp.EventsAir_Contact_Id__c, newopp.Id);
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
    
    
    public void setupForFunctionReg(List<Object> lstobject) {
        
        List<Map<String, Object>> listOfFunctioninfomap = new List<Map<String, Object>>();
        
        //loop through event'sair registration data for setup function start
        for(Object objEventReg: lstobject) {            
            Map<String, Object> eventReg = (Map<String, Object>)objEventReg;            
            Map<String, Object> tempfunmap = (Map<String, Object>)(eventReg.get('function'));            
            listOfFunctioninfomap.add(tempfunmap);            
        }   
        createFunction(listOfFunctioninfomap);
        
    }
    
    
    public void createFunction(List<Map<String, Object>> listOfFunctioninfomap) {
        
        lstInsrtFun = new List<Function__c>();
        ListToFinalInsert = new List<Function__c>();
        Set<String> setofeventfuncId = new Set<String>();
        Set<String> setofexistfuncId = new Set<String>();
        Map<String,Id> mapOfExistingFunction = new  Map<String,Id>();
        
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
        
        //get function details from function registration code start
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
            func.EventsAir_ID__c = (string)mapOfFunction.get('id');
            String strFunName = (string)mapOfFunction.get('name');
            if(strFunName.length() <= 80) {
                func.Name = strFunName;    
            }
            else{
                func.Name = strFunName.substring(0,80);    
            }            
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
        //get function details from function registration code end
        /*   if(!lstInsrtFun.isEmpty()) {

for(Function__c fun :lstInsrtFun)
if(!mapOfExistingFunction.containsKey(fun.EventsAir_ID__c)){
ListToFinalInsert.add(fun);
}            
}
if(!ListToFinalInsert.isEmpty()) {
insert ListToFinalInsert;
}*/
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