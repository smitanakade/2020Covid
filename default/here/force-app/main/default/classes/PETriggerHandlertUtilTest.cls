/*
    Author: Pratyush Chalasani

    @Modification Log
    ---------------------------------------------------
    Date           Author      		    Details
    ---------------------------------------------------
    26/08/2021     Pratyush Chalasani    Feature 295615: Asynchronous trigger processing
*/
@isTest
public class PETriggerHandlertUtilTest {
    @isTest
    static void testGetFields() {
        List<String> longTextFields = new List<String>();

        // Get all fields for object
        Map<String, SObjectField> fieldMap = Case.getSObjectType().getDescribe().fields.getMap();

        for (SObjectField field: fieldMap.values()) {
            Schema.DescribeFieldResult f = field.getDescribe();
            if (f.getType().name() == 'TEXTAREA') longTextFields.add(f.getName());
        }

        Test.startTest();

        List<String> fields = PETriggerHandlerUtil.getAllFields('Case');

        //Check that the fields returned by AsyncUtil do not contain any long text area fields
        Boolean hasLongTextArea = false;

        for (String f: fields) {
            if (longTextFields.contains(f)) {
                hasLongTextArea = true;
            }
        }

        Test.stopTest();

        System.assertEquals(false, hasLongTextArea, 'There should be no long text area fields returned by AsyncUtil.getFields');
    }

    @isTest
    static void testAsyncCaseInsert() {
        Account acc = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

        List<Case> cases = TestDataFactory.createCases(acc, 1, 'Trace', 'COVID-19 Case Assessment');

        Map<Id, Case> oldMap = new Map<Id, Case>();

        oldMap.put(cases[0].Id, cases[0]);

        Test.startTest();

        // Bypassing this because it's causing the wrong ID to be returned when testing
        TriggerHandler.bypass('WorkOrderTriggerHandler');

        PETriggerHandlerUtil.asyncInserted = false;
        PETriggerHandlerUtil.asyncUpdated = false;

        PETriggerHandlerUtil.publishAsyncEvents('Case', 'insert', cases, oldMap);

        Test.stopTest();

        System.assertEquals(true, PETriggerHandlerUtil.asyncInserted);
    }

    @isTest
    static void testAsyncCaseUpdate() {
        Account acc = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

        List<Case> cases = TestDataFactory.createCases(acc, 1, 'Trace', 'COVID-19 Case Assessment');

        Map<Id, Case> oldMap = new Map<Id, Case>();

        oldMap.put(cases[0].Id, cases[0]);

        Test.startTest();

        // Bypassing this because it's causing the wrong ID to be returned when testing
        TriggerHandler.bypass('WorkOrderTriggerHandler');

        PETriggerHandlerUtil.asyncInserted = false;
        PETriggerHandlerUtil.asyncUpdated = false;

        PETriggerHandlerUtil.publishAsyncEvents('Case', 'update', cases, oldMap);

        Test.getEventBus().deliver();

        Test.stopTest();

        System.assertEquals(true, PETriggerHandlerUtil.asyncUpdated);
    }

    @isTest
    static void testAsyncAccountInsert() {
        Set<Id> accountIds=new Set<Id>();
        List<Task> taskList=new List<Task>();
        
        List<Account> accList = TestDataFactory.createAccount(1, 'Active','Person Account',null);
        Map<Id, Account> oldMap = new Map<Id, Account>();

        oldMap.put(accList[0].Id, accList[0]);

        Test.startTest();
        PETriggerHandlerUtil.asyncInserted = false;
        PETriggerHandlerUtil.asyncUpdated = false;
        //Publishing events
        PETriggerHandlerUtil.publishAsyncEvents('Account', 'insert', accList, oldMap);
        Test.getEventBus().deliver();

        Test.stopTest();

        System.assertEquals(true, PETriggerHandlerUtil.asyncUpdated);
    }

    @isTest
    static void testAsyncAccountUpdate() {
        Set<Id> accountIds=new Set<Id>();
        List<Task> taskList=new List<Task>();
        
        List<Account> accList = TestDataFactory.createAccount(1, 'Active','Person Account',null);
        Map<Id, Account> oldMap = new Map<Id, Account>();

        oldMap.put(accList[0].Id, accList[0]);

        Test.startTest();

        PETriggerHandlerUtil.asyncInserted = false;
        PETriggerHandlerUtil.asyncUpdated = false;

        PETriggerHandlerUtil.publishAsyncEvents('Account', 'update', accList, oldMap);

        Test.stopTest();

        System.assertEquals(true, PETriggerHandlerUtil.asyncInserted);
    }
}