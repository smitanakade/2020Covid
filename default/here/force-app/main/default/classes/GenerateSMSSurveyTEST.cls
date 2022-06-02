/**
* @Author             : DHHS
* @Description        : Test Generate SMS Survey Apex class
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 30/09/2021     Aref Samad         PBI-322220 Add Http callout mock MC Journey API
*                                   
**/
@isTest(SeeAllData=True) // SFDC 25 Sep 2020 - SeeAllData required due to test class needing access to the Surveys 
public class GenerateSMSSurveyTEST {
    
    //@testSetup static void setup() {
    //Test data creation
    
   
    static Map <String,Id> createCase(){    

        Map <String,Id> caseIdBySubject = new Map <String,Id>();
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

        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        String caseRecordTypeIdCloseContact = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
        String caseRecordTypeIdSecondaryCloseContact = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Secondary Close Contact').getRecordTypeId();
        
       

        Case cse = new Case(recordTypeId=caseRecordTypeIdCloseContact,Status='Quarantine',SubStatus__c='In Progress',Subject='Test Case - Day 0',
                             AccountId=acc.Id, Day_0_Exposure_to_the_confirmed_case__c = System.Today());
        cases.add(cse);

        Case cse2 = new Case(recordTypeId=caseRecordTypeIdCloseContact,Status='Quarantine',SubStatus__c='In Progress',Subject='Test Case - Day 1 - 9',
                             AccountId=acc.Id, Day_0_Exposure_to_the_confirmed_case__c = System.Today()-4);
        cases.add(cse2);

        Case cse3 = new Case(recordTypeId=caseRecordTypeIdCloseContact,Status='Quarantine',SubStatus__c='In Progress',Subject='Test Case - Day 10',
                             AccountId=acc.Id, Day_0_Exposure_to_the_confirmed_case__c = System.Today()-10);
        cases.add(cse3);

        Case cse4 = new Case(recordTypeId=caseRecordTypeIdCloseContact,Status='Quarantine',SubStatus__c='In Progress',Subject='Test Case - Day 11',
                             AccountId=acc.Id, Day_0_Exposure_to_the_confirmed_case__c = System.today()-11);
        cases.add(cse4);

        // DHSCT-1433 - Send Day 12 SMS
        Case cse5 = new Case(recordTypeId=caseRecordTypeIdCloseContact,Status='Quarantine',SubStatus__c='In Progress',Subject='Test Case - Day 12',
                             AccountId=acc.Id, Day_0_Exposure_to_the_confirmed_case__c = System.today()-12);
        cases.add(cse5);
        //DHSCT-1437    Send Quarantine Completion SMS - close contact
        //Quarantine stage, No pending or positive test result,  Day 14 of their Quarantine
        Case cse8 = new Case(recordTypeId=caseRecordTypeIdCloseContact,Status='Quarantine',SubStatus__c='In Progress',Subject='Test Case - Test Case - ClearedCase - Close Contact',
                             AccountId=acc.Id, Day_0_Exposure_to_the_confirmed_case__c = System.today()-14);

        cases.add(cse8);
        //DHSCT-1435 - Send Daily Case SMS - Isolate - Confirmed Case
        Case cse6 = new Case(recordTypeId=caseRecordTypeId,Status='Isolate',SubStatus__c='In Progress',Subject='Test Case - Daily SMS - Isolate_ConfirmedCase_0to9',
                             AccountId=acc.Id, Symptoms_Onset_Date__c=System.today()-5, Clearance_eligibility_assessment_date__c=System.today()+1);
       cases.add(cse6);

        // DHSCT-1436 - Isolate stage AND WHEN it is day 10 after the initial phone call 
        Case cse7 = new Case(recordTypeId=caseRecordTypeId,Status='Isolate',SubStatus__c='In Progress',Subject='Test Case - Isolate_ClearCase_Day10',
                             AccountId=acc.Id, Symptoms_Onset_Date__c=System.today()-10, Clearance_eligibility_assessment_date__c = System.today()   );
        cases.add(cse7);
        // For SCC
        Case cse9 = new Case(recordTypeId=caseRecordTypeIdSecondaryCloseContact,Status='Quarantine',SubStatus__c='In Progress',Subject='Test Case - SCC_Daily',
                             AccountId=acc.Id,Day_0_Exposure_to_primarycc__c = System.today().addDays(-4), Symptoms_Onset_Date__c=System.today()-4);
        cases.add(cse9);

        TriggerHandler.bypass('CaseTriggerHandler');
        insert cases;
        for(Case c : cases){
            caseIdBySubject.put(c.Subject, c.Id);
            System.debug('Case Inserted: ' + c);
        }

        //Custom Settings initiate
        MC_Journey_SMS_Send__c mcJourneyCustomSettings=MC_Journey_SMS_Send__c.getValues(UserInfo.getOrganizationId());       
        if (mcJourneyCustomSettings==null)
        {
            mcJourneyCustomSettings=new MC_Journey_SMS_Send__c(SetupOwnerId=UserInfo.getOrganizationId(),Client_Id__c='OVDI12884DX',
            Client_Secret__c='XIUEJSEEE',Account_Id__c='2884384',Event_Definition_Key__c='Event:9dfjasdf0',Auth_Api_Url__c='https://test.api',Event_Api_Url__c='https://test.api');

            insert mcJourneyCustomSettings;
        }

        return caseIdBySubject;
    }

