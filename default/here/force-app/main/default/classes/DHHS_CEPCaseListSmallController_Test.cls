@istest
public with sharing class DHHS_CEPCaseListSmallController_Test {

    //Test data creation
    @testSetup static void setup() {
    
        String recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc= new Account(RecordTypeID=recordTypeId, FirstName='Test FName', LastName='Test LName', PersonMailingStreet='test@yahoo.com', PersonMailingPostalCode='12345', PersonMailingCity='SFO', PersonEmail='test@yahoo.com', PersonHomePhone='1234567', PersonMobilePhone='+611234');
        insert acc;

        // Create Entitlement
        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;
        // Create Case
        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today()-7, Event_Date__c = System.Today()-14, EntitlementId = entl.Id);
        insert cse;

    }
    
    @isTest 
    static void getCasesTest()
    {
        
        Account acc = [SELECT Id from Account Where FirstName = 'Test FName' LIMIT 1];

        Test.startTest();
        List<Case> cases = DHHS_CEPCaseListSmallController.getCases(acc.Id, 'Default');
        Test.stopTest();
        
        System.assertEquals(1, cases.size(), 'getCases not returning correct number of cases for the given account Id');
    } 
    
     @isTest 
    static void getCasesByRecordNumber()
    {
        
        Account acc = [SELECT Id from Account Where FirstName = 'Test FName' LIMIT 1];

        Case caseRec  = [SELECT RecordType.Name, CaseNumber, Status, Day_0_Calculated__c, Event_Date__c FROM Case where AccountId = :acc.Id LIMIT 1];
        Test.startTest();
        List<Case> cases = DHHS_CEPCaseListSmallController.getCasesbyRecordNumber(caseRec.CaseNumber);
        system.debug(cases.size());
        List<Application_Log__c>  Log = [Select Id from Application_Log__c];
        system.debug(Log.size());
        Test.stopTest();
        
        System.assertEquals(0, Log.size(), 'cases for the given account Id');
    }

    @isTest 
    static void causeExceptionWithMetaData()
    {
        

        Account acc = [SELECT Id from Account Where FirstName = 'Test FName' LIMIT 1];

        Test.startTest();
        
        try{
            // pass a null to the metadata type
            List<Case> cases = DHHS_CEPCaseListSmallController.getCases(acc.Id, '');
        }catch (Exception e) {
            System.debug('Error1: ' +e.getMessage());
            Boolean expectedExceptionThrown =  e.getMessage().contains('Script-thrown exception') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        Test.stopTest();
        
        
    } 

    @isTest 
    static void causeExceptionGetCases()
    {
        
        Test.startTest();
        
        try{
            // pass in the wrong Id to cause an exception....
            List<Case> cases = DHHS_CEPCaseListSmallController.getCases(null, 'Default');
        }catch (Exception e) {
            System.debug('Error2: ' +e.getMessage());
            Boolean expectedExceptionThrown =  e.getMessage().contains('DHHS_CEPCaseListSmallController.getCases') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        Test.stopTest();
        
        
    } 

    

}