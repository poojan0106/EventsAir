/* ==============================================
CreatedDate:-23 November 2023
CreatedBy:- Sakina Rampurwala
Description:- This class is call when user click "Update Marketing" button from Registration record page
=================================================*/
public class updateMarketingController {
	
  
    /* ================================================================================
	Description:-This method set Registration.Marketing Update Field with current Time.
	===================================================================================*/
    @AuraEnabled
	public static void setMarketingField(String recordId) {
        UpdateMarketingBatch batchJob = new UpdateMarketingBatch(recordId);
        Database.executeBatch(batchJob, 200);
    }

}