    @isTest 
    static void ztestSMSDay0_CloseContact()
    {
        Map <String,Id> caseIdBySubject = createCase();
        Case c = [SELECT Id, Status,Day_0_Exposure_to_primarycc__c, SurveyLinkURL__c, MessagingTemplate__c, Clearance_eligibility_assessment_date__c, Symptoms_Onset_Date__c, Day_0_Exposure_to_the_confirmed_case__c, Close_Contact_Record_Age__c, Record_Age__c, Permit_Type__c
                  FROM Case where Id =:caseIdBySubject.get('Test Case - Day 0') ];
        String msgTemplate= c.MessagingTemplate__c;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        GenerateSMSSurvey.CreateSurveyInv(c);
        Test.stopTest();
        c = [SELECT  MessagingTemplate__c FROM Case where Id =:caseIdBySubject.get('Test Case - Day 0')];
        String msgTemplateNew = c.MessagingTemplate__c;
        System.assertNotEquals(msgTemplateNew, msgTemplate, 'The URL in the Case record has changed - the MessageTemplate was generated');
    } 

    @isTest 
    static void testSMSDay1to9_CloseContact()
    {
        Map <String,Id> caseIdBySubject = createCase();
        Case c = [SELECT Id, Status, SurveyLinkURL__c,Day_0_Exposure_to_primarycc__c, MessagingTemplate__c, Clearance_eligibility_assessment_date__c, Symptoms_Onset_Date__c, Day_0_Exposure_to_the_confirmed_case__c, Close_Contact_Record_Age__c, Record_Age__c, Permit_Type__c
                  FROM Case where Id =:caseIdBySubject.get('Test Case - Day 1 - 9')];
        String msgTemplate = c.MessagingTemplate__c;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        GenerateSMSSurvey.CreateSurveyInv(c);
        Test.stopTest();
        c = [SELECT  MessagingTemplate__c FROM Case where Id =:caseIdBySubject.get('Test Case - Day 1 - 9')];
        String msgTemplateNew = c.MessagingTemplate__c;
        System.assertNotEquals(msgTemplateNew, msgTemplate, 'The URL in the Case record has changed - the MessageTemplate was generated');
    }

