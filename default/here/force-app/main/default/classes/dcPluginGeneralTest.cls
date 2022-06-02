/**
 * @Author             : Sten Ebenau (Plauti, Duplicate Check Vendor)
 * @Description        : Test class for dcPluginGeneral
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 04/02/2021     Sten Ebenau        Hotfix 258164: Initial version - Duplicate Check search performance improvement
 * 05/02/2021     Darko Jovanovic    Hotfix 258342: Incorporate custom merge rules
 * 19/02/2021     Gabriel Ludik		 Hotfix 261969: Change order for Case found by
 * 25/03/20201    Pratyush Chalasani Hotfix 266142,266294: Add rules for Contact hospital prior symptoms fields
 * 28/09/20201    Aref Samad         Feature 319580: Added Test method test_MergeSetFieldCaseForXHQFollowUpStatus to test 
 *                                                  merge records with 'Ex-HQ Follow up' status so that data is not lost during the merging process
 * 04/10/20201    Lija Jawahar       Feature:319578: Released clearance information test class
 * 25/11/2021    Aref S              PBI 318055 AC01:Update status/sub-status when 'contact' merged to PCC/SCC/CA 
**/
@isTest
private class dcPluginGeneralTest {
	
    static testMethod void test_Cache() {
        
        system.assert(new dcPluginGeneral().isAvailable(dupcheck.dc3Plugin.PluginEventType.CACHE_GET));
        system.assert(new dcPluginGeneral().isAvailable(dupcheck.dc3Plugin.PluginEventType.CACHE_PUT));
        
        Map<String, Object> inputCache = new Map<String, Object>();
        inputCache.put('cacheName', 'dcFieldMeta');
        
        system.assertEquals(null, new dcPluginGeneral().execute(dupcheck.dc3Plugin.PluginEventType.CACHE_GET, inputCache));
        
        inputCache.put('cacheData', 'Hallo');
        
        system.assertEquals(null, new dcPluginGeneral().execute(dupcheck.dc3Plugin.PluginEventType.CACHE_PUT, inputCache));
    }

    @isTest
    static void test_MergeSetFieldAccount() {
        // Create 7 accounts and set a different created date for them, in chronological order
        List<Account> personAccountList = TestDataFactory.createAccount(7, 'Active','Person Account');
        Test.setCreatedDate(personAccountList[0].Id, DateTime.newInstance(2013,12,12));
        Test.setCreatedDate(personAccountList[1].Id, DateTime.newInstance(2014,12,12));
        Test.setCreatedDate(personAccountList[2].Id, DateTime.newInstance(2015,12,12));
        Test.setCreatedDate(personAccountList[3].Id, DateTime.newInstance(2016,12,12));
        Test.setCreatedDate(personAccountList[4].Id, DateTime.newInstance(2017,12,12));
        Test.setCreatedDate(personAccountList[5].Id, DateTime.newInstance(2018,12,12));
        Test.setCreatedDate(personAccountList[6].Id, DateTime.newInstance(2019,12,12));
        // Set ABTSI flag for each
        personAccountList[0].Aboriginal_or_Torres_Strait_Islander__c = 'ABORIGINAL';
        personAccountList[0].Cultural_Support_Officer_Required__c = 'Yes';

        personAccountList[1].Aboriginal_or_Torres_Strait_Islander__c = 'BOTH';
        personAccountList[1].Cultural_Support_Officer_Required__c = 'Yes';

        personAccountList[2].Aboriginal_or_Torres_Strait_Islander__c = 'ABORIGINAL';
        personAccountList[2].Cultural_Support_Officer_Required__c = 'Yes';

        personAccountList[3].Aboriginal_or_Torres_Strait_Islander__c = '';
        personAccountList[4].Aboriginal_or_Torres_Strait_Islander__c = 'BOTH'; // this is the one that should be picked (highest priority, latest date of that priority)
        personAccountList[4].Cultural_Support_Officer_Required__c = 'Yes';

        personAccountList[5].Aboriginal_or_Torres_Strait_Islander__c = 'UNKNOWN';
        personAccountList[6].Aboriginal_or_Torres_Strait_Islander__c = 'UNKNOWN'; // this is the one that would've been picked by default merge rules (e.g. last created). However, it's not of highest priority so it should be overriden
        update personAccountList;
        Test.startTest();
        // Re-do the query to get created dates and all the other fields
        Map<Id, Account> recordByIdMap = new Map<Id, Account>();
        personAccountList = Database.query('SELECT ' + UtilityClass.getAllFieldsForQuery('Account') + ' FROM Account WHERE Id IN :personAccountList');
        for (Account acc : personAccountList) {
            recordByIdMap.put(acc.Id, acc);
        }
        // Set the default result of the merge rules (last created)
        Map<String, Id> defaultResultMap = new Map<String, Id>();
        for (String fieldAPIName : UtilityClass.getAllFields('Account')) {
            defaultResultMap.put(fieldAPIName, personAccountList[6].Id);
        }
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', personAccountList[0].Id, defaultResultMap, personAccountList);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = 
            (dupcheck.dc3PluginModel.MergeSetFieldOutput) new dcPluginGeneral().execute(dupcheck.dc3Plugin.PluginEventType.MERGE_SET_FIELD, input);
        Test.stopTest();
        System.assertEquals(personAccountList[4].Id, output.fieldSourceMap.get('Aboriginal_or_Torres_Strait_Islander__c'));
    }

