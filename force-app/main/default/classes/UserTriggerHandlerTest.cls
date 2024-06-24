/************************************************************************************************************
* @description  : Test Class for UserTriggerHandler
* @author       : Salesfix - CI
* @date         : 2018-10-11
*************************************************************************************************************/
@isTest
private class UserTriggerHandlerTest {
    @testSetup static void setupTestData(){
        UserRole newRole = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert newRole;
        
        User newUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = newRole.Id
        );
        insert newUser;
    }

    /************************************************************************************************************
    * @description  : Test if text is being coded to base64
    * @author       : Salesfix - CI
    * @date         : 2018-10-11
    *************************************************************************************************************/
    @isTest static void addUsernameAndPassword(){
        User insertedUser = [SELECT Id FROM User WHERE LastName = 'last' LIMIT 1];
        Test.startTest();
        insertedUser.ExpoCAD_Username__c = 'ced';
        insertedUser.ExpoCAD_Password__c = 't3$t@divcom';
        update insertedUser;
        Test.stopTest();
        
        User updatedUser = [SELECT Id, ExpoCAD_Credentials__c FROM User WHERE LastName = 'last' LIMIT 1];
        System.assert(updatedUser.ExpoCAD_Credentials__c =='Y2VkOnQzJHRAZGl2Y29t');
    }
}