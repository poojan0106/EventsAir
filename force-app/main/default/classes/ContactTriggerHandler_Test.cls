@isTest
public class ContactTriggerHandler_Test {
    
    static testMethod void testMethod1(){
        
        contact con = new Contact();
        con.Email = 'vandanap@gmail.com';
        con.FirstName = 'Test vandana';
        con.LastName = 'Test parmar';
       // con.AccountId = null;
        insert con;
        
         Account acc = new Account();
        acc.Name = 'Test account - 1';
        acc.Domain_Name__c = 'gmail.com';
        insert acc;
        
        
        
    }
    
     /*static testMethod void testMethod2(){
         
         
         Account acc = new Account();
        acc.Name = 'Test account - 2';
        acc.Domain_Name__c = 'gmal.com';
        insert acc;
        
        contact con = new Contact();
        con.Email = 'vandana@gmal.com';
        con.FirstName = 'Fname';
        con.LastName = 'Lname';
        con.AccountId = acc.Id;
        insert con;
        
        
        
    }*/


}