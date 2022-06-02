/**
 * @Author             : Hemant Singh
 * @Description        : Batch to re-trigger Account address validation for pending addressess
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author              Details
 * ---------------------------------------------------
 * 10/10/2021     Hemant Singh       Initial version
**/

global with sharing class AccountAddressValidationBatch implements Database.Batchable <sObject> {
    
    
    global String DAYS = System.Label.Address_Validation_Batch_Days;
    
    List<String> includeStatus = System.Label.Address_Validation_Batch_Include_Status.split(',');
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        Database.QueryLocator result;
        
        String query = 'SELECT Id, AddressValidationStatus__c, CreatedDate, LastModifiedDate ' +
                'FROM Account WHERE '+
                'AddressValidationStatus__c IN ' +includeStatus+' '+
                'AND CreatedDate < '+ DAYS;
        
         String firstname = '\'FName\'';  // to be used in running test
         String lastname = '\'LName\'';  // to be used in running test
    
        try{
            if(Test.isRunningTest()){
                result =  Database.getQueryLocator('Select Id, FirstName, LastName, AddressValidationStatus__c From Account Where FirstName = \'' + String.escapeSingleQuotes(firstname) + '\' AND LastName = \'' + String.escapeSingleQuotes(lastname) + '\'');
            } else {
                result =  Database.getQueryLocator(query);
            }
        }catch(Exception exp){
            ApplicationLogUtility.createlog('AccountAddressValidationBatch','start',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
        return result;
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope){
       
        List<Account> account = (List<Account>)scope; 
        
        List<Account> accountToUpdate = new List<Account>();
        System.debug('***STARTING AccountAddressValidationBatch at: ' + System.now());
        
        for (Account acc : account) {
            acc.AddressValidationStatus__c = 'Revalidate';
            accountToUpdate.add(acc);
        }
        
        if(accountToUpdate.size() > 0){
            System.debug('accountToUpdate size =  : '+accountToUpdate.size());
            
            try{
                Database.update(accountToUpdate);  //Update Accounts to re-trigger the address validation
            } catch(Exception exp){
                ApplicationLogUtility.createlog('AccountAddressValidationBatch','execute',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
                throw exp;
            } 
        }
    }
        
    global void finish(Database.BatchableContext bc){
        //post processing
    }
}