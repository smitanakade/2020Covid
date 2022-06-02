/**
 * @Author             : YPerera
 * @Description        : Test Class for OnGoingExposureOperationsBatch
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 20/09/2021     YPerera		        252802 - When creating a new contact encounter participant, need to be able to select 'Ongoing exposure' checkbox
**/
@isTest
private class OnGoingExposureOperationBatchTest {

    @testSetup
    static void setupTestData() {
        try{
            Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
            
            List<Account> personAccList = TestDataFactory.createAccount(50, 'Active','Person Account');

            Case parentCase = new Case(recordTypeId=closeContactRecordTypeId, Status='Identify', Subject='Test Parent Case', AccountId=personAccList[0].Id, Day_15_Anticipated_release_date__c = Date.today(), Day_0_Exposure_to_the_confirmed_case__c = Date.today() - 14);
            insert parentCase;
        }catch(Exception exp){
            ApplicationLogUtility.createlog('OnGoingExposureOperationBatchTest','setupTestData',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
    
    @IsTest
    static void closeContactOnGoingExposureDateUpdateToTodayTest() {
        try{
            Case parentCase = [SELECT Id, On_going_exposure__c, Day_0_Exposure_to_the_confirmed_case__c FROM Case WHERE Subject='Test Parent Case' LIMIT 1];
            
            System.assertEquals(false, parentCase.On_going_exposure__c);
            System.assertEquals(Date.today() - 14, parentCase.Day_0_Exposure_to_the_confirmed_case__c);
            
            parentCase.On_going_exposure__c = true;
            update parentCase;
            
            Test.startTest();
            Database.executeBatch(new OnGoingExposureOperationsBatch(), 200);
            Test.stopTest();
            
            parentCase = [SELECT Id, On_going_exposure__c, Day_0_Exposure_to_the_confirmed_case__c FROM Case WHERE Subject='Test Parent Case' LIMIT 1];        
            System.assertEquals(Date.today(), parentCase.Day_0_Exposure_to_the_confirmed_case__c);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('OnGoingExposureOperationBatchTest','closeContactOnGoingExposureDateUpdateToTodayTest',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
        }
    }
}