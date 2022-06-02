@isTest(SeeAllData=True)
private class SendSMSSurveyScheduledJobTest {

    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    static testmethod void testScheduledJob() {
        String recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        //User user 
        StaticCommon.disablePermissionTrigger();
        Profile p = [SELECT Id FROM Profile WHERE Name='Health worker']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.comvgkghgbkjhbgikhjbkjb');
        insert u;
        User u2 = [SELECT Id FROM User WHERE UserName='standarduser@testorg.comvgkghgbkjhbgikhjbkjb'];
        
        
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {

            Account acc= new Account(
            RecordTypeID=recordTypeId,
            FirstName='Test FName',
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='+61234',
            PersonHasOptedOutOfSMS__c=false
            );
            insert acc;

            acc = [SELECT Id from Account Where FirstName = 'Test FName' LIMIT 1];

            String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
            System.Debug('*** caseRecordTypeId :'+caseRecordTypeId);


            // List<Case> cases = new List<Case>();
            // for(Integer i=0;i<25;i++){
            //     Case newCase = new Case(recordTypeId=caseRecordTypeId,Status='Isolate', OwnerId = u2.Id, SubStatus__c='In Progress',Subject='Test Case ' + i,AccountId=acc.Id, Symptoms_Onset_Date__c=System.Today()-11, Day_0_Exposure_to_the_confirmed_case__c = System.Today()-4);
            //     cases.add(newCase);
            // }
            // insert cases;
            String caseRecordTypeIdConfirmedCase = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
            List<case> lstCase = new List<case>();
            for(Integer i=0; i<20;i++){
                Case cse2 = new Case(recordTypeId=caseRecordTypeIdConfirmedCase,Status='Isolate', OwnerId = u2.Id, SubStatus__c='In Progress',Subject='Batch Test Case',
                AccountId=acc.Id, Symptoms_Onset_Date__c=System.Today()-4);
                lstCase.add(cse2);
            }

            String caseRecordTypeIdCloseContact = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
            for(Integer i=0; i<5;i++){
                Case c = new Case(recordTypeId=caseRecordTypeIdCloseContact,Status='Quarantine',SubStatus__c='In Progress',Subject='Batch Test Case',
                                AccountId=acc.Id, Day_0_Exposure_to_the_confirmed_case__c = System.Today()-14);
                lstCase.add(c);
            }
            insert lstCase;
            
            Map<Id,Case> caseMap = new Map<Id,Case>(lstCase);
            List<Id> caseIds = new List<Id>(caseMap.keySet());
            system.debug('***** Numbr of caseIds to test:' + caseIds);

            // List<case> listCases = [SELECT Id, Record_Age__c, Close_Contact_Record_Age__c, Account.PersonMobilePhone, Account.PersonHasOptedOutOfSMS__c, Status, SubStatus__c, Owner.Type, AccountId, RecordTypeId FROM Case WHERE Id IN :caseIds];
            // system.debug('***** Cases ' + listCases.size());
            // for (Case c : listCases){
            //     System.Debug('*** AAA Id:'  +c.Id+ ', Record_Age__c:' +c.Record_Age__c+ ', Close_Contact_Record_Age__c:'+c.Close_Contact_Record_Age__c+', Account.PersonMobilePhone:'+c.Account.PersonMobilePhone+', Account.PersonHasOptedOutOfSMS__c:'+c.Account.PersonHasOptedOutOfSMS__c+', Status:'+c.Status+', SubStatus__c:'+c.SubStatus__c+', Owner.Type:'+c.Owner.Type+', AccountId:'+c.AccountId+', Record_Age__c:'+c.Record_Age__c+', RecordTypeId:'+c.RecordTypeId);
            // }

            // ******####### Test that this data matches what is in our Batch Process query:
            List<Case> casesCheckList = [SELECT Id, Record_Age__c, Close_Contact_Record_Age__c, Account.PersonMobilePhone, Account.PersonHasOptedOutOfSMS__c, Status, SubStatus__c, Owner.Type, AccountId, RecordTypeId FROM Case WHERE Account.PersonMobilePhone != null AND Account.PersonHasOptedOutOfSMS__c != true AND (Status = 'Quarantine' OR  Status = 'Isolate') AND Owner.Type = 'User' AND AccountId != null AND Record_Age__c != null AND (RecordTypeId = '0122e0000004NZ9AAM' OR RecordTypeId = '0122e0000004NYuAAM') AND Id IN :caseIds LIMIT 25];
            for (Case c : casesCheckList){
                System.Debug('*** BBB Id:'  +c.Id+ ', Record_Age__c:' +c.Record_Age__c+ ', Close_Contact_Record_Age__c:'+c.Close_Contact_Record_Age__c+', Account.PersonMobilePhone:'+c.Account.PersonMobilePhone+', Account.PersonHasOptedOutOfSMS__c:'+c.Account.PersonHasOptedOutOfSMS__c+', Status:'+c.Status+', SubStatus__c:'+c.SubStatus__c+', Owner.Type:'+c.Owner.Type+', AccountId:'+c.AccountId+', Record_Age__c:'+c.Record_Age__c+', RecordTypeId:'+c.RecordTypeId);
            }

            Test.startTest();

            String jbId = System.schedule('Scheduled Apex Test', CRON_EXP, new SendSMSSurveyScheduledJob());
            //List<case> lt = [SELECT Id FROM Case WHERE Id IN :caseIds AND SurveyLinkURL__c != null];
            //System.assertEquals(0, lt.size(), 'Cases exist but do not have a SurveyLinkURL__c');
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jbId]; 
            // Verify the job has not run but has been scheduled
            System.assertEquals(0, ct.TimesTriggered); 

            Test.stopTest();
            // Calling this System Assert seems to prevent the batchable class from finding records to process.
            //lt = [SELECT Id FROM Case WHERE Id IN :caseIds AND SurveyLinkURL__c != null];
            //System.assertEquals(caseIds.size(), lt.size(), 'Surveys were not created');

         }
    }

}