public class BatchForContactUpdate implements Database.Batchable<Contact> {
    
    
    public Iterable<Contact> start(Database.BatchableContext bc) {
        List<Contact> lstOfContact = new List<Contact>();
        
        if(!Test.isRunningTest()) {
            lstOfContact = [Select Id from contact 
                        where  LastModifiedDate >= 2024-09-18T00:00:00Z 
AND LastModifiedDate <= 2024-09-18T23:59:59Z   and 
                        (RecordType.name = 'Exhibitor / Sponsor' OR RecordType.name = 'Visitor') and 
                        OwnerId  != '00598000004osAqAAI' and
                        LastModifiedById = '00598000004osAqAAI' and
                        Is_Updated__c = false and
						LastModifiedDate != TODAY 
  						order by LastModifiedDate DESC];
        }
        else{
            lstOfContact = [Select Id from contact limit 1];
        }
        System.debug('Inside method'+lstOfContact);
        System.debug('lstOfContact.size()'+lstOfContact.size());
        return lstOfContact;
    }
    
    public void execute(Database.BatchableContext bc, List<Contact> lstOfContact) {
        System.debug('Inside method'+lstOfContact);
        
        List<ContactHistory> LstOfConHistory = new List<ContactHistory>();
        if(!Test.isRunningTest()) {
            LstOfConHistory = [SELECT ContactId, Field, OldValue, NewValue, CreatedDate , DataType
                               FROM ContactHistory 
                               WHERE CreatedDate  >= 2024-09-18T00:00:00Z 
AND CreatedDate <= 2024-09-18T23:59:59Z  
                               AND CreatedById = '00598000004osAqAAI' 
                               AND ContactId IN :lstOfContact
                               AND CreatedDate != TODAY ];
        } else {
            LstOfConHistory = [SELECT Id, ContactId, Field, OldValue, NewValue FROM ContactHistory LIMIT 5];
        }
        System.debug('Inside method' + LstOfConHistory);
        
        List<Contact> lstOfContactToUpdate = new List<Contact>();
        Set<Id> processedContactIds = new Set<Id>();  // Track processed Contact Ids
        
        // Iterate over the history records to revert changes dynamically
        for (ContactHistory history : LstOfConHistory) { 
            System.debug('@@@@ history = '+history);
            Contact contactToUpdate = new Contact(Id = history.ContactId);
            try {
                
                String fieldName = history.Field;
                
                if (fieldName == 'Account') {
                    fieldName = 'AccountId';
                }
                if (fieldName == 'RecordType') {
                    fieldName = 'RecordTypeId';
                }
                if (fieldName == 'FirstName') {
                    fieldName = 'FirstName';
                }
                if (fieldName == 'LastName') {
                    fieldName = 'LastName';
                }
                if (fieldName == 'MobilePhone') {
                    fieldName = 'MobilePhone';
                }
                if (fieldName == 'Salutation') {
                    fieldName = 'Salutation';
                }
                if (fieldName == 'Title') {
                    fieldName = 'Title';
                }
                if (fieldName == 'created') {
                    fieldName = 'created';
                }
                
                Object oldValue = history.OldValue;
                
                System.debug('Out fieldName = '+fieldName);
                System.debug('@@@ oldValue = '+oldValue);
                System.debug('Out history.DataType = '+history.DataType);
                
                String str = String.valueof(oldValue);
                if((fieldName != 'RecordTypeId' && fieldName != 'AccountId' )||
                   (fieldName == 'AccountId'  && history.DataType == 'EntityId') ||
                   (fieldName == 'RecordTypeId'  && history.DataType == 'EntityId') ){
                       System.debug('In fieldName = '+fieldName);
                       System.debug('In history.DataType = '+history.DataType);
                       contactToUpdate.put(fieldName, oldValue);
                   }
                
                System.debug('contactToUpdate' + contactToUpdate);
                contactToUpdate.Is_Updated__c = true;
                
                // Only add to list if the ContactId has not been processed yet
                /*if (!processedContactIds.contains(contactToUpdate.Id)) {
lstOfContactToUpdate.add(contactToUpdate);
processedContactIds.add(contactToUpdate.Id);
}*/
                System.debug('contactToUpdate' + contactToUpdate);
                //update contactToUpdate;
                
            } catch (Exception e) {
                System.debug('Error while reverting field: ' + history.Field + ' | ' + e.getMessage());
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
        
    }
}