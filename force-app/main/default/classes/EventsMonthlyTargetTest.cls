@IsTest
public class EventsMonthlyTargetTest {
    @TestSetup static void testSetup() {
        Event__c eventTest = new Event__c();
        eventTest.Name = 'Test Event';
        eventTest.Open_Date__c = DateTime.now();
        eventTest.Event_Portfolio__c = 'Built Environment';
        Insert eventTest;
    }
    
    @IsTest
    public static void eventsMonthlyTargetInvocableTest(){
        Event__c evTest = [Select Id From Event__c Limit 1];
        EventsMonthlyTargetInvocable.saveEventMonthlyTarget(new List<Id>{evTest.Id});
    }
}