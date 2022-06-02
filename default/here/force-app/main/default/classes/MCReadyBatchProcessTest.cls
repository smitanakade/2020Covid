@isTest
public class MCReadyBatchProcessTest {
    @IsTest
    static void testSchedular() {
        try{
            Test.startTest(); 
            RecordMCReadyLastRun__c previousRun = RecordMCReadyLastRun__c.getInstance(UserInfo.getProfileId());
            previousRun.CaseLastRun__c = AccountMCReadyBatchProcess.getUTCDateTime(DateTime.now());
            previousRun.MCReady_Recordtypes__c = 'Close_Contact';
            insert previousRun;

            String jobId = System.schedule('testScheduledApex', '0 0 9 * * ?', new MCReadyBatchSchedular());
            Test.stopTest();

            // Get the information from the CronTrigger API object
            List<CronTrigger> ct = [
                    SELECT Id, CronExpression, TimesTriggered, NextFireTime
                    FROM CronTrigger WHERE id = :jobId];

            System.assertNotEquals(0, ct.size());
        }catch(Exception exp){
            ApplicationLogUtility.createlog('MCReadyBatchProcessTest','testSchedular',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

      @IsTest
    static void testSchedular2() {
        try{
            Test.startTest(); 
            RecordMCReadyLastRun__c previousRun = RecordMCReadyLastRun__c.getInstance(UserInfo.getProfileId());
            previousRun.ConfirmedCaseLastRun__c = ConfirmedCasesMCReadyBatchProcess.getUTCDateTime(DateTime.now());
            previousRun.MCReady_Recordtypes__c = 'COVID_19_Case_Assessment';
            insert previousRun;

            String jobId = System.schedule('testScheduledApex', '0 0 9 * * ?', new ConfirmedCaseMCReadyBatchScheduler());
            Test.stopTest();

            // Get the information from the CronTrigger API object
            List<CronTrigger> ct = [
                    SELECT Id, CronExpression, TimesTriggered, NextFireTime
                    FROM CronTrigger WHERE id = :jobId];

            System.assertNotEquals(0, ct.size());
        }catch(Exception exp){
            ApplicationLogUtility.createlog('MCReadyBatchProcessTest','testSchedular2',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
    
    @IsTest
    static void testBatches() { 
        try{
            Test.startTest();
            
            //create custom setting
            RecordMCReadyLastRun__c previousRun = RecordMCReadyLastRun__c.getInstance(UserInfo.getProfileId());
            previousRun.CaseLastRun__c = AccountMCReadyBatchProcess.getUTCDateTime((DateTime.now().addDays(2)));
            
            previousRun.MCReady_Recordtypes__c = 'Close_Contact';
            insert previousRun;
            
            //create accounts
            List<Account> accountList = TestDataFactory.createAccount(10, 'Active','Person Account');

            //create cases
            List<Case> caseListData = TestDataFactory.createCases(accountList.get(0), 10, 'Quarantine', 'Close Contact');
            
            Database.executeBatch(new AccountMCReadyBatchProcess(),200);
            Test.stopTest();

            // get data to assert
            for(Account thisAccount : [SELECT Id, MC_Ready__c FROM Account WHERE Id =: accountList[0].Id]){
                system.assertEquals(thisAccount.MC_Ready__c, true, 'MC Ready should be set to true');
            } 

            for(Case thisCase : [SELECT Id, MC_Ready__c FROM Case WHERE Id In : caseListData]){
                system.assertEquals(thisCase.MC_Ready__c, true, 'MC Ready should be set to true');
            } 
        }catch(Exception exp){
            ApplicationLogUtility.createlog('MCReadyBatchProcessTest','testBatches',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

     @IsTest
    static void testBatches_confirmedcases() {
        try{
            Test.startTest();
            
            //create custom setting
            RecordMCReadyLastRun__c previousRun = RecordMCReadyLastRun__c.getInstance(UserInfo.getProfileId());
            previousRun.ConfirmedCaseLastRun__c = ConfirmedCasesMCReadyBatchProcess.getUTCDateTime((DateTime.now().addDays(2)));
            
            previousRun.MCReady_Recordtypes__c = 'Close_Contact';
            insert previousRun;
            
            //create accounts
            List<Account> accountList = TestDataFactory.createAccount(10, 'Active','Person Account');

            //create cases
            List<Case> caseListData = TestDataFactory.createCases(accountList.get(0), 10, 'Quarantine', 'COVID-19 Case Assessment');
            caseListData[0].Case_Classification__c = 'Confirmed';
            update caseListData;
            
            Database.executeBatch(new ConfirmedCasesMCReadyBatchProcess(),200);
            Test.stopTest();

            // get data to assert
            for(Account thisAccount : [SELECT Id, MC_Ready__c FROM Account WHERE Id =: accountList[0].Id]){
                system.assertEquals(thisAccount.MC_Ready__c, true, 'MC Ready should be set to true');
            } 

            for(Case thisCase : [SELECT Id, MC_Ready__c FROM Case WHERE Id =: caseListData[0].Id]){
                system.assertEquals(thisCase.MC_Ready__c, true, 'MC Ready should be set to true');
            } 
        }catch(Exception exp){
            ApplicationLogUtility.createlog('MCReadyBatchProcessTest','testBatches_confirmedcases',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }  
}