public class SyncContactIdWithEventsAirExternalId implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, EventsAir_Contact_Id__c, EventsAir_Event_Id__c, ExternalIdentifier__c
            FROM Contact
            WHERE Sync_To_EventsAir__c = true
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        // Build GraphQL mutation for this chunk
        String gqlQuery = 'mutation UpdateMultipleContacts {\n';
        Integer i = 0;
        for (Contact c : scope) {
            i++;
            gqlQuery += '  c' + i + ': updateContactDetails(input: {\n';
            gqlQuery += '    contactId: "' + c.EventsAir_Contact_Id__c + '",\n';
            gqlQuery += '    eventId: "' + c.EventsAir_Event_Id__c + '",\n';
            gqlQuery += '    externalIdentifier: "' + c.ExternalIdentifier__c + '"\n';
            gqlQuery += '  }) {\n';
            gqlQuery += '    contact { id externalIdentifier }\n';
            gqlQuery += '  }\n';
        }
        gqlQuery += '}';

        Map<String, Object> body = new Map<String, Object>();
        body.put('query', gqlQuery);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:EventsAir_GraphQL'); // Named Credential
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('### EventsAir Response: ' + res.getBody());

        // Clear the flag after successful sync
        for (Contact c : scope) {
            c.Sync_To_EventsAir__c = false;
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Sync batch finished.');
    }
}