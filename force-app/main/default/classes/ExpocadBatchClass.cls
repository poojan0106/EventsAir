public class ExpocadBatchClass implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{

    List<Id> recordIds;
    public static Map<Id, Stand__c> standsMap = new Map<Id, Stand__c>();
    public static List<Capture_Exception__c> captureException = new List<Capture_Exception__c>();


    public ExpocadBatchClass(List<Id> ids) {
        this.recordIds = ids;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Is_On_Hold__c, Is_Rented__c, Currently_Holding_Opportunity__r.Space_Type__c ,Currently_Holding_Opportunity__r.AccountId , Account_ID__c, Trading_As__c, Account_Name__c, Event_Expocad_Id__c, Event__c, Name FROM Stand__c WHERE Id IN :recordIds]);
     }
  
     public void execute(Database.BatchableContext BC, List<Stand__c> standList){

        for (Stand__c stand : standList) {
            // Process each Stand
            SFStandExpocadBoothSync(stand);
        }
        update standsMap.values();
        if(!captureException.isEmpty()){
            insert captureException;
        }
       
      }
  
    public void finish(Database.BatchableContext BC){}

    public static void SFStandExpocadBoothSync(Stand__c stand){
        try{
            ExpocadWrapper expocadWrapper=ExpocadIntegration.getBoothByEventAndName(stand.Event_Expocad_Id__c , stand.Name);

            String exhibitorId=stand.Account_ID__c !=null?stand.Account_ID__c:'';

            if (!expocadWrapper.success) {
                handleIntegrationException(expocadWrapper.message);
                return;
            }
            // Now take Hold or Rent Decision...
            ExpocadWrapper.BoothInfo expocadBooth=  (ExpocadWrapper.BoothInfo) JSON.deserialize(expocadWrapper.message,  ExpocadWrapper.BoothInfo.class);
            if( 
                ((expocadBooth.IsOnHold != stand.Is_On_Hold__c && stand.Is_On_Hold__c) || (expocadBooth.ExhibitorId != stand.Account_ID__c &&  expocadBooth.IsOnHold == stand.Is_On_Hold__c && stand.Is_On_Hold__c)) || 
                ((expocadBooth.IsOnHold != stand.Is_On_Hold__c && !stand.Is_On_Hold__c) && (expocadBooth.IsRented == stand.Is_Rented__c && !stand.Is_Rented__c)) || 
                ((expocadBooth.IsOnHold != stand.Is_On_Hold__c && !stand.Is_On_Hold__c) && (!expocadBooth.IsRented && stand.Is_Rented__c))){
                
                        // Hold Unhold stand...
                        System.debug('hold Unhold'+stand.Name);
                        holdUnHoldStand(stand, expocadWrapper.message);
            }else if(
                    ((expocadBooth.IsRented != stand.Is_Rented__c  && stand.Is_Rented__c)|| (expocadBooth.ExhibitorId!= stand.Account_ID__c && expocadBooth.IsRented == stand.Is_Rented__c && stand.Is_Rented__c))
                    || ((expocadBooth.IsRented != stand.Is_Rented__c && !stand.Is_Rented__c) && (expocadBooth.IsOnHold == stand.Is_On_Hold__c && !stand.Is_On_Hold__c))
                    ){
                        // Rent or Unrent
                        System.debug('rent Unrent'+stand.Name);
                        RentUnRentStand(stand, expocadWrapper.message);
            }else{
                updateStand(stand, 'Success', '');
            }
            
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }
    }
    // Description:- Add Exhibitor in Expocad.
    public static void addExhibitor(String boothJson, Stand__c stand){
        try{
            ExpocadWrapper expoWrapGetBooth=ExpocadIntegration.getBoothByEventAndName(stand.Event_Expocad_Id__c	 , stand.Name);
            Map<String, Object> requestBodyMap = new Map<String, Object>();
            requestBodyMap.put('DisplayOnDrawing', stand.Trading_As__c);
            requestBodyMap.put('ExhibitorName', stand.Account_Name__c);
            requestBodyMap.put('ExhibitorId', stand.Account_ID__c);
            String requestBody = JSON.serialize(requestBodyMap);
            ExpocadWrapper Expocad_newExhibitor= ExpocadIntegration.addNewExhibitor(stand.Event_Expocad_Id__c , requestBody);
            if(!Expocad_newExhibitor.success){
                    // Failure Integartion error...
                    handleIntegrationException(Expocad_newExhibitor.message);
                    System.debug('Integration Exception:::'+Expocad_newExhibitor.message);
                    return;

            }
            if(expoWrapGetBooth.success){
                ExpocadWrapper.BoothInfo expocadBooth=  (ExpocadWrapper.BoothInfo) JSON.deserialize(expoWrapGetBooth.message,  ExpocadWrapper.BoothInfo.class);
                // Check Exhibitor add Response..
                    ExpocadWrapper.Exhibitor exhibitorDetails=  (ExpocadWrapper.Exhibitor) JSON.deserialize(Expocad_newExhibitor.message,  ExpocadWrapper.Exhibitor.class);
                if(exhibitorDetails.ExhibitorId == stand.Account_ID__c && stand.Is_On_Hold__c && !expocadBooth.IsOnHold){
                    // Hold stand in Expocad
                    holdStandInExpocad(stand, boothJson);

                }else if(exhibitorDetails.ExhibitorId == stand.Account_ID__c && stand.Is_Rented__c && !expocadBooth.IsRented){
                    // Rent Stand in Expocad..
                    rentStand(stand,boothJson);
                }else if(exhibitorDetails.ExhibitorId == stand.Account_ID__c && stand.Is_Rented__c && expocadBooth.IsRented && !stand.Is_On_Hold__c && !expocadBooth.IsOnHold){
                    ExpocadWrapper expo= ExpocadIntegration.setBoothToUnrent(stand.Event_Expocad_Id__c ,stand.Name,stand.Account_ID__c);
                    if (!expo.success) {
                        // Failure in setting booth to unrent
                        updateStand(stand, 'Failure', expo.message);
                        handleIntegrationException(expo.message);
                        System.debug('Exception Integration: ' + expo.message);
                        return;
                    }
                    // Rent the stand again
                    rentStand(stand, boothJson);
                }else if(exhibitorDetails.ExhibitorId == stand.Account_ID__c && !stand.Is_Rented__c && !expocadBooth.IsRented && stand.Is_On_Hold__c && expocadBooth.IsOnHold){
                    // Success update stand.
                    ExpocadWrapper expocadWrapper= ExpocadIntegration.setBoothToUnhold(stand.Event_Expocad_Id__c , stand.Name);
                    if (!expocadWrapper.success) {
                        // Failure in setting booth to unhold
                        updateStand(stand, 'Failure', expocadWrapper.message);
                        handleIntegrationException(expocadWrapper.message);
                        System.debug('Exception Integration: ' + expocadWrapper.message);
                        return;
                    }
                    holdStandInExpocad(stand, boothJson);        
                }                   
                
            }
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }
    }
    // Description:- Check Exhbitor in Expocad.
    public static void checkExhibitor(Stand__c stand, String boothJson){
        try{
            ExpocadWrapper.BoothInfo expocadBooth=  (ExpocadWrapper.BoothInfo) JSON.deserialize(boothJson,  ExpocadWrapper.BoothInfo.class);
            // Check Exhibitor
            ExpocadWrapper exhibitor= ExpocadIntegration.getExhibitorById(stand.Event_Expocad_Id__c, stand.Account_ID__c);
            if(exhibitor.success){
                ExpocadWrapper.Exhibitor exhibitorDetails=  (ExpocadWrapper.Exhibitor) JSON.deserialize(exhibitor.message,  ExpocadWrapper.Exhibitor.class);
                if(exhibitorDetails.ExhibitorId== stand.Account_ID__c && stand.Is_On_Hold__c && !expocadBooth.IsOnHold){
                        // Hold Stand in Expocad
                        holdStandInExpocad(stand, boothJson);
                }else if(exhibitorDetails.ExhibitorId != stand.Account_ID__c && stand.Is_On_Hold__c && !expocadBooth.IsOnHold){
                        // Add Exhibitor in expocad
                        addExhibitor(boothJson, stand);
                }else if(exhibitorDetails.ExhibitorId== stand.Account_ID__c && stand.Is_Rented__c && !expocadBooth.IsRented){
                        // Rent stand in expocad
                        rentStand(stand, boothJson);
                }else if(exhibitorDetails.ExhibitorId != stand.Account_ID__c && stand.Is_Rented__c && !expocadBooth.IsRented){
                        // Add Exhibitor in Expocad
                        addExhibitor(boothJson, stand);
                }else if(exhibitorDetails.ExhibitorId == stand.Account_ID__c && stand.Is_Rented__c && expocadBooth.IsRented && !stand.Is_On_Hold__c && !expocadBooth.IsOnHold){
                        // Salesforce update stand
                        ExpocadWrapper expo= ExpocadIntegration.setBoothToUnrent(stand.Event_Expocad_Id__c ,stand.Name,stand.Account_ID__c);
                        if (!expo.success) {
                            // Failure in setting booth to unrent
                            updateStand(stand, 'Failure', expo.message);
                            handleIntegrationException(expo.message);
                            System.debug('Exception Integration: ' + expo.message);
                            return;
                        }
                        // Rent the stand again
                        rentStand(stand, boothJson);
            
                }else if(exhibitorDetails.ExhibitorId == stand.Account_ID__c && !stand.Is_Rented__c && !expocadBooth.IsRented && stand.Is_On_Hold__c && expocadBooth.IsOnHold){
                        // Success update stand.
                        ExpocadWrapper expocadWrapper= ExpocadIntegration.setBoothToUnhold(stand.Event_Expocad_Id__c , stand.Name);
                        if (!expocadWrapper.success) {
                            // Failure in setting booth to unhold
                            updateStand(stand, 'Failure', expocadWrapper.message);
                            handleIntegrationException(expocadWrapper.message);
                            System.debug('Exception Integration: ' + expocadWrapper.message);
                            return;
                        }
                        holdStandInExpocad(stand, boothJson);     
                }
            }else{
                // add exhibiotor in expocad
                addExhibitor(boothJson, stand);
            }
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }
    }
    //Description:- Hold or Unhold
    public static void holdUnHoldStand(Stand__c stand , String boothJson){
        try{
            if (stand.Is_On_Hold__c) {
                checkExhibitor(stand, boothJson);
            } else {
                unHoldStand(boothJson, stand);
            }
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }
    }
    // Description:- Hold Stand in Expocad..
    public static void holdStandInExpocad(Stand__c stand , String boothJson){
        try{
            string exhibitorId= stand.Account_ID__c != null?stand.Account_ID__c:'';

            ExpocadWrapper expoWrap=ExpocadIntegration.setBoothHold(stand.Event_Expocad_Id__c, stand.Name, exhibitorId);

            ExpocadWrapper expoWrapGetBooth=ExpocadIntegration.getBoothByEventAndName(stand.Event_Expocad_Id__c	 , stand.Name);
            if(!expoWrap.success){
                // Failure Update Stand..
                updateStand(stand, 'Failure' , expoWrap.message);  
                handleIntegrationException(expoWrap.message);  
                return; 
            }

            if(expoWrapGetBooth.success){
                ExpocadWrapper.BoothInfo expocadBooth=  (ExpocadWrapper.BoothInfo) JSON.deserialize(expoWrapGetBooth.message,  ExpocadWrapper.BoothInfo.class);
                if(expocadBooth.IsOnHold){
                    if(!stand.Is_Rented__c && expocadBooth.IsRented){
                        // Rent or Unrent
                        RentUnRentStand(stand, expoWrapGetBooth.message);
                    }else if(!stand.Is_Rented__c && !expocadBooth.IsRented && !expocadBooth.BoothClasses.contains('Standard Booth') && !expocadBooth.BoothClasses.contains('Pavilion Booth')){
                        //Callout Expocad Class Remove Put operation
                        removeExpocadClass(stand, expoWrapGetBooth.message);
                    }else{
                        // Success Update stand
                        updateStand(stand, 'Success' , '');  
                    }
                }
            }
            
            // 15th Dec Changes
            updateStand(stand, 'Success' , ''); 
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        } 
    }
    // Description:-UnHold stand in Expocad...
    public static void unHoldStand(String boothJson, Stand__c stand){
        try{
            ExpocadWrapper expocadWrapper= ExpocadIntegration.setBoothToUnhold(stand.Event_Expocad_Id__c , stand.Name);

            ExpocadWrapper expoWrap=ExpocadIntegration.getBoothByEventAndName(stand.Event_Expocad_Id__c	 , stand.Name);

            if(!expocadWrapper.success){
                // Failure update stand
                updateStand(stand, 'Failure' , expocadWrapper.message);  
                handleIntegrationException(expocadWrapper.message);
                return;
            }
            if(expoWrap.success){
                ExpocadWrapper.BoothInfo expocadBooth=  (ExpocadWrapper.BoothInfo) JSON.deserialize(expoWrap.message,  ExpocadWrapper.BoothInfo.class);
                if(!expocadBooth.IsOnHold){
                    if(stand.Is_Rented__c && !expocadBooth.IsRented){
                        // Rent or Unrent
                        RentUnRentStand(stand,expoWrap.message);

                    }else if(!stand.Is_Rented__c && expocadBooth.IsRented){
                        // Rent or Unrent
                        RentUnRentStand(stand, expoWrap.message);
                    }else if(stand.Is_Rented__c && expocadBooth.IsRented && !expocadBooth.BoothClasses.contains(stand.Currently_Holding_Opportunity__r.Space_Type__c) && stand.Currently_Holding_Opportunity__r.Space_Type__c != null){
                        // Callout EXPOCAD Class Request Put Operation
                        addBoothClass(stand);
                    }else{
                        // Sucess update stand 
                        updateStand(stand, 'Success' , '');  
                    
                    }
                }

            }
            // 15th Dec Changes
            updateStand(stand, 'Success' , '');  
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }
    }
    // Description:- Rent or Unrent Stand...
    public static void RentUnRentStand(Stand__c stand , String boothJson){
        try{
            String exhibitorId=stand.Account_ID__c != null ? stand.Account_ID__c : '';

            ExpocadWrapper.BoothInfo expocadBooth=  (ExpocadWrapper.BoothInfo) JSON.deserialize(boothJson,  ExpocadWrapper.BoothInfo.class);
            if(stand.Is_Rented__c){
                // Check Exhbibtor
                checkExhibitor(stand, boothJson);
            }else{
                // Unrent Stand in Expocad
                unRentStand(stand, boothJson);
            }
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }
        
    }
    // Description:- Unrent Stand in Expocad..
    public static void unRentStand(Stand__c stand ,String boothJson){
        try{
            String exhibitorId=stand.Account_ID__c != null ? stand.Account_ID__c : '';

            ExpocadWrapper expo= ExpocadIntegration.setBoothToUnrent(stand.Event_Expocad_Id__c ,stand.Name,exhibitorId);
            ExpocadWrapper expoWrap=ExpocadIntegration.getBoothByEventAndName(stand.Event_Expocad_Id__c	 , stand.Name);

            if(!expo.success){
                updateStand(stand, 'Failure' , expo.message);  
                handleIntegrationException(expo.message);  
                return;
            }
            if(expoWrap.success){
                ExpocadWrapper.BoothInfo expocadBooth=  (ExpocadWrapper.BoothInfo) JSON.deserialize(expoWrap.message,  ExpocadWrapper.BoothInfo.class);
                if(!expocadBooth.IsRented){
                    if(stand.Is_On_Hold__c && !expocadBooth.IsOnHold){
                        // Hold Or Unhold
                        holdUnHoldStand(stand, expoWrap.message);
                    }else if(!stand.Is_On_Hold__c && expocadBooth.IsOnHold){
                        // Hold or Unhold
                        holdUnHoldStand(stand, expoWrap.message);
                    }else if(!expocadBooth.BoothClasses.contains('Standard Booth') && !expocadBooth.BoothClasses.contains('Pavilion Booth')){
                        // Call out Expocad Class remove put operation
                        removeExpocadClass(stand, expoWrap.message);
                    }else{
                        // Salesforce Sucesss update Stand
                        updateStand(stand, 'Success' , '');  
                    
                    }
                }

                updateStand(stand, 'Success' , '');  

            }
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }
        
    }
    //Description:- Rent Stand in Expocad
    public static void rentStand(Stand__c stand , String boothJson){
        try{
            String exhibitorId=stand.Account_ID__c != null ? stand.Account_ID__c : '';
            // ExpocadWrapper.BoothInfo expocadBooth=  (ExpocadWrapper.BoothInfo) JSON.deserialize(boothJson,  ExpocadWrapper.BoothInfo.class);
            ExpocadWrapper expoRentCallout= ExpocadIntegration.setBoothToRent(stand.Event_Expocad_Id__c , stand.Name ,exhibitorId);
            ExpocadWrapper expoWrapGetBooth=ExpocadIntegration.getBoothByEventAndName(stand.Event_Expocad_Id__c	 , stand.Name);
            if(!expoRentCallout.success){
                // Failure update Stand.
                updateStand(stand, 'Failure' , expoRentCallout.message);  
                handleIntegrationException(expoRentCallout.message);  
                System.debug('Exception Integration::'+expoRentCallout.message); 
                return;     
            }
            if(expoWrapGetBooth.success){
                ExpocadWrapper.BoothInfo expocadBooth=  (ExpocadWrapper.BoothInfo) JSON.deserialize(expoWrapGetBooth.message,  ExpocadWrapper.BoothInfo.class);
                if(expocadBooth.IsRented){
                    if(!stand.Is_On_Hold__c && expocadBooth.IsOnHold){
                        // Hold or Unhold..
                        holdUnHoldStand(stand, expoWrapGetBooth.message);
                    }
                    else if(!expocadBooth.BoothClasses.contains(stand.Currently_Holding_Opportunity__r.Space_Type__c) && stand.Currently_Holding_Opportunity__r.Space_Type__c != null){
                        // $EXPOCAD_Current_Stand_Class != $classToUpdate && $classToUpdate != "N/A" ),
                        //  RunOperation("<TAG>Operations/Callout EXPOCAD Class Request Put Operation</TAG>"),
                        addBoothClass(stand);
                    }
                    else{
                        // Sucess update stand..
                        updateStand(stand, 'Success' , '');  
                    }
                }
                updateStand(stand, 'Success' , '');  

            }
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }     
        
    }
    // Description:- callout expocad class remove put Operation
    public static void removeExpocadClass(Stand__c stand  , String boothJson){      
        try{  
            Boolean isSuccess=false;
            String errorMessage='';
            ExpocadWrapper.BoothInfo expocadBooth=  (ExpocadWrapper.BoothInfo) JSON.deserialize(boothJson,  ExpocadWrapper.BoothInfo.class);
            for(String boothClassId:expocadBooth.BoothClasses){
                ExpocadWrapper removeBoothClass= ExpocadIntegration.removeBoothClass(stand.Event_Expocad_Id__c,stand.Name,boothClassId);
                // Check the response and handle success or failure
                if (removeBoothClass.success) {
                    isSuccess=true;
                } else {
                    isSuccess=false;
                    errorMessage=removeBoothClass.message;
                }
            }
            if(isSuccess){
                // success update stand
                updateStand(stand, 'Success' , '');  

            }
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }
    }
    // Description:- callout expocad class add put Operation
    public static void addBoothClass(Stand__c stand){    
        try{    
            ExpocadWrapper addBoothWrapper= ExpocadIntegration.setBoothClass(stand.Event_Expocad_Id__c, stand.Name, stand.Currently_Holding_Opportunity__r.Space_Type__c);
            if(!addBoothWrapper.success){
                // Failure update Stand.
                updateStand(stand, 'Failure' , addBoothWrapper.message);  
                handleIntegrationException(addBoothWrapper.message);  
                System.debug('Exception Integration::'+addBoothWrapper.message);
                return;    
            }

            if(addBoothWrapper.success){
                // success update stand
                updateStand(stand, 'Success' , '');  
            }
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }

    }

    // Description:- Handle Exception..
    private static void handleException(Exception exp) {
        Capture_Exception__c excep = new Capture_Exception__c();
        excep.Error_Message__c = 'LineNumber' + exp.getLineNumber() + 'Message:::' + exp.getMessage();
        excep.Name = exp.getTypeName();
        captureException.add(excep);
    }
    // Description:- Handle Integration Error...
    private static void handleIntegrationException(String errorMessage) {
        Capture_Exception__c excep = new Capture_Exception__c();
        excep.Error_Message__c = errorMessage;
        excep.Name = 'Integration Error';
        captureException.add(excep);
    }
    // Helper method to update stand fields when sync is successful
    private static void updateStand(Stand__c stand , String status, String errorDetails) {
        stand.Status_Last_Synced_with_ExpoCAD__c = System.now();
        stand.Status_Synced_with_ExpoCAD__c = status;
        stand.ExpoCAD_Error_Details__c = errorDetails;
        ExpocadIntegrationLogic.updateFromExpocad = true;
        standsMap.put(stand.Id, stand);
    }
}