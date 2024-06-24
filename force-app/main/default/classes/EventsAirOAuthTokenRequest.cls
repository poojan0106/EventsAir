/*************************
* Created By : Foram 
* Cereated Date : 15-09-2023
* Description : Get Access Token (Valid for 60min)
**************************/

public class EventsAirOAuthTokenRequest {
    
    public static String getAccessToken() {
        
        //fetch access token request information from custom seeting
        //Token_Request_Information__c objcust = Token_Request_Information__c.getValues('AccessToken Information');
        
        AccessToken_Information_For_Mumbrella__c objcust = AccessToken_Information_For_Mumbrella__c.getValues('AccessToken Information');
        if(objcust != null) {
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(objcust.EndPoint__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            String payload = 'grant_type=' + EncodingUtil.urlEncode(objcust.Grant_Type__c, 'UTF-8') +
                '&scope=' + EncodingUtil.urlEncode(objcust.Scope__c, 'UTF-8') +
                '&client_id=' + objcust.Client_Id__c +
                '&client_secret=' + objcust.Client_Secret__c;
            
            request.setBody(payload);
            System.debug('@@@@ request = '+request);
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                 System.debug('response.getBody() = '+response.getBody());
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String accessToken = (String) result.get('access_token');
                
                System.debug('@@@@ received accessToken = '+accessToken);
                
                return accessToken;
            } else {
                // Handle error response here
                System.debug('Error response: ' + response.getBody());
                return null;
            }
        }
        return null;
    }
}