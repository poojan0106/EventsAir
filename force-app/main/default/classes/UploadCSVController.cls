public with sharing class UploadCSVController {
    @AuraEnabled
    public static List<Co_Exhibitor__c> uploadCoExhibitors(String csvData, String OpportunityId) {
        System.debug('csvData---->'+csvData);
        System.debug('OpportunityId--->'+OpportunityId);
        List<Map<String, String>> records = (List<Map<String, String>>) JSON.deserialize(csvData, List<Map<String, String>>.class);
        System.debug('records--->'+records);
        List<Co_Exhibitor__c> coExhibitorList = new List<Co_Exhibitor__c>();

        Set<String> emailSet = new Set<String>();
        Set<String> companySet = new Set<String>();

        // Collect unique emails and company names
        for (Map<String, String> record : records) {
            if (record.containsKey('Email Address')) {
                emailSet.add(record.get('Email Address'));
            }
            if (record.containsKey('Company Name')) {
                companySet.add(record.get('Company Name'));
            }
        }

        // Fetch existing accounts using email OR company name
        Map<String, Account> accountMap = new Map<String, Account>();
        List<Account> accList = [Select Id, Name, Email_Address_1__c from Account where Name IN:companySet AND Email_Address_1__c IN:emailSet];
        if (!emailSet.isEmpty() || !companySet.isEmpty()) {
            for (Account acc :accList) {
                accountMap.put(acc.Name, acc);
            }
        }

        // Create new accounts where necessary
        List<Account> accountsToInsert = new List<Account>();
        for (Map<String, String> record : records) {
            String email = record.get('Email Address');
            String companyName = record.get('Company Name');
            String City = record.get('City');
            String State = record.get('State');
            String PostalCode = record.get('Postal Code');
            String Country = record.get('Country');
            String WorkPhone = record.get('Work Phone');
            
            System.debug('email--->'+ email +' ,companyName-->'+companyName+ ' ,City-->'+City+ ' ,State-->'+State +' ,PostalCode--->'+PostalCode+ ' ,Country-->'+ ' ,WorkPhone-->'+WorkPhone);
            
            if (!accountMap.containsKey(companyName)) {
                Account newAcc = new Account(Name = companyName);
                accountsToInsert.add(newAcc);
            }
        }

        if (!accountsToInsert.isEmpty()) {
           // insert accountsToInsert;
            for (Account acc : accountsToInsert) {
                accountMap.put(acc.Name, acc);
            }
        }

        // Create Co_Exhibitor__c records
        for (Map<String, String> record : records) {
            String companyName = record.get('Company Name');

            if (accountMap.containsKey(companyName)) {
                Co_Exhibitor__c coExhibitor = new Co_Exhibitor__c();
                coExhibitor.Account__c = accountMap.get(companyName).Id;
                coExhibitorList.add(coExhibitor);
            }
        }

        if (!coExhibitorList.isEmpty()) {
            //insert coExhibitorList;
        }
        
        return coExhibitorList;
    
    }
}