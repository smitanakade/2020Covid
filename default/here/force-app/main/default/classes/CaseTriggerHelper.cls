/**
* @Author             : DHHS
* @Description        : Case trigger helper 
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 26/04/2021     Cyrille Jeufo       Feature 270142 : Added clearInterviewFields
* 28/04/2021     Cyrille Jeufo       Feature 269587 : Added createELRTask
* 30/6/2021      Sai Kallu           Feature 298670 : Work Order Owner not updating with Record Owner change
* 13/07/2021     Pratyush Chalasani  Bugfix 302967: Setting WorkOrder owner to the Case owner
* 29/07/2021     Hemant Singh  Bugfix 305624: copyPccDatesToScc - fixing duplicate ids in list issue
* 20/09/2021     Pratyush Chalasani   Feature 323048: Shift trigger functions to dcPluginMerge (removed code from here)
* 24/09/2021     Hemant Singh        PBI 323006: Updated Clearance Eligibility Assessment Date
* 27/09/2021     Mayukhman Pathak     Feature 273382: Create New Workorder for Day 14 Confirmed Case Clearance
* 08/10/2021     Aref Samad :        Bugfix 326858 - handleSccToPccRecordTypeChange => if none of the case record has status EX-HQ Follow-up status 
                                        then only allow status to be changed to Quarantine
* 29/09/2021     Sukumar Salla       PBI 313212: MC - PCC initial notifications
* 08/10/2021     Xiang Zheng  		  PBI 326131 :  Fix Confirmed Case Interview Work Order Trigger, add method createInterviewWorkOrdersNew
* 14/10/2021     Aref Samad           PBI 326876 - Case Changed to Confirmed(Refactoring 2.0 - Rework of Sprint 10 PBI)
* 03/11/2021     Aref Samad           PBI 309115 : Email Notification To LPHUs/Queue when a Confirmed Case is Auto-allocated from Informatics Queue 
* 03/05/2021     Lija Jawahar         PBI 319578 - Removing Release Information on Active Records
* 10/11/2021     Aref Samad           PBI 318055 - Functional fix - Status and blank sub-status when Record Types changed   
* 15/11/2021     Krishna Suram        PBI 335716 - Remove Opt out of SMS automation from Clinical Care Management = Covid Positive Pathway
* 14/11/2021     Sai Kallu        	  PBI 332422 : OBM - Flagging when a Location is linked to an active Exposure Management record
* 06/11/2021     Krishna Suram        PBI 333814 DVR Integration - call platform API to publish DVR Option 1 search to Mystery Case Tracker
* 18/11/2021     Xiang Zheng          PBI 337536 : Adjust logic on Clearance Assessment Eligibility Date.
**/


public class CaseTriggerHelper {

// When Case Trigger is updating the child Work Order and Task records, set this flag to true
public static Boolean CASE_TRIGGER_UPDATING_OWNERS = false;


public static final Id CASE_EXPOSURE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Outbreak').getRecordTypeId();
public static final Id CASE_CASUAL_CONTACT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Casual_Contact').getRecordTypeId();
public static final Id CASE_CLOSE_CONTACT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
public static final Id CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
public static final Id CASE_COVID_19_ASSESSMENT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();

    public static final Id CASE_COVID_19_SCREENING_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Screening').getRecordTypeId();
    public static final Id CASE_ACQUISITION_CONTACT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Acquisition_Contact').getRecordTypeId();
    public static final Id CASE_UNCLASSIFIED_CONTACT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Unclassified_Contact').getRecordTypeId();
            
    public static final List<AccountEntitlements__mdt> ACCOUNT_ENTITLEMENTS_MDT = [SELECT Id, EntitlementId__c, Label FROM AccountEntitlements__mdt];
    public static final Id CASE_OUTBREAK_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Outbreak').getRecordTypeId();

    public static final String CASE_SCC_STATUS_IDENTIFY = 'Identify';
    public static final String CASE_STATUS_TRACE = 'Trace';
    public static final String CASE_STATUS_ISOLATE = 'Isolate';
    public static final String CASE_STATUS_CLOSE = 'Closed';
    public static final String CASE_SCC_STATUS_QUARANTINE = 'Quarantine';
    public static final String RECORDTYPE_CASE_SECONDARY_CLOSE_CONTACT = 'Secondary_Close_Contact';
    public static final String WO_STATUS_COMPLETED = 'Completed';
    public static final String WO_STATUS_CLOSE ='Closed';
    public static final String WO_STATUS_CANCELLED ='Cancelled';
    public static final String RECORDTYPE_WORK_ORDER_PCC_INTERVIEW = 'Close_Contact_Interview';
    public static final String RECORDTYPE_WORK_ORDER_PCC_MONITORING = 'Close_Contact_Monitoring';
    public static final String RECORDTYPE_WORK_ORDER_PCC_CLEARANCE = 'Close_Contact_Clearance';
    public static final String RECORDTYPE_WORK_ORDER_SCC_INTERVIEW = 'Secondary_Close_Contact_Interview';
    public static final String RECORDTYPE_WORK_SCC_MONITORING = 'Secondary_Close_Contact_Monitoring';
    public static final String RECORDTYPE_WORK_ORDER_SCC_CLEARANCE = 'Secondary_Close_Contact_Clearance';

    public static final String EHRO_TEST_TYPE_ANTIGEN_DETECTION ='PHESS-TEST-5';
    public static final String EHRO_TEST_RESULT_ANTIGEN_DETECTED ='260373001';
    public static final String EHRO_TEST_RESULT_INDICATIVE_PENDING ='PHESS-RES-22';
    public static final String EHRO_TASK_SUBJECT = 'Rapid Antigen Screening Call';

