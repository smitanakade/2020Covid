@isTest()
public with sharing class AccountPEHandlerTest {
    @isTest
    static void testAsyncInsert() {
        List<Account> accList = TestDataFactory.createAccount(1, 'Active', 'Person Account');

       
       
        Test.startTest();

        // Bypassing this because it's causing the wrong ID to be returned when testing
      //  TriggerHandler.bypass('WorkOrderTriggerHandler');       
       AccountPEHandler.asyncInsert(accList);       

        Test.stopTest();
        
    }

    @isTest
    static void testAsyncUpdate() {
        List<Account> accList = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        //List<Case> cases = TestDataFactory.createCases(acc, 1, 'Trace', 'COVID-19 Case Assessment');

        Map<Id, Account> oldMap = new Map<Id, Account>();

        oldMap.put(accList[0].Id, accList[0]);

        Test.startTest();

        // Bypassing this because it's causing the wrong ID to be returned when testing
       // TriggerHandler.bypass('WorkOrderTriggerHandler');       
      AccountPEHandler.asyncUpdate(accList, oldMap);       

        Test.stopTest();
        
    }
}