    @isTest
    static void test_MergeSetFieldCase() {
        // Create 1 accounts and set a different created date for them, in chronological order
        Account personAccount = TestDataFactory.createAccount(1, 'Active','Person Account')[0];
        // Create 3 cases for the account
        List<Case> caseList = new List<Case>();
        Case screeningCase      = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Active', 'COVID-19 Case Screening')[0];
        screeningCase.SubStatus__c = null;
        insert screeningCase;

        Case assessmentCase     = TestDataFactory.createCases(personAccount, 1, 'Isolate', 'COVID-19 Case Assessment')[0]; // record type of this one should be selected
        Case closeContactCase   = TestDataFactory.createCases(personAccount, 1, 'Identify', 'Close Contact')[0];
        
        caseList.add(screeningCase);
        caseList.add(assessmentCase);
        caseList.add(closeContactCase);
        Test.setCreatedDate(caseList[0].Id, DateTime.newInstance(2013,12,12));
        Test.setCreatedDate(caseList[1].Id, DateTime.newInstance(2014,12,12));
        Test.setCreatedDate(caseList[2].Id, DateTime.newInstance(2015,12,12));
        Test.startTest();
        // Re-do the query to get created dates and all the other fields
        Map<Id, Case> recordByIdMap = new Map<Id, Case>();
        caseList = Database.query('SELECT ' + UtilityClass.getAllFieldsForQuery('Case') + ' FROM Case WHERE Id IN :caseList');
        for (Case caseRec : caseList) {
            recordByIdMap.put(caseRec.Id, caseRec);
        }
        // Set the default result of the merge rules (last created)
        Map<String, Id> defaultResultMap = new Map<String, Id>();
        for (String fieldAPIName : UtilityClass.getAllFields('Case')) {
            defaultResultMap.put(fieldAPIName, caseList[2].Id);
        }
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('500', caseList[0].Id, defaultResultMap, caseList);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = 
            (dupcheck.dc3PluginModel.MergeSetFieldOutput) new dcPluginGeneral().execute(dupcheck.dc3Plugin.PluginEventType.MERGE_SET_FIELD, input);
        Test.stopTest();
        System.assertEquals(caseList[1].RecordTypeId, output.customValueMap.get('RecordTypeId'));
    }
    