    @isTest 
    static void testSMSDay10_CloseContact()
    {
        Map <String,Id> caseIdBySubject = createCase();

        Case c = [SELECT Id, Status,Day_0_Exposure_to_primarycc__c, SurveyLinkURL__c, MessagingTemplate__c, Symptoms_Onset_Date__c, Day_0_Exposure_to_the_confirmed_case__c, Close_Contact_Record_Age__c, Record_Age__c, Clearance_eligibility_assessment_date__c, Permit_Type__c
                   FROM Case where Id =:caseIdBySubject.get('Test Case - Day 10')];
        // String surveyURL = c.SurveyLinkURL__c;
        // GenerateSMSSurvey.CreateSurveyInv(c);
        // c = [SELECT  SurveyLinkURL__c FROM Case where Subject = 'Test Case - Day 10'];
        // String surveyURLNew = c.SurveyLinkURL__c;
        // System.assertNotEquals(surveyURLNew, surveyURL, 'The URL in the Case record has changed - the URL was generated');

        String msgTemplate = c.MessagingTemplate__c;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        GenerateSMSSurvey.CreateSurveyInv(c);
        Test.stopTest();
        c = [SELECT  MessagingTemplate__c FROM Case where Id =:caseIdBySubject.get('Test Case - Day 10')];
        String msgTemplateNew = c.MessagingTemplate__c;
        System.assertNotEquals(msgTemplateNew, msgTemplate, 'The URL in the Case record has changed - the MessageTemplate was generated');
    }
    @isTest 
    static void testSMSDay11_CloseContact()
    {
        Map <String,Id> caseIdBySubject = createCase();

        Case c = [SELECT Id, Status,Day_0_Exposure_to_primarycc__c, SurveyLinkURL__c, MessagingTemplate__c, Symptoms_Onset_Date__c, Day_0_Exposure_to_the_confirmed_case__c, Close_Contact_Record_Age__c, Record_Age__c, Clearance_eligibility_assessment_date__c, Permit_Type__c
                   FROM Case where Id=:caseIdBySubject.get('Test Case - Day 11')];
        // String surveyURL = c.SurveyLinkURL__c;
        // GenerateSMSSurvey.CreateSurveyInv(c);
        // c = [SELECT  SurveyLinkURL__c FROM Case where Subject = 'Test Case - Day 11'];
        // String surveyURLNew = c.SurveyLinkURL__c;
        // System.assertNotEquals(surveyURLNew, surveyURL, 'The URL in the Case record has changed - the URL was generated');
        
        String msgTemplate = c.MessagingTemplate__c;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        GenerateSMSSurvey.CreateSurveyInv(c);
        Test.stopTest();
        c = [SELECT  MessagingTemplate__c FROM Case where Id=:caseIdBySubject.get('Test Case - Day 11')];
        String msgTemplateNew = c.MessagingTemplate__c;
        System.assertNotEquals(msgTemplateNew, msgTemplate, 'The URL in the Case record has changed - the MessageTemplate was generated');
    }

    @isTest 
    static void testSMSDay12_CloseContact()
    {
        Map <String,Id> caseIdBySubject = createCase();
        Case c = [SELECT Id, Status,Day_0_Exposure_to_primarycc__c, SurveyLinkURL__c, MessagingTemplate__c, Symptoms_Onset_Date__c, Day_0_Exposure_to_the_confirmed_case__c, Close_Contact_Record_Age__c, Record_Age__c, Clearance_eligibility_assessment_date__c, Permit_Type__c  
                   FROM Case where Id= :caseIdBySubject.get('Test Case - Day 12')];
        // String surveyURL = c.SurveyLinkURL__c;
        // GenerateSMSSurvey.CreateSurveyInv(c);
        // c = [SELECT  SurveyLinkURL__c FROM Case where Subject = 'Test Case - Day 12'];
        // String surveyURLNew = c.SurveyLinkURL__c;
        // System.assertNotEquals(surveyURLNew, surveyURL, 'The URL in the Case record has changed - the URL was generated');
        String msgTemplate = c.MessagingTemplate__c;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        GenerateSMSSurvey.CreateSurveyInv(c);
        Test.stopTest();
        c = [SELECT  MessagingTemplate__c FROM Case where Id= :caseIdBySubject.get('Test Case - Day 12')];
        String msgTemplateNew = c.MessagingTemplate__c;
        System.assertNotEquals(msgTemplateNew, msgTemplate, 'The URL in the Case record has changed - the MessageTemplate was generated');
    }

