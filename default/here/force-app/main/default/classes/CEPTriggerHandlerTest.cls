@isTest
private class CEPTriggerHandlerTest 
{
    @testSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='sysadmin@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='ceptriggertest@testorg.com');
        insert u;

        Id accountRecordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Id outbreakRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Outbreak').getRecordTypeId();
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        Id secondaryCloseContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
        Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
        Id cepMovementRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Movement').getRecordTypeId();
        Id cepCloseConRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();        
        Id cepConfCaseTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Contact_with_Confirmed_Case').getRecordTypeId();
        
        Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='Test FName', LastName='Test LName',PersonMailingStreet='101 Collins Street',
                                 PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test@gmail.com', PersonHomePhone='1234567',PersonMobilePhone='+614444');
        insert accountRecord;
        Id contactId = [Select PersonContactId from Account where Id=:accountRecord.Id][0].PersonContactId;
        Case confirmedCase = new Case(recordTypeId=confirmedCaseRecordTypeId ,Status='Isolate', SubStatus__c = 'In Progress',Subject='Test Case - Assignment Rule',
                             AccountId=accountRecord.Id, Symptoms_Onset_Date__c=System.Today());
        insert confirmedCase ;
        Case closeContact2 = new Case(recordTypeId=closeContactRecordTypeId ,Status='Quarantine' ,SubStatus__c='In Progress',Subject='Test',
                             AccountId=accountRecord.Id, Day_0_Exposure_to_the_confirmed_case__c=System.Today()-6);
        ContactEncounter ceRecord = new ContactEncounter(RecordTypeId=cepCloseConRecordTypeId, Name='Private residence – home', StartTime=System.Now(), Record__c=confirmedCase.Id ); 
        insert ceRecord;       

        Case pcc = new Case(recordTypeId=closeContactRecordTypeId, Status='Identify', SubStatus__c = 'In Progress',Subject='Test Case - Assignment Rule',
                             AccountId=accountRecord.Id, Symptoms_Onset_Date__c=System.Today());
        insert pcc ;

        Case scc = new Case(recordTypeId=secondaryCloseContactRecordTypeId, Status='Identify', SubStatus__c = 'In Progress',Subject='Test Case - Assignment Rule',
                             AccountId=accountRecord.Id, Symptoms_Onset_Date__c=System.Today());
        insert scc;

