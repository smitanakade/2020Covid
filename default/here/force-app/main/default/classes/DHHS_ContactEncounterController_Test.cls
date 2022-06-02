@IsTest
public with sharing class DHHS_ContactEncounterController_Test {
    @IsTest
    public static void testFetchCase() {
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;

        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;

        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today(), EntitlementId = entl.Id);
        insert cse;

        Test.startTest();
        Case compare = DHHS_ContactEncounterController.fetchCase(cse.Id);

        try{
            Case testCase = DHHS_ContactEncounterController.fetchCase(null);
        } catch (Exception e) {

        }

        Test.stopTest();
        System.assertEquals(cse.Id, compare.Id);

    }


    @IsTest
    public static void testgetCaseIdByRecordId() {
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;

        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;

        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today(), EntitlementId = entl.Id);
        insert cse;

        // String interviewRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByName().get('Interview').getRecordTypeId();
        // WorkOrder wo = new WorkOrder(recordTypeId = interviewRecordTypeId, Status = 'In Progress', AccountId = acc.Id, CaseId=cse.Id, Priority='Low');
        // insert wo;

        Test.startTest();
        Id compareCaseId = DHHS_ContactEncounterController.getCaseIdByRecordId(cse.Id);
        //Id compareWorkOrderId = DHHS_ContactEncounterController.getCaseIdByRecordId(wo.Id);

        Test.stopTest();
        System.assertEquals(cse.Id, compareCaseId);
        // System.assertEquals(wo.Id, compareWorkOrderId);

    }

    @Istest
    public static void testcreateDirectContactEncounter() {

        User u = new User(Id=UserInfo.getUserId());
        UserTriggerHandler.addHCPermissionSets(new List<User>{u});
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;

        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;

        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Trace', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today().addDays(-5), Date_of_Test__c = System.Today().addDays(-2), Clearance_eligibility_assessment_date__c = System.Today().addDays(12), EntitlementId = entl.Id);
        insert cse;

        Schema.Location loc1 = New Schema.Location();
        loc1.Name = 'test';
        insert loc1;
        ContactEncounter contactEnc = new ContactEncounter ();
        Test.startTest();
        try {
            DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
        } catch (Exception e) {

        }
        contactEnc.Location__c = loc1.Id;
        contactEnc.LocationId = loc1.Id;
        contactEnc.Record__c = cse.Id;
        System.assertNotEquals(null, contactEnc.Location__c);
        try {
            DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
        } catch (Exception e) {

        }
        contactEnc.StartTime = DateTime.now();
        contactEnc.End_Time__c = DateTime.now().addDays(-1);

        try {
            DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
        } catch (Exception e) {

        }
        contactEnc.StartTime = contactEnc.StartTime.addDays(-25);
        try {
            DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
        } catch (Exception e) {

        }
        contactEnc.StartTime = contactEnc.StartTime.addDays(+90);
        contactEnc.End_Time__c = contactEnc.End_Time__c.addDays(+90);

        try {
            DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
        } catch (Exception e) {

        }
        contactEnc.StartTime = System.now().addDays(-1);
        contactEnc.End_Time__c = System.now();

        try {
            DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
        } catch (Exception e) {


            contactEnc.Name = 'At Home';

            DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
            List<ContactEncounter> movements = [Select Id from ContactEncounter];
            Test.stopTest();
            System.assertEquals(1,movements.size());

        }
    }

    @Istest
    public static void testLocationMappings() {
        map<string, string> mapLocationMappings  = DHHS_ContactEncounterController.fetchLocationsMappings();
        System.assertEquals(true, mapLocationMappings.size()>0);
    }
}