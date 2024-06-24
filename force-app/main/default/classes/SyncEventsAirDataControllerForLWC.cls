/*************************
* Created By : Foram 
* Cereated Date : 21-09-2023
* Description : Sync EventsAir data into salesforce
**************************/

public class SyncEventsAirDataControllerForLWC {
    
    //get data from eventsAir org
    @AuraEnabled(cacheable=false)
    public static Boolean getSyncData(Id eventId) {
        
        system.debug('@@eventId ='+eventId);
        
        boolean flag; //set return value 
        
        //fetch EventAir external Id  
        List<Event__c> lstevent = [SELECT Id, Name, EventsAirID__c, Open_Date__c, Close_Date__c, New_Event_Logo__c, Is_Pricebook_Created__c
                                   FROM Event__c
                                   WHERE Id =: eventId LIMIT 1];         
        List<Event__c> updteventlst = new List<Event__c>(); //update event data list
        List<Pricebook2> lstInsrtPricebook = new List<Pricebook2>();
        
        String strtoken; //store access token
        String evntsAirId = lstevent[0].EventsAirID__c;
        //check list has data or not
        if(lstevent.size() > 0) {
            
            //this loop execute only once 
            for(Event__C objevent: lstevent) {
                
                //check event record contains eventairid
                if(objevent.EventsAirID__c != null) {
                    
                    //access token callout
                    strtoken = EventsAirOAuthTokenRequest.getAccessToken();
                      system.debug('@@strtoken ='+strtoken);
                    if(strtoken != null) {
                        
                        //if get token then do event api callout based on external eventsairId field value                    
                        String graphqlQuery = '{' +
                            '"query": "query GetEventData($eventId: ID!) {' +
                            'event(id: $eventId) {' +
                            'id,' +
                            'name,' +
                            'startDate,'+
                            'endDate,'+  
                            'venue {' +
                            'name,' +
                            'city,' +
                            'state,' +
                            'country,' +
                            '},'+
                            'logo {' +
                            'url,' +                                
                            '}'+                            
                            '}' +
                            '}",' +
                            '"variables": {' +
                            '"eventId": "'+objevent.EventsAirID__c+'"' +
                            '}' +
                            '}';
                        
                        Http http = new Http();
                        HttpRequest request = new HttpRequest();                        
                        request.setEndpoint(System.Label.EventsAir_API_Base_URL);
                        request.setMethod('POST');
                        request.setBody(graphqlQuery);
                        request.setHeader('Content-Type', 'application/json');
                        request.setHeader('Authorization', 'Bearer ' + strtoken);
                        
                        System.debug('@@@@ request = '+graphqlQuery);
                        
                        System.debug('@@@@ request = '+request);
                        
                        try{
                            HttpResponse response = http.send(request);                            
                            System.debug('@@@ response = '+response);
                            
                            if (response.getStatusCode() == 200) {                   
                                
                                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());                                
                                Map<String, Object> eventDatamap = (Map<String, Object>) jsonResponse.get('data');
                                
                                System.debug('@@@ jsonResponse= '+response.getBody());
                                 System.debug('@@@ jsonResponse= '+eventDatamap);
                                if (eventDatamap != null) {
                                    
                                    Map<String, Object> eventmap = (Map<String, Object>) eventDatamap.get('event');                                    
                                    System.debug('@@@ eventmap = '+eventmap);
                                    
                                    if (eventmap != null) {
                                        
                                        //get event id
                                        String eventairId = (String) eventmap.get('id');
                                        
                                        //get event name
                                        String eventName = (String) eventmap.get('name');
                                        
                                        //get event start date
                                        String eventstartDate = (String) eventmap.get('startDate');
                                        
                                        //get event enddate
                                        String eventendDate = (String) eventmap.get('endDate');
                                        
                                        //get event logo code start
                                        Map<String, Object> eventlogomap = (Map<String, Object>) eventmap.get('logo');
                                        String eventlogourl;
                                        
                                        if(eventlogomap != null) {
                                            eventlogourl = (String) eventlogomap.get('url');                                        
                                            System.debug('@@@ eventlogourl = '+eventlogourl);
                                        }                                        
                                        //get event logo code end
                                        
                                        //get event venue code start
                                        Map<String, Object> eventvenuemap = (Map<String, Object>) eventmap.get('venue');
                                        System.debug('@@@ eventvenuemap = '+eventvenuemap);
                                        
                                        String eventvenuename;
                                        String eventvenuecity;
                                        String eventvenuestate;
                                        String eventvenuecountry;
                                        
                                        if(eventvenuemap != null) {
                                            eventvenuename = (String) eventvenuemap.get('name');
                                            eventvenuecity = (String) eventvenuemap.get('city'); 
                                            eventvenuestate = (String) eventvenuemap.get('state');
                                            eventvenuecountry = (String) eventvenuemap.get('country');  
                                        }
                                        //get event venue code end
                                        
                                        
                                        Integer height = 100;  // Set the logo height in pixels
                                        Integer width = 200;   // Set the logo width in pixels
                                        
                                        //update data in salesforce
                                        objevent.New_Event_Logo__c = '<img src="' + eventlogourl + '" alt="Logo" height="' + height + 'px" width="' + width + 'px" />';
                                        
                                        
                                        if(objevent.Is_Pricebook_Created__c == false) {
                                            //Pricebook2 field mapping
                                            Pricebook2 newPricebook = new Pricebook2();
                                            newPricebook.Name = eventName+' Visitor'; 
                                            newPricebook.Events__c = objevent.Id;
                                            newPricebook.Description = 'Description of the pricebook'; 
                                            newPricebook.IsActive = true; // Set the pricebook as active
                                            lstInsrtPricebook.add(newPricebook);
                                            
                                            //make is created pricebook checkbox to true on event
                                            objevent.Is_Pricebook_Created__c = true;
                                        }   
                                        
                                        updteventlst.add(objevent);
                                    }
                                }
                                flag = true; //return true if status code is 200
                            }
                            else {
                                System.debug('Error response: ' + response.getBody());
                                flag = false;
                            }                            
                        }
                        catch (Exception e) {
                            System.debug('Exception: ' + e.getMessage());
                        }
                    }
                }
            }            
        }
        
        System.debug('@@@ updteventlst = '+updteventlst.size());
        if (!updteventlst.isEmpty()) {            
            update updteventlst;  
                  
        }  
        
        if(!lstInsrtPricebook.isEmpty()) {
            insert lstInsrtPricebook;
        }
        return flag;        
    } 
   
}