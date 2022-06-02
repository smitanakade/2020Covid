/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test class for VaccinationDetailsController
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         ABN 
* @version        1.0
* @created        2021-06-19
*/


@IsTest
public with sharing class VaccinationDetailsControllerTest {
  
    @testSetup static void testDataSetup() {
        Id accountRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        Id secondaryCloseContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
        Id interviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
        Id cepCloseConRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();    


       
        Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='Test1 FName', LastName='Test1 LName',PersonMailingStreet='101 Collins Street',
                         PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test11112@gmail.com', PersonHomePhone='1234567',PersonMobilePhone='+614444');
        insert accountRecord;
        
        Id contactId = [Select PersonContactId from Account where Id=:accountRecord.Id][0].PersonContactId;

        Case closeContact = new Case(recordTypeId=closeContactRecordTypeId ,Status='Identify',Subject='Test closeContact',
                             AccountId=accountRecord.Id, ContactId = contactId);
        //Case closeContact = new Case(recordTypeId=closeContactRecordTypeId ,Status='Identify',AccountId=accountRecord.Id);
        insert closeContact;
        
        Case secondaryCloseContact = new Case(recordTypeId=secondaryCloseContactRecordTypeId ,Status='Identify',Subject='Test secondaryCloseContact',
                             AccountId=accountRecord.Id, ContactId = contactId);
        insert secondaryCloseContact;
        
      
        WorkOrder closeContactWorkOrder = new WorkOrder(recordTypeId=interviewWORecordTypeId, Status='In Progress', Subject='Initial close contact interview',
                             AccountId=accountRecord.Id,ContactId=contactId, CaseId = closeContact.Id);
        
        insert closeContactWorkOrder;

      
       

    }
    @IsTest
    static void Test_createCCEHRImmunization() {
        List<HealthCloudGA__EhrImmunization__c> ehrRecordList;
        HealthCloudGA__EhrImmunization__c ehrRecord;
        Vaccine__c newVaccine=new Vaccine__c();
        newVaccine.Name='Astra';
        insert newVaccine;
        Id interviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
        WorkOrder closeContactWorkOrder = [Select Id, ContactId, Status from WorkOrder Where recordtypeId=:interviewWORecordTypeId LIMIT 1];
        
        
        HealthCloudGA__EhrImmunization__c healthCloudObj=new HealthCloudGA__EhrImmunization__c();
        healthCloudObj.Contact__c =closeContactWorkOrder.ContactId ;
        healthCloudObj.Country__c = 'AUS';
        healthCloudObj.Vaccine__c = newVaccine.id;
        healthCloudObj.Have_you_had_a_COVID_19_vaccine__c = true;
        healthCloudObj.Date_administered__c = System.today();
        healthCloudObj.Validation_Status__c = '1';
        
        healthCloudObj.Notes__c = 'Test EHR';    
        Test.startTest();
        VaccinationDetailsController.createhealthCloudRecordOnSubmit(closeContactWorkOrder.ContactId, healthCloudObj);
        Test.stopTest();
        ehrRecordList = [select Id,name from HealthCloudGA__EhrImmunization__c where contact__c=:closeContactWorkOrder.ContactId];
        System.assertEquals(1, ehrRecordList.size());
        
    }

    @IsTest
    static void Test_retrieveCCEHRImmunization() {
        List<HealthCloudGA__EhrImmunization__c> ehrRecordList;
        HealthCloudGA__EhrImmunization__c ehrRecord;
        Vaccine__c newVaccine=new Vaccine__c();
        newVaccine.Name='Astra';
        insert newVaccine;
        Id interviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
        WorkOrder closeContactWorkOrder = [Select Id, ContactId, Status from WorkOrder Where recordtypeId=:interviewWORecordTypeId LIMIT 1];
        
        
        HealthCloudGA__EhrImmunization__c healthCloudObj=new HealthCloudGA__EhrImmunization__c();
        healthCloudObj.Contact__c =closeContactWorkOrder.ContactId ;
        healthCloudObj.Country__c = 'AUS';
        healthCloudObj.Vaccine__c = newVaccine.id;
        healthCloudObj.Have_you_had_a_COVID_19_vaccine__c = true;
        healthCloudObj.Date_administered__c = System.today();
        healthCloudObj.Validation_Status__c = '1';
        
        healthCloudObj.Notes__c = 'Test EHR';    
        Test.startTest();
        VaccinationDetailsController.createhealthCloudRecordOnSubmit(closeContactWorkOrder.ContactId, healthCloudObj);
        VaccinationDetailsController.getInitialData(closeContactWorkOrder.ContactId);
        Test.stopTest();
        ehrRecordList = [select Id,name from HealthCloudGA__EhrImmunization__c where contact__c=:closeContactWorkOrder.ContactId];
        System.assertEquals(1, ehrRecordList.size());
        
    }
}
