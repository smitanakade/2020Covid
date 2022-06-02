@isTest(SeeAllData=True)
private class GenerateSMSSurveyBatchProcessTest {
    
    @isTest 
    static void testbatch(){  
        String recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        StaticCommon.disablePermissionTrigger();
        Profile p = [SELECT Id FROM Profile WHERE Name='Health worker']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.comvgkghgbkjhbgikhjbkjb');
        insert u;
        


        system.runAs(u)
         {
             TestDataFactory.createQAllocationForCaseRecordType();
             TestDataFactory.createQAllocationForWorkOrderRecordType();

            User u2 = [SELECT Id FROM User WHERE UserName='standarduser@testorg.comvgkghgbkjhbgikhjbkjb'];

        Account acc= new Account(
                RecordTypeID=recordTypeId ,
                FirstName='Test FName',
                LastName='Test LName',
                PersonMailingStreet='test@yahoo.com',
                PersonMailingPostalCode='12345',
                PersonMailingCity='SFO',
                PersonEmail='test@yahoo.com',
                PersonHomePhone='1234567',
                PersonMobilePhone='+61123',
                PersonHasOptedOutOfSMS__c=false,
                Alive_deceased__c='Alive',
                Accommodation_type__c='Private Residence'
        );
        insert acc;

        acc = [SELECT Id, PersonHasOptedOutOfSMS__c from Account Where FirstName = 'Test FName' LIMIT 1];

        acc.PersonHasOptedOutOfSMS__c = false;

        update acc;

        String caseRecordTypeIdConfirmedCase = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        String caseRecordTypeIdCloseContact = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
        String caseRecordTypeIdSecondaryCloseContact = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Secondary Close Contact').getRecordTypeId();
        List<case> lstCase = new List<case>();
        /*for(Integer i=0; i<20;i++){
            Case cse2 = new Case(recordTypeId=caseRecordTypeIdConfirmedCase,Status='Isolate', OwnerId = u2.Id, SubStatus__c='In Progress',Subject='Batch Test Case',
            AccountId=acc.Id, Symptoms_Onset_Date__c=System.Today()-4);
            lstCase.add(cse2);
        }*/
        for(Integer i=0; i<5;i++){
            Case cse2 = new Case(recordTypeId=caseRecordTypeIdCloseContact,Status='Isolate', OwnerId = u2.Id, SubStatus__c='In Progress',Subject='Batch Test Case',
            AccountId=acc.Id, Symptoms_Onset_Date__c=System.Today()-4, Day_0_Exposure_to_the_confirmed_case__c=System.Today()-4,Clearance_eligibility_assessment_date__c=System.Today()+6);// 
            lstCase.add(cse2);
        }

        
        for(Integer i=0; i<5;i++){
            Case c = new Case(recordTypeId=caseRecordTypeIdCloseContact,Status='Quarantine',SubStatus__c='In Progress',Subject='Batch Test Case',
                             AccountId=acc.Id, Day_0_Exposure_to_the_confirmed_case__c = System.Today()-14);
            lstCase.add(c);
        }
        insert lstCase;

    
        
        Map<Id,Case> caseMap = new Map<Id,Case>(lstCase);
        List<Id> caseIds = new List<Id>(caseMap.keySet());

        List<Case> casesCheckList = [SELECT Id, Record_Age__c, Close_Contact_Record_Age__c, Account.Alive_deceased__c, Account.PersonMobilePhone, Account.PersonHasOptedOutOfSMS__c, Status, SubStatus__c, Owner.Type, AccountId, RecordTypeId 
                                    FROM Case WHERE Subject = 'Batch Test Case' AND Account.PersonMobilePhone != null 
                                    //AND Account.PersonHasOptedOutOfSMS__c != true AND (Status = 'Quarantine' OR  Status = 'Isolate') 
                                    //AND Owner.Type = 'User' AND AccountId != null AND (Record_Age__c != null OR Close_Contact_Record_Age__c != null)
                                    AND Id IN :caseIds LIMIT 10];
        System.assertEquals(casesCheckList.size(),10);

        Test.startTest();
        List<case> lt = [SELECT Id FROM Case WHERE Id IN :caseIds AND MessagingTemplate__c != null];
        System.assertEquals(0, lt.size(), 'Cases exist befor job has run');
        //System.Debug('*** Number of Cases created for Test with MessagingTemplate__c != null:'+lt.size());

        GenerateSMSSurveyBatchProcess b = new GenerateSMSSurveyBatchProcess();
        database.executebatch(b, 10);

        Test.stopTest();
        lt = [SELECT Id FROM Case WHERE Id IN :caseIds AND MessagingTemplate__c != null];
        System.Debug('*** Number of Cases created for Test with MessagingTemplate__c != null - AFTER TEST JOB:'+lt.size());
        System.assertEquals(caseIds.size(), lt.size(), 'Surveys were not created'); 
    }
    }
}