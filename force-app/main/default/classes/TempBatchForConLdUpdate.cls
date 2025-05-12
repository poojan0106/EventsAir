public class TempBatchForConLdUpdate implements Database.Batchable<ResponseWrapper>, Database.AllowsCallouts{
    
    //variable declartion
    public String strEventId;
    public String sfeventId;
    public String eventCategory;
    Integer contactsLimit = Integer.valueOf(System.Label.EventsAirFun_Attendee_Contact_Limit);
    Integer regLimit = Integer.valueOf(System.Label.EventsAir_Function_Registartion_Limit);
    Set<Lead> lstInsrtLead;
    public List<Event__c> eventData = new List<Event__c>();
    String RecordType;
    
    //fetch current offset value from custom setting
    List<Manage_Eventsair_Con_Lead_Updt_batch__c> lstcustsett = [Select Id, Name, Offset__c, Is_Execute_Next__c 
                                                                 from Manage_Eventsair_Con_Lead_Updt_batch__c LIMIT 1];
    
    public TempBatchForConLdUpdate(String eventId) {
        
        this.eventData = [SELECT Id, Name, EventsAirID__c, Open_Date__c, Close_Date__c, Event_Logo__c,New_Event_Logo__c, 
                          Is_Pricebook_Created__c, Next_Date_For_Function_Registration__c, Event_Category__c, 
                          RecordType.Name,Registration_Types__c FROM Event__c WHERE Id = :eventId LIMIT 1/* 'a0sAD000001BO9hYAG' */];
        
        for(Event__c evnt: eventData) {
            sfeventId = evnt.Id;
            strEventId = evnt.EventsAirID__c;
            eventCategory = evnt.Event_Category__c;
        }          
    }
    
    public Iterable<ResponseWrapper> start(Database.BatchableContext BC) {  
        
        if(eventData.size() > 0) {
            RecordType = eventData[0].RecordType.Name;
        }
        
        //get access token
        String graphqlQuery;
        String strtoken;
        
        if (RecordType != null) {
            strtoken = EventsAirOAuthTokenRequest.getAccessToken(RecordType);
        }
        //Prepare API Query   
        // Prepare the GraphQL query based on the record type 
        String commonQueryTemplate = '{' +
            '"query": "query GetEventData($eventId: ID!, $contactsLimit: PaginationLimit!, $conoffset: NonNegativeInt!, ${customFieldParam}) {' +
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
        
        // Determine custom parts based on RecordType
        String customFieldsSection = '';
        String customFieldParam = '';
        String customVariables = '';
        
        if (RecordType != 'Mumbrella') {
            customFieldParam = ', $input: CustomFieldSearchFilterInput!';
            customFieldsSection = 'customFields(input: $input , limit:5){name, definitionId, value},';
            customVariables = ', "input": { "names": ["Industry INT" , "Industry SEC" , "Job Function SEC" , "Company Size" , "Job Function INT"] }';
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
        
        // Set the Authorization header
        request.setHeader('Authorization', 'Bearer ' + strtoken);
        
        HttpResponse response = http.send(request);
        System.debug('@@@@ response = ' + response.getBody());
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
            
            if (responseWrapper.size() > 0) {
                serializedResponseWrapper = JSON.serialize(responseWrapper[0]);
                // Deserialize the JSON string into a map
                jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(serializedResponseWrapper);
            }
            
            if (jsonResponse != null) {
                // Extract the 'data' map from the JSON response
                if (jsonResponse.containsKey('data') && jsonResponse.get('data') != null) {
                    eventDatamap = (Map<String, Object>) jsonResponse.get('data');
                } 
            }
            
            Map<String, Object> eventmap;
            // Extract the 'event' map from the 'data' map, if present
            if(eventDatamap != null) {
                eventmap = (Map<String, Object>) eventDatamap.get('event');   
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
        }catch(Exception e){
            System.debug('ERROR==>'+ e.getMessage());
            FeedItem post = new FeedItem();
            post.ParentId = sfeventId; //eg. Opportunity id, custom object id..
            post.Body = 'Unable to import Function Registartions For Security And Integrate Batch. \nError : '+ e.getMessage();
            insert post;     
        }   
    }
    
    public void createRecords(List<Object> lsteventsairContacts) {
        // Lists to store records for insertion
        lstInsrtLead = new Set<Lead>();
        Set<String> setOfCombinedEventsAirAttendeeFromReg = new Set<String>(); 
        
        List<Registration__c> lstOfRegistration = [select id,Name,Lead__c,Lead__r.FirstName,Lead__r.LastName,Lead__r.CombinedString__c
                                                   from Registration__c where Event__c = :sfeventId];
        
        if(lstOfRegistration.size()>0){
            for(Registration__c reg : lstOfRegistration){
                if(reg.Lead__c != null && reg.Lead__r.CombinedString__c != null && reg.Lead__r.CombinedString__c != ''){
                    setOfCombinedEventsAirAttendeeFromReg.add(reg.Lead__r.CombinedString__c);  
                }
            }  
        }
        if(setOfCombinedEventsAirAttendeeFromReg.size()>0){
               
        // fetch Lead from sf based on combined String
        List<Lead> listOfAllLead = [SELECT Id,FirstName, LastName,Email,CombinedString__c FROM Lead
                                    WHERE CombinedString__c in :setOfCombinedEventsAirAttendeeFromReg LIMIT 50000];
        
        Map<String, Id> mapOfUniqueLeadStringandId = new Map<String, Id>();
        Map<String, Boolean> mapOfUniqueLeadString = new Map<String, Boolean>();
        
        //loop through existing Leads and fill the map to use for mapping with function registration
        for(Lead objLead :listOfAllLead){
            mapOfUniqueLeadStringandId.put(objLead.CombinedString__c, objLead.Id); 
        }
        // loop through event's air contact for create Lead/Contact based on Paid/Unpaid function registrations
        for (Object objEventCon : lsteventsairContacts) {
            Map<String, Object> eventConMap = (Map<String, Object>) objEventCon;
            
            String CombinedString = getCombinedString(objEventCon);
            if(mapOfUniqueLeadStringandId.containsKey(CombinedString)  && !mapOfUniqueLeadString.containsKey(CombinedString)){
                //lead field mapping
                
                Lead newLead = new Lead();
                newLead.Id = mapOfUniqueLeadStringandId.get(CombinedString);
                String strPosition = (String) eventConMap.get('jobTitle');
                
                if(strPosition != null && strPosition != '' ) {
                    newLead.Title = strPosition.trim();
                }else{
                    newLead.Title = ''; 
                } 
                
                String strOrganization = (String) eventConMap.get('organizationName');
                if(strOrganization != null && strOrganization != '') {
                    newLead.Company = strOrganization;
                }
                else{
                    newLead.Company = 'Unknown';
                }
                if (RecordType != 'Mumbrella') {
                    List<Object> lsteventsairCustomFields = (List<Object>) eventConMap.get('customFields');
                    
                    for (Object fields : lsteventsairCustomFields) {
                        Map<String, Object> customFieldsMap = (Map<String, Object>) fields;
                        String FieldName = (String) customFieldsMap.get('name');
                        if (FieldName != '' && FieldName != null) {
                            if (FieldName =='Industry SEC' && eventCategory == 'Security') {
                                newLead.Industry__c =(String) customFieldsMap.get('value');
                            }
                            if (FieldName =='Industry INT' && eventCategory == 'Integrate') {
                                newLead.Industry__c =(String) customFieldsMap.get('value');
                            }
                            if(FieldName == 'Job Function SEC' && eventCategory == 'Security'){
                                newLead.Job_Function__c = (String) customFieldsMap.get('value');
                            }
                            if(FieldName == 'Job Function INT' && eventCategory == 'Integrate'){
                                newLead.Job_Function__c = (String) customFieldsMap.get('value');
                            }
                        }
                    }  
                }
                lstInsrtLead.add(newLead);
                mapOfUniqueLeadString.put(CombinedString,true);
            }
        }
        }
        // update Lead
        if (!lstInsrtLead.isEmpty()) {
            update new List<Lead> (lstInsrtLead);
        }
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
    
    public void finish(Database.BatchableContext BC) {
        
        if(!test.isrunningtest()) {
            List<Manage_Eventsair_Con_Lead_Updt_batch__c> lstcustsett2 = [SELECT Id, Name, Offset__c, Is_Execute_Next__c 
                                                                          FROM Manage_Eventsair_Con_Lead_Updt_batch__c LIMIT 1];            
            // Your finish logic goes here
            if(lstcustsett2[0].Is_Execute_Next__c == true) {
                
                //update offset in custom setting
                lstcustsett2[0].Offset__c = lstcustsett[0].Offset__c + contactsLimit;
                update lstcustsett2;
                
                TempBatchForConLdUpdate newBatch = new TempBatchForConLdUpdate(sfeventId);
                Database.executeBatch(newBatch, 500);
            }
            else {
                lstcustsett2[0].Is_Execute_Next__c = true;
                update lstcustsett2;
                
                List<Event__c> updteventlstNextdt = new List<Event__c>();
                System.debug('### sfeventId  = '+sfeventId);
                Event__c evnt = new Event__c();
                if(sfeventId != null){
                    evnt.Id = sfeventId;
                    evnt.Next_Date_For_Function_Registration__c = System.today();
                    updteventlstNextdt.add(evnt);
                    update updteventlstNextdt;
                    
                    System.debug('### sfeventId  = '+sfeventId);
                    FeedItem post = new FeedItem();
                    post.ParentId = sfeventId; //eg. Opportunity id, custom object id..
                    post.Body = 'Apex batch End for fetching function Registration EventsAir Data';
                    insert post;   
                }             
            }
        }
    }
}