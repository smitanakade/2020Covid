/*
Created by: Hasantha E

@Modification Log   :
---------------------------------------------------
Date           Author      		    Details
11/03/2021     Hasantha E           Feature 253228: added createInterviewWorkOrders method
07/04/2021     Pratyush Chalasani   Feature 270241,270255: Confirmed, CC & SCC Case Allocation: WorkOrder & Task Record Owner
03/05/2021     Pratyush Chalasani   Hotfix 281213: Fixed record types for WorkOrder Interview and Monitoring (WorkOrder allocations)
30/06/2021     Pratyush Chalasani   Hotfix 294010: Proper error message should be shown at Work order creation
18/08/2021     Xiang Zheng          bug fix 310751: fix Unable to change status of secondary close contact interview work order to 'completed', 'cancelled' or 'closed'
20/06/2021     Hemant Singh         PBI-321900: Short form changes - copying interview details in case
08/10/2021     Xiang Zheng          PBI 326131 :  Fix Confirmed Case Interview Work Order Trigger, add method checkInterviewWorkOrder
---------------------------------------------------
*/
public with sharing class WorkOrderTriggerHelper {
    public static final String RECORDTYPE_CASE_CONFIRMED = 'COVID_19_Case_Assessment';
    public static final String RECORDTYPE_CASE_PCC = 'Close_Contact';
    public static final String RECORDTYPE_CASE_SCC = 'Secondary_Close_Contact';

    public static final String RECORDTYPE_WORK_ORDER_SCC_INTERVIEW = 'Secondary_Close_Contact_Interview';
    public static final String RECORDTYPE_WORK_ORDER_INTERVIEW = 'Interview';
    public static final String RECORDTYPE_WORK_ORDER_CLEARANCE = 'Confirmed_Case_Clearance';
    public static final String RECORDTYPE_WORK_SCC_MONITORING = 'Secondary_Close_Contact_Monitoring';

    public static final String RECORDTYPE_WORK_ORDER_PCC_INTERVIEW = 'Close_Contact_Interview';
    public static final String RECORDTYPE_WORK_ORDER_PCC_MONITORING = 'Close_Contact_Monitoring';
    public static final String RECORDTYPE_WORK_ORDER_PCC_CLEARANCE = 'Close_Contact_Clearance';
    public static final String RECORDTYPE_WORK_ORDER_SCC_CLEARANCE = 'Secondary_Close_Contact_Clearance';
    public static final String RECORDTYPE_WORK_ORDER_HEP_REFERRAL = 'HEP_Referral';

    public static final String RECORDTYPE_WORK_ORDER_CONFIRMED_INTERVIEW = 'Interview';
    public static final String RECORDTYPE_WORK_ORDER_CONFIRMED_MONITORING = 'Confirmed_Case_Monitoring_Work_Order';

    public static final String WO_STATUS_NEW ='New';
    public static final String WO_PRIORITY_LOW ='Low';

    public static final String WO_STATUS_COMPLETED = 'Completed';
    public static final String WO_PERSON_INTERVIEWED_SSC = 'Secondary Close Contact';
    public static final String WO_PERSON_INTERVIEWED_CASE = 'Case';
    public static final String WO_SUBJECT_SCC_MONITORING = 'Secondary Close Contact Monitoring';
    public static final String WO_SUBJECT_CLEARANCE = 'Confirmed Case Clearance';

    public static final String WO_STATUS_CLOSE ='Close';
    public static final String WO_STATUS_CANCELLED ='Cancelled';

    public static Id interviewWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_INTERVIEW).getRecordTypeId();
    public static Id SCCInterviewWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_SCC_INTERVIEW).getRecordTypeId();
    public static Id interviewWorkOrderClearanceRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_CLEARANCE).getRecordTypeId();
    public static Id SCCMonitoringWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_SCC_MONITORING).getRecordTypeId();

    public static Id pccInterviewWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_PCC_INTERVIEW).getRecordTypeId();
    public static Id pccMonitoringWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_PCC_MONITORING).getRecordTypeId();
    public static Id pccClearanceWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_PCC_CLEARANCE).getRecordTypeId();
    public static Id sccClearanceWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_SCC_CLEARANCE).getRecordTypeId();
    public static Id hepReferralWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_HEP_REFERRAL).getRecordTypeId();    

    public static Id confirmedMonitoringWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_CONFIRMED_MONITORING).getRecordTypeId();
    public static Id confirmedInterviewWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_CONFIRMED_INTERVIEW).getRecordTypeId();
    
    public static Id CASE_COVID_19_ASSESSMENT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();

    /**
     * PBI 326131 :  Fix Confirmed Case Interview Work Order Trigger
     * Each  'COVID-19 Case Assessment' Record should only have ONE 'Confirmed Case Interview' Work Order.  
     * System shouldn't automatically or allow users to create manually another 'Confirmed Case Interview' Work Order if there is already one existing against the Record.
     * @param workOrders
     * @param oldWorkOrders
     */
    public static void checkInterviewWorkOrder(List<WorkOrder> workOrders, Map<Id,WorkOrder> oldWorkOrders) {
        List<Id> caseIds = new List<Id>();//related cases
        List<WorkOrder> interviewWorkOrderList = new List<WorkOrder>();//the work orders need to be checked
        Map<Id,WorkOrder> workOrderMap = new Map<Id,WorkOrder>();//map of cases already have 'Interview' work order
        try{
            for(WorkOrder wo: workOrders){
                //find the work orders which with 'Interview' record type
                if(wo.RecordTypeId == interviewWorkOrderRecordTypeId){
                    if(oldWorkOrders == null || oldWorkOrders.get(wo.Id).RecordTypeId != interviewWorkOrderRecordTypeId){
                        caseIds.add(wo.CaseId);
                        interviewWorkOrderList.add(wo);
                    }
                }
            }
    
            //find the cases already have 'Interview' work order
            if(!caseIds.isEmpty()){
                List<WorkOrder> tempList = [SELECT Id,CaseId FROM WorkOrder WHERE CaseId = :caseIds AND RecordTypeId = :interviewWorkOrderRecordTypeId AND Case.RecordTypeId = :CASE_COVID_19_ASSESSMENT_RECORD_TYPE];
    
                if(!tempList.isEmpty()){
                    for(WorkOrder temp: tempList){
                        workOrderMap.put(temp.CaseId,temp);
                    }
                }
            }
    
            //check the cases of the new 'Interview' work orders if they already have a 'Interview' work order.
            if(!interviewWorkOrderList.isEmpty()){
                for(WorkOrder iwo: interviewWorkOrderList){
                    if(workOrderMap.get(iwo.CaseId) != null){
                        iwo.addError('Please review work orders, an existing confirmed case interview work order already exists for this record.');
                    }
                }
            }
        } catch (Exception e) {
            //TODO: log any errors here with future error handling framework
            throw new WorkOrderTriggerHelperException(e);
        }
    }
    /**
     * Set owner of work order to parent case, if they meet certain conditions (#270241 & #270255)
     * @param workOrders
     */
    public static void setOwnerFromCase(List<WorkOrder> workOrders) {
        if (!CaseTriggerHelper.CASE_TRIGGER_UPDATING_OWNERS) {
            List<String> contactRecordTypes            = new String[]{RECORDTYPE_CASE_PCC, RECORDTYPE_CASE_SCC};
            List<Id>     contactWorkOrderRecordTypes   = new Id[]{pccInterviewWorkOrderRecordTypeId, pccMonitoringWorkOrderRecordTypeId, pccClearanceWorkOrderRecordTypeId, SCCInterviewWorkOrderRecordTypeId, SCCMonitoringWorkOrderRecordTypeId, sccClearanceWorkOrderRecordTypeId, hepReferralWorkOrderRecordTypeId};
            List<Id>     confirmedWorkOrderRecordTypes = new Id[]{confirmedInterviewWorkOrderRecordTypeId, confirmedMonitoringWorkOrderRecordTypeId, interviewWorkOrderClearanceRecordTypeId, hepReferralWorkOrderRecordTypeId};
            List<String> workOrderIgnoreStatuses       = new String[]{WO_STATUS_CLOSE, WO_STATUS_COMPLETED, WO_STATUS_CANCELLED};

            Map<Id, Case> caseMap = new Map<Id, Case>();

            for (WorkOrder wo: workOrders) caseMap.put(wo.CaseId, null);
            
            caseMap = new Map<Id, Case>([SELECT Id, RecordType.DeveloperName, OwnerId FROM Case WHERE Id IN :caseMap.keySet()]);

            for (WorkOrder wo: workOrders) {
                if (wo.Manually_Allocated__c == true || workOrderIgnoreStatuses.contains(wo.Status)) continue;

                Case woCase = caseMap.get(wo.CaseId);

                if (woCase == null) {
                    // #294010
                    // Require a value in the Record lookup if not manually allocating (and not using one of the ignored status values)
                    wo.addError('Record is required to create a work order when Manually Allocated checkbox is not ticked');
                } else if ((contactRecordTypes.contains(woCase.RecordType.DeveloperName) && contactWorkOrderRecordTypes.contains(wo.RecordTypeId))
                    ||
                    (woCase.RecordType.DeveloperName == RECORDTYPE_CASE_CONFIRMED && confirmedWorkOrderRecordTypes.contains(wo.RecordTypeId))) {

                    wo.OwnerId = woCase.OwnerId;
                }
            }

        }
    }

        /**
     * Create Secondary Close Contact Monitoring work order records when the,
     * Secondary Close Contact interview work order is completed OR the Initial Interview is completed
     * @param workOrders
     * @param oldWorkOrders
     */
    public static void createSCCMonitoringWorkOrders(List<WorkOrder> workOrders, Map<Id,WorkOrder> oldWorkOrders) {
        // get the case record to access accountId, ContactId on the case record as the direct access doesn't work (workOrder.Case.AccountId doesn't work)
        Set<Id> caseIds = new Set<Id>();
        Map<Id, List<WorkOrder>> caseWorkOrderMap = new Map<Id, List<WorkOrder>>();
        for (WorkOrder workOrder : workOrders) {
            caseIds.add(workOrder.CaseId);
        }

        Map<Id,Case> casesByIds = new Map<Id,Case>([
            SELECT Id, AccountId, ContactId, OwnerId, Initial_Interview_completed__c
            FROM Case
            WHERE Id =: caseIds AND Status!='Closed'
        ]);

        if(casesByIds.size() < 1){
            return;
        }

        List<WorkOrder> workOrdersToCreate = new List<WorkOrder>();
        try {
            for (WorkOrder workOrder : workOrders) {
                WorkOrder oldWorkOrder = oldWorkOrders.get(workOrder.Id);
                // when the Secondary Close Contact interview work order is completed OR the Initial Interview is completed
                if (workOrder.RecordTypeId == SCCInterviewWorkOrderRecordTypeId && (workOrder.Status != oldWorkOrder.Status && WO_STATUS_COMPLETED.equals(workOrder.Status))){
                      //  || casesByIds.get(workOrder.CaseId).Initial_Interview_completed__c) { // initial Review Completed = true is already handled through Case Trigger Helper method createWorkOrderOnInitialInterview
                    if(casesByIds.get(workOrder.CaseId) != null){
                        workOrdersToCreate.add(
                            new WorkOrder(
                                    Status = WO_STATUS_NEW,
                                    Priority = WO_PRIORITY_LOW,
                                    AccountId = casesByIds.get(workOrder.CaseId).AccountId,
                                    ContactId = casesByIds.get(workOrder.CaseId).ContactId,
                                    CaseId = workOrder.CaseId,
                                    RecordTypeId = SCCMonitoringWorkOrderRecordTypeId,
                                    Person_Interviewed__c = WO_PERSON_INTERVIEWED_SSC,
                                    Subject = WO_SUBJECT_SCC_MONITORING
                            )
                        );
                    }
                }
            }
            if (workOrdersToCreate.isEmpty()) {
                return;
            }

            insert workOrdersToCreate;
        } catch (Exception e) {
            //TODO: log any errors here with future error handling framework
            System.debug('EXCEPTION : on WorkOrderTriggerHelper.createSCCMonitoringWorkOrders() '+e.getStackTraceString());
            throw new WorkOrderTriggerHelperException(e);
        }
    }
    /**
     * PBI 265251 : generate clearance work order records via the batch job.
     * this method wil be called via the batch job GenerateInterviewWorkOrdersBatch
     * @param records
     */
    public static  Database.SaveResult[] generateClearanceWorkOrders(List<Case> records) {
        List<WorkOrder> workOrdersToCreate = new List<WorkOrder>();
        for (Case record : records) {
            workOrdersToCreate.add(
                    new WorkOrder(
                            Status = WO_STATUS_NEW,
                            Priority = WO_PRIORITY_LOW,
                            RecordTypeId = interviewWorkOrderClearanceRecordTypeId,
                            Person_Interviewed__c = WO_PERSON_INTERVIEWED_CASE,
                            Subject = WO_SUBJECT_CLEARANCE,
                            AccountId = record.AccountId,
                            ContactId = record.ContactId,
                            CaseId = record.Id,
                            OwnerId = record.OwnerId
                    )
            );
        }

        if(workOrdersToCreate.isEmpty()) return null;
        return Database.Insert(workOrdersToCreate,false);
    }

   
    /**
     * Set Subject of work order from Custom Label, if Ex Hotel Quarantine rectype (#275681)
     * @param workOrders
     */
    public static void setDefaultSubject(List<WorkOrder> workOrders) {
        Id HQWoRecTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Ex_Hotel_Quarantine_Resident_Monitoring').getRecordTypeId();
		
        for (WorkOrder wo: workOrders) {
            if (wo.RecordTypeId == HQWoRecTypeId && wo.Subject == null){
                wo.Subject = System.label.Work_Order_HQ_Subject_Line; 
            }
		}
    }
    
    /*
    PBI : 321912
    Set start date of work order to the date time when status is moved to in progress
    @author:Ashwin Kondapally
    @date created: 16 September 2021*/
    public static void setStartDate(List<WorkOrder> workOrders) {
        
		
        for (WorkOrder wo: workOrders) {
            if (wo.Status == 'In Progress' && wo.startDate == null){
                wo.StartDate = System.now();
            }
		}
    }
