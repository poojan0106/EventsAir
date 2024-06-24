/*************************
* Created By : Foram 
* Cereated Date : 12-09-2023
* Description : Import Registration from Evntsair and 
Create Contact/Lead, Registartion
**************************/

public class ForamTestbatch implements Database.Batchable<ResponseWrapper>, Database.AllowsCallouts {
    
    //variable declartion
    public String strEventId;
    public String sfeventId;
    public String eventCategory;
    Integer contactsLimit = Integer.valueOf(System.Label.EventsAir_Attendee_Contact_Limit);
    Integer regLimit = Integer.valueOf(System.Label.EventsAir_Registartion_Limit);
    
    List<Contact> lstInsrtCon;
    List<Lead> lstInsrtLead;    
    List<Function__c> lstInsrtFun;        
    Map<String, Id> mapofConEmailAndId = new Map<String, Id>();
    Map<String, Id> mapofLeadEmailAndId = new Map<String, Id>();
    Map<String, Id> mapOfEventregTypeAndSFproId = new Map<String, Id>();
    Set<String> setofProductId = new Set<String>();
    Map<String, Id> mapOfEventRegTypeIdAndSFPBentryId = new Map<String, Id>();
    Map<String, Decimal> mapOfEventRegTypeIdAndSFPBentryPrice = new Map<String, Decimal>();
    
    //fetch current offset value from custom setting
    List<Manage_Eventsair_Reg_Apex_batch__c> lstcustsett = [Select Id, Name, Offset__c, Is_Execute_Next__c 
                                                            from Manage_Eventsair_Reg_Apex_batch__c LIMIT 1];
    
    public ForamTestbatch(String eventId, String strsfeventId) {        
        strEventId = eventId;
        sfeventId = strsfeventId;
    }
    
