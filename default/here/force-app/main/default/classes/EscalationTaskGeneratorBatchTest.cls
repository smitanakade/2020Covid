/**
 * Created by marcelo.cost on 17/12/20.
 */

@IsTest
private class EscalationTaskGeneratorBatchTest {
    @IsTest
    static void testOldCases() {
        try{
            List<Account> personAccounts = TestDataFactory.createAccount(2,'Active','Person Account');
            List<Case> caseListClose = TestDataFactory.createCases(personAccounts.get(0), 5, 'Isolate', 'Close Contact');
            caseListClose.get(0).Last_Check_in_Date__c = Datetime.now().addDays(-3);
            update caseListClose;
            List<Task> tasks = [Select Id from Task];
            System.assertEquals(tasks.size(),0);
            Test.startTest();
            Database.executeBatch(new EscalationTaskGeneratorBatch(), 200);
            Test.stopTest();
            tasks = [Select Id from Task];
            System.assertEquals(tasks.size(),1);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('EscalationTaskGeneratorBatchTest','testOldCases',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}