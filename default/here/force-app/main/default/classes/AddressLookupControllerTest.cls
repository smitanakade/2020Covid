/**
* @Author             : 
* @Description        : Test class for AddressLookupController
* @Modification Log   : 
 * Ver   Date         Author                               Modification
 * 1.0                Initial Version
 * 2.0   01/08/2021   Mayukhman Pathak                     Fix the null pointer exception when updateAccountAction() method is called
 *                                                         Added the TestDataFactory for setupTestData
**/@isTest
public  class AddressLookupControllerTest {
        @isTest
        static void AddressLookupControllerTestMethod() {
            List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
            List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
            insert caseListExp;
    
            Case caseRecord = caseListExp[0];
            
            Id hqRecTYpeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Confirmed_Case_Clearance').getRecordTypeId();
            List<WorkOrder> workOrders = [SELECT ID, Recordtype.Name, Status, Priority 
                                          From WorkOrder 
                                          WHERE CaseId =: caseRecord.Id 
                                          AND RecordTypeId =: hqRecTYpeId];
            
            Boolean result = AddressLookupController.updateAccountAction(personAccList[0]);
            Account result2 = AddressLookupController.getAccountAddress(workOrders[0].Id);
        }
    }