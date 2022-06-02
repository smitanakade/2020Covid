@isTest
Private class EHRProcedureTriggerHelperTest {
	private static Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
    
    @IsTest
    static void createELRTask_Positive(){
		Account accountRecord = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

		//Sample case
		Case newCase = new Case(recordTypeId=confirmedCaseRecordTypeId ,Status='Trace',Subject='Test2',
                					AccountId=accountRecord.Id, Case_Classification__c = null , Data_Quality_check_completed__c = false , 
                                    Is_case_allocation_completed__c = true , SubStatus__c='In Progress' );

            
		Test.startTest();
		insert newCase;
        
        HealthCloudGA__EHRProcedure__c Procedure = new HealthCloudGA__EHRProcedure__c(Record__c = newCase.Id,Data_Quality_check_completed__c = false,HealthCloudGA__Account__c = accountRecord.Id  );
         insert Procedure;   
		//add first observation
		HealthCloudGA__EhrObservation__c observation_1 = new HealthCloudGA__EhrObservation__c(
		Record__c = newCase.Id, 
		HealthCloudGA__Account__c = accountRecord.Id , 
		Test_Type__c = null,
		Test_Result__c = null);
		insert observation_1;

        //add latest observation
		HealthCloudGA__EhrObservation__c observation_2 = new HealthCloudGA__EhrObservation__c(
		Record__c = newCase.Id, 
		HealthCloudGA__Account__c = accountRecord.Id , 
		Test_Type__c = 'PHESS-TEST-5',
		Test_Result__c = '10828004');
		insert observation_2;
            
		Procedure.Data_Quality_check_completed__c = True;
		update Procedure;
            
		Test.stopTest();

		//Confirm the task was created
		List<Task> tasks = new List<Task>();
		tasks = [Select Id , Subject FROM Task WHERE WhatId =: newCase.Id AND Subject = 'Rapid Antigen Screening Call'];
		//System.assert(tasks.size() == 1, 'No Rapid Antigen Screening Call Task Created ');
    }
}