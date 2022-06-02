/**
 * @description       : Test class for AdvancedSearchService
 * @author            : CRM Squad 2
 * @group             : CRM Squad 2
 * @last modified on  : 12-13-2020
 * @last modified by  : CRM Squad 2
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   12-08-2020   CRM Squad 2   Initial Version
**/
@isTest
public with sharing class AdvancedSearchServiceTest {

    @testSetup static void testDataSetup() {

        //Create QA data for Case and Work Order - due to change from assignment rule to flow - US 240609
        TestDataFactory.createQAllocationForCaseRecordType();
        TestDataFactory.createQAllocationForWorkOrderRecordType();

        //Create Person Account
        List<Account> personAccList = TestDataFactory.createAccount(5, 'Active','Person Account');
        //Create Case
        List<Case> caseListConfirmed = TestDataFactory.createCases(personAccList.get(1), 5, 'Isolate', 'COVID-19 Case Assessment');
        //Create Case
        List<Case> caseListClose = TestDataFactory.createCases(personAccList.get(2), 5, 'Isolate', 'Close Contact');
    }

    /**
    * @description test Search  Full Search with Empty Criteria
    * @author CRM Squad 2 | 12-08-2020 
    **/
    @isTest static void testSearchWithEmptyCriteria(){

        String payload = '{'+
            '"recordNumber": "",'+
            '"firstName": "",'+
            '"middleName": "",'+
            '"lastName": "",'+
            '"dateOfBirth": "",'+
            '"mobile": "",'+
            '"homePhone": "",'+
            '"email": "" }';

        String recLimit = '100';
        String searchType = 'Individual';


        list<Case> caseList = new list<Case>();
        
        Test.startTest();
        caseList = (List<Case>) AdvancedSearchService.search(payload, recLimit, searchType);
        Test.stopTest();

        System.assertEquals(10, caseList.size(), 'Expected number of cases not returned');

    }

    /**
    * @description test Search Specific Case
    * @author CRM Squad 2 | 12-09-2020 
    **/
    @isTest static void testSearchSpecificRecordSearch(){

        Case confirmedCase = [Select Id, CaseNumber from Case where RecordType.Name='COVID-19 Case Assessment'  LIMIT 1];

        String payload = '{'+
            '"recordNumber":"'+confirmedCase.CaseNumber+'",'+
            '"firstName": "",'+
            '"middleName": "",'+
            '"lastName": "",'+
            '"dateOfBirth": "",'+
            '"mobile": "",'+
            '"homePhone": "",'+
            '"email": ""}';
        String recLimit = '100';
        String searchType = 'Individual';


        list<Case> caseList = new list<Case>();
        
        Test.startTest();
        caseList = (List<Case>)AdvancedSearchService.search(payload, recLimit, searchType);
        Test.stopTest();

        System.assertEquals(1, caseList.size(), 'Expected number of cases not returned');

    }

    /**
    * @description test Search With All SearchCriteria Search With Match
    * @author CRM Squad 2 | 12-09-2020 
    **/
    @isTest static void testSearchWithAllSerchCriteriaSearchWithMatch(){

        Case confirmedCase = [Select Id, CaseNumber from Case where RecordType.Name='COVID-19 Case Assessment'  LIMIT 1];

        String payload = '{'+
            '"recordNumber":"'+confirmedCase.CaseNumber+'",'+
            '"firstName": "Test",'+
             '"middleName": "",'+
            '"lastName": "Person Account",'+
            '"dateOfBirth": "",'+
            '"mobile": "611234",'+
            '"homePhone": "",'+
            '"email": "" }';

        String recLimit = '100';
        String searchType = 'Individual';


        list<Case> caseList = new list<Case>();
        
        Test.startTest();
        caseList = (List<Case>) AdvancedSearchService.search(payload, recLimit, searchType);
        Test.stopTest();

        System.assertEquals(1, caseList.size(), 'Expected number of cases not returned');

    }

    /**
    * @description test Search  With All SerchCriteria Search Without Match
    * @author CRM Squad 2 | 12-09-2020 
    **/
    @isTest static void testSearchWithAllSerchCriteriaSearchWithoutMatch(){

        Case confirmedCase = [Select Id, CaseNumber from Case where RecordType.Name='COVID-19 Case Assessment'  LIMIT 1];

        String payload = '{'+
            '"recordNumber":"'+confirmedCase.CaseNumber+'",'+
            '"firstName": "Test",'+
             '"middleName": "Test",'+
            '"lastName": "Person Account",'+
            '"dateOfBirth": "1980-05-05",'+
             '"mobile": "611234",'+
            '"homePhone": "034456",'+
            '"email": "test@test.com",'+
            '"selectedrecordTypes": "[\\"COVID_19_Case_Assessment\\",\\"Close_Contact\\"]" }';

        String recLimit = '100';
        String searchType = 'Individual';


        list<Case> caseList = new list<Case>();
        
        Test.startTest();
        caseList = (List<Case>) AdvancedSearchService.search(payload, recLimit, searchType);
        Test.stopTest();

        System.assertEquals(0, caseList.size(), 'Expected number of cases not returned');

    }

    /**
    * @description test Search With Exception
    * @author CRM Squad 2 | 12-11-2020 
    **/
    @isTest static void testSearchWithException(){

        Case confirmedCase = [Select Id, CaseNumber from Case where RecordType.Name='COVID-19 Case Assessment'  LIMIT 1];
        Boolean exceptionOccured = false;

        //Adding wrong date format which will throw exception
        String payload = '{'+
            '"recordNumber":"'+confirmedCase.CaseNumber+'",'+
            '"firstName": "Test",'+
             '"middleName": "",'+
            '"lastName": "Person Account",'+
            '"dateOfBirth": "05/05/1980",'+
            '"mobile": "611234"}';

        String recLimit = '100';
        String searchType = 'Individual';


        list<Case> caseList = new list<Case>();
        
        Test.startTest();

        try{
            caseList = (List<Case>) AdvancedSearchService.search(payload, recLimit, searchType);
        }catch(Exception e){
            exceptionOccured = true;
        }
        Test.stopTest();

        System.assert(exceptionOccured, 'Exception must have been thrown');

    }
    /**
    * @description test Search Specific Record Search RunAs HealthWorker
    * @author CRM Squad 2 | 12-11-2020 
    **/
    @isTest static void testSearchSpecificRecordSearchRunAsHealthWorker(){

        Case confirmedCase = [Select Id, CaseNumber from Case where RecordType.Name='COVID-19 Case Assessment'  LIMIT 1];
        User healthWorkerUser = TestDataFactory.createHealthWorkerUser();

        String payload = '{'+
            '"recordNumber":"'+confirmedCase.CaseNumber+'",'+
            '"firstName": "",'+
            '"middleName": "",'+
            '"lastName": "",'+
            '"dateOfBirth": "",'+
            '"mobile": ""}';

        String recLimit = '100';
        String searchType = 'Individual';


        list<Case> caseList = new list<Case>();
        System.runAs(healthWorkerUser){
            Test.startTest();
            caseList = (List<Case>)AdvancedSearchService.search(payload, recLimit, searchType);
            Test.stopTest();
        }

        System.assertEquals(1, caseList.size(), 'Expected number of cases not returned');

    }
}