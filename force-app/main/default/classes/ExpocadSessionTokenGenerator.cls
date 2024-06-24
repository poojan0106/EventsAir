public class ExpocadSessionTokenGenerator  implements Metadata.DeployCallback{

    public void handleResult(Metadata.DeployResult result,Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            System.debug(' ===>'+ result);
        } else {
            // Deployment was not successful
            System.debug(' ===> fail '+ result);
        }
    }   
    

    @future(callout=true)
    public static void refreshSessionToken(){  

        ExpocadeSessionToken__mdt expoCad = [SELECT Id, SessionToken__c, DeveloperName	, MasterLabel, ApiKey__c, Email__c   FROM ExpocadeSessionToken__mdt LIMIT 1];
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Expocad/ClientUser/apiLogin');
        request.setMethod('POST');
        String apiKey=expoCad.ApiKey__c;
        String email=expoCad.Email__c;
        String requestBody = 'email=' + EncodingUtil.urlEncode(email, 'UTF-8') + '&apiKey=' + EncodingUtil.urlEncode(apiKey, 'UTF-8');
        request.setBody(requestBody);
        
       // Set the Content-Type header
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setTimeout(120000);
        //Create an HTTP client to send the request
        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = 'ExpocadeSessionToken__mdt.'+expoCad.DeveloperName;
            customMetadata.label = expoCad.MasterLabel; // Modify field values as needed

            Metadata.CustomMetadataValue customMetadataValue = new Metadata.CustomMetadataValue();
            customMetadataValue.field='SessionToken__c';
            customMetadataValue.value=response.getBody();

            customMetadata.values.add(customMetadataValue);
            Metadata.DeployContainer container=new Metadata.DeployContainer();
            container.addMetadata(customMetadata);
            if(!Test.isRunningTest()){
                Metadata.Operations.enqueueDeployment(container , null);
            }



        }else {
            System.debug('HTTP Request failed with status code ' + response.getStatusCode());
        }
    }



   

    
}