/**
 * @Author             : Abbas Bagichawala
 * @Description        : CSRTriggerHandler test class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 25/11/2021     Abbas Bagichawala         
 *
**/
@IsTest
public with sharing class CSRTriggerHandlerTest {
    
    @testSetup static void setup() {
        	//create accounts
            List<Account> accountList = TestDataFactory.createAccount(5, 'Active','Person Account');
            //create cases
            List<Case> caseListData = TestDataFactory.createCases(accountList.get(0), 15, 'Quarantine','COVID-19 Case Assessment');
    		Occupation__c occObj = new Occupation__c(Name = 'Consultant');
        	insert occObj;
    }
	
	@isTest
	static void testCreateHMIP() {
        List<Case> caseList = [select id from case where recordtype.name = 'COVID-19 Case Assessment'];
        system.debug('CaseList'+caseList);
        Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[0].Id;
        survey1.What_date_did_you_start_to_isolate__c = system.today();
        survey1.Subject__c = CSRTriggerHelper.HMIP_DETAILS;
        Test.startTest();
        insert survey1;
        List<HealthCloudGA__EhrEncounter__c> lstHMIP = [select id from HealthCloudGA__EhrEncounter__c where record__c = : caseList[0].Id];
        Test.stopTest();        
		system.assertEquals(1,lstHMIP.size()); //This assert checks if HMIP record is created in system or not.        
    }
    
    @isTest
    static void createContactEncounterWSCwithOcc() {
        List<Case> caseList = [select id from case where recordtype.name = 'COVID-19 Case Assessment'];
        Occupation__c occObj = new Occupation__c(Name = 'Consultant');
        system.debug('CaseList'+caseList);
    	Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[2].Id;
        survey1.What_is_your_job_title__c = 'Consultant';
        survey1.What_is_your_employment_status__c = 'Employed';
        survey1.Subject__c = CSRTriggerHelper.WSC_DETAILS;
        Test.startTest();
        insert occObj;
        insert survey1;
        List<ContactEncounter> lstCERecord = [select id,name from ContactEncounter where record__c = : caseList[2].Id];
        Test.stopTest();
        //system.assertEquals('Consultant',lstCERecord[0].Name); //This assert checks if WSC record name is matching with selected Occupation on survey.
    }
    
    @isTest
    static void createContactEncounterWSCwithOccOther() {
        List<Case> caseList = [select id from case where recordtype.name = 'COVID-19 Case Assessment'];
        Occupation__c occObj = new Occupation__c(Name = 'Consultant');
        system.debug('CaseList'+caseList);
    	Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[3].Id;
        survey1.What_is_your_job_title__c = 'Other';
        survey1.Other_Occupation__c  = 'Testing';
        survey1.What_is_your_employment_status__c = 'Employed';
        survey1.Subject__c = CSRTriggerHelper.WSC_DETAILS;
        Test.startTest();
        insert occObj;
        insert survey1;
        List<ContactEncounter> lstCERecord = [select id,name from ContactEncounter where record__c = : caseList[3].Id];
        Test.stopTest();
        //system.assertEquals('Testing',lstCERecord[0].Name); //This assert checks if WSC record name is matching Other Occupation.
    }
    
    @isTest
    static void createContactEncounterWSCwithoutOcc() {
        List<Case> caseList = [select id from case where recordtype.name = 'COVID-19 Case Assessment'];
        Occupation__c occObj = new Occupation__c(Name = 'Consultant');
        system.debug('CaseList'+caseList);
    	Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[4].Id;
        survey1.What_is_your_employment_status__c = 'Employed';
        survey1.Subject__c = CSRTriggerHelper.WSC_DETAILS;
        Test.startTest();
        insert occObj;
        insert survey1;
        List<ContactEncounter> lstCERecord = [select id,name from ContactEncounter where record__c = : caseList[4].Id];
        Test.stopTest();        
		//system.assertEquals('Employed',lstCERecord[0].Name); //This assert checks if WSC record name is matching employment status.
    }
    
    @isTest
	static void testcreateEHRImmunization() {
        List<Case> caseList = [select id,account.personcontactid from case where recordtype.name = 'COVID-19 Case Assessment'];
        system.debug('CaseList'+caseList);
        Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[6].Id;
        survey1.Have_you_had_a_COVID_19_vaccine__c = 'Yes';
        survey1.Subject__c = CSRTriggerHelper.EHR_DETAILS;
        Test.startTest();
        insert survey1;
        List<HealthCloudGA__EhrImmunization__c> lstEHR = [select id from HealthCloudGA__EhrImmunization__c where contact__c = : caseList[6].account.personcontactid];
        Test.stopTest();        
		system.assertEquals(1,lstEHR.size()); //This assert checks if EHR Immunization record is created in system or not.        
    }
    
    @isTest
	static void testCreateContactEncounterTravelHistory() {
        List<Case> caseList = [SELECT Id,Account.PersonContactId FROM Case WHERE RecordType.Name = 'COVID-19 Case Assessment'];
        Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[7].Id;
        survey1.Returned_from_overseas_in_the_past_14day__c = 'Yes';
        survey1.Countries_visited_in_the_past_14_days__c = 'Japan, USA, Europe';
        survey1.Subject__c = CSRTriggerHelper.THistory_DETAILS;
        Test.startTest();
        insert survey1;
        List<ContactEncounter> lstTH = [SELECT Id, Name, RecordType.DeveloperName, Recent_Travel_Overseas__c, Country__c,
                Recent_Travel_Overseas_Notes__c, StartTime  FROM ContactEncounter WHERE Record__c = : caseList[7].Id];
        Test.stopTest();
		System.assertEquals(1, lstTH.size(),'Travel History record should be created in system'); //This assert checks if Travel History record is created in system or not.
        System.assertEquals('Travel_History', lstTH[0].RecordType.DeveloperName, 'ContactEncounter record type should be Travel_History');
        System.assertEquals(CSRTriggerHelper.TRAVEL_HISTORY_CONTACT_ENCOUNTER_NAME, lstTH[0].Name, 'Name was not correctly set');
        System.assertEquals('Yes', lstTH[0].Recent_Travel_Overseas__c, 'Recent_Travel_Overseas__c should be set from Returned_from_overseas_in_the_past_14day__c');
        System.assertEquals('UNK', lstTH[0].Country__c, 'Country__c was not correctly set');
        System.assertEquals('Japan, USA, Europe', lstTH[0].Recent_Travel_Overseas_Notes__c, 'Recent_Travel_Overseas_Notes__c should be set from Countries_visited_in_the_past_14_days__c');
    }

    @isTest
	static void testCreateCAR() {
        List<Case> caseList = [select id,account.personcontactid from case where recordtype.name = 'COVID-19 Case Assessment'];
        system.debug('CaseList'+caseList);
        Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[8].Id;
        survey1.had_any_symptoms_in_the_last_5days__c = 'Yes';
        survey1.Subject__c = CSRTriggerHelper.CAR_DETAILS;
        system.debug('-->'+survey1);
        Test.startTest();
        insert survey1;
        List<HealthCloudGA__Clinical_Assessment_Response__c> lstCAR = [select id from HealthCloudGA__Clinical_Assessment_Response__c where Record__c = : caseList[8].id];
        system.debug('lstCAR'+lstCAR);
        Test.stopTest();        
		system.assertEquals(lstCAR.size(),1); //This assert checks if Clinical assesment response record is created in system or not.        
    }
    
    @isTest
	static void testCreateCARNoCreation() {
        List<Case> caseList = [select id,account.personcontactid from case where recordtype.name = 'COVID-19 Case Assessment'];
        system.debug('CaseList'+caseList);
        Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[9].Id;
        survey1.Subject__c = CSRTriggerHelper.CAR_DETAILS;
        system.debug('-->'+survey1);
        Test.startTest();
        insert survey1;
        List<HealthCloudGA__Clinical_Assessment_Response__c> lstCAR = [select id from HealthCloudGA__Clinical_Assessment_Response__c where Record__c = : caseList[9].id];
        Test.stopTest();        
		system.assertEquals(lstCAR.size(),0); //This assert checks if Clinical assesment response record should not be created in system.        
    }
	
    @isTest
	static void createContactEncounterWSC() {
        List<Case> caseList = [SELECT Id FROM Case WHERE RecordType.Name = 'COVID-19 Case Assessment'];
        Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[5].Id;
        survey1.What_is_your_job_title__c = 'Consultant';
        survey1.What_is_your_employment_status__c = 'Employed';
        survey1.Subject__c = CSRTriggerHelper.WSC_DETAILS;
		Test.startTest();
        insert survey1;
        List<ContactEncounter> ceWSCData = [SELECT Id,Employment_Status__c,Name,Occupation__c FROM ContactEncounter WHERE Record__c = : caseList[5].Id OR Employment_Status__c = 'Employed'];
        Test.stopTest();        
		System.assertEquals(1,ceWSCData.size(),'WSC record should be created'); //This assert checks if WSC record is created in system or not.
        System.assertEquals('Consultant', ceWSCData[0].Name, 'Name should be set with the value from survey response');
        System.assertEquals('Employed', ceWSCData[0].Employment_Status__c, 'Employment_Status__c should be set with the value from survey response');
    }
    
    @isTest
	static void testcreateSingleCloseContactPersonAccount() {
        List<Case> caseList = [select id,account.personcontactid from case where recordtype.name = 'COVID-19 Case Assessment'];
        system.debug('CaseList'+caseList);
        Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[10].Id;
        survey1.Subject__c = 'Close Contact 1';
        survey1.Date_you_last_had_contact_with_this_pers__c = system.today();
        survey1.Street__c = 'Hasall Street';
        survey1.City__c = 'Paramatta';
        survey1.PostCode__c = '2150';
        survey1.State__c = 'NSW';
        survey1.First_Name__c = 'DEF';
        survey1.Last_Name__c = 'ABC';
        survey1.DOB__c = system.today();
        survey1.Mobile_Phone__c = '1212312312';
        survey1.Do_you_live_with_this_person__c = 'No';
        system.debug('-->'+survey1);
        Survey_Response__c survey2 = new Survey_Response__c();
        survey1.First_Name__c = 'XYZ';
        survey1.Last_Name__c = 'MNO';
        survey2.Do_you_live_with_this_person__c = 'Yes';
        survey2.Record__c = caseList[12].id;
        survey2.Subject__c = 'Close Contact 1';
        system.debug('-->'+survey2);
        Test.startTest();
        insert survey2;
        insert survey1;
        Test.stopTest();        
		//system.assertEquals( lstTH.size(),1); //This assert checks if Travel History record is created in system or not.        
    }

    @IsTest
    static void testUpdateAccount() {
        List<Case> caseList = [SELECT Id,Account.PersonContactId FROM Case WHERE RecordType.Name = 'COVID-19 Case Assessment'];
        Survey_Response__c survey1 = new Survey_Response__c();
        survey1.Record__c = caseList[10].Id;
        survey1.Subject__c = CSRTriggerHelper.ACCOUNT_DETAILS;
        survey1.Street__c = 'Hasall Street';
        survey1.City__c = 'Paramatta';
        survey1.PostCode__c = '2150';
        survey1.State__c = 'NSW';
        survey1.First_Name__c = 'DEF';
        survey1.Last_Name__c = 'ABC';
        survey1.DOB__c = System.today() - 40;
        survey1.Mobile_Phone__c = '1212312312';
        survey1.What_is_your_country_of_birth__c = 'Australia';
        Test.startTest();
        insert survey1;
        Test.stopTest();
        for (Account accountData : [
                SELECT Id, FirstName, LastName, PersonMailingStreet, PersonMailingCity,
                        PersonMailingPostalCode, PersonMailingState, PersonBirthdate, PersonMobilePhone,Country_of_birth__c
                FROM Account
                WHERE Id = :caseList[10].AccountId
        ]) {
            System.assertEquals(survey1.First_Name__c, accountData.FirstName, 'Incorrect FirstName retrieved');
            System.assertEquals(survey1.Last_Name__c, accountData.LastName, 'Incorrect LastName retrieved');
            System.assertEquals(survey1.Street__c, accountData.PersonMailingStreet, 'Incorrect PersonMailingStreet retrieved');
            System.assertEquals(survey1.PostCode__c, accountData.PersonMailingPostalCode, 'Incorrect PersonMailingPostalCode retrieved');
            System.assertEquals(survey1.State__c, accountData.PersonMailingState, 'Incorrect PersonMailingState retrieved');
            System.assertEquals(survey1.DOB__c, accountData.PersonBirthdate, 'Incorrect PersonBirthdate retrieved');
            System.assertEquals(survey1.Mobile_Phone__c, accountData.PersonMobilePhone, 'Incorrect PersonMobilePhone retrieved');
			System.assertEquals('AUS', accountData.Country_of_birth__c, 'Incorrect CountryofBirth retrieved');
        }
    }
    
}