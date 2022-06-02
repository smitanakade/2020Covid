/**
 * @Author             : Hemant Singh
 * @Description        : Apex Batch Job to delete de-dup index entries older than N number of days
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 25/11/2021     Hemant Singh          Initial version
**/

global class ClearDcIndexBatchScheduler implements Schedulable {
       
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new ClearDcIndexBatch(),200);
    }
}