/**
 * @Author             : Hemant Singh
 * @Description        : Apex Batch Job to delete de-dup audit log entries older than N number of days
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 16/08/2021     Hemant Singh          Initial version
 * 8/10/2021      Chaining batch and adding N number of days and query limit through label
 * 
**/

global with sharing class ClearDcAuditBatch implements Database.Batchable <sObject> {
    
    global Integer DAYS = integer.valueOf(System.Label.DC_Audit_Cleanup_Days);
    global Integer RECORD_LIMIT = integer.valueOf(System.Label.DC_Audit_Cleanup_Limit);
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        
        String query = 'SELECT Id ' +
                'FROM dupcheck__dcAudit__c WHERE '+
                'CreatedDate < LAST_N_DAYS:'+ DAYS;
        
                query  = query+' LIMIT '+ RECORD_LIMIT;
        
        System.debug('START METHOD DAYS : '+DAYS);
        System.debug('LIMIT : '+RECORD_LIMIT);
        
        String s = '\'Test\'';  // to be used in running test
        
        if(Test.isRunningTest()){
            return Database.getQueryLocator('SELECT Id, dupcheck__TypeString__c FROM dupcheck__dcAudit__c Where dupcheck__TypeString__c = \'' + String.escapeSingleQuotes(s) + '\'');
      } else {        
            return Database.getQueryLocator(query);
          
        }
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
       
        List<dupcheck__dcAudit__c> auditToBeDeleted = (List<dupcheck__dcAudit__c>)scope; //List of audit logs
        System.debug('***STARTING ClearDuplicateCheckdcAuditBatch at: ' + System.now());
        
        if(auditToBeDeleted.size() > 0){
            System.debug('auditToBeDeleted size =  : '+auditToBeDeleted.size());
            
        try {
             Delete auditToBeDeleted;
             Database.emptyRecycleBin(auditToBeDeleted);  //hard delete
         } catch(Exception ex) {
             System.Debug('The following exception has occurred: ' + ex.getMessage());
        } 
    }
            
    }
    
    
     global void finish(Database.BatchableContext bc){
         
         List<dupcheck__dcAudit__c> dcauditRemainingRecords = new List<dupcheck__dcAudit__c>();
         // To check if more records to be deleted
         String RemainingRecords = 'SELECT Id ' +
                'FROM dupcheck__dcAudit__c WHERE '+
                'CreatedDate < LAST_N_DAYS:'+ DAYS;
                
          RemainingRecords  = RemainingRecords+' LIMIT 100';
        
         dcauditRemainingRecords = Database.query(RemainingRecords);
         System.debug('FINISH METHOD DAYS : '+DAYS);
         
         If (dcauditRemainingRecords.size() > 0){ //passing remaining records
             System.debug('dcauditRemainingRecords size =  : '+dcauditRemainingRecords.size());
             Database.executeBatch(new ClearDcAuditBatch(),200);  //calling same batch again
         }
         
    }


}