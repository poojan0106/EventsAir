public class SyncContactIdWithEventsAirExternalId 
    implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {

    public Map<String, String> contactIdToExternalId;
    public String sfeventId;
    public String streventId;
    public String recordTypeName;
    public Integer totalRecords;
    public Integer processedRecords = 0;

    public SyncContactIdWithEventsAirExternalId(
        Map<String, String> contactIdToExternalId,
        String sfeventId,
        String streventId,
        String recordTypeName,
        Integer totalRecords
    ) {
        this.contactIdToExternalId = contactIdToExternalId;
        this.sfeventId = sfeventId;
        this.streventId = streventId;
        this.recordTypeName = recordTypeName;
        this.totalRecords = totalRecords;
    }

    // Instead of querying, we just return the set of keys
    public Iterable<String> start(Database.BatchableContext bc) {
        return contactIdToExternalId.keySet();
    }

    // Each execute() gets a chunk of contact IDs directly
    public void execute(Database.BatchableContext bc, List<String> scopeContactIds) {
        processedRecords += scopeContactIds.size();
        Integer chunkSize = 15; // GraphQL alias batching
        String strrToken = EventsAirOAuthTokenRequest.getAccessToken(recordTypeName);
        Map<Id, Contact> contactsMap = new Map<Id, Contact>();
        Map<Id, Lead> leadsMap = new Map<Id, Lead>();

        for (Integer i = 0; i < scopeContactIds.size(); i += chunkSize) {
            List<String> chunkContactIds = new List<String>();
            for (Integer j = i; j < Math.min(i + chunkSize, scopeContactIds.size()); j++) {
                chunkContactIds.add(scopeContactIds[j]);
            }
            String gqlQuery = 'mutation UpdateMultipleContacts {\n';
            Integer alias = 0;

            for (String eaContactId : chunkContactIds) {
                alias++;
                String externalIdentifier = contactIdToExternalId.get(eaContactId);

                gqlQuery += '  c' + alias + ': updateContactDetails(input: {\n';
                gqlQuery += '    contactId: "' + eaContactId + '",\n';
                gqlQuery += '    eventId: "' + streventId + '",\n';
                gqlQuery += '    externalIdentifier: "' + externalIdentifier + '"\n';
                gqlQuery += '  }) {\n';
                gqlQuery += '    contact { id externalIdentifier }\n';
                gqlQuery += '  }\n';
            }
            gqlQuery += '}';

            Map<String, Object> body = new Map<String, Object>{ 'query' => gqlQuery };

            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://developer.eventsair.com/graphql'); // ✅ production endpoint
            req.setMethod('POST');
            req.setTimeout(120000);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + strrToken);
            req.setBody(JSON.serialize(body));

            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('### Response for chunk ' + (i/chunkSize+1) + ': ' + res.getBody());
            if (res.getStatusCode() == 200 && !String.isBlank(res.getBody())) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                if (responseMap.containsKey('data')) {
                    Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
                    for (String aliasKey : dataMap.keySet()) {
                        Map<String, Object> aliasResult = (Map<String, Object>) dataMap.get(aliasKey);
                        if (aliasResult != null && aliasResult.containsKey('contact')) {
                            Map<String, Object> contactData = (Map<String, Object>) aliasResult.get('contact');

                            if (contactData != null && contactData.containsKey('externalIdentifier')) {
                                String sfRecordId = String.valueOf(contactData.get('externalIdentifier'));

                                if (sfRecordId.startsWith('003')) { // Contact Id
                                    contactsMap.put(sfRecordId, new Contact(Id = sfRecordId, Is_ExternalId_Synced__c = true));
                                } else if (sfRecordId.startsWith('00Q')) { // Lead Id
                                    leadsMap.put(sfRecordId, new Lead(Id = sfRecordId, Is_ExternalId_Synced__c = true));
                                }
                            }
                        }
                    }
                }
            }
        }

        if (!contactsMap.isEmpty()) {
            update contactsMap.values();
        }
        if (!leadsMap.isEmpty()) {
            update leadsMap.values();
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('processedRecords: ' + processedRecords + ', totalRecords: ' + totalRecords);
        if(sfeventId != null && sfeventId != '' && processedRecords == totalRecords) {
            FeedItem post = new FeedItem();
            post.ParentId = sfeventId; //eg. Opportunity id, custom object id..
            post.Body = 'Apex batch End for Sync Salesforce Contact with EventsAir Contact';
            insert post;
        }
    }
}