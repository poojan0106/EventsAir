@isTest
private class TestImportRegSeprateSecAndIntController {

    @isTest
    static void testExecuteBatch() {
        // Create test Event__c record
        Event__c testEvent = new Event__c(
            Name = 'Test Event',
            EventsAirID__c = 'TestAirID123', 
            Event_Portfolio__c = 'Wealth'
        );
        insert testEvent;

        // Instantiate StandardController with Event__c
        ApexPages.StandardController stdController = new ApexPages.StandardController(testEvent);

        // Instantiate custom controller
        ImportRegSeprateSecAndIntController controller = new ImportRegSeprateSecAndIntController(stdController);

        Test.startTest();
        PageReference result = controller.executeBatch();
        Test.stopTest();

        // Assert that result is redirecting to the Event record
        System.assertNotEquals(null, result);
        System.assert(result.getUrl().contains(testEvent.Id));

        // Optional: Verify FeedItem is created
        List<FeedItem> feedItems = [SELECT Id, ParentId, Body FROM FeedItem WHERE ParentId = :testEvent.Id];
        System.assertEquals(1, feedItems.size());
        System.assertEquals('Apex batch Start for fetching EventsAir Data', feedItems[0].Body);
    }
}