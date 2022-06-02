/**
 * @description       : Test Class for ELRelatedContactsController
 * @author            : CRM Squad 2
 * @group             : CRM Squad 2
 * @last modified on  : 12-13-2020
 * @last modified by  : CRM Squad 2
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   11-23-2020   CRM Squad 2   Initial Version
**/
@isTest
public with sharing class ELRelatedContactsControllerTest {

    /**
    * @description setup test data required
    * @author CRM Squad 2 | 11-23-2020 
    **/
    @testSetup static void testDataSetup() {

        //Create QA data for Case and Work Order - due to change from assignment rule to flow - US 240609
        TestDataFactory.createQAllocationForCaseRecordType();
        TestDataFactory.createQAllocationForWorkOrderRecordType();
        
        //Create Person Account
        List<Account> personAccList = TestDataFactory.createAccount(5, 'Active','Person Account');
        //Create Account
        List<Account> orgAccList = TestDataFactory.createAccount(5, 'Active','Place Or Organisation');
        //Create parent Case
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Exposure Management');
        //Create Case
        List<Case> caseListConfirmed = TestDataFactory.createCases(personAccList.get(1), 5, 'Isolate', 'COVID-19 Case Assessment');
        //Create Case
        List<Case> caseListClose = TestDataFactory.createCases(personAccList.get(2), 5, 'Isolate', 'Close Contact');

        //Create Contact
        List<Contact> conList = TestDataFactory.createContact(orgAccList);
        //Create ContactEncounter
        List<ContactEncounter> conEncList = TestDataFactory.createContactEncounter(conList);
        //Create ContactEncounterParticipant
        List<ContactEncounterParticipant> contPartList = new List<ContactEncounterParticipant>();
        for(Integer i=0; i<conEncList.size(); i++){
            ContactEncounterParticipant part = new ContactEncounterParticipant();
            part.ContactEncounterId = conEncList.get(i).Id;
            part.ContactId = conEncList.get(i).Contact_Person__c;
            part.Record__c = caseListClose.get(i).Id;
            part.Parent_Record__c = caseListConfirmed.get(i).Id;
            contPartList.add(part);
        }
        //Add one CEP for Close Contcat Link
        ContactEncounterParticipant part1 = new ContactEncounterParticipant(ContactEncounterId = conEncList.get(0).Id,Record__c = caseListClose.get(0).Id,
        ContactId = conEncList.get(0).Contact_Person__c, Parent_Record__c = caseListClose.get(0).Id);

        contPartList.add(part1);
        insert contPartList;

        //Create Exposure Link
        List<Exposure_Link__c> expLinkList = new List<Exposure_Link__c>();

        for (Case confCase:caseListConfirmed){
            Exposure_Link__c expLink = new Exposure_Link__c();
            expLink.Exposure_Record__c = caseListExp.get(0).Id;
            expLink.Linked_Record__c = confCase.Id;
            expLinkList.add(expLink);
        }
        //Link 1 close contact exposure Link
        expLinkList.add(new Exposure_Link__c(Exposure_Record__c=caseListExp.get(0).Id,Linked_Record__c=caseListClose.get(0).Id));
        insert expLinkList;
    }

    /**
    * @description test GetIndividualsLinkedToCase With Confirmed
    * @author CRM Squad 2 | 11-23-2020 
    **/
    @isTest static void testGetIndividualsLinkedToCaseWithConfirmed(){

        Case expCase = [Select Id from Case where RecordType.Name='Exposure Management'];
        list<ELRelatedContactsController.ContactEncounterParticipantWrapper> wrapper = new list<ELRelatedContactsController.ContactEncounterParticipantWrapper>();
        
        Test.startTest();
        wrapper = ELRelatedContactsController.getIndividualsLinkedToCase(expCase.Id,'COVID-19 Case Assessment');
        Test.stopTest();

        System.assertEquals(5, wrapper.size(), 'Expected number of individual Link with Confirm case not returned');

    }

    /**
    * @description test GetIndividualsLinkedToCase With CloseContact
    * @author CRM Squad 2 | 11-23-2020 
    **/
    @isTest static void testGetIndividualsLinkedToCaseWithCloseContact(){

        Case expCase = [Select Id from Case where RecordType.Name='Exposure Management'  LIMIT 1];
        list<ELRelatedContactsController.ContactEncounterParticipantWrapper> wrapper = new list<ELRelatedContactsController.ContactEncounterParticipantWrapper>();
        
        Test.startTest();
        wrapper = ELRelatedContactsController.getIndividualsLinkedToCase(expCase.Id,'Close Contact');
        Test.stopTest();

        System.assertEquals(1, wrapper.size(), 'Expected number of individual Link with Close Contact case not returned');

    }

    /**
    * @description test GetIndividualsLinked To Exposure Link
    * @author CRM Squad 2 | 11-23-2020 
    **/
    @isTest static void testGetIndividualsLinkedToExposureLink(){

        Exposure_Link__c expLink = [Select Id from Exposure_Link__c Limit 1];
        list<ELRelatedContactsController.ContactEncounterParticipantWrapper> wrapper = new list<ELRelatedContactsController.ContactEncounterParticipantWrapper>();
        
        Test.startTest();
        wrapper = ELRelatedContactsController.getIndividualsLinkedToCase(expLink.Id,'');
        Test.stopTest();

        System.assertEquals(1, wrapper.size(), 'Expected number of individual Link with Confirmed case not returned');
    }

    /**
    * @description test GetIndividualsLinkedToCase With Confirmed RunAs HealthWorker
    * @author CRM Squad 2 | 11-23-2020 
    **/
    @isTest static void testGetIndividualsLinkedToCaseWithConfirmedRunAsHealthWorker(){

        User healthWorkerUser = TestDataFactory.createHealthWorkerUser();
        Case expCase = [Select Id from Case where RecordType.Name='Exposure Management' LIMIT 1];
        list<ELRelatedContactsController.ContactEncounterParticipantWrapper> wrapper = new list<ELRelatedContactsController.ContactEncounterParticipantWrapper>();
        

        System.runAs(healthWorkerUser){
            Test.startTest();
            wrapper = ELRelatedContactsController.getIndividualsLinkedToCase(expCase.Id,'COVID-19 Case Assessment');
            Test.stopTest();
        }

        System.assertEquals(5, wrapper.size(), 'Expected number of individual Link with Confirm case not returned');
    }

    
    /**
    * @description test GetIndividualsLinkedToCase ErrorScenario
    * @author CRM Squad 2 | 11-23-2020 
    **/
    @isTest static void testGetIndividualsLinkedErrorScenario(){

        //Get the unsupported Object Like account
        Account acc = [Select Id from Account Limit 1];
        list<ELRelatedContactsController.ContactEncounterParticipantWrapper> wrapper = new list<ELRelatedContactsController.ContactEncounterParticipantWrapper>();
        Boolean exceptionOccured = false;

        Test.startTest();
        try{
        wrapper = ELRelatedContactsController.getIndividualsLinkedToCase(acc.Id,'');
        }catch(Exception e){
            exceptionOccured = true;
        }
        Test.stopTest();

        System.assert(exceptionOccured, 'Exception must have been thrown');
    }

    /**
    * @description test GetIndividualsLinkedToCase Empty List scenario
    * @author CRM Squad 2 | 11-23-2020 
    **/
    @isTest static void testGetIndividualsLinkedToCaseEmptyList(){

        Case expCase = [Select Id from Case where RecordType.Name='Close Contact' LIMIT 1];
        list<ELRelatedContactsController.ContactEncounterParticipantWrapper> wrapper = new list<ELRelatedContactsController.ContactEncounterParticipantWrapper>();
        
        Test.startTest();
        wrapper = ELRelatedContactsController.getIndividualsLinkedToCase(expCase.Id,'');
        Test.stopTest();

        System.assertEquals(0, wrapper.size(), 'No records should be returned if exposure record is not available');

    }
}