@isTest
public class ClearDcIndexBatchTest {
    @isTest
    static void ClearDcIndexBatchTest01() {
        try{
            //Creating dc Index record
            dupcheck__dcIndex__c testindexToBeDeleted = new dupcheck__dcIndex__c(
            Name = 'Test',
            dupcheck__objectPrefix__c = '500'
            );
            insert testindexToBeDeleted;
            
                
            Test.startTest();
            
            ClearDcIndexBatch b = new ClearDcIndexBatch();
            database.executebatch(b, 25);
            
            Test.stopTest(); 
            // check if record is deleted?
            List<dupcheck__dcIndex__c> testdcindex =[Select Id, Name, dupcheck__objectPrefix__c From dupcheck__dcIndex__c Where Name = 'Test'];
        }catch(Exception exp){
            ApplicationLogUtility.createlog('ClearDcIndexBatchTest','ClearDcIndexBatchTest01',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
        }
    }
}