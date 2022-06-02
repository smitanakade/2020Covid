@isTest
public class AccountMCReadyBatchProcessTest {
    @testSetup 
    static void setupTestData() {
        try{
            RecordMCReadyLastRun__c previousRun = RecordMCReadyLastRun__c.getInstance(UserInfo.getProfileId());
            previousRun.CaseLastRun__c = '2022-12-02T06:42:14.000+0000';
            previousRun.MCReady_Recordtypes__c = 'Close_Contact';
            insert previousRun;
            
            Id closeContactClearanceRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
            //Create Person Accounts
            //reduce this to 10 as we will reach apex limiataion if we create 50 records
            List<Account> personAccList = TestDataFactory.createAccount(10, 'Active','Person Account');

            //Create Parent Case
            Case parentCase = new Case(recordTypeId=closeContactClearanceRecordTypeId, 
                                       Status='Identify', 
                                       Subject='Test Parent Case', 
                                       AccountId=personAccList[0].Id, 
                                       Date_Cleared_from_Isolation__c=System.now(),
                                       MC_Ready__c = false,
                                       Soft_Deleted__c = false);
            insert parentCase;
            
            Datetime yesterday = Datetime.now().addDays(-1);
        	Test.setCreatedDate(parentCase.Id, yesterday);  
        }catch(Exception exp){
            ApplicationLogUtility.createlog('AccountMCReadyBatchProcessTest','setupTestData',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    @IsTest
    static void AccountMCReadyBatchProcessTest01() {
        try{
               Test.startTest();
               
               AccountMCReadyBatchProcess b = new AccountMCReadyBatchProcess();
               database.executebatch(b, 25);
               
               Test.stopTest(); 

       }catch(Exception exp){
           ApplicationLogUtility.createlog('AccountMCReadyBatchProcessTest','AccountMCReadyBatchProcessTest01',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
           throw exp;
       }
    }
}