/* ==============================================
CreatedDate:-27th October 2023
CreatedBy:- Sakina Rampurwala
Description:- Logic of all calloouts are mentioned in this class
=================================================*/
public  class ExpocadIntegrationLogic {
   
    public static Boolean updateFromExpocad=false;
    private static Event__c fetchEvent(String eventId) {
        return [SELECT Id,ExpoCAD_ID__c,Details_Synced_with_ExpoCAD__c, Last_Synced_with_ExpoCAD__c, Name FROM Event__c WHERE Id=:eventId LIMIT 1];
    }

    private static Co_Exhibitor__c fetchCoExhibitors(String coExhibitorId) {
        return [SELECT Id, Name , Stand__c , Exhibitor_Sync_with_ExpoCAD__c, Details_Synced_with_ExpoCAD__c, Stand__r.Name, Event__c , Event__r.Name ,Event__r.ExpoCAD_ID__c ,  Account__c	, Account__r.Name From Co_Exhibitor__c WHERE Id=:coExhibitorId LIMIT 1];
    }
    // ================== PROJECT-1 ========================
    // Description: Get pavilions name from expocad and upsert it in salesforce.
    @future (callout=true)
    public static void pavilionExpocadCallout(String eventId){
        Event__c eventRecord = fetchEvent(eventId);
        String eventExpocadId=eventRecord.ExpoCAD_ID__c.toLowerCase();
        try{
            ExpocadWrapper expoWrap= ExpocadIntegration.getPavilionsByEvent(eventExpocadId);
            if(expoWrap.success){
                List<String> pavilionNamesList= new List<String>();
                for (ExpocadWrapper.PavilionNames pavilion : (List<ExpocadWrapper.PavilionNames>) JSON.deserialize(expoWrap.message, List<ExpocadWrapper.PavilionNames>.class)) {
                    pavilionNamesList.add(pavilion.Name);
                }
                addStandRecords(eventRecord  , pavilionNamesList);
            }else{
                updateEventWithError(eventRecord, expoWrap.message);
                System.debug('Integration Error');
                handleIntegrationException(expoWrap.message);
            }
        }catch(Exception exp){
            updateEventWithError(eventRecord, 'Exception:' + exp.getMessage() + exp.getLineNumber());
            System.debug('pavilionExpocad Exception:' + exp.getMessage() + exp.getLineNumber());
            handleException(exp);
        }
    }
    // Description:Get booths from expocad and display it in salesforce.
    public static void addStandRecords(Event__c eventRecord, List<String> pavilionNamesList){
        String eventExpocadId=eventRecord.ExpoCAD_ID__c.toLowerCase();
        ExpocadWrapper expoWrap= ExpocadIntegration.getBoothByEvent(eventExpocadId);
        try{
            // collection to store the records...
            List<Stand__c> standList= new List<Stand__c>();
            Map<String, Pavilion__c> pavilionMap= new Map<String, Pavilion__c>();
            Map<String, Stand__c> standMap= new Map<String, Stand__c>();
            Set<String> exhibitorSet= new Set<String>();
            Set<String> expocadIdsSet= new Set<String>();
            Set<String> pavilionExpoCADIds = new Set<String>();
            Map<String, Pavilion__c> existingPavilionsMap = new Map<String, Pavilion__c>();
            List<Stand__c> recordsToAdd = new List<Stand__c>();
            Map<String, Stand__c> existingStandMap = new Map<String, Stand__c>();
            Map<String, Stand__c> recordsToAddMap = new Map<String, Stand__c>();


            // Upsert Pavilions Data..
            if(pavilionNamesList.size() > 0){
                List<Pavilion__c> pavilionList= new List<Pavilion__c>();
                Map<String,Pavilion__c> pavRecordsToAdd = new Map<String,Pavilion__c>();
                List<Pavilion__c> existPavList = new List<Pavilion__c>();

                for(String pavilionName: pavilionNamesList){
                    String pavExpocadId=eventRecord.ExpoCAD_ID__c+'.'+pavilionName;
                    pavilionList.add(new Pavilion__c(Name = pavilionName, ExpoCAD_ID__c=pavExpocadId , Event__c = eventRecord.Id));
                    pavilionExpoCADIds.add(pavExpocadId);
                }
                existPavList=[SELECT Id, Name, ExpoCAD_ID__c FROM Pavilion__c WHERE ExpoCAD_ID__c IN :pavilionExpoCADIds];
                for (Pavilion__c pavilion : existPavList) {
                    existingPavilionsMap.put(pavilion.ExpoCAD_ID__c.toLowerCase(), pavilion);
                }
                for (Pavilion__c pavRec : pavilionList) {
                    if (!existingPavilionsMap.containsKey(pavRec.ExpoCAD_ID__c.toLowerCase())) {
                        pavRecordsToAdd.put(pavRec.ExpoCAD_ID__c,pavRec);
                    }
                }
                Database.UpsertResult[] upsertResult = Database.upsert(pavRecordsToAdd.values(), Pavilion__c.Fields.ExpoCAD_ID__c, false);
                handleUpsertErrors(upsertResult);
                existingPavilionsMap.putAll(pavRecordsToAdd);
                for(Pavilion__c pavilion:existingPavilionsMap.values()){
                    pavilionMap.put(pavilion.ExpoCAD_ID__c.toLowerCase(), pavilion);
                }
            }

            if(expoWrap.success){
                List<ExpocadWrapper.BoothInfo> boothList = (List<ExpocadWrapper.BoothInfo>)JSON.deserialize(expoWrap.message, List<ExpocadWrapper.BoothInfo>.class);
                for(ExpocadWrapper.BoothInfo booth:boothList){
                    String standExpocadId=eventRecord.ExpoCAD_ID__c+'.'+booth.BoothNumber;
                    String pavExpocadId=eventRecord.ExpoCAD_ID__c+'.'+booth.Pavilion;

                    Stand__c  stand= new Stand__c();
                    stand.Area__c=booth.NumericArea;
                    stand.Booth_Type__c=booth.BoothType;
                    stand.Dimensions__c=booth.Dimensions;
                    stand.Display_Name_Override__c=booth.DisplayNameOverride;
                    stand.ExpoCAD_ID__c= standExpocadId;
                    stand.ExpoCAD_Status__c=booth.Status;
                    stand.Is_Deleted__c=booth.IsDeleted;
                    stand.Is_On_Hold__c=booth.IsOnHold;
                    stand.Is_Rented__c=booth.IsRented;
                    stand.Length__c=booth.YSize;
                    stand.Name=booth.BoothNumber;
                    stand.Open_Corners__c=booth.OpenCorners;
                    stand.Show_In_Show__c=booth.ShowInShow;
                    stand.Stand_Builder_Notes__c=booth.Pavilion;
                    stand.Status_Synced_with_ExpoCAD__c='Success';
                    stand.Status_Last_Synced_with_ExpoCAD__c= System.now();
                    stand.Unit_Type__c=booth.UnitType;
                    stand.Width__c=booth.XSize;
                    stand.Event__c=eventRecord.Id;
                    if (pavilionMap.containsKey(pavExpocadId.toLowerCase())) {
                        stand.Pavilion__c = pavilionMap.get(pavExpocadId.toLowerCase()).Id;
                    }
                    standList.add(stand);
                    expocadIdsSet.add(standExpocadId);
                }

                // Update Event Status
                eventRecord.Details_Synced_with_ExpoCAD__c = boothList.size()== 0 && pavilionNamesList.size()== 0 ? 'Failure' : 'Success';
                eventRecord.Event_ExpoCAD_Error_Details__c = boothList.isEmpty() && pavilionNamesList.isEmpty() ? expoWrap.message : '';

            }else{
                eventRecord.Details_Synced_with_ExpoCAD__c='Failure';
                eventRecord.Event_ExpoCAD_Error_Details__c=expoWrap.message;
                // Handle Integration Excepetion...................
                handleIntegrationException(expoWrap.message);
            }

            if (!standList.isEmpty()) {                
            
                for (Stand__c stand : [SELECT Id, Name, Pavilion__c, ExpoCAD_ID__c FROM Stand__c WHERE ExpoCAD_ID__c IN :expocadIdsSet]) {
                    existingStandMap.put(stand.ExpoCAD_ID__c.toLowerCase(), stand);
                }
            
                for (Stand__c standRec : standList) {
                    if (!existingStandMap.containsKey(standRec.ExpoCAD_ID__c.toLowerCase())) {
                        // 9th July 2024 changes
                        standRec.Pavilion__c = (!standRec.Is_Deleted__c && standRec.Pavilion__c != null) ? standRec.Pavilion__c : null;
                        // 9th July 2024 changes
                        recordsToAddMap.put(standRec.ExpoCAD_ID__c, standRec);
                    } else {
                        Stand__c exisStandRec = existingStandMap.get(standRec.ExpoCAD_ID__c.toLowerCase());

                        exisStandRec.Pavilion__c = (!standRec.Is_Deleted__c && standRec.Pavilion__c != null) ? standRec.Pavilion__c : null;
                        exisStandRec.Area__c = standRec.Area__c;
                        exisStandRec.Booth_Type__c = standRec.Booth_Type__c;
                        exisStandRec.Dimensions__c = standRec.Dimensions__c;
                        exisStandRec.Display_Name_Override__c = standRec.Display_Name_Override__c;
                        exisStandRec.ExpoCAD_Status__c = standRec.ExpoCAD_Status__c;
                        exisStandRec.Is_Deleted__c = standRec.Is_Deleted__c;
                        exisStandRec.Is_On_Hold__c = standRec.Is_On_Hold__c;
                        exisStandRec.Is_Rented__c = standRec.Is_Rented__c;
                        exisStandRec.Length__c = standRec.Length__c;
                        exisStandRec.Open_Corners__c = standRec.Open_Corners__c;
                        exisStandRec.Show_In_Show__c = standRec.Show_In_Show__c;
                        exisStandRec.Status_Synced_with_ExpoCAD__c = 'Success';
                        exisStandRec.Status_Last_Synced_with_ExpoCAD__c = System.now();
                        exisStandRec.Unit_Type__c = standRec.Unit_Type__c;
                        exisStandRec.Width__c = standRec.Width__c;
                        recordsToAddMap.put(exisStandRec.ExpoCAD_ID__c, exisStandRec);
                    }
                }
            }

            //on 24th June changes::For the  Pavilion stand is deleted off the floorplan, and  not  appearing as apart of the pavilion in Salesforce
            // for (Stand__c stand : [SELECT Id,Name, Pavilion__c, ExpoCAD_ID__c FROM Stand__c WHERE Pavilion__c != null AND Pavilion__r.ExpoCAD_ID__c IN :pavilionMap.keySet()]) {
            //     if (!existingStandMap.containsKey(stand.ExpoCAD_ID__c.toLowerCase())) {
            //         stand.Pavilion__c = null;
            //         stand.Is_Deleted__c = true;
            //         stand.Is_On_Hold__c = false;
            //         stand.Is_Rented__c = false;
            //         recordsToAddMap.put(stand.ExpoCAD_ID__c, stand);
            //         System.debug(stand.ExpoCAD_ID__c.toLowerCase()+'::'+stand.Name);    
            //     }
            // }


            for (Stand__c stand : [SELECT Id,Name, Pavilion__c, ExpoCAD_ID__c FROM Stand__c WHERE Event__c=:eventRecord.Id]) {
                if (stand.ExpoCAD_ID__c != null && !existingStandMap.containsKey(stand.ExpoCAD_ID__c.toLowerCase())) {
                    if(stand.Pavilion__c!=null){
                        stand.Pavilion__c = null;
                    }
                    stand.Is_Deleted__c = true;
                    stand.Is_On_Hold__c = false;
                    stand.Is_Rented__c = false;
                    recordsToAddMap.put(stand.ExpoCAD_ID__c, stand);
                    System.debug(stand.ExpoCAD_ID__c.toLowerCase()+'::'+stand.Name);    
                }
            }
            // 24th June changes end::  
            // Convert the map values to a list before the upsert
            recordsToAdd.addAll(recordsToAddMap.values());
        
            Database.UpsertResult[] upsertStand = Database.upsert(recordsToAdd, Stand__c.Fields.ExpoCAD_ID__c, false);
            handleUpsertErrors(upsertStand);
            
            
            
            // Update Event Status
            eventRecord.Last_Synced_with_ExpoCAD__c= System.now();
            updateFromExpocad=true;
            update eventRecord;

        }catch(Exception exp){
            updateEventWithError(eventRecord, 'Exception:' + exp.getMessage() + exp.getLineNumber());
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }
    }
    //========================Project -2 Logic ===========================
   
