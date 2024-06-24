/**
 * @author:     Jimson @ J4RVIS
 * @date:       May/2022
 * @version     1.0
 * @description This is a helper class for updating the Account Status
 *              All methods in this class are invoked from the Schedulable Apex Classes
 */
public class AccountStatusHandler {

    /* 
    * Updates Account with Onboarding Status to Development
    * if the Account is Onboarding for more than 60 days
    */
    public static void updateOnboardingStatus(){
        
        Date last60Days = Date.today().addDays(-60);
        List<Account> acctsToUpdate = new List<Account>();

        List<Account> accts = [ SELECT Id, Name, Account_Status__c, 
                                    ( SELECT Name,CloseDate 
                                        FROM Opportunities 
                                        WHERE StageName = 'Closed Won' 
                                        ORDER BY CloseDate 
                                        ASC LIMIT 1 )
                                FROM Account 
                                WHERE Account_Status__c = 'Onboarding' ];

        for( Account c : accts) {

            if (c.Opportunities.isEmpty()){
                continue;
            }

            if ( c.Opportunities[0].CloseDate < last60Days) {
                c.Account_Status__c = 'Development';
                acctsToUpdate.add(c);
            }

        }

        system.debug('updateDevelopmentStatus: '+ acctsToUpdate);
        if ( !acctsToUpdate.isEmpty() ){
            try{
                update acctsToUpdate;
            }catch(Exception e ){
                System.debug( 'updateDevelopmentStatus' + e.getMessage());
            }
        }
    }

    /* 
    * Updates Account with Development or Lapsed Status to Engaged
    * if it made Closed Won on 2 consecutive years
    */
    public static void updateDevelopmentStatus(){

        List<Account> acctsToUpdate = new List<Account>();

        List<Account> devAccList = [ SELECT Id, Name, Account_Status__c, 
                                        ( SELECT Name, CloseDate,StageName 
                                            FROM Opportunities 
                                            WHERE StageName = 'Closed Won'  
                                            AND ( CloseDate = LAST_N_YEARS:2 OR CloseDate = THIS_YEAR )
                                            AND Amount > 0 AND Type != 'Withdrawal') 
                                        FROM Account 
                                        WHERE (Account_Status__c = 'Development' OR Account_Status__c = 'Lapsed') ];

        Integer today = Date.today().year();
        Integer lastyear = Date.today().year() - 1;
        Integer last2Years = Date.today().year() - 2;
        Set<Integer> consecutiveYear = new Set<Integer>{ today, lastyear };
        Set<Integer> consecutiveYear2 = new Set<Integer>{ lastyear, last2Years };

        for (Account acc: devAccList) {

            Set<Integer> closeDateYear = new Set<Integer>();

            for( Opportunity opp: acc.Opportunities ) {
                closeDateYear.add(opp.CloseDate.year());
            }
            
            // Account made a sale on 2 concecutive years starting this year until the past 2 years
            if ( closeDateYear.containsAll(consecutiveYear) || closeDateYear.containsAll(consecutiveYear2) ) {
                acc.Account_Status__c = 'Engaged';
                acctsToUpdate.add(acc);
            }

        }

        system.debug('updateDevelopmentStatus: '+ acctsToUpdate);
        if ( !acctsToUpdate.isEmpty() ){
            try{
                update acctsToUpdate;
            }catch(Exception e ){
                System.debug( 'updateDevelopmentStatus' + e.getMessage());
            }
        }
        
    }

