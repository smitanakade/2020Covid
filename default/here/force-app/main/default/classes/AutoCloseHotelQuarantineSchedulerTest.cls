/**
 * Created by shrta on 5/04/2021.
 */

@IsTest
private class AutoCloseHotelQuarantineSchedulerTest {
    @IsTest
    static void testBehavior() {
        Test.startTest();
        String jobId = System.schedule('testScheduledApex', '0 0 9 * * ?', new AutoCloseHotelQuarantineScheduler());
        Test.stopTest();

        // Get the information from the CronTrigger API object
        List<CronTrigger> ct = [
                SELECT Id, CronExpression, TimesTriggered, NextFireTime
                FROM CronTrigger WHERE id = :jobId];

        System.assertNotEquals(0, ct.size());
    }
}