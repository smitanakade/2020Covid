/**
* @Author             : DHHS
* @Description        : Customer Survey Response trigger handler
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author                 Details
* ---------------------------------------------------
* 20/11/2021     Abbas Bagichawala      //PBI XXXXXX - Confirmed Case Interview Survey
**/


public class CSRTriggerHandler extends TriggerHandler{
    
    public override void afterInsert() {
        
        //if(Subject is NOT empty && Contain (SubjectList))
        
        System.debug('CSR TRIGGER Handler >> AFTER Insert CALLED');
        //PBI- XXXXXXX
        system.debug('===='+ Trigger.new);
        CaseInterviewSurveySetting__mdt cisSetting = CaseInterviewSurveySetting__mdt.getInstance('CaseManagementSurvey');
        system.debug('CIS Setting***'+cisSetting);
        
        
        if(cisSetting.ClinicalAssessnmentDetail__c)
            CSRTriggerHelper.createCAR((List<Survey_Response__c>)Trigger.new);
        
        if(cisSetting.AccountDetail__c)    
            CSRTriggerHelper.updateAccount((List<Survey_Response__c>)Trigger.new);    
            
        if(cisSetting.ContactEncounterDetail__c)    
            CSRTriggerHelper.createContactEncounterWSC((List<Survey_Response__c>)Trigger.new);
        if(cisSetting.ContactEncounterDetail__c)    
            CSRTriggerHelper.createContactEncounterTravelHistory((List<Survey_Response__c>)Trigger.new);
        
        if(cisSetting.EhrEncounterDetail__c)    
            CSRTriggerHelper.createHMIP((List<Survey_Response__c>)Trigger.new);
        
        if(cisSetting.EHR_Immunization_Detail__c)    
        	CSRTriggerHelper.createEHRImmunization((List<Survey_Response__c>)Trigger.new);
        
        if(cisSetting.CreateCloseContacts__c){
            if(!system.isFuture() && !system.isBatch() && !system.isQueueable()){
                List<String> srIds = new List<String>();
                for(Survey_Response__c srObj: (List<Survey_Response__c>)Trigger.new){
                    String CSRSubject = srObj.subject__c;
                    if(String.isNotBlank(CSRSubject) && CSRSubject.contains('Close Contact')){
                    	srIds.add(srObj.id);    
                    }
                }
                if(srIds.size()>0)
                	CSRTriggerHelper.createSingleCloseContactPersonAccount(srIds); 
            }
            
        }   
        //CSRHelper.createCloseContactPersonAccount((List<Survey_Response__c>)Trigger.new);
   }    
}