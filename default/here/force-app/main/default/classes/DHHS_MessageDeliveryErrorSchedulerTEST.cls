/*
* Name: DHHS_MessageDeliveryErrorSchedulerTEST
* Developer: Calvin Noronha
* Created Date: Sept 26
* Purpose: Test class for DHHS_MessageDeliveryErrorScheduler
* 
* 
*/
@isTest
public class DHHS_MessageDeliveryErrorSchedulerTEST {
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    @TestSetup
    static void setup()
    {
        string ERROR_STR = 'Error';
        String caseConfirmedRecordTypeID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        String caseCloseContactRecordTypeID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
        String AccountPARecordTypeID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
              
        //COVID-19 Case Assessment
        //Create Account
        Account acc = new Account(LastName='Test',FirstName='Account');
        acc.RecordTypeId = AccountPARecordTypeID;
        insert acc;
        
        TestDataFactory.createQAllocationForCaseRecordType();
        TestDataFactory.createQAllocationForWorkOrderRecordType();
        //Insert Case
        Case caseRec = new Case(Status='Quarantine');
        caseRec.RecordTypeId = caseConfirmedRecordTypeID;
        caseRec.AccountId = acc.id;
        caseRec.SubStatus__c = 'In Progress';
        insert caseRec;
        
        //Create MessagingDeliveryError
        MessagingDeliveryError mdeRecord = new MessagingDeliveryError();
        mdeRecord.FlowEntity = acc.Id;
        mdeRecord.Type = ERROR_STR;
        insert mdeRecord;                            

        //Close Contact
        //Create Account
        Account acc2 = new Account(LastName='Test1',FirstName='Account');
        acc2.RecordTypeId = AccountPARecordTypeID;
        insert acc2;

        //Insert Case
        Case caseRec2 = new Case(Status='Quarantine');
        caseRec2.RecordTypeId = caseCloseContactRecordTypeID;
        caseRec2.AccountId = acc2.id;
        caseRec2.SubStatus__c = 'In Progress';
        insert caseRec2;

        //Create MessagingDeliveryError
        MessagingDeliveryError mdeRecord2 = new MessagingDeliveryError();
        mdeRecord2.FlowEntity = acc2.Id;
        mdeRecord2.Type = ERROR_STR;
        insert mdeRecord2;


    }
                                
   //Test method
   static testmethod void schedulerTest() 
   {
       Test.startTest();
       // Schedule the test job
       String jobId = System.schedule('ScheduledApexTest',
                                      CRON_EXP, 
                                      new DHHS_MessageDeliveryErrorScheduler());         
       
		DHHS_MessageDeliveryErrorScheduler scheduledClass = new DHHS_MessageDeliveryErrorScheduler();
		scheduledClass.execute(null);
       // Stopping the test will run the job synchronously
       Test.stopTest();
                                    
   }
                                
}