    // public static void standCalloutByName(String standId){
    //     try{
    //         Stand__c stand = fetchStandRecord(standId);

    //         ExpocadWrapper expoWrap=ExpocadIntegration.getBoothByEventAndName(stand.Event_Expocad_Id__c	 , stand.Name);

    //         if(expoWrap.success && stand != null){
    //             ExpocadWrapper.BoothInfo boothDetails=  (ExpocadWrapper.BoothInfo) JSON.deserialize(expoWrap.message,  ExpocadWrapper.BoothInfo.class);
            
    //             String exhibitorId='';
    //             if(stand.Account_ID__c !=null){
    //                 exhibitorId=stand.Account_ID__c;
    //             }
    //             String ExhibitorName='';
    //             if(stand.Account_Name__c !=null){
    //                 ExhibitorName=stand.Account_Name__c;
    //             }
    //             boolean isOnHoldSynced = stand.Is_On_Hold__c == boothDetails.IsOnHold;
    //             boolean isRentSynced = stand.Is_Rented__c == boothDetails.IsRented;

    //             if(isOnHoldSynced || isRentSynced){
    //                 stand.Status_Synced_with_ExpoCAD__c='Success';                
    //                 stand.Status_Last_Synced_with_ExpoCAD__c=System.now();
    //                 stand.ExpoCAD_Error_Details__c='';

