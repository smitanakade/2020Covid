/**
 * Created by Suraj on 09/03/2021.
 */

@IsTest
private class WorkOrderTriggerHelperTest {
    
    @TestSetup
    static void setupTestData(){
        User adminUser = new User(Alias = 'admnusr', Email='workorderuser@example.com', 
        EmailEncodingKey='UTF-8', LastName='Test User', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = [SELECT ID FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id, 
        TimeZoneSidKey='Australia/Sydney', UserName='user.w7632hwlk@example.com');

        insert adminUser;
    }

    @IsTest
    static void checkInterviewWorkOrderTest() {
        List<Account> accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        Case testCase = new Case();
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
        testCase.AccountId = accs[0].Id;
        testCase.Case_Classification__c = 'Confirmed';
        insert testCase;
    }

    @IsTest
    static void Test_createSCCMonitoringWorkOrders_001() {

      
        //Id confirmedCaseRecordTypeId = CaseTriggerHelper.WORKORDER_CONFIRMEDCASE_RECORD_TYPE_ID;
        //Create Person Account
        List<Account> personAccList = TestDataFactory.createAccount(5, 'Active','Person Account');

        Test.StartTest();
        //Create Case
        List<Case> caseListConfirmed = TestDataFactory.createCasePerAccount(personAccList, 'Identify', 'In Progress', CaseTriggerHelper.CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE);

       
        Map<Id,Case> caseIdsToCases = new Map<Id,Case>();
        for(Case record : caseListConfirmed) {
            caseIdsToCases.put(record.Id, record);
        }
        Test.StopTest();
       
        // retrieve created work orders on the after update trigger of the case
        List<WorkOrder> workOrders = [
                SELECT  Id, CaseId, AccountId, ContactId, Priority,
                        Status, Subject, Person_Interviewed__c,
                        OwnerId, RecordTypeId
                FROM WorkOrder
                WHERE CaseId =: caseIdsToCases.keySet()
        ];
      
        system.assertEquals(5, workOrders.size());

        for(WorkOrder wo : workOrders) {
            wo.Status = 'completed ';
            System.assertEquals(CaseTriggerHelper.WORKORDER_SCC_INTERVIEW_RECORD_TYPE_ID, wo.RecordTypeId);
        }
        update workOrders;
      
        List<WorkOrder> workOrdersToCheck = [
                SELECT  Id, CaseId, AccountId, ContactId, Priority,
                        Status, Subject, Person_Interviewed__c,
                        OwnerId, RecordTypeId, RecordType.Name
                FROM WorkOrder
                WHERE CaseId =: caseIdsToCases.keySet()
                AND RecordTypeId =: WorkOrderTriggerHelper.SCCMonitoringWorkOrderRecordTypeId
        ];

        for(WorkOrder wo : workOrdersToCheck) {
            System.assertEquals(WorkOrderTriggerHelper.WO_PRIORITY_LOW, wo.Priority);
            System.assertEquals(WorkOrderTriggerHelper.WO_PERSON_INTERVIEWED_SSC, wo.Person_Interviewed__c);
            System.assertEquals(WorkOrderTriggerHelper.WO_STATUS_NEW, wo.Status);
            System.assertEquals(caseIdsToCases.get(wo.CaseId).AccountId, wo.AccountId);
            System.assertEquals(caseIdsToCases.get(wo.CaseId).ContactId, wo.ContactId);
            System.assertEquals(caseIdsToCases.get(wo.CaseId).OwnerId, wo.OwnerId);
        }
        system.assertEquals(5, workOrdersToCheck.size());
    }

    @isTest
    static void testSetOwnerFromCase() {
        List<Account> accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        Case pcc = TestDataFactory.createCases(accs[0], 1, 'Isolate', 'Close Contact')[0];

        Case confirmed = TestDataFactory.createCases(accs[0], 1, 'Isolate', 'COVID-19 Case Assessment')[0];

        Id caseOwnerID = [SELECT OwnerId FROM Case WHERE Id = :pcc.Id].OwnerId;

        Id pccOwnerID = [SELECT OwnerId FROM Case WHERE Id = :pcc.Id].OwnerId;
        Id confirmedOwnerID = [SELECT OwnerId FROM Case WHERE Id = :confirmed.Id].OwnerId;

        User otherUser = [SELECT Id FROM User WHERE Email = 'workorderuser@example.com'];

        System.assertNotEquals(pccOwnerID, otherUser.Id, 'Case owner and temp user should be different');
        System.assertNotEquals(confirmedOwnerID, otherUser.Id, 'Case owner and temp user should be different');

        Test.startTest();

        CaseTriggerHelper.CASE_TRIGGER_UPDATING_OWNERS = false;

        WorkOrder w1 = new WorkOrder(CaseId = pcc.Id, Status = 'New', RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Interview').getRecordTypeId());

        insert w1;

        WorkOrder w2 = new WorkOrder(CaseId = confirmed.Id, Status = 'New', RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('HEP_Referral').getRecordTypeId());

        insert w2;

        WorkOrder w3 = new WorkOrder(CaseId = pcc.Id, Status = 'New', Manually_Allocated__c = true, RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Interview').getRecordTypeId());

        insert w3;

        WorkOrder w4 = new WorkOrder(CaseId = confirmed.Id, Status = 'New', RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId());

        insert w4;

        WorkOrder w5 = new WorkOrder(CaseId = confirmed.Id, Status = 'New', RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Confirmed_Case_Monitoring_Work_Order').getRecordTypeId());

        insert w5;

        WorkOrder w6 = new WorkOrder(CaseId = PCC.Id, Status = 'New', RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId());

        insert w6;

        Boolean errorDisplayed = false;

        try { //#294010
            WorkOrder w7 = new WorkOrder(CaseId = null, Status = 'New', RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Interview').getRecordTypeId());
            insert w7;
        } catch (Exception e) {
            errorDisplayed = e.getMessage().contains('Record is required to create a work order when Manually Allocated checkbox is not ticked');
        }

        Test.stopTest();

        w1 = [SELECT Id, OwnerId FROM WorkOrder WHERE Id = :w1.Id];
        w2 = [SELECT Id, OwnerId FROM WorkOrder WHERE Id = :w2.Id];
        w3 = [SELECT Id, OwnerId FROM WorkOrder WHERE Id = :w3.Id];
        w4 = [SELECT Id, OwnerId FROM WorkOrder WHERE Id = :w4.Id];
        w5 = [SELECT Id, OwnerId FROM WorkOrder WHERE Id = :w5.Id];
        w6 = [SELECT Id, OwnerId FROM WorkOrder WHERE Id = :w6.Id];

        System.assertEquals(pccOwnerID, w1.OwnerId, 'Owner of WorkOrder1 should match Case (PCC <-> Close Contact Interview');
        System.assertEquals(confirmedOwnerID, w2.OwnerId, 'Owner of WorkOrder2 should match Case (Confirmed <-> HEP Referral)');
        System.assertNotEquals(pccOwnerID, w3.OwnerId, 'Owner of WorkOrder3 should not match Case (PCC <-> Close Contact Interview, Manually allocated)');
        System.assertEquals(confirmedOwnerID, w4.OwnerId, 'Owner of WorkOrder4 should match Case (Confirmed <-> Confirmed Case Interview)');
        System.assertEquals(confirmedOwnerID, w5.OwnerId, 'Owner of WorkOrder5 should match Case (Confirmed <-> Confirmed Case Monitoring)');
        System.assertNotEquals(pccOwnerID, w6.OwnerId, 'Owner of WorkOrder6 should not match Case (PCC <-> Confirmed Case Interview, Mismatched record types)');
        System.assertEquals(true, errorDisplayed, 'Error message should be displayed when CaseId is null');
    }

     @IsTest
    static void Test_Default_Subject_ExHQ() {
        //Create Person Account
        List<Account> personAccList = TestDataFactory.createAccount(5, 'Active','Person Account');

        Test.StartTest();
        //Create Case
        //282278: Updated Status to "Active" and Substatus to null
        List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Active', 'Casual Contact');
        caseListExp[0].SubStatus__c = null;
        insert caseListExp;

        //create test workorder
        Id HQWoRecTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Ex_Hotel_Quarantine_Resident_Monitoring').getRecordTypeId();
        insert new Workorder(CaseId = caseListExp[0].Id,
                             RecordTypeId = HQWoRecTypeId
							);
        
        //since we dint provide subject, assert default subject is populated from cust label
        List<WorkOrder> workOrdersToCheck = [
                SELECT  Id, Subject
                FROM WorkOrder
                WHERE CaseId =: caseListExp[0].Id
        ];

        
		        
        System.assertEquals(System.label.Work_Order_HQ_Subject_Line, workOrdersToCheck[0].Subject, 'Default Subject should be same as custom label');

    }
    
     @IsTest
    static void Test_Subject_ExHQ() {
        //Create Person Account
        List<Account> personAccList = TestDataFactory.createAccount(5, 'Active','Person Account');

        Test.StartTest();
        //Create Case
        //282278: Updated Status to "Active" and Substatus to null
        List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Active', 'Casual Contact');
        caseListExp[0].SubStatus__c = null;
        insert caseListExp;

        //create test workorder
        Id HQWoRecTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Ex_Hotel_Quarantine_Resident_Monitoring').getRecordTypeId();
        insert new Workorder(CaseId = caseListExp[0].Id,
                             RecordTypeId = HQWoRecTypeId,
                             Subject = 'Testclass Subject'
							);
        
        //since we provide subject, assert default subject is populated
        List<WorkOrder> workOrdersToCheck = [
                SELECT  Id, Subject
                FROM WorkOrder
                WHERE CaseId =: caseListExp[0].Id
        ];

        
		        
        System.assertEquals('Testclass Subject', workOrdersToCheck[0].Subject, 'Subject should be same as testdata');

    }

    @isTest
static void Test_GenerateInterviewWorkOrdersBatchTest_001() {
        //Create Person Accounts
        List<Account> personAccList = TestDataFactory.createAccount(50, 'Active','Person Account');
        //Create Cases
        Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
        List<Case> caseListConfirmed = TestDataFactory.createCasePerAccount(personAccList, 'Identity', '', confirmedCaseRecordTypeId);
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
		/*
        System.assertEquals(
                50
                , workOrders.size()
                , 'Test_GenerateInterviewWorkOrdersBatchTest_001 : Expecting work orders with Confirmed_Case_Clearance record type'
        );
*/
    }


    @isTest
    static void Test_copyInterviewDetailsToCase(){

        //Create Person Account
       // List<Account> personAccList = TestDataFactory.createAccount(5, 'Active','Person Account');

        //Create Case
        //List<Case> caseListConfirmed = TestDataFactory.createCasePerAccount(personAccList, 'Trace', CaseTriggerHelper.CASE_COVID_19_ASSESSMENT_RECORD_TYPE);
        
        List<Account> accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        Case confirmed = TestDataFactory.createCases(accs[0], 1, 'Isolate', 'COVID-19 Case Assessment')[0];
        WorkOrder wo = new WorkOrder(CaseId = confirmed.Id, Status = 'In Progress', RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId());
        insert wo;
        WorkOrder wo1 = [SELECT Id, Interviewed_By__c, Person_Interviewed__c FROM WorkOrder WHERE Id = :wo.Id];
        wo1.Interviewed_By__c = 'Test Interviewer';
        wo1.Person_Interviewed__c = 'Other';
        //update workorder
        update wo1;
        
        Case confirmedCase = [SELECT Id, Interviewed_By__c, Person_Interviewed__c FROM Case WHERE Id =: confirmed.Id];
        System.assertEquals('Test Interviewer', confirmedCase.Interviewed_by__c);
        System.assertEquals('Other', confirmedCase.Person_Interviewed__c);
       // Test.startTest()
        
      //  Test.stopTest()
        }
}