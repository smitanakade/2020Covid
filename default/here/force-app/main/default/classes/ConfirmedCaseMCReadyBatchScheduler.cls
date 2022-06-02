global class ConfirmedCaseMCReadyBatchScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new ConfirmedCasesMCReadyBatchProcess(),200);
    }
}