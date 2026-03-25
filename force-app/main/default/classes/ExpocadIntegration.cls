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
            if(expoCad != null) {
                sessionToken=expoCad.SessionToken__c;
            }
        }
    }

    public static ExpocadEndpoints__c fetchExpocadEndpoints(){
        if(Schema.SObjectType.ExpocadEndpoints__c.isAccessible()) {
            ExpocadEndpoints__c	 expocadEndpoints = ExpocadEndpoints__c.getInstance();
            return expocadEndpoints;
        }
        return null;
    }

    private HttpResponse makeCallout(String endpoint, String method, String requestBody) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setHeader('ApiSessionToken', sessionToken);
        if(method == 'PUT') {
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        } else if(method == 'POST') {
            request.setHeader('Content-Type', 'application/json; charset=utf-8');
        }
        if(method== 'POST' ||  method =='PUT'){
            request.setBody(requestBody);
        }
        request.setTimeout(120000);

        // Create an HTTP client to send the request
        Http http = new Http();
        return http.send(request);
    }
    
    
    public static  ExpocadWrapper getPavilionsByEvent(String eventName){
    
        ExpocadIntegration expoIntegration = new ExpocadIntegration();
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        // ===== HTTP GET CALLOUT=====

        HttpResponse response = expoIntegration.makeCallout('callout:Expocad/EdgeApi/' + eventName + expocadEndPoints.getAllPavilions__c, 'GET', null);

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
		//Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.getBoothByEvent__c,'GET', null);
        
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
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.getBoothByEventAndName__c+boothNumber, 'GET', null);
        
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
        
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        // Create an HTTP client to send the request
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.getExhibitorById__c+exhbitorId, 'GET', null);
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
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8') + '&exhibitorId=' + EncodingUtil.urlEncode(exhibitorId, 'UTF-8');
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.setBoothHold__c, 'PUT', requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
               
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
        
    }
    
    public static ExpocadWrapper setBoothToUnhold(String eventName, String boothNumber){
        ExpocadIntegration expoIntegration = new ExpocadIntegration();
        
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.setBoothToUnhold__c ,'PUT', requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
               
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
    }
    
    public static ExpocadWrapper setBoothToRent(String eventName, String boothNumber, String exhibitorId){
            
        ExpocadIntegration expoIntegration = new ExpocadIntegration(); 
        
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8') + '&exhibitorId=' + EncodingUtil.urlEncode(exhibitorId, 'UTF-8');
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.setBoothToRent__c , 'PUT' ,requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
               
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
    
    }
    
    public static ExpocadWrapper setBoothToUnrent(String eventName , String boothNumber, String exhibitorId){

        ExpocadIntegration expoIntegration = new ExpocadIntegration(); 
        
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.setBoothToUnrent__c , 'PUT', requestBody);
        
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
        
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        String requestBody = 'boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.resetBoothDisplayName__c , 'PUT', requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
               
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }    
    }
    
    public static ExpocadWrapper addNewExhibitor(String eventName, String requestBody){
        
        ExpocadIntegration expoIntegration = new ExpocadIntegration();
        
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.addNewExhibitor__c, 'POST', requestBody);
      
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
        
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        String requestBody = 'childExhibitorId=' + EncodingUtil.urlEncode(childExhibitorId, 'UTF-8') + '&boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.setBoothChildExhibitors__c , 'PUT', requestBody);
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
               
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode()+response.getBody());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }
    }


    public static ExpocadWrapper removeBoothClass(String eventName , String boothNumber, String classId){
        ExpocadIntegration expoIntegration = new ExpocadIntegration();   
		//Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();

        String requestBody = 'classId=' + EncodingUtil.urlEncode(classId, 'UTF-8')+'&boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.removeBoothClass__c, 'PUT', requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }

    }

    public static ExpocadWrapper setBoothClass(String eventName , String boothNumber, String classId){
        ExpocadIntegration expoIntegration = new ExpocadIntegration();  
        
        //Fetch endpoints from custom setting
        ExpocadEndpoints__c	 expocadEndPoints = fetchExpocadEndpoints();
        
        String requestBody = 'classId=' + EncodingUtil.urlEncode(classId, 'UTF-8')+'&boothNumber=' + EncodingUtil.urlEncode(boothNumber, 'UTF-8');
        HttpResponse response= expoIntegration.makeCallout('callout:Expocad/EdgeApi/'+eventName+expocadEndPoints.setBoothClass__c , 'PUT',requestBody);
        
        if (response.getStatusCode() == 200) {
            return new ExpocadWrapper(true, '');
        } else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
            return new ExpocadWrapper(false, response.getStatusCode()+':::'+response.getBody());
        }

    }
    
}