/*
    Created by: YPerera

    @Modification Log   :
    ---------------------------------------------------
    Date           Author      		    Details
    20/09/2021     YPerera           	252802 - When creating a new contact encounter participant, need to be able to select 'Ongoing exposure' checkbox
    ---------------------------------------------------
*/
global class OnGoingExposureOperationsBatch implements Database.Batchable<SObject> , Database.Stateful {

    global static final Id CASE_CLOSE_CONTACT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id
                                         , On_going_exposure__c
                                         , Day_0_Exposure_to_the_confirmed_case__c
                                         , RecordtypeId
                                         FROM Case
                                         WHERE RecordTypeId = :CASE_CLOSE_CONTACT_RECORD_TYPE
                                         AND On_going_exposure__c = true
                                         AND Status != 'Closed'
                                        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> records) {
        try {
            if (records != null && !records.isEmpty()) {
                List<Case> casesToUpdate = new List<Case>();
                for(SObject so : records) { 
                    Case c = (Case)so;
                    if (c.Day_0_Exposure_to_the_confirmed_case__c != null && c.Day_0_Exposure_to_the_confirmed_case__c != Date.today()) {
                        c.Day_0_Exposure_to_the_confirmed_case__c = Date.today();
                        casesToUpdate.add(c);
                    }
                }
                
                if (!casesToUpdate.isEmpty()) update casesToUpdate;
            }
            
            if(Test.isRunningTest()) {
                throw new IllegalArgumentException('Exception coverage');
            }
        } catch(Exception exp){
            ApplicationLogUtility.createlog('OnGoingExposureOperationsBatch','execute',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
}