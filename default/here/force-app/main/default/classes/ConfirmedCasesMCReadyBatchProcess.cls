/**
* @Author             : Smita kagde
* @Description        : Batch Class
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 22/09/2021    Sukumar Salla      	   PBI 322743

**/

public class ConfirmedCasesMCReadyBatchProcess implements Database.Batchable<sObject>{

    public String query; 
    public Static String getUTCDateTime(DateTime dt){
        Datetime GMTDate = Datetime.newInstance(dt.year(),dt.month(),dt.day(),dt.hour(),dt.minute(),dt.second());
        String formatted = GMTDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        return formatted;
	}
    public final String JobStartTime= getUTCDateTime(DateTime.now());
    public final List<String> excludedStatusForConfirmedCases = new List<String>{'Closed', 'Ex-HQ Follow-up'};
    public List<Case> listOfCaseRecords = new List<Case>();
    public set<Id> setAccountIds = new set<Id>();

    public ConfirmedCasesMCReadyBatchProcess(){

		//get the previous run time from custom setting
        RecordMCReadyLastRun__c previousRun = RecordMCReadyLastRun__c.getInstance();
        String previousRecordRunStr = previousRun.ConfirmedCaseLastRun__c;

        // get all records 
        String caseRecordsQueryString = 'SELECT Id, AccountId, MC_Ready__c FROM Case'; 
        caseRecordsQueryString += ' WHERE MC_Ready__c  = false AND Createddate >= LAST_N_DAYS:60 AND IsDeleted = false AND createddate < '+ previousRecordRunStr ;
        caseRecordsQueryString += ' AND RecordType.DeveloperName = \'COVID_19_Case_Assessment\' AND Case_Classification__c = \'Confirmed\' AND Soft_Deleted__c = false AND Status NOT IN: excludedStatusForConfirmedCases';
        
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
                'AND createddate < '+ previousRecordRunStr;
        
        query += ' AND Id IN: setAccountIds' + (Test.isRunningTest() ? ' LIMIT 25' : ''); 
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
        }
        catch(exception ex){
            System.debug('***expception  AccountMCReadyBatchProcess :' + ex.getMessage());
            Application_Log__c appLog = new Application_Log__c(Message__c = ex.getMessage(),Stack_Trace__c = ex.getStackTraceString(),Source__c = 'AccountMCReadyBatchProcess',Source_Function__c = 'execute', Transaction_Date__c = System.now());
            insert appLog;
        }
    }
    
    //Any post processing steps here
    public void finish(Database.BatchableContext BC){ 
         
        RecordMCReadyLastRun__c settingInst = RecordMCReadyLastRun__c.getInstance(UserInfo.getProfileId());
        settingInst.ConfirmedCaseLastRun__c  = JobStartTime;
        system.debug('settingInst ' + settingInst);
        update settingInst;
        
        //run the case batch after account batch is done
        RecordMCReadyBatchProcess recordbatch = new RecordMCReadyBatchProcess(JobStartTime, listOfCaseRecords);
		Database.executeBatch(recordbatch, 200);
    }
}