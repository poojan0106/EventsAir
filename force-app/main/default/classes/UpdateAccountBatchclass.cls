global class UpdateAccountBatchclass implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name FROM Account';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> LstOfAccts) {
        List<Contact> LstOfContact = [select Id,name,Email,AccountId from contact where AccountId in :LstOfAccts];
        Map<Id, String> accountToContactsMap = new Map<Id,string>();
        for (Contact con : LstOfContact) {
            if(!accountToContactsMap.containsKey(con.AccountId)){
                accountToContactsMap.put(con.AccountId,con.Email); 
            }
        }
        
        List<Account> LstOfAcctToUpdt = new List<Account>();
        for (Id id : accountToContactsMap.keySet()) {
            if(accountToContactsMap.get(id) != null){
                
            string conEmail = accountToContactsMap.get(id);
            List<string> emailparts = conEmail.split('@');
            string DomainName;
            if (emailparts.size() > 1) {
                DomainName = emailparts[1].trim();
            }
            Account acc = new Account();
            acc.id = id;
            acc.Domain_Name__c = DomainName;
            LstOfAcctToUpdt.add(acc);
                
            }
         }
        
        if(LstOfAcctToUpdt.size()>0){
            update LstOfAcctToUpdt;
         }
    }
    
    global void finish(Database.BatchableContext BC) {
    }
}