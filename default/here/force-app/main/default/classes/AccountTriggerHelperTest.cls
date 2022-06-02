@isTest
public class AccountTriggerHelperTest {
    @isTest
    static void modifyPersonMobileNumberTest(){
     List<Account> accList = new List<Account>();
     Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account account = new Account();
        account.Status__c='Active';
        account.RecordTypeId=recordTypeId;
                account.FirstName = 'Test';
                account.LastName= 'Test1';
                account.PersonMailingStreet='test@yahoo.com';
                account.PersonMailingPostalCode='12345'; 
                account.PersonMailingCity='SFO'; 
                account.PersonEmail='test@yahoo.com'; 
                account.PersonHomePhone='1234567';
                account.Work_Phone__pc=AccountTriggerHelper.remUnwantedNumber('0049999123334');
                account.CreatedDate = system.now();
        		account.PersonMobilePhone= AccountTriggerHelper.remUnwantedNumber('0499991234');
        		accList.add(account);
        		AccountTriggerHelper.modifyPersonMobileNumber(accList);


    }
    @isTest
    static void createSupportOfficerTaskonInsertTest(){
    Set<Id> accountIds=new Set<Id>();
    List<Task> taskList=new List<Task>();
    
    List<Account> accList = TestDataFactory.createAccountNoInsert(1, 'Active','Person Account',null);
        for(Account acc : accList){
            acc.Cultural_Support_Officer_Required__c='Yes';
            
        }

        Test.startTest();
        if(!accList.isEmpty()){
            insert accList;
        }
        for(Account accRec : accList){
            accountIds.add(accRec.Id);
        }
        Test.stopTest(); 
        taskList=[select Id,OwnerId from Task where whatId IN : accountIds and Subject=:Label.Aborginal_Health_Officer_Task_Subject];    
        if(!taskList.isEmpty()){
          
            System.assertEquals(0, taskList.size(), 'Task should not be created');
           
        }
    }

    @isTest
    static void createSupportOfficerTaskonUpdateTest(){
        Set<Id> accountIds=new Set<Id>();
        List<Task> taskList=new List<Task>();
        List<Account> accountList=new List<Account>();
        Test.startTest();
        List<Account> accList = TestDataFactory.createAccount(1, 'Active','Person Account',null);
        List<Case> caseList=TestDataFactory.createCases(accList[0], 1, 'Trace', 'Close Contact');
        accountList =[select Id,Cultural_Support_Officer_Required__c from Account where ID IN :accList ];
        
        Test.stopTest();

      
        for(Account acc : accountList){
            acc.Cultural_Support_Officer_Required__c='Yes';
            accountIds.add(acc.Id);
        }
        if(!accountList.isEmpty()){
            update accountList;
        }
     
       Test.getEventBus().deliver();
        
            taskList=[select Id,OwnerId from Task where  whatId = : caseList[0].Id and Subject=:Label.Aborginal_Health_Officer_Task_Subject];

            System.assertEquals(1, taskList.size(), 'Task created');
            System.assertEquals(AccountTriggerHelper.getQueueID(Label.Aboriginal_Health_Officer_Queue_Name), taskList[0].OwnerId, 'Task assigned to the correct queue');
        
    }
}