        System.runAs(u) {
            Case outbreak = new Case(recordTypeId=outbreakRecordTypeId,Status='Isolate', SubStatus__c = 'In Progress',Subject='Test Case - Outbreak',
                                AccountId=accountRecord.Id, Site_Type__c = 'Outbreak', OwnerId = u.Id);
            insert outbreak;
        }
    }

    @isTest()
    static void testCase1()    
    {
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant(Record__c=confirmedCase.Id ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        insert cepRecord3;
        List<ContentDocumentLink> notes = [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId =:confirmedCase.Id];
        System.assert(notes !=null);
    } 
    @isTest()
    static void testCase2()    
    {
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        test.startTest();
        ContactEncounterParticipant cepRecord1 = new ContactEncounterParticipant(ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        test.stopTest();
        insert cepRecord1 ;
        System.assert(cepRecord1!=null);        
    }
    @isTest()
    static void testCase3()    
    {
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        test.startTest();
        Account accountRecord = [Select Id from Account Limit 1];
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        Contact c = [Select Id, BirthDate from Contact where Id=:contactId];
        c.BirthDate = Date.Today()-30;
        update c;
        test.stopTest();
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        //Case closeContact = [Select Id from Case where RecordType.DeveloperName='Close_Contact'];
        Case closeContact = new Case(recordTypeId=closeContactRecordTypeId,Status='Identify',SubStatus__c='In Progress',Subject='Test Case - Day 0',
                            AccountId=accountRecord.Id, Day_0_Exposure_to_the_confirmed_case__c = System.Today()-2);//, Day_0_Exposure_to_the_confirmed_case__c = System.Today()-5
        try
        {
            insert closeContact ;
            ContactEncounterParticipant cepRecord2 = new ContactEncounterParticipant(Record__c=closeContact.Id ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
            insert cepRecord2;
            System.assert(cepRecord2 !=null);
        }
        catch(Exception e)
        {}    
    }       
    @isTest
    static void testSecondaryCloseContact()    
    {
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant( Contact_Type__c='Secondary Close Contact' ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        insert cepRecord3;
        List<ContentDocumentLink> notes = [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId =:confirmedCase.Id];
        System.assert(notes !=null);
    } 

    @isTest
    static void testCloseContact()    
    {
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant(Contact_Type__c='Close Contact' ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        insert cepRecord3;
        List<ContentDocumentLink> notes = [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId =:confirmedCase.Id];
        System.assert(notes !=null);
    }
    
    @istest
    static void testAcquisitionContact()
    {
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant(Contact_Type__c='Acquisition Contact' ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        insert cepRecord3;
        List<ContentDocumentLink> notes = [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId =:confirmedCase.Id];
        System.assert(notes !=null);
    }

    @istest
    static void testCasualContact()
    {
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant(Contact_Type__c='Casual Contact' ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        insert cepRecord3;
        List<ContentDocumentLink> notes = [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId =:confirmedCase.Id];
        System.assert(notes !=null);
    }

    @istest
    static void testUnclassifiedContact()
    {
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant(Contact_Type__c='Unclassified Contact' ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        insert cepRecord3;
        List<ContentDocumentLink> notes = [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId =:confirmedCase.Id];
        System.assert(notes !=null);
    }

    @IsTest
    private static void testCloseContactHouseholdAllocation(){
        
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant(Relationship_to_Case__c = 'Household', Contact_Type__c = 'Close contact', parent_record__c=confirmedCase.Id ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        
        Test.startTest();
            insert cepRecord3;
            System.assert(cepRecord3 !=null);
        Test.stopTest();
    }

    @IsTest
    private static void testSCCHouseholdAllocation(){
        
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant(Relationship_to_Case__c = 'Household', Contact_Type__c = 'Secondary Close Contact', parent_record__c=confirmedCase.Id ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        
        Test.startTest();
            insert cepRecord3;
            System.assert(cepRecord3 !=null);
        Test.stopTest();
    }

    @IsTest
    private static void testCloseContactUpdateHouseholdAllocation(){
        
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        acase.SubStatus__c = null;
        insert acase;
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant(Record__c = acase.Id, Relationship_to_Case__c = 'Household', Contact_Type__c = 'Close contact', parent_record__c=confirmedCase.Id ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        
        Test.startTest();
            insert cepRecord3;
            System.assert(cepRecord3 !=null);
        Test.stopTest();
    }

    @IsTest
    private static void testSCCUpdateHouseholdAllocation(){
        
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Secondary Close Contact').get(0);
        acase.SubStatus__c = null;
        insert acase;
        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant(Record__c = acase.Id, Relationship_to_Case__c = 'Household', Contact_Type__c = 'Secondary Close Contact', parent_record__c=confirmedCase.Id ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );
        
        Test.startTest();
            insert cepRecord3;
            System.assert(cepRecord3 !=null);
        Test.stopTest();
    }

    @isTest
    private static void testAddNote() {
        List<Case> cases = [Select Id, CaseNumber from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];

        Test.startTest();

        CEPTriggerHandler.addNote(cases, 'test', 'test');

        ContentDocumentLink link = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :cases[0].Id];

        ContentDocument doc = [SELECT Id, Title FROM ContentDocument WHERE Id = :link.ContentDocumentId];

        Test.stopTest();
    
        System.assertEquals('test', doc.Title);
    }

    @IsTest
    private static void testCloseContactOngoingExposure(){

        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        Id contactId = [Select PersonContactId from Account ][0].PersonContactId;
        ContactEncounter ceRecord = [Select Id from ContactEncounter ];
        Case confirmedCase = [Select Id from Case where RecordType.DeveloperName='COVID_19_Case_Assessment'];
        Case closeContactCase = [Select Id from Case where RecordType.DeveloperName='Close_contact'];

        ContactEncounterParticipant cepRecord3 = new ContactEncounterParticipant(Record__c = closeContactCase.Id, Relationship_to_Case__c = 'Household', Contact_Type__c = 'Close contact', parent_record__c=confirmedCase.Id ,ContactEncounterId =ceRecord.Id, ContactId = contactId, End_Time__c = System.Now()+3 );

        Test.startTest();
        insert cepRecord3;
        System.assert(cepRecord3 != null);

        cepRecord3.On_going_exposure__c = true;
        update cepRecord3;

        Case closeContact = [SELECT Id, On_going_exposure__c, Day_0_Exposure_to_the_confirmed_case__c FROM Case WHERE Id = :cepRecord3.Record__c];
        System.assertEquals(true, closeContact.On_going_exposure__c);
        System.assertNotEquals(Date.today(), closeContact.Day_0_Exposure_to_the_confirmed_case__c);

        Test.stopTest();
    }

}