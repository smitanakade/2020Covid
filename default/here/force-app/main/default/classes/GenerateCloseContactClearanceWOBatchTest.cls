/**
 * @Author             : YPerera
 * @Description        : Test Class for GenerateCloseContactClearanceWOBatch
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 29/03/2021     YPerera		        Feature 265632: Close Contact Clearance Work Order - Close Contact Day 14 Notification
 * 12/10/2021     ASamad		        Feature 313520: Populate Name while auto-creating Close Contact Tasks 
 *                                      Update unit tests to add assert for ContactId    
**/
@isTest
private class GenerateCloseContactClearanceWOBatchTest {
    
    @testSetup
    static void setupTestData() {
        try{
            Id closeContactClearanceRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();

            List<Account> personAccList = TestDataFactory.createAccount(50, 'Active','Person Account');

            Case parentCase = new Case(recordTypeId=closeContactClearanceRecordTypeId, Status='Identify', Subject='Test Parent Case', AccountId=personAccList[0].Id, Day_15_Anticipated_release_date__c = Date.today(), Day_0_Exposure_to_the_confirmed_case__c = Date.today() - 14);
            insert parentCase;

            HealthCloudGA__EHRProcedure__c ehrProcedure = new HealthCloudGA__EHRProcedure__c(HealthCloudGA__Account__c=personAccList[0].Id);
            insert ehrProcedure;

            HealthCloudGA__EhrObservation__c ehrObsPCC = new HealthCloudGA__EhrObservation__c(Record__c=parentCase.Id, EHR_Procedure__c=ehrProcedure.Id, HealthCloudGA__Account__c=personAccList[0].Id, HealthCloudGA__IssuedDate__c=System.now()-2, Test_Result__c = '260415000');
            insert ehrObsPCC;
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateCloseContactClearanceWOBatchTest','setupTestData',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
    
    @IsTest
    static void Test_CloseContactWorkOrderBatchJob_AC01PBI265632() {
        try{
            List<Case> casesToUpdate = new List<Case>();
            HealthCloudGA__EhrObservation__c obs = [SELECT Id FROM HealthCloudGA__EhrObservation__c LIMIT 1];
            obs.HealthCloudGA__IssuedDate__c = System.now();
            update obs;

            Case parentCase = [SELECT Id,ContactId FROM Case WHERE Subject='Test Parent Case' LIMIT 1];
            parentCase.Latest_EHR_Observation__c = obs.Id;
            update parentCase;
            
            Test.startTest();
            Database.executeBatch(new GenerateCloseContactClearanceWOBatch(), 200);
            Test.stopTest();

            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.WO_SUBJECT_CC_CLEARANCE];
            System.assertEquals(1, workOrderList.size());
            
            List<Task> taskList = [SELECT Id,WhoId FROM Task WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.TASK_SUBJECT_CC_CLEARANCE_1];
            System.assertEquals(1, taskList.size());
            System.assertEquals(parentCase.ContactId, taskList[0].WhoId);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateCloseContactClearanceWOBatchTest','Test_CloseContactWorkOrderBatchJob_AC01PBI265632',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
    
    @IsTest
    static void Test_CloseContactWorkOrderBatchJob_ELRAttached_AC02PBI265632() {
        List<Case> casesToUpdate = new List<Case>();
        try{
            Case parentCase = [SELECT Id FROM Case WHERE Subject='Test Parent Case' LIMIT 1];
            parentCase.Latest_EHR_Observation__c = null;
            parentCase.Day_0_Exposure_to_the_confirmed_case__c = Date.today() - 17;
            parentCase.Day_15_Anticipated_release_date__c = Date.today() - 3;
            update parentCase;
            
            Test.startTest();
            Database.executeBatch(new GenerateCloseContactClearanceWOBatch(), 200);
            Test.stopTest();

            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.WO_SUBJECT_CC_CLEARANCE];
            System.assertEquals(1, workOrderList.size());
            
            List<Task> taskList = [SELECT Id FROM Task WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.TASK_SUBJECT_CC_CLEARANCE_3];
            System.assertEquals(0, taskList.size());   
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateCloseContactClearanceWOBatchTest','Test_CloseContactWorkOrderBatchJob_ELRAttached_AC02PBI265632',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    @IsTest
    static void Test_CloseContactWorkOrderBatchJob_ELRNotAttached_AC02PBI265632() {
        List<Case> casesToUpdate = new List<Case>();
        try{
            Case parentCase = [SELECT Id,ContactId FROM Case WHERE Subject='Test Parent Case' LIMIT 1];
            parentCase.Latest_EHR_Observation__c = null;
            parentCase.Day_0_Exposure_to_the_confirmed_case__c = Date.today() - 17;
            parentCase.Day_15_Anticipated_release_date__c = Date.today() - 3;
            update parentCase;

            HealthCloudGA__EhrObservation__c obs = [SELECT Id, Record__c FROM HealthCloudGA__EhrObservation__c LIMIT 1];
            obs.Record__c = null;
            update obs;

            Test.startTest();
            Database.executeBatch(new GenerateCloseContactClearanceWOBatch(), 200);
            Test.stopTest();

            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.WO_SUBJECT_CC_CLEARANCE];
            System.assertEquals(1, workOrderList.size());

            List<Task> taskList = [SELECT Id,WhoId FROM Task WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.TASK_SUBJECT_CC_CLEARANCE_3];
            System.assertEquals(1, taskList.size());
            System.assertEquals(parentCase.ContactId, taskList[0].WhoId);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateCloseContactClearanceWOBatchTest','Test_CloseContactWorkOrderBatchJob_ELRNotAttached_AC02PBI265632',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
    
    @IsTest
    static void Test_CloseContactWorkOrderBatchJob_AC03PBI265632() {
        List<Case> casesToUpdate = new List<Case>();
        try{
            HealthCloudGA__EhrObservation__c obs = [SELECT Id FROM HealthCloudGA__EhrObservation__c LIMIT 1];
            
            Case parentCase = [SELECT Id,ContactId, OwnerId FROM Case WHERE Subject='Test Parent Case' LIMIT 1];
            parentCase.Latest_EHR_Observation__c = obs.Id;
            parentCase.Day_0_Exposure_to_the_confirmed_case__c = Date.today() - 17;
            parentCase.Day_15_Anticipated_release_date__c = Date.today() - 3;
            update parentCase;
            
            Test.startTest();
            Database.executeBatch(new GenerateCloseContactClearanceWOBatch(), 200);
            Test.stopTest();

            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.WO_SUBJECT_CC_CLEARANCE];
            System.assertEquals(1, workOrderList.size());

            List<Task> taskList = [SELECT Id,WhoId FROM Task WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.TASK_SUBJECT_CC_CLEARANCE_2];
            System.assertEquals(1, taskList.size());
            System.assertEquals(parentCase.ContactId, taskList[0].WhoId);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateCloseContactClearanceWOBatchTest','Test_CloseContactWorkOrderBatchJob_AC03PBI265632',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    @IsTest
    static void Test_CloseContactWorkOrderBatchJobWorkOrderAndTaskAlreadyExist_AC03PBI265632() {
        List<Case> casesToUpdate = new List<Case>();
        

        try{
            HealthCloudGA__EhrObservation__c obs = [SELECT Id FROM HealthCloudGA__EhrObservation__c LIMIT 1];

            Case parentCase = [SELECT Id,ContactId, OwnerId FROM Case WHERE Subject='Test Parent Case' LIMIT 1];
            parentCase.Latest_EHR_Observation__c = obs.Id;
            parentCase.Day_0_Exposure_to_the_confirmed_case__c = Date.today() - 17;
            parentCase.Day_15_Anticipated_release_date__c = Date.today() - 3;
            update parentCase;

            WorkOrder wo = new WorkOrder(Status = GenerateCloseContactClearanceWOBatch.WO_STATUS_NEW,
                                        Priority = GenerateCloseContactClearanceWOBatch.WO_PRIORITY_LOW,
                                        RecordTypeId = GenerateCloseContactClearanceWOBatch.interviewWorkOrderClearanceRecordTypeId,
                                        Person_Interviewed__c = GenerateCloseContactClearanceWOBatch.WO_PERSON_INTERVIEWED_CC,
                                        Subject = GenerateCloseContactClearanceWOBatch.WO_SUBJECT_CC_CLEARANCE,
                                        CaseId = parentCase.Id,
                                        OwnerId = parentCase.OwnerId
                                        );
            insert wo;
            
            Task t = new Task(Status = GenerateCloseContactClearanceWOBatch.WO_STATUS_NEW, Priority = GenerateCloseContactClearanceWOBatch.WO_PRIORITY_LOW, 
                        OwnerId = parentCase.OwnerId, 
                            Subject = GenerateCloseContactClearanceWOBatch.TASK_SUBJECT_CC_CLEARANCE_2, 
                            WhatId = wo.Id,
                            WhoId=parentCase.ContactId);
            insert t;
            
            Test.startTest();
            Database.executeBatch(new GenerateCloseContactClearanceWOBatch(), 200);
            Test.stopTest();

            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.WO_SUBJECT_CC_CLEARANCE];
            System.assertEquals(1, workOrderList.size());
            
            List<Task> taskList = [SELECT Id,WhoId FROM Task WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.TASK_SUBJECT_CC_CLEARANCE_2];
            System.assertEquals(1, taskList.size());
            System.assertEquals(parentCase.ContactId, taskList[0].WhoId);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateCloseContactClearanceWOBatchTest','Test_CloseContactWorkOrderBatchJobWorkOrderAndTaskAlreadyExist_AC03PBI265632',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    @IsTest
    static void Test_CloseContactWorkOrderBatchJobWorkOrderAndTaskAlreadyExist_AC01PBI265387() {
        List<Case> casesToUpdate = new List<Case>();
        try{
            HealthCloudGA__EhrObservation__c obs = [SELECT Id FROM HealthCloudGA__EhrObservation__c LIMIT 1];

            Case parentCase = [SELECT Id,ContactId, OwnerId FROM Case WHERE Subject='Test Parent Case' LIMIT 1];
            parentCase.Latest_EHR_Observation__c = obs.Id;
            parentCase.Day_0_Exposure_to_the_confirmed_case__c = Date.today() - 17;
            parentCase.Day_15_Anticipated_release_date__c = Date.today() - 3;
            update parentCase;

            WorkOrder wo = new WorkOrder(Status = GenerateCloseContactClearanceWOBatch.WO_STATUS_NEW,
                                        Priority = GenerateCloseContactClearanceWOBatch.WO_PRIORITY_LOW,
                                        RecordTypeId = GenerateCloseContactClearanceWOBatch.interviewWorkOrderClearanceRecordTypeId,
                                        Person_Interviewed__c = GenerateCloseContactClearanceWOBatch.WO_PERSON_INTERVIEWED_CC,
                                        Subject = GenerateCloseContactClearanceWOBatch.WO_SUBJECT_CC_CLEARANCE,
                                        CaseId = parentCase.Id,
                                        OwnerId = parentCase.OwnerId
                                        );
            insert wo;

            Task t = new Task(Status = GenerateCloseContactClearanceWOBatch.WO_STATUS_NEW, Priority = GenerateCloseContactClearanceWOBatch.WO_PRIORITY_LOW,
                                OwnerId = parentCase.OwnerId, Subject = GenerateCloseContactClearanceWOBatch.TASK_SUBJECT_CC_CLEARANCE_1, 
                                WhatId = wo.Id,
                                WhoId=parentCase.ContactId);
            insert t;

            Test.startTest();
            Database.executeBatch(new GenerateCloseContactClearanceWOBatch(), 200);
            Test.stopTest();

            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.WO_SUBJECT_CC_CLEARANCE];
            System.assertEquals(1, workOrderList.size());

            List<Task> taskList = [SELECT Id,WhoId FROM Task WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.TASK_SUBJECT_CC_CLEARANCE_1];
            System.assertEquals(1, taskList.size());
            System.assertEquals(parentCase.ContactId, taskList[0].WhoId);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateCloseContactClearanceWOBatchTest','Test_CloseContactWorkOrderBatchJobWorkOrderAndTaskAlreadyExist_AC01PBI265387',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    @IsTest
    static void Test_CloseContactWorkOrderBatchJobWorkOrderAndTaskAlreadyExist_AC02PBI265387() {
        List<Case> casesToUpdate = new List<Case>();
        try{
            HealthCloudGA__EhrObservation__c obs = [SELECT Id FROM HealthCloudGA__EhrObservation__c LIMIT 1];

            Case parentCase = [SELECT Id,ContactId, OwnerId FROM Case WHERE Subject='Test Parent Case' LIMIT 1];
            parentCase.Latest_EHR_Observation__c = obs.Id;
            parentCase.Day_0_Exposure_to_the_confirmed_case__c = Date.today() - 17;
            parentCase.Day_15_Anticipated_release_date__c = Date.today() - 3;
            update parentCase;

            WorkOrder wo = new WorkOrder(Status = GenerateCloseContactClearanceWOBatch.WO_STATUS_NEW,
                                        Priority = GenerateCloseContactClearanceWOBatch.WO_PRIORITY_LOW,
                                        RecordTypeId = GenerateCloseContactClearanceWOBatch.interviewWorkOrderClearanceRecordTypeId,
                                        Person_Interviewed__c = GenerateCloseContactClearanceWOBatch.WO_PERSON_INTERVIEWED_CC,
                                        Subject = GenerateCloseContactClearanceWOBatch.WO_SUBJECT_CC_CLEARANCE,
                                        CaseId = parentCase.Id,
                                        OwnerId = parentCase.OwnerId
                                        );
            insert wo;

            Task t = new Task(Status = GenerateCloseContactClearanceWOBatch.WO_STATUS_NEW, Priority = GenerateCloseContactClearanceWOBatch.WO_PRIORITY_LOW, 
                            OwnerId = parentCase.OwnerId, Subject = GenerateCloseContactClearanceWOBatch.TASK_SUBJECT_CC_CLEARANCE_3, 
                            WhatId = wo.Id,
                            WhoId=parentCase.ContactId);
            insert t;

            Test.startTest();
            Database.executeBatch(new GenerateCloseContactClearanceWOBatch(), 200);
            Test.stopTest();

            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.WO_SUBJECT_CC_CLEARANCE];
            System.assertEquals(1, workOrderList.size());

            List<Task> taskList = [SELECT Id,WhoId FROM Task WHERE Status = 'New' AND Subject = :GenerateCloseContactClearanceWOBatch.TASK_SUBJECT_CC_CLEARANCE_3];
            System.assertEquals(1, taskList.size());
            System.assertEquals(parentCase.ContactId, taskList[0].WhoId);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateCloseContactClearanceWOBatchTest','Test_CloseContactWorkOrderBatchJobWorkOrderAndTaskAlreadyExist_AC02PBI265387',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}