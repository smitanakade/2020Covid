@isTest
public with sharing class SendEmailToCaseOwnerTest {
    @testSetup
    static void setupTestData() {
        // Create Person Account
        Account personAc1 = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        // Create case for the person 
        Case acase = TestDataFactory.createCases(personAc1, 1, 'Isolate', 'Close Contact').get(0);
    }

    // #270278
    @isTest
    static void testSentEmailUsers() {
        Case acase = [SELECT Id, OwnerId FROM Case LIMIT 1];

        Map<Id,Id> casePreviousOwnerMap = new Map<Id, Id>();
        Map<Id,Id> caseNewOwnerMap = new Map<Id, Id>();

        List<User> users = [SELECT Id FROM User WHERE (IsActive = true) AND (Email != null) LIMIT 2];

        casePreviousOwnerMap.put(acase.Id, users[0].Id);
        caseNewOwnerMap.put(acase.Id, users[1].Id);

        Test.startTest();

        SendEmailToCaseOwner.sendEmail(casePreviousOwnerMap, caseNewOwnerMap);

        Test.stopTest();

        System.assertEquals(true, SendEmailToCaseOwner.EmailSent);
    }

    // #270278
    @isTest
    static void testSentEmailGroups() {
        Case acase = [SELECT Id, OwnerId FROM Case LIMIT 1];

        Map<Id,Id> casePreviousOwnerMap = new Map<Id, Id>();
        Map<Id,Id> caseNewOwnerMap = new Map<Id, Id>();

        List<Group> groups = [SELECT Id FROM Group WHERE Email != null LIMIT 2];        

        casePreviousOwnerMap.put(acase.Id, groups[0].Id);
        caseNewOwnerMap.put(acase.Id, groups[1].Id);

        Test.startTest();

        SendEmailToCaseOwner.sendEmail(casePreviousOwnerMap, caseNewOwnerMap);

        Test.stopTest();

        System.assertEquals(true, SendEmailToCaseOwner.EmailSent);
    }
}