    @isTest
    static void test_ABTSIPrecedence() {
        dcPluginGeneral.ABTSIPrecedence precedenceObj = new dcPluginGeneral.ABTSIPrecedence();
        System.assertEquals(2, precedenceObj.getFieldPrecedence('UNKNOWN'));
        System.assertEquals(1, precedenceObj.getFieldPrecedence('OTHERVALUE'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }

    @isTest
    static void test_InterpreterReqPrecedence() {
        dcPluginGeneral.InterpreterReqPrecedence precedenceObj = new dcPluginGeneral.InterpreterReqPrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence('Yes'));
        System.assertEquals(2, precedenceObj.getFieldPrecedence('No'));
        System.assertEquals(3, precedenceObj.getFieldPrecedence('Unknown'));
        System.assertEquals(4, precedenceObj.getFieldPrecedence('Not stated'));
        System.assertEquals(5, precedenceObj.getFieldPrecedence('Not applicable'));
        System.assertEquals(6, precedenceObj.getFieldPrecedence('OTHERVALUE'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }

    @isTest
    static void test_ReqSpecialHandlingPrecedence() {
        dcPluginGeneral.ReqSpecialHandlingPrecedence precedenceObj = new dcPluginGeneral.ReqSpecialHandlingPrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence('Yes'));
        System.assertEquals(2, precedenceObj.getFieldPrecedence('OTHERVALUE'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }

    @isTest
    static void test_CaseRecordTypePrecedence() {
        Map<Id, Schema.RecordTypeInfo> caseRecordTypes = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosById();
        Map<String, Id> recordTypeIdByDeveloperName = new Map<String, Id>();
        for (Id recordTypeId : caseRecordTypes.keySet())
        {
            Schema.RecordTypeInfo recType = caseRecordTypes.get(recordTypeId);
            recordTypeIdByDeveloperName.put(recType.getDeveloperName(), recordTypeId);
        }
        dcPluginGeneral.CaseRecordTypePrecedence precedenceObj = new dcPluginGeneral.CaseRecordTypePrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence(recordTypeIdByDeveloperName.get('COVID_19_Case_Assessment')));
        System.assertEquals(2, precedenceObj.getFieldPrecedence(recordTypeIdByDeveloperName.get('Close_Contact')));
        System.assertEquals(3, precedenceObj.getFieldPrecedence(recordTypeIdByDeveloperName.get('Secondary_Close_Contact')));
        System.assertEquals(4, precedenceObj.getFieldPrecedence(recordTypeIdByDeveloperName.get('Casual_Contact')));
        System.assertEquals(5, precedenceObj.getFieldPrecedence(recordTypeIdByDeveloperName.get('Acquisition_Contact')));
        System.assertEquals(6, precedenceObj.getFieldPrecedence(recordTypeIdByDeveloperName.get('COVID_19_Case_Screening')));
        System.assertEquals(7, precedenceObj.getFieldPrecedence(recordTypeIdByDeveloperName.get('Unclassified_Contact')));
        System.assertEquals(8, precedenceObj.getFieldPrecedence(recordTypeIdByDeveloperName.get('Outbreak')));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }

    @isTest
    static void test_CaseFoundByPrecedence() {
        dcPluginGeneral.CaseFoundByPrecedence precedenceObj = new dcPluginGeneral.CaseFoundByPrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence('Contact Tracing'));
        System.assertEquals(2, precedenceObj.getFieldPrecedence('Clinical Presentation'));
        System.assertEquals(3, precedenceObj.getFieldPrecedence('Screening'));
        System.assertEquals(4, precedenceObj.getFieldPrecedence('Non-Victorian Diagnosis'));
        System.assertEquals(5, precedenceObj.getFieldPrecedence('Outbreak Investigation'));
        System.assertEquals(6, precedenceObj.getFieldPrecedence('Serology'));
        System.assertEquals(7, precedenceObj.getFieldPrecedence('Clinical and epidemiology'));
        System.assertEquals(8, precedenceObj.getFieldPrecedence('Routine Follow-Up'));
        System.assertEquals(9, precedenceObj.getFieldPrecedence('Undertaking'));
        System.assertEquals(10, precedenceObj.getFieldPrecedence('Unknown or blank'));
        System.assertEquals(11, precedenceObj.getFieldPrecedence('External Contact Tracing'));
        System.assertEquals(12, precedenceObj.getFieldPrecedence('OTHERVALUE'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }

    @isTest
    static void test_EpiClassificationPrecedence() {
        dcPluginGeneral.EpiClassificationPrecedence precedenceObj = new dcPluginGeneral.EpiClassificationPrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence('Epidemiologically linked to a laboratory confirmed case'));
        System.assertEquals(2, precedenceObj.getFieldPrecedence('Secondary Contact - External follow up'));
        System.assertEquals(3, precedenceObj.getFieldPrecedence('Secondary Contact - Internal follow up'));
        System.assertEquals(4, precedenceObj.getFieldPrecedence('Part of cluster'));
        System.assertEquals(5, precedenceObj.getFieldPrecedence('Outbreak'));
        System.assertEquals(6, precedenceObj.getFieldPrecedence('Sporadic case'));
        System.assertEquals(7, precedenceObj.getFieldPrecedence('OTHERVALUE'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }

    @isTest
    static void test_EventClassificationPrecedence() {
        dcPluginGeneral.EventClassificationPrecedence precedenceObj = new dcPluginGeneral.EventClassificationPrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence('Confirmed'));
        System.assertEquals(2, precedenceObj.getFieldPrecedence('Suspected'));
        System.assertEquals(3, precedenceObj.getFieldPrecedence('At Risk'));
        System.assertEquals(4, precedenceObj.getFieldPrecedence('Not notifiable'));
        System.assertEquals(5, precedenceObj.getFieldPrecedence('Probable'));
        System.assertEquals(6, precedenceObj.getFieldPrecedence('Rejected'));
        System.assertEquals(7, precedenceObj.getFieldPrecedence('OTHERVALUE'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }

    @isTest
    static void test_EventTypePrecedence() {
        dcPluginGeneral.EventTypePrecedence precedenceObj = new dcPluginGeneral.EventTypePrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence('Case'));
        System.assertEquals(2, precedenceObj.getFieldPrecedence('Contact/exposed person'));
        System.assertEquals(3, precedenceObj.getFieldPrecedence('Control'));
        System.assertEquals(4, precedenceObj.getFieldPrecedence('Study Participant'));
        System.assertEquals(5, precedenceObj.getFieldPrecedence('Sample'));
        System.assertEquals(6, precedenceObj.getFieldPrecedence('OTHERVALUE'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }

    @isTest
    static void test_PriorityPrecedence() {
        dcPluginGeneral.PriorityPrecedence precedenceObj = new dcPluginGeneral.PriorityPrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence('High'));
        System.assertEquals(2, precedenceObj.getFieldPrecedence('Medium'));
        System.assertEquals(3, precedenceObj.getFieldPrecedence('Low'));
        System.assertEquals(4, precedenceObj.getFieldPrecedence('OTHERVALUE'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }

    @isTest
    static void test_TravelOs14DaysPrecedence() {
        dcPluginGeneral.TravelOs14DaysPrecedence precedenceObj = new dcPluginGeneral.TravelOs14DaysPrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence('Yes'));
        System.assertEquals(2, precedenceObj.getFieldPrecedence('No'));
        System.assertEquals(3, precedenceObj.getFieldPrecedence('Unknown'));
        System.assertEquals(4, precedenceObj.getFieldPrecedence('Not stated'));
        System.assertEquals(5, precedenceObj.getFieldPrecedence('Not applicable'));
        System.assertEquals(6, precedenceObj.getFieldPrecedence('OTHERVALUE'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }

    @isTest
    static void test_WuhanTravelPrecedence() {
        dcPluginGeneral.WuhanTravelPrecedence precedenceObj = new dcPluginGeneral.WuhanTravelPrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence('Yes'));
        System.assertEquals(2, precedenceObj.getFieldPrecedence('No'));
        System.assertEquals(3, precedenceObj.getFieldPrecedence('Unknown'));
        System.assertEquals(4, precedenceObj.getFieldPrecedence('Not stated'));
        System.assertEquals(5, precedenceObj.getFieldPrecedence('Not applicable'));
        System.assertEquals(6, precedenceObj.getFieldPrecedence('OTHERVALUE'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }
    
 
    @isTest
    static void test_ContactHospitalPriorSymptomsPrecedence() {
        dcPluginGeneral.ContactHospitalPriorSymptomsPrecedence precedenceObj = new dcPluginGeneral.ContactHospitalPriorSymptomsPrecedence();
        System.assertEquals(1, precedenceObj.getFieldPrecedence('Yes'));
        System.assertEquals(2, precedenceObj.getFieldPrecedence('No'));
        System.assertEquals(3, precedenceObj.getFieldPrecedence('Not stated'));
        System.assertEquals(4, precedenceObj.getFieldPrecedence('Not applicable'));
        System.assertEquals(5, precedenceObj.getFieldPrecedence('Unknown'));
        System.assertEquals(999, precedenceObj.getFieldPrecedence(null));
    }


    /**
    * @description Test method to test Ex-Hq Follow-up status for de dup merge (Feature 319580)
    * @author Aref Samad | 28/09/2021 
    **/
    @isTest
    static void test_MergeSetFieldCaseForXHQFollowUpStatus() {
        
        //given

        // Create 1 accounts and set a different created date for them, in chronological order
        Account personAccount = TestDataFactory.createAccount(1, 'Active','Person Account')[0];
        // Create 3 cases for the account
        List<Case> caseList = new List<Case>();
        
        Case sccCase     = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Identify', 'Secondary Close Contact')[0]; 
        sccCase.Day_0_Exposure_to_primarycc__c = Date.newInstance(2021,9,13);
        sccCase.SubStatus__c = null;
        insert sccCase; 
        
        Case sccCase2     = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Identify', 'Secondary Close Contact')[0]; 
        sccCase2.Day_0_Exposure_to_primarycc__c = Date.newInstance(2021,9,13);
        sccCase2.SubStatus__c = null;
        insert sccCase2; 

        Case sccCase3     = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Closed', 'Secondary Close Contact')[0]; 
        sccCase3.Day_0_Exposure_to_primarycc__c = Date.newInstance(2021,9,13);
        sccCase3.SubStatus__c = null;
        insert sccCase3; 
        
        Case closeContactCase      = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Quarantine', 'Close Contact')[0];// record type of this one should be selected
        closeContactCase.Day_0_Exposure_to_the_confirmed_case__c = Date.newInstance(2021,9,11);
        closeContactCase.SubStatus__c = null;
        insert closeContactCase;        

        Case casualContactCase   = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Ex-HQ Follow-up', 'Casual Contact')[0]; // statatus of this one should be selected
        casualContactCase.Day_0_Exposure_to_the_confirmed_case__c = Date.newInstance(2021,9,15);
        casualContactCase.HQ_Resident__c = true;
        casualContactCase.SubStatus__c = null;
        insert casualContactCase;        
        
        caseList.add(sccCase);
        caseList.add(closeContactCase);
        caseList.add(casualContactCase);

        Test.setCreatedDate(caseList[0].Id, DateTime.newInstance(2021,9,25));
        Test.setCreatedDate(caseList[1].Id, DateTime.newInstance(2021,9,26));
        Test.setCreatedDate(caseList[2].Id, DateTime.newInstance(2021,9,27));        
       
        Test.startTest();
        //When

        // Re-do the query to get created dates and all the other fields
        Map<Id, Case> recordByIdMap = new Map<Id, Case>();
        caseList = Database.query('SELECT ' + UtilityClass.getAllFieldsForQuery('Case') + ' FROM Case WHERE Id IN :caseList');
        for (Case caseRec : caseList) {
            recordByIdMap.put(caseRec.Id, caseRec);
        }
        // Set the default result of the merge rules (last created)
        Map<String, Id> defaultResultMap = new Map<String, Id>();
        for (String fieldAPIName : UtilityClass.getAllFields('Case')) {
            defaultResultMap.put(fieldAPIName, caseList[2].Id);
        }
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('500', caseList[0].Id, defaultResultMap, caseList);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = 
            (dupcheck.dc3PluginModel.MergeSetFieldOutput) new dcPluginGeneral().execute(dupcheck.dc3Plugin.PluginEventType.MERGE_SET_FIELD, input);

        Test.stopTest();

        //Then
        System.assertEquals(caseList[1].RecordTypeId, output.customValueMap.get('RecordTypeId'),'Record type not merged correctly');
        System.assertEquals(caseList[2].Id, output.fieldSourceMap.get('Status'),'Status not merged correctly');
    }
   
    /**
    * @description Test method to test release clearance(Feature 319578)
    **/
    @isTest
    static void test_Releaseclearance() {
        
        //given

        // Create 1 accounts and set a different created date for them, in chronological order
        Account personAccount = TestDataFactory.createAccount(1, 'Active','Person Account')[0];
        // Create 3 cases for the account
        List<Case> caseList = new List<Case>();
        
        Case sccCase     = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Quarantine', 'Close Contact')[0]; 
        sccCase.Day_0_Exposure_to_primarycc__c = Date.newInstance(2021,9,13);
        sccCase.SubStatus__c = null;
        sccCase.Case_Cleared_from_Isolation__c = 'No';
        sccCase.Has_Clearance_Letter_Been_Sent__c = 'No';
        insert sccCase; 
        
        Case sccCase2     = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Quarantine', 'Close Contact')[0]; 
        sccCase2.Day_0_Exposure_to_primarycc__c = Date.newInstance(2021,9,13);
        sccCase2.SubStatus__c = null;
        sccCase2.Case_Cleared_from_Isolation__c = 'No';
        sccCase2.Has_Clearance_Letter_Been_Sent__c = 'No';
        insert sccCase2; 

        Case sccCase3     = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Closed', 'Close Contact')[0]; 
        sccCase3.Day_0_Exposure_to_primarycc__c = Date.newInstance(2021,9,13);
        sccCase3.SubStatus__c = null;
        sccCase3.Case_Cleared_from_Isolation__c = 'Yes';
        sccCase3.Has_Clearance_Letter_Been_Sent__c = 'Yes';
        //sccCase3.Date_Cleared_from_Isolation__c = DateTime.newInstance(2021,9,13);
        insert sccCase3; 
        
            
        
        caseList.add(sccCase);
        caseList.add(sccCase2);
        caseList.add(sccCase3);

        Test.setCreatedDate(caseList[0].Id, DateTime.newInstance(2021,9,25));
        Test.setCreatedDate(caseList[1].Id, DateTime.newInstance(2021,9,26));
        Test.setCreatedDate(caseList[2].Id, DateTime.newInstance(2021,9,27));        
       
        Test.startTest();
        //When

        // Re-do the query to get created dates and all the other fields
        Map<Id, Case> recordByIdMap = new Map<Id, Case>();
        caseList = Database.query('SELECT ' + UtilityClass.getAllFieldsForQuery('Case') + ' FROM Case WHERE Id IN :caseList');
        for (Case caseRec : caseList) {
            recordByIdMap.put(caseRec.Id, caseRec);
        }
        // Set the default result of the merge rules (last created)
        Map<String, String> defaultResultMap = new Map<String, String>();
        for (String fieldAPIName : UtilityClass.getAllFields('Case')) {
            defaultResultMap.put(fieldAPIName, caseList[2].Id);
        }
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('500', caseList[0].Id, defaultResultMap, caseList);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = (dupcheck.dc3PluginModel.MergeSetFieldOutput) new dcPluginGeneral().execute(dupcheck.dc3Plugin.PluginEventType.MERGE_SET_FIELD, input);

        system.debug ('caseList[1].RecordTypeId -->' + caseList[1].RecordTypeId);
        system.debug ('output.customValueMap.get-->'+ output.customValueMap.get('RecordTypeId'));
        Test.stopTest();
                //Then
        //System.assertEquals(caseList[1].RecordTypeId, output.customValueMap.get('RecordTypeId'));
        //System.assertEquals(caseList[1].RecordTypeId, output.customValueMap.get('RecordTypeId'),'Record type not merged correctly');
        //System.assertEquals(caseList[2].Id, output.fieldSourceMap.get('Status'),'Status not merged correctly');
    }


    
     /**
    * @description Update status/sub-status when 'contact' merged to PCC/SCC/CA (PBI 318055 AC01)
    * @author Aref Samad | 25/11/2021 
    **/
    @isTest
    static void test_CaseForOtherContactToPCCOrSCCStatus() {
        
        //given

        // Create 1 accounts and set a different created date for them, in chronological order
        Account personAccount = TestDataFactory.createAccount(1, 'Active','Person Account')[0];
        // Create 3 cases for the account
        List<Case> caseList = new List<Case>();
        
        Case ccCase     = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Quarantine', 'Close Contact')[0];         
        ccCase.SubStatus__c = null;
        insert ccCase; 
       

        Case casualContactCase   = TestDataFactory.createCasesNoInsert(personAccount, 1, 'Active', 'Casual Contact')[0]; // statatus of this one should be selected       
        casualContactCase.SubStatus__c = null;
        insert casualContactCase;        
        
        caseList.add(ccCase);       
        caseList.add(casualContactCase);

        Test.setCreatedDate(caseList[0].Id, DateTime.newInstance(2021,9,25));
        Test.setCreatedDate(caseList[1].Id, DateTime.newInstance(2021,9,26));      
       
        Test.startTest();
        //When

        // Re-do the query to get created dates and all the other fields
        Map<Id, Case> recordByIdMap = new Map<Id, Case>();
        caseList = Database.query('SELECT ' + UtilityClass.getAllFieldsForQuery('Case') + ' FROM Case WHERE Id IN :caseList');
        for (Case caseRec : caseList) {
            recordByIdMap.put(caseRec.Id, caseRec);
        }
        // Set the default result of the merge rules (last created)
        Map<String, Id> defaultResultMap = new Map<String, Id>();
        for (String fieldAPIName : UtilityClass.getAllFields('Case')) {
            defaultResultMap.put(fieldAPIName, caseList[1].Id);
        }
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('500', caseList[0].Id, defaultResultMap, caseList);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = 
            (dupcheck.dc3PluginModel.MergeSetFieldOutput) new dcPluginGeneral().execute(dupcheck.dc3Plugin.PluginEventType.MERGE_SET_FIELD, input);

        Test.stopTest();

        //Then
        System.assertEquals('Identify',output.customValueMap.get('Status'), 'Status not merged correctly');
        System.assertEquals('In Progress',output.customValueMap.get('SubStatus__c'), 'Sub Status not merged correctly');
    }


}