    //             }
               
    //             if(!isOnHoldSynced && stand.Is_On_Hold__c){
    //                 System.debug('SF_ISHOLD is true');
    //                 System.debug('NEXT STEP: Check Exhibitor::::'+exhibitorId);
    //                 ExpocadWrapper checkExhibitor= ExpocadIntegration.getExhibitorById(stand.Event_Expocad_Id__c, exhibitorId);
                    
    //                 if(checkExhibitor.success){
    //                     System.debug('Sucessfully get exhbbitor by Id:::::Now Hold 2 Stand');
    //                     hold2Stand(stand);
    //                 }else{
    //                     System.debug('No Exhibitors Found::::: Add new Exhibitors');
    //                     Map<String, Object> requestBodyMap = new Map<String, Object>();
    //                     requestBodyMap.put('DisplayOnDrawing', stand.Trading_As__c);
    //                     requestBodyMap.put('ExhibitorName', ExhibitorName);
    //                     requestBodyMap.put('ExhibitorId', exhibitorId);
    //                     String requestBody = JSON.serialize(requestBodyMap);

    //                     ExpocadWrapper Expocad_newExhibitor= ExpocadIntegration.addNewExhibitor(stand.Event_Expocad_Id__c , requestBody);
    //                     if(Expocad_newExhibitor.success){
    //                         hold2Stand(stand);
    //                     }else{
    //                         System.debug('Hold 2 stand Fail::'+checkExhibitor.message);
    //                         // handleIntegrationException(checkExhibitor.message);
    //                         stand.ExpoCAD_Error_Details__c= checkExhibitor.message;
    //                         stand.Status_Synced_with_ExpoCAD__c='Failure';
    //                     }
    //                 } 
    //             }else  if(!isOnHoldSynced && !stand.Is_On_Hold__c){
    //                 System.debug('UNHOLD2 Stand');
    //                 ExpocadWrapper expocadWrapper= ExpocadIntegration.setBoothToUnhold(stand.Event_Expocad_Id__c , stand.Name);
    //                 if(expocadWrapper.success){
    //                     stand.Status_Last_Synced_with_ExpoCAD__c=System.now();
    //                     stand.Status_Synced_with_ExpoCAD__c='Success';
    //                     stand.ExpoCAD_Error_Details__c='';

