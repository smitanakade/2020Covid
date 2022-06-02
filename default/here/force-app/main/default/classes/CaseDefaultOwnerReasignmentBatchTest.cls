@isTest
public class CaseDefaultOwnerReasignmentBatchTest {
    
    @testSetup
    static void setupTestData() {
        //create accounts
        List<Account> accountList = TestDataFactory.createAccount(10, 'Active','Person Account');

        //create cases
		List<Case> caseListData = TestDataFactory.createCases(accountList.get(0), 10, 'Quarantine', 'Close Contact');
        
        Case caseUpdate = caseListData.get(0);
        caseUpdate.Case_Allocation_Retrigger__c = False;
        caseUpdate.Agency_Name__c = '\'TEST\'';
        update caseUpdate;
            
     
        
    }
    
    @isTest static void CaseDefaultOwnerReasignmentBatchTest01() {
        
        Test.startTest();
        
        CaseDefaultOwnerReasignmentBatch b = new CaseDefaultOwnerReasignmentBatch();
        database.executebatch(b, 25);
        
        Test.stopTest(); 
        
        List<Case> caseToTest =[Select Id, CreatedDate, LastModifiedDate, Case_Allocation_Retrigger__c From Case Where Case_Allocation_Retrigger__c = True AND Agency_Name__c = '\'TEST\''];
        System.assertEquals(caseToTest.size(), 1);
    }

}