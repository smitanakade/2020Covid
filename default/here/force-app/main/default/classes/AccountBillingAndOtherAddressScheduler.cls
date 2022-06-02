/**
 * @Author             : Touseef Ahmed Mohammed
 * @Description        : Batch Job Schedular to Seach and copy the Billing and Other address from account to CPA Object.
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 26/11/2021     Touseef Ahmed Mohammed        Initial version
**/

global class AccountBillingAndOtherAddressScheduler implements Schedulable {
       
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new AccountBillingAndOtherAddressBatch(),200);
    }
}
