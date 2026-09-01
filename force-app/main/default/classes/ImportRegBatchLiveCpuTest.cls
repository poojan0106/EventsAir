@IsTest
private class ImportRegBatchLiveCpuTest {
    @IsTest
    static void genericDomainDoesNotMatchWrongAccountByDomain() {
        Event__c eventRecord = createEvent();
        createBatchSetting('gmail.com, hotmail.com, outlook.com');
        activateStandardPricebook();
        createEventPricebook(eventRecord.Id);

        Account wrongGenericDomainAccount = new Account(
            Name = 'Wrong Gmail Account',
            Domain_Name__c = 'gmail.com',
            Phone = '0299999999',
            MobilePhone__c = '0299999999'
        );
        insert wrongGenericDomainAccount;

        ImportRegistartionBatchForLiveEvent batch = new ImportRegistartionBatchForLiveEvent();
        Test.startTest();
        batch.createRecords(new List<Object>{
            eventContact(
                'EA-CON-CPU-001',
                'Cpu',
                'Fix',
                'cpu.fix.gmail@example-replaced.invalid'.replace('example-replaced.invalid', 'gmail.com'),
                'Cpu Fix Test Org',
                '0291111111',
                Decimal.valueOf('100'),
                'EA-REG-CPU-001',
                'EA-TYPE-CPU-001'
            )
        });
        Test.stopTest();

        Contact importedContact = [
            SELECT Id, AccountId, Account.Name, Account.Domain_Name__c, Account.Phone, Account.MobilePhone__c
            FROM Contact
            WHERE Email = 'cpu.fix.gmail@gmail.com'
            LIMIT 1
        ];

        System.assertNotEquals(
            wrongGenericDomainAccount.Id,
            importedContact.AccountId,
            'Generic email domains must not map contacts to an unrelated Account by Domain_Name__c.'
        );
        System.assertEquals('Cpu Fix Test Org', importedContact.Account.Name);
        System.assertEquals('gmail.com', importedContact.Account.Domain_Name__c);
        System.assertEquals('0291111111', importedContact.Account.Phone);
        System.assertEquals('0291111111', importedContact.Account.MobilePhone__c);

        Registration__c importedRegistration = [
            SELECT Id, Contact__c, EventsAir_Regisration_ID__c, Event__c
            FROM Registration__c
            WHERE EventsAir_Regisration_ID__c = 'EA-REG-CPU-001'
            LIMIT 1
        ];
        System.assertEquals(importedContact.Id, importedRegistration.Contact__c);
        System.assertEquals(eventRecord.Id, importedRegistration.Event__c);
    }

