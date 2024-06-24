@isTest
public class AccountTriggerTest {
    @isTest

    public static void hasInsertRunTest(){
        List<Account> testAcc = TestDataFactory.createAccounts(1);
        insert testAcc;
        
    }

}