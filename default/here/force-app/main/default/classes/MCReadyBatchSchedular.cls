global class MCReadyBatchSchedular implements Schedulable {
       
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new AccountMCReadyBatchProcess(),200);
    }
}