@isTest
private class MergedCaseTriggerHandlerTest {
    @testSetup
    static void setupTestData() {
        Id accountRecordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        Id secondaryCloseContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
        Id cepCloseConRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();        

        Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='Test FName', LastName='Test LName',PersonMailingStreet='101 Collins Street',
                                            PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test@gmail.com', PersonHomePhone='1234567',PersonMobilePhone='+614444');
        insert accountRecord;
        
        Id contactId = [Select PersonContactId from Account where Id=:accountRecord.Id][0].PersonContactId;
        
        Case closeContact = new Case(recordTypeId=closeContactRecordTypeId ,Status='Quarantine' ,SubStatus__c='In Progress',Subject='Test',
                                    AccountId=accountRecord.Id, Day_0_Exposure_to_the_confirmed_case__c=System.Today()-6);
        insert closeContact;
    }

    @isTest
    static void testMergedCaseNumbers() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Merged_Case__e mergedCaseNumbers = new Merged_Case__e(Master_Case_ID__c = testCase.Id, Merged_Case_IDs__c = '12345, 67890');

        EventBus.publish(mergedCaseNumbers);

        Test.getEventBus().deliver();

        //testCase = [SELECT Id, Merged_Case_IDs__c FROM Case WHERE Id = :testCase.Id];

        //System.assertEquals('12345, 67890', testCase.Merged_Case_IDs__c);
    }
}