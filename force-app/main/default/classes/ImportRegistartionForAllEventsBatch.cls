/*************************
* Created By : Foram 
* Cereated Date : 12-09-2023
* Description : Import Registration from Evntsair and 
Create Contact/Lead, Registartion, Opportunity and Opportunity Products 
**************************/

public class ImportRegistartionForAllEventsBatch implements Database.Batchable<ResponseWrapper>, Database.AllowsCallouts {
    
    public String strEventId;
    public String sfeventId;
    Integer contactsLimit = 80;
    Integer regLimit = 10;
    
    List<Contact> lstInsrtCon;
    List<Lead> lstInsrtLead;    
    List<Function__c> lstInsrtFun;    
    List<Object> lsteventsairfuncRegistrations = new List<Object>();
    
    Map<String, Id> mapofConEmailAndId = new Map<String, Id>();
    Map<String, Id> mapofLeadEmailAndId = new Map<String, Id>();
    
    //fetch current offset value from custom setting
    List<Manage_Eventsair_Apex_batch_All_Events__c> lstcustsett = [Select Id, Name, Offset__c, Is_Execute_Next__c from Manage_Eventsair_Apex_batch_All_Events__c LIMIT 1];
    
    public ImportRegistartionForAllEventsBatch(String eventId, String strsfeventId){
        strEventId = eventId;
        sfeventId = strsfeventId;
    }
    
