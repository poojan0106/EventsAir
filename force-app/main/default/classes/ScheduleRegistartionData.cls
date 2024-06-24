/*************************
* Created By : Foram 
* Cereated Date : 22-01-2024
* Description : Schedule ImportRegistartionFromEventsAirBatch 
**************************/

public class ScheduleRegistartionData implements schedulable {
    
    public void execute(SchedulableContext sc) {
        
        ImportRegistartionFromEventsAirBatch newBatch = new ImportRegistartionFromEventsAirBatch();
        Database.executeBatch(newBatch, 500);
    }
}