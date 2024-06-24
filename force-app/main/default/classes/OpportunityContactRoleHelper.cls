/************************************************************************************************
 * @description : Extension class for OpportunityContactPage
 * @author      : SalesFix Dev - CL
 * @date        : 2018-08-01
 *************************************************************************************************/
public class OpportunityContactRoleHelper{
    public Opportunity opp;
    public OpportunityContactRoleHelper(ApexPages.StandardController stdController) {
        opp = (Opportunity)stdController.getRecord();        
    }
    public void updateParentAccountValues(){
        updateAccountPrimaryContact(opp.Id);    
    }
    
    public static void updateAccountPrimaryContact(Id oppId){
        try{
            Opportunity ocrOppAccount = [SELECT Id, Primary_Contact_Added__c, AccountId, Account.Primary_Contact__c,
                                            (SELECT Id, isPrimary, ContactId FROM OpportunityContactRoles WHERE isPrimary = true)
                                            FROM Opportunity WHERE id =: oppId];

            if(!ocrOppAccount.OpportunityContactRoles.isEmpty()){
                if(!ocrOppAccount.Primary_Contact_Added__c){
                    Opportunity newOpp = new Opportunity();
                    newOpp.Id = oppId;
                    newOpp.Primary_Contact_Added__c = true;
                    update newOpp;
                }
            }else{
                if(ocrOppAccount.Primary_Contact_Added__c){
                    Opportunity newOpp = new Opportunity();
                    newOpp.Id = oppId;
                    newOpp.Primary_Contact_Added__c = false;
                    update newOpp;
                }
            }
        }
        catch(Exception e){
            sendEmailError(e.getMessage());
        }
    }

    /************************************************************************************************
    * @description : method to send email when there is unexpected error
    * @author      : SalesFix Dev - CL
    * @date        : 2018-08-01
    *************************************************************************************************/
    public static void sendEmailError(String errorMessage){
        List<String> emailAddressToSend = new List<String>();
        Email_Error__c emailError = Email_Error__c.getOrgDefaults();
        if(emailError.Email_Address__c != null){
            emailAddressToSend.add(emailError.Email_Address__c);
        }
        if(!emailAddressToSend.isEmpty()){

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject('OpportunityContactRoleHelper Error on OpportunityContact page');
            email.setToAddresses(emailAddressToSend );
            email.setPlainTextBody('OpportunityContactRoleHelper failed to execute: ' + errorMessage);
            Messaging.sendEmail(new Messaging.Email[] { email });
        }
    }
}