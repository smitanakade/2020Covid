/**
 * @Author             : Chris Zhuang
 * @Description        : Apex Batch Job to create Secondary Close Contact Clearance WorkOrder
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 16/03/2021     Chris Zhuang          Feature 269161: All interview work orders should be automatically be created when new confirmed case or new primary close contact record is created - Part 3 (AC03)
**/
global class CloseContactWorkOrderBatchJob implements Database.Batchable<sObject>, Database.Stateful {
    global static final String BATCH_JOB_NAME = 'CloseContactWorkOrderBatchJob';

    global static final String RECORDTYPE_WORK_ORDER_SCC_CLEARANCE = 'Secondary_Close_Contact_Clearance';
    global static final String RECORDTYPE_CASE_SECONDARY_CLOSE_CONTACT = 'Secondary_Close_Contact';
    global static final String RECORDTYPE_CASE_CLOSE_CONTACT = 'Close_Contact';

    global static final String WO_STATUS_NEW   = 'New';
    global static final String WO_PRIORITY_LOW = 'Low';
    global static final String WO_PERSON_INTERVIEWED_SSC = 'Secondary Close Contact';
    global static final String WO_SUBJECT_SCC_CLEARANCE  = 'Secondary Close Contact Clearance';

    global static final String CEP_CONTACT_TYPE = 'Secondary Close Contact';

    global static final String EHR_OBSERVATION_OBJECT_APINAME     = 'HealthCloudGA__EhrObservation__c';
    global static final String EHR_OBSERVATION_FIELD_APINAME      = 'Test_Result__c';
    global static final String EHR_OBSERVATION_TEST_RESULT_VALUE  = 'Not detected';

    global static Id secondaryCloseContactClearanceRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_SCC_CLEARANCE).getRecordTypeId();

    global Integer totalRecord;
    global Integer failedRecord;

    global CloseContactWorkOrderBatchJob() {
        this.totalRecord  = 0;
        this.failedRecord = 0;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String testResultAPIName = '';
        Schema.SObjectType s = Schema.getGlobalDescribe().get(EHR_OBSERVATION_OBJECT_APINAME) ;
        Map<String,Schema.SObjectField> fields = s.getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(EHR_OBSERVATION_FIELD_APINAME).getDescribe();   
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple) {
            if (pickListVal.getLabel() == EHR_OBSERVATION_TEST_RESULT_VALUE) {
                testResultAPIName = pickListVal.getValue();
            }
        }

        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator([
                SELECT  Record__c,
                        Record__r.AccountId,
                        Record__r.Account.PersonContactId,
                        Record__r.OwnerId
                FROM ContactEncounterParticipant
                WHERE Record__r.RecordType.DeveloperName =: RECORDTYPE_CASE_SECONDARY_CLOSE_CONTACT
                      AND Record__r.On_going_exposure__c = FALSE
                      AND Record__r.Day_14_SCC_Calculated__c <= Today
                      AND Parent_Record__r.RecordType.DeveloperName =: RECORDTYPE_CASE_CLOSE_CONTACT
                      AND Parent_Record__r.Date_Cleared_from_Isolation__c = Today
                      AND Parent_Record__r.Latest_EHR_Observation__r.Test_Result__c =: testResultAPIName
        ]);
    }

    /* process each batch */
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<WorkOrder> workOrderToInsertList = new List<WorkOrder>();
        //Now, we loop the case again to figure which one we need to create workorder
        for(SObject so : scope) {
            ContactEncounterParticipant cep = (ContactEncounterParticipant)so;
            //create work order record with attributes mentioned in AC03
            WorkOrder wo = new WorkOrder(); 
            wo.Status    = WO_STATUS_NEW;
            wo.Priority  = WO_PRIORITY_LOW;
            wo.AccountId = cep.Record__r.AccountId;
            wo.ContactId = cep.Record__r.Account.PersonContactId;
            wo.CaseId    = cep.Record__c;
            wo.RecordTypeId = secondaryCloseContactClearanceRecordTypeId;
            wo.Person_Interviewed__c = WO_PERSON_INTERVIEWED_SSC;
            wo.Subject = WO_SUBJECT_SCC_CLEARANCE;
            wo.OwnerId = cep.Record__r.OwnerId;
            workOrderToInsertList.add(wo);
        }

        try {
            //insert workorders
            if (!workOrderToInsertList.isEmpty()) {
                //to allow partial insert
                Database.SaveResult[] srList = Database.insert(workOrderToInsertList, FALSE);
                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        failedRecord++;
                    }
                    totalRecord++;
                }
            }    
        } catch(Exception exp){
            ApplicationLogUtility.createlog('CloseContactWorkOrderBatchJob','execute',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }   
     
    global void finish(Database.BatchableContext BC) {
        try{
            // execute any post-processing operations like sending email
            BatchNotificationEmailService.sendEmail(BATCH_JOB_NAME, totalRecord, failedRecord);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('CloseContactWorkOrderBatchJob','finish',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}