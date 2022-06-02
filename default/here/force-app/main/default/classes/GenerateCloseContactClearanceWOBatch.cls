/*
    Created by: YPerera
    
	@WARNING: This is a resource intensive batch job and has a potential chance to fail due data issues.
			  It is a good idea to process records within past 3 months only
    @Modification Log   :
    ---------------------------------------------------
    Date           Author      		    Details
    23/03/2021     YPerera           	Feature 265632: Close Contact Clearance Work Order - Close Contact Day 14 Notification
    12/10/2021     ASamad           	Feature 313520: Populate Name while auto-creating Close Contact Tasks 
    ---------------------------------------------------
*/
global class GenerateCloseContactClearanceWOBatch implements Database.Batchable<SObject> , Database.Stateful {
    
    global static final String RECORDTYPE_CASE_CLOSE_CONTACT = 'Close_Contact';
    global static final String RECORDTYPE_WORK_ORDER_CLEARANCE = 'Close_Contact_Clearance';
    global static final String RECORDTYPE_TASK_CLEARANCE = 'Clearance';

    global static final String WO_STATUS_NEW   = 'New';
    global static final String WO_PRIORITY_LOW = 'Low';
    global static final String WO_PERSON_INTERVIEWED_CC = 'Close Contact';
    global static final String WO_SUBJECT_CC_CLEARANCE  = 'Close Contact Clearance';
    
    global static final String EHR_OBSERVATION_OBJECT_APINAME     = 'HealthCloudGA__EhrObservation__c';
    global static final String EHR_OBSERVATION_FIELD_APINAME      = 'Test_Result__c';
    global static final String EHR_OBSERVATION_TEST_RESULT_VALUE  = 'Not detected';
    
    global static final String TASK_SUBJECT_CC_CLEARANCE_1  = 'Clearance assessment';
    global static final String TASK_SUBJECT_CC_CLEARANCE_2  = 'Day 15-28 Negative Result';
    global static final String TASK_SUBJECT_CC_CLEARANCE_3  = 'Day 14 No Negative Result';
    
    global static Id interviewWorkOrderClearanceRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_CLEARANCE).getRecordTypeId();
    global static Id clearanceTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_TASK_CLEARANCE).getRecordTypeId();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id
                                         , Day14_Anticipated_last_day_of_quarantine__c
                                         , Day_11_Test__c
                                         , OwnerId 
                                         , AccountId
                                         , ContactId
                                         , Latest_EHR_Observation__c
                                         , Latest_EHR_Observation__r.Test_Result__c
                                         , Status
                                         , (SELECT Id, Subject FROM WorkOrders WHERE Subject = :WO_SUBJECT_CC_CLEARANCE) workorders //No workorders will be created if the similar is existing
                                         FROM Case
                                         WHERE RecordType.DeveloperName = :RECORDTYPE_CASE_CLOSE_CONTACT
                                         AND Day14_Anticipated_last_day_of_quarantine__c != NULL
                                         AND Day14_Anticipated_last_day_of_quarantine__c <= TODAY
                                         AND Status != 'Closed'
                                        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> records) {
        try {
            if (records != null && !records.isEmpty()) {
                
                List<WorkOrder> newWorkorders = new List<WorkOrder>();
                
                Map<Id, Case> workOrderToCaseMap = new Map<Id, Case>();
                Map<Id, List<Task>> workOrderToClearanceTaskExistanceMap = new Map<Id, List<Task>>();
                Map<Id, List<HealthCloudGA__EhrObservation__c>> caseToObservationMap = new Map<Id, List<HealthCloudGA__EhrObservation__c>>();

                List<Id> allWorkOrdersList = new List<Id>();
                
                for(SObject so : records) { 
                    Case c = (Case)so;

                    //AC01 (265632)
                    if (c.Day14_Anticipated_last_day_of_quarantine__c <= Date.today() && c.workorders.isEmpty()) {
                        WorkOrder wo = new WorkOrder(Status = WO_STATUS_NEW,
                                                     Priority = WO_PRIORITY_LOW,
                                                     RecordTypeId = interviewWorkOrderClearanceRecordTypeId,
                                                     Person_Interviewed__c = WO_PERSON_INTERVIEWED_CC,
                                                     Subject = WO_SUBJECT_CC_CLEARANCE,
                                                     AccountId = c.AccountId,
                                                     ContactId = c.ContactId,
                                                     CaseId = c.Id,
                                                     OwnerId = c.OwnerId
                                                    );
                        newWorkorders.add(wo);
                   } else if (c.workorders != null && !c.workorders.isEmpty()) {
                       for (Workorder wo : c.workorders) {
                           allWorkOrdersList.add(wo.Id);
                           workOrderToCaseMap.put(wo.Id, c);
                           workOrderToClearanceTaskExistanceMap.put(wo.Id, null);
                       }
                   }
                    
                }

                Database.SaveResult[] srListWO = Database.insert(newWorkorders);
                
                List<Task> clearanceTasks = new List<Task>();
                
                for (Database.SaveResult result : srListWO) {
                    if (result.isSuccess()) {
                        allWorkOrdersList.add(result.getId());
                        workOrderToCaseMap.put(result.getId(), null);
                        workOrderToClearanceTaskExistanceMap.put(result.getId(), null);
                    }
                }
                
                for (WorkOrder wo : [SELECT Id, CaseId, Case.OwnerId, Case.ContactId, Case.Day14_Anticipated_last_day_of_quarantine__c, Case.Day_11_Test__c/*, Case.Latest_EHR_Observation__c, Case.Latest_EHR_Observation__r.Test_Result__c, Case.Latest_EHR_Observation__r.HealthCloudGA__IssuedDate__c*/ FROM WorkOrder WHERE Id IN :workOrderToCaseMap.keySet()]) {
                    workOrderToCaseMap.put(wo.Id, wo.Case);
                }
                
                for (HealthCloudGA__EhrObservation__c ehrObservation : [SELECT Id, Record__c, Record__r.CaseNumber, Record__r.Day14_Anticipated_last_day_of_quarantine__c, Record__r.Day_11_Test__c, HealthCloudGA__IssuedDate__c, Test_Result__c FROM HealthCloudGA__EhrObservation__c WHERE Record__c IN :workOrderToCaseMap.values()]) {
                    if (!caseToObservationMap.containsKey(ehrObservation.Record__c)) {
                        List<HealthCloudGA__EhrObservation__c> observationList = new List<HealthCloudGA__EhrObservation__c>();
                        observationList.add(ehrObservation);
                        caseToObservationMap.put(ehrObservation.Record__c, observationList);
                    } else {
                        caseToObservationMap.get(ehrObservation.Record__c).add(ehrObservation);
                    }
                }
                
                for (Task t : [SELECT Id, WhatId, Subject FROM Task WHERE WhatId IN :workOrderToClearanceTaskExistanceMap.keyset() AND Subject IN (:TASK_SUBJECT_CC_CLEARANCE_1, :TASK_SUBJECT_CC_CLEARANCE_2, :TASK_SUBJECT_CC_CLEARANCE_3)]) {
                    if (workOrderToClearanceTaskExistanceMap.get(t.WhatId) != null) {//Only Workorders which have the Tasks comes here. This check is optional
                   		workOrderToClearanceTaskExistanceMap.get(t.WhatId).add(t);
                    } else {
                        List<Task> newTasks = new List<Task>();
                        newTasks.add(t);
                        workOrderToClearanceTaskExistanceMap.put(t.WhatId, newTasks);
                    }

                }
                
                for (Id woId : allWorkOrdersList) {
                    Case c = workOrderToCaseMap.get(woId);
                    Date day14 = c.Day14_Anticipated_last_day_of_quarantine__c;

                    //AC01 (265387)
                    if (day14 <= Date.today() && ((foundNotDetectedELROnDay11Test(caseToObservationMap, c)) || (foundNotDetectedELRAfterDay11Test(caseToObservationMap, c)) /*|| (foundNotDetectedELRBeforeDay11Test(caseToObservationMap, c))*/  ) ) {
                        if (!isTaskExist(workOrderToClearanceTaskExistanceMap, woId, TASK_SUBJECT_CC_CLEARANCE_1) ) {
                            clearanceTasks.add(new Task(Status = WO_STATUS_NEW, Priority = WO_PRIORITY_LOW, OwnerId = c.OwnerId, Subject = TASK_SUBJECT_CC_CLEARANCE_1, WhatId = woId,WhoId=c.ContactId, RecordTypeId = clearanceTaskRecordTypeId));
                        }
                    } 
                        
                    //AC02 (265387)
                    if (day14 <= Date.today()) {
                        if (!foundNotDetectedELRAfterDay11Test(caseToObservationMap, c) && !foundNotDetectedELROnDay11Test(caseToObservationMap, c) /*&& foundNotDetectedELRBeforeDay11Test(caseToObservationMap, c)*/){
                            if (!isTaskExist(workOrderToClearanceTaskExistanceMap, woId, TASK_SUBJECT_CC_CLEARANCE_3) ) {
                                clearanceTasks.add(new Task(Status = WO_STATUS_NEW, Priority = WO_PRIORITY_LOW, OwnerId = c.OwnerId, Subject = TASK_SUBJECT_CC_CLEARANCE_3, WhatId = woId,WhoId=c.ContactId));
                            }
                        }
                    }

                    //AC03 (265387)
                    if (day14 < Date.today() && foundNotDetectedELRAfterDay14LastDayofQuarantine(caseToObservationMap, c) ) {
                        if (!isTaskExist(workOrderToClearanceTaskExistanceMap, woId, TASK_SUBJECT_CC_CLEARANCE_2) ) {
                            clearanceTasks.add(new Task(Status = WO_STATUS_NEW, Priority = WO_PRIORITY_LOW, OwnerId = c.OwnerId, Subject = TASK_SUBJECT_CC_CLEARANCE_2, WhatId = woId,WhoId=c.ContactId, RecordTypeId = clearanceTaskRecordTypeId));
                        }
                    }
                }

                if (!clearanceTasks.isEmpty()) Database.SaveResult[] srListTasks = Database.insert(clearanceTasks);
            }
        } catch(Exception exp) { 
            System.debug('EXCEPTION: ' + JSON.serialize(exp)); 
            ApplicationLogUtility.createlog('GenerateCloseContactClearanceWOBatch','GenerateCloseContactClearanceWOBatch execute',
                                        exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
    
    private static boolean foundNotDetectedELRBeforeDay11Test(Map<Id, List<HealthCloudGA__EhrObservation__c>> caseToObservationMap, Case record) {
        if (caseToObservationMap.containsKey(record.Id)) {
            List<HealthCloudGA__EhrObservation__c> observationList = caseToObservationMap.get(record.Id);
            for (HealthCloudGA__EhrObservation__c o : observationList) {
                if (o.HealthCloudGA__IssuedDate__c != null) {
                    Date tempDate = o.HealthCloudGA__IssuedDate__c.date();
                    if (o.Test_Result__c == getTestResultAPIname() && (tempDate < record.Day_11_Test__c) ) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    private static boolean foundNotDetectedELRAfterDay14LastDayofQuarantine(Map<Id, List<HealthCloudGA__EhrObservation__c>> caseToObservationMap, Case record) {
        if (caseToObservationMap.containsKey(record.Id)) {
            List<HealthCloudGA__EhrObservation__c> observationList = caseToObservationMap.get(record.Id);
            for (HealthCloudGA__EhrObservation__c o : observationList) {
                if (o.HealthCloudGA__IssuedDate__c != null) {
                    Date tempDate = o.HealthCloudGA__IssuedDate__c.date();
                    if (o.Test_Result__c == getTestResultAPIname() && (tempDate > record.Day14_Anticipated_last_day_of_quarantine__c) ) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    private static boolean foundNotDetectedELRAfterDay11Test(Map<Id, List<HealthCloudGA__EhrObservation__c>> caseToObservationMap, Case record) {
        if (caseToObservationMap.containsKey(record.Id)) {
            List<HealthCloudGA__EhrObservation__c> observationList = caseToObservationMap.get(record.Id);
            for (HealthCloudGA__EhrObservation__c o : observationList) {
                if (o.HealthCloudGA__IssuedDate__c != null) {
                    Date tempDate = o.HealthCloudGA__IssuedDate__c.date();
                    if (o.Test_Result__c == getTestResultAPIname() && (tempDate > record.Day_11_Test__c) ) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private static boolean foundNotDetectedELROnDay11Test(Map<Id, List<HealthCloudGA__EhrObservation__c>> caseToObservationMap, Case record) {
        if (caseToObservationMap.containsKey(record.Id)) {
            List<HealthCloudGA__EhrObservation__c> observationList = caseToObservationMap.get(record.Id);
            for (HealthCloudGA__EhrObservation__c o : observationList) {
                if (o.HealthCloudGA__IssuedDate__c != null) {
                    Date tempDate = o.HealthCloudGA__IssuedDate__c.date();
                    if (o.Test_Result__c == getTestResultAPIname() && (tempDate == record.Day_11_Test__c) ) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private static boolean isTaskExist(Map<Id, List<Task>> workOrderToClearanceTaskExistanceMap, Id woId, String taskSubject) {
        if (workOrderToClearanceTaskExistanceMap.containsKey(woId)) {
            if (workOrderToClearanceTaskExistanceMap.get(woId) != null) {
                List<Task> tasks = workOrderToClearanceTaskExistanceMap.get(woId);
                for (Task t : tasks) {
                    if (t.Subject == taskSubject) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private static String getTestResultAPIname() {
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
        
        return testResultAPIName;
    }
}