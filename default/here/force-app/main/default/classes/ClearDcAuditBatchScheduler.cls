/**
 * @Author             : Hemant Singh
 * @Description        : Batch Job Schedular to delete de-dup audit log entries older than 30 days
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 16/08/2021     Hemant Singh          Initial version
**/

global class ClearDcAuditBatchScheduler implements Schedulable {
       
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new ClearDcAuditBatch(),200);
    }
}