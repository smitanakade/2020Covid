/*
Created by: Hasantha E

@Modification Log   :
---------------------------------------------------
Date           Author      		    Details
16/03/2021     Hasantha E           Feature 265251: generate interview work orders with the schedular -
---------------------------------------------------
*/
global with sharing class GenerateInterviewWorkOrdersBatch implements Database.Batchable<SObject> , Database.Stateful {
    // following 2 attributes are to track errors when the batch job fails
    global Integer totalRecord;
    global Integer failedRecord;
    global GenerateInterviewWorkOrdersBatch() {}
    global Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // feting all the eligible records to be processed,
        // when the clearance eligibility date today or greater
        if(!Test.isRunningTest()) {
            return Database.getQueryLocator([
                    SELECT Id
                            , Clearance_eligibility_assessment_date__c
                            , AccountId
                            , ContactId
                            , OwnerId
                    FROM Case
                    WHERE Clearance_eligibility_assessment_date__c != null
                    AND Clearance_eligibility_assessment_date__c = TODAY
                    AND RecordTypeId =: confirmedCaseRecordTypeId
            ]);
        } else {
            // this is to handle the unit tests
            return Database.getQueryLocator('SELECT Id, Clearance_eligibility_assessment_date__c, AccountId, ContactId, OwnerId  ' +
                    ' FROM Case ' +
                    ' WHERE Clearance_eligibility_assessment_date__c != null AND RecordTypeId =: confirmedCaseRecordTypeId');
        }
    }

    global void execute(Database.BatchableContext bc, List<sObject> records) {
        try {
            //insert work orders
            if (!records.isEmpty()) {
                //to allow partial insert
                Database.SaveResult[] srList = WorkOrderTriggerHelper.generateClearanceWorkOrders(records);
                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        failedRecord++;
                    }
                    totalRecord++;
                }
            }
        } catch(Exception e) {
            //NOTE: waiting on the error framework to complete
            System.debug(e);
        }
    }

    global void finish(Database.BatchableContext bc) {
        // execute any post-processing operations like sending email (ignore when running tests)
        if (!Test.isRunningTest()) BatchNotificationEmailService.sendEmail(GenerateInterviewWorkOrdersBatch.class.getName(), totalRecord, failedRecord);
    }

}