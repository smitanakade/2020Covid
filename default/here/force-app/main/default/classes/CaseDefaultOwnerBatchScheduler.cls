/**
 * @Author             : Hemant Singh
 * @Description        : Batch Job Schedular to re-trigger Case queue allocation from default owner (Deployment User)
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 11/11/2021     Hemant Singh          Initial version
**/

global class CaseDefaultOwnerBatchScheduler implements Schedulable {
       
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new CaseDefaultOwnerReasignmentBatch(),200);
    }
}