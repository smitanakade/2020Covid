/*********************************************************************************
 *** @ClassName         : CaseQueueAllocator 
 *** @Author		    : marsson
 *** @Created date    	: 10/02/2021 
 *** NOTES:
  For this constructor, the Cases object musr have AT LEAST the following fields:
  Account.PersonMailingPostalCode


 **********************************************************************************/
@IsTest
public with sharing class CaseQueueAllocatorTest {


    @IsTest
    private static void testWithoutPostcode(){
        // Create Person Account
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingPostalCode = null;
        update personAc;
        // Create case for the person and then update it
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id fallbackQueue = queuesByName.get(CaseQueueAllocator.FALLBACK_QUEUE).Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(fallbackQueue, mycase.OwnerId);
    }

    @IsTest
    private static void testPrison(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingStreet = 'A Prison counter';
        update personAc;
        // Create case for the person and then update it
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id teamTwoId = queuesByName.get('Team Two').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(teamTwoId, mycase.OwnerId);
    }

    @IsTest
    private static void testOrange(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingStreet = 'An Orange Team Account';
        update personAc;
        // Create case for the person and then update it
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Active', 'Casual Contact').get(0);
        acase.permit_Type__c = 'Orange';
        acase.SubStatus__c = Null ;
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id ccoteamcId = queuesByName.get('CCO Team C').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(ccoteamcId, mycase.OwnerId);
    }

    @IsTest
    private static void testGreen(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingStreet = 'An Green Team Account';
        update personAc;
        // Create case for the person and then update it
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Active', 'Casual Contact').get(0);
        acase.permit_Type__c = 'Green';
        acase.SubStatus__c = Null ;
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id ccoteamcId = queuesByName.get('CCO Team C').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(ccoteamcId, mycase.OwnerId);
    }


    @IsTest
    private static void testRed(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingStreet = 'An Red Team Account';
        update personAc;
        // Create case for the person and then update it
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        acase.permit_Type__c = 'Red';
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id redZoneQueue = queuesByName.get('Red Zone').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(redZoneQueue, mycase.OwnerId);
    }
 
    @IsTest
    private static void testInternationalTravellerInsert(){ 
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.Additional_Detail__c = 'CQ-fg';
        update personAc;
        // Create case for the person and then update it
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        acase.SubStatus__c = null;
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id hQId = queuesByName.get('HQU').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(hQId, mycase.OwnerId);
    }
    @IsTest
    private static void testInternationalTravellerUpdate(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.Additional_Detail__c = 'CQ-fg';
        update personAc;
        // Create case for the person and then update it
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Quarantine', 'Close Contact').get(0);
        
        insert acase;
        Test.startTest();
        CaseQueueAllocator.apexRulesToBeProcessed = [SELECT Implementation_Class__c, Queue_Name__c from Queue_Allocation__c WHERE Implementation_Class__c !=null ];
        acase.Status = 'Identify';
        acase.SubStatus__c = null;
        update acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id hQId = queuesByName.get('HQU').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(hQId, mycase.OwnerId);
    }
    
    @IsTest
    private static void testFallBack(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        System.Assert([SELECT Id from Queue_Allocation__c].size() >0);

        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingStreet = 'A nice Place';
        personAc.PersonMailingPostalCode = '3001';
        update personAc;
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id fallbackQueue = queuesByName.get(CaseQueueAllocator.FALLBACK_QUEUE).Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(fallbackQueue, mycase.OwnerId);

    }

    @IsTest
    private static void test3000(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        System.Assert([SELECT Id from Queue_Allocation__c].size() >0);

        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingStreet = 'A nice Place';
        personAc.PersonMailingPostalCode = '3000';
        update personAc;
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id teamTwoId = queuesByName.get('WPHU').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(teamTwoId, mycase.OwnerId);
    }

    @IsTest
    private static void test3996(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        System.Assert([SELECT Id from Queue_Allocation__c].size() >0);

        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingStreet = 'A nice Place';
        personAc.PersonMailingPostalCode = '3996';
        update personAc;
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id teamTwoId = queuesByName.get('Gippsland').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(teamTwoId, mycase.OwnerId);
    }

    @IsTest
    private static void test3996ForEXHQFollowup(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        System.Assert([SELECT Id from Queue_Allocation__c].size() >0);

        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonOtherStreet = 'A nice Place';
        personAc.PersonOtherPostalCode = '3996';
        update personAc;
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Ex-HQ Follow-up', 'Close Contact').get(0);
        acase.HQ_Resident__c = true;
        acase.SubStatus__c = '';
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id teamTwoId = queuesByName.get('COVID Coordination Unit').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(teamTwoId, mycase.OwnerId);
    }

    @IsTest
    private static void test3996ForEXHQFollowupStatusUpdate(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        System.Assert([SELECT Id from Queue_Allocation__c].size() >0);

        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonOtherStreet = 'A nice Place';
        personAc.PersonOtherPostalCode = '3996';
        update personAc;
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        insert acase;
        Test.startTest();
        CaseQueueAllocator.apexRulesToBeProcessed = [SELECT Implementation_Class__c, Queue_Name__c from Queue_Allocation__c WHERE Implementation_Class__c !=null ];
        acase.status = 'Ex-HQ Follow-up';
        acase.HQ_Resident__c = true;
        update acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id teamTwoId = queuesByName.get('COVID Coordination Unit').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(teamTwoId, mycase.OwnerId);
    }

    @IsTest
    private static void testAgedCare(){

        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        System.Assert([SELECT Id from Queue_Allocation__c].size() >0);

        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingStreet = '9 joffre st';
        personAc.PersonMailingPostalCode = '3996';
        personAc.PersonBirthdate = Date.valueOf('1922-12-12');
        update personAc;
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id teamTwoId = queuesByName.get('Team One').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(teamTwoId, mycase.OwnerId);
    }
    @IsTest
    private static void testnullAccount(){

        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        System.Assert([SELECT Id from Queue_Allocation__c].size() >0);

        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingStreet = '9 joffre st';
        personAc.PersonMailingPostalCode = '3996';
        personAc.PersonBirthdate = Date.valueOf('1922-12-12');
        update personAc;
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Identify', 'Close Contact').get(0);
        acase.AccountId=null;
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id fallbackQueue = queuesByName.get(CaseQueueAllocator.FALLBACK_QUEUE).Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(fallbackQueue, mycase.OwnerId);
    }

    @IsTest
    private static void testInformaticsAssignment(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        // Create case for the person and then update it
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Isolate', 'COVID-19 Case Assessment').get(0);
        CaseTriggerHandler.SkipUpdate = false;

        acase.Case_Classification__c = 'Confirmed';
        insert acase;
        CaseTriggerHandler.SkipUpdate = false;

        Test.startTest();
        CaseQueueAllocator.apexRulesToBeProcessed = [SELECT Implementation_Class__c, Queue_Name__c from Queue_Allocation__c WHERE Implementation_Class__c !=null ];
        acase.Status = 'Trace';
        acase.Case_Classification__c = '';
        update acase;
        CaseTriggerHandler.SkipUpdate = false;

        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id informaticsId = queuesByName.get('Informatics').Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(informaticsId, mycase.OwnerId);
    }

    @IsTest
    private static void PCCSCCQuarantineDefaultQueue(){
        //List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        
        List<Queue_Allocation__c> ls = new List<Queue_Allocation__c>();
        Queue_Allocation__c pcc = new Queue_Allocation__c(Record_Type__c = 'Close Contact', Queue_Name__c = 'COVID Coordination Unit', Implementation_Class__c = 'CaseQueueImplementation.PCCSCCQuarantineDefault');
        Queue_Allocation__c scc = new Queue_Allocation__c(Record_Type__c = 'Secondary Close Contact', Queue_Name__c = 'COVID Coordination Unit', Implementation_Class__c = 'CaseQueueImplementation.PCCSCCQuarantineDefault');
        ls.add(pcc);
        ls.add(scc);
        
        insert ls;
        
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);

        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Quarantine', 'Close Contact').get(0);
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id fallbackQueue = queuesByName.get(CaseQueueAllocator.FALLBACK_QUEUE).Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(fallbackQueue, mycase.OwnerId);
        
    }
    @IsTest
    private static void testCasualContactNoPermitType(){
        List<Queue_Allocation__c> ls = Test.loadData(Queue_Allocation__c.sObjectType, 'QueueAllocationMapping');
        // Create Person Account
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        personAc.PersonMailingStreet = 'An Casual Contact Team Account';
        update personAc;
        // Create case for the person and then update it
        Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Active', 'Casual Contact').get(0);
        acase.permit_Type__c = Null;
        acase.SubStatus__c = Null ;
        Test.startTest();
        insert acase;
        Test.stopTest();
        Map<String,Group> queuesByName = QueueService.getAllQueuesByQueueName();
        Id fallbackQueue = queuesByName.get(CaseQueueAllocator.FALLBACK_QUEUE).Id;
        Case mycase = [Select OwnerId from Case where Id= :acase.Id];
        System.assertEquals(fallbackQueue, mycase.OwnerId);
    }

}