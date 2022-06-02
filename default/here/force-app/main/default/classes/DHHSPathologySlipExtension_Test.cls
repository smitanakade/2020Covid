/*
 * @Author             : Jiten Joysar
 * @Description        : DHHSPathologySlipExtension Test class
 * @Modification Log   : 
 * -------------------------------------------------------------------------
 * Date           Author      		    Details
 * -------------------------------------------------------------------------
 * 01/03/2021     Jiten Joysar          Initial version
*/
@isTest
public without sharing class DHHSPathologySlipExtension_Test {
    
     // test setup method to create and setup records
     @testSetup static void setup() {

        // get user record
        User u = new User(Id=UserInfo.getUserId());
        UserTriggerHandler.addHCPermissionSets(new List<User>{u});
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;

        // create case record
        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case caseObj = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                AccountId = acc.Id, Clearance_eligibility_assessment_date__c = System.Today().addDays(12) ,Symptoms_Onset_Date__c = System.Today());
        insert caseObj;
    }
    
    @isTest static void testPathologySlipGeneration() {
        
        // get case record
        Case caseRecord = [Select Id from case Limit 1];

        PageReference pageRef = Page.PathologySlip;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(caseRecord.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(caseRecord);

        Test.startTest();
            DHHSPathologySlipExtension pathologySlipObj = new DHHSPathologySlipExtension(sc);
            System.assertEquals(pathologySlipObj.recordDetails.Id, caseRecord.Id);
        Test.stopTest();
    }
}