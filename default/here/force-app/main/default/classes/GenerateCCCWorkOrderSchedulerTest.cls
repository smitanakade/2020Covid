/*
    Created by: YPerera
    
    @Modification Log   :
    ---------------------------------------------------
    Date           Author      		    Details
    24/03/2021     YPerera		        Feature 265632: Close Contact Clearance Work Order - Close Contact Day 14 Notification
    ---------------------------------------------------
*/
@IsTest
public with sharing class GenerateCCCWorkOrderSchedulerTest {
    @IsTest
    public static void Test_GenerateCCCWorkOrdersScheduler_001(){
        Test.startTest();
        
        String jobId = System.schedule('testBasicScheduledApex', '0 0 9 * * ?', new GenerateCloseContactClearanceWOScheduler() );
        Test.stopTest();

        List<CronTrigger> ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        
        System.assertNotEquals(0,ct.size());
    }
}