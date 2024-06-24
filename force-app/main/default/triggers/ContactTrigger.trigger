trigger ContactTrigger on Contact (before insert) {

    if(Trigger.IsBefore && Trigger.IsInsert) {
       // ContactTriggerHandler.linkContactToAccount(Trigger.new);
    }
}