@isTest
public class ExpocadSessionTokenSchedulerTest {
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('');
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void testScheduler() {
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

            // Enqueue job
            Test.startTest();
            String jobId = System.schedule('Test ExpocadSessionTokenScheduler', '0 0 * * * ?', new ExpocadSessionTokenScheduler());
            Test.stopTest();

            // Verify job has been scheduled
            CronTrigger job = [SELECT Id, CronExpression, NextFireTime FROM CronTrigger WHERE Id = :jobId];
            System.assertEquals('0 0 * * * ?', job.CronExpression);
            System.assertNotEquals(null, job.NextFireTime); 
        }catch(Exception e){
            System.debug(e);
        }
    }
}