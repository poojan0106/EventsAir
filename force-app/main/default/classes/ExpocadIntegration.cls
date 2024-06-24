/* ==============================================
CreatedDate:-19th October 2023
CreatedBy:-
Description:- Expocad Integration with Salesforce
=================================================*/

public class ExpocadIntegration {
    private static String sessionToken;
    
    public ExpocadIntegration(){
        if(Schema.SObjectType.ExpocadeSessionToken__mdt.isAccessible() && Schema.SObjectType.ExpocadeSessionToken__mdt.fields.SessionToken__c.isAccessible()) {
            ExpocadeSessionToken__mdt expoCad = [SELECT Id, SessionToken__c, DeveloperName	, MasterLabel, ApiKey__c, Email__c   FROM ExpocadeSessionToken__mdt LIMIT 1];
            sessionToken=expoCad.SessionToken__c;
        }
    }
    
    public HttpResponse makeGetCallout(String endpoint) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('ApiSessionToken', sessionToken);
        request.setTimeout(120000);
        Http http = new Http();
        HttpResponse response = http.send(request);
        return response;
    }


    public HttpResponse makePutCallout(String endpoint , String requestBody) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('PUT');
        request.setHeader('ApiSessionToken', sessionToken);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody(requestBody);
        request.setTimeout(120000);
        // Create an HTTP client to send the request
        Http http = new Http();
        HttpResponse response = http.send(request);
        return response;
    }

    public HttpResponse makePostCallout(String endpoint , String requestBody) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('ApiSessionToken', sessionToken);
        request.setHeader('Content-Type', 'application/json; charset=utf-8');
        request.setBody(requestBody);
        request.setTimeout(120000);

        // Create an HTTP client to send the request
        Http http = new Http();
        HttpResponse response = http.send(request);
        return response;
    }

    
    
    public static  ExpocadWrapper getPavilionsByEvent(String eventName){
    
        ExpocadIntegration expoIntegration = new ExpocadIntegration();
        // ===== HTTP GET CALLOUT=====
        HttpResponse response= expoIntegration.makeGetCallout('callout:Expocad/EdgeApi/'+eventName+'/all');
        if(response.getStatusCode() == 200){
            String jsonData=response.getBody();
            return new ExpocadWrapper(true, jsonData);

        }else{
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, 'StatusCode: '+response.getStatusCode()+':'+response.getBody());

        }
        
    }
    
    public static ExpocadWrapper getBoothByEvent(String eventName){
        
        ExpocadIntegration expoIntegration = new ExpocadIntegration();        
        HttpResponse response= expoIntegration.makeGetCallout('callout:Expocad/EdgeApi/'+eventName+'/booths/all?deletedFilter=all');
        
        System.debug(response.getBody());
        if (response.getStatusCode() == 200) {
            String jsonData=response.getBody();
            return new ExpocadWrapper(true, jsonData);
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
        
    }

    public static ExpocadWrapper getDeletedBoothByEvent(String eventName){
        
        ExpocadIntegration expoIntegration = new ExpocadIntegration();        
        HttpResponse response= expoIntegration.makeGetCallout('callout:Expocad/EdgeApi/'+eventName+'/booths/all?deletedFilter=2');
        
        System.debug(response.getBody());
        if (response.getStatusCode() == 200) {
            String jsonData=response.getBody();
            return new ExpocadWrapper(true, jsonData);
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
        
    }
    
    public static ExpocadWrapper getBoothByEventAndName(String eventName , String boothNumber){
        ExpocadIntegration expoIntegration = new ExpocadIntegration();        
        HttpResponse response= expoIntegration.makeGetCallout('callout:Expocad/EdgeApi/'+eventName+'/booths?boothNumber='+boothNumber);
        
        if (response.getStatusCode() == 200) {
            String jsonData = response.getBody(); // Your JSON data as a string
            return new ExpocadWrapper(true, jsonData);
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
        
    }
        
    public static ExpocadWrapper getExhibitorById( String eventName ,  String exhbitorId){
        ExpocadIntegration expoIntegration = new ExpocadIntegration();
        
        // Create an HTTP client to send the request
        HttpResponse response= expoIntegration.makeGetCallout('callout:Expocad/EdgeApi/'+eventName+'/exhibitors?id='+exhbitorId);
        if (response.getStatusCode() == 200) {
            System.debug(response.getBody());
            String jsonData = response.getBody(); // Your JSON data as a string
            return new ExpocadWrapper(true, jsonData);
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
        
    }
    
    public static ExpocadWrapper setBoothHold(String eventName, String boothNumber, String exhibitorId){
                
        ExpocadIntegration expoIntegration = new ExpocadIntegration();   
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8') + '&exhibitorId=' + EncodingUtil.urlEncode(exhibitorId, 'UTF-8');
        HttpResponse response= expoIntegration.makePutCallout('callout:Expocad/EdgeApi/'+eventName+'/booths/hold' , requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
               
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
        
    }
    
    public static ExpocadWrapper setBoothToUnhold(String eventName, String boothNumber){
        ExpocadIntegration expoIntegration = new ExpocadIntegration();   
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        HttpResponse response= expoIntegration.makePutCallout('callout:Expocad/EdgeApi/'+eventName+'/booths/unhold' , requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
               
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
    }
    
    public static ExpocadWrapper setBoothToRent(String eventName, String boothNumber, String exhibitorId){
            
        ExpocadIntegration expoIntegration = new ExpocadIntegration();   
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8') + '&exhibitorId=' + EncodingUtil.urlEncode(exhibitorId, 'UTF-8');
        HttpResponse response= expoIntegration.makePutCallout('callout:Expocad/EdgeApi/'+eventName+'/booths/rent' , requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
               
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
    
    }
    
    public static ExpocadWrapper setBoothToUnrent(String eventName , String boothNumber, String exhibitorId){

        ExpocadIntegration expoIntegration = new ExpocadIntegration(); 
          
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        
        HttpResponse response= expoIntegration.makePutCallout('callout:Expocad/EdgeApi/'+eventName+'/booths/unrent' , requestBody);
        
        if (response.getStatusCode() == 200) {
            System.debug(response.getBody());
            return new ExpocadWrapper(true, '');
                
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
            
    }
    
    public static ExpocadWrapper resetBoothDisplayName(String eventName, String boothNumber){
        
        ExpocadIntegration expoIntegration = new ExpocadIntegration();   
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        HttpResponse response= expoIntegration.makePutCallout('callout:Expocad/EdgeApi/'+eventName+'/booths/displayNameOverride/reset' , requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
               
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }    
    }
    
    public static ExpocadWrapper addNewExhibitor(String eventName, String requestBody){
        
        ExpocadIntegration expoIntegration = new ExpocadIntegration();  
        HttpResponse response= expoIntegration.makePostCallout('callout:Expocad/EdgeApi/'+eventName+'/exhibitors/add', requestBody);
      
         if (response.getStatusCode() == 200 || response.getStatusCode()== 201) {
            String jsonData=response.getBody();
            return new ExpocadWrapper(true, jsonData);

        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
    }
    
    
    public static ExpocadWrapper setBoothChildExhibitors(String eventName, String boothNumber, String childExhibitorId){
        ExpocadIntegration expoIntegration = new ExpocadIntegration();   
        String requestBody = 'childExhibitorId=' + EncodingUtil.urlEncode(childExhibitorId, 'UTF-8') + '&boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        HttpResponse response= expoIntegration.makePutCallout('callout:Expocad/EdgeApi/'+eventName+'/booths/childExhibitor/add' , requestBody);
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
               
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode()+response.getBody());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
    }


    public static ExpocadWrapper removeBoothClass(String eventName , String boothNumber, String classId){
        ExpocadIntegration expoIntegration = new ExpocadIntegration();   


        String requestBody = 'classId=' + EncodingUtil.urlEncode(classId, 'UTF-8')+'&boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        HttpResponse response= expoIntegration.makePutCallout('callout:Expocad/EdgeApi/'+eventName+'/booths/classes/remove' , requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }

    }

    public static ExpocadWrapper setBoothClass(String eventName , String boothNumber, String classId){
        ExpocadIntegration expoIntegration = new ExpocadIntegration();   
        String requestBody = 'classId=' + EncodingUtil.urlEncode(classId, 'UTF-8')+'&boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        HttpResponse response= expoIntegration.makePutCallout('callout:Expocad/EdgeApi/'+eventName+'/booths/classes/apply' , requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }

    }
    
}