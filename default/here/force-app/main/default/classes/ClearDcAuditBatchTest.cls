@isTest
public class ClearDcAuditBatchTest {
    @isTest
    static void ClearDcAuditBatchTest01() {
        
        //Creating dc audit record
        dupcheck__dcAudit__c testauditToBeDeleted = new dupcheck__dcAudit__c(
        dupcheck__TypeString__c = '\'Test\'',
        dupcheck__Prefix__c = '500',
        dupcheck__Order__c = 0,
        dupcheck__AuditDate__c = Date.Today()
            );
        insert testauditToBeDeleted;
        
            
        Test.startTest();
        
        ClearDcAuditBatch b = new ClearDcAuditBatch();
        database.executebatch(b, 25);
        
        Test.stopTest(); 
        // check if record is deleted?
        List<dupcheck__dcAudit__c> testdcaudit =[Select Id, dupcheck__TypeString__c, dupcheck__AuditDate__c From dupcheck__dcAudit__c Where dupcheck__AuditDate__c = Today AND dupcheck__TypeString__c = '\'Test\''];
        System.assertEquals(testdcaudit.size(), 0);
    }

}