/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : Test class for dcPluginMerge
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 11/02/2021     Darko Jovanovic       Hotfix 258342 (Incorporate custom merge rules): Initial version
 * 19/09/2021     Pratyush Chalasani    Feature 330329: Address Management - ELR merge rules (blank address)
 * 28/10/2021     Pratyush Chalasani    Hotfix 332208: CPA entry is created after merging the ELR record with missing Suburb
**/
@isTest
private class dcPluginMergeTest {
    
    @isTest
    static void testBeforeMerge() {
        List<Account> personAccountList = TestDataFactory.createAccount(3, 'Active','Person Account');
        (new dcPluginMerge()).beforeMerge('001P', personAccountList[0], new List<Account>{personAccountList[1], personAccountList[2]});
    }

    @isTest
    static void testMergeFailed() {
        List<Account> personAccountList = TestDataFactory.createAccount(3, 'Active','Person Account');
        (new dcPluginMerge()).mergeFailed('001P', personAccountList[0], new Set<Id>{personAccountList[1].Id, personAccountList[2].Id}, null);
    }

    @isTest
    static void testAfterMerge() {
        List<Account> personAccountList = TestDataFactory.createAccount(2, 'Active','Person Account');
        Case rec = TestDataFactory.createCases(personAccountList[0], 1, 'Isolate', 'COVID-19 Case Screening')[0];
        (new dcPluginMerge()).afterMerge('001P', personAccountList[0], new Set<Id>{personAccountList[1].Id});
    }

    //#305103
    @isTest
    static void testELRMerge() {
        User integrationUser = [SELECT Id FROM User WHERE (Name = 'Integration User') AND (Profile.Name = 'Integration User' AND (IsActive = true))];

        Account masterAccount;
        List<Account> mergeAccounts;

        Test.startTest();

        System.runAs(integrationUser) {
            // Create Person Account
            masterAccount = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

            masterAccount.Primary_Address__c = 'Residential';
            masterAccount.PersonMailingStreet = '1 George St';
            masterAccount.PersonMailingCity = 'Sydney';
            masterAccount.PersonMailingState = 'NSW';
            masterAccount.PersonMailingPostalCode = '2000';
            masterAccount.PersonMailingCountry = 'Australia';

            update masterAccount;

            mergeAccounts = TestDataFactory.createAccount(1, 'Active', 'Person Account');

            mergeAccounts[0].Primary_Address__c = 'Residential';
            mergeAccounts[0].PersonMailingStreet = '1 George St';
            mergeAccounts[0].PersonMailingCity = 'Sydney';
            mergeAccounts[0].PersonMailingState = 'NSW';
            mergeAccounts[0].PersonMailingPostalCode = '2000';
            mergeAccounts[0].PersonMailingCountry = 'X';
            
            update mergeAccounts;
        }

        masterAccount = [SELECT Primary_Address__c, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, CreatedDate, CreatedById, RecordTypeId FROM Account WHERE Id = :masterAccount.Id];

        mergeAccounts = [SELECT Primary_Address__c, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, CreatedDate, CreatedById, RecordTypeId FROM Account WHERE Id IN :mergeAccounts];

        dcPluginMerge pluginMerge = new dcPluginMerge();

        pluginMerge.beforeMerge('001P', masterAccount, mergeAccounts);
        

        Id mergedID = mergeAccounts[0].Id;

        delete mergeAccounts;

        pluginMerge.afterMerge('001P', masterAccount, new Set<Id>{mergedID});

        Test.getEventBus().deliver();
        Test.stopTest();

        ContactPointAddress address = [SELECT ParentId, Name, AddressType, Street, City, State, PostalCode, Country, ActiveFromDate, ActiveToDate FROM ContactPointAddress WHERE ParentId = :masterAccount.Id];

        Account merged = mergeAccounts[0];

        System.assertEquals(masterAccount.Id, address.ParentId);
        System.assertEquals('Merged Address', address.Name);
        System.assertEquals('ELR', address.AddressType);
        System.assertEquals(merged.CreatedDate.date(), address.ActiveFromDate);
        System.assertEquals(merged.CreatedDate.date(), address.ActiveToDate);
        System.assertEquals(merged.PersonMailingStreet, address.Street);
        System.assertEquals(merged.PersonMailingCity, address.City);
        System.assertEquals(merged.PersonMailingState, address.State);
        System.assertEquals(merged.PersonMailingPostalCode, address.PostalCode);
        System.assertEquals(merged.PersonMailingCountry, address.Country);
    }

