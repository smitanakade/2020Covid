/**
 * @description       :  
 * @author            : DHHS
 * @group             : 
 * @last modified on  : 11-12-2021
 * @last modified by  : DHHS
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   04-20-2021   DHHS                                 Initial Version
 * 2.0   29-06-2021   Pratyush Chalasani                   Backported changes from release/prod1 to release/staging-sprint7
 * 3.0   29/09/2021   Mayukhman Pathak                     Feature 273382: Create New Workorder for Day 14 Confirmed Case Clearance
 * 4.0   29-09-2021   Sukumar Salla                        PBI 313212: MC - PCC initial notifications
 * 4.1   15-10-2021   Aref Samad                           PBI 326876 - Case Changed to Confirmed(Refactoring 2.0 - Rework of Sprint 10 PBI)
 * 4.2   8-11-2021    Krishna Suram                        PBI:333814 DVR Integration - call platform API to publish DVR Option 1 search to Mystery Case Tracker                                                        Added unit test for processConfirmedRecordsAsync  
 **/
@isTest
private class CaseTriggerHelperTest { 
    private static Id accountRecordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
    private static Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
    private static Id secondaryCloseContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
    private static Id cepCloseConRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();        
    private static Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
    private static Id casualConRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Casual_Contact').getRecordTypeId();        
       
    @testSetup
    static void setupTestData() {
        List<Case> testCases = new List<Case>();
        Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='Test FName', LastName='Test LName',PersonMailingStreet='101 Collins Street',
                                            PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test@gmail.com', PersonHomePhone='1234567',PersonMobilePhone='+614444');
        insert accountRecord;
        
        Id contactId = [Select PersonContactId from Account where Id=:accountRecord.Id][0].PersonContactId;
        
        Case closeContact = new Case(recordTypeId=closeContactRecordTypeId ,Status='Quarantine' ,SubStatus__c='In Progress',Subject='Test',
                                     AccountId=accountRecord.Id, Day_0_Exposure_to_the_confirmed_case__c=System.Today()-6);
        testCases.add(closeContact);
        
        Case secondaryCloseContact = new Case(recordTypeId=secondaryCloseContactRecordTypeId ,Status='Isolate',Subject='Test Case - Assignment Rule',
                                              AccountId=accountRecord.Id, Symptoms_Onset_Date__c=System.Today());
        testCases.add(secondaryCloseContact);
        
        Case confirmedCase = new Case(recordTypeId=confirmedCaseRecordTypeId ,Status='Quarantine' ,SubStatus__c='In Progress',Subject='Test',
                                     AccountId=accountRecord.Id, Confirmation_Date__c=System.Today()-6);
        testCases.add(confirmedCase);
        
        ContactEncounter ceRecord = new ContactEncounter(RecordTypeId=cepCloseConRecordTypeId, Name='Private residence – home', StartTime=System.Now(), Record__c=secondaryCloseContact.Id ); 
        insert ceRecord;
        
        ContactEncounterParticipant cepRecord = new ContactEncounterParticipant(Record__c=secondaryCloseContact.Id , Parent_Record__c=closeContact.Id, 
                                                                                ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        insert cepRecord;
        insert  testCases;
    }
    
    @isTest
    static void createInterviewWorkOrdersNewTest(){        
        Account acc = [Select Id from Account LIMIT 1];

        Case testCase = new Case();
        testCase.RecordTypeId = confirmedCaseRecordTypeId;
        testCase.AccountId = acc.Id;
        testCase.Case_Classification__c = 'Confirmed';
        insert testCase;

        Case testCase1 = new Case();
        testCase1.RecordTypeId = confirmedCaseRecordTypeId;
        testCase1.AccountId = acc.Id;
        testCase1.Case_Classification__c = null;
        insert testCase1;

        testCase1.Case_Classification__c = 'Confirmed';
        update testCase1;
    }

    @isTest
    static void testSecondaryCloseContact(){        
        Case closeContactCase = [Select Id, RecordTypeId, Day_0_Exposure_to_primarycc__c, Day_0_Exposure_to_the_confirmed_case__c, Parent_Record_Released__c from Case where RecordType.DeveloperName ='Close_Contact' limit 1];
        closeContactCase.Day_0_Exposure_to_primarycc__c = System.today();
        update closeContactCase;
        Case otherCase = new Case(Day_0_Exposure_to_primarycc__c = System.today() - 3);
        Map<Id, Case> mapCase = new Map<Id, Case>();
        mapCase.put(closeContactCase.Id, otherCase);
        CaseTriggerHelper.copyPccDatesToScc(new List<Case>{closeContactCase}, mapCase);
    }

    @isTest
    static void exposureManagementSetDeclaredDate() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Exposure Management');
        System.assertEquals(caseListExp[0].createdDate, caseListExp[0].DHHS_Declared_Date__c, 'Declared Date should be set to the same as CreatedDate');
    }
    
    @isTest
    static void handleSccToPccRecordTypeChangeTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Secondary Close Contact');
        System.assertNotEquals('At Risk', caseListExp[0].Event_Classification__c, 'Event Classification was set to At Risk even before the test ran');
        
