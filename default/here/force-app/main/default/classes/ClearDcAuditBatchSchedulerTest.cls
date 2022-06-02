@isTest
private class ClearDcAuditBatchSchedulerTest {
    @isTest
    static void testBehavior(){
        try{
            Test.startTest();
            String jobId = System.schedule('testScheduledApex', '0 0 9 * * ?', new ClearDcAuditBatchScheduler());
            Test.stopTest();

            // Get the information from the CronTrigger API object
            List<CronTrigger> ct = [
                    SELECT Id, CronExpression, TimesTriggered, NextFireTime
                    FROM CronTrigger WHERE id = :jobId];

            System.assertNotEquals(0, ct.size());
        }catch(Exception exp){
            ApplicationLogUtility.createlog('ClearDcAuditBatchSchedulerTest','testBehavior',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}