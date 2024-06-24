public class LinkObjectsHandler {

    public static void LinkFunctionToRegistration(List<Registration__c> lstRegistration) {
        
        Set<String> setOfEventFunId = new Set<String>();
        List<Function__c> lstFunction;
        
        for(Registration__c objReg: lstRegistration) {
            if(objReg.EventsAir_Function_Id__c != null) {
                setOfEventFunId.add(objReg.EventsAir_Function_Id__c);
            }
        }
        if(!setOfEventFunId.isEmpty()) {
            lstFunction = [SELECT Id, EventsAir_ID__c
                           FROM Function__c
                           WHERE EventsAir_ID__c IN: setOfEventFunId];
        }
        Map<String,Id> mapOfEventFunIdAndFunId = new Map<String, Id>();
        List<Registration__c> lstupdtReg = new List<Registration__c>();
        
        if(lstFunction != null) {
            for(Function__c objFun: lstFunction) {
                mapOfEventFunIdAndFunId.put(objFun.EventsAir_ID__c, objFun.Id);
            }
        }
        
        if(mapOfEventFunIdAndFunId != null) {
            for(Registration__c objReg: lstRegistration) {
                if(mapOfEventFunIdAndFunId.containsKey(objReg.EventsAir_Function_Id__c)) {
                    Registration__c reg = new Registration__c();
                    reg.id = objReg.id;
                    reg.Function__c = mapOfEventFunIdAndFunId.get(objReg.EventsAir_Function_Id__c);
                    lstupdtReg.add(reg);
                }                
            }
            if(!lstupdtReg.isEmpty()) {
                update lstupdtReg;
            }
        }
    }
    
    public static void linkAccToOpp(List<Opportunity> lstOpp) {
        
        /*Set<String> setOfEventConIds = new Set<String>();
        
        for(Opportunity objOpp: lstOpp) {
            if(objOpp.EventsAir_Contact_Id__c != null) {
                setOfEventConIds.add(objOpp.EventsAir_Contact_Id__c);
            }
        }
        Map<String, id> mapOfEvntConIdAndAccId = new Map<String, Id>();
        if(!setOfEventConIds.isEmpty()) {
            List<Contact> lstContact = [Select Id, AccountId, EventsAir_Contact_Id__c from Contact 
                                        where EventsAir_Contact_Id__c IN: setOfEventConIds and AccountId != null];
                        
            if(!lstContact.isEmpty()) {
                for(Contact objCon: lstContact) {
                    mapOfEvntConIdAndAccId.put(objCon.EventsAir_Contact_Id__c, objCon.AccountId);
                }
            }
        }
                
        if(mapOfEvntConIdAndAccId != null) {
            List<Opportunity> lstupdtOpp = new List<Opportunity>();
            
            for(Opportunity opp: lstOpp) {
                if(mapOfEvntConIdAndAccId.containskey(opp.EventsAir_Contact_Id__c)) {
                    Opportunity objOpp = new Opportunity();
                    objOpp.Id = opp.Id;
                    objOpp.AccountId = mapOfEvntConIdAndAccId.get(opp.EventsAir_Contact_Id__c);
                    lstupdtOpp.add(objOpp);
                }
            }            
            if(!lstupdtOpp.isEmpty()) {
                update lstupdtOpp;
            }
        } */
    }
}