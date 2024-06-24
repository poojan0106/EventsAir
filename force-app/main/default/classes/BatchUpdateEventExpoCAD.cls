/******************************************************************************************************************************
* @description  : Batch class to update Details Synced to Requested
* @author       : Salesfix Dev - JL
* @date         : 2018-04-18
*******************************************************************************************************************************/
global class BatchUpdateEventExpoCAD implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    /************************************************************************************************************
    * @description  : Start method to query Event record
    * @author       : Salesfix Dev - JL
    * @date         : 2018-04-18
    *************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Active__c, ExpoCAD_ID__c, Details_Synced_with_ExpoCAD__c';
        query += ' FROM Event__c';
        query += ' WHERE Active__c = true';
        query += ' AND ExpoCAD_ID__c != null';
        query += ' AND (Details_Synced_with_ExpoCAD__c = \'Success\'';
        query += ' OR Details_Synced_with_ExpoCAD__c = \'Failure\')';
        return Database.getQueryLocator(query);
    }

    /************************************************************************************************************
    * @description  : execute method to update queried record.
    * @author       : Salesfix Dev - JL
    * @date         : 2018-04-18
    *************************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<Event__c> queriedEvents){
        if(!queriedEvents.isEmpty()){
            List<Event__c> eventListToUpdate = new List<Event__c>();
            for(Event__c queriedEvent: queriedEvents){
                queriedEvent.Details_Synced_with_ExpoCAD__c = 'Requested';
                eventListToUpdate.add(queriedEvent);
            }

            if(!eventListToUpdate.isEmpty()){
                try{

                }catch(Exception e){
                    sendEmailError(e.getMessage());
                }
                update eventListToUpdate;
            }
        }
    }

    /************************************************************************************************************
    * @description  : Finish method
    * @author       : Salesfix Dev - JL
    * @date         : 2018-04-18
    *************************************************************************************************************/
    global void finish(Database.BatchableContext BC){
    }

    public void sendEmailError(String errorMessage){
        List<String> emailAddressToSend = new List<String>();
        Email_Error__c emailError = Email_Error__c.getOrgDefaults();
        if(emailError.Email_Address__c != null){
            emailAddressToSend.add(emailError.Email_Address__c);
        }
        if(!emailAddressToSend.isEmpty()){
            String currentClassName = String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject(currentClassName + ' Error');
            email.setToAddresses(emailAddressToSend );
            email.setPlainTextBody(currentClassName + ' failed to execute: ' + errorMessage);
            Messaging.sendEmail(new Messaging.Email[] { email });
        }
    }
}