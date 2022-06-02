@isTest
public with sharing class AccountBillingAndOtherAddressBatchTest {
    @testSetup
    static void setupTestData() {
        Id accountRecordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc1=new Account();
        acc1.Alternative_Contact_Number__c='0432676435';
        acc1.BillingStreet='Ballantine';                
        acc1.BillingCity='Melbourne';        
        acc1.LastName='Test1 Acc';
        acc1.FirstName = 'Test1';
        acc1.RecordTypeId= accountRecordTypeId;
        insert acc1;

        Account acc2=new Account();
        acc2.PersonOtherStreet='0432676435';
        acc2.PersonOtherCity='Ballantine';
        acc2.LastName='Test2 Acc';
        acc2.FirstName = 'Test2';
        acc2.RecordTypeId= accountRecordTypeId;
        insert acc2;         
        
    }

    @IsTest
    public static void Test_AccountBillingAndOtherAddressBatch() {        

        Test.startTest();
        Database.executeBatch(new AccountBillingAndOtherAddressBatch(), 200);
        Test.stopTest();
        string personAccount='Person Account';
        List<ContactPointAddress> cpaList = [SELECT Id FROM ContactPointAddress where (Street!=null or Home_Phone__c!=null or City!=null)];
        System.assertEquals(2, cpaList.size(), 'CPA has been created');
    }
}
