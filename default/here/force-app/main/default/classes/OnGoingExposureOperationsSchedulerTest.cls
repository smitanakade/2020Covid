/**
 * @Author             : YPerera
 * @Description        : Test Class for OnGoingExposureOperationsBatch
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 20/09/2021     YPerera		        252802 - When creating a new contact encounter participant, need to be able to select 'Ongoing exposure' checkbox
**/
@isTest
private class OnGoingExposureOperationsSchedulerTest {

    @IsTest
    private static void onGoingExposureOperationsSchedulerTest(){
        Test.startTest();
        String jobId = System.schedule('testScheduledApex', '0 0 9 * * ?', new OnGoingExposureOperationsScheduler());
        Test.stopTest();
        
        List<CronTrigger> ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        
        System.assertNotEquals(0, ct.size());
    }
    
}