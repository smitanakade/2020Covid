@isTest
private class EHRObservationTriggerHandlerTest
{

    @testSetup static void testDataSetup() 
    {

        //Create QA data for Case and Work Order
        TestDataFactory.createQAllocationForCaseRecordType();
        TestDataFactory.createQAllocationForWorkOrderRecordType();

        //Create Person Accounts
        List<Account> accounts = TestDataFactory.createAccount(5, 'Active','Person Account');
        Set<Id> contactIds = new Set<Id>();
        List<Account> accountRecords = [Select PersonContactId from Account];
        for(Account acc : accountRecords )
        {
            contactIds.add(acc.PersonContactId);
        }        
        //Contacts
        List<Contact> contacts = [Select Id from Contact where Id=:contactIds];
        //Create ContactEncounters
        List<ContactEncounter> contactEncounters = TestDataFactory.createContactEncounter(contacts);
        System.assert(contactEncounters.size()>0);
        //Create Confirmed Cases
        List<Case> confirmedCases = TestDataFactory.createCases(accounts.get(1), 5, 'Isolate', 'COVID-19 Case Assessment');
        //Create Close Contact Cases
        List<Case> closeContacts = TestDataFactory.createCases(accounts.get(2), 5, 'Isolate', 'Close Contact');
        //Create Secondary Close Contact Case
        List<Case> secondaryCloseContacts = TestDataFactory.createCases(accounts.get(2), 5, 'Isolate', 'Secondary Close Contact');
        HealthCloudGA__EHRProcedure__c ehrProcedure = new HealthCloudGA__EHRProcedure__c(HealthCloudGA__Account__c=accounts[0].Id);
        Database.insert(ehrProcedure);
    }
    @isTest static void testCase()
    {
        Account accountRecord = [Select Id from Account LIMIT 1];
        Case closeContact = [Select Id, CaseNumber,Latest_EHR_Observation__c  from Case where RecordType.Name='Close Contact'  LIMIT 1];

        Case secondaryCloseContact = [Select Id, CaseNumber,Parent_Record_EHR_Observation__c from Case where RecordType.Name='Secondary Close Contact'  LIMIT 1];

        Test.startTest();
        try
        {
            ContactEncounter ce = [Select Id from ContactEncounter LIMIT 1];
            update ce;
            ContactEncounterParticipant cep = new ContactEncounterParticipant(Contact_Type__c='Secondary Close Contact', Parent_Record__c = closeContact.Id, Record__c = secondaryCloseContact.Id, ContactEncounterId=ce.Id);
            insert cep;
    
            HealthCloudGA__EHRProcedure__c ehrProcedure =[Select Id from HealthCloudGA__EHRProcedure__c Limit 1];
            HealthCloudGA__EhrObservation__c ehrObsPCC = new HealthCloudGA__EhrObservation__c(Record__c=closeContact.Id, EHR_Procedure__c=ehrProcedure.Id,
                                                                                            HealthCloudGA__Account__c=accountRecord.Id, HealthCloudGA__IssuedDate__c =System.now()-2);
            insert ehrObsPCC;
            System.assert(ehrObsPCC.Id==[Select Latest_EHR_Observation__c from Case where Id=:closeContact.Id][0].Latest_EHR_Observation__c );                                                                                                                                                           
            
            HealthCloudGA__EhrObservation__c ehrObsSCC = new HealthCloudGA__EhrObservation__c(Record__c=secondaryCloseContact.Id, EHR_Procedure__c=ehrProcedure.Id,
                                                                                            HealthCloudGA__Account__c=accountRecord.Id, HealthCloudGA__IssuedDate__c =System.now()-2);
            insert ehrObsSCC;
            secondaryCloseContact.Parent_Record_EHR_Observation__c = ehrObsSCC.Id;
            update secondaryCloseContact;
            HealthCloudGA__EhrObservation__c ehrObsPCC2 = new HealthCloudGA__EhrObservation__c(Record__c=closeContact.Id, EHR_Procedure__c=ehrProcedure.Id,
                                                                                            HealthCloudGA__Account__c=accountRecord.Id, HealthCloudGA__IssuedDate__c =System.now());
            insert ehrObsPCC2;
            Test.stopTest();
            
            System.assert(ehrObsPCC2.Id==[Select Latest_EHR_Observation__c from Case where Id=:closeContact.Id][0].Latest_EHR_Observation__c ) ;
            System.assert([Select Parent_Record_EHR_Observation__c from Case where Id=:secondaryCloseContact.Id][0].Parent_Record_EHR_Observation__c ==[Select Latest_EHR_Observation__c from Case where Id=:closeContact.Id][0].Latest_EHR_Observation__c  );
        }
        catch(Exception ex){}         
    }    
}