    public Iterable<ResponseWrapper> start(Database.BatchableContext BC) {  
        
        System.debug('%%% strEventId = '+strEventId);
        System.debug('%%% lstcustsett[0].Offset__c = '+lstcustsett[0].Offset__c);
        //get access token
        String strtoken = EventsAirOAuthTokenRequest.getAccessToken();
        
        //Prepare API Query        
        String graphqlQuery = '{' +
            '"query": "query GetEventData($eventId: ID!, $contactsLimit: PaginationLimit!, $conoffset: NonNegativeInt!, $regLimit: PaginationLimit!,) {' +
            'event(id: $eventId) {' +
            'id,' +
            'name,' +
            'startDate,'+
            'endDate,'+ 
            'contacts(offset: $conoffset, limit: $contactsLimit) { ' +
            'id,' +
            'lastName,' +
            'firstName,' +
            'title,' +
            'lastModifiedAt,'+
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
            'paymentDetails {' +
            'paymentStatus,'+
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
        system.debug('hi in execute');
        
        //***  create pricebook if Is_Pricebook_Created__c is false on event *** 
        List<Event__c> lstevent = [SELECT Id, Name, EventsAirID__c, Open_Date__c, Close_Date__c, New_Event_Logo__c, Is_Pricebook_Created__c,Event_Category__c
                                   FROM Event__c
                                   WHERE EventsAirID__c =: strEventId LIMIT 1];
        List<Event__c> updteventlst = new List<Event__c>(); 
        List<Pricebook2> lstInsrtPricebook = new List<Pricebook2>();
        
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
        lstInsrtLead = new List<Lead>();
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
                    setOfDomainName.add(emailparts[1].trim());
                }
            }
        }
        
        //if set contains any value then do soql on account and fill the mapOfDomainNameAndAccId Map
        if(setOfDomainName != null) {
            for (AggregateResult aggregateResult : [
                SELECT MAX(CreatedDate) latestCreatedDate, Domain_Name__c, MAX(Id) accountId
                FROM Account
                WHERE Domain_Name__c IN: setOfDomainName
                GROUP BY Domain_Name__c
            ]) {
                String domain = (String)aggregateResult.get('Domain_Name__c');
                Id accountId = (Id)aggregateResult.get('accountId');
                
                if (accountId != null) {
                    mapOfDomainNameAndAccId.put(domain, accountId);
                }
            }
        }
        
        //Loop through event's air contacts data to check if need to create contact or lead based on account's domain name
        for(Object objeventcon: lsteventsairContacts) {
            
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
            
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
                objcon.Business_Unit__c = 'Divcom'; 
                objcon.Organization_Name__c = (String) eventconmap.get('organizationName');
                objcon.AccountId = mapOfDomainNameAndAccId.get(strAccdomainname);
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
                if(strLastName == null || strLastName == '')  {
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
               /*
                Object eventconadress = eventconmap.get('primaryAddress');
                Map<String, Object> eventconAdressmap = (Map<String, Object>) eventconadress;
                if(eventconAdressmap != null) {
                    if(eventconAdressmap.get('city') != null){
                        objcon.MailingCity = (String) eventconAdressmap.get('city');  
                    }
                    
                    if(eventconAdressmap.get('country') != null){
                        objcon.MailingCountry = (String) eventconAdressmap.get('country');
                    }
                    
                    if(eventconAdressmap.get('line1') != null && eventconAdressmap.get('line2') != null  && eventconAdressmap.get('line3') != null){
                        objcon.MailingStreet = (String) eventconAdressmap.get('line1')+ ' '+(String) eventconAdressmap.get('line2')+' '+(String) eventconAdressmap.get('line3');
                        
                    }
                    if(eventconAdressmap.get('state') != null){
                        objcon.MailingState = (String) eventconAdressmap.get('state'); 
                    }
                    if(eventconAdressmap.get('postCode') != null){
                        String strPostalcode = (String) eventconAdressmap.get('postCode');                    
                        // Store only the first 20 characters in the mailingpostalcode field
                        objcon.MailingPostalCode = strPostalcode != null ? strPostalcode.left(20) : null;
                        
                    }
                    
                    
                }*/   
                lstInsrtCon.add(objcon);
            }
            else {                
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
                if(strLastName == null || strLastName == '') {
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
                Object eventconphone = eventconmap.get('contactPhoneNumbers');
                Map<String, Object> eventconphonemap = (Map<String, Object>) eventconphone; 
                if(eventconphonemap != null) {
                    newLead.MobilePhone = (String) eventconphonemap.get('mobile'); 
                }  
                
                /*Object eventleadadress = eventconmap.get('primaryAddress');
                Map<String, Object> eventleadAdressmap = (Map<String, Object>) eventleadadress;
                
                if(eventleadAdressmap != null) {
                    if(eventleadAdressmap.get('city') != null){
                        newLead.City = (String) eventleadAdressmap.get('city');  
                    }
                    
                    if(eventleadAdressmap.get('country') != null){
                        newLead.Country = (String) eventleadAdressmap.get('country');
                        
                    }
                    if(eventleadAdressmap.get('line1') != null && eventleadAdressmap.get('line2') != null && eventleadAdressmap.get('line3') != null){
                        newLead.Street = (String) eventleadAdressmap.get('line1')+ ' '+(String) eventleadAdressmap.get('line2')+' '+(String) eventleadAdressmap.get('line3');
                        
                    }
                    if(eventleadAdressmap.get('state') != null){
                        
                        String strState = (String) eventleadAdressmap.get('state');  
                        // Store only the first 80 characters in the state field
                        newLead.State = strState != null ? strState.left(80) : null; 
                    }
                    
                    if(eventleadAdressmap.get('postCode') != null){
                        String strPostalcode = (String) eventleadAdressmap.get('postCode'); 
                        // Store only the first 20 characters in the mailingpostalcode field
                        newLead.PostalCode = strPostalcode != null ? strPostalcode.left(20) : null; 
                        
                    }
                    
                }    */              
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
            mapofConEmailAndId = insertContactsIfNotExist(lstInsrtCon);   
            system.debug('insertContactsIfNotExist');
        }
        
        // Insert Lead
        if (!lstInsrtLead.isEmpty()) {
            mapofLeadEmailAndId = insertLeadsIfNotExist(lstInsrtLead); 
            system.debug('insertContactsIfNotExist');
        }
        
        List<Registration__c> lstInsrtReg = new List<Registration__c>(); 
        List<Opportunity> lstInsrtOpp = new List<Opportunity>();        
        List<Pricebook2> lstPriceook = [Select Id from Pricebook2 where Events__c =: sfeventId];
        Pricebook2 standardPriceBook = [ SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
        
        // Loop through event's air contacts data to create registration
        for(Object objeventcon : lsteventsairContacts) {
            Map<String, Object> eventconmap = (Map<String, Object>) objeventcon;
            List<Object> lsteventsairReg = (List<Object>) eventconmap.get('registrations');
            String strevntconId = (String) eventconmap.get('id');
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
                    } else {
                        objreg.Lead__c = mapofLeadEmailAndId.get(Finalstring);
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
    
    public static Boolean isValidEmail(String email) {

        // Regular expression pattern for email validation

        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';

        

        // Compile the pattern

        Pattern pattern = Pattern.compile(emailRegex);

        boolean returnval =  false;

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
    
    // to insert only new Leads if not exist in salesforce
    public static Map<String, Id> insertLeadsIfNotExist(List<Lead> leadsToInsert) {
        
        
        Set<String> setOfCombinedEventsAirAttendee = new Set<String>();
        
        system.debug('##leadsToInsert size'+leadsToInsert.size());
        system.debug('@@leadsToInsert '+leadsToInsert);
        //loop through lead list to combined the attendee data        
        for(Lead objLead: leadsToInsert) {
            String strcombinedEventsAirAttendee= objLead.FirstName+objLead.LastName+objLead.Email;
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            setOfCombinedEventsAirAttendee.add(strcombinedEventsAirAttendee);
        }
        system.debug('setOfCombinedEventsAirAttendee'+setOfCombinedEventsAirAttendee.size());
        //fetch existing leads based on Combined name and email
        List<Lead> LstOfExtistingLead = [Select Id,FirstName, LastName,Email,CombinedString__c from Lead where CombinedString__c in :setOfCombinedEventsAirAttendee];
         system.debug('@@LstOfExtistingLead'+LstOfExtistingLead);
        system.debug('@@LstOfExtistingLead size '+LstOfExtistingLead.size());
        Map<String, Id> mapOfLeadStringAndId = new Map<String, Id>();
        
        //loop through existing leads and fill the map
        for(Lead objLead :LstOfExtistingLead){
           mapOfLeadStringAndId.put(objLead.CombinedString__c, objLead.Id); 
        }
        system.debug('@@mapOfLeadStringAndId '+mapOfLeadStringAndId);
        List<Lead> ListOfLeadToInsert = new List<Lead>();
         List<Lead> FinalListOfLeadToInsert = new List<Lead>();
        Set<String> setOfCurrentleadCombinedData = new Set<String>();
        
        for(Lead objLead :leadsToInsert){
             String strcombinedEventsAirAttendee= objLead.FirstName+objLead.LastName+objLead.Email; 
            strcombinedEventsAirAttendee = strcombinedEventsAirAttendee.toLowerCase();
            system.debug('setOfCombinedEventsAirAttendee'+setOfCombinedEventsAirAttendee);
            //check if lead exist or not
            if(!mapOfLeadStringAndId.ContainsKey(strcombinedEventsAirAttendee)){
                // this is for check current batch duplicate data
                if(!setOfCurrentleadCombinedData.contains(strcombinedEventsAirAttendee)){
                     ListOfLeadToInsert.add(objLead);
                    setOfCurrentleadCombinedData.add(strcombinedEventsAirAttendee);
                }
                else{
                    system.debug('Lead alreaded added');
                }
               
            }else{
                system.debug('Lead already exist in Salesforce');
            }
        }
         system.debug('@@ListOfLeadToInsert-size'+ListOfLeadToInsert.size());
        for(Lead objLead :ListOfLeadToInsert){
            FinalListOfLeadToInsert.add(objLead);
            /*if(isValidEmail(objLead.Email)) {
                
                system.debug('valid');
                
            }
            else{
                System.debug('not valid');
            }*/
            
        }
        
        
        if(FinalListOfLeadToInsert.size()>0){
             system.debug('@@FinalListOfLeadToInsert-size'+FinalListOfLeadToInsert.size());
            database.insert(FinalListOfLeadToInsert,false);
            system.debug('@@FinalListOfLeadToInsert'+FinalListOfLeadToInsert);
            //insert FinalListOfLeadToInsert;
        }
        
        List<Lead> LstOfInsertedLead = [select id,CombinedString__c from Lead where Id in :FinalListOfLeadToInsert];
        system.debug('@@LstOfInsertedLead'+LstOfInsertedLead);
        system.debug('@@LstOfInsertedLead'+LstOfInsertedLead.size());
        // for adding the new Leads in Map
        for(Lead objLead :LstOfInsertedLead){
            mapOfLeadStringAndId.put(objLead.CombinedString__c, objLead.Id); 
        }
        system.debug('@@mapOfLeadStringAndId'+mapOfLeadStringAndId);
        system.debug('@@mapOfLeadStringAndId - size'+mapOfLeadStringAndId.size());
        return mapOfLeadStringAndId;
       
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
            if(mapOfEvnRegIdandSfRegId.containskey(newreg.EventsAir_Regisration_ID__c)) {
                finallisttoinsertreg.add(newreg);
            }
        }
        system.debug('finallisttoinsertreg'+finallisttoinsertreg.size());
        if(finallisttoinsertreg.size() >0) {
            system.debug('finallisttoinsertreg'+finallisttoinsertreg.size());
            upsert finallisttoinsertreg EventsAir_Regisration_ID__c;
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
                
                ForamTestbatch newBatch = new ForamTestbatch(strEventId, sfeventId);
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