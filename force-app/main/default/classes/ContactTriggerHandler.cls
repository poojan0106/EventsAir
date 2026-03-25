public class ContactTriggerHandler {
    
    public static void linkContactToAccount(List<Contact> lstCon){
        
        Set<String> setOfDomainName = new Set<String>();
        
        //loop through list of contacts and fill the set code start
        for(Contact objCon: lstCon) {
            
            //extract domain name from email and add to set
            if(objCon.email != null) {
                String[] emailparts = objCon.email.split('@');
                if (emailparts.size() > 1) {
                    setOfDomainName.add(emailparts[1].trim());
                }
            }
        }
        //loop through list of contacts and fill the set code end
        
        Map<String, Id> mapOforgNameAndAccId = new Map<String, Id>();  
        Map<String, Id> mapOfDomainNameAndAccId = new Map<String, Id>();
        
        System.debug('@@@ setOfDomainName = '+setOfDomainName);
        
        //if two set contains any value then do soql on account 
        if(setOfDomainName != null) {
            
            //fetch account based on contact's organization name and domain name (email)
            List<Account> lstAccount = [SELECT Id, Name, Domain_Name__c
                                        FROM Account 
                                        WHERE Domain_Name__c IN: setOfDomainName
                                        FOR UPDATE];
            
            if(!lstAccount.isEmpty()) {
                for(Account objacc: lstAccount) {
                    mapOforgNameAndAccId.put(objacc.Name, objacc.Id);
                    mapOfDomainNameAndAccId.put(objacc.Domain_Name__c, objacc.Id);
                }                                                    
            }        
            
            System.debug('@@@@ mapOforgNameAndAccId = '+mapOforgNameAndAccId);
            
            List<Lead> lstInsrtLead = new List<Lead>();
            
            //if account map is not null then update account id on contact
            if(mapOforgNameAndAccId != null) {
                //loop through contact list to set account id code start
                for(Contact con: lstcon) {
                    
                    if(con.Email != null) {
                        
                        String strtempdomain;
                        String[] emailparts = con.email.split('@');
                        if (emailparts.size() > 1) {
                            strtempdomain = (emailparts[1].trim());
                        }
                        if(mapOfDomainNameAndAccId.containskey(strtempdomain)) {
                            con.AccountId = mapOfDomainNameAndAccId.get(strtempdomain);
                        }
                    }
                    
                    //if can't find account based on domain name then create lead
                    if(con.AccountId == null) {
                        
                        //create lead
                        // Create a new lead and populate fields
                        Lead newLead = new Lead();
                        newLead.FirstName = con.FirstName;
                        newLead.LastName = con.LastName;
                        newLead.Email = con.Email;
                        newLead.Phone = con.Phone;
                        newLead.Event_Category__c = 'AOG Energy';
                        newLead.Business_Unit__c = 'Divcom';
                        if(con.Organization_Name__c != null) {
                            newLead.Company = con.Organization_Name__c;
                        }
                        else{
                            newLead.Company = 'Test Company';
                        }
                        newLead.Status = 'New';
                        lstInsrtLead.add(newLead);
                    }
                    
                }            
                //loop through contact list to set account id code end
                if(!lstInsrtLead.IsEmpty()) {
                    insert lstInsrtLead;
                }
            }            
        }
        
    }
}