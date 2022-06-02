/**
 * @Author             : Chris Zhuang
 * @Description        : Test Class for CloseContactWorkOrderBatchJob
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 16/03/2021     Chris Zhuang          Feature 269161: All interview work orders should be automatically be created when new confirmed case or new primary close contact record is created - Part 3 (AC03)
**/
@isTest
private class CloseContactWorkOrderBatchJobTest {
    @testSetup
    static void setupTestData() {
        try{
            Id closeContactClearanceRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
            Id secondaryCloseContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
            //Create Person Accounts
            //reduce this to 10 as we will reach apex limiataion if we create 50 records
            List<Account> personAccList = TestDataFactory.createAccount(10, 'Active','Person Account');

            //Create Parent Case
            Case parentCase = new Case(recordTypeId=closeContactClearanceRecordTypeId, Status='Identify', Subject='Test Parent Case', AccountId=personAccList[0].Id, Date_Cleared_from_Isolation__c=System.now());
            insert parentCase;

            //create HealthCloudGA__EHRProcedure__c
            HealthCloudGA__EHRProcedure__c ehrProcedure = new HealthCloudGA__EHRProcedure__c(HealthCloudGA__Account__c=personAccList[0].Id);
            insert ehrProcedure;
            
            //create HealthCloudGA__EhrObservation__c
            HealthCloudGA__EhrObservation__c ehrObsPCC = new HealthCloudGA__EhrObservation__c(Record__c=parentCase.Id, EHR_Procedure__c=ehrProcedure.Id, HealthCloudGA__Account__c=personAccList[0].Id, HealthCloudGA__IssuedDate__c=System.now()-2, Test_Result__c = '260415000');
            insert ehrObsPCC;
            
            //Create Cases
            List<Case> caseListConfirmed = TestDataFactory.createCasePerAccount(personAccList, 'Identify', '', secondaryCloseContactRecordTypeId);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('CloseContactWorkOrderBatchJobTest','setupTestData',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    @IsTest
    static void Test_CloseContactWorkOrderBatchJob_AC32() {
        List<Case> casesToUpdate = new List<Case>();
        try{
            HealthCloudGA__EhrObservation__c obs = [Select id from HealthCloudGA__EhrObservation__c limit 1];
            Case parentCase = [Select id from Case Where Subject='Test Parent Case' limit 1];
            parentCase.Latest_EHR_Observation__c = obs.Id;
            //parentCase.Date_Cleared_from_Isolation__c=System.now();
            parentCase.Status='Closed';
            parentCase.SubStatus__c='Release';
            update parentCase;

            //create record for Acceptance Criteria 03.1 (No SCC found for PCC)
            List<Case> childCase = [Select id, ParentId, On_going_exposure__c, Latest_EHR_Observation__c from Case Where Subject != 'Test Parent Case'];
            childCase[0].ParentId = parentCase.Id;
            childCase[0].On_going_exposure__c = FALSE;
            childCase[0].Day_0_Exposure_to_primarycc__c = System.today() - 20;
            casesToUpdate.add(childCase[0]);
            update casesToUpdate;

            ContactEncounter ceRecord = new ContactEncounter(Name='Private residence – home', StartTime=System.Now(), Record__c=childCase[0].Id); 
            insert ceRecord;
        
            ContactEncounterParticipant cepRecord = new ContactEncounterParticipant(ContactEncounterId=ceRecord.Id, Contact_Type__c = 'Secondary Close Contact', Record__c = childCase[0].Id,  Parent_Record__c = parentCase.Id);
            insert cepRecord;
            
            Test.startTest();
            Database.executeBatch(new CloseContactWorkOrderBatchJob(), 200);
            Test.stopTest();

            // Verify workorder created
            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder WHERE Status = 'New' AND Subject = 'Secondary Close Contact Clearance'];
            System.assertEquals(1, workOrderList.size(), 'AC3.1 - Secondary Close Contact Clearance workorder has been created');
        }catch(Exception exp){
            ApplicationLogUtility.createlog('CloseContactWorkOrderBatchJobTest','Test_CloseContactWorkOrderBatchJob_AC32',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    @IsTest
    static void Test_CloseContactWorkOrderBatchJob_AC32_FAILD() {
        List<Case> casesToUpdate = new List<Case>();
        
        try{
            HealthCloudGA__EhrObservation__c obs = [Select id from HealthCloudGA__EhrObservation__c limit 1];
        
            Case parentCase = [Select id from Case Where Subject='Test Parent Case' limit 1];
            parentCase.Latest_EHR_Observation__c = obs.Id;
            update parentCase;

            //create record for Acceptance Criteria 03.1 (No SCC found for PCC)
            List<Case> childCase = [Select id, ParentId, Latest_EHR_Observation__c from Case Where Subject != 'Test Parent Case'];
            childCase[0].ParentId = parentCase.Id;
            casesToUpdate.add(childCase[0]);
            update casesToUpdate;

            ContactEncounter ceRecord = new ContactEncounter(Name='Private residence – home', StartTime=System.Now(), Record__c=childCase[0].Id); 
            insert ceRecord;
            
            ContactEncounterParticipant cepRecord = new ContactEncounterParticipant(ContactEncounterId=ceRecord.Id, Contact_Type__c = 'Secondary Close Contact', On_going_exposure__c = TRUE);
            insert cepRecord;

            Test.startTest();
            Database.executeBatch(new CloseContactWorkOrderBatchJob(), 200);
            Test.stopTest();

            // Verify workorder created
            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder WHERE Status = 'New' AND Subject = 'Secondary Close Contact Clearance'];
            System.assertEquals(0, workOrderList.size(), 'No workorder has been created.');

        }catch(Exception exp){
            ApplicationLogUtility.createlog('CloseContactWorkOrderBatchJobTest','Test_CloseContactWorkOrderBatchJob_AC32_FAILD',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}