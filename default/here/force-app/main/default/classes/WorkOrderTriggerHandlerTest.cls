@isTest
public class WorkOrderTriggerHandlerTest {
    @testSetup 
    static void setupTestData() {
        Id accountRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        Id secondaryCloseContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
        Id interviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
        Id cepCloseConRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();        

        User aUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = [SELECT ID FROM Profile WHERE Name = 'Health Worker' LIMIT 1].Id, 
        TimeZoneSidKey='Australia/Sydney', UserName='standarduser@testorg.com.test');
        insert aUser;

        system.runAs(aUser) {
        Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='Test1 FName', LastName='Test1 LName',PersonMailingStreet='101 Collins Street',
                         PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test11112@gmail.com', PersonHomePhone='1234567',PersonMobilePhone='+614444');
        insert accountRecord;
        
        Id contactId = [Select PersonContactId from Account where Id=:accountRecord.Id][0].PersonContactId;

        Case closeContact = new Case(recordTypeId=closeContactRecordTypeId ,Status='Identify',Subject='Test closeContact',
                             AccountId=accountRecord.Id, ContactId = contactId);
        //Case closeContact = new Case(recordTypeId=closeContactRecordTypeId ,Status='Identify',AccountId=accountRecord.Id);
        insert closeContact;
        
        Case secondaryCloseContact = new Case(recordTypeId=secondaryCloseContactRecordTypeId ,Status='Identify',Subject='Test secondaryCloseContact',
                             AccountId=accountRecord.Id, ContactId = contactId);
        insert secondaryCloseContact;
        
        ContactEncounter ceRecord = new ContactEncounter(RecordTypeId=cepCloseConRecordTypeId, Name='Private residence – home', StartTime=System.Now(), Record__c=closeContact.Id ); 
        insert ceRecord;
        
        ContactEncounterParticipant cepRecord = new ContactEncounterParticipant(Record__c=secondaryCloseContact.Id , Parent_Record__c=closeContact.Id, 
                                         ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        insert cepRecord;
                
        WorkOrder closeContactWorkOrder = new WorkOrder(recordTypeId=interviewWORecordTypeId, Status='In Progress', Subject='Test closeContactWorkOrder',
                             AccountId=accountRecord.Id, CaseId = closeContact.Id);
        
        insert closeContactWorkOrder;
        }
    }
    
    @isTest()
    static void testCase1()    
    {
        Id interviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
        List<WorkOrder> closeContactWorkOrder = [Select Id, Status from WorkOrder Where Subject='Test closeContactWorkOrder' Limit 1];
        if(closeContactWorkOrder.size() > 0)
        {
            closeContactWorkOrder[0].status = 'Completed';
            closeContactWorkOrder[0].RecordTypeId = interviewWORecordTypeId;

            try{
                test.startTest();
                update closeContactWorkOrder;
                test.stopTest();
                }
             
            catch(Exception e)
                {
                    System.debug('Exception occured : '+e.getMessage());

                }
                
                //Case secondaryCloseContact = [Select Id, Status from Case where Subject = 'Test secondaryCloseContact'];
                //Assert

        }

    }
    @isTest()
    static void test_handleCloseContactInterview() {
        Id closeContacInterviewRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Close_Contact_Interview').getRecordTypeId();

    

        List<WorkOrder> closeContactWorkOrder = [Select Id, Status, RecordTypeId, Subject from WorkOrder Limit 1];
        if (closeContactWorkOrder.size() > 0)
        {
        closeContactWorkOrder[0].status = 'Completed';
        closeContactWorkOrder[0].RecordTypeId = closeContacInterviewRecordTypeId;
        closeContactWorkOrder[0].Subject = 'Initial close contact interview';

        User userForTesting = [SELECT Id FROM User WHERE Email = 'standarduser@testorg.com' LIMIT 1];
        system.runAs(userForTesting)  {
            test.startTest();
           
            update closeContactWorkOrder;
            test.stopTest();
        }
        
        //Assert
        List<WorkOrder> inProgressWorkOrder = [Select Id, Status, RecordTypeId, Subject from WorkOrder Where Subject = 'Close contact monitoring' and Status = 'In Progress'];
        system.assertEquals(1, inProgressWorkOrder.size());
        }
        
    } 

    @isTest()
    static void test_handleCloseContactInterviewBulk() {
	
		List<WorkOrder> workOrderList=new List<WorkOrder>();
		List<WorkOrder> workOrderUpdateList=new List<WorkOrder>();
        Account accountRecord = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];
        Case caseRecord=TestDataFactory.createCases(accountRecord, 1, 'Trace', 'Close Contact')[0];
		User userForTesting = [SELECT Id FROM User WHERE Email = 'standarduser@testorg.com' LIMIT 1];
        system.runAs(userForTesting)  {
		workOrderList=TestDataFactory.createWorkOrdersNoInsert(accountRecord, caseRecord,10, 'In Progress', 'Close_Contact_Interview','Initial close contact interview');
		insert workOrderList;
        
		for(WorkOrder workOrderRec : workOrderList){
		workOrderRec.Status='Completed';
		workOrderUpdateList.add(workOrderRec);
		}
		 test.startTest();
       
            update workOrderUpdateList;
         test.stopTest();
		
		}
        
        //Assert
         
        Case caseList=[select Id,Initial_Interview_completed__c from Case where ID =:caseRecord.Id];
        system.assertEquals(TRUE, caseList.Initial_Interview_completed__c);

    } 
}