    @isTest 
    static void testSMSDay14_CloseContact()
    {
        Map <String,Id> caseIdBySubject = createCase();
        Case c = [SELECT Id,Day_0_Exposure_to_primarycc__c, Status, SurveyLinkURL__c, MessagingTemplate__c, Symptoms_Onset_Date__c, Day_0_Exposure_to_the_confirmed_case__c, Close_Contact_Record_Age__c, Record_Age__c, Clearance_eligibility_assessment_date__c, Permit_Type__c  
                  FROM Case where Id= :caseIdBySubject.get('Test Case - Test Case - ClearedCase - Close Contact')];
        // String surveyURL = c.SurveyLinkURL__c;
        // GenerateSMSSurvey.CreateSurveyInv(c);
        // c = [SELECT  SurveyLinkURL__c FROM Case where Subject = 'Test Case - Test Case - ClearedCase - Close Contact'];
        // String surveyURLNew = c.SurveyLinkURL__c;
        // System.assertNotEquals(surveyURLNew, surveyURL, 'The URL in the Case record has changed - the URL was generated');

        String msgTemplate = c.MessagingTemplate__c;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        GenerateSMSSurvey.CreateSurveyInv(c);
        Test.stopTest();
        c = [SELECT  MessagingTemplate__c FROM Case where Id= :caseIdBySubject.get('Test Case - Test Case - ClearedCase - Close Contact')];
        String msgTemplateNew = c.MessagingTemplate__c;
        System.assertNotEquals(msgTemplateNew, msgTemplate, 'The URL in the Case record has changed - the MessageTemplate was generated');

    }
        
    @isTest 
    static void testSMS_Isolate_ConfirmedCase_0to9()
    {
        Map <String,Id> caseIdBySubject = createCase();
        Case c = [SELECT Id, Status,Day_0_Exposure_to_primarycc__c, SurveyLinkURL__c, MessagingTemplate__c, Symptoms_Onset_Date__c, Day_0_Exposure_to_the_confirmed_case__c, Close_Contact_Record_Age__c, Record_Age__c,Clearance_eligibility_assessment_date__c, Permit_Type__c 
        FROM Case where Id= :caseIdBySubject.get('Test Case - Daily SMS - Isolate_ConfirmedCase_0to9')];
        // String surveyURL2 = c.SurveyLinkURL__c;
        // GenerateSMSSurvey.CreateSurveyInv(c);
        // c = [SELECT  SurveyLinkURL__c FROM Case where Subject = 'Test Case - Daily SMS - Isolate_ConfirmedCase_0to9'];
        // String surveyURLNew = c.SurveyLinkURL__c;
        // System.assertNotEquals(surveyURLNew, surveyURL2, 'The URL in the Case record has changed - the URL was generated');
        String msgTemplate = c.MessagingTemplate__c;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        GenerateSMSSurvey.CreateSurveyInv(c);
        Test.stopTest();
        c = [SELECT  MessagingTemplate__c FROM Case where Id= :caseIdBySubject.get('Test Case - Daily SMS - Isolate_ConfirmedCase_0to9')];
        String msgTemplateNew = c.MessagingTemplate__c;
        System.debug('*** New Message Template: ' + msgTemplateNew + ' Old Message Template: ' + msgTemplate);
        System.assertNotEquals(msgTemplateNew, msgTemplate, 'The URL in the Case record has changed - the MessageTemplate was generated');

    }

