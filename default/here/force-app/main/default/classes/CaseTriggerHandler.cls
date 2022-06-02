/**
* @Author             : Darko Jovanovic 
* @Description        : Case trigger handler
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 28/11/2020     Darko Jovanovic       Feature 230036: Duplicate Check tool implementation - Initial version
* 16/12/2020     Henna Mullaji         Feature 229986: Copy PCC dates to SCC via CEP on date changes 
* 10/02/2020     Duncan Bridges        Feature 252130: Refactor "Is Exposure Mgmt Record " step of "CaseHandler" Process Builder
* 12/02/2021     Darko Jovanovic       Hotfix 258342 (Incorporate custom merge rules): Added beforeInsert/Update and defaultAccountIdText methods
* 03/03/2021     Darko Jovanovic       Feature 259086: Refactor "Create positive pathway task" Process Builder - added call to CaseTriggerHelper.createPositivePathwayTask
* 03/03/2021     Darko Jovanovic       Feature 259006: Refactor "New Close Contact Case created" step of "CaseHandler" Process Builder  - added call to CaseTriggerHelper.handleNewCloseContactCreation
* 08/03/2021     Nikhil Verma          Feature 261231: Capture Merged Records' ID (CaseNumber) on surviving master record to make it searchable
* 08/03/2021     Nikhil Verma          Feature 261231: Capture Merged Records' ID (CaseNumber) on surviving master record to make it searchable
* 29/03/2021     Pratyush Chalasani    Hotfix 272728: Refactor merged Case numbers future method to Platform Event
* 29/03/2021     Jiten Joysar          Feature 270253: Case Allocation
* 31/03/2021     Suraj Sood          	Feature 274738: Hotel Quarantine - Automated Work Order
* 06/04/2021     Jiten Joysar          Feature 270252: Case Allocation 
* 07/04/2021     Sai Kallu             Feature 270242/270256: Update Record Owner on Task and Work Order
* 13/04/2021     Pratyush Chalasani    Hotfix 276114: Update Case trigger to capture merged CaseNumber values synchronously
* 05/03/2021     Chris Zhuang          Feature 260477: Close Contact Interview Completed = Checked
* 28/04/2021     Cyrille Jeufo         Feature 269587 : Added createELRTask
* 29/04/2021     Rahul Ankireddypalli  Feature 271921 : case allocation logic in beforeUpdate for record type change from Casual contact to PCC when permit Type = 'Red'
* 10/05/2021     Jiten Joysar          Feature 277160 : Case Allocation 
* 22/06/2021     Suraj Sood            Feature 269587 : Fixed createELRTask method
* 09/07/2021     Sai Kallu      	      Feature 277236: Cross Border Notifications - Identification
* 01/06/2021	 Smita Kagde		   Bug 	288751: PROD - Closing a Record for Clearance creates 'We hit a snag' Error
* 30/06/2021     Rahul Ankireddypalli  Bug 298715 : Need to Re-route the case owner based on permit type for Casual Contact Records
* 01/07/2021     Rahul Ankireddypalli  Feature 299815 : Adding a condition in beforeUpdate of processCaseAllocationRecords() to change the caseowner based on condition
* 27/07/2021     Rahul Ankireddypalli  Bug 306934 : Added status check in processCaseAllocationRecords()
* 29/07/2021     Santosh 			  Feature 307015 : Manual Allocation for Casual Contacts 
* 29/07/2021     Santosh 			  Feature 286007 :Process builder Refactoring 2.0- Case_ChangeToConfirmed
*10/08/2021		 Santosh			  Feature 256028 : Update SCC when PCC is released 	
* 20/09/2021     Pratyush Chalasani   Feature 323048: Shift trigger functions to dcPluginMerge (removed code from here)
* 27/09/2021     Mayukhman Pathak     Feature 273382: Create New Workorder for Day 14 Confirmed Case Clearance
* 29/09/2021     Sukumar Salla        Feature 313212: MC - PCC initial notifications
* 08/10/2021     Xiang Zheng          PBI 326131 :  Fix Confirmed Case Interview Work Order Trigger, add method createInterviewWorkOrdersNew
* 15/10/2021     Aref Samad           PBI 326876 - Case Changed to Confirmed(Refactoring 2.0 - Rework of Sprint 10 PBI)
                                      Enable processConfirmedRecords for Before Insert/Update and Platform event for After Update event  
* 18/10/2021     Hemant Singh         PBI 318284 : Switching off iniial outbreak notification     
* 03/05/2021     Lija Jawahar         PBI 319578 - Removing Release Information on Active Records              
* 10/11/2021     Aref Samad           PBI 318055 - Functional fix - Status and blank sub-status when Record Types changed  
* 12/11/2021     Hemant Singh         PBI 336439 : Re-trigger case allocation rule via the batch job to reassign ownership from Deployment User to right queue  
**/

