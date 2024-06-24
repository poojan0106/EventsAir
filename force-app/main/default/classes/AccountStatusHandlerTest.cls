@isTest
public class AccountStatusHandlerTest {

    @testSetup static void setup() {

        /* 
        * Cannot add amount in opportunity directly for testing
        * because of the workflow 
        * 'Approve opportunity when discount applied goes below threshold' and
        * 'Unapprove Oppty For Breaking Discount Threshold' will cause an error
        * Instead created product to add amount to Opportunity
        */

        // Create a Pricebook
        Pricebook2 priceBook = new Pricebook2(
            Name = 'Example Price Book',
            Description = 'Description',
            IsActive = true
        );

        insert priceBook;

        // Create a Product
        Product2 product = new Product2(
            Name = 'Example Product',
            Description = 'This is the Product description.',
            Target_Category__c = 'Example Category',
            ProductCode = 'EX1234',
            StockKeepingUnit = 'EX5678',
            Family = 'Example Product Family',
            QuantityUnitOfMeasure = 'inches',
            DisplayUrl = 'https://www.example.com/',
            IsActive = true
        );

        insert product;

        // Insert the Product in the Standard Price Book
        PricebookEntry standardPriceBookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100.00,
            UseStandardPrice = false,
            IsActive = true
        );

        insert standardPriceBookEntry;

        // Insert the Product in the New Price Book
        PricebookEntry priceBookEntry = new PricebookEntry(
            Pricebook2Id = priceBook.Id,
            Product2Id = product.Id,
            UnitPrice = 100.00,
            UseStandardPrice = false,
            IsActive = true
        );

        insert priceBookEntry;

        Account obAcc = new Account();
        obAcc.Name = 'Test 1';
        obAcc.Account_Status__c = 'Onboarding';
        obAcc.BillingStreet = '333 George Street';
        obAcc.BillingCity = 'Sydney';
        obAcc.BillingPostalCode = '2000';
        obAcc.BillingState = 'New South Wales';
        obAcc.BillingCountry = 'Australia';

        insert obAcc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Opportunity 1';
        opp.AccountId = obAcc.Id;
        opp.CloseDate = date.today().addYears(-1);
        opp.StageName = 'Closed Won';

        insert opp;

        Opportunity opp2 = new Opportunity();
        opp2.Name = 'Opportunity 2';
        opp2.AccountId = obAcc.Id;
        opp2.CloseDate = date.today().addYears(-2);
        opp2.StageName = 'Closed Won'; 

        insert opp2;

        Opportunity opp3 = new Opportunity();
        opp3.Name = 'Opportunity 3';
        opp3.AccountId = obAcc.Id;
        opp3.CloseDate = date.today().addYears(-3);
        opp3.StageName = 'Closed Won'; 

        insert opp3;

        // Must Update the close date again to make sure it is not affected by other process
        opp.CloseDate = date.today().addYears(-1);
        opp2.CloseDate = date.today().addYears(-2);

        update opp;
        update opp2;

        //Add products to opportunities
        List<OpportunityLineItem> lines = new List<OpportunityLineItem>();

        List<Opportunity> oppList = [Select Id,Name from Opportunity];
        for(Opportunity record: oppList){
            lines.add(new OpportunityLineItem(PricebookEntryId=priceBookEntry.Id, OpportunityId=record.Id, UnitPrice=priceBookEntry.UnitPrice, Quantity=1));
        }

        insert lines;

    }   

    @isTest static void testUpdateOnboardingStatus() { 

        // Testing
        AccountStatusHandler.updateOnboardingStatus();

        Account acct = [SELECT Name, Account_Status__c FROM Account];
        System.assertEquals('Development', acct.Account_Status__c);

    }

    @isTest static void testUpdateDevelopmentStatus() {     

        Account acc = [SELECT Name, Account_Status__c FROM Account];
        acc.Account_Status__c = 'Development';
        update acc;

        // Testing
        AccountStatusHandler.updateDevelopmentStatus();
        // Testing

       Account acct = [SELECT Name, Account_Status__c FROM Account];
       System.assertEquals('Engaged', acct.Account_Status__c);

    }

    @isTest static void testUpdateEngagedStatusHasWon() {     

        Account acc = [SELECT Name, Account_Status__c FROM Account];
        acc.Account_Status__c = 'Engaged';
        update acc;

        // Testing
        AccountStatusHandler.updateEngagedStatus();

       Account acct = [SELECT Name, Account_Status__c FROM Account];
       System.assertEquals('Engaged', acct.Account_Status__c);

    }

    @isTest static void testUpdateEngagedStatusEmpty() {     
        
        Test.startTest();
        Account acc = [SELECT Name, Account_Status__c FROM Account];
        acc.Account_Status__c = 'Engaged';
        update acc;

        List<Opportunity> oppList = [SELECT CloseDate, StageName FROM Opportunity];
        for( Opportunity opp : oppList ){
            opp.CloseDate = date.today();
        }

        update oppList;

         // Testing
        
        AccountStatusHandler.updateEngagedStatus();
        Test.stopTest();

       Account acct = [SELECT Name, Account_Status__c FROM Account];
       System.assertEquals('Lapsed', acct.Account_Status__c);

    }
    
   @isTest static void testUpdateEngagedStatusHasLost() {     

        Test.startTest();
        Account acc = [SELECT Name, Account_Status__c FROM Account];
        acc.Account_Status__c = 'Engaged';
        update acc;

        Opportunity opp = [SELECT CloseDate, StageName,Is_Withdrawn__c FROM Opportunity WHERE Name = 'Opportunity 2'];

        opp.Is_Withdrawn__c = true;
        opp.StageName = 'Closed Lost';  

        update opp;
        
        // Testing
        AccountStatusHandler.updateEngagedStatus();
        Test.stopTest();

       Account acct = [SELECT Name, Account_Status__c FROM Account];
       System.assertEquals('Development', acct.Account_Status__c);

    } 

    @isTest static void testUpdateEngagedStatusLapsed() {     

        Test.startTest();
        Account acc = [SELECT Name, Account_Status__c FROM Account];
        acc.Account_Status__c = 'Engaged';
        update acc;

        List<Opportunity> oppList = [SELECT CloseDate, StageName FROM Opportunity];

        for(Opportunity opp: oppList){
            opp.CloseDate = date.today().addYears(-3);
        }

        update oppList;
        
        // Testing
        AccountStatusHandler.updateEngagedStatus();
        Test.stopTest();

       Account acct = [SELECT Name, Account_Status__c FROM Account];
       System.assertEquals('Lapsed', acct.Account_Status__c);

    }
    
    @isTest static void testUpdateEngagedStatusWithdrawal() {     

        Test.startTest();
        Account acc = [SELECT Name, Account_Status__c FROM Account];
        acc.Account_Status__c = 'Engaged';
        update acc;

        List<Opportunity> oppList = [SELECT CloseDate, StageName,Is_Withdrawn__c FROM Opportunity];
        for( Opportunity opp : oppList ){
            opp.Is_Withdrawn__c = true;
            opp.StageName = 'Closed Lost';
        }

        update oppList;

        // Testing
        AccountStatusHandler.updateEngagedStatus();
        Test.stopTest();

       Account acct = [SELECT Name, Account_Status__c FROM Account];
       System.assertEquals('Development', acct.Account_Status__c);

    } 

}