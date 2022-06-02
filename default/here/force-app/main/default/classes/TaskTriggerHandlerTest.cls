/**
 * @Author             : marcelo.cost
 * @Description        : TaskTriggerHandlerTest
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 10/12/2020     marcelo.cost          Initial version
 * 16/03/2021     Nikhil Verma          254881: added testmethod to cover escalation tasks method handleEscalationsTasks()
 * 07/04/2021     Pratyush Chalasani    Feature 270255: PCC & SCC Case Allocation: WorkOrder & Task Record Owner
**/

@IsTest
private class TaskTriggerHandlerTest {

    @testSetup static void setupTestData() {
        TestDataFactory.createQAllocationForCaseRecordType();
        TestDataFactory.createQAllocationForWorkOrderRecordType();
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        User aUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = [SELECT ID FROM Profile WHERE Name = 'Integration User' LIMIT 1].Id, 
        TimeZoneSidKey='Australia/Sydney', UserName='standarduser@testorg.com.test');
        insert aUser;

        User adminUser = new User(Alias = 'admnusr', Email='tasktriggeruser@example.com', 
        EmailEncodingKey='UTF-8', LastName='Test User', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = [SELECT ID FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id, 
        TimeZoneSidKey='Australia/Sydney', UserName='user.sdoj3287wejf@example.com');
        insert adminUser;

        system.runAs(aUser) {
            Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                    PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
            insert acc;

            Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
            insert entl;

		String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
		Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
		AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today(), EntitlementId = entl.Id);
		insert cse;
		
		String caseRecordTypeId1 = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
		Case cse1 = new Case(recordTypeId = caseRecordTypeId1, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
		AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today(), EntitlementId = entl.Id);
		insert cse1;

		//String wrkOrdrInterviewId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByName().get('Interview').getRecordTypeId();
		String wrkOrdrInterviewId = SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
		WorkOrder wrkOrdr = new WorkOrder(recordTypeId =Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Close Contact Interview').getRecordTypeId() , Status = 'Not Started', CaseId = cse.Id, Subject = 'Test Work Order',
		AccountId = acc.Id, EntitlementId = entl.Id);
		insert wrkOrdr;
        }
    }

    @IsTest
    static void testTriggerHandler() {
        WorkOrder work = [Select Id from Workorder limit 1];
        Task t = new Task(WhatId = work.Id, TaskSubtype = 'Call', Status='Completed');
        Integer cseMilestones = [SELECT COUNT() FROM EntityMilestone WHERE ParentEntityId = :work.Id AND completionDate = null];
        System.debug('***WorkOrder Milestones:' + cseMilestones);
        Test.startTest();
        insert t;
        Test.stopTest();
        Integer cseMilestones2 = [SELECT COUNT() FROM EntityMilestone WHERE ParentEntityId = :work.Id AND completionDate = null];
    }

    @IsTest
    static void test_handleInitialInterviewCompleted() {
        Case aCase = [Select Id from CASE limit 1];
        Task aTask = new Task(WhatId = aCase.Id, TaskSubtype = 'Call', Status='Completed', Communication_Type__c='Call made via Genesys - Initial close contact campaign', Outcome__c='Successful',ActivityDate=System.today());

        User userForTesting = [SELECT Id FROM User WHERE Email = 'standarduser@testorg.com' LIMIT 1];
        system.runAs(userForTesting)  {
            Test.startTest();
            insert aTask;
            Test.stopTest();
        }

        //Assert
        List<WorkOrder> completedWorkOrder = [Select Id, Status, RecordTypeId, Subject from WorkOrder Where Subject = 'Initial close contact interview' and Status = 'Completed'];
        system.assertEquals(1, completedWorkOrder.size());

        List<WorkOrder> inProgressWorkOrder = [Select Id, Status, RecordTypeId, Subject from WorkOrder Where Subject = 'Close contact monitoring' and Status = 'In Progress'];
        system.assertEquals(1, inProgressWorkOrder.size());
    }

    @IsTest
    static void test_handleInitialInterviewCompletedBulk() {
        Case aCase = [Select Id from CASE limit 1];
        
		List<Task> taskList=new List<Task>();
		for(Integer i=0;i<100;i++){
			Task tRec=new Task();
			tRec.TaskSubtype='Call';
			tRec.Status='Completed';
			tRec.Communication_Type__c='Call made via Genesys - Initial close contact campaign';
			tRec.Outcome__c='Successful';
			tRec.ActivityDate=System.today();
			tRec.WhatId=aCase.Id;
			taskList.add(tRec);
		}

		
        User userForTesting = [SELECT Id FROM User WHERE Email = 'standarduser@testorg.com' LIMIT 1];
        system.runAs(userForTesting)  {
            Test.startTest();
            insert taskList;
            Test.stopTest();
        }

        
    }
    
    @isTest
    static void testEscalationTasks() {
        Case varC = [SELECT Id FROM Case LIMIT 1];
        Id commRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Communication').getRecordTypeId();
        
        Test.startTest();
        Task newTask = new Task(RecordTypeId = commRecTypeId, WhatId = varC.Id, Escalated__c = 'Yes', 
                                Subject = 'Escalated - Call made via Genesys',
                                Description = 'Escalation: REFUSED_INTERVIEW | Escalation Notes: Long Description');
        insert newTask;
        Test.stopTest();
        Task varT = [SELECT Id, Subject, Description FROM Task WHERE Subject = 'Escalated - Call made via Genesys' LIMIT 1];
        System.assertEquals(false, varT.Description.contains('|'));
    }

    @isTest
    static void testSetOwnerFromCase() {
        Test.startTest();
        List<Account> accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        Case pcc = TestDataFactory.createCases(accs[0], 1, 'Isolate', 'Close Contact')[0];

        Id caseOwnerID = [SELECT OwnerId FROM Case WHERE Id = :pcc.Id].OwnerId;

        User otherUser = [SELECT Id FROM User WHERE Email = 'tasktriggeruser@example.com'];

        System.assertNotEquals(caseOwnerID, otherUser.Id, 'Case owner and temp user should be different');

        

        CaseTriggerHelper.CASE_TRIGGER_UPDATING_OWNERS = false;

        Task t1 = new Task(Subject = 'Interview', Status = 'Not Started', WhatId = pcc.Id, OwnerId = otherUser.Id, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId(), Escalated__c = 'No', Queue_Id__c = null);

        insert t1;

        Task t2 = new Task(Subject = 'Log a Call', Status = 'Not Started', WhatId = pcc.Id, OwnerId = otherUser.Id, Manually_Allocated__c = true, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Log_A_Call').getRecordTypeId(), Escalated__c = 'No', Queue_Id__c = null);

        insert t2;
        
        t1 = [SELECT Id, OwnerId FROM Task WHERE Id = :t1.Id];
        t2 = [SELECT Id, OwnerId FROM Task WHERE Id = :t2.Id];
		Test.stopTest();

        System.assertEquals(caseOwnerID, t1.OwnerId, 'Owner of Task1 should match Case');

        System.assertNotEquals(caseOwnerID, t2.OwnerId, 'Owner of Task2 should not match Case');
    }
	
	@IsTest
    static void testTriggerHandler1() {
        Case testCases1 = [SELECT Id FROM Case WHERE recordType.Name = 'Close Contact' limit 1];
        Id taskRT = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosByName().get('Clearance').getRecordTypeId();

        Task t1 = new Task(WhatId = testCases1.Id, TaskSubtype = 'Call', recordTypeId = taskRT, Was_the_case_ever_symptomatic__c = 'Yes');
        try{
            insert t1;
        }catch(Exception ex){
            system.assertEquals('For a close contact you cannot update confirmed case clearance details.', ex.getDmlMessage(0));
        }
    }

    @IsTest
    static void testTriggerHandler2() {
        Case testCases2 = [SELECT Id FROM Case WHERE recordType.Name = 'COVID-19 Case Assessment' limit 1];
        Id taskRT = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosByName().get('Clearance').getRecordTypeId();
        
        Task t2 = new Task(WhatId = testCases2.Id, TaskSubtype = 'Call', recordTypeId = taskRT, Contact_currently_have_any_symptoms__c = 'Yes');
        try{
            insert t2;
        }catch(Exception ex){
            system.assertEquals('For a confirmed case you cannot update close contact clearance details.', ex.getDmlMessage(0));
        }
    }

    @IsTest
    static void testTriggerHandler3() {
        Case testCases1 = [SELECT Id FROM Case WHERE recordType.Name = 'Close Contact' limit 1];
        Id taskRT = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosByName().get('Clearance').getRecordTypeId();

        Task t1 = new Task(WhatId = testCases1.Id, TaskSubtype = 'Call', recordTypeId = taskRT);
        insert t1;

        try{
            t1.X12_Are_symptoms_significantly_improved__c = 'Yes';
            update t1;
        }catch(Exception ex){
            system.assertEquals('For a close contact you cannot update confirmed case clearance details.', ex.getDmlMessage(0));
        }
    }

    @IsTest
    static void testTriggerHandler4() {
        Case testCases2 = [SELECT Id FROM Case WHERE recordType.Name = 'COVID-19 Case Assessment' limit 1];
        Id taskRT = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosByName().get('Clearance').getRecordTypeId();
        
        Task t2 = new Task(WhatId = testCases2.Id, TaskSubtype = 'Call', recordTypeId = taskRT);
        insert t2;

        try{
            t2.Any_household_contacts_symptomatic__c = 'Yes';
            update t2;
        }catch(Exception ex){
            system.assertEquals('For a confirmed case you cannot update close contact clearance details.', ex.getDmlMessage(0));
        }
    }
}