    public Iterable<ResponseWrapper> start(Database.BatchableContext BC) {  
        
        System.debug('@@@ lstcustsett = '+lstcustsett);
        
        //get access token
        String strtoken = EventsAirOAuthTokenRequest.getAccessToken();
        
        //Prepare API Query        
        String graphqlQuery = '{' +
            '"query": "query GetEventData($eventId: ID!, $contactsLimit: PositiveInt!, $conoffset: NonNegativeInt!, $regLimit: PositiveInt!,) {' +
            'event(id: $eventId) {' +
            'id,' +
            'contacts(offset: $conoffset, limit: $contactsLimit) { ' +
            'id,' +
            'lastName,' +
            'firstName,' +
            'title,' +
            'organizationName,'+
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
            //update offset in custom setting
            lstcustsett[0].Is_Execute_Next__c = false;
            lstcustsett[0].Offset__c = 0;
            update lstcustsett;
             FeedItem post = new FeedItem();
             post.ParentId = strEventId; //eg. Opportunity id, custom object id..
             post.Body = 'Data is not synced for this event.';
             insert post;
        }        
        return lstofresponseWrapper;
    }
    
    public void execute(Database.BatchableContext BC, List<ResponseWrapper> responseWrapper) {
        
        String serializedResponseWrapper = JSON.serialize(responseWrapper[0]);
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(serializedResponseWrapper);
        Map<String, Object> eventDatamap = (Map<String, Object>) jsonResponse.get('data');        
        Map<String, Object> eventmap = (Map<String, Object>) eventDatamap.get('event');        
        System.debug('@@@@ eventmap = '+eventmap);
        
        List<Object> lsteventsairContacts = new List<Object>();
        lsteventsairContacts = (List<Object>) eventmap.get('contacts');
        System.debug('lsteventsairContacts '+lsteventsairContacts);
        createRecords(lsteventsairContacts);
        
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
        lstInsrtLead = new List<Lead>();
        List<Registration__c> lstInsrtReg = new List<Registration__c>(); 
        Set<String> setOfDomainName = new Set<String>();
        Map<String, Id> mapOfDomainNameAndAccId = new Map<String, Id>();
        
        //Loop through event's air contacts data to extract contact's email domain name
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;            
            String strevntconemail = (String) eventconmap.get('primaryEmail');            
            
            if(strevntconemail != null && strevntconemail != '') {
                String[] emailparts = strevntconemail.split('@');
                if (emailparts.size() > 1) {
                    setOfDomainName.add(emailparts[1].trim());
                }
            }
        }
        
        
        
        //if set contains any value then do soql on account and fill the mapOfDomainNameAndAccId Map
        if(setOfDomainName != null) {
            
            //fetch account based on contact's email domain name
            List<Account> lstAccount = [SELECT Id, Name, Domain_Name__c
                                        FROM Account 
                                        WHERE Domain_Name__c IN: setOfDomainName
                                       ];
            
            if(!lstAccount.isEmpty()) {
                for(Account objacc: lstAccount) {
                    mapOfDomainNameAndAccId.put(objacc.Domain_Name__c, objacc.Id);
                }                                                    
            }   
        }
        
        //Loop through event's air contacts data to check if need to create contact or lead based on account's domain name
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
            
            String strevntconId = (String) eventconmap.get('id');
            String strcontEmail = (String) eventconmap.get('primaryEmail');
            String strAccdomainname;
            
            //extract domain name from contact's email
            if(strcontEmail != null && strcontEmail != '') {
                String[] emailparts = strcontEmail.split('@');
                if (emailparts.size() > 1) {
                    strAccdomainname = emailparts[1].trim();
                }
            }
            
            //check if create contact or Lead
            //create contact if fund the account based on domain name and create lead if not found                        
            if(mapOfDomainNameAndAccId.containsKey(strAccdomainname)) {
                
                // Contact field mapping start
                Contact objcon = new Contact();
                objcon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Visitor').getRecordTypeId();
                
                String strFirstName = (String) eventconmap.get('firstName');
                if (strFirstName != null )  {
                    if(strFirstName.length() <= 40) {
                        objCon.FirstName = strFirstName;
                    } else {
                        objCon.FirstName = strFirstName.substring(0,40);
                    }
                }
                String strLastName = (String) eventconmap.get('lastName');
                if(strLastName == null || strLastName == '') {
                    objcon.LastName = 'Unknown';
                }
                else{
                    objcon.LastName = strLastName;
                }                
                objcon.Organization_Name__c = (String) eventconmap.get('organizationName');
                String stremail = (String) eventconmap.get('primaryEmail');
                if(stremail != null && stremail != '') {
                    stremail = stremail.trim();
                    objcon.Email = stremail;
                }                    
                objcon.Business_Unit__c = 'Divcom'; 
                Object eventconphone = eventconmap.get('contactPhoneNumbers');
                Map<String, Object> eventconphonemap = (Map<String, Object>) eventconphone;
                if(eventconphonemap != null) {
                    objcon.MobilePhone = (String) eventconphonemap.get('mobile');
                } 
				//===============
				Object eventconadress = eventconmap.get('primaryAddress');
                 Map<String, Object> eventconAdressmap = (Map<String, Object>) eventconadress;
                   system.debug('@@eventconAdressmap'+eventconAdressmap);
                   if(eventconAdressmap != null) {
                    objcon.MailingCity = (String) eventconAdressmap.get('city');
                    objcon.MailingCountry = (String) eventconAdressmap.get('country');
                    objcon.MailingStreet = (String) eventconAdressmap.get('line1')+ ' '+(String) eventconAdressmap.get('line2')+' '+(String) eventconAdressmap.get('line3');
                     objcon.MailingPostalCode = (String) eventconAdressmap.get('postCode');
                    objcon.MailingState = (String) eventconAdressmap.get('state');
                     
                } 
				
				//===============                
                objcon.AccountId = mapOfDomainNameAndAccId.get(strAccdomainname);    
                lstInsrtCon.add(objcon);
                // Contact field mapping end
            }
            else {                
                //create lead field mapping start
                Lead newLead = new Lead();
                newLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Visitor').getRecordTypeId();
                String strFirstName = (String) eventconmap.get('firstName');
                if (strFirstName != null )  {
                    if(strFirstName.length() <= 40) {
                        newLead.FirstName= strFirstName;
                    } else {
                        newLead.FirstName = strFirstName.substring(0,40);
                    }
                }
                
                String strLastName = (String) eventconmap.get('lastName');
                if(strLastName == null || strLastName == '') {
                    newLead.LastName = 'Unknown';
                }
                else{
                    newLead.LastName = strLastName;
                }
                String stremail = (String) eventconmap.get('primaryEmail');
                if(stremail != null && stremail != '') {
                    stremail = stremail.trim();
                    newLead.Email = stremail;
                } 
                newLead.Event_Category__c = 'AOG Energy';
                newLead.Business_Unit__c = 'Divcom';
                Object eventconphone = eventconmap.get('contactPhoneNumbers');
                Map<String, Object> eventconphonemap = (Map<String, Object>) eventconphone; 
                if(eventconphonemap != null) {
                    newLead.MobilePhone = (String) eventconphonemap.get('mobile'); 
                }  
                
                //===============
				Object eventleadadress = eventconmap.get('primaryAddress');
                 Map<String, Object> eventleadAdressmap = (Map<String, Object>) eventleadadress;
                   system.debug('@@eventleadAdressmap'+eventleadAdressmap);
                   if(eventleadAdressmap != null) {
                    newLead.City = (String) eventleadAdressmap.get('city');
                    newLead.Country = (String) eventleadAdressmap.get('country');
                    newLead.Street = (String) eventleadAdressmap.get('line1')+ ' '+(String) eventleadAdressmap.get('line2')+' '+(String) eventleadAdressmap.get('line3');
                    //newLead.MailingStreet = (String) eventleadAdressmap.get('line2');
                   // newLead.MailingStreet = (String) eventleadAdressmap.get('line3');
                    newLead.PostalCode = (String) eventleadAdressmap.get('postCode');
                    newLead.State = (String) eventleadAdressmap.get('state');
                     
                } 
				
				//===============  
                String strOrganization = (String) eventconmap.get('organizationName');
                if(strOrganization != null && strOrganization != '') {
                    newLead.Company = strOrganization;
                }
                else{
                    newLead.Company = 'Unknown';
                }
                newLead.Status = 'New';
                lstInsrtLead.add(newLead);
            }
        }
        
        // Insert Contacts
        if (!lstInsrtCon.isEmpty()) {
            
            Set<String> setOfConEmail = new Set<String>();
            //check if contact
            for(Contact con: lstInsrtCon){
                if(con.Email != null) {
                    setOfConEmail.add(con.Email);
                }
            }
            
            if(!setOfConEmail.isEmpty()) {
                List<Contact> lstExistingCon = [SELECT Id, Email from Contact WHERE Email IN: setOfConEmail];
                for(Contact objCon: lstExistingCon) {
                    mapofConEmailAndId.put(objCon.Email, objCon.Id);
                }
            }
            
            List<Contact> finallstToInsrtCon = new List<Contact>();
            for(Contact con: lstInsrtCon){
                if(!mapofConEmailAndId.containsKey(con.Email)) {
                    finallstToInsrtCon.add(con);                    
                }
            }
            
            Database.upsert(finallstToInsrtCon, Contact.Email, false);
            
            for(Contact con: finallstToInsrtCon) {
                mapofConEmailAndId.put(con.Email, con.Id);
            }
            
        }
        
        // Insert Lead
        if (!lstInsrtLead.isEmpty()) {
            
            Set<String> setOfLeadEmail = new Set<String>();
            //check if lead exist or not
            for(Lead objLead: lstInsrtLead){
                if(objLead.Email != null) {
                    setOfLeadEmail.add(objLead.Email);
                }
            }
            
            if(!setOfLeadEmail.isEmpty()) {
                List<Lead> lstExistingLead = [SELECT Id, Email from Lead WHERE Email IN: setOfLeadEmail];
                for(Lead objLead: lstExistingLead) {
                    mapofLeadEmailAndId.put(objLead.Email, objLead.Id);
                }
            }
            
            List<Lead> finallstToInsrtLead = new List<Lead>();
            for(Lead lead: lstInsrtLead){
                if(!mapofLeadEmailAndId.containsKey(lead.Email)) {
                    finallstToInsrtLead.add(lead);                    
                }
            }
            
            //Database.insert(finallstToInsrtLead);
            
            Database.upsert(finallstToInsrtLead, Lead.Email, false);
            
            for(Lead objlead: finallstToInsrtLead) {
                mapofLeadEmailAndId.put(objlead.Email, objlead.Id);
            }
            
        }
        
        //Loop through event's air contacts data to create registartion and prepare list of function registration list for all contact
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;  
            Map<String, Object> eventregtypemap = new Map<String, Object>();            
            List<Object> lsteventsairRegistrations = (List<Object>) eventconmap.get('registrations');
            /*List<Object> lsteventsairfunReg = ((List<Object>) eventconmap.get('functionRegistrations'));
            System.debug('@@@ lsteventsairfunReg = '+lsteventsairfunReg);
            
            if(!lsteventsairfunReg.isEmpty()) {
                lsteventsairfuncRegistrations.add(lsteventsairfunReg);
            } */
            
            //loop through event'sair registration data
            for(Object objEventReg: lsteventsairRegistrations) {
                
                //Registartion field mapping start
                Map<String, Object> eventReg = (Map<String, Object>)objEventReg;
                
                Object eventregtype = eventReg.get('type');                    
                eventregtypemap = (Map<String, Object>)eventregtype; 
                
                String strRegDate = (String) eventReg.get('registrationDateTime'); 
                
                //Registartion field mapping start
                Registration__c objreg = new Registration__c();                
                objreg.RecordTypeId = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Registration').getRecordTypeId(); 
                if(strRegDate != null) {
                    objreg.Date_Registered__c = Datetime.valueOf(strRegDate.replace('T',' ')); 
                }                  
                objreg.EventsAir_Regisration_ID__c = (String) eventReg.get('id');
                objreg.EventsAir_Contact_Id__c = (String) eventconmap.get('id');
                String streventconEmail = (String) eventconmap.get('primaryEmail');
                
                if(streventconEmail != null) {
                    if(mapofConEmailAndId.containsKey(streventconEmail)) {
                        objreg.Contact__c = mapofConEmailAndId.get(streventconEmail);
                    }
                    else{
                        objreg.Lead__c = mapofLeadEmailAndId.get(streventconEmail);
                    }
                }
                
                /*if(mapOfEventConAndSFOppId.containsKey(objreg.EventsAir_Contact_Id__c)) {
objreg.Opportunity__c = mapOfEventConAndSFOppId.get(objreg.EventsAir_Contact_Id__c);
}*/
                
                objreg.Event__c = sfeventId; 
                
                if(eventregtypemap.get('name') != null){
                    if(!Test.isRunningTest()){
                        objreg.Registration_Type__c = (String) eventregtypemap.get('name'); 
                    }
                }
                
                /*  if(eventregPaymentdetails.get('paymentStatus') != null){
objreg.Payment_Status__c = (String) eventregPaymentdetails.get('paymentStatus'); 

}*/
                
                lstInsrtReg.add(objreg);    
                //Registartion field mapping end   
            }            
        }
        
        insertRegistration(lstInsrtReg, false);
        
        System.debug('@@@ lsteventsairFuncRegistrations = '+lsteventsairFuncRegistrations.size());
        System.debug('@@@ lsteventsairFuncRegistrations = '+lsteventsairFuncRegistrations);
        if(!lsteventsairfuncRegistrations.isEmpty()) {
            
            //setupForFunctionReg(lsteventsairfuncRegistrations);  
        }
    }
    
    public void insertRegistration(List<Registration__c> lstInsrtReg, Boolean isFunReg) {
        
        //create registration
        if(!lstInsrtReg.isEmpty()) {
            
            Set<String> setOfevntRegIds = new Set<String>();
            
            //check for existing registration
            for(Registration__c reg: lstInsrtReg) {
                setOfevntRegIds.add(reg.EventsAir_Regisration_ID__c);
            }
            
            Map<String, Boolean> mapofEvntRegIdAndfalg = new Map<String, Boolean>();
            
            if(setOfevntRegIds != null) {
                List<Registration__c> lstReg = [Select Id, EventsAir_Regisration_ID__c from Registration__c 
                                                where EventsAir_Regisration_ID__c IN: setOfevntRegIds];
                if(!lstReg.isEmpty()) {
                    for(Registration__c objReg: lstReg) {
                        mapofEvntRegIdAndfalg.put(objReg.EventsAir_Regisration_ID__c ,true);
                    }
                }
            }
            
            List<Registration__c> lstfinalinsrtReg = new List<Registration__c>();
            
            for(Registration__c objreg: lstInsrtReg) {
                if(!mapofEvntRegIdAndfalg.containskey(objreg.EventsAir_Regisration_ID__c)) {
                    lstfinalinsrtReg.add(objreg);                   
                }
            }
            
            if(!lstfinalinsrtReg.isEmpty()) {
                upsert lstfinalinsrtReg;  
            }
            
        }
        
        if(isFunReg) {
            //LinkObjectsHandler.LinkFunctionToRegistration(lstInsrtReg);
        }
    }
    
    
    public void finish(Database.BatchableContext BC) {
        
        if(!test.isrunningtest()) {
            List<Manage_Eventsair_Apex_batch_All_Events__c> lstcustsett2 = [SELECT Id, Name, Offset__c, Is_Execute_Next__c 
                                                                 FROM Manage_Eventsair_Apex_batch_All_Events__c LIMIT 1];
            
            // Your finish logic goes here
            if(lstcustsett2[0].Is_Execute_Next__c == true) {
                
                //update offset in custom setting
                lstcustsett2[0].Offset__c = lstcustsett[0].Offset__c + contactsLimit;
                update lstcustsett2;
                
                ImportRegistartionForAllEventsBatch newBatch = new ImportRegistartionForAllEventsBatch(strEventId, sfeventId);
                Database.executeBatch(newBatch, 500);
            }
            else {
                lstcustsett2[0].Is_Execute_Next__c = true;
                update lstcustsett2;
                
                  // Enqueue the Queueable job
                ImportRegistartionFromEventsAirQueueable job = new ImportRegistartionFromEventsAirQueueable();
                System.enqueueJob(job);
                
                FeedItem post = new FeedItem();
                post.ParentId = sfeventId; //eg. Opportunity id, custom object id..
                post.Body = 'Apex batch End for fetching EventsAir Data';
                insert post;
                
            }
        }
        
    }
}