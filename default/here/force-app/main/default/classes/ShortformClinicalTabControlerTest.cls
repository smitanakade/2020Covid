/*
 * @Author             : Xiang Zheng
 * @Description        : test class for ShortformClinicalTabControler
 * @Modification Log   : 
 * --------------------------------------------------------------------------------------
 * Date           Author      		    Details
 * --------------------------------------------------------------------------------------
 * 06/09/2021     Xiang Zheng        Initial version
 * 05/10/2021     Mayukhman          Added the recordtype condition as PBI 27338: when Confirmed Case (Record) is created that is in Trace or Isolate status 
 * 17/11/2021     LJ                 Added the Travel history details
 */
@IsTest
private class ShortformClinicalTabControlerTest {
    @testSetup static void setupTestData() {
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;

        String recordTypeId1 = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Place Or Organisation').getRecordTypeId();
        Account acc1 = new Account(RecordTypeID = recordTypeId1, Name='test');
        insert acc1;

        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',Symptoms_Onset_Date__c = System.Today());
        insert cse;

        WorkOrder wrkOrdr = new WorkOrder(recordTypeId =Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Close Contact Interview').getRecordTypeId() , Status = 'Not Started', CaseId = cse.Id, Subject = 'Test Work Order',
                AccountId = acc.Id);
        insert wrkOrdr;

        Occupation__c testOcc = new Occupation__c();
        testOcc.name = 'test';
        insert testOcc;
    }

    @IsTest
    static void testCreateRecords() {
        //Added the recordtype condition as PBI 27338: when Confirmed Case (Record) is created that is in Trace or Isolate status 
        // new clearance work order will get created
        Id hqRecTYpeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Close Contact Interview').getRecordTypeId();
        WorkOrder work = [Select Id,CaseId,AccountId from Workorder Where RecordTypeId =: hqRecTYpeId limit 1];
        Account testAcc = [SELECT Id FROM Account WHERE recordType.Name = 'Business' limit 1];

        ShortformClinicalTabControler.FormWrapper testWrapper = new ShortformClinicalTabControler.FormWrapper();
        testWrapper.workOrderId = work.Id;
        testWrapper.haveAnySymptoms = 'Yes';
        testWrapper.dateOfFirstSymptoms = '2021-09-06';
        testWrapper.hadVaccine = 'true';
        testWrapper.dose = '1st';
        testWrapper.startDate = '2021-09-06';
        testWrapper.contactHospital14DaysPriorSymptoms = 'Yes';
        testWrapper.dateAdmitted = '2021-09-06';
        testWrapper.hospital = testAcc.Id;
        testWrapper.ifYesCommencedOn = '2021-09-06';
        testWrapper.recentTravelOverseas = 'Yes';
        testWrapper.countryOverseas ='ATA';

        ShortformClinicalTabControler.createRecords(testWrapper);
    }

    @IsTest
    static void testCheckAccountRecordType() {
        Account testAcc = [SELECT Id FROM Account limit 1];
        String result = ShortformClinicalTabControler.checkAccountRecordType(testAcc.Id);
    }

    @IsTest
    static void testCreateWSCRecord() {
        Occupation__c testOcc = [SELECT Id FROM Occupation__c LIMIT 1];
        WorkOrder work = [Select Id,CaseId,AccountId from Workorder limit 1];
        ContactEncounter testCE = new ContactEncounter();
        testCE.Occupation__c = testOcc.Id;
        testCE.Work_Order__c = work.Id;
        String result = ShortformClinicalTabControler.createWSCRecord(testCE);
        system.assertEquals('success', result);
    }

    @IsTest
    static void testGetdisabilitydetails() {
        WorkOrder work = [Select Id,CaseId,AccountId from Workorder limit 1];
        WorkOrder result = ShortformClinicalTabControler.getdisabilitydetails(work.Id);
        system.assertNotEquals(null, result);
    }
}