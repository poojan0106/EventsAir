@isTest
public class AccountOnboardingScheduleTest {
    
    public static String CRON_EXP = '0 0 0 15 3 ? ' + (date.today().year() + 1);

    @testSetup
    static void initialize() {

        System.debug('cron time '+ CRON_EXP);

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

        // Must Update the close date again to make sure it is not affected by other process
        opp.CloseDate = date.today().addYears(-1);
        update opp;

        //Add products to opportunities
        List<OpportunityLineItem> lines = new List<OpportunityLineItem>();

        List<Opportunity> oppList = [Select Id,Name from Opportunity];
        for(Opportunity record: oppList){
            lines.add(new OpportunityLineItem(PricebookEntryId=priceBookEntry.Id, OpportunityId=record.Id, UnitPrice=priceBookEntry.UnitPrice, Quantity=1));
        }

        insert lines;

    }
    
    static testMethod void testScheduledJob() {

        Test.startTest();

        // Schedule the test job
        String jobId = System.schedule('AccountOnboardingSched',
            CRON_EXP,
            new AccountOnboardingSchedule());
        // Verify the scheduled job has not run yet.
        
        Account acct = [SELECT Name, Account_Status__c FROM Account];
        System.assertEquals('Onboarding', acct.Account_Status__c, 'Account already updated before job has run');
        // Stopping the test will run the job synchronously
        Test.stopTest();

        Account acctNew = [SELECT Name, Account_Status__c FROM Account];
        System.assertEquals('Development', acctNew.Account_Status__c);

    }
}