    public static final Id WORKORDER_CONFIRMEDCASE_RECORD_TYPE_ID = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
    public static final Id WORKORDER_CONFIRMEDCASE_MONITORING_RECORD_TYPE_ID = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Confirmed_Case_Monitoring_Work_Order').getRecordTypeId();
    public static final Id WORKORDER_SCC_INTERVIEW_RECORD_TYPE_ID = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact_Interview').getRecordTypeId();
    public static final Id WORKORDER_CONFIRMEDCASE_CLEARANCE_RECORD_TYPE_ID = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Confirmed_Case_Clearance').getRecordTypeId();
    public static final Id pccInterviewWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_PCC_INTERVIEW).getRecordTypeId();
    public static final Id pccMonitoringWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_PCC_MONITORING).getRecordTypeId();
    public static final Id pccClearanceWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_PCC_CLEARANCE).getRecordTypeId();
    public static final Id sccClearanceWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_SCC_CLEARANCE).getRecordTypeId();
    public static final Id SCCMonitoringWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_SCC_MONITORING).getRecordTypeId();
    public static final Id confirmedMonitoringWorkOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WORK_ORDER_SCC_CLEARANCE).getRecordTypeId();

    public static final String WO_PERSON_INTERVIEWED_CASE = 'Case';
    public static final String WO_PERSON_INTERVIEWED_SSC = 'Secondary Close Contact';

    public static final String WO_SUBJECT_CONFIRM_CASE_INTERVIEW ='Confirmed Case Interview';
    public static final String WO_SUBJECT_SCC_INTERVIEW ='Secondary Close Contact Interview';

    public static final String WO_STATUS_NEW ='New';
    public static final String WO_PRIORITY_LOW ='Low';

    public static final List<String> workOrderIgnoreStatuses = new String[]{WO_STATUS_CLOSE, WO_STATUS_COMPLETED, WO_STATUS_CANCELLED};
    public static final Id WORKORDER_HEP_REFERAL_RECORD_TYPE_ID = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('HEP_Referral').getRecordTypeId();
    public static final Id TASK_LOG_A_CALL_RECORD_TYPE_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Log_A_Call').getRecordTypeId();
    public static final Id TASK_COMMUNICATION_RECORD_TYPE_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Communication').getRecordTypeId();
    public static final Id TASK_NEW_TASK_RECORD_TYPE_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('New_Task').getRecordTypeId();

    public static final String T_STATUS_WAITING = 'Waiting on someone else';
    public static final String T_STATUS_DEFERRED = 'Deferred';
    public static final String T_STATUS_NO_RESPONSE = 'No response';
    public static final String T_STATUS_QA = 'In QA';
    public static final String T_STATUS_PENDING = 'Pending';
    public static final String T_STATUS_REJECTED = 'Rejected';
    public static final String T_STATUS_NO_ANSWER = 'No Answer';
    public static final String T_STATUS_MEDICAL = 'Medical Review';
    public static final String T_STATUS_F_I_REQUIRED = 'Further Interview Required';
    public static final String T_STATUS_UNSUCCESSFUL = 'Unsuccessful';
    public static final String T_STATUS_VOICEMAIL = 'Left voicemail';
    public static final String T_STATUS_CALL_BACK = 'Request call back';
    public static Boolean publishDVREvent = false;
    
        public static final List<String> taskOrderIgnoreStatuses = new String[]{WO_STATUS_CLOSE, WO_STATUS_COMPLETED, WO_STATUS_CANCELLED
                                                                            , T_STATUS_WAITING, T_STATUS_DEFERRED, T_STATUS_NO_RESPONSE, T_STATUS_QA, T_STATUS_PENDING, T_STATUS_PENDING, T_STATUS_REJECTED
                                                                            , T_STATUS_NO_ANSWER, T_STATUS_MEDICAL, T_STATUS_F_I_REQUIRED, T_STATUS_UNSUCCESSFUL, T_STATUS_VOICEMAIL, T_STATUS_CALL_BACK};
    
        //PBI 319578 - Records with Active status shouldnot have release Information- Data clean up                                                                     
        Public static void removeReleaseInformationForActiveRecords(List<Case> newCases, Map<Id, Case> oldCases){
    
            for(Case newCase: newCases){
                // 'Active' statuses --> [Identify, Quarantine, Trace, Isolate] - These shouldnt have Release information.
                if(newCase.Status == CASE_SCC_STATUS_IDENTIFY || newCase.Status == CASE_STATUS_TRACE ||newCase.Status ==  CASE_STATUS_ISOLATE || newCase.Status ==  CASE_SCC_STATUS_QUARANTINE) {
                    newCase.Date_Cleared_from_Isolation__c = null;
                    newCase.Case_Cleared_from_Isolation__c = null;
                    newCase.Has_Clearance_Letter_Been_Sent__c = null;
                }
            }
        }
        
        //PBI 326131 Fix Confirmed Case Interview Work Order Trigger
        //'Confirmed Case Interview' Work Order must be created against 'COVID-19 Case Assessment' record only when the Event Classification is set to 'Confirmed'.  
        //The creation of the Work Order can either be at the time of CREATION or UPDATE of the Case Assessment record,  but when the Event Classification criteria is met.
        Public static void createInterviewWorkOrdersNew(List<Case> newCases, Map<Id, Case> oldCases){
            
            List<WorkOrder> workOrdersToCreate = new List<WorkOrder>();
            try{
                if(oldCases == null){
                    //handle the case creation. 
                    for(Case newCase: newCases){
                        if(newCase.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE && newCase.Case_Classification__c == 'Confirmed'){
                            WorkOrder newWorkOrder = new WorkOrder();
                            newWorkOrder.AccountId = newCase.AccountId;
                            newWorkOrder.ContactId = newCase.ContactId;
                            newWorkOrder.CaseId = newCase.Id;
                            newWorkOrder.RecordTypeId = WORKORDER_CONFIRMEDCASE_RECORD_TYPE_ID;
                            newWorkOrder.Person_Interviewed__c = WO_PERSON_INTERVIEWED_CASE;
                            newWorkOrder.Subject = WO_SUBJECT_CONFIRM_CASE_INTERVIEW;
                            newWorkOrder.ownerId = newCase.ownerId;
        
                            workOrdersToCreate.add(newWorkOrder);
                        }
                    }
                }else{
                    //handel the case update. 
                    List<Id> caseIdList = new List<Id>();
                    List<Case> tempCaseList = new List<Case>();
                    Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
        
                    //find all the cases need to handle
                    for(Case newCase: newCases){
                        if(newCase.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE && newCase.Case_Classification__c == 'Confirmed' && oldCases.get(newCase.Id).Case_Classification__c != 'Confirmed'){
                            caseIdList.add(newCase.Id);
                            tempCaseList.add(newCase);
                        }
                    }
        
                    //find the related work orders with 'Confirmed Case Interview' record type
                    List<WorkOrder> workOrderList = [SELECT Id,CaseId FROM WorkOrder WHERE CaseId = :caseIdList AND RecordTypeId = :WORKORDER_CONFIRMEDCASE_RECORD_TYPE_ID];
                    for(WorkOrder wo: workOrderList){
                        workOrderMap.put(wo.CaseId,wo);
                    }
        
                    for(Case theCase: tempCaseList){
                        //creaet the work order if the case doesn't have a 'Confirmed Case Interview' work order.
                        if(workOrderMap.get(theCase.Id) == null){
                            WorkOrder newWorkOrder = new WorkOrder();
                            newWorkOrder.AccountId = theCase.AccountId;
                            newWorkOrder.ContactId = theCase.ContactId;
                            newWorkOrder.CaseId = theCase.Id;
                            newWorkOrder.RecordTypeId = WORKORDER_CONFIRMEDCASE_RECORD_TYPE_ID;
                            newWorkOrder.Person_Interviewed__c = WO_PERSON_INTERVIEWED_CASE;
                            newWorkOrder.Subject = WO_SUBJECT_CONFIRM_CASE_INTERVIEW;
                            newWorkOrder.ownerId = theCase.ownerId;
        
                            workOrdersToCreate.add(newWorkOrder);
                        }
                    }
                }
        
                //insert the work orders
                if(!workOrdersToCreate.isEmpty()){
                    insert workOrdersToCreate;
                }
            } catch (Exception e) {
                //TODO: log any errors here with future error handling framework
                throw new CaseTriggerHandlerException(e);
            }
        }
    
        public static void copyPccDatesToScc(List<Case> lstCases, Map<Id, Case> mapOldCase) {
            List<Id> pccCaseIds = new List<Id>();
    
            for(Case caseRec : lstCases){
                if(caseRec.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE
                && (mapOldCase.get(caseRec.Id).Day_0_Exposure_to_primarycc__c != caseRec.Day_0_Exposure_to_primarycc__c
                || mapOldCase.get(caseRec.Id).Day_0_Exposure_to_the_confirmed_case__c != caseRec.Day_0_Exposure_to_the_confirmed_case__c
                || mapOldCase.get(caseRec.Id).Parent_Record_Released__c != caseRec.Parent_Record_Released__c)){
    
                    pccCaseIds.add(caseRec.Id);
    
                }
            }
            if(pccCaseIds.size() > 0){
                List<Case> secondaryCasesToBeUpdated = new List<Case>();
                for(ContactEncounterParticipant cep : [select id, record__c,record__r.Day_0_Exposure_to_the_confirmed_case__c,record__r.Day_0_Exposure_to_primarycc__c,
                record__r.Primary_close_contact_Day_11_test__c,record__r.Primary_close_contact_Day_14__c,record__r.Parent_Record_Released__c,
                parent_record__c,parent_record__r.Day_0_Exposure_to_the_confirmed_case__c,parent_record__r.Day_0_Exposure_to_primarycc__c,
                parent_record__r.Day_11_Test__c,parent_record__r.Case_Cleared_from_Isolation__c,parent_record__r.Day14_Anticipated_last_day_of_quarantine__c,parent_record__r.Parent_Record_Released__c
                from ContactEncounterParticipant where parent_record__c IN:pccCaseIds
                and record__r.recordtypeId =: CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE ]){
                    Case secCaseRef = new Case();
                    secCaseRef.Id = cep.record__r.Id;
                    secCaseRef.Day_0_Exposure_to_the_confirmed_case__c = cep.parent_record__r.Day_0_Exposure_to_the_confirmed_case__c;
                    secCaseRef.Primary_close_contact_Day_11_test__c = cep.parent_record__r.Day_11_Test__c;
                    secCaseRef.Primary_close_contact_Day_14__c = cep.parent_record__r.Day14_Anticipated_last_day_of_quarantine__c;
                    secCaseRef.Parent_Record_Released__c = cep.parent_record__r.Case_Cleared_from_Isolation__c;
                    secondaryCasesToBeUpdated.add(secCaseRef);
                }
                //Bugfix-305624  using map to remove duplicate ids from the list
                    map<Id,Case> secondaryCasesToBeUpdatedById =  new map<Id,Case>();
                    
                    secondaryCasesToBeUpdatedById.putall(secondaryCasesToBeUpdated);
                    
                    if(secondaryCasesToBeUpdatedById.size() > 0){
                        update secondaryCasesToBeUpdatedById.values();
                    }
            }
        }
    
           /**
        * for Primary Close Contact, Secondary close contact and casual contact record the case owner should be fetched based on the post code on Contact point address of type Discharge
        * When no discharge address identified owner should be assigned to CCU    
        */
        
        public static void fetchCaseOwnerforHQResident(List<case> HQCases, List<Id> HQAccountIds){
            
           List<ContactPointAddress> ALLDischargeCPAs = New List<ContactPointAddress>([select id,postalcode,parentid, lastmodifieddate from ContactPointAddress where parentid IN :HQAccountIds AND AddressType = 'Discharge']);
           Map<Id,String> AccountsrelatedPostcodeMap = new Map<Id,String>();
           Map<Id,ContactPointAddress> tempAccountRelatedPostCodeMap = new Map<Id, ContactPointAddress>(); // to hold latest modified CPA
            Set<String> Postcodes = new Set<String>();
            for(ContactPointAddress CPA : ALLDischargeCPAS){
                if(CPA.postalcode != null && CPA.postalcode != ''){
                    Postcodes.add(CPA.postalcode);
                    if(!tempAccountRelatedPostCodeMap.containsKey(CPA.parentid)){
                        tempAccountRelatedPostCodeMap.put(CPA.parentid,CPA);
                        AccountsrelatedPostcodeMap.put(CPA.parentid,CPA.postalcode);
                    }
                    else{
                        ContactPointAddress existingCPA = tempAccountRelatedPostCodeMap.get(CPA.parentid);
                        if(CPA.lastmodifieddate > existingCPA.lastmodifieddate){
                            AccountsrelatedPostcodeMap.put(CPA.parentid,CPA.postalcode);
                            tempAccountRelatedPostCodeMap.put(CPA.parentid,CPA);
                        }
                    }
                    
                }
            }
           // Create a map of Postcode and QueueAllocation 
           List<Queue_Allocation__c> AllRealtedQueueAllocations = New List<Queue_Allocation__c>([Select id,queue_name__c,postcode__c from Queue_Allocation__c where postcode__c IN :Postcodes ]);
           Map<string,Queue_Allocation__c> PostcodeQAMap = new Map<String,Queue_Allocation__c>();
            for(Queue_Allocation__c QA :AllRealtedQueueAllocations){
                if(QA.Postcode__c != '' && QA.Queue_Name__c != ''){
                    PostcodeQAMap.put(QA.Postcode__c,QA);
                }
            }
            // Get the case owner id 
            for (case HQC : HQCases){
                if(AccountsrelatedPostcodeMap.Keyset().contains(HQC.AccountId) && PostcodeQAMap.size()>0 ){
                HQC.OwnerId = CaseQueueAllocator.QUEUE_BY_NAME.get(PostcodeQAMap.get(AccountsrelatedPostcodeMap.get(HQC.AccountId)).Queue_Name__c).Id;    
                }else{
                 HQC.OwnerId = CaseQueueAllocator.QUEUE_BY_NAME.get(CaseQueueAllocator.FALLBACK_QUEUE).Id;   
                } 
                
            }
            
        }
        
        public static void updateRelatedContactsWithPCCandSCCWhenManuallyUntickTheOngoingExposure(List<Case> newCases, Map<Id, Case> oldCasesById) {
            List<Id> casestoProcesss = new List<Id>();
    
            for (Case cc : newCases) {
                if (!cc.On_going_exposure__c && oldCasesById.get(cc.Id).On_going_exposure__c) {
                    casestoProcesss.add(cc.Id);
                }
            }
    
            List<ContactEncounterParticipant> cepsToUpdate = new List<ContactEncounterParticipant>();
    
            for (ContactEncounterParticipant cep : [SELECT Id, Parent_Record__c, Record__c, On_going_exposure__c, Contact_Type__c, ContactEncounter.End_Time__c
                                                    FROM ContactEncounterParticipant
                                                    WHERE Record__c IN :casestoProcesss
                                                    AND Parent_Record__c != null AND On_going_exposure__c = true AND (Contact_Type__c = 'Secondary Close Contact' OR Contact_Type__c = 'Close contact')]) {
                cep.On_going_exposure__c = false;
                cepsToUpdate.add(cep);
            }
    
            if (!cepsToUpdate.isEmpty()) update cepsToUpdate;
        }
    
        Public static void updatePCCandSCConReleaseofConfirmedCase(List<Case> newCases, Map<Id, Case> oldCasesById){
            List<Id> casestoProcesss = new List<Id>();
    
            for (Case cc : newCases) {
                if (cc.Status == 'Closed' && oldCasesById.get(cc.Id).Status != 'Closed' && cc.SubStatus__c == 'Release' && oldCasesById.get(cc.Id).SubStatus__c != 'Release') {
                    casestoProcesss.add(cc.Id);
                }
            }
    
            List<ContactEncounterParticipant> cepsToUpdate = new List<ContactEncounterParticipant>();
            List<Case> recordsToUpdate = new List<Case>();
    
            Map<Id, List<ContactEncounterParticipant>> recordToParentRecordCEPMap = new Map<Id, List<ContactEncounterParticipant>>();
    
            for (ContactEncounterParticipant cep : [SELECT Id, Parent_Record__c, Record__c, On_going_exposure__c, Contact_Type__c, ContactEncounter.End_Time__c
                                                    FROM ContactEncounterParticipant
                                                    WHERE Parent_Record__c IN :casestoProcesss
                                                    AND Record__c != null /*AND On_going_exposure__c = true*/ AND (Contact_Type__c = 'Secondary Close Contact' OR Contact_Type__c = 'Close contact')]) {
                if (recordToParentRecordCEPMap.containsKey(cep.Record__c)) {
                    recordToParentRecordCEPMap.get(cep.Record__c).add(cep);
                } else {
                    List<ContactEncounterParticipant>cepList = new List<ContactEncounterParticipant>();
                    cepList.add(cep);
                    recordToParentRecordCEPMap.put(cep.Record__c, cepList);
                }
            }
    
            //Should run again to get multiple links to a single record
            for (ContactEncounterParticipant cep : [SELECT Id, Parent_Record__c, Record__c, On_going_exposure__c, Contact_Type__c, ContactEncounter.End_Time__c
                                                    FROM ContactEncounterParticipant
                                                    WHERE Record__c IN  :recordToParentRecordCEPMap.keyset() AND On_going_exposure__c = true AND (Contact_Type__c = 'Secondary Close Contact' OR Contact_Type__c = 'Close contact')]) {
                if (recordToParentRecordCEPMap.containsKey(cep.Record__c)) {
                    recordToParentRecordCEPMap.get(cep.Record__c).add(cep);
                } else {
                    List<ContactEncounterParticipant>cepList = new List<ContactEncounterParticipant>();
                    cepList.add(cep);
                    recordToParentRecordCEPMap.put(cep.Record__c, cepList);
                }
            }
    
            if (!recordToParentRecordCEPMap.isEmpty()) {
                for (Id recordId : recordToParentRecordCEPMap.keySet()) {
    
                    ContactEncounterParticipant cep;
    
                    if (recordToParentRecordCEPMap.get(recordId).size() > 1) {
                        //Where a Record is exposed to multiple Parent Records
                        List<ContactEncounterParticipant>cepList = recordToParentRecordCEPMap.get(recordId);
                        cep = cepList.get(0);
                        for (ContactEncounterParticipant cepTemp : cepList) {
                            if (cepTemp.ContactEncounter.End_Time__c > cep.ContactEncounter.End_Time__c) {
                                cep = cepTemp;
                            }
                        }
                    } else {
                        cep = recordToParentRecordCEPMap.get(recordId).get(0);
                    }
    
                    if (cep != null && cep.On_going_exposure__c && casestoProcesss.contains(cep.Parent_Record__c)) {
                        cep.On_going_exposure__c = false;
                        cepsToUpdate.add(cep);
                        recordsToUpdate.add(new Case(Id = cep.Record__c, On_going_exposure__c = false));
                    }
                }
            }
    
            if (!cepsToUpdate.isEmpty()) update cepsToUpdate;
            if (!recordsToUpdate.isEmpty()) update recordsToUpdate;
    
        }
    
    
          /**
        * When the Primary Close Contact record is released and field: Released = Yes then 
        * The field 'Parent Contact Released' on the Secondary Close Contact record should be updated to = Yes
        *  PBI = 256028
        *     
        */
        Public static void updateSCConreleaseofPCC(List<Case> newCases, Map<Id, Case> oldCasesById){
            
         List<case> secondaryclosecontactstoupdate = new List<case>();
         List<case> PCCstoProcess = new List<case>(); 
         // Store all PCC Ids where   Case_Cleared_from_Isolation__c is updated to Yes 
         List<Id> PCCstoProcessIds = new List<Id>();
         List<Id> PCCstoProcessIdspositive = new List<Id>();  
         List<Id> PCCstoProcessIdsnegative = new List<Id>();  
            for(case pcc : newCases){
                if(pcc.Case_Cleared_from_Isolation__c == 'Yes' && pcc.Case_Cleared_from_Isolation__c != oldCasesById.get(pcc.id).Case_Cleared_from_Isolation__c){
                    PCCstoProcess.add(pcc);
                    PCCstoProcessIds.add(pcc.id);
                    PCCstoProcessIdspositive.add(pcc.id);
                    }
                if(pcc.Case_Cleared_from_Isolation__c != 'Yes' &&  oldCasesById.get(pcc.id).Case_Cleared_from_Isolation__c == 'Yes'){
                    PCCstoProcess.add(pcc);
                    PCCstoProcessIds.add(pcc.id);
                    PCCstoProcessIdsnegative.add(pcc.id);
                }
            }
         if(PCCstoProcess.size() == 0 && !Test.isRunningTest())return;
         
         // Fetch All CEPs related to PCCs where contact type = Secondary Close Contact   
         List<ContactEncounterParticipant> CEPrelatedtoPCCs = new List<ContactEncounterParticipant>();
         // Store Related SCC Ids
         List<Id> CEPSCCIds = new List<Id>();
         CEPrelatedtoPCCs = [select id,Parent_Record__c,Record__c,On_going_exposure__c,Contact_Type__c from ContactEncounterParticipant where Parent_Record__c IN :PCCstoProcessIds and On_going_exposure__c = true and Contact_Type__c = 'Secondary Close Contact'];
            if(CEPrelatedtoPCCs.size()>0){
                for(ContactEncounterParticipant CEPP: CEPrelatedtoPCCs ){
                    if(CEPP.Record__c != null){
                        CEPSCCIds.add(CEPP.Record__c);
                    }
                }
            }
         // Verify if the pcc related to the fetched scc in the above step is the latest one
         List<ContactEncounterParticipant> CEPrelatedtoSCCs = new List<ContactEncounterParticipant>();
         CEPrelatedtoSCCs = [select id,Parent_Record__c,Record__c,On_going_exposure__c,createddate,Contact_Type__c,ContactEncounter.End_Time__c from ContactEncounterParticipant where Record__c IN :CEPSCCIds and On_going_exposure__c = true and Contact_Type__c = 'Secondary Close Contact'];
         // Below map stores all latest PCCs related to SCC
            Map<id,ContactEncounterParticipant> RecordCEPMap = new Map<id,ContactEncounterParticipant>();
            if(CEPrelatedtoSCCs.size()>0){
                for(ContactEncounterParticipant CEPS : CEPrelatedtoSCCs){
                    if(RecordCEPMap.keySet().contains(CEPS.Record__c)){
                        if(RecordCEPMap.get(CEPS.Record__c).ContactEncounter.End_Time__c < CEPS.ContactEncounter.End_Time__c){
                          RecordCEPMap.put(CEPS.Record__c,CEPS);  
                        }
                    }else{
                        RecordCEPMap.put(CEPS.Record__c,CEPS);
                    }
                }
            }
            // Verify if the latest PCC from the map is a part of the scope
            for (Id SCCID : RecordCEPMap.keyset()){
                if(PCCstoProcessIdspositive.contains(RecordCEPMap.get(SCCID).parent_record__c)){
                    case scc = new case();
                    scc.id = SCCID;
                    scc.Parent_Record_Released__c = 'Yes';
                    secondaryclosecontactstoupdate.add(scc);
                }
                if(PCCstoProcessIdsnegative.contains(RecordCEPMap.get(SCCID).parent_record__c)){
                    case scc = new case();
                    scc.id = SCCID;
                    scc.Parent_Record_Released__c = null;
                    secondaryclosecontactstoupdate.add(scc);
                }
            } 
            if(secondaryclosecontactstoupdate.size()>0){
                update secondaryclosecontactstoupdate;
            } 
            
        }
        
    
        /**
        * replaces the ProcessBuilder flow: 'Is Exposure Mgmt Record' which was invoked from caseHandler.
        *   Entry Criterea:
        *      Record Type = Exposure Management
        *      Is New Record
        *   Expected Output:
        *      DHHS Declared Date is populated to equal the date of creation (regardless of whether it was inserted with a value or not)
        */
        public static void exposureManagementSetDeclaredDate(List<Case> newCases){
            for(Case newCase : newCases) {
                if((newCase.RecordTypeId == CASE_EXPOSURE_RECORD_TYPE_ID) && (newCase.DHHS_Declared_Date__c == null) ){
                    //If a new record: Created date will be null; but you can still dataload historical records in with createdDate set in the data
                    if(newCase.CreatedDate == null){
                        newCase.DHHS_Declared_Date__c = System.Now();
                    } else{
                        newCase.DHHS_Declared_Date__c = newCase.CreatedDate;
                    }
                }
            }
        }
       
        /**
        * Replaces the ProcessBuilder flow: ' Case_ChangeToConfirmed' .PBI - 286007
        *   Entry Criterea:
        *      Classification = Confirmed
        *    
        *   Expected Output:
        *     
        */
        public static void processConfirmedRecords(List<Case> newCases, Map<Id, Case> oldCasesById){
            
            List<Case> casestoprocess = new List<Case>();
            List<Id> casesIdstoprocess = new List<Id>();    
            
            try{
                // ic - individual case
                for(case ic : newCases){               
                    if(ic.Case_Classification__c == 'Confirmed' && ic.recordtypeid != CASE_COVID_19_ASSESSMENT_RECORD_TYPE){
                        casestoprocess.add(ic);
                    } 
                }
            
                // Make Case updates 
                // icp - individual case to process     
    
                for(case icp : casestoprocess){              
                    if(icp.recordtypeid != CASE_COVID_19_ASSESSMENT_RECORD_TYPE)
                    {                    
                        icp.recordtypeid = CASE_COVID_19_ASSESSMENT_RECORD_TYPE;
                        icp.Event_Type__c = 'Case';
                        icp.Initial_Interview_Completed_Time__c = null;
                        icp.Initial_Interview_completed__c = false;
                        icp.Milestone_Start_Date__c = system.now();
                        icp.Status = 'Trace';
                        icp.SubStatus__c = 'In Progress';                    
                    }            
                } 
                assignEntitlementId(casestoprocess);           
            }
            catch(Exception exp)
            {
                ApplicationLogUtility.createlog('CaseTriggerHelper','processConfirmedRecords',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
                throw exp;
            } 
    
            
            
        }
    
        /**
        * Replaces the ProcessBuilder flow: ' Case_ChangeToConfirmed' .PBI - 286007
        *   Entry Criterea:
        *      Classification = Confirmed
        *    
        *   This method will run by Platform Event(CasePEHandler/Trigger)
        *     
        */
    
        public static void processConfirmedRecordsAsync(List<Case> newCases, Map<Id, SObject> oldCasesById){
                 
            List<Id> casesIdstoprocess = new List<Id>();   
            boolean clearTasks=false;
            try {
                // ic - individual case
                for(case ic : newCases){              
                
                    if(oldCasesById != null){    
                        Case oldCase=  (Case)oldCasesById.get(ic.id);                  
                        if(ic.Case_Classification__c == 'Confirmed' && oldCase.Case_Classification__c != 'Confirmed'
                        && ic.recordtypeid == CASE_COVID_19_ASSESSMENT_RECORD_TYPE){
                            clearTasks=(oldCase.recordtypeid!=CASE_COVID_19_ASSESSMENT_RECORD_TYPE);
                            casesIdstoprocess.add(ic.Id);
                        }
                    }                            
                }
    
                if (clearTasks)
                {
                    // Update related Tasks to cancelled 
                    List<Task> Taskstoupdate = new List<Task>();
                    Taskstoupdate = [select id,status from task where WhatId IN :casesIdstoprocess And Status != 'Completed' AND status != 'Cancelled'];
                    
                    if(Taskstoupdate.size() >0){
                        for(task tu:Taskstoupdate){
                            tu.status = 'Cancelled';
                        }
                        update Taskstoupdate;
                    }
                }
                
                
                // Create Tasks 
                List<Task> TaskstoInsert = new List<Task>();
                List<ClassificationHistory__c> histories = new List<ClassificationHistory__c>();
    
                Map<Id,ClassificationHistory__c> existingConfirmedHistories=new Map<Id,ClassificationHistory__c>();
                for(ClassificationHistory__c history:[Select Id,Record_Classification__c FROM ClassificationHistory__c WHERE
                                                        Record_Classification__c IN: casesIdstoprocess and Classification__c='Confirmed'])
                {
                    existingConfirmedHistories.put(history.Record_Classification__c,history); 
                }
    
                if(casesIdstoprocess.size()>0){
                    for(ID ic : casesIdstoprocess){
                        if (clearTasks)
                        {
                                TaskstoInsert.add(new task(WhatId = ic,Status = 'Completed',Subject = 'Record Changed to Confirmed Case'));
                        }
                    
                        ClassificationHistory__c history=new ClassificationHistory__c(Record_Classification__c = ic, Classification_Date__c = system.now(), Classification__c = 'Confirmed');
                        if (existingConfirmedHistories.get(ic)==null)
                        {
                            histories.add(history);             
                        }                              
                    }
                }
                if (clearTasks)
                {
                    if(!TaskstoInsert.isEmpty()){
                        insert TaskstoInsert;
                    }   
                }
                    
            
                if(!histories.isEmpty()){
                    insert histories;
                }
                
                if (clearTasks)
                {
                    //Update all work orders to cancelled 
                    List<workorder> workordertoupdate = new List<workorder>();
                    workordertoupdate = [select id,status from workorder where CaseId IN :casesIdstoprocess And Status != 'Completed' 
                                        AND status != 'Closed' 
                                        AND status != 'Stopped' 
                                        AND RecordType.Name NOT IN ('Household Engagement Referral','Confirmed Case Interview','Confirmed Case Monitoring Work Order','Confirmed Case Clearance') ];
                    
                    if(workordertoupdate.size() >0){
                        for(workorder wu:workordertoupdate){
                            wu.status = 'Stopped';
                        }
                        update workordertoupdate;
                    }
                    
                    // Delete Survey Invitations 
                    List<SurveyInvitation> SurveyInvitationtodelete = new List<SurveyInvitation>();
                    for(SurveyInvitation SI : [select id,ResponseStatus from SurveyInvitation where Record__c IN :casesIdstoprocess And ResponseStatus != 'Completed']){
                            SurveyInvitationtodelete.add(SI);
                    }        
                    if(SurveyInvitationtodelete.size() > 0){
                            delete SurveyInvitationtodelete;
                    }
                }
            }
            catch(Exception exp)
            {
                ApplicationLogUtility.createlog('CaseTriggerHelper','processConfirmedRecordsAsync',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
                throw exp;
            } 
            
            
            
        }
        
        /**
        * Replaces the ProcessBuilder flow: 'SCc to PCC Record Type Changed' which was invoked from caseHandler.
        *   Entry Criterea:
        *      Record Type = Secondary close contact
        *      Record type is changed
        *   Expected Output:
        *      Contact related fields are set to defaults (Case and EPI Classification, Case source, Interview is Completed, Status)
        *   08/10/2021 Aref Samad : Bugfix 326858 - if none of the case record has status EX-HQ Follow-up status then only allow status to be changed to Quarantine
        */
        public static void handleSccToPccRecordTypeChange(Map<Id, Case> newCasesById, Map<Id, Case> oldCasesById){
            List<Case> casesToUpdate = new List<Case>();
            
            for(Case caseToFilter : newCasesById.values()){
                if(caseToFilter.recordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE && 
                    oldCasesById.get(caseToFilter.Id).RecordTypeId == CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE){
    
                    caseToFilter.Case_Classification__c = 'At Risk';
                    caseToFilter.Case_Found_By__c = 'Contact tracing';
                    caseToFilter.Epi_Classification__c = 'Epidemiologically linked to a laboratory confirmed case';
                    caseToFilter.Initial_Interview_completed__c = false;
                    caseToFilter.Initial_Interview_Completed_Time__c = null;
                    if (caseToFilter.Status!='Ex-HQ Follow-up' && oldCasesById.get(caseToFilter.Id).Status!='Ex-HQ Follow-up')
                    {
                        caseToFilter.Status = 'Quarantine';
                    }                
                    caseToFilter.SubStatus__c = 'In Progress';
    
                }
            }
        }
    
        /**
        * Replaces the ProcessBuilder flow: 'setFields' which was invoked from caseHandler.
        *   Entry Criterea:
        *      Outbreak_record__c is changed and not null
        *   Expected Output:
        *      The Cases "Outbreak_Setting_Type__c" should equal the related outbreak records "Setting_Type__c"
        */
        public static void updateDetailsOnOutbreakChange(Map<Id, Case> newCases, Map<Id, Case> oldCasesById){
            List<Case> casesWithChangedOutbreak = new List<Case>();
            Set<Id> relatedOutbreakIds = new Set<Id>();
            map<Id, Case> relatedOutbreakById = new Map<Id, Case>();
            List<Case> casesToSetOutbreakSetting = new List<Case>();
            
            for(Case caseToFilter : newCases.values()) {
                if(caseToFilter.Outbreak_record__c != oldCasesById.get(caseToFilter.Id).outbreak_record__c){
                    casesWithChangedOutbreak.add(caseToFilter);
                    relatedOutbreakIds.add(caseToFilter.Outbreak_record__c);
                }
            }
            
            for(Case outbreak : [SELECT ID, Setting_Type__c FROM Case WHERE Id IN : relatedOutbreakIds]) {
                relatedOutbreakById.put(outbreak.Id, outbreak);
            }
            
            // for each case in casesWithChangedOutbreak check if the Outbreak_record__c is in the map
            if(!casesWithChangedOutbreak.isEmpty()){
                for(Case record : casesWithChangedOutbreak) {
                    if(relatedOutbreakById.containsKey(record.Outbreak_record__c)){
                        record.Outbreak_setting_type__c = relatedOutbreakById.get(record.Outbreak_record__c).Setting_Type__c;
                    }
                }
            }
        }
    
        /**
        * Replaces the ProcessBuilder flow: 'Day 0 Updated' which was invoked from caseHandler.
        *   Entry Criterea:
        *      Day_0_Calculated__c is changed
        *   Expected Output:
        *      Day_15_Anticipated_release_date__c is updated to equal new Day_0_Calculated__c date plus 15 days
        */
        public static void updateForcastDateOnDayZeroChange(List<Case> newCases, Map<Id, Case> oldCasesById) {
            if(oldCasesById == null) {      //PBI332772 
                for(Case newCase : newCases) {
                    if(newCase.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE && newCase.Journey_Type__c == 'PCC 7 Day'){
                        newCase.Day_15_Anticipated_release_date__c = newCase.Day14_Anticipated_last_day_of_quarantine__c;
                    }else if(newCase.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE && newCase.Day_0_Calculated__c != null){
                        newCase.Day_15_Anticipated_release_date__c = newCase.Day_0_Calculated__c.addDays(14);
                    }
                }
            }
            else{
                for(Case newCase : newCases) {
                    if(newCase.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE){
                       // if(newCase.Journey_Type__c == 'PCC 7 Day'){
                        if(newCase.Day14_Anticipated_last_day_of_quarantine__c != null && newCase.Day14_Anticipated_last_day_of_quarantine__c!=oldCasesById.get(newCase.Id).Day14_Anticipated_last_day_of_quarantine__c){
                            newCase.Day_15_Anticipated_release_date__c = newCase.Day14_Anticipated_last_day_of_quarantine__c;   
                    }
              //  }else if(newCase.Day_0_Calculated__c != null && oldCasesById.get(newCase.Id).Day_0_Calculated__c != newCase.Day_0_Calculated__c){
              //      newCase.Day_15_Anticipated_release_date__c = newCase.Day_0_Calculated__c.addDays(14);
             //   }//PBI332772
                        
                    }
                    /*
                    if(newCase.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE &&  newCase.Day_0_Calculated__c != null &&
                        oldCasesById.get(newCase.Id).Day_0_Calculated__c != newCase.Day_0_Calculated__c){                     //commented out for PBI332772
                            newCase.Day_15_Anticipated_release_date__c = newCase.Day_0_Calculated__c.addDays(14);
                        }*/
                }
            }
        }
        /**
        * Replaces the ProcessBuilder flow: 'Initial Interview Completed?' which was invoked from caseHandler.
        *   Entry Criterea:
        *      Initial_Interview_completed__c has changed to true
        *      Account Id is blank
        *      record Type is COVID case assessment, Close Contact or Secondary Close contact
        *   Expected Output:
        *      A new "Confirmed Case" Work order is created.
        *
        *  Note that ownership of the work order is standardised so this method
        *      Does not set work order ownership. Please refer to the WorkOrderHandler process builder and the WorkOrderTriggerHandler
        *      for the implementation.
        *  Close Contact record types need an extra check on status so they only get a new workorder if in the status 'Quarantine'
        */
        public static void createWorkOrderOnInitialInterview(Map<Id, Case> newCasesById, Map<Id, Case> oldCasesById) {
            List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
            List<Case> casesThatNeedWorkorder = new List<Case>();
            Map<Id, String> subjectTextByCaseRecordType = new Map<Id,String>{
                CASE_COVID_19_ASSESSMENT_RECORD_TYPE => System.label.Work_Order_Confirmed_Case_Subject_Line,
                // CASE_CLOSE_CONTACT_RECORD_TYPE => System.label.Work_Order_Close_Contact_Subject_Line,
                CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE => System.label.Work_Order_Secondary_Contact_Subject_Line
            };
    
            for(Case newCase : newCasesById.values()) {
                if(oldCasesById == null){
                    if (newCase.Initial_Interview_completed__c) {
                        if(newCase.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE ||
                        // (newCase.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE && newCase.Status == 'Quarantine') ||
                        newCase.RecordTypeId == CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE)
                        casesThatNeedWorkorder.add(newCase);
                    }
                } else if(oldCasesById.get(newCase.Id).Initial_Interview_completed__c != newCase.Initial_Interview_completed__c && newCase.Initial_Interview_completed__c == true && newCase.AccountId != null &&
                (newCase.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE ||
                // (newCase.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE && newCase.Status == 'Quarantine') ||
                newCase.RecordTypeId == CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE)) {
                    casesThatNeedWorkorder.add(newCase);
                }
            }
            if (casesThatNeedWorkorder.size() != 0 && casesThatNeedWorkorder != null) {
                DHHS_Default_Ids__mdt md;
                Map<Id, Id> workOrderRtByCaseRt = new Map<Id, Id>{
                    CASE_COVID_19_ASSESSMENT_RECORD_TYPE => Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Confirmed_Case_Monitoring_Work_Order').getRecordTypeId(),
                    // CASE_CLOSE_CONTACT_RECORD_TYPE => Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Monitoring').getRecordTypeId(),
                    CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE => Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact_Monitoring').getRecordTypeId()
                };
    
                for(Case rec : casesThatNeedWorkorder){
                    WorkOrder wo = new WorkOrder(
                        AccountId = rec.AccountId,
                            ContactID = rec.ContactId,
                            CaseId = rec.Id,
                        RecordTypeId = workOrderRtByCaseRt.get(rec.RecordTypeId),
                            Subject = subjectTextByCaseRecordType.get(rec.recordTypeId),
                            OwnerId = rec.OwnerId //#302967
                        );
                    workOrdersToInsert.add(wo);
                }
            }
            insert workOrdersToInsert;
        }
    
    
        /**
        *   PBI - 274738
        *   Entry Criterea:
        *       'HQ Resident' = True AND Record Status = 'Ex-HQ Follow-up' on PCC,SCC
        *   Expected Output:
        *      A new "Ex-Hotel Quarantine Resident Monitoring" Work order is created.
        *
        */
        public static void createWorkOrderOnHotelQuaratine(Map<Id, Case> newCasesById, Map<Id, Case> oldCasesById) {
            system.debug('createWorkOrderOnHotelQuaratine  entry');
            List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
            List<Case> casesThatNeedWorkorder = new List<Case>();
            
            
            Id HQWoRecTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Ex_Hotel_Quarantine_Resident_Monitoring').getRecordTypeId();
            
            //if WO already created do not create again
            for(Case newCase : newCasesById.values()) {
                if(newCase.HQ_Resident__c == true && oldCasesById.get(newCase.Id).Status != 'Ex-HQ Follow-up' 
                && newCase.Status == 'Ex-HQ Follow-up' && (  newCase.RecordTypeId == CASE_CASUAL_CONTACT_RECORD_TYPE ||
                newCase.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE ||
                newCase.RecordTypeId == CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE)){
    
                    system.debug('newCase  Ex-HQ Follow-up ' + newCase);
                    casesThatNeedWorkorder.add(newCase);
    
                }
            }
            if (casesThatNeedWorkorder.size() != 0 && casesThatNeedWorkorder != null) {
                
                for(Case rec : casesThatNeedWorkorder){
                    WorkOrder wo = new WorkOrder(AccountId = rec.AccountId,
                    CaseId = rec.Id,
                    Status = 'In Progress',
                    Priority = 'Low',
                    ownerId = rec.OwnerId,
                    ContactId = rec.ContactId,
                    RecordTypeId = HQWoRecTypeId,
                    Subject = System.label.Work_Order_HQ_Subject_Line
                    );
                    
                    system.debug('wo::::  ' + wo);
                    workOrdersToInsert.add(wo);
                }
            }
            insert workOrdersToInsert;
        }
/**
    * 337536
    */
    public static void updateClearanceEligibilityDate(List<Case> newCases){
        for(Case newCase : newCases) {
			if (CASE_COVID_19_ASSESSMENT_RECORD_TYPE == newCase.recordTypeId){
				if(newCase.Date_of_Test__c != null){
					if(newCase.Clearance_eligibility_assessment_date__c == null && newCase.Date_of_Test__c != null){
						newCase.Clearance_eligibility_assessment_date__c = newCase.Date_of_Test__c.addDays(10);
					}
				}else{
					newCase.Clearance_eligibility_assessment_date__c = null;
				}
			}
        }
    }

    /**
    * 337536
    */
    public static void updateClearanceEligibilityDate(Map<Id, Case> newCasesById, Map<Id, Case> oldCasesById){
		List<Case> newCases = newCasesById.values();
		for(Case newCase : newCases){
			if (CASE_COVID_19_ASSESSMENT_RECORD_TYPE == newCase.recordTypeId){
				if(newCase.Date_of_Test__c != null){
					if(newCase.Clearance_eligibility_assessment_date__c == null && newCase.Date_of_Test__c != null){
						newCase.Clearance_eligibility_assessment_date__c = newCase.Date_of_Test__c.addDays(10);
					}
				}else{
					newCase.Clearance_eligibility_assessment_date__c = null;
				}
			}
		}
    }
        /**
        * Replaces the "PersonAccountAdded" functionality from CaseHandler process builder
        * Entry Criteria: Before Update - when the Account changes or on before insert when there is no contact Id
        *                  (because usually Person Account are linked to case so contactId will remain blank)
        * Output: ContactId is updated to reflect the main account related to the record
        */
        public static void updateContactId(List<Case> newCasesById, Map<Id, Case> oldCasesById){
            Set<Case> caseIdsToUpdate = new Set<Case>();
            Map<Id, Account> accountsById = new Map<Id,Account>();
            Set<Id> accountIds = new Set<Id>();
            if(oldCasesById == null){
                for(Case rec : newCasesById){
                    if(rec.ContactId == null){
                        caseIdsToUpdate.add(rec);
                        accountIds.add(rec.AccountId);
                    }
                }
            }
            else{
                for(Case rec : newCasesById){
                    if(rec.AccountId != oldCasesById.get(rec.Id).AccountId && rec.ContactId == oldCasesById.get(rec.Id).ContactId){
                        caseIdsToUpdate.add(rec);
                        accountIds.add(rec.AccountId);
                    }
                }
            }
            if(accountIds.isEmpty()){
                return;
            }
            accountsById = new Map<Id, Account>([SELECT ID, PersonContactId FROM Account WHERE Id IN : accountIds]);
            if(accountsById.isEmpty()){
                return;
            }
            for(Case rec : caseIdsToUpdate){
                //This will be null if business account - which is what we want in accordance with original process builder
                if(accountsById.get(rec.AccountId) != null){
                    rec.ContactId = accountsById.get(rec.AccountId).personContactId;
                }
            }
        }
    
        /**
        * Replaces the ProcessBuilder flow: 'Classification Change to Other' which was invoked from caseHandler.
        * A Classification history record needs to be inserted everytime a Record is created and another inserted if the Record
        * changes it's case classification
        *   Entry Criterea:
        *      Case_Classification__c is changed and not "Confirmed
        *      OR
        *      Is new
        *
        *   Expected Output:
        *      A new History is inserted and Classification equals the related records Case_Classification__c
        */
        public static void createClassificationHistory(Map<Id, Case> newCasesById, Map<Id,Case> oldCasesById){
            List<ClassificationHistory__c> histories = new List<ClassificationHistory__c>();
            List<Case> casesToProcess = new List<Case>();        
            for(Case rec : newCasesById.values()){
                if(oldCasesById == null) {
                    if (rec.Case_Classification__c == 'Confirmed'){
                        casesToProcess.add(rec);                
                    }                
                }
                else if((rec.EntitlementId != oldCasesById.get(rec.Id).EntitlementId && rec.Case_Classification__c != 'Confirmed')
                || (rec.Case_Classification__c != 'Confirmed' && rec.Case_Classification__c != oldCasesById.get(rec.Id).Case_Classification__c)){
                    casesToProcess.add(rec);               
                }
            }        
             
            for(Case rec : casesToProcess) {
                ClassificationHistory__c classification = new ClassificationHistory__c(Record_Classification__c = rec.Id, Classification_Date__c =rec.CreatedDate, Classification__c = rec.Case_Classification__c);
                histories.add(classification); 
            }
            if(!histories.isEmpty()){
                insert histories;
            }
        }
    
        public static void updateCaseMilestoneStartDate(List<Case> newCases){
            for(Case rec : newCases) {
                if(rec.Milestone_Start_Date__c == null) {
                    rec.Milestone_Start_Date__c = System.now();
                }
            }
        }

        public static void updateCaseMilestoneStartDate(Map<Id,Case> newMap, Map<Id,Case> oldMap){
            if(newMap!=null){
             for(Case rec : newMap.values()) {
                 if(oldMap==null && rec.Milestone_Start_Date__c == null){
                     rec.Milestone_Start_Date__c = System.now();
                 }
                 else if(oldMap!=null && rec.Case_Classification__c =='Confirmed' && oldMap.get(rec.Id).Case_Classification__c != 'Confirmed' && 
                     oldMap.get(rec.Id).recordTypeId !=CASE_COVID_19_ASSESSMENT_RECORD_TYPE && newMap.get(rec.Id).recordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE){
                        rec.Milestone_Start_Date__c = System.now();
                 }
                
             }
            }
             
         }
    
        /*
        *  Helper Method that processes a list of cases and gives them the correct Entitlement Id
        *  Entry Criterea:
        *       a list of records that needs EntitlementId set to the appropiate value
        *  Expected Output:
        *       A modified list of records with the Entitlement Id filled in based on Account Entitlement Custom Metadata which
        *       holds a record Id based on the records Record Type
        */
        public static List<Case> assignEntitlementId(List<Case> newCases) {
            Map<String, String> entitlementsIdByLabel = new Map<String, Id>();
            
            for(AccountEntitlements__mdt mdt : ACCOUNT_ENTITLEMENTS_MDT){
                entitlementsIdByLabel.put(mdt.Label, mdt.EntitlementId__c);
            }
            
            for (Case rec : newCases){
                if(rec.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE){                
                    rec.EntitlementId = entitlementsIdByLabel.get('ConfirmedCaseInitial');
                }
                else if(rec.RecordTypeId == CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE) {
                    rec.EntitlementId = entitlementsIdByLabel.get('SecondaryCloseContact');
                }
                else if(rec.RecordTypeId == CASE_EXPOSURE_RECORD_TYPE_ID) {
                rec.EntitlementId = entitlementsIdByLabel.get('CaseExposureMgmt');
                }
                else if(rec.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE && rec.EntitlementId == null && rec.related_Case_confirmation_date__c != null) {
                    rec.EntitlementId = entitlementsIdByLabel.get('CloseContact');
                }
            }
            return newCases;
        }
    
        public static void updateEntitlements(List<Case> newCases, Map<Id, Case> oldCases){
            List<Case> casesToUpdate = new List<Case>();
            for(Case rec : newCases) {
                if(oldCases == null){
                    casesToUpdate.add(rec);
                }
                else if(rec.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE && rec.EntitlementId == null) {
                    casesToUpdate.add(rec);
                }
            }
            if(casesToUpdate.size() > 0){
                assignEntitlementId(casesToUpdate);
            }
        }
    
        /*
        If substatus is empty on new Assessment Cases - default to In Progress (so long as the Status has it as a allowed value)
        Note - the API name of the unallocated value is: "In Progress"
        */
        public static void setSubstatus(List<Case> newCases) {
            for(Case rec : newCases) {
                if(rec.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE && rec.SubStatus__c == null && ((String)rec.OwnerId).left(3) == '00G'
                && (rec.Status == 'Quarantine' || rec.Status == 'Isolate' || rec.Status == 'Trace')){
                    try{
                        rec.SubStatus__c = 'In Progress';
                    }
                    catch(Exception e) {
                        System.debug('Cannot default Substatus to In Progress: ' + e.getMessage());
                    }
                }
            }
        }
    
        /**
        * Replaces the soft-delete functionality from CaseHandler process builder
        * Entry Criteria: Case on before update if the soft_deleted__c flag is changed to true and the the running user
        * is part of informatics team
        * Output: change case owner to the running user
        */
    
        public static void handleSoftDelete(Map<Id, Case> newCasesById, Map<Id,Case> oldCasesById) {
            Id userRoleId = UserInfo.getUserRoleId();
            List<Case> casesSoftDeleted = new List<Case>();
            for (Case rec : newCasesById.values()) {
                if(rec.Soft_deleted__c != oldCasesById.get(rec.Id).Soft_deleted__c && rec.Soft_deleted__c == true){
                    casesSoftDeleted.add(rec);
                }
            }
            
            //If user has no role nothing needs to happen
            if(!casesSoftDeleted.isEmpty() && userRoleId != null) {
                List<UserRole> r = [Select Id, DeveloperName FROM UserRole WHERE Id =: userRoleId];
                //Users can only have one role so no need to loop through the list.
                if(!r.isEmpty()){
                    if(r.get(0).DeveloperName == 'Informatics_Intel'){
                        for(Case rec : casesSoftDeleted){
                            rec.OwnerId = UserInfo.getUserId();
                        }
                    }
                }
            }
        }
    
        /**
        * Replaces "SurveyResponded" functionality from CaseHandler process builder
        * Entry Criteria: Case on before update if the Survey_responded flag is changed to true
        * Output: Update the Last Check-In date
        */
        public static void handleSurveyResponded(Map<Id, Case> newCasesById, Map<Id,Case> oldCasesById) {
            List<Case> casesResponded = new List<Case>();
            for (Case rec : newCasesById.values()) {
                if(rec.Survey_responded__c != oldCasesById.get(rec.Id).Survey_responded__c && rec.Survey_responded__c == true){
                    casesResponded.add(rec);
                }
            }
            if(!casesResponded.isEmpty()) {
                for(Case rec : casesResponded){
                    rec.Last_Check_in_Date__c = System.now();
                    rec.Survey_responded__c = false;
                }
            }
        }
    
        /**
        * Replaces the "Is Case Contact Has Email" and "reject/Release close contact functionality from CaseHandler process builder
        * Entry Criteria: Close Contact type Case on after update if the status is changed to closed and substatus changed to Release
        * so long as the Send_clearance_Email__c is checked and Email is filled out
        * Output: A new related Task is created for the case and assigned to close contact escalation queue
        */
        public static void createPostClearanceTaskNoEmail(Map<Id, Case> newCasesById, Map<Id,Case> oldCasesById) {
            List<Case> casesClosed = new List<Case>();
            List<Task> tasksToInsert = new List<Task>();
            Set<Id> relatedContactIds = new Set<Id>();
            for (Case rec : newCasesById.values()) {
                if((rec.Status != oldCasesById.get(rec.Id).Status || rec.SubStatus__c != oldCasesById.get(rec.Id).SubStatus__c || rec.Send_Clearance_Letter__c != oldCasesById.get(rec.Id).Send_Clearance_Letter__c)
                && rec.Status == 'Closed'
                && rec.SubStatus__c == 'Release'
                && rec.Send_Clearance_Letter__c == true
                && rec.recordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE){
                    casesClosed.add(rec);
                    relatedContactIds.add(rec.AccountId);
                }
            }
            if(!casesClosed.isEmpty()) {
                Map<Id,Account> relatedAccountsById = new Map<Id,Account>([SELECT Id, PersonEmail FROM Account WHERE PersonEmail = '' AND Id in: relatedContactIds]);
                Group existingCloseContactQueue;
                try{
                    existingCloseContactQueue = [SELECT Id FROM Group Where DeveloperName = 'Existing_Close_Contacts' AND Type = 'Queue' LIMIT 1];
                } catch(QueryException qe) {
                    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The Existing Close Contacts queue is missing. please contact the administrator: ' + qe.getMessage());
                    ApexPages.addMessage(msg);
                }
                if(!relatedAccountsById.isEmpty() && existingCloseContactQueue != null){
                    for (Case rec : casesClosed) {
                        if(relatedAccountsById.containsKey(rec.AccountId)){
                            Task t = new Task(ActivityDate = System.Today(), OwnerId = existingCloseContactQueue.Id, Priority = 'High', Status = 'Not Started', Subject = 'Bulk reject failed - no email provided', whatId = rec.Id);
                            tasksToInsert.add(t);
                        }
                    }
                }
                if(!tasksToInsert.isEmpty()){
                    insert tasksToInsert;
                }
            }
        }
        /**
        * Replaces the "reject/Release close" contact functionality from CaseHandler process builder
        * Entry Criteria: Close Contact type Case on before update if the status is changed to closed and substatus changed to Release
        * so long as the Send_clearance_Email__c is checked and SMS opt out on the account is not checked
        * Output: Update the Cases MessagingTemplate__c to Completed_Close_Contact_Notification
        */
        public static void updateMessagingTemplateOnSMSOptOut(Map<Id, Case> newCasesById, Map<Id,Case> oldCasesById) {
            List<Case> casesClosed = new List<Case>();
            Set<Id> relatedAccountId = new Set<Id>();
            for (Case rec : newCasesById.values()) {
                if((rec.Status != oldCasesById.get(rec.Id).Status || rec.SubStatus__c != oldCasesById.get(rec.Id).SubStatus__c || rec.Send_Clearance_Letter__c != oldCasesById.get(rec.Id).Send_Clearance_Letter__c)
                && rec.Status == 'Closed'
                && rec.SubStatus__c == 'Release'
                && rec.Send_Clearance_Letter__c == true
                && rec.recordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE){
                    casesClosed.add(rec);
                    relatedAccountId.add(rec.AccountId);
                }
            }
            if(!casesClosed.isEmpty()) {
                Map<Id,Account> relatedAccountsById = new Map<Id,Account>([SELECT Id, PersonHasOptedOutOfSMS__c FROM Account WHERE PersonHasOptedOutOfSMS__c = false AND Id in: relatedAccountId]);
                if(!relatedAccountsById.isEmpty()){
                    for (Case rec : casesClosed) {
                        if(relatedAccountsById.containsKey(rec.AccountId)){
                            rec.MessagingTemplate__c = 'Completed_Close_Contact_Notification';
                        }
                    }
                }
            }
        }
    
        /*
        * Replaces the Create Positive Pathway Task process builder
        * Entry Criteria: If clinical care management is Covid Positive Pathway and either:
        * - Care status has changed
        * - Patient has been cleared (changed to Yes)
        * - Review was requested (changed to Yes)
        * Output: Create Pathway Task of Type "Perform Eligibility Assessment"
        */
        public static void createPositivePathwayTask(Map<Id, Case> newCasesById, Map<Id,Case> oldCasesById){
            String pathwayTaskRecTypeId  =
            [SELECT Pathway_Record_Type_Id__c
            FROM DHHS_Default_Ids__mdt
            WHERE DeveloperName = 'Default' LIMIT 1].Pathway_Record_Type_Id__c;
            List<Task> pathwayTaskList = new List<Task>();
            for (Case rec : newCasesById.values())
            {
                // ------------------------------------
                // Entry criteria
                // ------------------------------------
                // Sub-criteria for certain fields - check whether each field has changed
                Boolean careStatusChanged      = rec.Clinical_Care_Status__c != oldCasesById.get(rec.Id).Clinical_Care_Status__c;
                Boolean patientClearedChanged  = rec.Patient_Cleared_by_Authorised_Clinician__c != oldCasesById.get(rec.Id).Patient_Cleared_by_Authorised_Clinician__c;
                Boolean reviewRequestedChanged = rec.DHHS_Review_Requested__c != oldCasesById.get(rec.Id).DHHS_Review_Requested__c;
                if (rec.Clinical_Care_Management__c == 'Covid Positive Pathway'
                && (careStatusChanged
                || (rec.Patient_Cleared_by_Authorised_Clinician__c == 'Yes'
                && patientClearedChanged)
                || (rec.DHHS_Review_Requested__c == 'Yes'
                && reviewRequestedChanged))) {
                    // ------------------------------------
                    // Criteria matches - create pathway task
                    // ------------------------------------
                    Task pathwayTask = new Task();
                    pathwayTask.ActivityDate    = System.today();
                    pathwayTask.Description     = 'Please check the Record History and verify the changes made';
                    pathwayTask.OwnerId         = rec.OwnerId;
                    pathwayTask.Priority        = 'Normal';
                    pathwayTask.RecordTypeId    = pathwayTaskRecTypeId;
                    pathwayTask.Status          = 'Not Started';
                    pathwayTask.Subject         = 'Review of COVID Positive Pathway Record';
                    pathwayTask.Type            = 'Perform Eligibility Assessment';
                    pathwayTask.WhatId          = rec.Id;
                    pathwayTaskList.add(pathwayTask);
                }
            }
            if (!pathwayTaskList.isEmpty()) {
                insert pathwayTaskList;
            }
        }
    
        /*
        * Replaces "New Close Contact Case created" step of "CaseHandler" Process Builder
        * Entry Criteria:
        * - AccountId is provided
        * - Record type is Close Contact
        * - Status is not Identify
        * Output: Creation of work order
        */
        public static void handleNewCloseContactCreation(List<Case> recordList){
            Id closeContactRecordTypeId             = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
            Map<Id, Id> accountIdByCaseIdMap = new Map<Id, Id>();
            for (Case rec : recordList)
            {
                // ------------------------------------
                // Entry criteria
                // ------------------------------------
                if (rec.AccountId != null
                && rec.RecordTypeId == closeContactRecordTypeId
                && rec.Status != 'Identify') {
                    // Criteria matches - store results in intermediary variables which will be used to generate the work orders
                    accountIdByCaseIdMap.put(rec.Id, rec.AccountId);
                }
            }
            if (!accountIdByCaseIdMap.isEmpty()) {
                // ------------------------------------
                // Records with matching criteria found - create Work Orders
                // NOTE: The code below is much simpler than what's present in the Create Close Contact WO flow, which is called
                // by the "New Close Contact Case created" step of "CaseHandler" Process Builder. Reason: unnecessary steps in the flow.
                // The major complexity of the flow is the retrieval of the right queue to assign the new Work Order to.
                // However, other than creating a Work Order, the flow does not actually set the queue ownership. i.e. the flow
                // populates varOwnerId variable which is then never used in creation of the Work Order.
                // On top of that, even if OwnerId was used in the "Create Record" step, it would have no effect since
                // WorkOrderHandler Process Builder runs on creation of the work order and then overrides the ownership anyway.
                // As such, since WorkOrderHandler handles the ownership assignment for the work order, we don't need the ownership logic.
                // ------------------------------------
                // First, get account - contact mapping
                Map<Id, Id> contactIdByAccountIdMap = new Map<Id, Id>();
                List<Account> accountList =
                [SELECT Id, PersonContactId
                FROM Account
                WHERE Id IN :accountIdByCaseIdMap.values()];
                for (Account acc : accountList)
                {
                    contactIdByAccountIdMap.put(acc.Id, acc.PersonContactId);
                }
                // Create work orders
                Id closeContactInterviewRecordTypeId    = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Interview').getRecordTypeId();
                List<WorkOrder> workOrders = new List<WorkOrder>();
                for (Id caseId : accountIdByCaseIdMap.keySet())
                {
                    WorkOrder wo = new WorkOrder();
                    wo.AccountId                    = accountIdByCaseIdMap.get(caseId);
                    wo.CaseId                       = caseId;
                    wo.Case_Interview_Completed__c  = 'Not stated';
                    wo.ContactId                    = contactIdByAccountIdMap.get(accountIdByCaseIdMap.get(caseId));
                    wo.Person_Interviewed__c        = 'Close Contact';
                    wo.Priority                     = 'Low';
                    wo.RecordTypeId                 = closeContactInterviewRecordTypeId;
                    wo.Status                       = 'Not Started';
                    wo.Subject                      = 'Initial Close Contact Interview';
                    workOrders.add(wo);
                }
                if (!workOrders.isEmpty()) {
                    insert workOrders;
                }
            }
        }
    
        //261231: Future method to update surviving master case's field (to capture Case Numbers of all merged cases) when a merge happens
        //Future method used since, can't update the parent case in the same context when merge is happening
        @future
        public static void updateMasterCase(Map<Id, String> mapCaseId_MergedCaseNums) {
            List<Case> listCaseToUpdate = new List<Case>();
            
            for(Id varCaseId : mapCaseId_MergedCaseNums.keySet()) {
                Case masterCase = new Case(Id = varCaseId, Merged_Case_IDs__c = mapCaseId_MergedCaseNums.get(varCaseId));
                listCaseToUpdate.add(masterCase);
            }
            
            if(listCaseToUpdate.size() > 0)
            update listCaseToUpdate;
        }
    
    
    
        /**
        * Replaces the "Sub Status = Escalate" and "Close Contact Escalation" functionality from  DHHS Task Creation process builder
        * Entry Criteria: Case Substatus equals Escalated and Recordtype is either COVID_19_Case_Assessment or Close_Contact. Status will be either Trace or Quarantine
        * Output: A new related Task is created for the case based on the record type.
        */
        public static void createTaskWhenStatusIsEscalated(Map<Id, Case> newCasesById, Map<Id,Case> oldCasesById) {
            List<Case> caseStatusEscalatedRecsToProcess = new List<Case>();
            List<Case> casesToProcess = new List<Case>();
            List<Task> tasksToInsert = new List<Task>();
            Set<Id> selectedCaseId = new Set<Id>(); 
            for (Case rec : newCasesById.values()) {
                if(oldCasesById == null) {
                    casesToProcess.add(rec);
                }else if((rec.Status != oldCasesById.get(rec.Id).Status || rec.SubStatus__c != oldCasesById.get(rec.Id).SubStatus__c || rec.recordtypeId != oldCasesById.get(rec.Id).recordtypeId)){
                    casesToProcess.add(rec);       
                }
            }
            if(!casesToProcess.isEmpty()) {
                for(Case cs:casesToProcess){
                    if(cs.SubStatus__c=='Escalate'){
                        if(cs.RecordTypeId==CASE_COVID_19_ASSESSMENT_RECORD_TYPE && cs.Status=='Trace'){
                            selectedCaseId.add(cs.Id);
                        }else if(cs.RecordTypeId==CASE_CLOSE_CONTACT_RECORD_TYPE && cs.Status=='Quarantine'){
                            selectedCaseId.add(cs.Id);
                        }
                    }
                }
                if(!selectedCaseId.isEmpty()){
                    Escalation_Queue_Id__c eq = Escalation_Queue_Id__c.getOrgDefaults();
                    caseStatusEscalatedRecsToProcess = [SELECT Id,RecordTypeId,Account.PersonContactID 
                    FROM Case
                    WHERE id IN : selectedCaseId];
                    Map<Id, Case>  caseMap = new  Map<Id, Case>();
                    caseMap.putAll(caseStatusEscalatedRecsToProcess);                                        
                    for(Case rec:caseStatusEscalatedRecsToProcess){
                        Task t = new task();
                        t.Priority = 'High';
                        t.Status = 'Not Started';
                        t.whatId = rec.Id;
                        t.WhoId = caseMap.get(rec.Id).Account.PersonContactID;
                        if(rec.RecordTypeId==CASE_COVID_19_ASSESSMENT_RECORD_TYPE){
                            t.Subject='Case Escalated for Non Compliance';
                            t.OwnerId=eq.Confirmed_Case_Escalation_Queue__c;
                        }else if(rec.RecordTypeId==CASE_CLOSE_CONTACT_RECORD_TYPE){
                            t.Subject='Case Escalated for Review';
                            t.OwnerId=eq.Close_Contact_Escalation_Queue__c;
                        }
                        tasksToInsert.add(t);
                    }
                }
                if(!tasksToInsert.isEmpty()){
                    insert tasksToInsert;
                }
            }
        }
    
        public class CaseTriggerHandlerException extends Exception {}
    
        /**
        * Replaces the Criteria "Closed Case Contact Fields", "Event Classification and Event Type", "Send CC & PCC Notification Email" and "Send CC & PCC Notification Letter Task" functionality from  Case_CloseTaskAndWorkorder process builder
        * Entry Criteria: Case Substatus equals Release, Case Status equals Closed and Recordtype is either COVID_19_Case_Assessment or Close_Contact. 
        * Output: Case will be updated , work order and task status will be updated. When record type is Close_Contact - A new related Task is created. When record type is COVID_19_Case_Assessment - A email will be sent to contact Email
        */
        // For bug fixing 288751 - caseCloseTaskStatusUpdate method updating status of case related Task in after update
        public static void caseCloseTaskStatusUpdate(Map<Id, Case> newCasesById, Map<Id,Case> oldCasesById) {
            List<Task> tasksToUpdateFinal = new List<Task>();
            List<Task> tasksToUpdate = new List<Task>();
            List<case> selectedCaseId = new List<case>(); 
            for (Case rec : newCasesById.values()) {
                if(rec.Status != oldCasesById.get(rec.Id).Status || rec.SubStatus__c != oldCasesById.get(rec.Id).SubStatus__c){
                    if(rec.Status=='Closed' && rec.SubStatus__c=='Release'){
                        selectedCaseId.add(rec);
                    }      
                }
            }
            if(!selectedCaseId.isEmpty()) {
                
                tasksToUpdate = [SELECT id,Status, Subject
                                    FROM Task
                                    WHERE WhatId=:selectedCaseId
                                    AND Status!='Completed'
                                    AND (Subject!='Send email as letter' OR Subject != 'Bulk reject failed - no email provided')];
                if(!tasksToUpdate.isEmpty()){
                    for(Task tk:tasksToUpdate){
                        tk.Status = 'Completed';
                        tasksToUpdateFinal.add(tk);
                    }
                } 
            
                
                if(!tasksToUpdateFinal.isEmpty()){
                        if(Trigger.isAfter){
                        update tasksToUpdateFinal;
                        }
                }
            }
            
        }
        public static void caseCloseTaskAndWorkorderProcess(Map<Id, Case> newCasesById, Map<Id,Case> oldCasesById) {
            // List<Case> caseStatusEscalatedRecsToProcess = new List<Case>();
            // List<Task> tasksToUpdateFinal = new List<Task>();
            List<WorkOrder> workOrderUpdateFinal = new List<WorkOrder>();
            // List<Task> tasksToUpdate = new List<Task>();
            List<WorkOrder> workOrderUpdate = new List<WorkOrder>();
            List<Task> tasksToInsert = new List<Task>();
            List<case> selectedCaseId = new List<case>(); 
            Set<Id> relatedContactIds = new Set<Id>();
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            EmailTemplate em = new EmailTemplate();
            em = [SELECT id,name
            FROM EmailTemplate
            WHERE developername='Close_Contact_Letter_of_Clearance'];
            //PBI-293590 ability to send email from orgwide email address
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'covid-19.health@dhhs.vic.gov.au'];
    
            for (Case rec : newCasesById.values()) {
                if(rec.Status != oldCasesById.get(rec.Id).Status || rec.SubStatus__c != oldCasesById.get(rec.Id).SubStatus__c){
                    if(rec.Status=='Closed' && rec.SubStatus__c=='Release'){
                        selectedCaseId.add(rec);
                        relatedContactIds.add(rec.AccountId);
                        rec.Case_Cleared_from_Isolation__c = 'Yes';
                        if(rec.Date_Cleared_from_Isolation__c==null){
                            rec.Date_Cleared_from_Isolation__c = System.now();
                        }
                        //Bug- 279849- Case_Classification__c will be unchanged if Case record type is CASE_COVID_19_ASSESSMENT
                        if(rec.RecordTypeId!=CASE_COVID_19_ASSESSMENT_RECORD_TYPE){
                        rec.Case_Classification__c='Rejected';
                        rec.Event_Type__c='Contact/exposed person';
                        }
                    }      
                }
            }
            if(!selectedCaseId.isEmpty()) {
                /* caseStatusEscalatedRecsToProcess = [SELECT Id,Status,RecordTypeId,Account.PersonContactID,Send_Clearance_Letter__c,ContactId,Contact.HasOptedOutOfEmail,OwnerId,Recordtype.name,contact.name,contact.firstname,contact.lastname
                FROM Case
                WHERE id =:selectedCaseId];*/
                Map<Id,Account> relatedAccountsById = new Map<Id,Account>([SELECT Id, PersonEmail,PersonHasOptedOutOfEmail FROM Account WHERE  Id in: relatedContactIds]);
                
                workOrderUpdate = [SELECT id,Status
                FROM WorkOrder
                WHERE CaseId=:selectedCaseId
                AND Status!='Closed'];
                /*Commented Task update for fixing bug 288751 and implemented in caseCloseTaskStatusUpdate
                tasksToUpdate = [SELECT id,Status, Subject
                FROM Task
                WHERE WhatId=:selectedCaseId
                AND Status!='Completed'
                AND (Subject!='Send email as letter' OR Subject != 'Bulk reject failed - no email provided')];*/
                if(!workOrderUpdate.isEmpty()){
                    for(WorkOrder wo:workOrderUpdate){
                        wo.Status = 'Closed';
                        workOrderUpdateFinal.add(wo);
                    }
                }
            /* Commented Task update for fixing bug 288751 and implemented in caseCloseTaskStatusUpdate
                if(!tasksToUpdate.isEmpty()){
                    for(Task tk:tasksToUpdate){
                        tk.Status = 'Completed';
                        tasksToUpdateFinal.add(tk);
                    }
                } */
                for(Case cs:selectedCaseId){
                    Account acc  =relatedAccountsById.get(cs.AccountId);
                    if(cs.Send_Clearance_Letter__c && (cs.RecordTypeId==CASE_COVID_19_ASSESSMENT_RECORD_TYPE || cs.RecordTypeId==CASE_CLOSE_CONTACT_RECORD_TYPE || cs.RecordTypeId==CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE)){
                        if(acc.PersonHasOptedOutOfEmail){
                            Task t = frameTask(cs, 'Send email as letter', cs.OwnerId);
                            t.Description='Please send the email template: '+cs.Recordtype.name+' - Letter of Clearance  to '+cs.Contact.firstname+' '+cs.Contact.Lastname+'  as a letter.';
                            tasksToInsert.add(t);
                            cs.Has_Clearance_Letter_Been_Sent__c = 'No';
                        }else if(!acc.PersonHasOptedOutOfEmail && em!=null){
                            Messaging.SingleEmailMessage emailCus = frameSingleEmailMessage(cs.Id, cs.ContactId, em.Id, owea.get(0).Id); 
                            mails.add(emailCus);
                            cs.Has_Clearance_Letter_Been_Sent__c = 'Yes';
                        }
                    } 
                }
                
                if(!workOrderUpdateFinal.isEmpty()){
                    update workOrderUpdateFinal;
                }
                if(!tasksToInsert.isEmpty()){
                    insert tasksToInsert;
                }
                    /*Commented Task update for fixing bug 288751 and implemented in caseCloseTaskStatusUpdate
                if(!tasksToUpdateFinal.isEmpty()){
                    update tasksToUpdateFinal;
                }*/
                if(!mails.isEmpty()){
                    Messaging.SendEmailResult[] r = Messaging.sendEmail(mails,false);
                    system.debug('<<r'+r);
                }
            }
            
        }
    
    
        
       /**
        * @description: Updates related tasks to have the parent records owner (PBI281448)
        * @param newCasesList   new records list
        * @param oldCasesMap old records map
        **/
        /*public static void updateRelatedTasks(List<Case> newCasesList, Map<Id,Case> oldCasesMap) {
            Map<Id, Case> filteredCasesMap = new Map<Id, Case>();
            List<Task> tasksToBeUpdated = new List<Task>();
    
            try {
                if (newCasesList != null && !newCasesList.isEmpty()) {
                    for (Case c : newCasesList) {
                        if ((c.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE || c.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE || c.RecordTypeId == CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE) && (c.OwnerId != oldCasesMap.get(c.Id).OwnerId)) {
                            filteredCasesMap.put(c.Id, c);
                        }
                    }
                }
    
                if (!filteredCasesMap.isEmpty()) {
                    for (Task t :[SELECT Id, Status, Manually_Allocated__c, WhatId, OwnerId
                                  FROM Task
                                  WHERE WhatId IN :filteredCasesMap.keySet()
                                  AND Status IN ('Not Started', 'In Progress', 'Escalated', 'Team Lead QA', 'Completed'
                                                 , 'Waiting on someone else', 'Deferred', 'No response', 'Cancelled', 'In QA'
                                                 , 'Pending', 'Rejected', 'No Answer', 'Medical Review', 'Further Interview Required'
                                                 , 'Unsuccessful', 'Left voicemail', 'Request call back')]) {
                        if (!t.Manually_Allocated__c) {
                            if ((t.Status == 'Not Started' || t.Status == 'In Progress' || t.Status == 'Escalated' || t.Status == 'Team Lead QA')) {
                                if (filteredCasesMap.get(t.WhatId).OwnerId != t.OwnerId) {
                                    t.OwnerId = filteredCasesMap.get(t.WhatId).OwnerId;
                                    tasksToBeUpdated.add(t);
                                }
                            }
                        } else {
                            if (t.Status == 'Completed' || t.Status == 'Waiting on someone else' || t.Status == 'Deferred' || t.Status == 'No response' || t.Status == 'Cancelled' || t.Status == 'In QA'
                                || t.Status == 'Pending' || t.Status == 'Rejected' || t.Status == 'No Answer' || t.Status == 'Medical Review' || t.Status == 'Further Interview Required' || t.Status == 'Unsuccessful' || t.Status == 'Left voicemail' || t.Status == 'Request call back' ) {
                                //No change to the owner (yet)
                            }
    
                        }
                    }
                }
    
                if (!tasksToBeUpdated.isEmpty()) update tasksToBeUpdated;
            } catch (Exception e) { System.debug('Error occurred in updateRelatedTasks: ' + e.getStackTraceString()); throw e; }
        }*/
    
    
        private static Messaging.SingleEmailMessage frameSingleEmailMessage(String whatId, String targetObjid, String templateid, String OrgWideEmailAddress){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId(targetObjid);
            email.setTemplateId(templateid);
            email.setWhatId(whatId);
            email.setOrgWideEmailAddressId(OrgWideEmailAddress);
            return email;        
        }
    
        private static Task frameTask(Case cs, String subj, String ownerId){
            Task t = new task();
            t.Priority = 'High';
            t.Status = 'Not Started';
            t.whatId = cs.Id;
            t.Subject = subj;
            t.WhoId = cs.Account.PersonContactID;
            if(ownerId!=null)   t.OwnerId = ownerId;
            t.ActivityDate = System.Today();
            return t;                  
        }
    
        /**
        * Replaces Process the  Builder 'Case - Initial Outbreak Notification'
        * Entry Criteria: Case Substatus equals Release, Case Status equals Closed and Recordtype is either COVID_19_Case_Assessment or Close_Contact. 
        * Output: Case will be updated , work order and task status will be updated. When record type is Close_Contact - A new related Task is created. When record type is COVID_19_Case_Assessment - A email will be sent to contact Email
        */
    
    
        // After Insert
        public static void processOutbreakNotificationsInsert(Map<Id, SObject> objectNewMap) {
            for (SObject currentObject: objectNewMap.values()){
                Case currentCase = (Case)currentObject;
                if(currentCase.RecordTypeId == CASE_OUTBREAK_RECORD_TYPE && currentCase.Site_type__c == 'Outbreak'){
                    String ownerIdString = Id.valueOf(currentCase.OwnerId);
                    if(ownerIdString.startsWith('005')){
                        generateFlow(currentCase.Id, 'Generic');
                    }else if(ownerIdString.startsWith('00G')){
                        generateFlow(currentCase.Id, getDeveloperName(currentCase.OwnerId));
                    }
                }
            }
        }
    
        // After Update
        public static void processOutbreakNotificationsUpdate(Map<Id, SObject> objectNewMap, Map<Id, SObject> objectOldMap){
            for (SObject currentObject: objectNewMap.values()){
                Case currentCase = (Case)currentObject;
                if(currentCase.RecordTypeId == CASE_OUTBREAK_RECORD_TYPE && currentCase.Site_type__c == 'Outbreak'){
                    sObject oldObject = objectOldMap.get(currentCase.Id);
                    Case oldCase = (Case)oldObject;
                    if((currentCase.RecordTypeId != oldCase.RecordTypeId) || (currentCase.Site_Type__c != oldCase.Site_Type__c) || (currentCase.OwnerId != oldCase.OwnerId)){
                        String ownerIdString = Id.valueOf(currentCase.OwnerId);
                        if(ownerIdString.startsWith('005')){
                            generateFlow(currentCase.Id, 'Generic');
                        }else if(ownerIdString.startsWith('00G')){
                            generateFlow(currentCase.Id, getDeveloperName(currentCase.OwnerId));
                        }
                    }
                }
            }
        }
    
        private static void generateFlow(Id caseId, String emailAlert){
            Map<String, Object> params = new Map<String, Object>();
            params.put('CaseId', Id.valueOf(caseId));
            params.put('SelectedEmailAlert', emailAlert);
            System.debug(params);
            Flow.Interview.Send_Outbreak_Email sendOutbreakEmailFlow = new Flow.Interview.Send_Outbreak_Email(Params);
            
            if (!Test.isRunningTest()) sendOutbreakEmailFlow.start();
        }
    
        private static String getDeveloperName(Id ownerId){
            Map<Id, String> ownerDeveloperNameById;
            if(ownerDeveloperNameById == null){
                ownerDeveloperNameById = new Map<Id, String>();
                List<Group> groups = [SELECT Id, DeveloperName FROM Group];
                for(Group currentGroup: groups){
                    ownerDeveloperNameById.put(currentGroup.Id, currentGroup.DeveloperName);
                }
            }
            return ownerDeveloperNameById.get(ownerId);
        }
    
        //PBI 270242 Updating Record Owner on Confirmed Case Should Update the Record Owner on Work Order & Task
        //PBI 270256 Updating Record Owner on Close Contact or Secondary Close Contact Should Update the Record Owner on Work Order & Task
        public static void updateOwnerOnWorkOrderandTask(list<Case> recordList, Map<Id, SObject> objectOldMap){
            // Prevent WorkOrder and Task allocation logic from running
            CASE_TRIGGER_UPDATING_OWNERS = true;
            List<Case> confirmedCase = new List<Case>();
            Map<Id,Id> caseOwnerIdMap = new Map<Id,Id>();
            List<WorkOrder> workOrderListToUpdate = new List<WorkOrder> ();
            List<Task> taskListUpdate = new List<Task>();
    
            for(Case record : recordList){
                sObject oldObject = objectOldMap.get(record.Id);
                Case oldCase = (Case)oldObject;
                
                if((record.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE || record.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE || record.RecordTypeId == CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE) && record.OwnerId != oldCase.ownerId ){
                    confirmedCase.add(record);
                    caseOwnerIdMap.put(record.Id,record.OwnerId);
                }
            }
    
            if(confirmedCase != null && confirmedCase.size()>0){
                List<WorkOrder> workOrderList = [SELECT Id,OwnerId,RecordTypeId, Status, Manually_Allocated__c, CaseId,Record_s_Owner__c
                                                    FROM WorkOrder
                WHERE CaseId IN :confirmedCase
                AND Manually_Allocated__c=FALSE
                AND Status NOT IN ('Closed', 'Completed', 'Canceled')];
    
                for(WorkOrder workorder : workOrderList){
                    if((workorder.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact_Interview').getRecordTypeId() ||
                            workorder.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact_Monitoring').getRecordTypeId() ||
                            workorder.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact_Clearance').getRecordTypeId() ||
                            workorder.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Clearance').getRecordTypeId() ||
                            workorder.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId() ||
                            workorder.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Interview').getRecordTypeId() ||
                            workorder.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Monitoring').getRecordTypeId() ||
                            workorder.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Confirmed_Case_Clearance').getRecordTypeId() ||
                            workorder.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Confirmed_Case_Monitoring_Work_Order').getRecordTypeId() ||
                            workorder.RecordTypeId == Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('HEP_Referral').getRecordTypeId())) {
    
                        if (workorder.ownerId != caseOwnerIdMap.get(workorder.CaseId)) {
                            workorder.ownerId = caseOwnerIdMap.get(workorder.CaseId);
                            workOrderListToUpdate.add(workorder);
                        }
                    
                    /*if((workorder.RecordTypeId == WORKORDER_CONFIRMEDCASE_RECORD_TYPE_ID ||
                            workorder.RecordTypeId == WORKORDER_CONFIRMEDCASE_MONITORING_RECORD_TYPE_ID ||
                            workorder.RecordTypeId == WORKORDER_CONFIRMEDCASE_CLEARANCE_RECORD_TYPE_ID) &&
                            workorder.Manually_Allocated__c == false &&
                            !(workOrderIgnoreStatuses.contains(workorder.Status))) {
    
                            if(workorder.ownerId != caseOwnerIdMap.get(workorder.CaseId)){
                                workorder.ownerId = caseOwnerIdMap.get(workorder.CaseId);
                                workOrderListToUpdate.add(workorder);
                            }
                    }else */ if(workorder.RecordTypeId == WORKORDER_HEP_REFERAL_RECORD_TYPE_ID &&
                            workorder.Status == 'New' &&
                            workorder.Manually_Allocated__c == False){
    
                        if(workorder.ownerId != caseOwnerIdMap.get(workorder.CaseId)){
                            workorder.ownerId = caseOwnerIdMap.get(workorder.CaseId);
                            workOrderListToUpdate.add(workorder);
                        }
                    }
                }
                                } 
                if (workOrderListToUpdate != null && workOrderListToUpdate.size() > 0)
                    update workOrderListToUpdate;
                
                list<Task> taskList = [SELECT RecordTypeId, Id, WhoId, WhatId,Subject, Status, Manually_Allocated__c,OwnerId  FROM Task WHERE WhatId IN :confirmedCase];
                for(Task task : taskList){
                    if(task.RecordTypeId != TASK_COMMUNICATION_RECORD_TYPE_ID && 
                        task.Manually_Allocated__c == false && !(taskOrderIgnoreStatuses.contains(task.Status))){
                            if(task.OwnerId != caseOwnerIdMap.get(task.WhatId)){
                                task.ownerId = caseOwnerIdMap.get(task.WhatId);
                                taskListUpdate.add(task);
                            }
                            
                            
                        }
                }
                
                if(taskListUpdate.size() > 0)
                    update taskListUpdate;
            }
        }
    
        public static void setInitialInterview(List<Case> cases) {
            for (Case c: cases) {
                System.debug('Case initial interview: ' + c.Set_Initial_Interview__c + ' [' + c.Id + ']');
    
                if (c.Set_Initial_Interview__c == 'T') {
                    // PBI 266139 condition 2 & 4:
                    // Check the Initial Interview Completed checkbox, Initial Interview Completed Time will be taken from merge logic
                    c.Initial_Interview_completed__c = true;
                    c.Set_Initial_Interview__c = null;
                } else if (c.Set_Initial_Interview__c == 'F') {
                    // PBI 266139 condition 1 & 3:
                    // Uncheck the Initial Interview Completed checkbox and clear Initial Interview Completed Time
                    c.Initial_Interview_completed__c = false;
                    c.Initial_Interview_completed_time__c = null;
                    c.Set_Initial_Interview__c = null;
                }
            }
        }
    
        //Feature 260477: Close Contact Interview Completed = Checked
        public static void updateInitialInterviewCompleted(Map<Id, Case> newCasesById, Map<Id, Case> oldCasesById) {
            List<Case> casesToUpdate = new List<Case>();
    
            for(Case caseToFilter : newCasesById.values()){
                if(caseToFilter.recordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE
                    && caseToFilter.Day_0_Exposure_to_the_confirmed_case__c != NULL
                    && caseToFilter.Initial_Interview_Completed_Time__c != NULL
                    && caseToFilter.Day_0_Exposure_to_the_confirmed_case__c != oldCasesById.get(caseToFilter.Id).Day_0_Exposure_to_the_confirmed_case__c
                    && caseToFilter.Day_0_Exposure_to_the_confirmed_case__c > caseToFilter.Initial_Interview_Completed_Time__c
                    && caseToFilter.Status != 'Closed'){
    
                    caseToFilter.Initial_Interview_completed__c = FALSE;
                    caseToFilter.Initial_Interview_Completed_Time__c = NULL;
                }
            }
        }
        public static void createCOVIDSafeAndDVRAssessmentTask(List<Case> newCases, Map<Id, Case> mapOldCase) {
            if (newCases != null && !newCases.isEmpty()) {
                Id queueCCU = [SELECT Id FROM Group WHERE Name = 'COVID Coordination Unit' AND Type = 'Queue'].Id;
                List<Task> tasks = new List<Task>();
    
                for (Case c : newCases) {
                    if (mapOldCase.get(c.Id).Case_have_the_COVID_Safe_app__c != 'Yes (Please complete the Close Contacts Sheet)'
                        && c.Case_have_the_COVID_Safe_app__c == 'Yes (Please complete the Close Contacts Sheet)') {
                            Task t = createTask(c.Id , c.ContactId , TASK_NEW_TASK_RECORD_TYPE_ID , null , System.today() , 'COVID safe assessment to be completed' , queueCCU);
                            t.Status = 'Not Started';
                            tasks.add(t);
                        }
    
                    if (mapOldCase.get(c.Id).DVR_assessment_required__c != 'Yes' && c.DVR_assessment_required__c == 'Yes') {
                        Task t = createTask(c.Id , c.ContactId , TASK_NEW_TASK_RECORD_TYPE_ID , null , System.today() , 'DVR Assessment to be completed' , queueCCU);
                        t.Status = 'Not Started';
                        tasks.add(t);
                    }
                }
    
                if(tasks.size() > 0) insert tasks;
            }
    
        }
        /**
        * @description generic method to instantiate a task
        * @param whatId
        * @param whoId
        * @param recordTypeId
        * @param type
        * @param activityDate
        * @param subject
        * @return instantiated task
        **/
        private static Task createTask (Id whatId , Id whoId , Id recordTypeId , String type , Date activityDate , String subject , String OwnerId){
            Task newTask = new Task();
            newTask.WhatId = whatId;
            newTask.WhoId = whoId;
            newTask.recordTypeId = recordTypeId;
            newTask.OwnerId = OwnerId;
            newTask.Type = Type;
            newTask.ActivityDate = activityDate;
            newTask.Subject = Subject;
            System.debug('$$$ new newTask ' + newTask);
            return newTask;
        }
    
    
        /**
        * @description PBI 270142 requires Initial_Interview_completed__c to be reset on the below conditions:
            When a recordType is changed from SCC to PCC ||
            When a recordType is changed from PCC to Confirmed ||
            When a PCC status goes from Closed to Identify AND Day_0_Exposure_to_the_confirmed_case__c has a new value 
        * @param lstCases   Trigger.New cases
        * @param lstCases   Trigger.OldMap cases
        **/
        public static void clearInterviewFields(List<Case> lstCases, Map<Id, Case> mapOldCase) {
            System.debug('$$$ START clearInterviewFields');
            //Added this flag to check the Mergeing Scenario PBI 336537
            Boolean isMerging=dcPluginMerge.isMerging;
            for (Case newCase: lstCases) {
                
                Case oldRecord = mapOldCase.get(newCase.id);
                
                if(
                (   newCase.RecordTypeId != mapOldCase.get(newCase.id).RecordTypeId &&
                    (newCase.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE || newCase.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE ) &&
                    (oldRecord.RecordTypeId == CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE || oldRecord.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE) &&
                    (oldRecord.Initial_Interview_completed__c != true || oldRecord.Initial_Interview_Completed_Time__c != null) &&
                    (!newCase.Status.equalsIgnoreCase(CASE_STATUS_CLOSE)) && !isMerging
                ) ||
    
                (
                newCase.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE &&
                String.isNotBlank(newCase.Status) &&
                String.isNotBlank(oldRecord.Status) &&
                (!newCase.Status.equalsIgnoreCase(CASE_STATUS_CLOSE)) &&
                newCase.Status.equalsIgnoreCase(CASE_SCC_STATUS_IDENTIFY) &&
                oldRecord.Status.equalsIgnoreCase(WO_STATUS_CLOSE) &&
                newCase.Day_0_Exposure_to_the_confirmed_case__c != oldRecord.Day_0_Exposure_to_the_confirmed_case__c &&
                newCase.Day_0_Exposure_to_the_confirmed_case__c != null && !isMerging
                )
                ){
                    System.debug('$$$ clearing Interview Fields');
                    newCase.Initial_Interview_completed__c = false;
                    newCase.Initial_Interview_Completed_Time__c = null;
                }
            }
        }
        /**
        * //PBI 253228 - All interview work orders should be automatically be created when new confirmed case or new primary close contact record is created        
        * Create work order records based on the record type when the case records are created.
        * @param records
        */
        @future
        public static void createInterviewWorkOrders(Set<Id> recordSet) {
            
            List<Case> records=new List<Case>([select Id,RecordtypeId,Status,Priority,AccountID
                                                ,ContactId,Person_Interviewed__c,subject from Case 
                                                where ID IN : recordSet]);
                        
                
            try {
                if(!records.isEmpty()){
                List<WorkOrder> workOrdersToCreate = new List<WorkOrder>();
                for (Case record : records) {
                    /*
                    //when created a new Confirmed Case
                    if (record.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE) {
                        // then create a interview work order
                        workOrdersToCreate.add(
                                new WorkOrder(
                                        AccountId = record.AccountId,
                                        ContactId = record.ContactId,
                                        CaseId = record.Id,
                                        RecordTypeId = WORKORDER_CONFIRMEDCASE_RECORD_TYPE_ID,
                                        Person_Interviewed__c = WO_PERSON_INTERVIEWED_CASE,
                                        Subject = WO_SUBJECT_CONFIRM_CASE_INTERVIEW
                                )
                        );
                    }
                    */
    
                    //created a Secondary Close Contact record either in Identify or Quarantine Status
                    if (record.RecordTypeId == CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE
                            && (CASE_SCC_STATUS_IDENTIFY.equals(record.Status) || CASE_SCC_STATUS_QUARANTINE.equals(record.Status))) { //
                        workOrdersToCreate.add(
                                new WorkOrder(
                                        Status = WO_STATUS_NEW,
                                        Priority = WO_PRIORITY_LOW,
                                        AccountId = record.AccountId,
                                        ContactId = record.ContactId,
                                        CaseId = record.Id,
                                        RecordTypeId = WORKORDER_SCC_INTERVIEW_RECORD_TYPE_ID,
                                        Person_Interviewed__c = WO_PERSON_INTERVIEWED_SSC,
                                        Subject = WO_SUBJECT_SCC_INTERVIEW
                                )
                        );
                    }
                }
    
                if (workOrdersToCreate.isEmpty()) {
                    return;
                }
    
                insert workOrdersToCreate;
                }
            
            } catch (Exception e) {
                //TODO: log any errors here with future error handling framework
                throw new CaseTriggerHandlerException(e);
             }
         }
     
        /**
        * Replaces Process the  Builder 'Suppress SMS Symptoms survey' PBI: 259080
        * Entry Criteria: Confirmed Case updates the case classification to Confirmed and the confirmation date is either blank or in the past. Does not run on insert
        * Output: Update the confirmation date to todays date
        */
         public static void suppressSmsSymptomsSurvey(List<Case> newCases, Map<Id, Case> oldCasesById) {
            Map<Id, Account> accountsByCaseId = new Map<Id,Account>();
            List<Account> accountsToUpdate = new List<Account>();
            Set<Id> PathwayAccountIds = new Set<Id>();
            Set<Id> DhhsManagedAccountIds = new Set<Id>();
            for(Case newCase : newCases) {
                    if(newCase.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE && newCase.AccountId != null) {
                        if(oldCasesById == null){
                                if(newCase.Clinical_Care_Management__c == 'Covid Positive Pathway'){
                                    PathwayAccountIds.add(newCase.AccountId);
                                }
                                else if(newCase.Clinical_Care_Management__c == 'DHHS Managed'){
                                    DhhsManagedAccountIds.add(newCase.AccountId);
                                }
                        }else if(newCase.Clinical_Care_Management__c != oldCasesById.get(newCase.Id).Clinical_Care_Management__c){
                                if(newCase.Clinical_Care_Management__c == 'Covid Positive Pathway'){
                                    PathwayAccountIds.add(newCase.AccountId);
                                }
                                else if(newCase.Clinical_Care_Management__c == 'DHHS Managed'){
                                    DhhsManagedAccountIds.add(newCase.AccountId);
                                }  
                            }
                        }
                        
                    }
         
            if(!PathwayAccountIds.isEmpty()){
                for (Id accid : PathwayAccountIds){
                    accountsToupdate.add(new Account(Id= accid, Reason_For_Exclusion__c = 'Eligible for Positive Pathway')); //  removed as part of  PBI 335716 PersonHasOptedOutOfSMS__c = false
                }
            }
            if(!DhhsManagedAccountIds.isEmpty()){
                for (Id accid : DhhsManagedAccountIds){
                    accountsToupdate.add(new Account(Id= accid, Reason_For_Exclusion__c = null,PersonHasOptedOutOfSMS__c = false));
                }
            }
            
            if(!accountsToupdate.isEmpty()){
                update accountsToUpdate;
            }
         }
     
     
        /**
        * Replaces Process the  Builder 'Auto-populate Confirmation Date' PBI: 277122
        * Entry Criteria: Confirmed Case updates the case classification to Confirmed and the confirmation date is either blank or in the past. Does not run on insert
        * Output: Update the confirmation date to todays date
        */
         public static void populateConfirmationDate(List<Case> newCases, Map<Id, Case> oldCasesById) {
            if(oldCasesById != null) {
                for(Case newCase : newCases) {
                    if(newCase.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE 
                                                && newCase.Case_Classification__c != oldCasesById.get(newCase.Id).Case_Classification__c
                                                && newCase.Case_Classification__c == 'Confirmed'
                                                && newCase.Confirmation_Date__c == null ){
                        newCase.Confirmation_Date__c = System.Now();
                    }
                }
            }
        }
    
        /* When the Confirmation Date is set on a Case Assessment record and Case_Classification__c = 'Confirmed' and there are no other "Address at time of confirmation" entries
         on CPA with Created Date within 60 days from the Confirmation Date,Then the existing Primary/Residential address should be copied onto the CPA object
        as "Address at time of confirmation" type and named as "Confirmation date address"
        */
    
        public static void populateCPARecord(Map<Id, Case> newCasesMap, Map<Id, Case> oldCasesMap ){
            Set<Id> accountIdSet=new Set<Id>();
            Map<Id,Date> accountIdtoConfirmationDateMap=new Map<Id,Date>();
            try{
                for(Case caseRec : newCasesMap.values()){
    
    
                    if(caseRec.Confirmation_Date__c != null && 
                    (oldCasesMap==null ||  (oldCasesMap!=null && caseRec.Confirmation_Date__c != oldCasesMap.get(caseRec.Id).Confirmation_Date__c ) ||
                   (oldCasesMap!=null && caseRec.Case_Classification__c != oldCasesMap.get(caseRec.Id).Case_Classification__c ) ) &&      
                    (caseRec.Case_Classification__c=='Confirmed')         
                   ){
                        //Collect all required cases
                        accountIdSet.add(caseRec.Accountid);
                        DateTime dT = caseRec.Confirmation_Date__c;       
                        accountIdtoConfirmationDateMap.put(caseRec.Accountid, date.newinstance(dT.year(), dT.month(), dT.day()));
                    }
                }
            }
            
    
            catch(Exception e){
                System.debug('Exception occured in CPARecord Creation :' + e.getStackTraceString());
            }
    
            if(accountIdtoConfirmationDateMap!=null){
                createCPARecord(accountIdtoConfirmationDateMap);
            }
        }
    
     
    
        private static void createCPARecord(Map<Id,Date> accountIdtoConfirmationDateMap){
            String CONFIRMATION_ADDRESS = 'Address at time of confirmation';
            String CPANAME='Confirmation date address';
            List<ContactPointAddress> cpaList=new List<ContactPointAddress>();    
            try{ 
            List<Account> accountList= new List<Account>([select ID,PersonMailingCity, PersonMailingCountry, PersonMailingStreet, PersonMailingState, PersonMailingPostalCode ,
                                                        (select Id,name,Address,AddressType,Createddate from ContactPointAddresses 
                                                        where AddressType=:CONFIRMATION_ADDRESS and createdDate = LAST_N_DAYS:60) 
                                                        from Account where Id IN :accountIdtoConfirmationDateMap.keySet()]);    
              
               for(Account accRec : accountList){        
                if(accRec.ContactPointAddresses.IsEmpty()){
                    ContactPointAddress cpaRec = new ContactPointAddress();
                    cpaRec.Name=CPANAME;
                    cpaRec.AddressType=CONFIRMATION_ADDRESS;
                    cpaRec.ParentId=accRec.Id;
                    cpaRec.Street=accRec.PersonMailingStreet;
                    cpaRec.City=accRec.PersonMailingCity;
                    cpaRec.State=accRec.PersonMailingState;
                    cpaRec.PostalCode=accRec.PersonMailingPostalCode;
                    cpaRec.Country=accRec.PersonMailingCountry;
                    cpaRec.ActiveFromDate=accountIdtoConfirmationDateMap.get(accRec.Id);
                    cpaRec.Set_by_Trigger__c=true;             
                    cpaList.add(cpaRec);
                }
           
            }
    
            if(!cpaList.IsEmpty()){
                Database.insert(cpaList);
            }
        }
        catch(Exception e){
            System.debug('Exception occured in CPARecord Creation :' + e.getStackTraceString());
        }
        }
        /* PBI 273382: Create New Workorder for Day 14, when Confirmed Case (Record) is created that is in Trace or Isolate status 
            */
        public static void createConfirmedCaseClearanceWorkOrder(Map<Id, Case> newCasesMap){
            string WO_CONFIRMEDCASECLEARANCE_RECORD_TYPE = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Confirmed_Case_Clearance').getRecordTypeId();
            List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
            for(Case rec : newCasesMap.values()){
                if(rec.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE &&
                ( rec.Status == CASE_STATUS_TRACE ||  rec.Status == CASE_STATUS_ISOLATE ) ){
                    WorkOrder wo = new WorkOrder(
                            AccountId = rec.AccountId,
                            ContactID = rec.ContactId,
                            CaseId = rec.Id,
                            RecordTypeId = WO_CONFIRMEDCASECLEARANCE_RECORD_TYPE,
                            Priority = WO_PRIORITY_LOW,
                            Status = WO_STATUS_NEW,
                            Subject = 'Confirmed Case Clearance',
                            OwnerId = rec.OwnerId 
                        );
                    workOrdersToInsert.add(wo);
                }
            }
            if (!workOrdersToInsert.isEmpty()) {
                try{
                    insert workOrdersToInsert;
                }
                catch(Exception e){
                    System.debug('Exception occured in Work order Creation :' + e.getStackTraceString());
                }
            }
        }
    
        /**
        *  PBI-313212
        *  Criteria - Cases of record type 'Case Assessment' and 'Close Contact' 
        *  set Time and Date of sent initial email when Send Initial notification email is checked.
        */
        public static void stampDateTimeOfSentInitialEmail(List<Case> newCases, Map<Id, Case> oldCasesMap){
            for(case rec : newCases){
                if((rec.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE || rec.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE) && rec.Send_initial_notification_email__c ){
                    if(oldCasesMap == null){ //before insert
                        rec.Time_and_Date_of_sent_initial_email__c = system.now();
                    }
                    else if(oldCasesMap != null){ // before update
                        if(rec.Send_initial_notification_email__c != oldCasesMap.get(rec.Id).Send_initial_notification_email__c && rec.Send_initial_notification_email__c){
                            rec.Time_and_Date_of_sent_initial_email__c = system.now();
                        }
                    }   
                }
            }
        }
    
         /**
        *  PBI-313212
        *  Criteria - Cases of record type 'Close Contact' 
        *  reset interview information if closed case is reopened with in 60 days
        */
        public static void resetInterviewInformation(Map<Id, Case> newCasesMap, Map<Id, Case> oldCasesMap){
            for(case rec : newCasesMap.values()){
                if(rec.RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE && rec.Status != CASE_STATUS_CLOSE 
                   && oldCasesMap.get(rec.Id).Status == CASE_STATUS_CLOSE
                   && rec.Status != oldCasesMap.get(rec.Id).Status){
                       if(rec.ClosedDate != null){
                           Integer numberOfDaysFromClosedDate = (System.Today()).daysBetween(Date.valueOf(rec.ClosedDate));
                            if(numberOfDaysFromClosedDate < 60){
                                rec.Initial_COVID_First_Aid_Contact__c = false;
                                rec.Initial_Interview_completed__c = false;
                                rec.Initial_Interview_Completed_Time__c = null;
                                rec.Send_initial_notification_email__c = false;
                                rec.Time_and_Date_of_sent_initial_email__c = null;
                            } 
                       }
                       
                   }
            }
        }
    
        /**
         * This method is called by Platform events
         * Sends out case email notifications to the queue members when the classification is changed to Confirmed.
         * PBI 309115 : Email Notification To LPHUs/Queue when a Confirmed Case is Auto-allocated from Informatics Queue 
         * */
        public static void sendQueueAssignmentNotificationToMembersAsync(List<Case> newCases, Map<Id, SObject> oldCasesById) {
            List<Case> results = new List<Case>();  
            
            if (newCases != null) {
    
                for(Case c : newCases) {    
                    Case oldCase= (Case)oldCasesById.get(c.Id);    
                    //only when case classification has been changed to confirmed and record type Confirmed record                             
                    if (c.Case_Classification__c == 'Confirmed' && oldCase.Case_Classification__c != 'Confirmed'
                        && c.RecordTypeId==CASE_COVID_19_ASSESSMENT_RECORD_TYPE) {
                            results.add(c);                        
                    }
                }
            }        
            if (results.size()>0)
            {
                (new SendEmailToConfirmedCaseQueue()).sendEmailToCaseQueues(results);
            }       
        }
    
        /**
    * PBI 332422 : OBM - Flagging when a Location is linked to an active Exposure Management record
    * */
        public static void updateLocationCount(List<Case> newCases, Map<Id, Case> oldCasesById){
            List<Case> CaseList = new List<Case> ();
            Set<Id> LocationcsSet = new Set<Id>();
            if ( Trigger.isDelete ) {
                CaseList = oldCasesById.values(); 
            } else {
                CaseList = newCases;  
            }
            for ( Case caseC : CaseList ) {
                
                if ( caseC.LocationAddress__c != null  && caseC.RecordTypeId == CASE_EXPOSURE_RECORD_TYPE_ID ){
                    LocationcsSet.add(caseC.LocationAddress__c);
                }
                
                if ( Trigger.isUpdate ) {
                    Case oldCase = (Case)Trigger.oldMap.get(caseC.Id); // Map<Id, sObject>
                    if ( oldCase.LocationAddress__c != caseC.LocationAddress__c && caseC.RecordTypeId == CASE_EXPOSURE_RECORD_TYPE_ID  ) {
                        LocationcsSet.add(oldCase.LocationAddress__c);
                    }
                }
            }
            
             if(LocationcsSet.size() > 0){
            List<Schema.Location> locationList = [Select Id, Name, Location_linked_to_active_exposure_site__c,(SELECT Id, Status FROM Records__r WHERE RecordType.DeveloperName = 'Outbreak' AND Status != 'Inactive' AND Status != 'Closed')  FROM Location WHERE Id IN : LocationcsSet];
            for( Schema.Location eachLocation : locationList){
                
                eachLocation.Location_linked_to_active_exposure_site__c = eachLocation.Records__r.size();
                
            }
            
            update locationList;
                
            }
        }
        /*PBI 333814 DVR Integration - call platform API to publish DVR Option 1 search to Mystery Case Tracker
     * 
    * Create DVR_Search_Request_Event__e events and publish  
    */
    public static void publishDVRSearchRequestEvents(List<Case> newCases){
        if(!publishDVREvent){
        List<DVR_Search_Request_Event__e> newdvrs = new List<DVR_Search_Request_Event__e>();
        List<Case> casesToUpdate = new List<Case>();
        Map<Id, Id> accountIdByCaseIdMap = new Map<Id, Id>();
        Map<Id, String> accountIdByPhone = new Map<Id, String>(); // to store Account phone
        //Group  existingConfirmedCaseQueue = [SELECT Id FROM Group Where  DeveloperName =: System.Label.PublishDvr_RecordOwner   AND Type = 'Queue' LIMIT 1];
        for(Case accountid:newCases){
            accountIdByCaseIdMap.put(accountid.id,accountid.AccountId);
            
        }
        List<Account> acclist = [select id,phone from Account where id IN:accountIdByCaseIdMap.values()];
        for(Account acc:acclist){
            accountIdByPhone.put(acc.id,acc.Phone);
        }
        // to map DVR_Search_Request_Event__e with case details
        for(Case dvrc:newCases){
            DVR_Search_Request_Event__e dvrs = new DVR_Search_Request_Event__e();
            if(dvrc.AccountId != null){
                if(String.isNotBlank(accountIdByPhone.get(dvrc.AccountId))  && dvrc.RecordTypeId == CASE_COVID_19_ASSESSMENT_RECORD_TYPE && dvrc.Case_Classification__c == 'Confirmed' 
                   && dvrc.Status != System.Label.PublishDvr_Status  && dvrc.Soft_Delete__c == false  && dvrc.Status_update_type__c != System.Label.PublishDvr_DVR_Search 
                  // && dvrc.OwnerId == existingConfirmedCaseQueue.Id && dvrc.MC_Ready__c == true
                  ){
                       dvrs.Phone_Number__c = accountIdByPhone.get(dvrc.AccountId);
                       if(dvrc.Confirmation_Date__c != null){
                          /* String dt1 = (dvrc.Confirmation_Date__c.addDays(-28)).format('yyyy-MM-dd HH:mm:ss', 'Australia/Melbourne');
                           dvrs.Start_Date_Time__c = Datetime.valueOf(dt1);
                           String dt2 = dvrc.Confirmation_Date__c.format('yyyy-MM-dd HH:mm:ss', 'Australia/Melbourne');
                           dvrs.End_Date_Time__c = Datetime.valueOf(dt2); */
                           Datetime cDate = dvrc.Confirmation_Date__c;
                          Integer minutes = integer.valueOf(System.Label.PublishDvr_UTC) ; // Need to update lable to 600 after daylightsavings
                           Datetime utcdt = cDate.addMinutes(minutes);
                           dvrs.Start_Date_Time__c = utcdt.adddays(-28);
                           dvrs.End_Date_Time__c = utcdt;
                           dvrs.Search_Reason__c  = 'Confirmed Case';
                           dvrs.TREVI_Case_ID__c = Integer.valueOf(dvrc.CaseNumber);
                           newdvrs.add(dvrs);
                           Case csearch = new Case(id=dvrc.id);
                           csearch.Status_update_type__c = System.Label.PublishDvr_DVR_Search;
                           casesToUpdate.add(csearch);
                           }
                   }
            }
        }
        System.debug('@@@@@newdvrs'+newdvrs);
        if(casesToUpdate.size()>0){
            try{
                  Database.update(casesToUpdate); 
            }
            catch(Exception e){
                System.debug('Exception occured in updating caserecord :' + e.getStackTraceString());
            }
           
        }
       // to publish dvr search request events
        if(newdvrs.size()>0){
            List<Database.SaveResult> results = EventBus.publish(newdvrs);
            publishDVREvent = True;    // limiting to publish events only once per transaction
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                     System.debug('Successfully published event.'+sr.getId());
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                    }
                    
                }
            }
        }      
    }
    }


     /**
    *   handle Status/SubStatus logic when Record Type is changed from CasC,AC, CS and UC to SCC/PCC and vice versa
    *   10/11/2021 Aref S    : PBI 318055 - Functional fix - Status and blank sub-status when Record Types changed
    */
    public static void handleStatusForSccOrPccRecordType(Map<Id, Case> newCasesById, Map<Id, Case> oldCasesById){
        List<Case> casesToUpdate = new List<Case>();
 
        try {
            for(Case caseToFilter : newCasesById.values()){
               
                //PBI 318055 AC01:Update status/sub-status when a record type is changed
                if(isRecordTypeOtherThenPCCorSCCorCC(caseToFilter.recordTypeId) &&
                        (oldCasesById.get(caseToFilter.Id).RecordTypeId == CASE_CLOSE_CONTACT_RECORD_TYPE || 
                        oldCasesById.get(caseToFilter.Id).RecordTypeId == CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE)){
    
                    if (oldCasesById.get(caseToFilter.Id).Status=='Identify' || oldCasesById.get(caseToFilter.Id).Status=='Quarantine')
                    {
                        caseToFilter.Status='Active';
                    } 
    
                    if (oldCasesById.get(caseToFilter.Id).Status=='Identify' || oldCasesById.get(caseToFilter.Id).Status=='Quarantine' ||
                        oldCasesById.get(caseToFilter.Id).Status=='Closed' || oldCasesById.get(caseToFilter.Id).Status=='Ex-HQ Follow-up' )                    
                    {
                        caseToFilter.SubStatus__c=null;
                    }
                }
    
                //PBI-318055 AC02: When merging a PCC/SCC record with a sub-status of 'In Progress' with a 'contact(CasC,AC,CS,UC)' then the auto de-dupe functionality should not produce an error
                if(isRecordTypeOtherThenPCCorSCCorCC(caseToFilter.recordTypeId))
                {
                    if (caseToFilter.SubStatus__c=='In Progress')
                    {
                        caseToFilter.SubStatus__c=null;
                    }
                }
            }
            
        } catch (Exception exp) {
            ApplicationLogUtility.createlog('CaseTriggerHelper','handleStatusForSccOrPccRecordType',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
        }
        
    }

    private static Boolean isRecordTypeOtherThenPCCorSCCorCC(Id recordTypeId)
    {
        return (recordTypeId == CASE_CASUAL_CONTACT_RECORD_TYPE ||
        recordTypeId == CASE_COVID_19_SCREENING_RECORD_TYPE ||
        recordTypeId == CASE_ACQUISITION_CONTACT_RECORD_TYPE ||
        recordTypeId == CASE_UNCLASSIFIED_CONTACT_RECORD_TYPE);
    }
}
