@isTest
public class updateMarketingControllerTest {
     public static testmethod void marketingField() {
         Id recordTypeId = Schema.SObjectType.Registration__c.getRecordTypeInfosByName().get('Registration').getRecordTypeId();

         Event__c eventRecord= new Event__c();
         eventRecord.Name='Testing Event';
         eventRecord.Event_Portfolio__c ='Technology';
         insert eventRecord;
         
         Registration__c registrationRec= new Registration__c();
         registrationRec.Event__c=eventRecord.Id;
         registrationRec.RecordTypeId=recordTypeId;
         insert registrationRec;
         
         Test.startTest();
         updateMarketingController.setMarketingField(eventRecord.Id);
         Test.stopTest();
     }

}