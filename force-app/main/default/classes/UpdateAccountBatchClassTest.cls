@isTest
public class UpdateAccountBatchClassTest {
    
    @isTest
    static void testmethod1(){
        
        Account acc = new Account();
        acc.Name = 'Test account - 1';
        insert acc;
        
        contact con = new Contact();
        con.Email = 'vandanap3334@gmail.com';
        con.FirstName = 'Test vandana345';
        con.LastName = 'Test parmar';
        con.AccountId = acc.Id;
        insert con;
        
        
        Test.startTest();
        
        UpdateAccountBatchclass batchJob = new UpdateAccountBatchclass();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
    }
    
}