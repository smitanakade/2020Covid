/**
 * @Author             : Hemant Singh
 * @Description        : Apex Batch Job to delete de-dup index entries older than N number of days
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 24/11/2021     Hemant Singh          Initial version
 * 
**/


global with sharing class ClearDcIndexBatch implements Database.Batchable <sObject> {
    
    //Number of days is configurable from custom label
    global Integer DAYS = integer.valueOf(System.Label.DC_Index_Cleanup_Days); 
    //Limiting the query to avoid hitting time out (default is 1 million records). Batch chain will take care of next set of records
    global Integer RECORD_LIMIT = integer.valueOf(System.Label.DC_Index_Cleanup_Limit); 
    //Object prefix is configurable from custom label
    global static final String OBJECT_PREFIX = System.Label.DC_Index_Cleanup_Object;

    global Database.QueryLocator start(Database.BatchableContext bc){
              
        String query = 'SELECT Id FROM dupcheck__dcIndex__c WHERE CreatedDate < LAST_N_DAYS:'+ DAYS;
               query  = query+' AND dupcheck__objectPrefix__c = '+ OBJECT_PREFIX;
               query  = query+' LIMIT '+ RECORD_LIMIT;
        
        System.debug('START METHOD DAYS : '+DAYS);
        System.debug('OBJECT PREFIX : '+OBJECT_PREFIX);
        System.debug('LIMIT : '+RECORD_LIMIT);
        
        if(Test.isRunningTest()){
            return Database.getQueryLocator([Select Id, Name, dupcheck__objectPrefix__c From dupcheck__dcIndex__c Where Name = 'Test']);
      } else {        
            return Database.getQueryLocator(query);
                     
        }
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
       
        List<dupcheck__dcIndex__c> indexToBeDeleted = (List<dupcheck__dcIndex__c>)scope; //List of dc index
        System.debug('***STARTING ClearDcIndexBatch at: ' + System.now());
        
        if(indexToBeDeleted.size() > 0){
            System.debug('indexToBeDeleted size =  : '+indexToBeDeleted.size());
            
        try {
             Delete indexToBeDeleted;
             Database.emptyRecycleBin(indexToBeDeleted);  //hard delete
         } catch(Exception exp) {
             ApplicationLogUtility.createlog('ClearDcIndexBatch','execute',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
        } 
    }
            
    }
        
     global void finish(Database.BatchableContext bc){
        List<dupcheck__dcIndex__c> dcIndexRemainingRecords = new List<dupcheck__dcIndex__c>();
        // To check if more records to be deleted
        String RemainingRecords = 'SELECT Id FROM dupcheck__dcIndex__c WHERE CreatedDate < LAST_N_DAYS:'+ DAYS;
                RemainingRecords  = RemainingRecords+' AND dupcheck__objectPrefix__c = '+ OBJECT_PREFIX;
                RemainingRecords  = RemainingRecords+' LIMIT 100';
        
        dcIndexRemainingRecords = Database.query(RemainingRecords);
            
        If (dcIndexRemainingRecords.size() > 0){ //passing remaining records
            System.debug('dcIndexRemainingRecords size =  : '+dcIndexRemainingRecords.size());
            Database.executeBatch(new ClearDcIndexBatch(),200);  //calling same batch again
        }
    }
}