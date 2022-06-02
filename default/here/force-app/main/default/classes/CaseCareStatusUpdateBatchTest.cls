/**  
 * @Author             : Subbiah Kumaravel
 * @Description        : Set In care pathway or Self care pathway Test class, 
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 21/10/2021     Subbiah Kumaravel        Initial version
 * 
**/
@isTest
public class CaseCareStatusUpdateBatchTest {
    @IsTest
    static void testSchedular() {
        try{
            Test.startTest(); 
            String jobId = System.schedule('testScheduledApex', '0 0 9 * * ?', new CaseSurveyResponseScheduler());
            Test.stopTest();

            // Get the information from the CronTrigger API object
            List<CronTrigger> ct = [
                    SELECT Id, CronExpression, TimesTriggered, NextFireTime
                    FROM CronTrigger WHERE id = :jobId];

            System.assertNotEquals(0, ct.size());
        }catch(Exception exp){
            ApplicationLogUtility.createlog('CaseCareStatusUpdateBatchTest','testSchedular',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    @isTest
    static void setupTestData() {      
       try{
           //create accounts
            List<Account> accountList = TestDataFactory.createAccount(10, 'Active','Person Account');
			Map<Id,String> recordStatusMap = new Map<Id,String>();
            //create cases
            List<Case> caseListData = TestDataFactory.createCases(accountList.get(0), 10, 'Quarantine', 'Close Contact');
            List<Survey_Response__c> surveys = new List<Survey_Response__c>();
            Survey_Response__c survey1 = new Survey_Response__c();
            survey1.Record__c = caseListData[0].Id;
            survey1.Do_you_need_support__c = 'Yes';
            survey1.Record_Created_Status__c = false;
           survey1.Subject__c ='Confirmed Case Initial Triage';
           recordStatusMap.put(caseListData[0].Id, 'In care pathway');
            surveys.add(survey1);
                        
            Survey_Response__c survey2 = new Survey_Response__c();
            survey2.Record__c = caseListData[0].Id;
            survey2.Do_you_need_support__c = 'No';
            survey2.Have_received_both_doses_of_the_vaccine__c = 'Yes';
            survey2.How_sick_do_you_feel__c = 'A bit sick';
            survey2.Do_you_see_doctors_regularly__c = 'No';
            survey2.Happy_to_contact_your_GP_for_clinical_ca__c = 'Yes';
            survey2.Record_Created_Status__c = false;
           	survey2.Subject__c ='Confirmed Case Initial Triage';
            recordStatusMap.put(caseListData[0].Id, 'Self care pathway');

            surveys.add(survey2);
            insert surveys;
            
            Id jobId = Database.executeBatch(new CaseCareStatusUpdateBatch(), 200);   
        }catch(Exception exp){
            ApplicationLogUtility.createlog('CaseCareStatusUpdateBatchTest','setupTestData',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }   
}