public class CaseTriggerHandler extends TriggerHandler {
    
    @testVisible
    private static Boolean SkipUpdate = false;
    
    public override void beforeInsert() {
        // Validate Manual allocation for Casual Contacts
        manualallocationvalidation();
        //runs the case allocator.
        filterCaseAllocationRecords();
        // PBI 286007 
        CaseTriggerHelper.processConfirmedRecords(Trigger.new, null);
        CaseTriggerHelper.exposureManagementSetDeclaredDate(Trigger.new);
       //PBI 313974
        //CaseTriggerHelper.updateCaseMilestoneStartDate(Trigger.new);
        CaseTriggerHelper.updateCaseMilestoneStartDate((Map<Id, Case>)Trigger.newMap, null);
        CaseTriggerHelper.updateContactId(Trigger.new, null);
        CaseTriggerHelper.setSubstatus(Trigger.new);
        CaseTriggerHelper.updateForcastDateOnDayZeroChange(Trigger.new, null);
        CaseTriggerHelper.updateClearanceEligibilityDate(Trigger.new);
        CaseTriggerHelper.updateEntitlements(Trigger.new, null);
        CaseTriggerHelper.stampDateTimeOfSentInitialEmail(Trigger.new, null); // PBI-313212
        CaseTriggerHelper.removeReleaseInformationForActiveRecords(Trigger.new, null); //PBI 319578
        defaultAccountIdText();
    }
    