        caseListExp[0].RecordTypeId = CaseTriggerHelper.CASE_CLOSE_CONTACT_RECORD_TYPE;
        update caseListExp;
        Case updated_record = [SELECT Id, Case_Classification__c, Case_Found_By__c, Epi_Classification__c, Initial_Interview_completed__c, Initial_Interview_Completed_Time__c, Status, SubStatus__c FROM Case WHERE ID =: caseListExp[0].Id LIMIT 1];
        System.assertEquals('At Risk', updated_record.Case_Classification__c, 'Event Classification did not change to At Risk');
        System.assertEquals('Contact Tracing', updated_record.Case_Found_By__c, 'Case_Found_By__c did not change to Contact Tracing');
        System.assertEquals('Epidemiologically linked to a laboratory confirmed case', updated_record.Epi_Classification__c, 'Epi_Classification__c did not change');
        System.assertEquals(false, updated_record.Initial_Interview_completed__c, 'Initial_Interview_completed__c did not change to false');
        System.assertEquals(null, updated_record.Initial_Interview_Completed_Time__c, 'Initial_Interview_Completed_Time__c is not null');
        System.assertEquals('Quarantine', updated_record.Status, 'Status is not Quarantine');
        System.assertEquals('In Progress', updated_record.SubStatus__c, 'SubStatus__c did not change to In Progress ');
        
    }
    
    @isTest
    static void updateDetailsOnOutbreakChangeTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 2, 'Isolate', 'Exposure Management');
        CaseTriggerHandler.SkipUpdate = false;

        Case exposureRecord = caseListExp[1];
        exposureRecord.Setting_type__c = 'Hospitality and Entertainment';
        update exposureRecord;
        CaseTriggerHandler.SkipUpdate = false;

        Case mainRecord = [SELECT ID, Setting_type__c, Outbreak_record__c from Case WHERE Id =: caseListExp[0].Id LIMIT 1];
        System.assertEquals(null, mainRecord.Setting_type__c, 'Before the records are linked, Setting Type should be blank');
        mainRecord.Outbreak_record__c = exposureRecord.Id;
        update mainRecord;
        CaseTriggerHandler.SkipUpdate = false;
        
        mainRecord = [SELECT ID, Outbreak_Setting_Type__c, Outbreak_record__c from Case WHERE Id =: mainRecord.Id LIMIT 1];
        System.assertEquals(exposureRecord.Setting_type__c, mainRecord.Outbreak_Setting_Type__c, 'Main Record should have updated its setting type');
    }
     @isTest
    static void updateForcastDateOnDayZeroChangeTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Close Contact');
        Case exposureRecord = caseListExp[0];
        exposureRecord = [SELECT ID, Symptoms_Onset_Date__c, Day_15_Anticipated_release_date__c, Day_0_Calculated__c,Day_0_Exposure_to_the_confirmed_case__c  FROM Case WHERE Id =: exposureRecord.Id];
        exposureRecord.Day_0_Exposure_to_the_confirmed_case__c = System.Today() + 1;
        
        update exposureRecord;
        exposureRecord = [SELECT ID, Symptoms_Onset_Date__c, Day_15_Anticipated_release_date__c, Day_0_Calculated__c FROM Case WHERE Id =: exposureRecord.Id];
        System.assertEquals(exposureRecord.Day_0_Calculated__c.addDays(14), exposureRecord.Day_15_Anticipated_release_date__c, 'Day_15_Anticipated_release_date__c is wrong');
        
    }
    @isTest
    static void createWorkOrderOnInitialInterviewTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        CaseTriggerHandler.SkipUpdate = false;

        Case caseRecord = caseListExp[0];
        List<WorkOrder> workOrders = [SELECT ID From WorkOrder WHERE CaseId =: caseRecord.Id];
        Integer initialWorkOrderSize = workOrders.size();
        
        // Make sure unrelated changes aren't creating a work order to be created
        caseRecord.Symptoms_Onset_Date__c = System.Today() + 1;
        update caseRecord;
        CaseTriggerHandler.SkipUpdate = false;
        
        workOrders = [SELECT ID From WorkOrder WHERE CaseId =: caseRecord.Id];
        System.assertEquals(initialWorkOrderSize, workOrders.size(), 'A workorder was created even when an unrelated field was edited');
        
        Test.startTest();

        caseRecord.Initial_Interview_completed__c = true;
        update caseRecord;
        CaseTriggerHandler.SkipUpdate = false;
        
        Test.stopTest();

        //#302967: Testing for WorkOrder owner to be same as Case owner
        workOrders = [SELECT ID, Subject, OwnerId, Case.OwnerId From WorkOrder WHERE CaseId =: caseRecord.Id AND Subject = 'Confirmed Case monitoring'];
        System.assertEquals(1, workOrders.size(), 'a single Work order was not created on Initial Interview Completed');
        System.assertEquals(workOrders[0].Case.OwnerId, workOrders[0].OwnerId, 'WorkOrder owner should be the same as the parent Case owner');
        
    }
    @isTest
    static void updateClearanceEligibilityDateTest(){
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        Case caseRecord = caseListExp[0];
        
        //create a Health Care Encounter
        List<HealthCloudGA__EhrEncounter__c> encounters = TestDataFactory.createHospitalRecordsForCases(caseListExp, 'Hospital admission', Date.today());
        
        System.assertEquals(1, encounters.size(), 'Expected to get a list of 1 encounter created for the case. Are there more than one case or is the encounter insert failing?');
        caseRecord.Case_Classification__c = 'Confirmed';
        //Test: should not update yet
        caseRecord = [SELECT ID, Clearance_eligibility_assessment_date__c, Calculated_Onset_Date__c FROM Case WHERE Id =: caseRecord.Id LIMIT 1];
        Date originalDate = caseRecord.Clearance_eligibility_assessment_date__c;
        System.debug('original date is: ' + originalDate);
        
        caseRecord.Initial_Interview_Completed__c = true;
        update caseRecord;
        
        caseRecord = [SELECT ID,  Symptoms_Onset_Date__c, Clearance_eligibility_assessment_date__c FROM Case WHERE Id =: caseRecord.Id LIMIT 1];
        System.debug('updated date is: ' + caseRecord.Clearance_eligibility_assessment_date__c);
        // System.assertNotEquals(originalDate, caseRecord.Clearance_eligibility_assessment_date__c);
        //Case WITH Encounter AND SEVERLY ILL => add 10 Days to
        
        caseRecord.Symptoms_Onset_Date__c = Date.today();
        update caseRecord;
        caseRecord = [SELECT ID, Symptoms_Onset_Date__c, Clearance_eligibility_assessment_date__c, Calculated_Onset_Date__c FROM Case WHERE Id =: caseRecord.Id LIMIT 1];
        System.debug('updated date is: ' + caseRecord.Clearance_eligibility_assessment_date__c);
       // System.assertEquals(caseRecord.Calculated_Onset_Date__c.addDays(10), caseRecord.Clearance_eligibility_assessment_date__c);
       //System.assertEquals(Date.newInstance(caseRecord.Calculated_Onset_Date__c.addDays(14).year(),caseRecord.Calculated_Onset_Date__c.addDays(14).month(),caseRecord.Calculated_Onset_Date__c.addDays(14).day()), caseRecord.Clearance_eligibility_assessment_date__c);
    }
    
    @isTest
    static void handlePersonAccountAddedTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Account> businessAccList = TestDataFactory.createAccount(1, 'Active','Clinic');
        List<Contact> businessContact = TestDataFactory.createContact(businessAccList);
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        Case caseRecord = caseListExp[0];
        
        // If The Case is New AND there is no ContactId, the contactId should be added on inset
        System.assertEquals(personAccList.get(0).PersonContactId, caseRecord.ContactId);
        
        // IF the case is changed AND Account is changed AND Contact is not Changed
        caseRecord.AccountId = businessAccList.get(0).Id;
        update caseRecord;
        caseRecord = [SELECT ID, ContactId, AccountId FROM Case WHERE Id =: caseRecord.Id LIMIT 1];
        System.assertEquals(businessAccList.get(0).PersonContactId, caseRecord.ContactId, 'person account should be null');
        
        //List<Case> BusinesscaseList = TestDataFactory.createCases(businessAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        System.assertEquals(businessAccList.get(0).PersonContactId, caseRecord.ContactId, 'person account should be null');
    }
    
    @isTest
    static void addHistoryAndEntitlementsTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListContact = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Close Contact');
        List<Case> caseListCovid = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        List<Case> caseListSecondary = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Secondary Close Contact');
        List<Case> caseListExposure = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Exposure Management');
        Case caseRecordCloseContact = caseListContact[0];
        Case caseRecordCovid = caseListCovid[0];
        Case caseRecordsecondary = caseListSecondary[0];
        Case caseExposureRecord = caseListExposure[0];
        
         Test.startTest(); 
        //Do an assert first to make sure that the MDT exists
        System.assertNotEquals(0, CaseTriggerHelper.ACCOUNT_ENTITLEMENTS_MDT.size(), 'Account Entitlements Custom Metadata has not been loaded');
       
        // Trigger should run if Case doesn't have an EntitlementId
        // Trigger should also run if Case is new
        //result: classification should be created
        caseRecordCloseContact = [SELECT Id, Milestone_Start_Date__c, EntitlementId, CreatedDate FROM Case WHERE Id =: caseListContact[0].Id LIMIT 1];
        caseRecordCovid = [SELECT Id, Milestone_Start_Date__c, EntitlementId, CreatedDate FROM Case WHERE Id =: caseRecordCovid.Id LIMIT 1];
        caseRecordsecondary = [SELECT Id, Milestone_Start_Date__c, EntitlementId, CreatedDate FROM Case WHERE Id =: caseRecordsecondary.Id LIMIT 1];
        caseRecordCloseContact.Case_Classification__c = 'Confirmed';
        update caseRecordCloseContact;
        caseExposureRecord = [SELECT Id, Milestone_Start_Date__c, EntitlementId, CreatedDate FROM Case WHERE Id =: caseListExposure[0].Id LIMIT 1];
        
       

        List<ClassificationHistory__c> history = [SELECT Id, Record_Classification__c, CreatedDate FROM ClassificationHistory__c WHERE Record_Classification__c =: caseListContact[0].Id LIMIT 1];
        //System.assertEquals(1, history.size());
        System.debug('History size is: ' + history.size());
        
        Case caseRecordCloseContact1 = [SELECT Id, Milestone_Start_Date__c, EntitlementId, CreatedDate FROM Case WHERE Id =: caseRecordCloseContact.Id LIMIT 1];
        //if the Cases Milestone Date is blank
        //Result: Cases Milestone Date should be same as Created Date
        //As per the defect Milestone STart date should be the time case is moved to Confirmed.
        System.assertEquals(caseRecordCloseContact1.CreatedDate.date(), caseRecordCloseContact1.Milestone_Start_Date__c.date());
        
        //If Case is new AND RT is COVID_19 AND Custom Metadata is loaded
        // Set Entitlement Id
        System.assertNotEquals(null, caseRecordCloseContact.EntitlementId);
        
        
        //If Case RT is Close Contact AND EntitlementId is blank AND Case Related_Case_confirmation_date is not blank AND MDT is not null
        //SET entitlementId
        System.assertNotEquals(null, caseRecordCovid.EntitlementId);
        
        //If Case is new AND RT is COVID_19 AND Custom Metadata is loaded
        // Set Entitlement Id
        System.assertNotEquals(null, caseRecordCloseContact.EntitlementId);
        
        //IF Case is new AND RT is Outbreak and MDT Is Loaded
        //SET EntitlementId
        //System.assertNotEquals(null, caseExposureRecord.EntitlementId);
        
        //Remove entitlementId, update the Related_Case_confirmation_date__c from the Close Contact case and make sure the PCC entitlement is filled in:

        caseRecordCloseContact.entitlementId = null;
        update caseRecordCloseContact;
        caseRecordCloseContact = [SELECT Id, Milestone_Start_Date__c, EntitlementId, CreatedDate, Related_case_confirmation_date__c FROM Case WHERE Id =: caseRecordCloseContact.Id LIMIT 1];
        System.assertEquals(null, caseRecordCloseContact.EntitlementId);
        System.assertEquals(null, caseRecordCloseContact.Related_case_confirmation_date__c);
        caseRecordCloseContact.Related_case_confirmation_date__c = System.now();
        update caseRecordCloseContact;
        caseRecordCloseContact = [SELECT Id, Milestone_Start_Date__c, EntitlementId, CreatedDate, Related_case_confirmation_date__c FROM Case WHERE Id =: caseRecordCloseContact.Id LIMIT 1];
        //System.assertEquals(null, caseRecordCloseContact.EntitlementId);
        
        Test.stopTest();
    }
    @isTest
    static void handleInsertCaseAsQueueTest() {
        Group g = new Group(Name='group name', type='Queue');
        insert g;
        QueuesObject q1 = new QueueSObject(QueueID = g.id, SobjectType = 'Case');
        insert q1;
        
        GroupMember member = new GroupMember();
        member.UserOrGroupId = UserInfo.getUserId();
        member.GroupId = g.Id;
        
        insert member;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        System.runAs(thisUser){
            List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
            List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
            for(Case c : caseListExp) {
                c.OwnerId = g.Id;
                c.SubStatus__c = null;
            }
            insert caseListExp;
            Case testCase = [SELECT Id, OwnerId, SubStatus__c FROM Case WHERE Id =: caseListExp[0].Id LIMIT 1];
            System.assertEquals('00G', ((String)testCase.OwnerId).left(3));
            System.assertEquals('In Progress', testCase.SubStatus__c);
            
        }
        
    }
    
    @isTest
    static void handleSoftDeleteCaseTest() {
        Case caseRecord;
        User thisUser = [Select Id, UserRoleId, Email FROM User WHERE Id = :UserInfo.getUserId()];
        
        System.runAs(thisUser){
            List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
            List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 2, 'Isolate', 'COVID-19 Case Assessment');
            CaseTriggerHandler.SkipUpdate = false;

            caseRecord = caseListExp[0];
            caseRecord.Soft_deleted__c = true;
            update caseRecord;
            CaseTriggerHandler.SkipUpdate = false;
        }
        caseRecord = [SELECT Id, OwnerId FROM Case WHERE Id = :caseRecord.Id LIMIT 1];
        
        //Case is assigned to a queue on insert. If this fails it's not due to this this unit test but because of SOQL limitations
        //I can't isolate this unit test away from that functionality
        System.assertNotEquals(UserInfo.getUserId(), caseRecord.OwnerId);
        
        Test.startTest();

            UserRole informaticsIntel = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Informatics_Intel' LIMIT 1]; 
            thisUser.UserRoleId = informaticsIntel.Id;
            update thisUser;
            
            System.runAs(thisUser){
                List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
                List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 2, 'Isolate', 'COVID-19 Case Assessment');
                caseRecord = caseListExp[0];
                caseRecord.Soft_deleted__c = true;
                update caseRecord;
                CaseTriggerHandler.SkipUpdate = false;
            }
            caseRecord = [SELECT Id, OwnerId FROM Case WHERE Id = :caseRecord.Id LIMIT 1];
            
        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(), caseRecord.OwnerId);
        
    }
    
    @isTest
    static void createPositivePathwayTaskTest1() {
        List<Case> recordList = 
            [SELECT Id
             FROM Case
             LIMIT 2];
        // Set fields to enter the entry criteria
        Test.startTest();
        for (Case rec : recordList)
        {
            rec.Clinical_Care_Management__c  = 'Covid Positive Pathway';
            rec.Clinical_Care_Status__c      = 'Clinically discharged';
        }
        update recordList;
        Test.stopTest();
        // Verify Positive Pathway task was created for each record
        List<Task> positivePathwayTaskList = 
            [SELECT Id
             FROM Task
             WHERE WhatId IN :recordList
             AND Type = 'Perform Eligibility Assessment'];
        System.assertEquals(2, positivePathwayTaskList.size());
    }
    
    @isTest
    static void createPositivePathwayTaskTest2() {
        List<Case> recordList = 
            [SELECT Id
             FROM Case
             LIMIT 2];
        // Set fields to enter the entry criteria, but only for the first record
        Test.startTest();
        // Matching entry criteria
        recordList[0].Clinical_Care_Management__c  = 'Covid Positive Pathway';
        recordList[0].Clinical_Care_Status__c      = 'Clinically discharged';
        // Not matching entry criteria
        recordList[1].Clinical_Care_Management__c  = 'Covid Positive Pathway';
        update recordList;
        Test.stopTest();
        // Verify Positive Pathway task was created for first record only
        List<Task> positivePathwayTaskList = 
            [SELECT Id, WhatId
             FROM Task
             WHERE WhatId IN :recordList
             AND Type = 'Perform Eligibility Assessment'];
        System.assertEquals(1, positivePathwayTaskList.size());
        System.assertEquals(recordList[0].Id, positivePathwayTaskList[0].WhatId);
    }
    
    @isTest
    static void createPostClearanceTaskNoEmailTest(){
        Case caseRecord = [Select  Id, Status, SubStatus__c, AccountId, ContactId FROM Case where RecordType.DeveloperName ='Close_Contact' limit 1];
        Account acc = [SELECT Id, PersonEmail FROM Account WHERE Id =: caseRecord.AccountId LIMIT 1];
        
        acc.PersonEmail = '';
        update acc;
        caseRecord.Status = 'Closed';
        update caseRecord;
        CaseTriggerHandler.SkipUpdate = false;
        
        List<Task> tasks = [SELECT Id FROM Task WHERE whatId =: caseRecord.Id];
        
        caseRecord.SubStatus__c = 'Release';
        caseRecord.Send_Clearance_Letter__c = true;
        update caseRecord;
        CaseTriggerHandler.SkipUpdate = false;
        
        tasks = [SELECT Id, Subject, Status FROM Task WHERE whatId =: caseRecord.Id AND Subject = 'Bulk reject failed - no email provided'];
        System.debug('tasks: ' + tasks);
        System.assertEquals(1, tasks.size(), 'error Task was not added to case.');
    }
    
    @isTest
    static void updateMessagingTemplateOnSMSOptOutTest1(){
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Close Contact');
        Case caseRecord = caseListExp[0];
        
        
        personAccList.get(0).PersonHasOptedOutOfSMS__c = false;
        update personAccList;
        caseRecord.Status = 'Closed';
        caseRecord.SubStatus__c = 'Release';
        caseRecord.Send_Clearance_Letter__c = true;
        update caseRecord;
        
        caseRecord = [SELECT Id, MessagingTemplate__c FROM Case WHERE Id =: caseRecord.id LIMIT 1];
        System.assertEquals('Completed_Close_Contact_Notification', caseRecord.MessagingTemplate__c, 'Messaging template did not change to correct value for an account that has opted out of sms');
    }
    
    @isTest
    static void updateMessagingTemplateOnSMSOptOutTest2(){
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Close Contact');
        Case caseRecord = caseListExp[0];
        
        personAccList.get(0).PersonHasOptedOutOfSMS__c = true;
        update personAccList;
        caseRecord.Status = 'Closed';
        caseRecord.SubStatus__c = 'Release';
        caseRecord.Send_Clearance_Letter__c = true;
        update caseRecord;
        
        caseRecord = [SELECT Id, MessagingTemplate__c FROM Case WHERE Id =: caseRecord.id LIMIT 1];
        System.assertNotEquals('Completed_Close_Contact_Notification', caseRecord.MessagingTemplate__c, 'Messaging template should not have changed to completed_close_contact_notification since the account has not opted out of sms');
    }
    
    @isTest
    static void updateLastCheckInDateTest(){
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Close Contact');
        Case caseRecord = caseListExp[0];
        
        caseRecord.Survey_responded__c = true;
        update caseRecord;
        
        caseRecord = [SELECT Id, Last_Check_in_Date__c, Survey_responded__c FROM Case WHERE Id =: caseRecord.id LIMIT 1];
        
        System.assertEquals(System.Today(), caseRecord.Last_Check_in_Date__c.date(), 'Last Check in date should have changed to today');
    }
    
    @isTest
    static void handleNewCloseContactCreationTest1() {
        Id accId = 
            [SELECT Id
             FROM Account
             LIMIT 1].Id;
        // Create close contact records matching the entry criteria
        Test.startTest();
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        List<Case> recordList = new List<Case>();    
        Case closeContact1 = new Case(recordTypeId=closeContactRecordTypeId ,Status='Quarantine' ,SubStatus__c='In Progress',Subject='Test1',
                                      AccountId=accId, Day_0_Exposure_to_the_confirmed_case__c=System.Today()-6);
        Case closeContact2 = new Case(recordTypeId=closeContactRecordTypeId ,Status='Quarantine' ,SubStatus__c='In Progress',Subject='Test2',
                                      AccountId=accId, Day_0_Exposure_to_the_confirmed_case__c=System.Today()-6);
        recordList.add(closeContact1);
        recordList.add(closeContact2);
        insert recordList;
        Test.stopTest();
        // Verify Work Order was created for each record
        List<WorkOrder> workOrderList = 
            [SELECT Id
             FROM WorkOrder
             WHERE CaseId IN :recordList
             AND Subject = 'Initial Close Contact Interview'];
        System.assertEquals(2, workOrderList.size());
    }
    
    @isTest
    static void createWorkOrderForHQTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        
        //282278: Updated Status to "Active" and Substatus to null
        List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Active', 'Casual Contact');
        caseListExp[0].SubStatus__c = null;
        insert caseListExp;

        Case caseRecord = caseListExp[0];
        
        //update HQ flag and HQ status to create work order
        caseRecord.HQ_Resident__c = true;
        caseRecord.Status = 'Ex-HQ Follow-up';
        update caseRecord;
        
        //get work orders to Assert
        Id hqRecTYpeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Ex_Hotel_Quarantine_Resident_Monitoring').getRecordTypeId();
        List<WorkOrder> workOrders = [SELECT ID, Recordtype.Name, Status, Priority 
                                      From WorkOrder 
                                      WHERE CaseId =: caseRecord.Id 
                                      AND RecordTypeId =: hqRecTYpeId];
        
        System.assertEquals(1, workOrders.size(), 'A Ex_Hotel_Quarantine_Resident_Monitoring workorder should be created');
        System.assertEquals('In Progress', workOrders[0].Status, 'Work Order status should be - In Progress');
        System.assertEquals('Low', workOrders[0].Priority, 'Work Order Priority should be - Low');
    }
    
    @isTest
    static void handleNewCloseContactCreationTest2() {
        Id accId = 
            [SELECT Id
             FROM Account
             LIMIT 1].Id;
        // Create close contact records, but only the first record will match the criteria
        Test.startTest();
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        List<Case> recordList = new List<Case>();
        // Matching entry criteria  
        Case closeContact1 = new Case(recordTypeId=closeContactRecordTypeId ,Status='Quarantine' ,SubStatus__c='In Progress',Subject='Test1',
                                      AccountId=accId, Day_0_Exposure_to_the_confirmed_case__c=System.Today()-6);
        // Not matching entry criteria                                     
        Case closeContact2 = new Case(recordTypeId=closeContactRecordTypeId ,Status='Identify',Subject='Test2',
                                      AccountId=accId, Day_0_Exposure_to_the_confirmed_case__c=System.Today()-6);
        recordList.add(closeContact1);
        recordList.add(closeContact2);
        insert recordList;
        Test.stopTest();
        // Verify Work Order was created for first record only
        List<WorkOrder> workOrderList = 
            [SELECT Id, CaseId
             FROM WorkOrder
             WHERE CaseId IN :recordList
             AND Subject = 'Initial Close Contact Interview'];
        System.assertEquals(1, workOrderList.size());
        System.assertEquals(recordList[0].Id, workOrderList[0].CaseId);
    }

    static void handlecreateTaskWhenStatusIsEscalatedTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Quarantine', 'Close Contact');
        caseListExp[0].SubStatus__c = 'Escalate';
        insert caseListExp;
        caseListExp[0].Status = 'Trace';
        caseListExp[0].recordTypeId = CaseTriggerHelper.CASE_COVID_19_ASSESSMENT_RECORD_TYPE;
        update caseListExp;
        List<Task> tskList = [SELECT id FROM Task WHERE whatid=:caseListExp[0].Id];
        System.assertEquals(2, tskList.size());
    }
    
    @isTest
    static void handlecaseCloseTaskAndWorkorderProcessEmailTest() {
        
        
        Group g = [select Id From Group WHERE Type = 'Queue' AND Name = 'Existing Confirmed Case' LIMIT 1];
       
        Escalation_Queue_Id__c eq = new Escalation_Queue_Id__c(Confirmed_Case_Escalation_Queue__c = g.Id, Close_Contact_Escalation_Queue__c = g.id);
        insert eq;
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        //personAccList[0].PersonHasOptedOutOfEmail = true;
        //update personAccList;
        Test.startTest();
        List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Quarantine', 'Close Contact');
        CaseTriggerHandler.SkipUpdate = false;

        List<Case> caseListSecondary = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Secondary Close Contact');
        CaseTriggerHandler.SkipUpdate = false;
        
        //COVID-19 Case Assessment
        caseListExp[0].SubStatus__c = 'In Progress';
        caseListExp[0].Send_Clearance_Letter__c = true;
        insert caseListExp;
        CaseTriggerHandler.SkipUpdate = false;

        caseListExp[0].SubStatus__c = 'Release';
        caseListExp[0].Status = 'Closed';
        update caseListExp;
        CaseTriggerHandler.SkipUpdate = false;
        Test.stopTest();
        Case caseRecord = [SELECT Id, Case_Classification__c, Survey_responded__c FROM Case WHERE Id =: caseListExp[0].id LIMIT 1];
        System.assertEquals(caseRecord.Case_Classification__c, 'Rejected');
        
        //SCC record 
        caseListSecondary[0].Status = 'Closed';
        caseListSecondary[0].SubStatus__c = 'Release';
        caseListSecondary[0].Send_Clearance_Letter__c = true;
        //caseListSecondary[0].Account.PersonHasOptedOutOfEmail = true;
        update caseListSecondary;
        CaseTriggerHandler.SkipUpdate = false;

        Case caseRecordsecondary = [SELECT Id, Case_Cleared_from_Isolation__c , Survey_responded__c FROM Case WHERE Id =: caseListSecondary[0].id LIMIT 1];
        
        System.assertEquals(caseRecordsecondary.Case_Cleared_from_Isolation__c , 'Yes');
        
    }
    @isTest
    static void handlecaseCloseTaskAndWorkorderProcessTaskTest() {
        
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        personAccList[0].PersonHasOptedOutOfEmail = True;
        update personAccList;
        Test.startTest();
        List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Trace', 'COVID-19 Case Assessment');
        CaseTriggerHandler.SkipUpdate = false;

        List<Case> caseListSecondary = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Trace', 'Secondary Close Contact');
        CaseTriggerHandler.SkipUpdate = false;

        //Covid 19
        caseListExp[0].Send_Clearance_Letter__c = true;
        insert caseListExp;
        CaseTriggerHandler.SkipUpdate = false;

        caseListExp[0].SubStatus__c = 'Release';
        caseListExp[0].Status = 'Closed';
        update caseListExp;
        CaseTriggerHandler.SkipUpdate = false;
        Test.stopTest();
        List<Task> tskList = [SELECT id FROM Task WHERE whatid=:caseListExp[0].Id];
        System.assertEquals(1, tskList.size());
        
        //SCC
        caseListSecondary[0].Send_Clearance_Letter__c = true;
        insert caseListSecondary;
        CaseTriggerHandler.SkipUpdate = false;

        caseListSecondary[0].SubStatus__c = 'Release';
        caseListSecondary[0].Status = 'Closed';
        update caseListSecondary;
        CaseTriggerHandler.SkipUpdate = false;

        List<Task> tskListscc = [SELECT id FROM Task WHERE whatid=:caseListSecondary[0].Id];
        
        System.assertEquals(1, tskListscc.size());
        
    }

    static testMethod void testInsertCaseOwnedByUser(){
        User testUser = TestDataFactory.createAdminUser();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Test.startTest();
            insertCaseOwnedByUser(testUser.Id);
            Test.stopTest();
        }
    }

    private static void insertCaseOwnedByUser(Id ownerId){
        Id outbreakRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Exposure Management').getRecordTypeId();
        Case testCase = new Case();
        testCase.RecordTypeId = outbreakRecordTypeId;
        testCase.Subject = 'Test Case';
        testCase.Site_type__c = 'Outbreak';
	    testCase.Status = 'New';
        testCase.OwnerId = ownerId;
        insert testCase;
    }

    static testMethod void testInsertCaseOwnedByQueue(){
        Group testGroup = new Group();
        testGroup.Name = 'Test Group123';
        testGroup.Type = 'Queue';

        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Test.startTest();
            insert testGroup;
            QueueSObject queueAssignment = new QueueSObject(SobjectType='Case', QueueId = testGroup.Id);
            insert queueAssignment;
    
            
            insertCaseOwnedByGroup(testGroup.Id);
            Test.stopTest();
        }
       
    }

    private static void insertCaseOwnedByGroup(Id ownerId){
        Id outbreakRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Exposure Management').getRecordTypeId();
        Case testCase = new Case();
        testCase.RecordTypeId = outbreakRecordTypeId;
        testCase.Subject = 'Test Case';
        testCase.Site_type__c = 'Outbreak';
	    testCase.Status = 'New';
        testCase.OwnerId = ownerId;
        insert testCase;
    }

    static testMethod void testUpdateCaseOwnedByUser(){
       User testUser = TestDataFactory.createAdminUser();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Test.startTest();
            updateCaseOwnedByUser(testUser.Id);
            Test.stopTest();
        }
    }

    private static void updateCaseOwnedByUser(Id ownerId){
        Id outbreakRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Exposure Management').getRecordTypeId();
        Case testCase = new Case();
        testCase.RecordTypeId = outbreakRecordTypeId;
        testCase.Subject = 'Test Case';
        testCase.Site_type__c = 'Placeholder';
	    testCase.Status = 'New';
        testCase.OwnerId = ownerId;
        insert testCase;
        testCase.Site_Type__c = 'Outbreak';
        update testCase;
    }

    static testMethod void testUpdateCaseOwnedByQueue(){
        Group testGroup = new Group();
        testGroup.Name = 'Test Group123';
        testGroup.Type = 'Queue';
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Test.startTest();
            insert testGroup;
            QueueSObject queueAssignment = new QueueSObject(SobjectType='Case', QueueId = testGroup.Id);
            insert queueAssignment;
    
            
            updateCaseOwnedByQueue(testGroup.Id);
            Test.stopTest();
        }
       
    }
    
    private static void updateCaseOwnedByQueue(Id ownerId){
        Id outbreakRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Exposure Management').getRecordTypeId();
        Case testCase = new Case();
        testCase.RecordTypeId = outbreakRecordTypeId;
        testCase.Subject = 'Test Case';
        testCase.Site_type__c = 'Placeholder';
        testCase.Status = 'New';
        testCase.OwnerId = ownerId;
        insert testCase;
        testCase.Site_Type__c = 'Outbreak';
        update testCase;   
    }

    @isTest
    public static void updateWorkOrderOwner(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardstandarduser@testorg.com');
        insert u;
        Case closeContactCase = [Select Id, Day_0_Exposure_to_primarycc__c from Case where RecordType.DeveloperName ='Close_Contact' limit 1];
        closeContactCase.ownerId = u.Id;
        update closeContactCase; 
        Case secondarycloseContactCase = [Select Id, ownerId from Case where RecordType.DeveloperName ='Secondary_Close_Contact' limit 1];
        secondarycloseContactCase.ownerId = u.Id;
        update secondarycloseContactCase; 
        Case confirmedCase = [Select Id, ownerId from Case where RecordType.DeveloperName ='COVID_19_Case_Assessment' limit 1];
        confirmedCase.ownerId = u.Id;
        update confirmedCase;
        
        system.assertEquals(confirmedCase.ownerId, u.Id);
        system.assertEquals(closeContactCase.ownerId, u.Id);
        system.assertEquals(secondarycloseContactCase.ownerId, u.Id);
    }

    
    @isTest
    static void testSetInitialInterview() {
        Account acc = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

        List<Case> cases = TestDataFactory.createCases(acc, 3, 'Trace', 'COVID-19 Case Assessment');

        cases[0].Initial_Interview_Completed_Time__c = System.today();
        cases[0].Initial_Interview_completed__c = true;
        cases[0].Set_Initial_Interview__c = 'T';

        cases[1].Initial_Interview_Completed_Time__c = System.today();
        cases[1].Initial_Interview_completed__c = true;
        cases[1].Set_Initial_Interview__c = 'F';

        cases[2].Initial_Interview_Completed_Time__c = System.today();
        cases[2].Initial_Interview_completed__c = true;
        cases[2].Set_Initial_Interview__c = null;
        

        Test.startTest();

        update cases;

        Case case1 = [SELECT Initial_Interview_Completed_Time__c, Initial_Interview_completed__c, Set_Initial_Interview__c FROM Case WHERE Id = :cases[0].Id];
        Case case2 = [SELECT Initial_Interview_Completed_Time__c, Initial_Interview_completed__c, Set_Initial_Interview__c FROM Case WHERE Id = :cases[1].Id];
        Case case3 = [SELECT Initial_Interview_Completed_Time__c, Initial_Interview_completed__c, Set_Initial_Interview__c FROM Case WHERE Id = :cases[2].Id];

        Test.stopTest();

        System.assertEquals(true, case1.Initial_Interview_completed__c);
        System.assertEquals(false, case2.Initial_Interview_completed__c);
        System.assertEquals(true, case3.Initial_Interview_completed__c);

        System.assertEquals(null, case1.Set_Initial_Interview__c);
        System.assertEquals(null, case2.Set_Initial_Interview__c);
        System.assertEquals(null, case3.Set_Initial_Interview__c);

        System.assertNotEquals(null, case1.Initial_Interview_Completed_Time__c);
        System.assertEquals(null, case2.Initial_Interview_Completed_Time__c);
        System.assertNotEquals(null, case3.Initial_Interview_Completed_Time__c);
    }

    @isTest
    static void test_updateInitialInterviewCompleted() {        
        Case closeContactCase = [Select Id, Day_0_Exposure_to_primarycc__c from Case where RecordType.DeveloperName ='Close_Contact' limit 1];
        closeContactCase.Day_0_Exposure_to_the_confirmed_case__c = System.today() + 1;
        closeContactCase.Initial_Interview_Completed_Time__c = System.today();

      
            Test.startTest();
            update closeContactCase;
            Test.stopTest();
        
        
        //Assert
        Case returnCase = [Select Id, Initial_Interview_completed__c,Initial_Interview_Completed_Time__c from Case where RecordType.DeveloperName ='Close_Contact' limit 1];
        system.assertEquals(FALSE, returnCase.Initial_Interview_completed__c);
    }

    @isTest
    static void test_updateInitialInterviewCompletedBulk() {  
		Account acc = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];
        TestDataFactory.createCases(acc, 50, 'Trace', 'Close Contact');
		List<Case> caseList=new List<Case>();
		for(Case caseRec: [select Id, Day_0_Exposure_to_primarycc__c from Case where RecordType.DeveloperName ='Close_Contact' limit 50]){
			caseRec.Day_0_Exposure_to_the_confirmed_case__c = System.today() + 1;
			caseRec.Initial_Interview_Completed_Time__c = System.today();
			caseList.add(caseRec);
		}
		   
            Test.startTest();
            update caseList;
            Test.stopTest();
        
        
        //Assert
		List<Case> updatedCaseList = new List<Case>();
       updatedCaseList = [Select Id, Initial_Interview_completed__c,Initial_Interview_Completed_Time__c from Case where RecordType.DeveloperName ='Close_Contact' and Initial_Interview_completed__c=false LIMIT 50];
        system.assertEquals(50, updatedCaseList.size());
    }
  

