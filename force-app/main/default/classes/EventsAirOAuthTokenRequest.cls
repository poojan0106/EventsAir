/*************************
* Created By : Foram 
* Cereated Date : 15-09-2023
* Description : Get Access Token (Valid for 60min)
**************************/

public class EventsAirOAuthTokenRequest {
    
    public static String getAccessToken(String RecordType) {
        String accessToken = null;
        if (RecordType == 'Mumbrella') {
            accessToken = fetchAccessTokenMumbrella();
        } else {
            accessToken = fetchAccessTokenDefault();
        }
        return accessToken;
    }

    public static String fetchAccessTokenMumbrella() {
        AccessToken_Information_For_Mumbrella__c objcust = AccessToken_Information_For_Mumbrella__c.getValues('AccessToken Information');
        
        if (objcust == null) {
            System.debug('Mumbrella custom setting not found.');
            return null;
        }
        
        return sendAccessTokenRequest(objcust.EndPoint__c, objcust.Grant_Type__c, objcust.Scope__c, objcust.Client_Id__c, objcust.Client_Secret__c);
    }

    public static String fetchAccessTokenDefault() {
        Token_Request_Information__c objcust = Token_Request_Information__c.getValues('AccessToken Information');
        
        if (objcust == null) {
            System.debug('Default custom setting not found.');
            return null;
        }
        
        return sendAccessTokenRequest(objcust.EndPoint__c, objcust.Grant_Type__c, objcust.Scope__c, objcust.Client_Id__c, objcust.Client_Secret__c);
    }
    public static String sendAccessTokenRequest(String endpoint, String grantType, String scope, String clientId, String clientSecret) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        String payload = 'grant_type=' + EncodingUtil.urlEncode(grantType, 'UTF-8') +
            '&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8') +
            '&client_id=' + clientId +
            '&client_secret=' + clientSecret;
        
        request.setBody(payload);
        System.debug('@@@@ request = ' + request);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            System.debug('response.getBody() = ' + response.getBody());
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String accessToken = (String) result.get('access_token');
            
            System.debug('@@@@ received accessToken = ' + accessToken);
            return accessToken;
        } else {
            // Handle error response here
            System.debug('Error response: ' + response.getBody());
            return null;
        }
    }
}