/*
    Author: Pratyush Chalasani

    @Modification Log
    ---------------------------------------------------
    Date           Author      		    Details
    ---------------------------------------------------
    26/08/2021     Pratyush Chalasani    Feature 295615: Asynchronous trigger processing
*/
@isTest()
public class CasePEHandlerTest {

    @isTest
    static void testAsyncInsert() {
        Account acc = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

        List<Case> cases = TestDataFactory.createCases(acc, 1, 'Trace', 'COVID-19 Case Assessment');
       
        Test.startTest();

        // Bypassing this because it's causing the wrong ID to be returned when testing
        TriggerHandler.bypass('WorkOrderTriggerHandler');       
        CasePEHandler.asyncInsert(cases);       

        Test.stopTest();
        
    }

    @isTest
    static void testAsyncUpdate() {
        Account acc = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

        List<Case> cases = TestDataFactory.createCases(acc, 1, 'Trace', 'COVID-19 Case Assessment');

        Map<Id, Case> oldMap = new Map<Id, Case>();

        oldMap.put(cases[0].Id, cases[0]);

        Test.startTest();

        // Bypassing this because it's causing the wrong ID to be returned when testing
        TriggerHandler.bypass('WorkOrderTriggerHandler');       
        CasePEHandler.asyncUpdate(cases, oldMap);       

        Test.stopTest();
        
    }
}
