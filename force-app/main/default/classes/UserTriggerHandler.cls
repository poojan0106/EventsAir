/************************************************************************************************************
* @description  : Handler for User Trigger
* @author       : Salesfix - CI
* @date         : 2018-10-11
*************************************************************************************************************/
public class UserTriggerHandler{

    /************************************************************************************************************
    * @description  : Process before update events
    * @author       : Salesfix - CI
    * @date         : 2018-10-11
    * @param        : newUsers - trigger.new
    * @param        : newUsersMap - trigger.newMap
    * @param        : oldUsersMap - trigger.oldMap
    *************************************************************************************************************/
    public void onBeforeUpdate(List<User> newUsers, Map<Id, User> newUsersMap, Map<Id, User> oldUsersMap){
        updateExpocadCredentials(newUsers, newUsersMap, oldUsersMap);
    }

    /************************************************************************************************************
    * @description  : Update Expocad Credentials based on the Expocad Username and Password Entered
    * @author       : Salesfix - CI
    * @date         : 2018-10-11
    * @param        : newUsers - trigger.new
    * @param        : newUsersMap - trigger.newMap
    * @param        : oldUsersMap - trigger.oldMap
    *************************************************************************************************************/
    public void updateExpocadCredentials(List<User> newUsers, Map<Id, User> newUsersMap, Map<Id, User> oldUsersMap){
        for(User userItem: newUsers){
            if((newUsersMap.get(userItem.Id).ExpoCAD_Username__c != oldUsersMap.get(userItem.Id).ExpoCAD_Username__c ||
                    newUsersMap.get(userItem.Id).ExpoCAD_Password__c != oldUsersMap.get(userItem.Id).ExpoCAD_Password__c) &&
                    newUsersMap.get(userItem.Id).ExpoCAD_Username__c != null && newUsersMap.get(userItem.Id).ExpoCAD_Password__c != null){
                String userPassword = userItem.ExpoCAD_Username__c + ':' + userItem.ExpoCAD_Password__c;
                String userPasswordBase64 = EncodingUtil.base64Encode(Blob.valueOf(userPassword));
                userItem.ExpoCAD_Credentials__c = userPasswordBase64;
            }
        }
    }

}