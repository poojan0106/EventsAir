/*************************
* Created By : Foram 
* Cereated Date : 06-05-24
* Description : Import Registration from Evntsair contactstore data and Create Contact/Lead
**************************/

public class ImportContactStoreBatch implements Database.Batchable<ResponseWrapper>, Database.AllowsCallouts {
    
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
    
    public ImportContactStoreBatch(String eventId, String strsfeventId) {        
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
            '"query": "query GetEventData($eventId: ID!, $contactsLimit: PaginationLimit!, $conoffset: NonNegativeInt!) {' +
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
            '}' +
            '}' +
            '}",' +
            '"variables": {' +
            '"eventId": "' + strEventId + '",' +
            '"contactsLimit": ' + contactsLimit + ',' +
            '"conoffset": ' + lstcustsett[0].Offset__c +        
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
                
        List<Object> lsteventsairContacts = new List<Object>();
        lsteventsairContacts = (List<Object>) eventmap.get('contacts'); //extract list of contas from event query
        System.debug('### lsteventsairContacts = '+lsteventsairContacts);
                
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }
}