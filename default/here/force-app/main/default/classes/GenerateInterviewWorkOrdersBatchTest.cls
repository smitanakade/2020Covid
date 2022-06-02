/*
Created by: Hasantha E
 
@Modification Log   : 
---------------------------------------------------
Date           Author      		    Details 
16/03/2021     Hasantha E           Feature 265251: generate interview work orders with the schedular
---------------------------------------------------
*/
@IsTest
public with sharing class GenerateInterviewWorkOrdersBatchTest {
    /**
     * Testing of clearance work order creation when the Clearance_eligibility_assessment_date__c value is today
     * the batch job should run daily
     */
    @IsTest
    static void Test_GenerateInterviewWorkOrdersBatchTest_001() {
        //Create Person Accounts
        List<Account> personAccList = TestDataFactory.createAccount(50, 'Active','Person Account');
        //Create Cases
        Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
        List<Case> caseListConfirmed = TestDataFactory.createCasePerAccount(personAccList, 'Identity', '', confirmedCaseRecordTypeId);

        // Set placeholder value for Date_of_Test__c and Clearance_eligibility_assessment_date__c field
        for (Case c: caseListConfirmed) {
                c.Date_of_Test__c = System.today();
                c.Clearance_eligibility_assessment_date__c = System.Today();
        }

        update caseListConfirmed;

        Set<Id> caseIds = new Set<Id>();

        for(Case record : caseListConfirmed) {
            caseIds.add(record.id);
        }

        List<WorkOrder> workOrders = [
                SELECT createdDate, case.CreatedBy.Name , id, Status, CaseId, OwnerId, AccountId,  ContactId, Subject, Person_Interviewed__c, Priority
                FROM WorkOrder
                WHERE CaseId =: caseIds
                AND RecordTypeId =: WorkOrderTriggerHelper.interviewWorkOrderClearanceRecordTypeId
        ];

        System.assertEquals(
                0
                , workOrders.size()
                , 'Test_GenerateInterviewWorkOrdersBatchTest_001 : No work order records should be created with record type  Confirmed_Case_Clearance be found at this stage'
        );
        
        Test.startTest();
        Database.executeBatch(new GenerateInterviewWorkOrdersBatch());
        Test.stopTest();
        workOrders = [
                SELECT createdDate, case.CreatedBy.Name , id, Status, CaseId, OwnerId, AccountId,  ContactId, Subject, Person_Interviewed__c, Priority
                FROM WorkOrder
                WHERE CaseId =: caseIds
                AND RecordTypeId =: WorkOrderTriggerHelper.interviewWorkOrderClearanceRecordTypeId
        ];

        System.assertEquals(
                50
                , workOrders.size()
                , 'Test_GenerateInterviewWorkOrdersBatchTest_001 : Expecting work orders with Confirmed_Case_Clearance record type'
        );
    }
}