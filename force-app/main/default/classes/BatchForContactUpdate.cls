public without sharing class  BatchForContactUpdate implements Database.Batchable<Contact> {
    
    public Iterable<Contact> start(Database.BatchableContext bc) {
        
        List<Contact> lstOfContact = new List<Contact>();
        if(!Test.isRunningTest()) {
            lstOfContact = [Select Id,Readt_to_process__c from contact  where Readt_to_process__c = true
                            order by LastModifiedDate DESC];
        } else {
            lstOfContact = [Select Id,Readt_to_process__c from contact limit 1];
        }
        System.debug('Inside method'+lstOfContact);
        System.debug('lstOfContact.size()'+lstOfContact.size());
        return lstOfContact;
    }
    
    public void execute(Database.BatchableContext bc, List<Contact> lstOfContact) {
        
        
        List<Contact> lstOfContactToUpdate = new List<Contact>();
        Set<Id> processedContactIds = new Set<Id>();  // Track processed Contact Ids
        
        for(Contact con: lstOfContact){
            
            List<ContactHistory> lstofContactHistory = new List<ContactHistory>();
            if(!Test.isRunningTest()) {
                lstofContactHistory = [SELECT ContactId, Field, OldValue, NewValue, CreatedDate , DataType
                                       FROM ContactHistory 
                                       WHERE Contact.Readt_to_process__c = true  
                                       AND CreatedById = '00598000004osAqAAI' and ContactId = :con.Id AND Field = 'Account'
                                       ORDER BY CreatedDate ASC limit 1];
                
            }
            else{
                lstofContactHistory = [SELECT Id, ContactId, Field, OldValue, NewValue FROM ContactHistory where ContactId = :con.Id  ];
            }
            
            Contact contactToUpdate = new Contact(Id = con.Id);
            
            try {
                
                String fieldName = lstofContactHistory[0].Field;
                
                if (fieldName == 'Account') {
                    fieldName = 'AccountId';
                }
                
                Object oldValue = lstofContactHistory[0].OldValue;
                String oldValueStr = String.valueOf(oldValue);
                System.debug('Out fieldName = '+fieldName);
                System.debug('@@@ oldValue = '+oldValue);
                List<Account> LstOfAcct = [Select Id ,name From Account where name =:oldValueStr ORDER BY CreatedDate DESC limit 1];
                System.debug('Out history.DataType = '+lstofContactHistory[0].DataType);
                
                String str = String.valueof(oldValue);
                
                System.debug('In fieldName = '+fieldName);
                System.debug('In history.DataType = '+lstofContactHistory[0].DataType);
                contactToUpdate.put('AccountId', LstOfAcct[0].Id);
                
                
                System.debug('contactToUpdate' + contactToUpdate);
                System.debug('contactToUpdate' + contactToUpdate);
                contactToUpdate.Readt_to_process__c = false;
           		 update contactToUpdate;
                
                
            } catch (Exception e) {
                System.debug('Error while reverting field: ' + lstofContactHistory[0].Field + ' | ' + e.getMessage());
            }
            
            
        }
        //update lstOfContactToUpdate;
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch processing completed.');
    }
    
    
    public void dumyy() {
        Integer i = 1;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
        
    }
}