    //#330329: Master address is blank, Merged address is filled
    @isTest
    static void testELRMergeWithBlankAddresses1() {
        User integrationUser = [SELECT Id FROM User WHERE (Name = 'Integration User') AND (Profile.Name = 'Integration User' AND (IsActive = true))];

        Account masterAccount;
        List<Account> mergeAccounts;

        Test.startTest();

        System.runAs(integrationUser) {
            // Create Person Account
            masterAccount = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

            masterAccount.Primary_Address__c = 'Residential';
            masterAccount.PersonMailingStreet = '';
            masterAccount.PersonMailingCity = 'Sydney';
            masterAccount.PersonMailingState = 'NSW';
            masterAccount.PersonMailingPostalCode = '2000';
            masterAccount.PersonMailingCountry = 'Australia';

            update masterAccount;

            mergeAccounts = TestDataFactory.createAccount(1, 'Active', 'Person Account');

            mergeAccounts[0].Primary_Address__c = 'Residential';
            mergeAccounts[0].PersonMailingStreet = '1 George St';
            mergeAccounts[0].PersonMailingCity = 'Sydney';
            mergeAccounts[0].PersonMailingState = 'NSW';
            mergeAccounts[0].PersonMailingPostalCode = '2000';
            mergeAccounts[0].PersonMailingCountry = 'X';
            
            update mergeAccounts;
        }

        masterAccount = [SELECT Primary_Address__c, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, CreatedDate, CreatedById, RecordTypeId FROM Account WHERE Id = :masterAccount.Id];

        mergeAccounts = [SELECT Primary_Address__c, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, CreatedDate, CreatedById, RecordTypeId FROM Account WHERE Id IN :mergeAccounts];

        dcPluginMerge pluginMerge = new dcPluginMerge();

        pluginMerge.beforeMerge('001P', masterAccount, mergeAccounts);

        Id mergedID = mergeAccounts[0].Id;

        delete mergeAccounts;

        pluginMerge.afterMerge('001P', masterAccount, new Set<Id>{mergedID});

        Test.getEventBus().deliver();

        Test.stopTest();

        Account master = [SELECT PersonMailingStreet FROM Account WHERE Id = :masterAccount.Id];

        Account merged = mergeAccounts[0];

        System.assertEquals(merged.PersonMailingStreet, master.PersonMailingStreet, 'Master address street should be copied from merged account');
    }

    //#330329: Master address is blank, Merged address is also blank
    @isTest
    static void testELRMergeWithBlankAddresses2() {
        User integrationUser = [SELECT Id FROM User WHERE (Name = 'Integration User') AND (Profile.Name = 'Integration User' AND (IsActive = true))];

        Account masterAccount;
        List<Account> mergeAccounts;

        Test.startTest();

        System.runAs(integrationUser) {
            // Create Person Account
            masterAccount = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

            masterAccount.Primary_Address__c = 'Residential';
            masterAccount.PersonMailingStreet = '';
            masterAccount.PersonMailingCity = 'Sydney';
            masterAccount.PersonMailingState = 'NSW';
            masterAccount.PersonMailingPostalCode = '2000';
            masterAccount.PersonMailingCountry = 'Australia';

            update masterAccount;

            mergeAccounts = TestDataFactory.createAccount(1, 'Active', 'Person Account');

            mergeAccounts[0].Primary_Address__c = 'Residential';
            mergeAccounts[0].PersonMailingStreet = '';
            mergeAccounts[0].PersonMailingCity = 'Sydney';
            mergeAccounts[0].PersonMailingState = 'NSW';
            mergeAccounts[0].PersonMailingPostalCode = '2000';
            mergeAccounts[0].PersonMailingCountry = 'X';
            
            update mergeAccounts;
        }

        masterAccount = [SELECT Primary_Address__c, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, CreatedDate, CreatedById, RecordTypeId FROM Account WHERE Id = :masterAccount.Id];

        mergeAccounts = [SELECT Primary_Address__c, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, CreatedDate, CreatedById, RecordTypeId FROM Account WHERE Id IN :mergeAccounts];

        dcPluginMerge pluginMerge = new dcPluginMerge();

        pluginMerge.beforeMerge('001P', masterAccount, mergeAccounts);

        Id mergedID = mergeAccounts[0].Id;

        delete mergeAccounts;

        pluginMerge.afterMerge('001P', masterAccount, new Set<Id>{mergedID});

        Test.getEventBus().deliver();

        Test.stopTest();

        Account master = [SELECT PersonMailingCountry FROM Account WHERE Id = :masterAccount.Id];

        System.assertEquals(masterAccount.PersonMailingCountry, master.PersonMailingCountry, 'Master address country should be unchanged');
    }