// PBI-321900: Short form changes - copying interview details in case
    public static void copyInterviewDetailsToCase(List<WorkOrder> workOrders, Map<Id,WorkOrder> oldWorkOrders) {

        Set<Id> recordSet = new Set<Id>();
        List<Case> caseList = new List<Case>();


        for(WorkOrder WORec : workOrders){
            if(WORec.RecordTypeId == interviewWorkOrderRecordTypeId
            && ((oldWorkOrders.get(WORec.Id).Interviewed_By__c != WORec.Interviewed_By__c)
               || (oldWorkOrders.get(WORec.Id).Person_Interviewed__c != WORec.Person_Interviewed__c)
               || (oldWorkOrders.get(WORec.Id).Date_of_interview__c != WORec.Date_of_interview__c))){

                recordSet.add(WORec.CaseId);

            }
        }
        Map<Id, Case> casesByIds = new Map<Id, Case>([SELECT Id, Interviewed_By__c, Person_Interviewed__c, Date_of_interview__c From Case Where Id IN :recordSet]);
        for (WorkOrder WORec : workOrders){
            Case record = casesByIds.get(WORec.caseId);
            if (record != null) {
            record.Interviewed_By__c = WORec.Interviewed_By__c;
            record.Person_Interviewed__c = WORec.Person_Interviewed__c;
              if (WORec.Date_of_Interview__c != null){
                record.Date_of_interview__c = WORec.Date_of_Interview__c.Date();
            }
            caseList.add(record);
            }
        }
        try{
            if (!caseList.isEmpty()){
        	update caseList;
            }
        }catch (Exception e) {
            System.debug('EXCEPTION : on WorkOrderTriggerHelper.copyInterviewDetailsToCase() '+e.getStackTraceString());
            throw new WorkOrderTriggerHelperException(e);
        }
        
    }


    public class WorkOrderTriggerHelperException extends Exception {}
}