    /* 
    * Updates Account with Engaged Status to Lapsed or Development
    * - Account is Lapsed if it doesn't have Closed Won opp on 2 consecutive years 
    * - Account is Development if it doesn't have 2 consecutive Closed Won opp
    *   and the Closed Won Opportunity that made it Engaged is Withdrawn
    */
    public static void updateEngagedStatus(){

        List<Account> acctsToUpdate = new List<Account>();
        // Get Closed Won Opportunities From 2 years ago
        List<Account> engagedAccList = [ SELECT Id, Name, Account_Status__c, 
                                        ( SELECT Name, CloseDate,StageName,Type,Is_Withdrawn__c,Amount 
                                            FROM Opportunities 
                                            WHERE ( StageName = 'Closed Won' OR StageName = 'Closed Lost' )  
                                            AND CloseDate < THIS_YEAR )    
                                        FROM Account WHERE Account_Status__c = 'Engaged' ];

        for ( Account acc : engagedAccList ) {  
            
            Set<Integer> closeWonYear = new Set<Integer>();
            Set<Integer> closeLostYear = new Set<Integer>();

            for( Opportunity opp: acc.Opportunities ) {
                if (opp.StageName == 'Closed Won' && opp.Type != 'Withdrawal' && opp.Amount > 0) {
                    closeWonYear.add(opp.CloseDate.year());
                }else if ( opp.StageName == 'Closed Lost' && opp.Is_Withdrawn__c ){
                    closeLostYear.add(opp.CloseDate.year());
                }
            }

            // Sort Year in desc order
            List<Integer> orderWon = new List<Integer>(closeWonYear);
            List<Integer> orderLost = new List<Integer>(closeLostYear);

            orderWon.sort();
            orderLost.sort();

            List<Integer> wonDescList = new List<Integer>();
            List<Integer> lostDescList = new List<Integer>();
            String status;

            for(Integer i = orderWon.size()-1; i>=0;i--){
                wonDescList.add(orderWon.get(i));
            }

            for(Integer i = orderLost.size()-1; i>=0;i--){
                lostDescList.add(orderLost.get(i));
            }

            System.debug('WON ' + wonDescList);
            System.debug('Lost ' + lostDescList);
            
            status = getCurrentStatus(wonDescList,lostDescList);
            
            System.debug('status '+ status);
            if ( status == 'Development'){
                acc.Account_Status__c = 'Development';
                acctsToUpdate.add(acc);
            }else if(status == 'Lapsed'){
                acc.Account_Status__c = 'Lapsed';
                acctsToUpdate.add(acc);
            }

        }

        system.debug('updateEngagedStatus: '+ acctsToUpdate);
        if ( !acctsToUpdate.isEmpty() ){
            try{
                update acctsToUpdate;
            }catch(Exception e ){
                System.debug( 'updateEngagedStatus' + e.getMessage());
            }
        }

    }

    public static String getCurrentStatus(List<Integer> closeWonYear, List<Integer> closeLostYear){
        String status;
    
        if (closeWonYear.isEmpty() ) {
            
            if(closeLostYear.isEmpty() ) {
                status = 'Lapsed';
                return status;
            }
    
            //Check if account had 2 consecutive sale withdrawn prior to Engaged status
            for( Integer cLYear: closeLostYear ){
    
                if ( closeLostYear.contains(cLYear -1)) {
                    status = 'Development';
                    break;
                }
    
                if (closeLostYear.contains(cLYear +1)){
                    status = 'Development';
                    break;
                }
    
            }
    
            if( status == 'Development'){
                return status;
            }else {
                status = 'Lapsed';
                return status;
            }
    
        } 
    
        /* Loop closed won list to check if account missed 2 consecutive years */
        Integer currentYear = Date.today().year();
    
        for(Integer i=0; i<closeWonYear.size(); i++) {
    
            // use current year for first iteration
            if ( i > 0 ){
                currentYear = closeWonYear[i-1];
            }
    
            Integer diff = currentYear - closeWonYear[i];

            // Check if sale missed 2 consecutive years
            if ( diff > 2){
                
                if ( hasConsecutiveWon(closeWonYear) ){
                    status = 'Lapsed';
                    break;
                }

                if( hasWithdrawn(closeWonYear, closeLostYear) ){
                    status = 'Development';
                    break;
                }

                status = 'Lapsed';
            }

            //sale did not missed 2 consecutive years
            if ( diff <= 2 ) {

                if ( closeWonYear.size() == 1 && hasWithdrawn(closeWonYear, closeLostYear) ) {
                    status = 'Development';
                }

                //check if it is last item
                if ( i == closeWonYear.size() - 1 ){
                    if ( ! hasConsecutiveWon(closeWonYear) && hasWithdrawn(closeWonYear, closeLostYear) ){
                        status = 'Development';
                    }
                }

            }
            
        } 

        return status;
    
    }

    public static Boolean hasConsecutiveWon(List<Integer> wonList){
        Boolean isConsecutive = false;

        for( Integer i = 0; i < wonList.size(); i++){
            //stop if last item
            if( i == wonList.size() - 1 ) {
                break;
            }

            if( wonList[i] - wonList[i+1] == 1 ){
                isConsecutive = true;
                break;
            }
        }

        return isConsecutive;
    }

    public static Boolean hasWithdrawn(List<Integer> wonList, List<Integer> withdrawnList){
        Boolean hasWithdrawn = false;

        if(withdrawnList.isEmpty()){
            return hasWithdrawn;
        }

        for(Integer wonYear: wonList){
            if( withdrawnList.contains(wonYear + 1) || withdrawnList.contains(wonYear - 1) ) {
                hasWithdrawn = true;
                break;
            }
        }

        for(Integer lostYear: withdrawnList){
            if( withdrawnList.contains(lostYear + 1) || withdrawnList.contains(lostYear - 1) ) {
                hasWithdrawn = true;
                break;
            }
        }        

        return hasWithdrawn;
    }

}