/**
 * @Author             : Pratyush Chalasani (Contino)
 * @Description        : Base class for record comparison, where simple precedence rules are not enough.
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date          Author      		   Details
 * ---------------------------------------------------
 * 25/03/2021    Pratyush Chalasani    Initial Version
 * 07/04/2021    Pratyush Chalasani    Hotfix 275362: Merge records is not taking last created date rule into consideration for Country of Birth and Sex field
 * 08/04/2021    Pratyush Chalasani    Hotfix 266306: Refactored initialising code, and added extra test methods
 * 12/04/2021    Pratyush Chalasani    Hotfix 275639-276133: Updated tests for Merge defects
 * 30/04/2021    Pratyush Chalasani    Updated test Account creation to use PersonAccount
 * 05/10/2021    Pratyush Chalasani    Feature 321606: Marketing Cloud - Merge Rules for Marketing Cloud Day 0 flag
**/
@isTest
private class dcPluginComparatorAbstractTest {
    static User IntegrationUser, ADFService;

    static Map<String, Id> userMap = new Map<String, Id>();
    static Map<String, Id> recordTypeMap = new Map<String, Id>();

    private static void init() {
        for (User u: [SELECT Id, Name, Profile.Name FROM User WHERE IsActive = true]) {
            if (u.Name == 'Integration User' && u.Profile.Name == 'Integration User') IntegrationUser = u;
            if (u.Name == 'ADF Service') ADFService = u;

            // Skip if it's the wrong type of Integration User
            if (u.Name == 'Integration User' && u.Profile.Name != 'Integration User') continue;

            userMap.put(u.Name, u.Id);
        }
        
        Map<String, Schema.RecordTypeInfo> recordTypeInfo = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        for (String recTypeName: recordTypeInfo.keySet()) {
            Schema.RecordTypeInfo info = recordTypeInfo.get(recTypeName);

            recordTypeMap.put(recTypeName, info.getRecordTypeId());
        }
    }

    @isTest
    static void testCreatedDate() {
        init();

        // Create accounts with the same user but different CreatedDate values
        // person2 should be recorded as created 1 day after person1
        Account person1 = TestDataFactory.createAccount(1, 'Active', 'Person Account', System.now().addDays(-1))[0];
        Account person2 = TestDataFactory.createAccount(1, 'Active', 'Person Account', System.now())[0];
        
        // Precedence for these values is the same
        person1.Sex__pc = 'Male';
        person2.Sex__pc = 'Female';

        update person1;
        update person2;

        Test.startTest();

        dcPluginGeneral.SexComparator comparator = new dcPluginGeneral.SexComparator(userMap);

        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Sex__pc', person1.Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', person1.Id, defaultResultMap, new SObject[]{person1, person2});
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(person1, new SObject[]{person2}, 'Sex__pc', output);

        Id masterID = output.fieldSourceMap.get('Sex__pc');

        // Check that the newer created record is used as the reference for the field value
        System.assertEquals(person2.Id, masterID, '"Female" should take precedence since the record was created later');

