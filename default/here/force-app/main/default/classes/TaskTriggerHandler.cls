/**
 * @Author             : marcelo.cost 
 * @Description        : TaskTriggerHandler
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 10/12/2020     marcelo.cost          Initial version
 * 16/03/2021     Nikhil Verma          254881: Logic to handle escalation tasks (format Description and assign owner)
 * 07/04/2021     Pratyush Chalasani    Feature 270255: PCC & SCC Case Allocation: WorkOrder & Task Record Owner
 * 28/07/2021     Xiang Zheng           PBI 271848: add confirmedCaseClearanceCheck and clearanceFieldChangeCheck method.
**/

public with sharing class TaskTriggerHandler extends TriggerHandler {
    public static final String T_STATUS_CLOSE ='Close';
    
    private static string CLOSE_CONTACT = 'Close Contact';
    private static string COVID_19_CASE_ASSESSMENT = 'COVID-19 Case Assessment';
    private static string SECONDARY_CLOSE_CONTACT = 'Secondary Close Contact';
    
    public static final String T_STATUS_CANCELLED ='Cancelled';
    public static final String T_STATUS_COMPLETED ='Completed';
    public static final String T_SUBJECT_ABORGINAL ='Aboriginal Cultural Health Officer Review';

    public static final String RECORDTYPE_TASK_COMMUNICATION = 'Communication';
    public static final String RECORDTYPE_TASK_LOGACALL = 'Log_A_Call';

    public static Id communicationTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_TASK_COMMUNICATION).getRecordTypeId();
    public static Id logACallTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_TASK_LOGACALL).getRecordTypeId();    
    
    private Map<id, Task> newTasksByIds;

    //Constructor
    public TaskTriggerHandler() {
        this.newTasksByIds = (Map<Id, Task>) Trigger.newMap;
    }

    //Overrides
    public override void afterInsert() {
        List<Task> phoneCallsfromWorkOrders = getPhonecallsfromWorkOrder(newTasksByIds.values());
        cancelMilestones(phoneCallsfromWorkOrders);   
        handleInitialInterviewCompleted((List<Task>) Trigger.new); 
    }

    public override void beforeInsert() {
        handleEscalationsTasks(true, (List<Task>)Trigger.new, null);
        setOwnerFromCase((List<Task>)Trigger.new);
	confirmedCaseClearanceCheck(Trigger.new,null);
    }

    public override void beforeUpdate() {
        handleEscalationsTasks(false, (List<Task>)Trigger.new, (Map<Id, Task>)Trigger.oldMap);
        setOwnerFromCase((List<Task>)Trigger.new);
	confirmedCaseClearanceCheck(Trigger.new,(Map<Id, Task>)Trigger.oldMap);
    }

    private void setOwnerFromCase(List<Task> tasks) {
        if (!CaseTriggerHelper.CASE_TRIGGER_UPDATING_OWNERS) {
            List<String> caseRecordTypes         = new String[]{'Close_Contact', 'Secondary_Close_Contact', 'COVID_19_Case_Assessment'};
            List<String> taskIgnoreRecordTypes   = new String[]{communicationTaskRecordTypeId};
            List<String> taskOrderIgnoreStatuses = new String[]{T_STATUS_CLOSE, T_STATUS_COMPLETED, T_STATUS_CANCELLED};
            List<String> taskOrderIgnoreSubjects = new String[]{T_SUBJECT_ABORGINAL};

            Map<Id, Case> caseMap = new Map<Id, Case>();

            for (Task t: tasks) {
                if (t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')) {
                    caseMap.put(t.WhatId, null);
                }
            }
            
            if (caseMap.keySet().isEmpty()) return;

            caseMap = new Map<Id, Case>([SELECT Id, RecordType.DeveloperName, OwnerId FROM Case WHERE Id IN :caseMap.keySet()]);

            for (Task t: tasks) {
                Case tCase = caseMap.get(t.WhatId);

                if (t.Manually_Allocated__c == true || tCase == null || taskOrderIgnoreStatuses.contains(t.Status) || taskOrderIgnoreSubjects.contains(t.Subject)) continue;

                if (caseRecordTypes.contains(tCase.RecordType.DeveloperName) && !taskIgnoreRecordTypes.contains(t.RecordTypeId)) {
                    t.OwnerId = tCase.OwnerId;
                }
            }
        }
    }

    //helper methods
    private List<Task> getPhonecallsfromWorkOrder(List<Task> taskList) {
        List<Task>tasks = new List<Task>();
        for (Task aTask : taskList) {
            //Subtype==cal abd Id of whatId is from Case.
            if (aTask.TaskSubtype == 'Call' && String.valueOf(aTask.WhatId)?.startsWith('0WO')) {
                tasks.add(aTask);
            }
        }
        return tasks;
    }

    private void cancelMilestones(List<Task> taskList) {
        List<DHHS_CompleteMilestone.FlowInputs> inputList = new List<DHHS_CompleteMilestone.FlowInputs>();
        for (Task aTask : taskList) {
            DHHS_CompleteMilestone.FlowInputs wrapper = new DHHS_CompleteMilestone.FlowInputs();
            wrapper.strObject = 'WorkOrder';
            wrapper.recordId = aTask.WhatId;
            wrapper.completionDate = aTask.CompletedDateTime;
            wrapper.milestoneName ='First attempt to contact confirmed case';
            inputList.add(wrapper);
        }
        if(!inputList.isEmpty()){
        DHHS_CompleteMilestone.DHHS_CompleteMilestone(inputList);
        }
    }

     //Feature 260477: Close Contact Interview Completed = Checked
     private void handleInitialInterviewCompleted(List<Task> taskList) {
        List<Case> casesToUpdate = new List<Case>();
        List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
        Map<Id, List<WorkOrder>> caseWorkOrderMap = new Map<Id, List<WorkOrder>>();
        Map<Id, DateTime> caseActivityDateMap = new Map<Id, DateTime>();
		Set<Id> caseIds = new Set<Id>();
        Id closeContactInterviewRecordTypeId    = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Interview').getRecordTypeId();
        Id closeContactMonitoringRecordTypeId   = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Monitoring').getRecordTypeId();
        for (Task aTask : taskList) {
        	if (aTask.Communication_Type__c == 'Call made via Genesys - Initial close contact campaign'
                && aTask.Outcome__c == 'Successful') {
                    caseIds.add(aTask.WhatId);
                    if (aTask.ActivityDate != null) {
                        DateTime tempDateTime = DateTime.newInstance(aTask.ActivityDate.year(), aTask.ActivityDate.month(), aTask.ActivityDate.day());
                    	caseActivityDateMap.put(aTask.WhatId, tempDateTime);
                    }
                }
        }
        
        //check existing workorders
        for (WorkOrder wo : [SELECT Id, CaseId FROM WorkOrder WHERE recordtype.DeveloperName = 'Close_Contact_Monitoring' AND Status = 'In Progress' AND CaseId IN : caseIds]) {
            if (!caseWorkOrderMap.containsKey(wo.CaseId)) {
                caseWorkOrderMap.put(wo.CaseId, new List<WorkOrder>{wo});
            } else {
                caseWorkOrderMap.get(wo.CaseId).add(wo);
            }         
        }
        
        for(Case c : [SELECT Id, Initial_Interview_completed__c, Initial_Interview_Completed_Time__c, HealthCloudGA__DueDate__c, OwnerId, AccountId, Account.PersonContactId FROM CASE WHERE Initial_Interview_completed__c = FALSE AND Initial_Interview_Completed_Time__c = NULL AND Status != 'Closed' AND Id IN: caseIds]){
        	c.Initial_Interview_completed__c = TRUE;
            if (caseActivityDateMap.containsKey(c.Id)) {
            	c.Initial_Interview_Completed_Time__c = (DateTime)caseActivityDateMap.get(c.Id);  
            }
            casesToUpdate.add(c);
            
            //create a word order - "close contact interview"
            WorkOrder     tempWo1 = new WorkOrder();
            tempWo1.RecordTypeId  = closeContactInterviewRecordTypeId;
            tempWo1.Subject       = 'Initial close contact interview';
            tempWo1.Status        = 'Completed';
            tempWo1.OwnerId       = c.OwnerId;
            tempWo1.CaseId        = c.Id;
            tempWo1.AccountId     = c.AccountId;
            tempWo1.ContactId     = c.Account.PersonContactId;
            workOrdersToInsert.add(tempWo1);
            
            //create a work order only if the below workorder does not exist
            if (!caseWorkOrderMap.containsKey(c.Id)) {
                WorkOrder    tempWo2  = new WorkOrder();
                tempWo2.RecordTypeId  = closeContactMonitoringRecordTypeId;
                tempWo2.Subject       = 'Close contact monitoring';
                tempWo2.Status        = 'In Progress';
                tempWo2.OwnerId       = c.OwnerId;
                tempWo2.CaseId        = c.Id;
                tempWo2.AccountId     = c.AccountId;
                tempWo2.ContactId     = c.Account.PersonContactId;               
                workOrdersToInsert.add(tempWo2);
            }
        }
        
        //update cases
        if (!casesToUpdate.isEmpty()) {
        	update casesToUpdate;
        }
        
        //insert workorders
        if (!workOrdersToInsert.isEmpty()) {
        	insert workOrdersToInsert;
        }
	}
    

    //254881: Method to format Comments containing Questions & Answers for escalation tasks coming from Genesys
    private void handleEscalationsTasks(boolean isInsert, List<Task> listNewTasks, Map<Id, Task> mapOldTasks) {

        Id taskCommRTId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Communication').getRecordTypeId();
        Set<Id> setCaseIds = new Set<Id>();

        for(Task varT : listNewTasks) {
            if(varT.RecordTypeId == taskCommRTId && varT.Escalated__c == 'Yes') {
                if(isInsert && varT.WhatId != null && String.valueOf(varT.WhatId).startsWith('500')) {
                    setCaseIds.add(varT.WhatId);
                }
                if(varT.Description != null && varT.Description != '') {
                    String formattedDesc = varT.Description.replace('|', '\n');
                    varT.Description = formattedDesc;
                }
            }
        }

        Map<Id, Case> mapCaseId_Case = new Map<Id, Case>([SELECT Id, OwnerId FROM Case WHERE Id IN :setCaseIds]);

        for(Task varT : listNewTasks) {
            if(varT.RecordTypeId == taskCommRTId && varT.Escalated__c == 'Yes') {
                if(isInsert && varT.WhatId != null && mapCaseId_Case.containsKey(varT.WhatId)) {
                    varT.OwnerId = mapCaseId_Case.get(varT.WhatId).OwnerId;
                }
            }
        }
    }
	
	//Related PBI 271848
    //If Task (Recordtype = "Clearance") to Clear a Contact (Case.Record Type="Close Contact" or "Secondary Close Contact"), "Confirmed Case Clearance" section fields should not editable
    //If Task (Recordtype = "Clearance") to Clear a Contact (Case.Record Type="COVID-19 Case Assessment"), "Close Contact Clearance" section section fields should not editable
    private void confirmedCaseClearanceCheck(List<Task> taskList, Map<Id,Task> oldMap) {
        String taskRTId = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosByName().get('Clearance').getRecordTypeId();

        List<Task> clearanceTaskList = new List<Task>();
        List<Id> caseIdList = new List<Id>();
        for(Task theTask: taskList){
            if(theTask.recordTypeId == taskRTId && theTask.WhatId != null && String.valueOf(theTask.WhatId).startsWith('500')){
                caseIdList.add(theTask.WhatId);
                clearanceTaskList.add(theTask);
            }
        }

        if(caseIdList.size() > 0){
            List<String> recordTypeList = new List<String>();
            recordTypeList.add(CLOSE_CONTACT);
            recordTypeList.add(COVID_19_CASE_ASSESSMENT);
            recordTypeList.add(SECONDARY_CLOSE_CONTACT);

            Map<Id,Case> caseMap = new Map<Id,Case>([SELECT id,RecordType.Name FROM Case WHERE Id = :caseIdList AND RecordType.Name = :recordTypeList]);

            for(Task theTask: clearanceTaskList){
                if(caseMap.get(theTask.WhatId) != null){
                    Task oldTask;
                    if(oldMap != null){
                        oldTask = oldMap.get(theTask.Id);
                    }
                    
                    String checkResult = clearanceFieldChangeCheck(theTask,oldTask,caseMap.get(theTask.WhatId).RecordType.Name);
                    if(checkResult != null){
                        theTask.addError(checkResult);
                    }
                }
            }
        }
    }

    //check related fields has been changed
    private String clearanceFieldChangeCheck(Task newTask, Task oldTask, string caseRecordType) {
        String result = null;

        if(oldTask != null){
            if(caseRecordType.equals(CLOSE_CONTACT)){
                if(newTask.Was_the_case_ever_symptomatic__c != oldTask.Was_the_case_ever_symptomatic__c || 
                    newTask.Was_the_case_hospitalised_due_to_COVID_1__c != oldTask.Was_the_case_hospitalised_due_to_COVID_1__c ||
                    newTask.Has_it_been_14_or_more_days__c != oldTask.Has_it_been_14_or_more_days__c ||
                    newTask.In_the_last_72_hours_any_symptoms__c != oldTask.In_the_last_72_hours_any_symptoms__c ||
                    newTask.X5_10_or_more_days_since__c != oldTask.X5_10_or_more_days_since__c ||
                    newTask.X6_Is_the_case_still_asymptomatic__c != oldTask.X6_Is_the_case_still_asymptomatic__c ||
                    newTask.X7_When_did_the_case_develop_symptoms__c != oldTask.X7_When_did_the_case_develop_symptoms__c ||
                    newTask.X8_10_or_more_days_since_symptom__c != oldTask.X8_10_or_more_days_since_symptom__c ||
                    newTask.Is_the_case_immunosupressed__c != oldTask.Is_the_case_immunosupressed__c ||
                    newTask.X2_x_swabs_been_performed_24_hours_apar__c != oldTask.X2_x_swabs_been_performed_24_hours_apar__c ||
                    newTask.X11_Are_both_clearance_swabs_negative__c != oldTask.X11_Are_both_clearance_swabs_negative__c ||
                    newTask.X12_Are_symptoms_significantly_improved__c != oldTask.X12_Are_symptoms_significantly_improved__c){
                    result = 'For a close contact you cannot update confirmed case clearance details.';
                }
            }else if(caseRecordType.equals(COVID_19_CASE_ASSESSMENT)){
                if(newTask.Negative_End_of_Quarantine_Test_received__c != oldTask.Negative_End_of_Quarantine_Test_received__c ||
                    newTask.Contact_currently_have_any_symptoms__c != oldTask.Contact_currently_have_any_symptoms__c || 
                    newTask.Has_there_been_any_re_exposure_risk__c != oldTask.Has_there_been_any_re_exposure_risk__c || 
                    newTask.Any_household_contacts_symptomatic__c != oldTask.Any_household_contacts_symptomatic__c){
                    result = 'For a confirmed case you cannot update close contact clearance details.';
                }
            }
        }else{
            if(caseRecordType.equals(CLOSE_CONTACT)){
                if(newTask.Was_the_case_ever_symptomatic__c != null || 
                    newTask.Was_the_case_hospitalised_due_to_COVID_1__c != null ||
                    newTask.Has_it_been_14_or_more_days__c != null ||
                    newTask.In_the_last_72_hours_any_symptoms__c != null ||
                    newTask.X5_10_or_more_days_since__c != null ||
                    newTask.X6_Is_the_case_still_asymptomatic__c != null ||
                    newTask.X7_When_did_the_case_develop_symptoms__c != null ||
                    newTask.X8_10_or_more_days_since_symptom__c != null ||
                    newTask.Is_the_case_immunosupressed__c != null ||
                    newTask.X2_x_swabs_been_performed_24_hours_apar__c != null ||
                    newTask.X11_Are_both_clearance_swabs_negative__c != null ||
                    newTask.X12_Are_symptoms_significantly_improved__c != null){
                    result = 'For a close contact you cannot update confirmed case clearance details.';
                }
            }else if(caseRecordType.equals(COVID_19_CASE_ASSESSMENT)){
                if(newTask.Negative_End_of_Quarantine_Test_received__c != null ||
                    newTask.Contact_currently_have_any_symptoms__c != null || 
                    newTask.Has_there_been_any_re_exposure_risk__c != null || 
                    newTask.Any_household_contacts_symptomatic__c != null){
                    result = 'For a confirmed case you cannot update close contact clearance details.';
                }
            }            
        }
        return result;
    }
}