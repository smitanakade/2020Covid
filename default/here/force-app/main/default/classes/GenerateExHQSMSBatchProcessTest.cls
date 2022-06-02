@isTest
public class GenerateExHQSMSBatchProcessTest {

    @isTest 
    static void testbatch_Day2Scenario(){  
        try{
            // Create Person Account
            List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
            // Create case for the person and then update it
            List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Active', 'Casual Contact');
            caseListExp[0].SubStatus__c = null;
            insert caseListExp;

            caseListExp[0].Subject = 'Test Batch Class ExHQ';
            caseListExp[0].HQ_Resident__c = true;
            caseListExp[0].Status = 'Ex-HQ Follow-up';
            caseListExp[0].Hotel_Quarantine_End_Date__c = Date.today().addDays(-1);
            update caseListExp;
            Test.startTest();
            
            GenerateExHQSMSBatchProcess b = new GenerateExHQSMSBatchProcess();
            database.executebatch(b, 25);
            
            Test.stopTest(); 
            
            //assert for results
            //query case and see if message template Id is updated
            Case testCase = [SELECT Id, MessagingTemplate__c FROM Case WHERE Id =: caseListExp[0].Id];
            System.assertEquals(testCase.MessagingTemplate__c, 'Ex_Hotel_Quarantine_Day_2', 'Ex HQ Days 2 Message should be sent'); 
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateExHQSMSBatchProcessTest','testbatch_Day2Scenario',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
    
    
    @isTest 
    static void testbatch_Day2Scenario_BulkLoad(){  
        try{
            // Create Person Account
            List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
            // Create case for the person and then update it
            List<Case> caseListData = new List<Case>();
            
            caseListData = TestDataFactory.createCasesNoInsert(personAccList.get(0), 25, 'Active', 'Casual Contact');
            for (Case c: caseListData) c.SubStatus__c = null;
            insert caseListData;       
            //update test specific data
            for(Case thisCase : caseListData){
                thisCase.Subject = 'Test Batch Class ExHQ';
                thisCase.HQ_Resident__c = true;
                thisCase.Status = 'Ex-HQ Follow-up';
                thisCase.Hotel_Quarantine_End_Date__c = Date.today().addDays(-1);
            }
                    
            update caseListData;
            
            Map<Id,Case> caseMap = new Map<Id,Case>(caseListData);
            List<Id> caseIds = new List<Id>(caseMap.keySet());
            
            Test.startTest();
            
            GenerateExHQSMSBatchProcess b = new GenerateExHQSMSBatchProcess();
            database.executebatch(b, 25);
            
            Test.stopTest(); 
            
            //assert for results
            //query case and see if message template Id is updated
            List<Case> testCase = [SELECT Id, MessagingTemplate__c FROM Case WHERE Id IN: caseIds AND MessagingTemplate__c = 'Ex_Hotel_Quarantine_Day_2'];
            System.assertEquals(testCase.size(), 25, 'All cases should have MessagingTemplate for: Ex HQ Days 2 Message should be sent'); 
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateExHQSMSBatchProcessTest','testbatch_Day2Scenario_BulkLoad',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
    
    @isTest 
    static void testbatch_Day6Scenario(){  
        try{
            // Create Person Account
            List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
            // Create case for the person and then update it
            List<Case> caseListExp = TestDataFactory.createCasesNoInsert(personAccList.get(0), 1, 'Active', 'Casual Contact');
            caseListExp[0].SubStatus__c = null;
            insert caseListExp[0];
            
            caseListExp[0].Subject = 'Test Batch Class ExHQ';
            caseListExp[0].HQ_Resident__c = true;
            caseListExp[0].Status = 'Ex-HQ Follow-up';
            caseListExp[0].Hotel_Quarantine_End_Date__c = Date.today().addDays(-5);
            update caseListExp;
            Test.startTest();
            
            GenerateExHQSMSBatchProcess b = new GenerateExHQSMSBatchProcess();
            database.executebatch(b, 25);
            
            Test.stopTest();        
            //assert for results
            //query case and see if message template Id is updated
            Case testCase = [SELECT Id, MessagingTemplate__c FROM Case WHERE Id =: caseListExp[0].Id];
            System.assertEquals(testCase.MessagingTemplate__c, 'Ex_Hotel_Quarantine_Day_6', 'Ex HQ Days 6 Message should be sent'); 
        }catch(Exception exp){
            ApplicationLogUtility.createlog('GenerateExHQSMSBatchProcessTest','testbatch_Day6Scenario',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
        
    }
}