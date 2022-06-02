/**
 * @Author             : Chris Zhuang
 * @Description        : Test Class for CloseContactWorkOrderScheduler
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 16/03/2021     Chris Zhuang          Feature 269161: All interview work orders should be automatically be created when new confirmed case or new primary close contact record is created - Part 3 (AC03)
**/
@isTest
private class CloseContactWorkOrderSchedulerTest {
    @IsTest
    public static void Test_CloseContactWorkOrderScheduler(){
        try{
            Test.startTest();
            // Schedule the test job
            String jobId = System.schedule('testScheduledApex', '0 0 9 * * ?', new CloseContactWorkOrderScheduler());
            Test.stopTest();

            // Get the information from the CronTrigger API object
            List<CronTrigger> ct = [
                    SELECT Id, CronExpression, TimesTriggered, NextFireTime
                    FROM CronTrigger WHERE id = :jobId];

            System.assertNotEquals(0, ct.size());
        }catch(Exception exp){
            ApplicationLogUtility.createlog('CloseContactWorkOrderSchedulerTest','Test_CloseContactWorkOrderScheduler',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}