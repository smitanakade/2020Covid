/**
 * Created by marcelo.cost on 17/12/20.
 */
@IsTest
public with sharing class EscalationTaskGeneratorSchedulerTest {
    @IsTest
    public static void testScheduler(){
        Test.startTest();


        // Schedule the test job

        String jobId = System.schedule('testBasicScheduledApex', '0 0 9 * * ?', new EscalationTaskGeneratorScheduler() );
        Test.stopTest();
        // Get the information from the CronTrigger API object
        List<CronTrigger> ct = [SELECT Id, CronExpression, TimesTriggered,
                NextFireTime
        FROM CronTrigger WHERE id = :jobId];

        System.assertNotEquals(0,ct.size() );
    }

}