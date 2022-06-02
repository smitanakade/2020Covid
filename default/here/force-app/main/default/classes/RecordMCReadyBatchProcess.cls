/**
* @Author             : Smita kagde
* @Description        : Batch Class
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author             Details
* ---------------------------------------------------
* 18/08/2021     Smita kagde        PBI 312055 : Marketing Cloud - Allowing TREVI records to sync to MC after de-dupe
* 20/09/2021     Sukumar Salla      PBI 322743 : Update to MC Ready logic

**/

public class RecordMCReadyBatchProcess implements Database.Batchable<sObject>{

    public string JobStartTime;
    public List<Case> listOfRecordsToBeProcessed = new List<Case>();

    public RecordMCReadyBatchProcess(string jobStartTime, List<Case> listOfRecords){
        this.JobStartTime = jobStartTime;
        this.listOfRecordsToBeProcessed = listOfRecords;
        system.debug('jobStartTime ==> ' + JobStartTime);
    }

    public List<Case> start(Database.BatchableContext BC){
        system.debug('listOfRecordsToBeProcessed ==> ' + listOfRecordsToBeProcessed.size());
       return listOfRecordsToBeProcessed;
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
    	List<Case> casesMCReady = (List<Case>)scope; //List of cases
        system.debug('casesMCReady ==> ' + casesMCReady.size());
        try{
            for(Case thisCase : casesMCReady ){
                thisCase.MC_Ready__c = true;
            }
            update casesMCReady;
        }
        catch(Exception ex){
            System.debug('***expception  RecordMCReadyBatchProcess :' + ex.getMessage());
             Application_Log__c appLog = new Application_Log__c(Message__c = ex.getMessage(),Stack_Trace__c = ex.getStackTraceString(),Source__c = 'RecordMCReadyBatchProcess',Source_Function__c = 'execute', Transaction_Date__c = System.now());
            insert appLog;
        }
    }
    
    //Any post processing steps here
    public void finish(Database.BatchableContext BC){ 
      
    }
}