    @IsTest
    static void nonGenericDomainStillMatchesByDomain() {
        Event__c eventRecord = createEvent();
        createBatchSetting('gmail.com, hotmail.com, outlook.com');
        activateStandardPricebook();
        createEventPricebook(eventRecord.Id);

        Account domainAccount = new Account(
            Name = 'Domain Match Account',
            Domain_Name__c = 'realcompany.example',
            Phone = '0288888888',
            MobilePhone__c = '0288888888'
        );
        insert domainAccount;

        ImportRegistartionBatchForLiveEvent batch = new ImportRegistartionBatchForLiveEvent();
        Test.startTest();
        batch.createRecords(new List<Object>{
            eventContact(
                'EA-CON-CPU-002',
                'Domain',
                'Match',
                'domain.match@realcompany.example',
                'Different Org Name',
                '0287777777',
                Decimal.valueOf('100'),
                'EA-REG-CPU-002',
                'EA-TYPE-CPU-002'
            )
        });
        Test.stopTest();

        Contact importedContact = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Email = 'domain.match@realcompany.example'
            LIMIT 1
        ];
        System.assertEquals(
            domainAccount.Id,
            importedContact.AccountId,
            'Non-generic email domains should continue to use the existing domain-based Account match.'
        );
    }

    @IsTest
    static void duplicateHelperMethodsSkipExistingCombinedString() {
        Map<String, Boolean> existingContactKeys = new Map<String, Boolean>{
            'existingcontactpersonexisting.contact@example.com' => true
        };

        ImportRegistartionBatchForLiveEvent.insertContactsIfNotExist(new List<Contact>{
            new Contact(FirstName = 'Existing', LastName = 'ContactPerson', Email = 'existing.contact@example.com'),
            new Contact(FirstName = 'New', LastName = 'ContactPerson', Email = 'new.contact@example.com'),
            new Contact(FirstName = 'New', LastName = 'ContactPerson', Email = 'new.contact@example.com')
        }, existingContactKeys);

        System.assertEquals(1, [
            SELECT COUNT()
            FROM Contact
            WHERE Email = 'new.contact@example.com'
        ]);

        Map<String, Boolean> existingLeadKeys = new Map<String, Boolean>{
            'existingleadpersonexisting.lead@example.com' => true
        };

        ImportRegistartionBatchForLiveEvent.insertLeadsIfNotExist(new List<Lead>{
            new Lead(FirstName = 'Existing', LastName = 'LeadPerson', Email = 'existing.lead@example.com', Company = 'Existing Co', Status = 'New'),
            new Lead(FirstName = 'New', LastName = 'LeadPerson', Email = 'new.lead@example.com', Company = 'New Co', Status = 'New'),
            new Lead(FirstName = 'New', LastName = 'LeadPerson', Email = 'new.lead@example.com', Company = 'New Co', Status = 'New')
        }, existingLeadKeys);

        System.assertEquals(1, [
            SELECT COUNT()
            FROM Lead
            WHERE Email = 'new.lead@example.com'
        ]);
    }

    @IsTest
    static void executeBatchWithEventsAirMockCoversStartAndExecute() {
        Test.setMock(HttpCalloutMock.class, setStaticMock('importregistrationMock'));

        Event__c eventRecord = createEvent();
        createBatchSetting('gmail.com, hotmail.com, outlook.com');
        activateStandardPricebook();
        createEventPricebook(eventRecord.Id);

        Account accountRecord = new Account(
            Name = 'Existing Mock Account',
            Domain_Name__c = 'gmail.com',
            Phone = '0277777777',
            MobilePhone__c = '0277777777'
        );
        insert accountRecord;

        Contact contactRecord = new Contact(
            FirstName = 'Fname',
            LastName = 'Lname',
            Email = 'vandana@gmail.com',
            AccountId = accountRecord.Id
        );
        insert contactRecord;

        Lead leadRecord = new Lead(
            FirstName = 'Fname',
            LastName = 'Lname',
            Email = 'vandana@gmail.com',
            Company = 'Unknown',
            Phone = '0266666666',
            MobilePhone = '0266666666',
            Status = 'New'
        );
        insert leadRecord;

        Test.startTest();
        Database.executeBatch(new ImportRegistartionBatchForLiveEvent(), 250);
        Test.stopTest();

        System.assertEquals(1, [
            SELECT COUNT()
            FROM Event__c
            WHERE Id = :eventRecord.Id
        ]);
    }

    private static Event__c createEvent() {
        Event__c eventRecord = new Event__c(
            Name = 'CPU Fix Test Event',
            EventsAirID__c = 'EA-EVENT-CPU-FIX',
            Event_Portfolio__c = 'Food',
            Close_Date__c = Date.today().addMonths(1),
            Next_Date__c = null
        );
        insert eventRecord;
        return eventRecord;
    }

    private static void createBatchSetting(String genericDomains) {
        Manage_Eventsair_Reg_batch_Live_Event__c settingRecord = new Manage_Eventsair_Reg_batch_Live_Event__c(
            Name = 'CPU Fix Test Setting',
            Offset__c = 0,
            Is_Execute_Next__c = true,
            Generic_Email_Domains__c = genericDomains
        );
        insert settingRecord;
    }

    private static void activateStandardPricebook() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
    }

    private static Pricebook2 createEventPricebook(Id eventId) {
        Pricebook2 eventPricebook = new Pricebook2(
            Name = 'CPU Fix Event Pricebook',
            IsActive = true,
            Events__c = eventId
        );
        insert eventPricebook;
        return eventPricebook;
    }

    private static StaticResourceCalloutMock setStaticMock(String mockName) {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }

    private static Map<String, Object> eventContact(
        String contactId,
        String firstName,
        String lastName,
        String email,
        String organizationName,
        String workPhone,
        Decimal totalChargeAmount,
        String registrationId,
        String registrationTypeId
    ) {
        return new Map<String, Object>{
            'id' => contactId,
            'firstName' => firstName,
            'lastName' => lastName,
            'title' => 'Manager',
            'organizationName' => organizationName,
            'primaryEmail' => email,
            'workPhone' => workPhone,
            'checkInDate' => '2026-04-15T05:45:03.000Z',
            'checkOutDate' => '2026-04-15T06:45:03.000Z',
            'primaryAddress' => new Map<String, Object>{
                'city' => 'Sydney',
                'country' => 'Australia',
                'line1' => '1 Test Street',
                'line2' => null,
                'line3' => null,
                'postCode' => '2000',
                'state' => 'NSW'
            },
            'contactPhoneNumbers' => new List<Object>{
                new Map<String, Object>{ 'mobile' => workPhone }
            },
            'customFields' => new List<Object>{
                new Map<String, Object>{ 'name' => 'Industry', 'value' => 'Food' },
                new Map<String, Object>{ 'name' => 'Company Size', 'value' => '1 - 9' },
                new Map<String, Object>{ 'name' => 'Job Function', 'value' => 'Management' }
            },
            'marketingRecords' => new List<Object>{
                new Map<String, Object>{
                    'id' => 'EA-MKT-' + registrationId,
                    'name' => 'Visitor Type',
                    'value' => 'Visitor'
                }
            },
            'registrations' => new List<Object>{
                new Map<String, Object>{
                    'id' => registrationId,
                    'registrationDateTime' => '2026-04-15T05:45:03.000Z',
                    'type' => new Map<String, Object>{
                        'id' => registrationTypeId,
                        'name' => 'Visitor',
                        'uniqueCode' => registrationTypeId,
                        'fees' => new List<Object>{
                            new Map<String, Object>{ 'amount' => totalChargeAmount }
                        }
                    },
                    'paymentDetails' => new Map<String, Object>{
                        'paymentStatus' => 'PAID',
                        'discountAmount' => Decimal.valueOf('0'),
                        'adjustmentAmount' => Decimal.valueOf('0'),
                        'taxAmount' => Decimal.valueOf('0'),
                        'totalChargeAmount' => totalChargeAmount,
                        'discountCode' => new Map<String, Object>{ 'code' => 'TEST' }
                    }
                }
            }
        };
    }
}