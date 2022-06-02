@IsTest
private class AccBillAndOthAddrSchedulerTest {
    @IsTest
    public static void Test_AccBillOtherAddr() {
        Test.startTest();
        String jobId = System.schedule('testScheduledApex', '0 0 9 * * ?', new AccountBillingAndOtherAddressScheduler());
        Test.stopTest();
         // Get the information from the CronTrigger API object
         List<CronTrigger> ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger WHERE id = :jobId];

        System.assertNotEquals(0, ct.size());
    }
}

 