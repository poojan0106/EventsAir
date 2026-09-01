@isTest
public class ImportRegistartionForAllEventsBatchTest {

    @isTest
    static void testExecuteMapsOnlyStateAndCountryAddressFields() {
        Event__c testEvent = new Event__c(
            Name = 'All Events Address Test',
            EventsAirID__c = 'EA-ALL-ADDRESS-TEST',
            Event_Portfolio__c = 'Food',
            Event_Category__c = 'Naturally Good'
        );
        insert testEvent;

        Account matchedAccount = new Account(
            Name = 'Known All Events Account',
            Domain_Name__c = 'known-all.example'
        );
        insert matchedAccount;

        Manage_Eventsair_Apex_batch_All_Events__c settingRecord = new Manage_Eventsair_Apex_batch_All_Events__c(
            Name = 'All Events Batch Test',
            Offset__c = 0,
            Is_Execute_Next__c = false
        );
        insert settingRecord;

        ImportRegistartionForAllEventsBatch batchInstance =
            new ImportRegistartionForAllEventsBatch('EA-ALL-ADDRESS-TEST', testEvent.Id);

        ResponseWrapper wrapper = (ResponseWrapper) JSON.deserialize(buildResponseBody(), ResponseWrapper.class);

        Test.startTest();
        batchInstance.execute(null, new List<ResponseWrapper>{ wrapper });
        Test.stopTest();

        Contact insertedContact = [
            SELECT MailingCity, MailingCountry, MailingStreet, MailingState, MailingPostalCode
            FROM Contact
            WHERE Email = 'contact@known-all.example'
            LIMIT 1
        ];
        System.assertEquals(null, insertedContact.MailingCity, 'Contact city should not be populated from EventsAir.');
        System.assertEquals('Australia', insertedContact.MailingCountry, 'Contact country should be populated from EventsAir.');
        System.assertEquals(null, insertedContact.MailingStreet, 'Contact street should not be populated from EventsAir.');
        System.assertEquals('VIC', insertedContact.MailingState, 'Contact state should be populated from EventsAir.');
        System.assertEquals(null, insertedContact.MailingPostalCode, 'Contact postal code should not be populated from EventsAir.');

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Contact WHERE MailingCity != null OR MailingStreet != null OR MailingPostalCode != null],
            'Batch should not populate street, city, or postal code from EventsAir primaryAddress.'
        );
    }

    @isTest
    static void testExecuteHandlesEmptyContacts() {
        Event__c testEvent = new Event__c(
            Name = 'All Events Empty Test',
            EventsAirID__c = 'EA-ALL-EMPTY-TEST',
            Event_Portfolio__c = 'Food',
            Event_Category__c = 'Naturally Good'
        );
        insert testEvent;

        Manage_Eventsair_Apex_batch_All_Events__c settingRecord = new Manage_Eventsair_Apex_batch_All_Events__c(
            Name = 'All Events Empty Batch Test',
            Offset__c = 10,
            Is_Execute_Next__c = true
        );
        insert settingRecord;

        ImportRegistartionForAllEventsBatch batchInstance =
            new ImportRegistartionForAllEventsBatch('EA-ALL-EMPTY-TEST', testEvent.Id);

        ResponseWrapper wrapper = (ResponseWrapper) JSON.deserialize(buildEmptyResponseBody(), ResponseWrapper.class);

        Test.startTest();
        batchInstance.execute(null, new List<ResponseWrapper>{ wrapper });
        batchInstance.insertRegistration(new List<Registration__c>(), true);
        batchInstance.finish(null);
        Test.stopTest();

        Manage_Eventsair_Apex_batch_All_Events__c updatedSetting = [
            SELECT Offset__c, Is_Execute_Next__c
            FROM Manage_Eventsair_Apex_batch_All_Events__c
            WHERE Id = :settingRecord.Id
        ];
        System.assertEquals(0, updatedSetting.Offset__c, 'Offset should reset when no contacts are returned.');
        System.assertEquals(false, updatedSetting.Is_Execute_Next__c, 'Next execution flag should stop when no contacts are returned.');
    }

    private static String buildResponseBody() {
        return JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'event' => new Map<String, Object>{
                    'contacts' => new List<Object>{
                        buildContact('EA-CON-ALL-1', 'Known', 'Contact', 'Known Org', 'contact@known-all.example'),
                        buildContact('EA-CON-ALL-2', 'Unknown', 'Lead', 'Unknown Org', 'lead@unknown-all.example')
                    }
                }
            }
        });
    }

    private static String buildEmptyResponseBody() {
        return JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'event' => new Map<String, Object>{
                    'contacts' => new List<Object>()
                }
            }
        });
    }

    private static Map<String, Object> buildContact(
        String contactId,
        String firstName,
        String lastName,
        String organizationName,
        String email
    ) {
        return new Map<String, Object>{
            'id' => contactId,
            'firstName' => firstName,
            'lastName' => lastName,
            'organizationName' => organizationName,
            'primaryEmail' => email,
            'primaryAddress' => new Map<String, Object>{
                'city' => 'Melbourne',
                'country' => 'Australia',
                'line1' => '1 Test Street',
                'line2' => 'Suite 2',
                'line3' => 'Level 3',
                'postCode' => '3000',
                'state' => 'VIC'
            },
            'contactPhoneNumbers' => new Map<String, Object>{
                'mobile' => '0411111111'
            },
            'registrations' => new List<Object>{
                new Map<String, Object>{
                    'id' => 'REG-' + contactId,
                    'registrationDateTime' => '2026-06-18T12:00:00',
                    'type' => new Map<String, Object>{
                        'id' => 'TYPE-' + contactId,
                        'name' => 'Visitor',
                        'uniqueCode' => 'VIS',
                        'fees' => new List<Object>{
                            new Map<String, Object>{ 'amount' => 0 }
                        }
                    }
                }
            }
        };
    }
}