    //#330329: Master address is filled, Merged address is blank
    @isTest
    static void testELRMergeWithBlankAddresses3() {
        User integrationUser = [SELECT Id FROM User WHERE (Name = 'Integration User') AND (Profile.Name = 'Integration User' AND (IsActive = true))];

        Account masterAccount;
        List<Account> mergeAccounts;

        Test.startTest();

        System.runAs(integrationUser) {
            // Create Person Account
            masterAccount = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

            masterAccount.Primary_Address__c = 'Residential';
            masterAccount.PersonMailingStreet = '1 George Street';
            masterAccount.PersonMailingCity = 'Sydney';
            masterAccount.PersonMailingState = 'NSW';
            masterAccount.PersonMailingPostalCode = '2000';
            masterAccount.PersonMailingCountry = 'Australia';

            update masterAccount;

            mergeAccounts = TestDataFactory.createAccount(1, 'Active', 'Person Account');

            mergeAccounts[0].Primary_Address__c = 'Residential';
            mergeAccounts[0].PersonMailingStreet = '1 George Street';
            mergeAccounts[0].PersonMailingCity = '';
            mergeAccounts[0].PersonMailingState = 'NSW';
            mergeAccounts[0].PersonMailingPostalCode = '2000';
            mergeAccounts[0].PersonMailingCountry = 'X';
            
            update mergeAccounts;
        }

        masterAccount = [SELECT Primary_Address__c, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, CreatedDate, CreatedById, RecordTypeId FROM Account WHERE Id = :masterAccount.Id];

        mergeAccounts = [SELECT Primary_Address__c, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, CreatedDate, CreatedById, RecordTypeId FROM Account WHERE Id IN :mergeAccounts];

        dcPluginMerge pluginMerge = new dcPluginMerge();

        pluginMerge.beforeMerge('001P', masterAccount, mergeAccounts);

        Id mergedID = mergeAccounts[0].Id;

        delete mergeAccounts;

        pluginMerge.afterMerge('001P', masterAccount, new Set<Id>{mergedID});

        Test.getEventBus().deliver();

        Test.stopTest();

        Account master = [SELECT PersonMailingCountry FROM Account WHERE Id = :masterAccount.Id];

        System.assertEquals(masterAccount.PersonMailingCountry, master.PersonMailingCountry, 'Master address country should be unchanged');
    }

    //#276114
    @isTest
    static void testMergedCaseNumbers() {
        Account acc = TestDataFactory.createAccount(1, 'Active', 'Person Account')[0];

        List<Case> cases = TestDataFactory.createCases(acc, 3, 'Trace', 'COVID-19 Case Assessment');

        List<Case> casesWithNumbers = [SELECT CaseNumber, Merged_Case_IDs__c FROM Case];

        String expectedMergedIDText = casesWithNumbers[1].CaseNumber + ',' + casesWithNumbers[2].CaseNumber;

        Test.startTest();

        dcPluginMerge pluginMerge = new dcPluginMerge();

        pluginMerge.beforeMerge('500', casesWithNumbers[0], new List<Case>{casesWithNumbers[1], casesWithNumbers[2]});

        pluginMerge.afterMerge('500', casesWithNumbers[0], new Set<Id>{casesWithNumbers[1].Id, casesWithNumbers[2].Id});

        Test.stopTest();

        System.assertEquals(expectedMergedIDText, casesWithNumbers[0].Merged_Case_IDs__c);
    }
}