/*
    Author: Henna Mullaji
    @Modification Log   :  
    ---------------------------------------------------
    Date           Author      		    Details
    ---------------------------------------------------
    03/02/2021     Darko Jovanovic       Feature 255889: Modified to use common trigger framework
    08/04/2021     Suraj Sood            Feature 270255: Default Subject
    07/04/2021     Pratyush Chalasani    Feature 270255: PCC & SCC Case Allocation: WorkOrder & Task Record Owner
    05/03/2021     Chris Zhuang          Feature 260477: Close Contact Interview Completed = Checked 
    08/10/2021     Xiang Zheng           PBI 326131 :  Fix Confirmed Case Interview Work Order Trigger, add method checkInterviewWorkOrder
    */
    public class WorkOrderTriggerHandler extends TriggerHandler {
    
        public override void beforeInsert() {
            WorkOrderTriggerHelper.setDefaultSubject((List<WorkOrder>) Trigger.new);//275681
            WorkOrderTriggerHelper.setOwnerFromCase((List<WorkOrder>) Trigger.new);
            WorkOrderTriggerHelper.checkInterviewWorkOrder((List<WorkOrder>) Trigger.new, null);//PBI 326131
        }

        public override void beforeUpdate() {
            WorkOrderTriggerHelper.setOwnerFromCase((List<WorkOrder>) Trigger.new);
            WorkOrderTriggerHelper.setStartDate((List<WorkOrder>) Trigger.new);
	    WorkOrderTriggerHelper.checkInterviewWorkOrder((List<WorkOrder>) Trigger.new, (Map<Id, WorkOrder>) trigger.oldMap);//PBI 326131

        }
        
        public override void afterUpdate() {
            WorkOrderTriggerHelper.createSCCMonitoringWorkOrders((List<WorkOrder>) Trigger.new, (Map<Id, WorkOrder>) trigger.oldMap);
            WorkOrderTriggerHandler.modifyContacts((List<WorkOrder>) Trigger.new, (Map<Id, WorkOrder>) trigger.oldMap);
            WorkOrderTriggerHandler.handleCloseContactInterview((List<WorkOrder>) Trigger.new, (Map<Id, WorkOrder>) trigger.oldMap);   
            WorkOrderTriggerHelper.copyInterviewDetailsToCase((List<WorkOrder>) Trigger.new, (Map<Id, WorkOrder>) trigger.oldMap); 
        }

        @testVisible
        private static void modifyContacts(List<WorkOrder> woRecords, Map<Id, WorkOrder> mapOldWorkOrder) 

        {
            List<Id> caseIds = new List<Id>(); //To store Confirmed and Close Contacts Case ids 
            
            Id secInterviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact_Interview').getRecordTypeId();
            Id ccInterviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Interview').getRecordTypeId();
            Id interviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
            Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
            Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
            Id secondaryCloseContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
            System.debug('Inside method modifyContacts');
            //Identify Confirmed and Close Contacts Case ids for completed interview workorders
            for( WorkOrder woRecord : woRecords )
            { 
                System.debug('Inside Identify Confirmed and Close Contacts Case ids');            
                System.debug('woRecord.RecordTypeId : '+woRecord.RecordTypeId);            
                System.debug('woRecord.Status : '+woRecord.status);            
                System.debug('woRecord.CaseId : '+woRecord.CaseId);            
                System.debug('mapOldWorkOrder.get(woRecord.Id).status : '+mapOldWorkOrder.get(woRecord.Id).status);
                System.debug('interviewWORecordTypeId: '+interviewWORecordTypeId);            
                            
                if((woRecord.RecordTypeId == ccInterviewWORecordTypeId || woRecord.RecordTypeId == interviewWORecordTypeId)
                && woRecord.status == 'Completed' 
                && mapOldWorkOrder.get(woRecord.Id).status != 'Completed'
                && woRecord.CaseId != null)
                {   
                    caseIds.add(woRecord.CaseId);   
                }                        
                
            }
            System.debug('caseIds ' + caseIds); 
            if (caseIds.isEmpty()) {
                return;
            }
            //If close contacts available then identify the CEP records so that secondary close contacts to be quarantined
            if(caseIds.size() > 0){
                Map<Id,Id> mapOfCaseIdToAccountId = new Map<Id,Id>();
                Map<Id,Id> mapOfCaseIdToRecordTypeId = new Map<Id,Id>();
                System.debug('Inside Identify CEP records');
                List<Case> secContactsToBeUpdated = new List<Case>();
                for(ContactEncounterParticipant cepRecord : [Select Id, Record__c, Record__r.RecordTypeId, Parent_Record__c, Parent_Record__r.ContactId, Parent_Record__r.AccountId, Record__r.Status, Parent_Record__r.Status 
                                                            from ContactEncounterParticipant where Parent_Record__c IN : caseIds AND (Parent_Record__r.RecordTypeId = : closeContactRecordTypeId OR Parent_Record__r.RecordTypeId = :confirmedCaseRecordTypeId)]){
                    if(cepRecord.Record__c != null && cepRecord.Record__r.Status == 'Identify') {                    
                        System.debug('cepRecord.Record__c ' + cepRecord.Record__c);
                        Case scRef = new Case();
                        scRef.Id = cepRecord.Record__c;
                        scRef.Status = 'Quarantine';
                        //Assign Close Contact Person AccountId to Secondary Close Contact
                        if(cepRecord.Parent_Record__r.AccountId != Null){
                            //scRef.AccountId = cepRecord.Parent_Record__r.AccountId;
                            //scRef.ContactId = cepRecord.Parent_Record__r.ContactId;
                            mapOfCaseIdToAccountId.put(cepRecord.Record__c, cepRecord.Parent_Record__r.AccountId);
                        }
                        mapOfCaseIdToRecordTypeId.put(cepRecord.Record__c, cepRecord.Record__r.RecordTypeId);
                        secContactsToBeUpdated.add(scRef);                  
                    }  
                }
                System.debug('secContactsToBeUpdated ' + secContactsToBeUpdated);
                //Update secondary close contacts
                if(secContactsToBeUpdated.size() > 0){
                    System.debug('Inside update secondary contact records' + secContactsToBeUpdated);
                    Database.update(secContactsToBeUpdated);
                    
                    //Create Interview Work Orders                
                    List<WorkOrder> interviewWorkOrderToBeCreated = new List<WorkOrder>();
                    for(Case sccRecord : secContactsToBeUpdated){                  
                        WorkOrder iWorkOrder = new WorkOrder(); 
                        iWorkOrder.CaseId = sccRecord.Id;     
                        
                        if(mapOfCaseIdToRecordTypeId.get(sccRecord.Id) != null && mapOfCaseIdToRecordTypeId.get(sccRecord.Id) == secondaryCloseContactRecordTypeId){
                            //Assign Secondary_Close_Contact_Interview WO RecordType Id
                            iWorkOrder.RecordTypeId = secInterviewWORecordTypeId;
                        }else if(mapOfCaseIdToRecordTypeId.get(sccRecord.Id) != null && mapOfCaseIdToRecordTypeId.get(sccRecord.Id) == closeContactRecordTypeId){
                            //Assign Close_Contact_Interview WO RecordType Id
                            iWorkOrder.RecordTypeId = ccInterviewWORecordTypeId;   
                        }
                        //Assign Close Contact Person AccountId to Secondary Close Contact's WorkOrder
                        if(mapOfCaseIdToAccountId.get(sccRecord.Id) != Null){
                        // iWorkOrder.AccountId = mapOfCaseIdToAccountId.get(sccRecord.Id);                        
                        }
                        interviewWorkOrderToBeCreated.add(iWorkOrder);                    
                    }
                    
                    if(interviewWorkOrderToBeCreated.size() > 0){
                        System.debug('Inside interview record creation');
                        Database.insert(interviewWorkOrderToBeCreated);
                    }
                }
            }
        }
                    //Feature 260477: Close Contact Interview Completed = Checked
        //Feature 260477: Close Contact Interview Completed = Checked
        private static void handleCloseContactInterview(List<WorkOrder> workOrders, Map<Id, WorkOrder> mapOldWorkOrder) {
            List<Case> casesToUpdate = new List<Case>();
            List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
            Map<Id, WorkOrder> caseIdToWorkOrderMap = new Map<Id, WorkOrder>();
            Map<Id, List<WorkOrder>> caseWorkOrderMap = new Map<Id, List<WorkOrder>>();
            Id closeContacInterviewRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Interview').getRecordTypeId();
            Id closeContactMonitoringRecordTypeId   = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Monitoring').getRecordTypeId();
            for(WorkOrder wo : workOrders) {

                if (wo.Status != mapOldWorkOrder.get(wo.Id).Status
                    && wo.Status == 'Completed'
                    && wo.RecordTypeId == closeContacInterviewRecordTypeId
                    && wo.Subject == 'Initial close contact interview') {
                        caseIdToWorkOrderMap.put(wo.CaseId, wo);
                }
            }

            if (caseIdToWorkOrderMap.isEmpty()) {
                return;
            }

            //check existing workorders
            for (WorkOrder wo : [SELECT Id, CaseId FROM WorkOrder WHERE recordtype.DeveloperName = 'Close_Contact_Monitoring' AND Status = 'In Progress' AND CaseId IN: caseIdToWorkOrderMap.keySet()]) {
                if (!caseWorkOrderMap.containsKey(wo.CaseId)) {
                    caseWorkOrderMap.put(wo.CaseId, new List<WorkOrder>{wo});
                } else {
                    caseWorkOrderMap.get(wo.CaseId).add(wo);
                }         
            }
         

            for(Case c : [SELECT Id, Initial_Interview_completed__c, Initial_Interview_Completed_Time__c, HealthCloudGA__DueDate__c, OwnerId, AccountId, Account.PersonContactId
                          FROM CASE
                          WHERE Initial_Interview_completed__c = FALSE AND Initial_Interview_Completed_Time__c = NULL 
                          AND Status != 'Closed' AND Id IN: caseIdToWorkOrderMap.keySet()]) {
                            System.debug('WWWWWABN11:' + c );
                c.Initial_Interview_completed__c = TRUE;
                c.Initial_Interview_Completed_Time__c = caseIdToWorkOrderMap.get(c.Id).LastModifiedDate;
                casesToUpdate.add(c);
                
                //create a work order only if the below workorder does not exist
                if (!caseWorkOrderMap.containsKey(c.Id)) {
                    WorkOrder     tempWo = new WorkOrder();
                    tempWo.RecordTypeId  = closeContactMonitoringRecordTypeId;
                    tempWo.Subject       = 'Close Contact Monitoring';
                    tempWo.Status        = 'In Progress';
                    tempWo.OwnerId       = c.OwnerId;
                    tempWo.CaseId        = c.Id;
                    tempWo.AccountId     = c.AccountId;
                    tempWo.ContactId     = c.Account.PersonContactId;  
                    workOrdersToInsert.add(tempWo);
                }
            }

            //update case
            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
            
            //insert workorders
            if (!workOrdersToInsert.isEmpty()) {
                insert workOrdersToInsert;
            }
        }
    
    
    }