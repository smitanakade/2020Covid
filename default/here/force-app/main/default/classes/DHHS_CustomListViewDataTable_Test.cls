@isTest
public without sharing class DHHS_CustomListViewDataTable_Test {

    // test setup method to create and setup records
    @testSetup static void setup() {

        // get user record
        User u = new User(Id=UserInfo.getUserId());
        UserTriggerHandler.addHCPermissionSets(new List<User>{u});
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;

        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;

        // create case record
        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                AccountId = acc.Id, Clearance_eligibility_assessment_date__c = System.Today().addDays(12) ,Symptoms_Onset_Date__c = System.Today(), EntitlementId = entl.Id);
        insert cse;

        // create location record
        Schema.Location loc1 = New Schema.Location();
        loc1.Name = 'test';
        insert loc1;

        // create contact encounter record
        ContactEncounter contactEnc = new ContactEncounter ();
        contactEnc.Name = 'At Home';
        contactEnc.Location__c = loc1.Id;
        contactEnc.LocationId = loc1.Id;
        contactEnc.Record__c = cse.Id;
        contactEnc.StartTime = DateTime.now();
        contactEnc.End_Time__c = DateTime.now().addDays(3);
        insert contactEnc;
        //DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);

        // create contact encounter record
        ContactEncounter contactEnc2 = new ContactEncounter ();
        contactEnc2.Name = 'At Home';
        contactEnc2.Location__c = loc1.Id;
        contactEnc2.LocationId = loc1.Id;
        contactEnc2.Record__c = cse.Id;
        contactEnc2.StartTime = DateTime.now();
        contactEnc2.End_Time__c = DateTime.now().addDays(3);
        insert contactEnc2;
        //DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc2);

        // create contact encounter record
        ContactEncounter contactEnc3 = new ContactEncounter ();
        contactEnc3.Name = 'At Home';
        contactEnc3.Location__c = loc1.Id;
        contactEnc3.LocationId = loc1.Id;
        contactEnc3.Record__c = cse.Id;
        contactEnc3.StartTime = DateTime.now();
        contactEnc3.End_Time__c = DateTime.now().addDays(3);
        contactEnc3.RecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByName().get('Movement').getRecordTypeId();
        insert contactEnc3;
        //DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc3);
    }
    
    @isTest static void testFetchRecordsWithoutAdditionalFilters() {
        
        // get case record
        Case caseRecord = [Select Id from case Limit 1];

        String inputString = 'ContactEncounter' + '-' + 'CalculatedDay__c, StartTime, Name, Location__r.Name, Duration_Days_Hours_Minutes__c, Movement_Notes__c' + '-' +   
        'Record__c'+ '-' + caseRecord.Id + '-' + 
        'StartTime' + '-'+ '25' + '-' +
        'undefined' +'-'+ 'undefined'; 

        Test.startTest();
            List<ContactEncounter> contactEncounterList = DHHS_CustomListViewDataTableController.fetchRecs(inputString);
            System.assertEquals(contactEncounterList.size(), 3);
        Test.stopTest();
    }

    @isTest static void testFetchRecordsWithoutRecordCountsLimit() {
        
        // get case record
        Case caseRecord = [Select Id from case Limit 1];

        String inputString = 'ContactEncounter' + '-' + 'CalculatedDay__c, StartTime, Name, Location__r.Name, Duration_Days_Hours_Minutes__c, Movement_Notes__c' + '-' +   
        'Record__c'+ '-' + caseRecord.Id + '-' + 
        'StartTime' + '-'+ 'undefined' + '-' +
        'undefined' +'-'+ 'undefined'; 

        Test.startTest();
            List<ContactEncounter> contactEncounterList = DHHS_CustomListViewDataTableController.fetchRecs(inputString);
            System.assertEquals(contactEncounterList.size(), 3);
        Test.stopTest();

    }
    
    @isTest static void testFetchRecordsWithAdditionalFilters() {
        
        // get case record
        Case caseRecord = [Select Id from case Limit 1];

        String inputString = 'ContactEncounter' + '-' + 'CalculatedDay__c, StartTime, Name, Location__r.Name, Duration_Days_Hours_Minutes__c, Movement_Notes__c' + '-' +   
        'Record__c'+ '-' + caseRecord.Id + '-' + 
        'StartTime' + '-'+ '25' + '-' +
        'StartTime' +'-'+ DateTime.now().addMinutes(7).getTime(); 

        Test.startTest();
            List<ContactEncounter> contactEncounterList = DHHS_CustomListViewDataTableController.fetchRecs(inputString);
            
        Test.stopTest();
    }

    @isTest static void testFetchRecordsWithRecordTypeFilters() {
        // get case record
        Case caseRecord = [Select Id from case Limit 1];

        String inputString = 'ContactEncounter' + '-' + 'CalculatedDay__c, StartTime, Name, Location__r.Name, Duration_Days_Hours_Minutes__c, Movement_Notes__c' + '-' +   
        'Record__c'+ '-' + caseRecord.Id + '-' + 
        'StartTime' + '-'+ '25' + '-' +
        'undefined' +'-'+ 'undefined'; 

        Test.startTest();
            List<ContactEncounter> contactEncounterList = DHHS_CustomListViewDataTableController.fetchRecs(inputString);
            
        Test.stopTest();
    }
}