        Test.stopTest();
    }

    @isTest
    static void testSexComparator() {
        init();

        List<Account> people = TestDataFactory.createAccount(2, 'Active', 'Person Account');
        
        people[0].Sex__pc = 'Male';
        people[1].Sex__pc = 'Female';

        update people[0];

        System.runAs(ADFService) {
            update people[1];
        }

        Test.startTest();

        dcPluginGeneral.SexComparator comparator = new dcPluginGeneral.SexComparator(userMap);

        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Sex__pc', people[1].Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', people[0].Id, defaultResultMap, people);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(people[0], new SObject[]{people[1]}, 'Sex__pc', output);

        Id masterID = output.fieldSourceMap.get('Sex__pc');

        System.assertEquals(people[0].Id, masterID, '"Male" should take precedence since it was updated by a user other than ADFService');

        Test.stopTest();
    }

    @isTest
    static void testLanguageSpokenAtHomeComparator() {
        init();

        List<Account> people = TestDataFactory.createAccount(2, 'Active', 'Person Account');
        
        people[0].Language_spoken_at_home__c = 'Bosnian';
        people[1].Language_spoken_at_home__c = 'Catalan';

        update people[0];

        System.runAs(ADFService) {
            update people[1];
        }

        Test.startTest();

        dcPluginGeneral.LanguageSpokenAtHomeComparator comparator = new dcPluginGeneral.LanguageSpokenAtHomeComparator(userMap);

        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Language_spoken_at_home__c', people[1].Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', people[0].Id, defaultResultMap, people);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(people[0], new SObject[]{people[1]}, 'Language_spoken_at_home__c', output);

        Id masterID = output.fieldSourceMap.get('Language_spoken_at_home__c');

        System.assertEquals(people[0].Id, masterID, '"Bosnian" should take precedence since it was updated by a user other than ADFService');

        Test.stopTest();
    }

    @isTest
    static void testCountryOfBirthComparator() {
        init();

        List<Account> people = TestDataFactory.createAccount(2, 'Active', 'Person Account');
        
        people[0].Country_of_birth__c = 'AUS';
        people[1].Country_of_birth__c = 'ALB';

        update people[0];

        System.runAs(ADFService) {
            update people[1];
        }

        Test.startTest();

        dcPluginGeneral.CountryOfBirthComparator comparator = new dcPluginGeneral.CountryOfBirthComparator(userMap);

        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Country_of_birth__c', people[1].Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', people[0].Id, defaultResultMap, people);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(people[0], new SObject[]{people[1]}, 'Country_of_birth__c', output);

        Id masterID = output.fieldSourceMap.get('Country_of_birth__c');

        System.assertEquals(people[0].Id, masterID, '"AUS" should take precedence since it was updated by a user other than ADFService');

        Test.stopTest();
    }

    @isTest
    static void testRecordOwnerComparator() {
        init();

        List<Account> accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        List<Case> case1  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact');
        List<Case> case2  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Secondary Close Contact');

        List<Case> cases = new Case[]{case1[0], case2[0]};

        insert cases;

        Test.startTest();

        dcPluginGeneral.RecordOwnerComparator comparator = new dcPluginGeneral.RecordOwnerComparator(userMap, recordTypeMap);

        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('OwnerId', cases[1].Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', cases[0].Id, defaultResultMap, cases);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(cases[0], new SObject[]{cases[1]}, 'OwnerId', output);

        Id masterID = output.fieldSourceMap.get('OwnerId');

        System.assertEquals(cases[0].Id, masterID);

        Test.stopTest();
    }

    @isTest
    static void testStatusComparator() {
        init();

        List<Account> accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        Case case1  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Trace', 'COVID-19 Case Assessment')[0];
        Case case2  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Trace', 'COVID-19 Case Assessment')[0];

        case1.Event_Date__c = System.now().addDays(-1);
        case2.Event_Date__c = System.now();

        List<Case> assessCases = new Case[]{case1, case2};

        insert assessCases;

        Case case3  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact')[0];
        Case case4  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact')[0];

        case3.Symptoms_Onset_Date__c = System.today().addDays(1);
        case4.Symptoms_Onset_Date__c = System.today();

        List<Case> pccCases = new Case[]{case3, case4};

        insert pccCases;

        Test.startTest();

        // Confirmed Case

        dcPluginGeneral.StatusComparator comparator = new dcPluginGeneral.StatusComparator(recordTypeMap);

        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Status', assessCases[1].Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', assessCases[0].Id, defaultResultMap, assessCases);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(assessCases[0], new SObject[]{assessCases[1]}, 'Status', output);

        Id masterID = output.fieldSourceMap.get('Status');

        // PCC

        System.assertEquals(assessCases[0].Id, masterID);

        defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Status', pccCases[1].Id);
        input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', pccCases[0].Id, defaultResultMap, pccCases);
        output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(pccCases[0], new SObject[]{pccCases[1]}, 'Status', output);

        masterID = output.fieldSourceMap.get('Status');

        System.assertEquals(pccCases[0].Id, masterID);

        Test.stopTest();
    }

    @isTest
    static void testSubStatusComparator() {
        init();

        List<Account> accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        Case case1  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Closed', 'COVID-19 Case Assessment')[0];
        Case case2  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Closed', 'Close Contact')[0];

        case1.SubStatus__c = 'Release';
        case2.SubStatus__c = 'Release';

        case1.Event_Date__c = System.now().addDays(-1);
        case2.Event_Date__c = System.now();

        List<Case> assessCases = new Case[]{case1, case2};

        insert assessCases;

        Case case3  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Closed', 'Close Contact')[0];
        Case case4  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Closed', 'Secondary Close Contact')[0];

        case3.SubStatus__c = 'Release';
        case4.SubStatus__c = 'Release';

        case3.Symptoms_Onset_Date__c = System.today().addDays(1);
        case4.Symptoms_Onset_Date__c = System.today();

        List<Case> pccCases = new Case[]{case3, case4};

        insert pccCases;

        Test.startTest();

        // Confirmed Case

        dcPluginGeneral.SubStatusComparator comparator = new dcPluginGeneral.SubStatusComparator(recordTypeMap);

        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Status', assessCases[1].Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', assessCases[0].Id, defaultResultMap, assessCases);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(assessCases[0], new SObject[]{assessCases[1]}, 'SubStatus__c', output);

        Id masterID = output.fieldSourceMap.get('SubStatus__c');

        System.assertEquals(assessCases[0].Id, masterID);

        // PCC

        defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Status', pccCases[1].Id);
        input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', pccCases[0].Id, defaultResultMap, pccCases);
        output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(pccCases[0], new SObject[]{pccCases[1]}, 'SubStatus__c', output);

        masterID = output.fieldSourceMap.get('SubStatus__c');

        System.assertEquals(pccCases[0].Id, masterID);

        Test.stopTest();
    }

    @isTest
    static void testInitialInterviewCompletedTimeComparator() {
        init();

        List<Account> accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        Case case1  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Trace', 'COVID-19 Case Assessment')[0];
        Case case2  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Trace', 'COVID-19 Case Assessment')[0];

        case1.Initial_Interview_Completed_Time__c = System.now().addDays(-1);
        case2.Initial_Interview_Completed_Time__c = System.now();

        List<Case> assessCases = new Case[]{case1, case2};

        insert assessCases;

        Case case3  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact')[0];
        Case case4  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact')[0];

        // Older Case
        case3.CreatedDate = System.now().addDays(-1);
        case3.LastModifiedDate = System.now().addDays(-1);
        case3.Initial_Interview_Completed_Time__c = System.now().addDays(-1);

        // Newer Case
        case4.Initial_Interview_Completed_Time__c = System.now();
        case4.Day_0_Exposure_to_the_confirmed_case__c = System.today();

        List<Case> pccCases = new Case[]{case3, case4};

        insert pccCases;

        Test.startTest();

        // Confirmed Case

        dcPluginGeneral.InitialInterviewCompletedTimeComparator comparator = new dcPluginGeneral.InitialInterviewCompletedTimeComparator(recordTypeMap);

        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Initial_Interview_Completed_Time__c', assessCases[1].Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('500', assessCases[0].Id, defaultResultMap, assessCases);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(assessCases[0], new SObject[]{assessCases[1]}, 'Initial_Interview_Completed_Time__c', output);

        Id masterID = output.fieldSourceMap.get('Initial_Interview_Completed_Time__c');

        System.assertEquals(assessCases[0].Id, masterID);

        // PCC

        defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Initial_Interview_Completed_Time__c', pccCases[1].Id);
        input = new dupcheck.dc3PluginModel.MergeSetFieldInput('500', pccCases[0].Id, defaultResultMap, pccCases);
        output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(pccCases[0], new SObject[]{pccCases[1]}, 'Initial_Interview_Completed_Time__c', output);

        masterID = output.fieldSourceMap.get('Initial_Interview_Completed_Time__c');

        System.assertEquals(pccCases[0].Id, masterID);

        Test.stopTest();
    }

    @isTest
    static void testInitialInterviewCompletedCheckboxComparator() {
        init();

        List<Account> accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        Case case1  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Trace', 'COVID-19 Case Assessment')[0];
        Case case2  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact')[0];

        case1.Initial_Interview_Completed_Time__c = System.now().addDays(-1);
        case2.Initial_Interview_Completed_Time__c = System.now();

        List<Case> assessCases = new Case[]{case1, case2};

        insert assessCases;

        Case case3  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact')[0];
        Case case4  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact')[0];

        // Older Case
        case3.CreatedDate = System.now().addDays(-1);
        case3.LastModifiedDate = System.now().addDays(-1);
        case3.Initial_Interview_Completed_Time__c = System.now().addDays(-1);

        // Newer Case
        case4.Initial_Interview_Completed_Time__c = System.now();
        case4.Day_0_Exposure_to_the_confirmed_case__c = System.today();

        List<Case> pccCases = new Case[]{case3, case4};

        insert pccCases;

        Test.startTest();

        dcPluginGeneral.InitialInterviewCompletedCheckboxComparator comparator = new dcPluginGeneral.InitialInterviewCompletedCheckboxComparator(recordTypeMap);

        // Confirmed Case

        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Initial_Interview_completed__c', assessCases[1].Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('500', assessCases[0].Id, defaultResultMap, assessCases);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(assessCases[0], new SObject[]{assessCases[1]}, 'Initial_Interview_completed__c', output);

        Id masterID = output.fieldSourceMap.get('Initial_Interview_completed__c');

        System.assertEquals(assessCases[0].Id, masterID);

        // PCC

        defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Initial_Interview_completed__c', pccCases[1].Id);
        input = new dupcheck.dc3PluginModel.MergeSetFieldInput('500', pccCases[0].Id, defaultResultMap, pccCases);
        output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(pccCases[0], new SObject[]{pccCases[1]}, 'Initial_Interview_completed__c', output);

        String setInitialInterview = (String)output.customValueMap.get('Set_Initial_Interview__c');

        System.assertEquals('F', setInitialInterview);

        Test.stopTest();
    }

    @isTest
    static void testMCDay0PicklistComparator() {
        init();

        List<Account> accs = TestDataFactory.createAccount(1, 'Active', 'Person Account');

        Case case1  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Trace', 'COVID-19 Case Assessment')[0];
        Case case2  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact')[0];

        case1.Marketing_Cloud_PCC_Day_0__c = 'PCC Day 0 Sent';
        case2.Marketing_Cloud_PCC_Day_0__c = 'Red Permit Day 0 Sent';

        List<Case> assessCases = new Case[]{case1, case2};

        insert assessCases;

        Case case3  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact')[0];
        Case case4  = TestDataFactory.createCasesNoInsert(accs[0], 1, 'Identify', 'Close Contact')[0];

        case3.Marketing_Cloud_PCC_Day_0__c = null;
        case4.Marketing_Cloud_PCC_Day_0__c = 'PCC Day 0 Sent';

        List<Case> pccCases = new Case[]{case3, case4};

        insert pccCases;

        Test.startTest();

        dcPluginGeneral.MCDay0PicklistComparator comparator = new dcPluginGeneral.MCDay0PicklistComparator(recordTypeMap);

        // Confirmed Case

        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Marketing_Cloud_PCC_Day_0__c', assessCases[1].Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('500', assessCases[0].Id, defaultResultMap, assessCases);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(assessCases[0], new SObject[]{assessCases[1]}, 'Marketing_Cloud_PCC_Day_0__c', output);

        Id masterID = output.fieldSourceMap.get('Marketing_Cloud_PCC_Day_0__c');

        System.assertEquals(assessCases[0].Id, masterID);

        // PCC

        defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('Marketing_Cloud_PCC_Day_0__c', pccCases[1].Id);
        input = new dupcheck.dc3PluginModel.MergeSetFieldInput('500', pccCases[0].Id, defaultResultMap, pccCases);
        output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);

        comparator.applyPrecedenceRule(pccCases[0], new SObject[]{pccCases[1]}, 'Marketing_Cloud_PCC_Day_0__c', output);

        Id currentID = output.fieldSourceMap.get('Marketing_Cloud_PCC_Day_0__c');

        System.assertEquals(pccCases[1].Id, currentID);

        Test.stopTest();
    }
}