    //                 }else{
    //                     stand.ExpoCAD_Error_Details__c= expoWrap.message;
    //                     stand.Status_Synced_with_ExpoCAD__c='Failure';
    //                     // handleIntegrationException(expoWrap.message);

    //                 }
    //             }
                
    //             System.debug('RENT UNRENT SCRIPT::::: ExpocadisHold=== SFisHold');
    //             if(!isRentSynced && stand.Is_Rented__c){
    //                 System.debug('SF_Rent=True::::Next Rent2 Stand');
    //                 ExpocadWrapper expo= ExpocadIntegration.setBoothToRent(stand.Event_Expocad_Id__c,stand.Name,exhibitorId);
    //                 if(expo.success){
    //                     stand.Status_Last_Synced_with_ExpoCAD__c=System.now();
    //                     stand.Status_Synced_with_ExpoCAD__c='Success';
    //                     stand.ExpoCAD_Error_Details__c='';

    //                 }else{
    //                     System.debug('Rent 2 Fail:::'+expo.message);
    //                     stand.ExpoCAD_Error_Details__c= expo.message;
    //                     stand.Status_Synced_with_ExpoCAD__c='Failure';
    //                     // handleIntegrationException(expo.message);
    //                 }

    //             }else if(!isRentSynced && !stand.Is_Rented__c){
    //                 System.debug('SF_Rent = false::::Next UnRent2 Stand');
    //                 ExpocadWrapper expo= ExpocadIntegration.setBoothToUnrent(stand.Event_Expocad_Id__c,stand.Name,exhibitorId);
    //                 if(expo.success){
    //                     stand.Status_Last_Synced_with_ExpoCAD__c=System.now();
    //                     stand.Status_Synced_with_ExpoCAD__c='Success';
    //                     stand.ExpoCAD_Error_Details__c='';

