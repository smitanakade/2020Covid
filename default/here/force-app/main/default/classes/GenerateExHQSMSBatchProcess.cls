/**
* @Author             : Suraj Sood
* @Description        : Batch Class
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 11/04/2021     Suraj Sood        	   PBI 274739: Send SMS Ex HQ day 2 and Day 6

**/

public class GenerateExHQSMSBatchProcess implements Database.Batchable<sObject>{
    public final String query; 

    public GenerateExHQSMSBatchProcess(){

        String closeContactRecordTypeId  = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
        String casualContactRecordTypeId  = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Casual Contact').getRecordTypeId();
        String secondaryCloseContactRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Secondary Close Contact').getRecordTypeId();
        
        if(Test.isRunningTest()){//for testing
            query = 'SELECT Id, Status, Hotel_Quarantine_End_Date__c ' +
                    'FROM Case WHERE '+
                    'Subject = \'Test Batch Class ExHQ\' '+
                    'AND Status = \'Ex-HQ Follow-up\' '+
                    'AND AccountId != null '+
                    'AND Hotel_Quarantine_End_Date__c != null '+
                    'AND (RecordTypeId = \'' + closeContactRecordTypeId + '\' OR RecordTypeId = \'' + casualContactRecordTypeId + '\' OR RecordTypeId = \'' +
                								secondaryCloseContactRecordTypeId + '\') LIMIT 25';

            System.Debug('*** GenerateExHQSMSBatchProcess: query'+query);
        } else {
            query = 'SELECT Id, Status, Hotel_Quarantine_End_Date__c ' +
                    'FROM Case WHERE '+
                    'Account.PersonMobilePhone != null '+
                    'AND Status = \'Ex-HQ Follow-up\' '+
                    'AND AccountId != null '+
                    'AND Hotel_Quarantine_End_Date__c != null '+
                    'AND (RecordTypeId = \'' + closeContactRecordTypeId + '\' OR RecordTypeId = \'' + casualContactRecordTypeId + '\' OR RecordTypeId = \'' +
                								secondaryCloseContactRecordTypeId + '\') ';

                    
            System.Debug('*** GenerateExHQSMSBatchProcess: query' + query);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query); 
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
    	List<Case> casestatusOEB = (List<Case>)scope; //List of cases

        try{
            System.debug('***STARTING  GenerateExHQSMSBatchProcess  at:' + System.now());
            for(Case thisCase : casestatusOEB ){
                Integer noOfHQDays = thisCase.Hotel_Quarantine_End_Date__c.daysBetween( Date.today() );

                // update the Message template id for records in scope,
                // Updating Message template will trigger a Message and Task creation from Process : Case_SendSMS
                // no of days frequency is in cus label
                if(noOfHQDays == Integer.valueOf(System.Label.Ex_Hotel_Quarantine_First_SMS)){// HQ First Scenario
                    thisCase.MessagingTemplate__c = 'Ex_Hotel_Quarantine_Day_2';     
                }else if(noOfHQDays == Integer.valueOf(System.Label.Ex_Hotel_Quarantine_Second_SMS)){// HQ Second Scenario
                    thisCase.MessagingTemplate__c = 'Ex_Hotel_Quarantine_Day_6';     
                }
            }
            update casestatusOEB;
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateExHQSMSBatchProcess','execute',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
    
    //Any post processing steps here
    public void finish(Database.BatchableContext BC){ 
    }
}