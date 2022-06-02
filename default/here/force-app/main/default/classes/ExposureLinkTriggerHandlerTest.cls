@isTest 
public without sharing class ExposureLinkTriggerHandlerTest {
    
	// test setup method to create and setup records
    @testSetup static void setupTestData() {
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id teamTwoId = queuesByName.get('Team Two').Id;
        Id teamSixId = queuesByName.get('Team Six').Id;
        System.debug('teamTwoId '+teamTwoId);
        System.debug('teamSixId '+teamSixId);
    	// Create Person Account
        Account personAc1 = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        // Create case for the person 
        Case acase = TestDataFactory.createCasesnoInsert(personAc1, 1, 'New', 'Exposure Management').get(0);
        acase.SubStatus__c = '';
        acase.Site_type__c = 'Exposure site';
        acase.ownerId = teamTwoId;
        insert acase;
        
        Account personAc2 = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        // Create case for the person 
        Case acase1 = TestDataFactory.createCasesnoInsert(personAc2, 1, 'Identify', 'Close Contact').get(0);
        acase1.SubStatus__c = '';
        insert acase1;
        
        Account personAc3 = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        // Create case for the person 
        Case acase2 = TestDataFactory.createCasesnoInsert(personAc3, 1, 'Identify', 'Secondary Close Contact').get(0);
        acase2.SubStatus__c = '';
        insert acase2;
        
        // Create Person Account
        Account personAc4 = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        // Create case for the person 
        Case acase3 = TestDataFactory.createCasesnoInsert(personAc4, 1, 'New', 'Exposure Management').get(0);
        acase3.SubStatus__c = '';
        acase3.Site_type__c = 'Outbreak';
        acase.ownerId = teamSixId;
        insert acase3;
    }
	
	@isTest static void testExposureSiteCaseAllocationForCloseContact() {
        
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
		Id SCCRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
		Id exposureManagementRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Outbreak').getRecordTypeId();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id teamTwoId = queuesByName.get('Team Two').Id;
        Id teamSixId = queuesByName.get('Team Six').Id;
        Case exposureSiteRecord = [Select Id, recordTypeId from case WHERE RecordTypeId = :exposureManagementRecordTypeId AND Site_type__c = 'Exposure site' LIMIT 1];
        exposureSiteRecord.ownerId = teamTwoId;
        update exposureSiteRecord;
        Case closeContactRecord = [Select Id, recordTypeId from case WHERE RecordTypeId = :closeContactRecordTypeId LIMIT 1];
		
        Test.startTest();
        if(closeContactRecord != null && exposureSiteRecord != null){
            Exposure_Link__c exposureLinkObj = new Exposure_Link__c(Linked_Record__c = closeContactRecord.Id, Exposure_Record__c = exposureSiteRecord.Id);
            
            insert exposureLinkObj;
            Case mycase = [Select OwnerId from Case where Id= :closeContactRecord.Id];
        	System.assertEquals(teamTwoId, mycase.OwnerId);
        }   
        Test.stopTest();

    } 
    
    @isTest static void testOutbreakCaseAllocationForSCC() {
        
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
		Id SCCRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
		Id exposureManagementRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Outbreak').getRecordTypeId();
        
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id teamTwoId = queuesByName.get('Team Two').Id;
        Id teamSixId = queuesByName.get('Team Six').Id;
        
        Case outbreakRecord = [Select Id, recordTypeId from case WHERE RecordTypeId = :exposureManagementRecordTypeId AND Site_type__c = 'Outbreak' LIMIT 1];
        outbreakRecord.ownerId = teamTwoId;
        update outbreakRecord;
        Case sccRecord = [Select Id, recordTypeId from case WHERE RecordTypeId = :closeContactRecordTypeId LIMIT 1];
		
        Test.startTest();
        if(sccRecord != null && outbreakRecord != null){
            Exposure_Link__c exposureLinkObj = new Exposure_Link__c(Linked_Record__c = sccRecord.Id, Exposure_Record__c = outbreakRecord.Id);
            
            insert exposureLinkObj;
            Case mycase = [Select OwnerId from Case where Id= :outbreakRecord.Id];
        	System.assertEquals(teamTwoId, mycase.OwnerId);
        }   
        Test.stopTest();

    }
    @isTest static void testOutbreakAndESCaseAllocation() {
        
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
		Id SCCRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
		Id exposureManagementRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Outbreak').getRecordTypeId();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id teamTwoId = queuesByName.get('Team Two').Id;
        Id teamSixId = queuesByName.get('Team Six').Id;
        Case exposureSiteRecord = [Select Id, recordTypeId from case WHERE RecordTypeId = :exposureManagementRecordTypeId AND Site_type__c = 'Exposure site' LIMIT 1];
        Case closeContactRecord = [Select Id, recordTypeId from case WHERE RecordTypeId = :closeContactRecordTypeId LIMIT 1];
		if(closeContactRecord != null && exposureSiteRecord != null){
            Exposure_Link__c exposureLinkObj = new Exposure_Link__c(Linked_Record__c = closeContactRecord.Id, Exposure_Record__c = exposureSiteRecord.Id);
            
            insert exposureLinkObj;
        }   
        exposureSiteRecord.ownerId = teamTwoId;
        update exposureSiteRecord;
        Case outbreakRecord = [Select Id, recordTypeId from case WHERE RecordTypeId = :exposureManagementRecordTypeId AND Site_type__c = 'Outbreak' LIMIT 1];
		outbreakRecord.ownerId = teamSixId;
        update outbreakRecord;
        
        Test.startTest();
        
            Exposure_Link__c exposureLinkObj1 = new Exposure_Link__c(Linked_Record__c = closeContactRecord.Id, Exposure_Record__c = outbreakRecord.Id);
            insert exposureLinkObj1;
        	Case mycase = [Select OwnerId from Case where Id= :closeContactRecord.Id];
        	System.assertEquals(teamTwoId, mycase.OwnerId);
        
        Test.stopTest();

    }
}