    //                 }else{
    //                     stand.ExpoCAD_Error_Details__c= expo.message;
    //                     stand.Status_Synced_with_ExpoCAD__c='Failure';
    //                     // handleIntegrationException(expo.message);

    //                 }
    //             } 
    //         }else{
    //             System.debug('Error:::::: Failed to get Booth Details....');
    //             // handleIntegrationException(expoWrap.message);
    //             stand.ExpoCAD_Error_Details__c= expoWrap.message;
    //             stand.Status_Synced_with_ExpoCAD__c='Failure';
    //         }
    //         updateFromExpocad=true;
    //         update stand;
    //     }catch(Exception exp){
    //         handleException(exp);
    //         System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
    //     }
    // }
    // Description:- Hold Stand in Expo (Make put request to set booth to hold in expocad)
    // public static void hold2Stand(Stand__c stand){
    //     try{
    //         String exhibitorId='';
    //         if(stand.Account_ID__c !=null){
    //             exhibitorId=stand.Account_ID__c;
    //         }

    //         ExpocadWrapper expoWrap=ExpocadIntegration.setBoothHold(stand.Event_Expocad_Id__c, stand.Name, exhibitorId);
    //         if(expoWrap.success){
    //             System.debug('Both Hold sucess');
    //             stand.Status_Synced_with_ExpoCAD__c='Success';
    //             stand.Status_Last_Synced_with_ExpoCAD__c=System.now();
    //             stand.ExpoCAD_Error_Details__c='';

