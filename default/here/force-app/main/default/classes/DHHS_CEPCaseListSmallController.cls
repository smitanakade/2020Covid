/**
 * @description       : CaseList Small Controller
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0                                  Initial Version
 * 2.0   14-10-2021   Phase 3 team1     Search Cases by record number PBI- 327529
**/
public with sharing class DHHS_CEPCaseListSmallController {
    @AuraEnabled(Cacheable=true)
    public static List <Case> getCases(String accountId, string customSettingDevName) { 
        LWC_Interview_Settings__mdt lwcMetaDataSettings = null;
        try {
            lwcMetaDataSettings = [SELECT AgeOfRecords__c FROM LWC_Interview_Settings__mdt WHERE DeveloperName = :customSettingDevName];
        } catch(Exception exp){
            ApplicationLogUtility.createlog('AdvancedSearchService','Search',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw new AuraHandledException(exp.getMessage());
        }
        
        List<Case> caseList = null;
        try{
            System.debug('***getCases - accountId: '+accountId+ ' AgeOfRecords:'+ lwcMetaDataSettings.AgeOfRecords__c);
            integer days = (integer)lwcMetaDataSettings.AgeOfRecords__c;
            Datetime compareDate = System.today() - days;
            System.debug('***getCases - Searching for cases where Event_Date__c > compareDate: '+compareDate);
            caseList = [SELECT RecordType.Name, CaseNumber, Status, Day_0_Calculated__c, Event_Date__c
                                       FROM Case
                                       WHERE AccountId = :accountId AND Event_Date__c  > :compareDate AND RecordType.Name != 'Exposure Management'
                                       LIMIT 10];
    
            System.debug('***Returning from getCases - caseList: '+caseList);
        } catch(Exception exp){
            ApplicationLogUtility.createlog('DHHS_CEPCaseListSmallController','getCasesbyRecordNumber',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw new AuraHandledException(exp.getMessage());

        }
        
        return caseList;
    }   

    //327529 - include search by recordNumber
    @AuraEnabled(Cacheable=true)
    public static List <Case> getCasesbyRecordNumber(String recordNumber) { 
       
        List<Case> caseList = null;
        try{
            
            caseList = [SELECT RecordType.Name, CaseNumber, Status, Day_0_Calculated__c, Event_Date__c
                                       FROM Case
                                       WHERE Id= :recordNumber  //AND Event_Date__c  > :compareDate AND RecordType.Name != 'Exposure Management'
                                       LIMIT 1];
    
            System.debug('***Returning from  getCasesbyRecordNumber- caseList: '+caseList);
        } catch(Exception exp){
            ApplicationLogUtility.createlog('DHHS_CEPCaseListSmallController','getCasesbyRecordNumber',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            //throw new AuraHandledException(exp.getMessage());

        }
        
        return caseList;
    }   
}