@isTest
public class ImportFunRegSeprateSecAndInteLiveTest {

    @testSetup
    static void setupData() {
        upsert new ManageEvtAir_FunReg_SecAndInt_Live_Batch__c(
            Name = 'Test batch settings',
            Offset__c = 0,
            Is_Execute_Next__c = false,
            Generic_Email_Domains__c = 'gmail.com,yahoo.com,bigpond.com'
        );

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
    }

    @isTest
    static void testBatchSuccessPath() {
        Test.setMock(HttpCalloutMock.class, setStaticMock('importfuncregistrationMockCoverage'));

        Event__c testEvent = createEvent('Security', 'Food', true);
        seedFunctionRegistrationData(testEvent);

        Test.startTest();
        Database.executeBatch(new ImportFunRegSeprateSecAndInteLiveBatch());
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Pricebook2 WHERE Events__c = :testEvent.Id] > 0);
    }

    @isTest
    static void testStartErrorPath() {
        Test.setMock(HttpCalloutMock.class, new ErrorCalloutMock(500, '{"message":"boom"}'));

        Event__c testEvent = createEvent('Fire', 'Food', true);
        seedFunctionRegistrationData(testEvent);

        Test.startTest();
        Database.executeBatch(new ImportFunRegSeprateSecAndInteLiveBatch());
        Test.stopTest();

        ManageEvtAir_FunReg_SecAndInt_Live_Batch__c cfg = [
            SELECT Offset__c, Is_Execute_Next__c
            FROM ManageEvtAir_FunReg_SecAndInt_Live_Batch__c
            LIMIT 1
        ];
        System.assertEquals(0, cfg.Offset__c);
        System.assertEquals(false, cfg.Is_Execute_Next__c);
    }

    @isTest
    static void testHelperBranches() {
        Event__c testEvent = createEvent('Security', 'Technology', true);
        insert new Pricebook2(
            Name = testEvent.Name + ' Visitor',
            Events__c = testEvent.Id,
            IsActive = true,
            Description = 'Test pricebook'
        );
        testEvent.Is_Pricebook_Created__c = true;
        update testEvent;

        Account acc = new Account(Name = 'Test Account', Domain_Name__c = 'gmail.com');
        insert acc;

        Contact existingContact = new Contact(
            FirstName = 'Fname',
            LastName = 'Lname',
            Email = 'existing@example.com',
            AccountId = acc.Id,
            EventsAir_Con_ID__c = 'CON-EXIST'
        );
        insert existingContact;

        Lead existingLead = new Lead(
            FirstName = 'Lead',
            LastName = 'Exists',
            Email = 'lead.exists@example.com',
            Company = 'Acme',
            Event_Category__c = 'Security'
        );
        insert existingLead;

        Product_Service_Option__c existingProductService = new Product_Service_Option__c(
            Name = 'Existing service',
            EventsAirMarketing_Record_ID__c = 'PSO-EXIST'
        );
        insert existingProductService;

        Registration__c existingRegistration = new Registration__c(
            Event__c = testEvent.Id,
            Lead__c = existingLead.Id,
            Registration_Type__c = 'Business Summit - Early Bird',
            EventsAir_Regisration_ID__c = 'REG-EXIST'
        );
        insert existingRegistration;

        Opportunity existingOpportunity = new Opportunity(
            Name = 'Existing Opp Seed',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            EventsAir_Contact_Id__c = 'CON-EXIST',
            AccountId = acc.Id
        );
        insert existingOpportunity;

        Function__c existingFunction = new Function__c(
            Name = 'Existing Function',
            Events__c = testEvent.Id,
            EventsAir_ID__c = 'FUN-EXIST',
            Function_Date__c = Date.today()
        );
        insert existingFunction;

        ImportFunRegSeprateSecAndInteLiveBatch batch = new ImportFunRegSeprateSecAndInteLiveBatch();
        batch.sfeventId = testEvent.Id;
        batch.eventData = new List<Event__c>{ testEvent };
        batch.eventCategory = 'Security';

        Contact insertContact = new Contact(
            FirstName = 'New',
            LastName = 'Contact',
            Email = 'new.contact@example.com'
        );
        Contact updateContact = new Contact(
            Id = existingContact.Id,
            FirstName = existingContact.FirstName,
            LastName = existingContact.LastName,
            Email = existingContact.Email
        );
        insertContact.AccountId = acc.Id;
        updateContact.AccountId = acc.Id;

        Lead insertLead = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Email = 'new.lead@example.com',
            Company = 'Acme',
            Event_Category__c = 'Security'
        );
        Lead updateLead = new Lead(
            Id = existingLead.Id,
            FirstName = existingLead.FirstName,
            LastName = existingLead.LastName,
            Email = existingLead.Email,
            Company = 'Acme',
            Event_Category__c = 'Security'
        );

        ImportFunRegSeprateSecAndInteLiveBatch.insertContactsIfNotExist(
            new List<Contact>{ insertContact, new Contact(FirstName = 'New', LastName = 'Contact', Email = 'new.contact@example.com') },
            new Map<String, Boolean>{ 'fnamelnameexisting@example.com' => true },
            new List<Contact>{ updateContact }
        );

        ImportFunRegSeprateSecAndInteLiveBatch.insertLeadsIfNotExist(
            new List<Lead>{ insertLead, new Lead(FirstName = 'New', LastName = 'Lead', Email = 'new.lead@example.com', Company = 'Acme', Event_Category__c = 'Security') },
            new Map<String, Boolean>{ 'leadexistslead.exists@example.com' => true },
            new List<Lead>{ updateLead }
        );

        Product_Service_Option__c newProductService = new Product_Service_Option__c(
            Name = 'New service',
            EventsAirMarketing_Record_ID__c = 'PSO-NEW'
        );
        Product_Service_Option__c updateProductService = new Product_Service_Option__c(
            Name = 'Existing service updated',
            EventsAirMarketing_Record_ID__c = 'PSO-EXIST'
        );
        batch.insertProdAndServicesIfNotExist(new List<Product_Service_Option__c>{ newProductService, updateProductService });

        Registration__c newRegistration = new Registration__c(
            Event__c = testEvent.Id,
            Lead__c = insertLead.Id,
            Registration_Type__c = 'Business Summit - Early Bird',
            EventsAir_Regisration_ID__c = 'REG-NEW'
        );
        Registration__c updateRegistration = new Registration__c(
            Event__c = testEvent.Id,
            Lead__c = existingLead.Id,
            Registration_Type__c = 'Business Summit - Early Bird',
            EventsAir_Regisration_ID__c = 'REG-EXIST'
        );
        List<Registration__c> linkedRegs = batch.insertRegistrationIfNotExist(
            new List<Registration__c>{ newRegistration, updateRegistration },
            new Map<String, String>{ 'REG-EXIST' => Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') }
        );
        System.assertEquals(2, linkedRegs.size());

        Opportunity newOpp = new Opportunity(
            Name = 'New Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            EventsAir_Contact_Id__c = 'CON-NEW',
            AccountId = acc.Id
        );
        Opportunity updateOpp = new Opportunity(
            Name = 'Existing Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            EventsAir_Contact_Id__c = 'CON-EXIST',
            AccountId = acc.Id
        );
        List<Opportunity> allOpps = batch.insertOpportunityIfNotExist(new List<Opportunity>{ newOpp, updateOpp });
        System.assertEquals(2, allOpps.size());

        List<Object> eventContacts = new List<Object>{
            new Map<String, Object>{
                'id' => 'CON-NEW',
                'firstName' => 'New',
                'lastName' => 'Contact',
                'primaryEmail' => 'new.contact@example.com',
                'organizationName' => 'Test Account',
                'functionRegistrations' => new List<Object>{
                    buildFunctionRegistration(
                        'REG-FUN-1',
                        '1 Day Conference Pass - Thursday',
                        'FEE-1',
                        110,
                        true
                    )
                }
            }
        };

        Registration__c regForFunctionLink = new Registration__c(
            Event__c = testEvent.Id,
            Lead__c = insertLead.Id,
            Registration_Type__c = 'Business Summit - Early Bird',
            EventsAir_Regisration_ID__c = 'REG-FUN-1',
            EventsAir_Function_Id__c = 'FUN-EXIST'
        );
        insert regForFunctionLink;

        batch.eventData = new List<Event__c>{
            new Event__c(Function_Registration_Types__c = '1 Day Conference Pass - Thursday')
        };
        batch.setupForFunctionReg(
            new List<Object>{
                new Map<String, Object>{
                    'function' => new Map<String, Object>{
                        'id' => 'FUN-SETUP-1',
                        'name' => '1 Day Conference Pass - Thursday',
                        'start' => '17:00',
                        'date' => '2024-03-13',
                        'end' => '19:00',
                        'overview' => 'Overview',
                        'details' => 'Details'
                    },
                    'feeType' => new Map<String, Object>{
                        'id' => 'FEE-SETUP-1',
                        'name' => '1 Day Conference Pass - Thursday'
                    }
                }
            }
        );

        batch.createFunction(new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => 'FUN-EXPLICIT',
                'name' => 'Explicit Function',
                'start' => '08:30',
                'date' => '2024-03-14',
                'end' => '10:00',
                'overview' => 'Explicit overview',
                'details' => 'Explicit details'
            }
        });

        batch.LinkFunctionToRegistration(new List<Registration__c>{ regForFunctionLink });

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Function__c WHERE Events__c = :testEvent.Id AND EventsAir_ID__c = 'FUN-EXPLICIT']
        );
        System.assertEquals(
            existingFunction.Id,
            [SELECT Function__c FROM Registration__c WHERE Id = :regForFunctionLink.Id].Function__c
        );

        batch.createOpportunityProduct(eventContacts, allOpps);

        System.assertEquals(1, [SELECT COUNT() FROM OpportunityLineItem WHERE Function_Registration_Id__c = 'REG-FUN-1']);
        Registration__c linkedReg = [
            SELECT Opportunity__c, Opportunity_Product__c, CheckInDate__c
            FROM Registration__c
            WHERE EventsAir_Regisration_ID__c = 'REG-FUN-1'
            LIMIT 1
        ];
        System.assertNotEquals(null, linkedReg.Opportunity__c);
        System.assertNotEquals(null, linkedReg.Opportunity_Product__c);
    }

    @isTest
    static void testCreateRecordsEndToEnd() {
        Event__c testEvent = createEvent('Integrate', 'Technology', false);
        insert new Pricebook2(
            Name = testEvent.Name + ' Visitor',
            Events__c = testEvent.Id,
            IsActive = true,
            Description = 'Test pricebook'
        );
        update new Event__c(Id = testEvent.Id, Is_Pricebook_Created__c = true);

        ImportFunRegSeprateSecAndInteLiveBatch batch = new ImportFunRegSeprateSecAndInteLiveBatch();
        batch.sfeventId = testEvent.Id;
        batch.eventCategory = 'Integrate';
        batch.eventData = new List<Event__c>{ new Event__c(Function_Registration_Types__c = '') };

        List<Object> eventContacts = new List<Object>{
            new Map<String, Object>{
                'id' => 'END-CON-1',
                'firstName' => 'End',
                'lastName' => 'ToEnd',
                'primaryEmail' => 'end.toend@example.com',
                'organizationName' => null,
                'title' => 'He/Him',
                'jobTitle' => 'Engineer',
                'customFields' => new List<Object>{
                    new Map<String, Object>{
                        'name' => 'Industry INT',
                        'definitionId' => 'D1658AB1-C034-4429-8B40-D5CFD01387FB',
                        'value' => 'Consultant'
                    },
                    new Map<String, Object>{
                        'name' => 'Job Function INT',
                        'definitionId' => '5A263685-76F8-4E0A-BBEF-21AA3E28126F',
                        'value' => 'Consultant'
                    },
                    new Map<String, Object>{
                        'name' => 'Company Size',
                        'definitionId' => 'D30BE3F5-69A6-485B-BF03-BDA224BF06C8',
                        'value' => '500+'
                    }
                },
                'marketingRecords' => new List<Object>{
                    new Map<String, Object>{
                        'id' => 'MRK-END-1',
                        'name' => 'Product & Service Categories',
                        'tag' => new Map<String, Object>{
                            'id' => 'TAG-END-1',
                            'name' => 'Product & Service Categories'
                        },
                        'value' => 'Engineering & Consultancy Services'
                    }
                },
                'functionRegistrations' => new List<Object>{
                    buildFunctionRegistration('REG-END-1', '1 Day Conference Pass - Thursday', 'FEE-END-1', 110, true)
                }
            }
        };

        Test.startTest();
        batch.createRecords(eventContacts);
        Test.stopTest();
    }

    private static Event__c createEvent(String category, String portfolio, Boolean includeFunctionTypes) {
        Event__c eventRec = new Event__c(
            Name = 'Test Event ' + category,
            Registration_Types__c = 'Speaker;Security Exhibitor;Security Media;Security Stand Coordinator',
            EventsAirID__c = String.valueOf(Crypto.getRandomInteger()),
            Event_Portfolio__c = portfolio,
            Event_Category__c = category,
            Close_Date__c = System.today().addMonths(1),
            Next_Date__c = null
        );
        if (includeFunctionTypes) {
            eventRec.Function_Registration_Types__c = '1 Day Conference Pass - Thursday;1 Day Conference Pass - Thursday - Rate;';
        }
        insert eventRec;
        return eventRec;
    }

    private static void seedFunctionRegistrationData(Event__c testEvent) {
        ManageEvtAir_FunReg_SecAndInt_Live_Batch__c cfg = [
            SELECT Id, Offset__c, Is_Execute_Next__c, Generic_Email_Domains__c
            FROM ManageEvtAir_FunReg_SecAndInt_Live_Batch__c
            LIMIT 1
        ];
        cfg.Offset__c = 0;
        cfg.Is_Execute_Next__c = false;
        update cfg;

        insert new Pricebook2(
            Name = testEvent.Name + ' Visitor',
            Events__c = testEvent.Id,
            IsActive = true,
            Description = 'Test pricebook'
        );

        Account acc = new Account(Name = 'Seed Account', Domain_Name__c = 'gmail.com');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Seed',
            LastName = 'Contact',
            Email = 'seed.contact@gmail.com',
            AccountId = acc.Id
        );
        insert con;

        Lead ld = new Lead(
            FirstName = 'Seed',
            LastName = 'Lead',
            Email = 'seed.lead@gmail.com',
            Company = 'Seed Co',
            Event_Category__c = testEvent.Event_Category__c
        );
        insert ld;

        insert new Registration__c(
            Event__c = testEvent.Id,
            Lead__c = ld.Id,
            Registration_Type__c = 'Business Summit - Early Bird',
            EventsAir_Regisration_ID__c = 'SEED-REG-1'
        );
    }

    private static Map<String, Object> buildFunctionRegistration(
        String regId,
        String feeName,
        String feeId,
        Decimal amount,
        Boolean paid
    ) {
        return new Map<String, Object>{
            'id' => regId,
            'tickets' => '1',
            'checkInDate' => '2024-03-13T08:10:06.300Z',
            'checkOutDate' => null,
            'createdAt' => '2024-03-13T08:10:06.300Z',
            'feeType' => new Map<String, Object>{
                'id' => feeId,
                'name' => feeName,
                'uniqueCode' => 'UT-' + feeId,
                'fees' => new List<Object>{ new Map<String, Object>{ 'amount' => amount } }
            },
            'function' => new Map<String, Object>{
                'id' => 'FUN-' + regId,
                'name' => feeName,
                'start' => '17:00',
                'date' => '2024-03-13',
                'end' => '19:00',
                'overview' => 'Overview',
                'details' => 'Details'
            },
            'paymentDetails' => new Map<String, Object>{
                'paymentStatus' => paid ? 'PURCHASE' : 'INCLUSIVE',
                'discountAmount' => 0,
                'adjustmentAmount' => 0,
                'taxAmount' => 0,
                'totalChargeAmount' => amount,
                'discountCode' => paid ? new Map<String, Object>{ 'code' => 'A024' } : null
            }
        };
    }

    public static StaticResourceCalloutMock setStaticMock(String mockName) {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }

    private class ErrorCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        ErrorCalloutMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }
}