/**
 * @Author             : Arun
 * @Description        : Duplicate Check Index - Test class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 14/11/2021    Arun               PBI 332958 - Test class for Scheduled job for Duplicate Check Index creation/re-build 
 
**/
@isTest
public with sharing class DuplicateCheckIndexSchedulerTest {
    public static testMethod void testschedule() {

        Test.StartTest();
        DuplicateCheckIndexScheduler sh1 = new DuplicateCheckIndexScheduler('Exposure_Link');

        String sch = '0 0 23 * * ?'; 
        System.schedule('Test Dupe Check', sch, sh1); 
        Test.stopTest(); 
    }

}
