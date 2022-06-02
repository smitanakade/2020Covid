/**
* @Author             : smita kagde
* @Description        : Batch Class
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 18/08/2021     smita kagde        PBI 312055 : Marketing Cloud - Allowing TREVI records to sync to MC after de-dupe
									   Pick up records only after 2 hours, 2 hours is for dupe check and merge
									   Set previous run time in custome setting	
* 20/09/2021     Sukumar Salla      PBI 322743 : Update to MC Ready logic
**/

public class AccountMCReadyBatchProcess implements Database.Batchable<sObject>{
    public String query; 
    public Static String getUTCDateTime(DateTime dt){
        Datetime GMTDate = Datetime.newInstance(dt.year(),dt.month(),dt.day(),dt.hour(),dt.minute(),dt.second());
        String formatted = GMTDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        return formatted;
	}
    public final String JobStartTime= getUTCDateTime(DateTime.now());
    public final List<String> includedStatusForCloseContactCases = new List<String>{'Active', 'Identify', 'Quarantine'};
    public List<Case> listOfCaseRecords = new List<Case>();
    Public set<Id> setAccountIds = new set<Id>();

    public AccountMCReadyBatchProcess(){
        try{
            //get the previous run time from custom setting
            RecordMCReadyLastRun__c previousRun = RecordMCReadyLastRun__c.getInstance();
            String previousRecordRunStr = previousRun.CaseLastRun__c;
            system.debug('previousRun--------------- ' + previousRecordRunStr);
			
            // get all records 
            String caseRecordsQueryString = 'SELECT Id, AccountId, MC_Ready__c FROM Case'; 
            caseRecordsQueryString += ' WHERE MC_Ready__c  = false AND Createddate >= LAST_N_DAYS:60 AND IsDeleted = false AND lastmodifieddate < '+ previousRecordRunStr ;
            caseRecordsQueryString += ' AND RecordType.DeveloperName = \'Close_Contact\' AND Soft_Deleted__c = false AND Status IN: includedStatusForCloseContactCases';
            system.debug('================'+caseRecordsQueryString);
            listOfCaseRecords = Database.Query(caseRecordsQueryString);
            system.debug('listOfCaseRecords ==> ' + listOfCaseRecords.size());

            for(Case c: listOfCaseRecords){
                setAccountIds.add(c.AccountId);
            }

            query = 'SELECT Id, MC_Ready__c ' +
                    'FROM Account WHERE '+
                    'MC_Ready__c = false '+
                    'AND recordtype.Name = \'Person Account\' '+
                    'AND IsDeleted = false ' +
                    'AND Soft_Deleted__c = false ' +
                    'AND lastmodifieddate < '+ previousRecordRunStr;
            
            query += ' AND Id IN: setAccountIds' + (Test.isRunningTest() ? ' LIMIT 25' : ''); 
        }catch(Exception exp){
            ApplicationLogUtility.createlog('AccountMCReadyBatchProcess','AccountMCReadyBatchProcess',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC){      
        return Database.getQueryLocator(query); 
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
    	List<Account> accountsMCReady = (List<Account>)scope; //List of Accounts
        system.debug('size ==> ' + scope.size());
        try{
            // update mcready flag on accounts
            for(Account thisAccount : accountsMCReady ){
                thisAccount.MC_Ready__c = true;  
            }

            update accountsMCReady;
        }catch(Exception exp){
            ApplicationLogUtility.createlog('AccountMCReadyBatchProcess','start',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
    
    //Any post processing steps here
    public void finish(Database.BatchableContext BC){ 
        try{
            RecordMCReadyLastRun__c settingInst = RecordMCReadyLastRun__c.getInstance(UserInfo.getProfileId());
            settingInst.CaseLastRun__c  = JobStartTime;
            system.debug('settingInst ' + settingInst);
            update settingInst;

            //run the case batch after account batch is done
            RecordMCReadyBatchProcess recordbatch = new RecordMCReadyBatchProcess(JobStartTime, listOfCaseRecords);
            Database.executeBatch(recordbatch, 200);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('AccountMCReadyBatchProcess','finish',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}