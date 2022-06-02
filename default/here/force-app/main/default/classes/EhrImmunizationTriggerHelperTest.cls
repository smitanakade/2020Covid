/*
Author: Arun
 
@Modification Log   :  
---------------------------------------------------
Date           Author      		    Details
---------------------------------------------------
15/06/2021     Arun       Feature 272348: Modified to use common trigger framework
19/10/2021     Xiang      Feature 330357: Marketing Cloud - TREVI changes for PCC Triage message
25/10/2021     Xiang      Feature 331107: Logic change for calculating Fully vaccinated person
*/
@isTest
private class EhrImmunizationTriggerHelperTest {
    private static Id accountRecordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

    @testSetup
    static void setupTestData() {
        Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='Test FName', LastName='Test LName',PersonMailingStreet='101 Collins Street',
                                            PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test@gmail.com', PersonHomePhone='1234567',PersonMobilePhone='+614444');
        insert accountRecord;
    }
    
    @isTest 
    static void vaccinationRecordSuccess(){
        Id contactId = [Select PersonContactId from Account where recordTypeId =:accountRecordTypeId LIMIT 1].PersonContactId;
        HealthCloudGA__EhrImmunization__c EhrRec = new HealthCloudGA__EhrImmunization__c();
        EhrRec.Contact__c=contactId;
        EhrRec.Have_you_had_a_COVID_19_vaccine__c=true;
        insert EhrRec;
        
        Test.startTest();
        delete EhrRec;
        Test.stopTest();
        Contact conRec1 = [select Id, Any_vaccination_details_recorded__c from Contact where ID =:contactId];
        System.assertEquals(false,conRec1.Any_vaccination_details_recorded__c,'Vaccination Recorded set to false at Account level');
    }

    @isTest 
    static void updatePersonAccountInsertTest(){
        Id contactId = [Select PersonContactId from Account where  recordTypeId =:accountRecordTypeId LIMIT 1].PersonContactId;
        HealthCloudGA__EhrImmunization__c EhrRec = new HealthCloudGA__EhrImmunization__c();
        EhrRec.Contact__c=contactId;
        EhrRec.Have_you_had_a_COVID_19_vaccine__c=true;
        EhrRec.Dose_Received__c = '2nd';
        EhrRec.Validation_Status__c = '1';
        insert EhrRec;

        Contact conRec = [select Id, Any_vaccination_details_recorded__c from Contact where ID =:contactId];
        
        System.assertEquals(true,conRec.Any_vaccination_details_recorded__c,'Vaccination Recorded at Account level');
    }

    @isTest 
    static void updatePersonAccountUpdateTest(){
        Id contactId = [Select PersonContactId from Account where  recordTypeId =:accountRecordTypeId LIMIT 1].PersonContactId;
        HealthCloudGA__EhrImmunization__c EhrRec = new HealthCloudGA__EhrImmunization__c();
        EhrRec.Contact__c=contactId;
        EhrRec.Have_you_had_a_COVID_19_vaccine__c=true;
        EhrRec.Dose_Received__c = '1st';
        EhrRec.Validation_Status__c = '1';
        insert EhrRec;

        EhrRec.Dose_Received__c = '2nd';
        update EhrRec;

        Contact conRec = [select Id, Any_vaccination_details_recorded__c from Contact where ID =:contactId];
        
        System.assertEquals(true,conRec.Any_vaccination_details_recorded__c,'Vaccination Recorded at Account level');
    }

    @isTest 
    static void updatePersonAccountDeleteTest(){
        Id contactId = [Select PersonContactId from Account where  recordTypeId =:accountRecordTypeId LIMIT 1].PersonContactId;
        HealthCloudGA__EhrImmunization__c EhrRec = new HealthCloudGA__EhrImmunization__c();
        EhrRec.Contact__c=contactId;
        EhrRec.Have_you_had_a_COVID_19_vaccine__c=true;
        EhrRec.Dose_Received__c = '2nd';
        EhrRec.Validation_Status__c = '1';
        insert EhrRec;

        HealthCloudGA__EhrImmunization__c EhrRec1 = new HealthCloudGA__EhrImmunization__c();
        EhrRec1.Contact__c=contactId;
        EhrRec1.Have_you_had_a_COVID_19_vaccine__c=true;
        EhrRec1.Dose_Received__c = '2nd';
        EhrRec1.Validation_Status__c = '6';
        insert EhrRec1;

        delete EhrRec;

        Contact conRec = [select Id, Any_vaccination_details_recorded__c from Contact where ID =:contactId];
        
        System.assertEquals(false,conRec.Any_vaccination_details_recorded__c,'Vaccination Recorded at Account level');
    }
}