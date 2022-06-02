/*
 * @Author             : Xiang Zheng
 * @Description        : test class for ShortformController
 * @Modification Log   : 
 * --------------------------------------------------------------------------------------
 * Date           Author      		    Details
 * --------------------------------------------------------------------------------------
 * 10/09/2021     Xiang Zheng           Initial version
*/
@isTest
public class ShortformController_Test {
    @testSetup static void setupTestData() {
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        Id interviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
        Id cepCloseConRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();        
        
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);

        Case cse = new Case(recordTypeId = closeContactRecordTypeId, Status = 'Trace', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                            AccountId = personAc.Id, Symptoms_Onset_Date__c = System.Today().addDays(-5), Date_of_Test__c = System.Today().addDays(-2), Clearance_eligibility_assessment_date__c = System.Today().addDays(12));
        insert cse;

        ContactEncounter contactEnc = new ContactEncounter ();
        contactEnc.Record__c = cse.Id;
        contactEnc.StartTime = System.now();
        contactEnc.End_Time__c = System.now().addDays(1);
        contactEnc.Name = 'At Home';
        contactEnc.recordTypeId = cepCloseConRecordTypeId;
        insert contactEnc;

        WorkOrder closeContactWorkOrder = new WorkOrder(recordTypeId=interviewWORecordTypeId, Status='In Progress', Subject='Test closeContactWorkOrder',
                                          AccountId=personAc.Id, CaseId = cse.Id);
        insert closeContactWorkOrder;

        ContactEncounterParticipant cep = new ContactEncounterParticipant();
        cep.Parent_Record__c = cse.Id;
        cep.ContactEncounterId =contactEnc.Id;
        cep.Account__c = personAc.Id;
        insert cep;
    }


    @isTest()
    static void getcontactsTest(){
        workorder inscopeworkorder = [select id,accountId,caseid from workorder LIMIT 1];
        List<ShortformController.contactWrapper> wrapperList = ShortformController.getcontacts(inscopeworkorder.Id);
        system.assertNotEquals(wrapperList, null);
    }

    @isTest()
    static void saveclosecontactTest(){
        Case testCase = [SELECT Id,AccountId FROM Case LIMIT 1];
        String caseid = (String)testCase.Id;
        String result = ShortformController.saveclosecontact(testCase.AccountId,testCase.Id,caseid, System.today(),'Airline','Friend');
        system.assertEquals(result, 'success');
    }
}