    //         }else{
    //             System.debug(expoWrap.message);
    //             stand.ExpoCAD_Error_Details__c= expoWrap.message;
    //             stand.Status_Synced_with_ExpoCAD__c='Failure';
    //         }
    //     }catch(Exception exp){
    //         handleException(exp);
    //         System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
    //     }
    // }
    // Callout ChildExhibitor Transformation
    @future(callout=true)
    public static void childExhibitorTransformation(String coExhibitorId){
        try{
            System.debug('childExhibitorTransformation');
            Co_Exhibitor__c coExhibitor=fetchCoExhibitors(coExhibitorId);
            String eventName='';
            String boothNumber='';
            String accountId='';
            if(coExhibitor.Event__c != null && coExhibitor.Event__r.ExpoCAD_ID__c != null){
                eventName=coExhibitor.Event__r.ExpoCAD_ID__c;
            }
            if(coExhibitor.Stand__c !=null && coExhibitor.Stand__r.Name != null){
                boothNumber=coExhibitor.Stand__r.Name;
            }
            if(coExhibitor.Account__c != null){
                accountId=coExhibitor.Account__c;
            }
            System.debug(eventName+':'+boothNumber+':'+ accountId);
            ExpocadWrapper expoWrapper= ExpocadIntegration.setBoothChildExhibitors(eventName , boothNumber, accountId);
            System.debug(expoWrapper.success);
            if(expoWrapper.success){
                System.debug('Callout Booth Reset');
                ExpocadWrapper resetDisplayName= ExpocadIntegration.resetBoothDisplayName(eventName , boothNumber);
                if(resetDisplayName.success){
                    System.debug('Call Co exhibitor 2');
                    coExhibitor.Details_Synced_with_ExpoCAD__c='Success';
                }
            }else{
                coExhibitor.Details_Synced_with_ExpoCAD__c='Failure';
                System.debug('Integration Exception:');
                // Expocad error details...
                handleIntegrationException(expoWrapper.message);
            }
            updateFromExpocad=true;
            update coExhibitor;
        }catch(Exception exp){
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
            handleException(exp);
        }
    }

    @future(callout=true)
    public static void checkVerifingStatus(String coExhibitorId){
        try{
            Co_Exhibitor__c coExhibitor=fetchCoExhibitors(coExhibitorId);
            String eventName='';
            String exhibitorId='';
            if(coExhibitor.Event__c !=null && coExhibitor.Event__r.ExpoCAD_ID__c !=null){
                eventName=coExhibitor.Event__r.ExpoCAD_ID__c;
            }

            if(coExhibitor.Account__c !=null){
                exhibitorId=coExhibitor.Account__c;
            }
                
            ExpocadWrapper exhibitorDetails= ExpocadIntegration.getExhibitorById(eventName, exhibitorId);
            if(exhibitorDetails.success){
                //update from existing coexhibitor Request
                coExhibitor.Exhibitor_Sync_with_ExpoCAD__c='Exists';
            }else{
                //update from non existing coexhibitor Request
                coExhibitor.Exhibitor_Sync_with_ExpoCAD__c='Creating';
            }

            updateFromExpocad=true;
            update coExhibitor;
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }    
    }