    public override void beforeUpdate() {
        if (SkipUpdate) return;

        // Reset 'Is_case_allocation_completed__c' flag if status is changed
        resetCaseAllocationComepletedFlag();
        // Reset 'Manual_Allocation__c' flag on Casual Contacts if the status is changed
        resetmanualallocation();
        // PBI 286007 
        CaseTriggerHelper.processConfirmedRecords(Trigger.new, (Map<Id, Case>)Trigger.oldMap);
        // Filter case records and run case allocation logic
        processCaseAllocationRecords();
        processCaseAllocationRecordsDeploymentUser();
        defaultAccountIdText();
        CaseTriggerHelper.handleStatusForSccOrPccRecordType((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        caseTriggerHelper.populateConfirmationDate(Trigger.new, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.updateInitialInterviewCompleted((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);           
        CaseTriggerHelper.handleSccToPccRecordTypeChange((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.updateDetailsOnOutbreakChange((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.handleSurveyResponded((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.updateForcastDateOnDayZeroChange(Trigger.new, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.updateClearanceEligibilityDate((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.updateContactId(Trigger.new, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.updateEntitlements(Trigger.new, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.handleSoftDelete((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.updateMessagingTemplateOnSMSOptOut((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.caseCloseTaskAndWorkorderProcess((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.setInitialInterview((List<Case>)Trigger.new);
        CaseTriggerHelper.clearInterviewFields((List<Case>)Trigger.new , (Map<Id, Case>)Trigger.oldMap);
         //PBI 313974
         CaseTriggerHelper.updateCaseMilestoneStartDate((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        //CaseTriggerHelper.updateRelatedTasks((List<Case>)Trigger.new , (Map<Id, Case>)Trigger.oldMap);
        //Feature 277236: Cross Border Notifications - Identification
        CrossBorderNotificationEmail.validateCrossBorderIdentificationFlags((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.stampDateTimeOfSentInitialEmail((List<Case>)Trigger.new , (Map<Id, Case>)Trigger.oldMap); // PBI-313212
        CaseTriggerHelper.resetInterviewInformation((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap); // PBI-313212
        CaseTriggerHelper.removeReleaseInformationForActiveRecords(Trigger.new, null); //PBI 319578
    }
    
    public override void afterInsert() {
        // Standard duplicate check
        dupCheckTrigger();
        //PBI 296818 update Opt out of SMS
        CaseTriggerHelper.suppressSmsSymptomsSurvey(Trigger.new, null);
       
        CaseTriggerHelper.handleNewCloseContactCreation((List<Case>) Trigger.new);
        CaseTriggerHelper.createWorkOrderOnInitialInterview((Map<Id, Case>)Trigger.newMap, null);
        CaseTriggerHelper.createClassificationHistory((Map<Id, Case>) Trigger.newMap, null);
        // Determine whether to insert into queue for Duplicate Check
        DuplicateCheckService.processDuplicateCheckQueue(Trigger.newMap, Trigger.oldMap);
        
        CaseTriggerHelper.createTaskWhenStatusIsEscalated((Map<Id, Case>) Trigger.newMap, null);
        // Send Outbreak Notifications
        // PBI-318284
        //CaseTriggerHelper.processOutbreakNotificationsInsert(Trigger.newMap);
        //PBI 253228 - All interview work orders should be automatically be created when new confirmed case or new primary close contact record is created 
        //PBI 339021 - To avoid exception Calling async process chain from future method. 
        if(!system.isFuture()) 
        CaseTriggerHelper.createInterviewWorkOrders(Trigger.newMap.keySet());
        //Feature 277236: Cross Border Notifications - Identification
        CrossBorderNotificationEmail.validateCrossBorderIdentificationFlagsInsert(Trigger.new);
        //Feature 304111: Address Management - Capture confirmation address  
        CaseTriggerHelper.populateCPARecord((Map<Id, Case>) Trigger.newMap, null);
         //PBI 273382: Create New Workorder for Day 14 Confirmed Case Clearance
         CaseTriggerHelper.createConfirmedCaseClearanceWorkOrder((Map<Id, Case>) Trigger.newMap);
	 //PBI 326131 Fix Confirmed Case Interview Work Order Trigger
         CaseTriggerHelper.createInterviewWorkOrdersNew(Trigger.new, null);
        //PBI 332422 : OBM - Flagging when a Location is linked to an active Exposure Management record
        CaseTriggerHelper.updateLocationCount(Trigger.new, null);
        //PBI 333814 DVR Integration - call platform API to publish DVR Option 1 search to Mystery Case Tracker
      	CaseTriggerHelper.publishDVRSearchRequestEvents(Trigger.new);

        //For asynch tigger handler (should be at the end)
         PETriggerHandlerUtil.publishAsyncEvents('Case', 'insert', Trigger.New, null);
    }
    
    public override void afterUpdate() {
        if (SkipUpdate) return;

        // Standard duplicate check
        dupCheckTrigger();

        // Determine whether to insert into queue for Duplicate Check
        DuplicateCheckService.processDuplicateCheckQueue(Trigger.newMap, Trigger.oldMap);
        // Copy PCC dates to SCC via CEP on date changes 
        System.debug('*****Inside New Method*****');        
        //PBI 296818 update Opt out of SMS
        CaseTriggerHelper.suppressSmsSymptomsSurvey(Trigger.new, (Map<Id, Case>)Trigger.oldMap);
        
        CaseTriggerHelper.copyPccDatesToScc((List<Case>) Trigger.new, (Map<Id, Case>) Trigger.oldMap);
        CaseTriggerHelper.createWorkOrderOnInitialInterview((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.createClassificationHistory((Map<Id, Case>) Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.createPositivePathwayTask((Map<Id, Case>) Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.createPostClearanceTaskNoEmail((Map<Id, Case>) Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.caseCloseTaskStatusUpdate((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.createTaskWhenStatusIsEscalated((Map<Id, Case>) Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        //PBI-274738 Hotel Quarantine - Automated Work Order
        CaseTriggerHelper.createWorkOrderOnHotelQuaratine((Map<Id, Case>)Trigger.newMap, (Map<Id, Case>)Trigger.oldMap);
        
        //PBI 270242,270256 Updating Record Owner on Confirmed Case Should Update the Record Owner on Work Order & Task
        CaseTriggerHelper.updateOwnerOnWorkOrderandTask(Trigger.new, (Map<Id, Case>) Trigger.oldMap);
        // PBI 256028 Update SCC when PCC is released 
        CaseTriggerHelper.updateSCConreleaseofPCC(Trigger.new, (Map<Id, Case>) Trigger.oldMap);
            //Feature 304111: Address Management - Capture confirmation address  
        CaseTriggerHelper.populateCPARecord((Map<Id, Case>) Trigger.newMap, (Map<Id, Case>) Trigger.oldMap);
        // Send Outbreak Notifications
        // PBI-318284
        //CaseTriggerHelper.processOutbreakNotificationsUpdate(Trigger.newMap, Trigger.oldMap);
        CaseTriggerHelper.createCOVIDSafeAndDVRAssessmentTask((List<Case>) Trigger.new, (Map<Id, Case>)Trigger.oldMap);
        CaseTriggerHelper.updatePCCandSCConReleaseofConfirmedCase(Trigger.new, (Map<Id, Case>) Trigger.oldMap);
        CaseTriggerHelper.updateRelatedContactsWithPCCandSCCWhenManuallyUntickTheOngoingExposure(Trigger.new, (Map<Id, Case>) Trigger.oldMap);
        //PBI 326131 Fix Confirmed Case Interview Work Order Trigger
        CaseTriggerHelper.createInterviewWorkOrdersNew(Trigger.new, (Map<Id, Case>) Trigger.oldMap);
        //PBI 332422 : OBM - Flagging when a Location is linked to an active Exposure Management record
        CaseTriggerHelper.updateLocationCount(Trigger.new, (Map<Id, Case>) Trigger.oldMap);
        //PBI 333814 DVR Integration - call platform API to publish DVR Option 1 search to Mystery Case Tracker
      	CaseTriggerHelper.publishDVRSearchRequestEvents(Trigger.new);

        //For asynch trigger handler (should be at the end)
        PETriggerHandlerUtil.publishAsyncEvents('Case', 'update', Trigger.New, Trigger.oldMap);
      
	SkipUpdate = true;
    }

    public override void afterDelete() {
        CaseTriggerHelper.updateLocationCount(null, (Map<Id, Case>) Trigger.oldMap);
    }

    /********************************************************************/
    /* Manual Allocation Validation - One cannot create a casual contact with Manual allocation enabled 
/********************************************************************/
    private static void manualallocationvalidation(){
        for (Case aCase : (List<Case>) Trigger.new){
            if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Casual_Contact' && aCase.Manual_Allocation__c == true){
                aCase.adderror('On creation Manual Allocation must be unticked. Please save the record and edit to manually allocate if required.');
            }
        }
        
    }
	
     /********************************************************************/
    /* Manual Allocation Update  - Manual Allocation should be disabled when 
/********************************************************************/
    private static void resetmanualallocation(){
         Map<Id, Case> oldCaseMap = (Map<Id, Case>)Trigger.oldMap;
        for (Case aCase : (List<Case>) Trigger.new){
            if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Casual_Contact' && aCase.Manual_Allocation__c == true &&
              ((aCase.Status == 'Ex-HQ Follow-up'&& oldCaseMap.get(aCase.Id).Status == 'Active')||(aCase.Status == 'Ex-HQ Follow-up'&& oldCaseMap.get(aCase.Id).Status == 'Closed')||(aCase.Status == 'Active'&& oldCaseMap.get(aCase.Id).Status == 'Closed'))){
               aCase.Manual_Allocation__c = false;
            }
        }
        
    }
    

    /* Case allocation - Function to filter case records which are 
already processed for case allocation logic
/********************************************************************/
    private static void filterCaseAllocationRecords(){
        List<Case> caseAllocationList = new List<Case>();
         List<Case> caseAllocationHQList = new List<Case>();
        List<ID> HQAccountIds = new List<ID>();
        for (Case aCase : (List<Case>) Trigger.new){
            if(!aCase.Is_case_allocation_completed__c && 
                (CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'COVID_19_Case_Assessment' ||
                CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Close_Contact' ||
                CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Casual_Contact' ||
                CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Secondary_Close_Contact')){
               
                 if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName != 'COVID_19_Case_Assessment' && aCase.HQ_Resident__c && aCase.Status == 'Ex-HQ Follow-up' && aCase.AccountId != null){
                        caseAllocationHQList.add(aCase);
                        HQAccountIds.add(aCase.accountId);
                    }else{
                        caseAllocationList.add(aCase);
                        
                    }
            }
        }
        
        if(caseAllocationList != null && caseAllocationList.size() > 0)
            new CaseQueueAllocator(caseAllocationList,getAccountInfo()).run();
        
        if(caseAllocationHQList != null && caseAllocationHQList.size() > 0){
            casetriggerhelper.fetchCaseOwnerforHQResident(caseAllocationHQList,HQAccountIds);
        }
    }
    
    /********************************************************************/
    /* Case allocation - Function to reset 'Is_case_allocation_completed__c' flag
when case status is changed.
/********************************************************************/
    private static void resetCaseAllocationComepletedFlag(){
        Map<Id, Case> oldCaseMap = (Map<Id, Case>)Trigger.oldMap;
        for (Case aCase : (List<Case>) Trigger.new){
            if(aCase.Is_case_allocation_completed__c && aCase.Status != 'Identify' && oldCaseMap.get(aCase.Id).Status == 'Identify' && aCase.Status != oldCaseMap.get(aCase.Id).Status){
                aCase.Is_case_allocation_completed__c = false;
            }
        } 
    }
    /********************************************************************/
    /* Case allocation - Function to filter case records which needs
to under go allocation logic 
/********************************************************************/
    private static void processCaseAllocationRecords(){
        // add conditions to check for PBI - 270253 and call case allocation logic 
        List<Case> caseAllocationList = new List<Case>();
        Map<Id, Case> oldCaseMap = (Map<Id, Case>)Trigger.oldMap;
        Map<Id,Account> relatedAccountInfo = getAccountInfo();
        List<Case> caseAllocationHQList = new List<Case>();
        List<ID> HQAccountIds = new List<ID>();
        //Added to test the issue of case incorrectly assigning to Deployment User (Bug-322389)
        Id DEPLOYMENT_USER_ID = [Select Id From User Where isActive = True AND Name = 'Deployment User' LIMIT 1].Id;
        // Case Record Type = 'Close Contact'  OR Case Record Type = 'Secondary Close Contact'  Status = Identify PersonAccount.Additional_Detail__c contains 'CQ-')
        for (Case aCase : (List<Case>) Trigger.new){
            
            // added filter for case allocation process
            if(!aCase.Is_case_allocation_completed__c && !aCase.Manual_Allocation__c){
                if((CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Close_Contact' || CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Secondary_Close_Contact') && 
                   aCase.Status == 'Identify' && 
                   aCase.Status != oldCaseMap.get(aCase.Id).Status && 
                   relatedAccountInfo.get(aCase.AccountId).Additional_Detail__c != null &&
                   relatedAccountInfo.get(aCase.AccountId).Additional_Detail__c.contains('CQ-')){
                       caseAllocationList.add(aCase);
                   }
                else if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'COVID_19_Case_Assessment' &&
                        aCase.Status == 'Trace' && 
                        aCase.Case_Classification__c == 'Confirmed' && 
						(aCase.Status != oldCaseMap.get(aCase.Id).Status || aCase.Case_Classification__c != oldCaseMap.get(aCase.Id).Case_Classification__c || aCase.OwnerId == DEPLOYMENT_USER_ID)){
                            caseAllocationList.add(aCase);
                        }
                else if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'COVID_19_Case_Assessment' &&
                        aCase.Status == 'Trace' && 
                        aCase.Case_Classification__c != 'Confirmed' && 
						(aCase.Status != oldCaseMap.get(aCase.Id).Status || aCase.Case_Classification__c != oldCaseMap.get(aCase.Id).Case_Classification__c)){
                            caseAllocationList.add(aCase);
                        }
                else if((CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Close_Contact' || CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Secondary_Close_Contact') && 
                        aCase.Status == 'Identify' && 
                        aCase.Status != oldCaseMap.get(aCase.Id).Status ){
                            caseAllocationList.add(aCase);
                        }
                else if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Close_Contact' &&
                        aCase.Status == 'Identify' && 
                        (aCase.Permit_Type__c == 'Red' || aCase.Permit_Type__c == Null )){
                            caseAllocationList.add(aCase);
                        }
                // added new if condition for PBI 277160        
                else if((CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Close_Contact' 
                        || CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Secondary_Close_Contact'
                        || CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Casual_Contact') && 
                        aCase.Status == 'Ex-HQ Follow-up' && aCase.HQ_Resident__c && 
                        aCase.Status != oldCaseMap.get(aCase.Id).Status ){
                          //  caseAllocationList.add(aCase);
                          caseAllocationHQList.add(aCase);
                      	    HQAccountIds.add(aCase.accountId);
                        }  
                        //Added below condition for case allocation process when permit Type is 'Orange' or 'Green' or Null
                        // PBI 271921 : Rahul Ankireddypalli
                        // PBI 306934 : Rahul Ankireddypalli Added condition for status check not equal to Closed
                        else if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Casual_Contact' &&
                                aCase.Status != 'Closed'  &&
                        (aCase.Permit_Type__c == 'Green' || aCase.Permit_Type__c == 'Orange' || aCase.Permit_Type__c == Null)){
                            caseAllocationList.add(aCase);
                        }        
            }
            
        }
        
        if(caseAllocationList != null && caseAllocationList.size() > 0)
            new CaseQueueAllocator(caseAllocationList,getAccountInfo()).run();

         if(caseAllocationHQList != null && caseAllocationHQList.size() > 0){
            casetriggerhelper.fetchCaseOwnerforHQResident(caseAllocationHQList,HQAccountIds);
        }
    }
     /********************************************************************/
    /* //PBI 336439: Case allocation Retrigger - Function to filter case records which needs
to under go allocation logic via the batch job to reassign ownership from Deployment user to right queue (This might be removed once bug-322389 is resolved)
/********************************************************************/
    
    private static void processCaseAllocationRecordsDeploymentuser(){
        
         List<Case> caseAllocationList = new List<Case>();
        Map<Id, Case> oldCaseMap = (Map<Id, Case>)Trigger.oldMap;
        Map<Id,Account> relatedAccountInfo = getAccountInfo();
        List<Case> caseAllocationHQList = new List<Case>();
        List<ID> HQAccountIds = new List<ID>();
        // Case Record Type = 'Close Contact'  OR Case Record Type = 'Secondary Close Contact'  Status = Identify PersonAccount.Additional_Detail__c contains 'CQ-')
        for (Case aCase : (List<Case>) Trigger.new){
            
            // added filter to retrigger case allocation process only when invoked from batch
            if(aCase.Case_Allocation_Retrigger__c){
                if((CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Close_Contact' || CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Secondary_Close_Contact') && 
                   aCase.Status == 'Identify' && 
                   relatedAccountInfo.get(aCase.AccountId).Additional_Detail__c != null &&
                   relatedAccountInfo.get(aCase.AccountId).Additional_Detail__c.contains('CQ-')){
                       aCase.Case_Allocation_Retrigger__c = False;
                       caseAllocationList.add(aCase);
                   }
                else if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'COVID_19_Case_Assessment' &&
                        aCase.Status == 'Trace' && 
                        aCase.Case_Classification__c == 'Confirmed') 
						{    
                            aCase.Case_Allocation_Retrigger__c = False;
                            caseAllocationList.add(aCase);
                        }
                else if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'COVID_19_Case_Assessment' &&
                        aCase.Status == 'Trace' && 
                        aCase.Case_Classification__c != 'Confirmed') 
						{
                            aCase.Case_Allocation_Retrigger__c = False;
                            caseAllocationList.add(aCase);
                        }
                else if((CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Close_Contact' || CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Secondary_Close_Contact') && 
                        aCase.Status == 'Identify'){
                            aCase.Case_Allocation_Retrigger__c = False;
                            caseAllocationList.add(aCase);
                        }
                else if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Close_Contact' &&
                        aCase.Status == 'Identify' && 
                        (aCase.Permit_Type__c == 'Red' || aCase.Permit_Type__c == Null )){
                            aCase.Case_Allocation_Retrigger__c = False;
                            caseAllocationList.add(aCase);
                        }
                // added new if condition for PBI 277160        
                else if((CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Close_Contact' 
                        || CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Secondary_Close_Contact'
                        || CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Casual_Contact') && 
                        aCase.Status == 'Ex-HQ Follow-up' && aCase.HQ_Resident__c){
                          //  caseAllocationList.add(aCase);
                          aCase.Case_Allocation_Retrigger__c = False;
                          caseAllocationHQList.add(aCase);
                      	    HQAccountIds.add(aCase.accountId);
                        }  
                        //Added below condition for case allocation process when permit Type is 'Orange' or 'Green' or Null
                        // PBI 271921 : Rahul Ankireddypalli
                        // PBI 306934 : Rahul Ankireddypalli Added condition for status check not equal to Closed
                        else if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(aCase.RecordTypeId).DeveloperName == 'Casual_Contact' &&
                                aCase.Status != 'Closed'  &&
                        (aCase.Permit_Type__c == 'Green' || aCase.Permit_Type__c == 'Orange' || aCase.Permit_Type__c == Null)){
                            aCase.Case_Allocation_Retrigger__c = False;
                            caseAllocationList.add(aCase);
                        }        
            }
            
        }
        
        if(caseAllocationList != null && caseAllocationList.size() > 0)
            new CaseQueueAllocator(caseAllocationList,getAccountInfo()).run();

         if(caseAllocationHQList != null && caseAllocationHQList.size() > 0){
            casetriggerhelper.fetchCaseOwnerforHQResident(caseAllocationHQList,HQAccountIds);
        }
        
    }
    
    private static void dupCheckTrigger() {
        dupcheck.dc3Trigger triggerTool = new dupcheck.dc3Trigger(trigger.isBefore, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete);
        String errorString = triggerTool.processTrigger(trigger.oldMap, trigger.new); 
        
        if (String.isNotEmpty(errorString)) { trigger.new[0].addError(errorString,false); } 
    }
    
    private static void defaultAccountIdText() {
        for (Case caseRec : (List<Case>) Trigger.new)
        {
            caseRec.AccountIdText__c = caseRec.AccountId;
        }
    }
    private static Map<Id,Account> getAccountInfo(){
        Set<Id> accountIds = new Set<Id>();
        for (Case aCase : (List<Case>) Trigger.new){
            accountIds.add(aCase.AccountId);
        }
        
        Map<Id,Account> accountsByIds =new Map<id,Account> ([SELECT Additional_Detail__c, PersonMailingStreet,Age_Value__pc, PersonMailingPostalCode, PersonOtherPostalCode, PersonMailingAddress,PersonMailingState, Id from Account where Id IN:accountIds ]);
        return accountsByIds;
    }
}