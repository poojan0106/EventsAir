/******************************************************************************************************************************
* @description  : Schedule class for BatchUpdateEventExpoCAD batch class
* @author       : Salesfix Dev - JL
* @date         : 2018-04-18
*******************************************************************************************************************************/
global class BatchUpdateEventExpoCADSchedule implements Schedulable {
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new BatchUpdateEventExpoCAD());
    }
}