    @future(callout=true)
    public static void checkCreatingStatus(String coExhibitorId){
        try{
            Co_Exhibitor__c coExhibitor=fetchCoExhibitors(coExhibitorId);
            String eventName='';
            String exhibitorId='';
            if(coExhibitor.Event__c !=null && coExhibitor.Event__r.ExpoCAD_ID__c !=null){
                eventName=coExhibitor.Event__r.ExpoCAD_ID__c;
            }

            if(coExhibitor.Account__c !=null){
                exhibitorId=coExhibitor.Account__c;
            }
                
            // if(coExhibitor.Exhibitor_Sync_with_ExpoCAD__c== 'Creating' && coExhibitor.Details_Synced_with_ExpoCAD__c != 'Requested'){
                // Add New Exhibitor
                Map<String, Object> requestBodyMap = new Map<String, Object>();
                requestBodyMap.put('DisplayOnDrawing', 'Tested');
                requestBodyMap.put('ExhibitorName', coExhibitor.Account__r.Name);
                requestBodyMap.put('ExhibitorId', exhibitorId);
                String requestBody = JSON.serialize(requestBodyMap);

                // ExpocadWrapper.Exhibitor exhibitor= ExpocadIntegration.addNewExhibitor(eventName , requestBody);
                ExpocadWrapper Expocad_newExhibitor= ExpocadIntegration.addNewExhibitor(eventName , requestBody);

                if(Expocad_newExhibitor.success){
                    System.debug('Update From just created exhibitor requested');
                    coExhibitor.Exhibitor_Sync_with_ExpoCAD__c='Exists';
                }

            // }

            updateFromExpocad=true;
            update coExhibitor;
        }catch(Exception exp){
            handleException(exp);
            System.debug('Exception:' + exp.getMessage() + exp.getLineNumber());
        }    
    }
    // Description:- Check-co-exhibitor Status..
    public static void checkCoExhibitorStatus(String coExhibitorId){
        try{
            Co_Exhibitor__c coExhibitor=fetchCoExhibitors(coExhibitorId);
            String eventName='';
            String exhibitorId='';
            if(coExhibitor.Event__c !=null && coExhibitor.Event__r.Name !=null){
                eventName=coExhibitor.Event__r.Name;
            }

            if(coExhibitor.Account__c !=null){
                exhibitorId=coExhibitor.Account__c;
            }

            if(coExhibitor.Exhibitor_Sync_with_ExpoCAD__c== 'Verifying' && coExhibitor.Details_Synced_with_ExpoCAD__c != 'Requested'){
                System.debug('Check Parent Exhibitor');
                // ExpocadWrapper.Exhibitor exhibitorDetails= ExpocadIntegration.getExhibitorById(eventName, exhibitorId);
                ExpocadWrapper exhibitorDetails= ExpocadIntegration.getExhibitorById(eventName, exhibitorId);

                if(exhibitorDetails.success){
                    //update from existing coexhibitor Request
                    coExhibitor.Exhibitor_Sync_with_ExpoCAD__c='Exists';
                }else{
                    //update from non existing coexhibitor Request
                    coExhibitor.Exhibitor_Sync_with_ExpoCAD__c='Creating';
                }

            }

            if(coExhibitor.Exhibitor_Sync_with_ExpoCAD__c== 'Creating' && coExhibitor.Details_Synced_with_ExpoCAD__c != 'Requested'){
                // Add New Exhibitor
                Map<String, Object> requestBodyMap = new Map<String, Object>();
                requestBodyMap.put('DisplayOnDrawing', 'Tested');
                requestBodyMap.put('ExhibitorName', coExhibitor.Account__r.Name);
                requestBodyMap.put('ExhibitorId', exhibitorId);
                String requestBody = JSON.serialize(requestBodyMap);

                // ExpocadWrapper.Exhibitor exhibitor= ExpocadIntegration.addNewExhibitor(eventName , requestBody);
                ExpocadWrapper Expocad_newExhibitor= ExpocadIntegration.addNewExhibitor(eventName , requestBody);

                if(Expocad_newExhibitor.success){
                    System.debug('Update From just created exhibitor requested');
                    coExhibitor.Exhibitor_Sync_with_ExpoCAD__c='Exists';
                }

            }

            if(coExhibitor.Exhibitor_Sync_with_ExpoCAD__c== 'Exists' && coExhibitor.Details_Synced_with_ExpoCAD__c == 'Requested'){
                //callout childExhibitorTransformation
                childExhibitorTransformation(coExhibitorId);
            }
            updateFromExpocad=true;
            update coExhibitor;
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
        insert excep;
    }
    // Description:- Handle Integration Error...
    private static void handleIntegrationException(String errorMessage) {
        Capture_Exception__c excep = new Capture_Exception__c();
        excep.Error_Message__c = errorMessage;
        excep.Name = 'Integration Error';
        insert excep;
    }

     //Description:- Handle Upsert Errors...
     private static void handleUpsertErrors(Database.UpsertResult[] upsertResults) {
        for(Database.UpsertResult result : upsertResults) {
            if(result.isSuccess()) {
                // System.debug('Record successfully inserted/updated with Id: ' + result.getId());
            } else {
                for(Database.Error error : result.getErrors()) {
                    System.debug('Error message: ' + error.getMessage());
                }
            }
        }
    }


    private static void updateEventWithError(Event__c eventRecord, String errorMessage) {
        eventRecord.Details_Synced_with_ExpoCAD__c = 'Failure';
        eventRecord.Event_ExpoCAD_Error_Details__c = errorMessage;
        updateFromExpocad = true;
        update eventRecord;
    }

    
}