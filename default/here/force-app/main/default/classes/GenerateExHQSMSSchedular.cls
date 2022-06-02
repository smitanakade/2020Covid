global class GenerateExHQSMSSchedular implements Schedulable {
       
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new GenerateExHQSMSBatchProcess(),200);
    }
}