/**
    * ───────────────────────────────────────────────────────────────────────────────────────────────┝
    * @description    Check fields reset when records changed from PCC to Confirmed
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */    
    @IsTest
    static void clearInterviewFields_PCC_to_Confirmed (){

        List<Case> pccCase = new List<Case>();
        List<Account> accs = new List<Account>();
        Case result;
        accs = [Select Id , Name FROM Account WHERE RecordtypeId =: accountRecordTypeId AND PersonEmail = 'test@gmail.com'];
        pccCase = [Select Id , RecordTypeId , Initial_Interview_completed__c , Initial_Interview_Completed_Time__c , Day_0_Exposure_to_the_confirmed_case__c from Case  WHERE RecordTypeId =: closeContactRecordTypeId LIMIT 1];
        
        //test account wasn't found
        if(accs.size() == 0){
            accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');
        }

        System.assert(accs.size() == 1 , 'TestDataFactory.createAccount failed to create the test record. accs.size() = ' + accs.size());

        // test case wasn't found
        if(pccCase.size() == 0){
            pccCase = TestDataFactory.createCases(accs[0], 1, 'Trace', 'Close Contact');
            CaseTriggerHandler.SkipUpdate = false;
        }

        System.assert(pccCase.size() == 1 , 'TestDataFactory.createCases failed to create the test record. pccCase.size() = ' + pccCase.size());

        Test.startTest();
            pccCase[0].Initial_Interview_completed__c = true;
            pccCase[0].Initial_Interview_Completed_Time__c = System.today() - 1;
            pccCase[0].Day_0_Exposure_to_the_confirmed_case__c = System.today() - 2;
            pccCase[0].Status = 'Closed';
            update pccCase;
            CaseTriggerHandler.SkipUpdate = false;

            result = [Select Id , Status, RecordTypeId , Initial_Interview_completed__c , Initial_Interview_Completed_Time__c , Day_0_Exposure_to_the_confirmed_case__c from Case WHERE ID =: pccCase[0].Id];
            System.assert(result.Initial_Interview_completed__c == true , 'Initial_Interview_completed__c  was not set. It should be true. Current Value = ' + result.Initial_Interview_completed__c);
            System.assert(result.Status.equalsIgnoreCase('Closed') , 'Case status not Closed. Current value = ' + result.Status);

            //change from SCC to Confirmed 
            pccCase[0].recordTypeId = confirmedCaseRecordTypeId;
            pccCase[0].Day_0_Exposure_to_the_confirmed_case__c = System.today() - 1;
            pccCase[0].Status = 'Identify';
            update pccCase;
            CaseTriggerHandler.SkipUpdate = false;
        Test.stopTest();

        result = [Select Id , Status, RecordTypeId , Initial_Interview_completed__c , Initial_Interview_Completed_Time__c , Day_0_Exposure_to_the_confirmed_case__c from Case WHERE ID =: pccCase[0].Id];
        System.assert(result.RecordTypeId == confirmedCaseRecordTypeId , 'Incorrect record type Id. Expected = ' + confirmedCaseRecordTypeId + ' Current Value = ' + result.RecordTypeId);
        System.assert(result.Initial_Interview_completed__c == false , 'Initial_Interview_completed__c  should be false. Current Value = ' + result.Initial_Interview_completed__c);
        System.assert(result.Initial_Interview_Completed_Time__c == null , 'Initial_Interview_Completed_Time__c  should be null. Current Value = ' + result.Initial_Interview_Completed_Time__c);
        System.assert(result.Status.equalsIgnoreCase('Identify') , 'Case status not Identify. Current value = ' + result.Status);
    }

    @IsTest
    static void testCOVIDSafeDVRAssessmentTasks(){
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingPostalCode = null;
        update personAc;

        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = personAc.Id);
        insert entl;


        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Trace', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                            AccountId = personAc.Id, Symptoms_Onset_Date__c = System.Today().addDays(-5), Date_of_Test__c = System.Today().addDays(-2), Clearance_eligibility_assessment_date__c = System.Today().addDays(12), EntitlementId = entl.Id);

        insert cse;

        Test.startTest();
        cse.Case_have_the_COVID_Safe_app__c = 'Yes (Please complete the Close Contacts Sheet)';
        cse.DVR_assessment_required__c = 'Yes';

        update cse;
        Test.stopTest();

        //System.assertEquals(2, Database.countQuery('SELECT Count() FROM Task'));
    }
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────┝
    * @description    Check fields reset when records changed from SCC to PCC
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */    
    // @IsTest
    // static void clearInterviewFields_SCC_to_PCC (){
    //     // Account acc = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];
    //     // TestDataFactory.createCases(acc, 200, 'Trace', 'Close Contact');
            // User contextuser = TestDataFactory.createHealthWorkerUser();
    //     System.runAs(contextUser){
    //         List<Case> sccCase = new List<Case>();
    //         List<Account> accs = new List<Account>();
    //         Case result;
    //         accs = [Select Id , Name FROM Account WHERE RecordtypeId =: accountRecordTypeId AND PersonEmail = 'test@gmail.com'];
    //         sccCase = [Select Id , RecordTypeId , Initial_Interview_completed__c , Initial_Interview_Completed_Time__c , Day_0_Exposure_to_the_confirmed_case__c from Case  WHERE RecordTypeId =: secondaryCloseContactRecordTypeId LIMIT 1];
            
    //         //test account wasn't found
    //         if(accs.size() == 0){
    //             accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');
    //         }
    
    //         System.assert(accs.size() == 1 , 'TestDataFactory.createAccount failed to create the test record. accs.size() = ' + accs.size());
    
    //         // test case wasn't found
    //         if(sccCase.size() == 0){
    //             sccCase = TestDataFactory.createCases(accs[0], 1, 'Trace', 'Secondary Close Contact');
    //         }
    
    //         System.assert(sccCase.size() == 1 , 'TestDataFactory.createCases failed to create the test record. pccCase.size() = ' + sccCase.size());
    
    //         Test.startTest();
    //             sccCase[0].Initial_Interview_completed__c = true;
    //             sccCase[0].Initial_Interview_Completed_Time__c = System.today() - 1;
    //             sccCase[0].Day_0_Exposure_to_the_confirmed_case__c = System.today() - 2;
    //             update sccCase;
    
    //             result = [Select Id , Status, RecordTypeId , Initial_Interview_completed__c , Initial_Interview_Completed_Time__c , Day_0_Exposure_to_the_confirmed_case__c from Case WHERE ID =: sccCase[0].Id];
    //             System.assert(result.Initial_Interview_completed__c == true , 'Initial_Interview_completed__c  was not set. It should be true. Current Value = ' + result.Initial_Interview_completed__c);
    
    //             //change from SCC to PCC 
    //             sccCase[0].recordTypeId = closeContactRecordTypeId;
    //             sccCase[0].SubStatus__c = 'Released';
    //             update sccCase;
    //         Test.stopTest();
    
    //         result = [Select Id , Status, RecordTypeId , Initial_Interview_completed__c , Initial_Interview_Completed_Time__c , Day_0_Exposure_to_the_confirmed_case__c from Case WHERE ID =: sccCase[0].Id];
    //         System.assert(result.RecordTypeId == closeContactRecordTypeId , 'Incorrect record type Id. Expected = ' + closeContactRecordTypeId + ' Current Value = ' + result.RecordTypeId);
    //         System.assert(result.Initial_Interview_completed__c == false , 'Initial_Interview_completed__c  should be false. Current Value = ' + result.Initial_Interview_completed__c);
    //         System.assert(result.Initial_Interview_Completed_Time__c == null , 'Initial_Interview_Completed_Time__c  should be null. Current Value = ' + result.Initial_Interview_Completed_Time__c);
    //     }
    // }

    @IsTest
    static void updateOwnerOnWorkOrderandTaskTest(){
        Case caseTest = [SELECT Id, RecordType.Name, Owner.Name, Status FROM Case WHERE RecordType.DeveloperName='Close_Contact' LIMIT 1];
        List<WorkOrder> workOrder = [SELECT Id,OwnerId,RecordTypeId, Status, Manually_Allocated__c, CaseId,Record_s_Owner__c
        FROM WorkOrder
        WHERE CaseId =: caseTest.Id];

        caseTest.OwnerId = UserInfo.getUserId();

        Test.startTest();
        update caseTest;
        Test.stopTest();

        System.assert([SELECT Id,OwnerId,RecordTypeId, Status, Manually_Allocated__c, CaseId,Record_s_Owner__c FROM WorkOrder LIMIT 1].OwnerId == UserInfo.getUserId());
    }

    //PBI 253228 - All interview work orders should be automatically be created when new confirmed case or new primary close contact record is created 
        
    @IsTest
    static void Test_createInterviewWorkOrders_001() {
        //Create Person Account
        List<Account> personAccList = TestDataFactory.createAccount(30, 'Active','Person Account');
       
        Test.StartTest();
        //Create Case
        List<Case> caseListConfirmed = TestDataFactory.createCasePerAccount(personAccList, 'Isolate', 'In Progress', CaseTriggerHelper.CASE_COVID_19_ASSESSMENT_RECORD_TYPE);
        CaseTriggerHandler.SkipUpdate = false;
        Test.StopTest();

        Map<Id,Case> caseIdsToCases = new Map<Id,Case>();
        for(Case record : caseListConfirmed) {
            caseIdsToCases.put(record.Id, record);
        }

        // retrieve created work orders on the after update trigger of the case
        Id hqRecTYpeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
        List<WorkOrder> workOrders = [
                SELECT  Id, CaseId, AccountId, ContactId, Priority,
                        Status, Subject, Person_Interviewed__c,
                        OwnerId, RecordTypeId
                FROM WorkOrder
                WHERE CaseId =: caseIdsToCases.keySet()
                AND RecordTypeId =: hqRecTYpeId
        ];


      
        for(WorkOrder wo : workOrders) {
            System.assertEquals(CaseTriggerHelper.WO_SUBJECT_CONFIRM_CASE_INTERVIEW, wo.Subject);
            System.assertEquals(CaseTriggerHelper.WO_PERSON_INTERVIEWED_CASE, wo.Person_Interviewed__c);
            System.assertEquals(caseIdsToCases.get(wo.CaseId).AccountId, wo.AccountId);
            System.assertEquals(caseIdsToCases.get(wo.CaseId).ContactId, wo.ContactId);
            System.assertEquals(caseIdsToCases.get(wo.CaseId).OwnerId, wo.OwnerId);
            System.assertEquals(CaseTriggerHelper.WORKORDER_CONFIRMEDCASE_RECORD_TYPE_ID, wo.RecordTypeId);
        }
    }

    //PBI 253228 - All interview work orders should be automatically be created when new confirmed case or new primary close contact record is created 
        
    @IsTest
    static void Test_createInterviewWorkOrders_002() {
        //Create Person Account
        List<Account> personAccList = TestDataFactory.createAccount(30, 'Active','Person Account');

        Test.StartTest();
        //Create Case
        List<Case> caseListConfirmed = TestDataFactory.createCasePerAccount(personAccList, CaseTriggerHelper.CASE_SCC_STATUS_IDENTIFY, '', CaseTriggerHelper.CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE);
        CaseTriggerHandler.SkipUpdate = false;
        Test.StopTest();

        Map<Id,Case> caseIdsToCases = new Map<Id,Case>();
        for(Case record : caseListConfirmed) {
            caseIdsToCases.put(record.Id, record);
        }

        // retrieve created work orders on the after update trigger of the case
        List<WorkOrder> workOrders = [
                SELECT  Id, CaseId, AccountId, ContactId, Priority,
                        Status, Subject, Person_Interviewed__c,
                        OwnerId, RecordTypeId
                FROM WorkOrder
                WHERE CaseId =: caseIdsToCases.keySet()
        ];


     
        for(WorkOrder wo : workOrders) {
            System.assertEquals(CaseTriggerHelper.WO_SUBJECT_SCC_INTERVIEW, wo.Subject);
            System.assertEquals(CaseTriggerHelper.WO_PERSON_INTERVIEWED_SSC, wo.Person_Interviewed__c);
            System.assertEquals(CaseTriggerHelper.WO_STATUS_NEW, wo.Status);
            System.assertEquals(CaseTriggerHelper.WO_PRIORITY_LOW, wo.Priority);
            System.assertEquals(caseIdsToCases.get(wo.CaseId).AccountId, wo.AccountId);
            System.assertEquals(caseIdsToCases.get(wo.CaseId).ContactId, wo.ContactId);
            System.assertEquals(caseIdsToCases.get(wo.CaseId).OwnerId, wo.OwnerId);
            System.assertEquals(CaseTriggerHelper.WORKORDER_SCC_INTERVIEW_RECORD_TYPE_ID, wo.RecordTypeId);
        }
    }
    @isTest
    static void suppressSmsSymptomsSurveyTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        CaseTriggerHandler.SkipUpdate = false;

        Case caseRecord = caseListExp[0];

        Test.StartTest();
        caseRecord.Clinical_Care_Management__c = 'Covid Positive Pathway';
        update caseRecord;
        Test.StopTest();

        Account accountRec = [SELECT Reason_For_Exclusion__c, PersonHasOptedOutOfSMS__c FROM Account WHERE Id =: caseRecord.AccountId LIMIT 1];
        //System.assertEquals(true, accountRec.PersonHasOptedOutOfSMS__c, 'Related account should be opted out of SMS if Clinical Care Management is Covid Positive Pathway');
        //System.assertEquals('Eligible for Positive Pathway', accountRec.Reason_For_Exclusion__c, 'Related account should have their reason for exclusion set');
        
    }
    
    @isTest
    static void suppressSmsSymptomsSurveyDHHSManagedTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        CaseTriggerHandler.SkipUpdate = false;

        Case caseRecord = caseListExp[0];

        Test.StartTest();
        caseRecord.Clinical_Care_Management__c = 'DHHS Managed';
        update caseRecord;
        Test.StopTest();

        Account accountRec = [SELECT Reason_For_Exclusion__c, PersonHasOptedOutOfSMS__c FROM Account WHERE Id =: caseRecord.AccountId LIMIT 1];
        System.assertEquals(false, accountRec.PersonHasOptedOutOfSMS__c, 'Related Account should not be opted out');
        System.assertEquals(null, accountRec.Reason_For_Exclusion__c, 'Related account should not have their reason for exclusion set');
        
    }
    
    @isTest
    static void populateConfirmationDateTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        Case caseRecord = caseListExp[0];
        caseRecord.Case_Classification__c = 'At Risk';
        update caseRecord;
        CaseTriggerHandler.SkipUpdate = false;

        Test.StartTest();
        System.debug('case is: ' + caseRecord.Case_Classification__c);
        System.debug('case confirmation dat is : ' + caseRecord.Confirmation_Date__c);
        caseRecord.Case_Classification__c = 'Confirmed';
        update caseRecord;
        CaseTriggerHandler.SkipUpdate = false;
        Test.StopTest();

        caseRecord = [SELECT Id, Confirmation_Date__c FROM Case WHERE Id =: caseRecord.Id LIMIT 1];
        System.assertNotEquals(null, caseRecord.Confirmation_Date__c, 'Confirmation Date should update if classification is confirmed');
        
    }

    @isTest
    static void populateCPARecordTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        CaseTriggerHandler.SkipUpdate = false;

        Case caseRecord = caseListExp[0];
       
        Test.StartTest();
     
        caseRecord.Case_Classification__c = 'Confirmed';
        caseRecord.Confirmation_Date__c=System.today();
        
        update caseRecord;
        
        Test.StopTest();
        ContactPointAddress cpaRec= new ContactPointAddress();     
        cpaRec = [select Id,name,Address,AddressType,Createddate from ContactPointAddress where ParentId = : personAccList[0].Id LIMIT 1];      
        System.assertNotEquals(null, cpaRec, 'CPA Record created ');
        
    }
    @isTest
    static void createClearanceWorkOrderForConfirmCases() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Trace', 'COVID-19 Case Assessment');
        insert caseListExp;

        Case caseRecord = caseListExp[0];
        
        Id hqRecTYpeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Confirmed_Case_Clearance').getRecordTypeId();
        List<WorkOrder> workOrders = [SELECT ID, Recordtype.Name, Status, Priority 
                                      From WorkOrder 
                                      WHERE CaseId =: caseRecord.Id 
                                      AND RecordTypeId =: hqRecTYpeId];
        
        System.assertEquals(1, workOrders.size(), 'A Confirmed_Case_Clearance workorder should be created');
        System.assertEquals(hqRecTYpeId, workOrders[0].RecordTypeId, 'Work Order recordtype should be - Confirmed_Case_Clearance');
        System.assertEquals('Low', workOrders[0].Priority, 'Work Order Priority should be - Low');
    }

    //#313212
    @isTest
    static void initialEmailSentNotificationTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        Case caseRecord = caseListExp[0];

        Test.StartTest();
        caseRecord.Send_initial_notification_email__c = True;
        update caseRecord;
        Test.StopTest();

        Case rec = [SELECT Time_and_Date_of_sent_initial_email__c FROM Case WHERE Id =: caseRecord.Id LIMIT 1];
        System.assertEquals(true, rec.Time_and_Date_of_sent_initial_email__c != null ? true : false, 'Time and Date of sent inital email should have value'); 
    }
    
     // #313212
     @isTest
    static void resetInterviewInformationTest() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        Case caseRecord = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Closed', 'Close Contact')[0];
        caseRecord.Send_initial_notification_email__c = True;
        caseRecord.SubStatus__c='Release';
        insert caseRecord;

        Test.StartTest();
        case updateRec = [Select Id,Send_initial_notification_email__c, status,ClosedDate from case where id=: caseRecord.Id limit 1];
        updateRec.status = 'Isolate';
        updateRec.SubStatus__c = 'In Progress';
        update updateRec;
        Test.stopTest();

        Case rec = [SELECT Send_initial_notification_email__c FROM Case WHERE Id =: updateRec.Id LIMIT 1];
        System.assertEquals(true, rec.Send_initial_notification_email__c == false ? true : false, 'send initial notification should be false'); 
    }


    /**
    * @description PBI 326876 - Case Changed to Confirmed(Refactoring 2.0 - Rework of Sprint 10 PBI)
    *                            Unit test for processConfirmedRecordsAsync  
    * @author Aref Samad | 10-15-2021 
    **/
    @isTest
    static void processConfirmedRecordsAsyncTest() {
        
        //given
        
        Account acc = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

        List<Case> cases = TestDataFactory.createCases(acc, 1, 'Quarantine', 'Close Contact');
        cases[0].Case_Classification__c='Confirmed';
        Test.startTest();

            //when
            Update cases[0];

        Test.stopTest();

        //then
        
        //Case check
        List<Case> casesResult=[SELECT Id, RecordTypeId FROM Case Where Id=:cases[0].Id];
        System.assert(casesResult.size()>0,'Case not available');
        System.assertEquals(confirmedCaseRecordTypeId, casesResult[0].RecordTypeId,'Case Record not changed');

        //Task check
        List<Task> tasks=[SELECT Id FROM Task where Subject = 'Record Changed to Confirmed Case' and WhatId=:cases[0].Id];
        System.assert(tasks.size()>0,'Task not available');

        //Work order check
        List<WorkOrder> wos=[SELECT Id FROM WorkOrder where status = 'Stopped' and CaseId=:cases[0].Id];
        System.assert(wos.size()>0,'Work order not available');

        //Classification check
        List<ClassificationHistory__c> histories=[SELECT Id FROM ClassificationHistory__c where Classification__c = 'Confirmed' and Record_Classification__c=:cases[0].Id];
        System.assert(histories.size()>0,'History not available');

        //Can't check the Survey Invitation as we have to enable SeeAllData(not recommended)

    }


  
    @isTest
    static void handleStatusForPCCToCCRecordTypeTest() {

         //given
        
         Account acc = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

         List<Case> cases = TestDataFactory.createCasesNoInsert(acc, 1, 'Quarantine', 'Close Contact');
         cases[0].SubStatus__c='In Progress';
         insert cases;

         cases[0].RecordTypeId=casualConRecordTypeId;
         Test.startTest();
 
            //when
            Update cases[0];
 
         Test.stopTest();
 
         //then
         
         //Case check
         List<Case> casesResult=[SELECT Id, Status,SubStatus__c, RecordTypeId FROM Case Where Id=:cases[0].Id];
         System.assert(casesResult.size()>0,'Case not available');
         System.assertEquals(casualConRecordTypeId, casesResult[0].RecordTypeId,'Case Record not changed');
         System.assertEquals('Active', casesResult[0].Status,'Case Status not changed');
         System.assertEquals(null, casesResult[0].SubStatus__c,'Case Sub Status not changed');

    }

    
    //#333814
    
    @isTest
    static void publishDVRSearchRequestEvents() {
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        Group  existingConfirmedCaseQueue = [SELECT Id FROM Group Where DeveloperName = 'Existing_Confirmed_Case' AND Type = 'Queue' LIMIT 1];
        Case caseRecord = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Trace', 'COVID-19 Case Assessment')[0];
        caseRecord.Send_initial_notification_email__c = True;
        caseRecord.Soft_Delete__c = false;
        caseRecord.MC_Ready__c = true;
        caseRecord.OwnerId= existingConfirmedCaseQueue.id;
        caseRecord.Case_Classification__c ='Confirmed';
        caseRecord.Confirmation_Date__c = system.today();
        
        insert caseRecord;
        
        
        List<DVR_Search_Request_Event__e> dvrslist = new List<DVR_Search_Request_Event__e>();
    	DVR_Search_Request_Event__e dvrs = new DVR_Search_Request_Event__e();
        dvrs.Phone_Number__c = '61402654876';
                      dvrs.Start_Date_Time__c = caseRecord.Confirmation_Date__c;
                       dvrs.End_Date_Time__c = caseRecord.Confirmation_Date__c;
                       dvrs.Search_Reason__c  = 'Confirmed Case';
                       dvrs.TREVI_Case_ID__c = Integer.valueOf('09876546');
        dvrslist.add(dvrs);
        DVR_Search_Request_Event__e dvrs1 = new DVR_Search_Request_Event__e();
        dvrs1.Phone_Number__c = '61402654872';
                      dvrs1.Start_Date_Time__c = system.today();
                       dvrs1.End_Date_Time__c = system.today();
                       dvrs1.Search_Reason__c  = 'Confirmed Case';
                       dvrs1.TREVI_Case_ID__c = Integer.valueOf('09876542');
        
        Test.StartTest();
        Database.SaveResult sr = EventBus.publish(dvrs1);
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess());

    } 
    
}