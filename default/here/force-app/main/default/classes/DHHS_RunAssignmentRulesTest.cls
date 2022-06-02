//*************************/
// Created By:  SFDC
// Created Date: 7 Oct 2020
// Story: DHSCT-1158
// Desc:  
// Test Class for DHHS_RunAssignmentRulesTest
// Note:  This test clas relies on the case assignment rules being present.
/**************************/
@isTest
public with sharing class DHHS_RunAssignmentRulesTest {
    
    @testSetup 
    static void setupTestData() {

        String recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc= new Account(RecordTypeID=recordTypeId, FirstName='Test FName', LastName='Test LName',PersonMailingStreet='test@yahoo.com',
                                 PersonMailingPostalCode='12345', PersonMailingCity='SFO', PersonEmail='test@yahoo.com', PersonHomePhone='1234567',PersonMobilePhone='+611234');
        insert acc;

        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId=caseRecordTypeId,Status='Isolate',SubStatus__c='In Progress',Subject='Test Case - Assignment Rule',
                             AccountId=acc.Id, Symptoms_Onset_Date__c=System.Today());
        insert cse;
    
    }

    @isTest
    static void TestAssignmentRule(){

        Case cse = [SELECT Id, OwnerId  FROM Case where Subject ='Test Case - Assignment Rule'];
        Id caseOwnerId = cse.Id;
        System.debug('***caseOwnerId:' +caseOwnerId);

        List<DHHS_RunAssignmentRules.FlowInputs> request = new List<DHHS_RunAssignmentRules.FlowInputs>();
        DHHS_RunAssignmentRules.FlowInputs inputs = new DHHS_RunAssignmentRules.FlowInputs();
        inputs.caseId = cse.Id;
        request.add(inputs);
        DHHS_RunAssignmentRules.DHHS_RunAssignmentRules(request);

        cse = [SELECT Id,OwnerId FROM Case where Subject ='Test Case - Assignment Rule'];
        System.debug('***cse.ownerId new:' +cse.OwnerId);
        System.assertNotEquals(caseOwnerId, cse.OwnerId, 'These ownerIds should be different if assignment rules have run');
        
    }
}