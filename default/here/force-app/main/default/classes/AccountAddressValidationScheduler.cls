/**
 * @Author             : Hemant Singh
 * @Description        : Batch Job Schedular to re-trigger Account address validation for pending addressess
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 10/10/2021     Hemant Singh          Initial version
**/

global class AccountAddressValidationScheduler implements Schedulable {
       
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new AccountAddressValidationBatch(),200);
    }
}