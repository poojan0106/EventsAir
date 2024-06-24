@isTest
public class SyncEventsAirDataControllerForLWCTest {
    
    static testMethod void testmethod1() {
        
          MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        	multimock.setStaticResource('https://api.eventsair.com/graphql','StaticResponseforLwc');
        multimock.setStaticResource('https://api.microsoftonline.com/dff76352-1ded-46e8-96a4-1a83718b2d3a/oauth2/v2.0/token','staticresponseForAcessToken');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);
        
        Token_Request_Information__c customSettingRecord = new Token_Request_Information__c();
        customSettingRecord.Name = 'AccessToken Information';
        customSettingRecord.Client_Id__c = 'AccessToken Information';
        customSettingRecord.Client_Secret__c = 'your-access-token-value'; 
        customSettingRecord.EndPoint__c = 'https://api.microsoftonline.com/dff76352-1ded-46e8-96a4-1a83718b2d3a/oauth2/v2.0/token'; 
        customSettingRecord.Grant_Type__c = 'your-access-token-value'; 
        customSettingRecord.Scope__c = 'your-access-token-value'; 
        
        // Insert the Custom Setting record
        insert customSettingRecord;
        
        Event__c evnt = new Event__c();
        evnt.Name = 'text';
        evnt.EventsAirID__c = '1234';
        evnt.Event_Portfolio__c = 'Food';      
        insert evnt;
        
        
        Test.startTest();
        SyncEventsAirDataControllerForLWC.getSyncData(evnt.Id);
        Test.stopTest();
        
    }
    
    public static StaticResourceCalloutMock setStaticMock (String mockName) {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }
    
    
    
}