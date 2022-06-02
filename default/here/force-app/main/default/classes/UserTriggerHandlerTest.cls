@IsTest
public with sharing class UserTriggerHandlerTest
{
    @TestSetup
    static void setup()
    {
        User newUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = [SELECT ID FROM Profile WHERE Name = 'Health Worker' LIMIT 1].Id, 
        TimeZoneSidKey='Australia/Sydney', UserName='standarduser@teDHHSstorg.com');
        
        User newUser2 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = [SELECT ID FROM Profile WHERE Name = 'Health Worker' LIMIT 1].Id,
        UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'CCOM Lead' LIMIT 1].Id, 
        TimeZoneSidKey='Australia/Sydney', UserName='standarduser@teDHHSstor3289g.com');

        User newSysAdmin = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = [SELECT ID FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id, 
        TimeZoneSidKey='Australia/Sydney', UserName='standarduser@teDHHSstorgAdmin.com');        
        
        StaticCommon.disablePermissionTrigger();
        Database.insert(new List<User>{newUser, newUser2, newSysAdmin}, false);
    }
       /* commenting liveMessagingPermissionSet , messagingUserPermissionSet as a part of BUG295340
     @IsTest 
     static void testAddPermissionsAndRoletoNewUser()
    {        
        Test.startTest();
            
        UserTriggerHandler.addHCPermissionSets([SELECT Id,UserRoleId,ProfileId,IsActive FROM User WHERE Username = 'standarduser@teDHHSstorg.com' OR Username = 'standarduser@teDHHSstor3289g.com']);
        
        

         Id userId = [SELECT Id FROM User WHERE Username = 'standarduser@teDHHSstor3289g.com'].Id;
         Integer pslaCount = [SELECT COUNT() FROM PermissionSetLicenseAssign WHERE AssigneeId = :userId];
         System.assertEquals(3,pslaCount);

        Test.stopTest();
		


    }*/

    @IsTest 
     static void testaddDefaultRole()
    {        
        Test.startTest();

         String userWithoutRole = [SELECT UserRole.DeveloperName FROM User WHERE Username = 'standarduser@teDHHSstorg.com' LIMIT 1].UserRole.DeveloperName;
         String userWithRole = [SELECT UserRole.DeveloperName FROM User WHERE Username = 'standarduser@teDHHSstor3289g.com' LIMIT 1].UserRole.DeveloperName;
         System.assertEquals('CCOM_Officer',userWithoutRole); //User gets default role
         System.assertEquals('CCOM_Lead',userWithRole);//User stays with current role

        Test.stopTest();    
    }
       
    @IsTest 
     static void testcurrentUserProfileChangeToHealthWorker()
    {        
        Test.startTest();

        UserTriggerHandler.addHCPermissionSets([SELECT Id,UserRoleId,ProfileId,IsActive FROM User WHERE Username = 'standarduser@teDHHSstorgAdmin.com']);
        User originalAdminUser = [SELECT Id,ProfileId FROM User WHERE Username = 'standarduser@teDHHSstorgAdmin.com'];
        Integer pslaCount = [SELECT COUNT() FROM PermissionSetLicenseAssign WHERE AssigneeId = :originalAdminUser.Id];
        Integer psaCount = [SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :originalAdminUser.Id];
        System.debug('psaCount:' + [SELECT Id, PermissionSet.Label from PermissionSetAssignment WHERE AssigneeId = :originalAdminUser.Id]);
        System.assertEquals(0,pslaCount,'The user is curretly Admin. It should not have any Permission Set Licenses');
        System.assertEquals(1,psaCount,'The user is curretly Admin. It should not have any Permission Sets/groups');
        
        //changing user profile from 'System Administator' to 'Health Worker'
        originalAdminUser.ProfileId = [SELECT ID FROM Profile WHERE Name = 'Health Worker' LIMIT 1].Id;
        StaticCommon.disablePermissionTrigger();
        update originalAdminUser;
        UserTriggerHandler.addHCPermissionSets([SELECT Id,UserRoleId,ProfileId,IsActive FROM User WHERE Username = 'standarduser@teDHHSstorgAdmin.com']);
        
        pslaCount = [SELECT COUNT() FROM PermissionSetLicenseAssign WHERE AssigneeId = :originalAdminUser.Id];
        psaCount = [SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :originalAdminUser.Id];
        
        System.assertEquals(2,pslaCount,'The user is curretly HealthWorker. It should have 2 Permission Set Licenses');
        System.assertEquals(6,psaCount,'The user is curretly Admin. It should have 8 Permission Sets/groups (1 permission set group + 4 PermissionSets + 1 hidden Permission Set');
        
        Test.stopTest();    
    }
    
    // 242230 - a method to test "DHHS EPI Access" perm set assignment 
    @isTest 
    static void testaddDHHSEPIAccessPermSet() {       
        User testUser = [SELECT Id FROM User WHERE Username = 'standarduser@teDHHSstor3289g.com']; 
        testUser.userRoleId = [SELECT ID FROM UserRole WHERE Name = 'Clinical' LIMIT 1].Id;
        Test.startTest();
        update testUser;
        Test.stopTest();

        List<PermissionSet> DHHSEPIAccessPS = [SELECT Id FROM PermissionSet WHERE Name = 'DHHS_EPI_Access' LIMIT 1];

        if(!DHHSEPIAccessPS.isEmpty()) {
            List<PermissionSetAssignment> DHHSEpiAccessAssignments = [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment 
                                                                        WHERE PermissionSetId =: DHHSEPIAccessPS[0].Id AND AssigneeId =: testUser.Id LIMIT 1];
            System.assertEquals(1, DHHSEpiAccessAssignments.size());
            
        }  
    }


    // 244511 - a method to test "DHHS EPI Access" perm set removal
    @isTest 
    static void testRemoveDHHSEPIAccessPermSet() {       
        User testUser = [SELECT Id FROM User WHERE Username = 'standarduser@teDHHSstor3289g.com']; 
        List<PermissionSet> DHHSEPIAccessPS = [SELECT Id FROM PermissionSet WHERE Name = 'DHHS_EPI_Access' LIMIT 1];

        test.startTest();
        testUser.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'CCOM' LIMIT 1].Id;    //remove from "Clinical" / "Epidemiologist" role
        update testUser;
        test.stopTest();

        if(!DHHSEPIAccessPS.isEmpty()) {
            List<PermissionSetAssignment> DHHSEpiAccessAssignments = [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment 
                                                                        WHERE PermissionSetId =: DHHSEPIAccessPS[0].Id AND AssigneeId =: testUser.Id ];

            System.assertEquals(0, DHHSEpiAccessAssignments.size());
        }


    }

    // Method to test addMarketingUser (PBI-293522)
    @isTest
    static void testaddMarketingUser(){
        List<User> testUser2 = [SELECT Id, isActive, UserRole.DeveloperName, UserPermissionsMarketingUser FROM User WHERE Username = 'standarduser@teDHHSstor3289g.com' LIMIT 1];

        test.startTest();
        UserTriggerHandler.addMarketingUser(testUser2);
        System.debug('Value: '+testUser2[0].UserPermissionsMarketingUser);
        System.debug('Value ROLE: '+testUser2[0].UserRole.DeveloperName);
        test.stopTest();
        Boolean userWithMarketingPermission = [SELECT UserPermissionsMarketingUser FROM User WHERE Username = 'standarduser@teDHHSstor3289g.com' LIMIT 1].UserPermissionsMarketingUser;
        System.assertEquals(true,userWithMarketingPermission);
       
    }
}