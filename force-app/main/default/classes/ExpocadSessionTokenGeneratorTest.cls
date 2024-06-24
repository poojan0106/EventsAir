@isTest
public class ExpocadSessionTokenGeneratorTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Check if the request method is POST and if the endpoint matches
            if (req.getMethod() == 'POST' && req.getEndpoint().endsWith('/ClientUser/apiLogin')) {
                // Simulate a successful response for the POST request
                res.setBody('{"success": true, "sessionToken": "mockSessionToken"}');
                res.setStatusCode(200);
            } else {
                // Handle other endpoints or methods if needed
                res.setStatusCode(404); // Simulate a Not Found response for other requests
            }
            
            return res;
        }
    }

    @isTest
    static void testRefreshSessionToken() {
        try{
            // Mocking the callout response
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

            Test.startTest();
            ExpocadSessionTokenGenerator.refreshSessionToken();
            Test.stopTest();
        }catch(Exception e){
            System.debug(e);
        }

    }
}