/*************************
* Created By : Foram 
* Cereated Date : 22-01-2024
* Description : Schedule ImportFuncRegistartionFromEventsAirBatch 
**************************/

public class ScheduleFunctionRegistartionData implements schedulable {
    
    public void execute(SchedulableContext sc){
        
        ImportFuncRegistartionFromEventsAirBatch newBatch = new ImportFuncRegistartionFromEventsAirBatch();
        Database.executeBatch(newBatch, 500);
    }
}