    @isTest 
    static void testSMS_Isolate_ConfirmedCase_ClearCase_Day10()
    {
        Map <String,Id> caseIdBySubject = createCase();

        Case c = [SELECT Id, Status,Day_0_Exposure_to_primarycc__c, SurveyLinkURL__c, MessagingTemplate__c, Symptoms_Onset_Date__c, Day_0_Exposure_to_the_confirmed_case__c, Close_Contact_Record_Age__c, Record_Age__c, Clearance_eligibility_assessment_date__c, Permit_Type__c  
        FROM Case where Id= :caseIdBySubject.get('Test Case - Isolate_ClearCase_Day10')];
        // String surveyURL2 = c.SurveyLinkURL__c;
        // GenerateSMSSurvey.CreateSurveyInv(c);
        // c = [SELECT  SurveyLinkURL__c FROM Case where Subject = 'Test Case - Isolate_ClearCase_Day10'];
        // String surveyURLNew = c.SurveyLinkURL__c;
        // System.assertNotEquals(surveyURLNew, surveyURL2, 'The URL in the Case record has changed - the URL was generated');
        String msgTemplate = c.MessagingTemplate__c;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        GenerateSMSSurvey.CreateSurveyInv(c);
        Test.stopTest();
        c = [SELECT  MessagingTemplate__c FROM Case where Id= :caseIdBySubject.get('Test Case - Isolate_ClearCase_Day10')];
        String msgTemplateNew = c.MessagingTemplate__c;
        System.debug('*** New Message Template: ' + msgTemplateNew + ' Old Message Template: ' + msgTemplate);
        System.assertNotEquals(msgTemplateNew, msgTemplate, 'The URL in the Case record has changed - the MessageTemplate was generated');
    }

    // For SCC
    @isTest
    static void testSMS_Daily_SCC_Notification()
    {
        Map <String,Id> caseIdBySubject = createCase();

        Case c = [SELECT Id, Status,Day_0_Exposure_to_primarycc__c, SurveyLinkURL__c, MessagingTemplate__c, Symptoms_Onset_Date__c, Day_0_Exposure_to_the_confirmed_case__c, Close_Contact_Record_Age__c, Record_Age__c, Clearance_eligibility_assessment_date__c, Permit_Type__c  
        FROM Case where Id= :caseIdBySubject.get('Test Case - SCC_Daily')];
        //String msgTemplate = c.MessagingTemplate__c;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        GenerateSMSSurvey.CreateSurveyInv(c);
        Test.stopTest();
        Case c2 = [SELECT  MessagingTemplate__c FROM Case where Id= :caseIdBySubject.get('Test Case - SCC_Daily')];
        //String msgTemplateNew = c.MessagingTemplate__c;
        System.assertNotEquals(c.MessagingTemplate__c, c2.MessagingTemplate__c, 'The URL in the Case record has changed - the MessageTemplate was generated');
    }
    
    @isTest 
    static void testSMS(){

        //createCase();
        Map <String,Id> caseIdBySubject = createCase();

        Case c = [SELECT Id FROM Case where Id= :caseIdBySubject.get('Test Case - Day 0')];
        Id caseId = c.Id;

        Survey s = [SELECT Id, Name FROM Survey WHERE DeveloperName = 'day0close'];
        string surveyId = s.Id;
        string surveyName = s.Name;

        Integer numSurveyInvs = [SELECT count() FROM surveyinvitation];
        Integer numSurveySubjects = [SELECT count() FROM surveysubject];
        Integer expectedSurveyInvs = numSurveyInvs + 1;
        Integer expectedSurveySubjects = numSurveySubjects + 1;
        List<case> results = [SELECT AccountId, SurveyLinkURL__c from case where id = :caseId];
        string URL = results[0].SurveyLinkURL__c;
        
        List<GenerateSMSSurvey.FlowInputs> request = new List<GenerateSMSSurvey.FlowInputs>();
        GenerateSMSSurvey.FlowInputs inputs = new GenerateSMSSurvey.FlowInputs();
        inputs.caseId = caseId;
        inputs.surveyId = surveyId;
        inputs.surveyName = surveyName;
        request.add(inputs);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new McJourneyEventSendCalloutMock()); 
        GenerateSMSSurvey.CreateSurveyInv(request);
        Test.stopTest();
        numSurveyInvs = [select count() from surveyinvitation];
        numSurveySubjects = [select count() from surveysubject];
        c = [SELECT Id, SurveyLinkURL__c FROM Case where Id= :caseIdBySubject.get('Test Case - Day 0') LIMIT 1];
        string newURL = c.SurveyLinkURL__c;
        
        System.assertEquals(expectedSurveyInvs, numSurveyInvs, 'Survey Invitation did not get created');
        System.assertEquals(expectedSurveySubjects, numSurveySubjects, 'Survey Subject did not get created');
        System.assertNotEquals(newURL, URL, 'The URL in the Person account record is the same');
    }

}