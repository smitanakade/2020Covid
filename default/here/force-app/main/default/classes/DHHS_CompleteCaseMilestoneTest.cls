//*************************/
// Created By:  SFDC
// Created Date: 2 Oct 2020
// Story: DHSCT-1158
// Desc:  
// Test Class for DHHS_CompleteCaseMilestone
/**************************/
@isTest
public with sharing class DHHS_CompleteCaseMilestoneTest {
    static testMethod void TestCompleteMilestoneCase(){

        String recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc= new Account(RecordTypeID=recordTypeId, FirstName='Test FName', LastName='Test LName',PersonMailingStreet='test@yahoo.com',
                                 PersonMailingPostalCode='12345', PersonMailingCity='SFO', PersonEmail='test@yahoo.com', PersonHomePhone='1234567',PersonMobilePhone='+611234');
        insert acc;

        Entitlement entl = new Entitlement(Name='TestEntitlement', AccountId=acc.Id);
        insert entl;

        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId=caseRecordTypeId,Status='Isolate',SubStatus__c='In Progress',Subject='Test Case - Daily Milestone Test',
                             AccountId=acc.Id, Symptoms_Onset_Date__c=System.Today(), EntitlementId=entl.Id);
        insert cse;

        Integer cseMilestones = [SELECT COUNT() FROM CaseMilestone WHERE caseId = :cse.Id AND MilestoneType.Name='Interview confirmed case' AND completionDate = null];
        //System.assertEquals(cseMilestones, 1, 'Case Milestones are epxected to have a null date when created');

        DateTime dt = System.Now();
        List<DHHS_CompleteCaseMilestone.FlowInputs> request = new List<DHHS_CompleteCaseMilestone.FlowInputs>();
        DHHS_CompleteCaseMilestone.FlowInputs inputs = new DHHS_CompleteCaseMilestone.FlowInputs();
        inputs.caseId = cse.Id;
        inputs.milestoneName = 'Interview confirmed case';
        inputs.completionDate = dt;
        request.add(inputs);
        DHHS_CompleteCaseMilestone.DHHS_CompleteCaseMilestone(request);
        cseMilestones = [SELECT COUNT() FROM CaseMilestone WHERE caseId = :cse.Id AND MilestoneType.Name='Interview confirmed case' AND completionDate = null];
        //System.assertEquals(cseMilestones, 0, 'Case Milestones end date should be set');

    }
}