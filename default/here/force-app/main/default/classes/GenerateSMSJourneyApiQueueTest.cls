
/**
* @Author             : DHHS
* @Description        : Test Generate SMS JourneyApi Queues class test
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 26/10/2021     Aref Samad         PBI-322220 Add test for GenerateSMSJourneyApiQueue class
*                                   
**/
@isTest() 
public class GenerateSMSJourneyApiQueueTest {

    @TestSetup
    static void prepareData(){
                
        TestDataFactory.createQAllocationForCaseRecordType();
        TestDataFactory.createQAllocationForWorkOrderRecordType();

        String recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc= new Account(
          RecordTypeID=recordTypeId ,
          FirstName='Test FName for Test',
          LastName='Test LName',
          PersonMailingStreet='test@yahoo.com',
          PersonMailingPostalCode='12345',
          PersonMailingCity='SFO',
          PersonEmail='test@yahoo.com',
          PersonHomePhone='1234567',
          PersonMobilePhone='+611234'
        );
        insert acc;

        List<Case>cases = new list<Case>();
        acc = [SELECT Id from Account Where FirstName = 'Test FName for test' LIMIT 1];
       
        String caseRecordTypeIdCloseContact = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
              

        Case cse = new Case(recordTypeId=caseRecordTypeIdCloseContact,Status='Quarantine',SubStatus__c='In Progress',Subject='Test Case - Day 0',
                             AccountId=acc.Id, Day_0_Exposure_to_the_confirmed_case__c = System.Today());
        cases.add(cse);

        TriggerHandler.bypass('CaseTriggerHandler');
        insert cases;       

        //Custom Settings initiate
        MC_Journey_SMS_Send__c mcJourneyCustomSettings=MC_Journey_SMS_Send__c.getValues(UserInfo.getOrganizationId());       
        if (mcJourneyCustomSettings==null)
        {
            mcJourneyCustomSettings=new MC_Journey_SMS_Send__c(SetupOwnerId=UserInfo.getOrganizationId(),Client_Id__c='OVDI12884DX',
            Client_Secret__c='XIUEJSEEE',Account_Id__c='2884384',Event_Definition_Key__c='Event:9dfjasdf0',Auth_Api_Url__c='https://test.api',Event_Api_Url__c='https://test.api');


            insert mcJourneyCustomSettings;
        }
        
    }


    @isTest 
    static void testSuccessJourneyApiQueue(){

        //given
        Case c = [SELECT Id FROM Case where Subject= 'Test Case - Day 0'];
        Id caseId = c.Id;

       
        Test.startTest();
        //when
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        System.enqueueJob(new GenerateSMSJourneyApiQueue(caseId));

        Test.stopTest();

        //then
        MC_Journey_SMS_Send__c mcJourneyCustomSettings=MC_Journey_SMS_Send__c.getValues(UserInfo.getOrganizationId());    
        System.assert(String.isNotBlank(mcJourneyCustomSettings.Key_Part_1__c));

    }




   
   
}
