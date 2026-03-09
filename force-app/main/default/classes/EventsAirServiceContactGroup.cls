public with sharing class EventsAirServiceContactGroup {
    // ====== CONFIG ======
    // Consider moving these to Hierarchy Custom Settings / Custom Metadata / Named Credentials.
    private static final String TENANT_ID   = 'YOUR_AAD_TENANT_GUID'; // TODO
    private static final String CLIENT_ID   = 'YOUR_CLIENT_ID';       // TODO
    private static final String CLIENT_SECRET = 'YOUR_CLIENT_SECRET'; // TODO
    // Scope from EventsAir docs (URL-encoded when posted)
    private static final String SCOPE       = 'https://eventsairprod.onmicrosoft.com/85d8f626-4e3d-4357-89c6-327d4e6d3d93/.default';
    // Choose API host: prod or test
    private static final String GRAPHQL_BASE = 'https://api.eventsair.com/graphql'; // or https://api.eventsairtest.com/graphql

    // ====== PUBLIC DTOs ======
    public class ContactGroupResult {
        public String id;
        public String name;
        public String coordinatorId;
        public String coordinatorFirstName;
        public String coordinatorLastName;
        public String raw; // full raw response for debugging
    }

    // ====== GRAPHQL CALLER ======
    private static Map<String,Object> postGraphQL(String accessToken, String query, Object variables) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(System.Label.EventsAir_API_Base_URL);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        Map<String,Object> payload = new Map<String,Object>{
            'query' => query,
            'variables' => variables
        };
        req.setBody( JSON.serialize(payload) );

        HttpResponse res = h.send(req);
        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            Map<String,Object> out = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());

            // GraphQL errors?
            if (out.containsKey('errors')) {
                List<Object> errs = (List<Object>) out.get('errors');
                throw new CalloutException('EventsAir GraphQL errors: ' + JSON.serialize(errs));
            }
            return out;
        }
        throw new CalloutException('EventsAir GraphQL HTTP ' + res.getStatusCode() + ': ' + res.getBody());
    }

    // ====== PUBLIC: CREATE CONTACT GROUP ======
    @AuraEnabled
    public static ContactGroupResult createContactGroup(String contactId, String eventId, String groupName) {
        if (String.isBlank(eventId) || String.isBlank(groupName)) {
            throw new AuraHandledException('contactId, eventId, and groupName are required.');
        }
        String token = EventsAirOAuthTokenRequest.getAccessToken('RecordType');

        // GraphQL mutation (variables-based)  // input fields: contactId, eventId, groupName **** // query fields: name, coordinator { id firstName lastName }, members { id }
        String mutation = ''
        + 'mutation CreateGroup($input: CreateEventContactGroupInput!) {'
        + '  createEventContactGroup(input: $input) {'
        + '    group {'
        + '      name'
        + '      coordinator { id firstName lastName }'
        + '      members { id }'                // optional to confirm empty on create
        + '    }'
        + '  }'
        + '}';

        Map<String,Object> input = new Map<String,Object>{
            'contactId' => contactId,
            'eventId'   => eventId,
            'groupName' => groupName
        };
        Map<String,Object> variables = new Map<String,Object>{ 'input' => input };

        Map<String,Object> response = postGraphQL(token, mutation, variables);
        // Parse data
        Map<String,Object> data = (Map<String,Object>) response.get('data');
        if (data == null || !data.containsKey('createEventContactGroup')) {
            throw new CalloutException('Unexpected response shape: ' + JSON.serialize(response));
        }
        Map<String,Object> payload = (Map<String,Object>) data.get('createEventContactGroup');
        Map<String,Object> grp = (Map<String,Object>) payload.get('group');

        ContactGroupResult result = new ContactGroupResult();
        result.id = (String) grp.get('id');
        result.name = (String) grp.get('name');
        Map<String,Object> coord = (Map<String,Object>) grp.get('coordinator');
        if (coord != null) {
            result.coordinatorId = (String) coord.get('id');
            result.coordinatorFirstName = (String) coord.get('firstName');
            result.coordinatorLastName  = (String) coord.get('lastName');
        }
        result.raw = JSON.serialize(response);
        System.debug('Created EventsAir contact group: ' + result.raw);
        return result;
    }

}