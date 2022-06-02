/**
 * @Author             : Xiang Zheng
 * @Description        : DuplicateCheckDeltaTriggerHandler Test
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 15/10/2021     Xiang Zheng       PBI 320275: Merge fix - Priority for non-negatives
**/
@isTest
public with sharing class DuplicateCheckDeltaTriggerHandlerTest {
    private static Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
    @isTest
    static void handlePriorityTest() {
        Account testAcc1 = new Account();
        testAcc1.LastName = 'test1';
        testAcc1.DC_queue_priority__c = 1;
        testAcc1.DC_queue_status__c = 'Inserted';
        insert testAcc1;

        /*
        dupcheck__dcDelta__c testddc1 = new dupcheck__dcDelta__c();
        testddc1.dupcheck__object__c = testAcc1.Id;
        insert testddc1;
        */

        List<Case> testList = new List<Case>();
        Case testCase1 = new Case();
        testCase1.AccountId = testAcc1.Id;
        testCase1.DC_queue_priority__c = 1;
        testCase1.recordTypeId = confirmedCaseRecordTypeId;
        testCase1.DC_queue_status__c = 'Inserted';
        testList.add(testCase1);
        //insert testCase1;

        /*
        dupcheck__dcDelta__c testddc2 = new dupcheck__dcDelta__c();
        testddc2.dupcheck__object__c = testCase1.Id;
        insert testddc2;
        */

        Case testCase2 = new Case();
        testCase2.AccountId = testAcc1.Id;
        testCase2.recordTypeId = confirmedCaseRecordTypeId;
        testList.add(testCase2);
        //insert testCase2;
        insert testList;

        /*
        dupcheck__dcDelta__c testddc3 = new dupcheck__dcDelta__c();
        testddc3.dupcheck__object__c = testCase2.Id;
        insert testddc3;
        */

        List<dupcheck__dcDelta__c> checkList = [SELECT Id FROM dupcheck__dcDelta__c WHERE dupcheck__Priority__c != 1];
        //System.assertEquals(0,checkList.size());
    }
}