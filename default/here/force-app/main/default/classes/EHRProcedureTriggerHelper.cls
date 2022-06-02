/**
 * @Author             : Santosh Bompally
 * @Description        : EHRProcedure trigger Helper
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 05/08/2021     Santosh Bompally       Feature 269587: processes for Rapid Antigen Testing test types
 * 26/08/2021     Xiang Zheng            Bug 315756 : EHR procedure trigger error when ticking data quality check box
**/

public class EHRProcedureTriggerHelper {
    public static final Id CASE_EXPOSURE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Outbreak').getRecordTypeId();
    public static final Id CASE_CASUAL_CONTACT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Casual_Contact').getRecordTypeId();
    public static final Id CASE_CLOSE_CONTACT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
    public static final Id CASE_SECONDARY_CLOSE_CONTACT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
    public static final Id CASE_COVID_19_ASSESSMENT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
    public static final Id CASE_COVID_19_SCREENING_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Screening').getRecordTypeId();
    public static final Id CASE_ACQUISITION_CONTACT_RECORD_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Acquisition_Contact').getRecordTypeId();
    public static final Id TASK_LOG_A_CALL_RECORD_TYPE_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Log_A_Call').getRecordTypeId();
    public static final String EHRO_TASK_SUBJECT = 'Rapid Antigen Screening Call';
    
     public static void createELRTask(List<HealthCloudGA__EHRProcedure__c> lstProcedures, Map<Id, HealthCloudGA__EHRProcedure__c> mapOldProcedures) {
         
        List<Id> CaseIds = New List<Id>();
        User userDetails =[SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id=:userinfo.getUserId()];
		system.debug('Role Name:' + userDetails.UserRole.Name);
        
        //do logic only if role is Informatics/Intel
        if(userDetails.UserRole.Name != 'Informatics/Intel' && !Test.isRunningTest()) return;

        //allowed recordtype Ids set for logic
        Set<Id> recordTypeIdSet = new Set<Id>{	CASE_ACQUISITION_CONTACT_RECORD_TYPE,
     											CASE_CASUAL_CONTACT_RECORD_TYPE, CASE_CLOSE_CONTACT_RECORD_TYPE,
            									CASE_COVID_19_ASSESSMENT_RECORD_TYPE, CASE_COVID_19_SCREENING_RECORD_TYPE};

        //Filter Procedures 
        for(HealthCloudGA__EHRProcedure__c Procedure : lstProcedures){
           if(Procedure.Data_Quality_check_completed__c && !mapOldProcedures.get(Procedure.id).Data_Quality_check_completed__c && Procedure.Record__c != null){
                 CaseIds.add(Procedure.Record__c);
             }
         }
                                                  
        if(CaseIds.size() == 0) return;
        
        //get most recent EHR observation
        List<Case> casesForTaskCreation = new List<Case>();
        
        for(Case thisCase : [SELECT id, ContactId, OwnerId,
                             	(SELECT id,Test_Result__c, Test_Type__c, CreatedDate
                                 FROM Observations__r ORDER BY CreatedDate DESC LIMIT 1) 
                             FROM Case WHERE id IN : CaseIds AND RecordtypeId IN : recordTypeIdSet])
        {
           
           
        	System.debug('$$$ thisCase.Observations__r  ' + thisCase.Observations__r);
           //if test result and test type satisfy criteria add case for task creation 
           if(thisCase.Observations__r != null && !thisCase.Observations__r.isEmpty() && thisCase.Observations__r.get(0).Test_Result__c == Label.OTR_10828004
             	&& thisCase.Observations__r.get(0).Test_Type__c == Label.OTT_PHESS_TEST_5
             )
           {
           		casesForTaskCreation.add(thisCase);
			}
            
        }
        
        
        System.debug('$$$ casesForTaskCreation ' + casesForTaskCreation);
        if(casesForTaskCreation.size() == 0) return;
	    List<Task> TaskstoInsert = New List<Task>();
         
        for (Case newCase : casesForTaskCreation) {
           TaskstoInsert.add( createTask(newCase.Id , newCase.ContactId , TASK_LOG_A_CALL_RECORD_TYPE_ID , 'Call' , System.today() , EHRO_TASK_SUBJECT , newCase.OwnerId)) ;
        }
         if(TaskstoInsert.size()>0){
             insert TaskstoInsert;
         }
         
     }
    
    private static Task createTask (Id whatId , Id whoId , Id recordTypeId , String type , Date activityDate , String subject , Id OwnerId){
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

}