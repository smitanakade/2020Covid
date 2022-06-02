@isTest
public with sharing class RelatedListControllerTest {

    @isTest public static void testInit(){
        
        Id accountRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        Id secondaryCloseContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
        Id interviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();
        Id cepCloseConRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();        
        Id cepMovementRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Movement').getRecordTypeId();
        Id cepWSCRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Work_Study_Care').getRecordTypeId();        
        Id cepConfCaseTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Contact_with_Confirmed_Case').getRecordTypeId();
        
        String recId;
        User aUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = [SELECT ID FROM Profile WHERE Name = 'Health Worker' LIMIT 1].Id, 
        TimeZoneSidKey='Australia/Sydney', UserName='standarduser@testorg.com.test');
        insert aUser;

        system.runAs(aUser) {
            
            Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='Test1 FName', LastName='Test1 LName',PersonMailingStreet='101 Collins Street',
                                                PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test11112@gmail.com', PersonHomePhone='1234567',PersonMobilePhone='+614444');
            insert accountRecord;
            Id contactId = [Select PersonContactId from Account where Id=:accountRecord.Id][0].PersonContactId;


            List<case> caselist = new List<case>();
            Case closeContact = new Case(recordTypeId=closeContactRecordTypeId ,Status='Identify',Subject='Test closeContact',
                                AccountId=accountRecord.Id, ContactId = contactId);
            caselist.add(closeContact);
            
            Case primaryCloseContact = new Case(recordTypeId=secondaryCloseContactRecordTypeId ,Status='Identify',Subject='Test secondaryCloseContact',AccountId=accountRecord.Id, ContactId = contactId);
            caselist.add(primaryCloseContact);
            insert caselist;

            

            List<ContactEncounter> conEnList = new  List<ContactEncounter>();
            ContactEncounter ceRecord = new ContactEncounter(RecordTypeId=cepCloseConRecordTypeId, Name='Private residence – home', StartTime=System.Now(), Record__c=caseList[0].Id );
            conEnList.add(ceRecord);
            
            ContactEncounter ce1 = new ContactEncounter(RecordTypeId=cepMovementRecordTypeId, Recent_Travel_Overseas__c='yes',Country__c='ATA', Arrival_Date__c = System.today(),Name='CE1', 
                                                        StartTime=System.Now(), End_Time__c = System.today(), Record__c=caseList[1].Id ); 
            conEnList.add(ce1);

            ContactEncounter ce2 = new ContactEncounter(RecordTypeId=cepWSCRecordTypeId, Employment_Status__c = 'Employed',Name='CE2', StartTime=System.Now(), 
                                                        End_Time__c = System.today(), Record__c=caseList[1].Id ); 
            conEnList.add(ce2);
            insert conEnList ;
            

            ContactEncounterParticipant cepRecord = new ContactEncounterParticipant(Record__c=caseList[0].Id , Parent_Record__c=caseList[0].Id,ContactEncounterId =conEnList[0].Id, 
                                                        ContactId = contactId, End_Time__c = System.Now()+3 );
            insert cepRecord ;
                
            
            WorkOrder closeContactWorkOrder = new WorkOrder(recordTypeId=interviewWORecordTypeId, Status='In Progress', Subject='Test closeContactWorkOrder',
                                                        AccountId=accountRecord.Id, CaseId = caseList[0].Id);
            insert closeContactWorkOrder;
            recId = String.valueOf(closeContactWorkOrder.Id);
                
            
            HealthCloudGA__EhrImmunization__c EhrRec = new HealthCloudGA__EhrImmunization__c();
            EhrRec.Contact__c=contactId;
            EhrRec.Have_you_had_a_COVID_19_vaccine__c=true;
            insert EhrRec;


            HealthCloudGA__Clinical_Assessment_Response__c CarRec = new HealthCloudGA__Clinical_Assessment_Response__c();
            CarRec.HealthCloudGA__Patient__c = accountRecord.Id;
            CarRec.Record__c = caseList[1].Id;
            insert CarRec;

            
            HealthCloudGA__EhrEncounter__c encounter = new HealthCloudGA__EhrEncounter__c(Record__c = caseList[1].id, Presented_to__c = 'Hospital admission', 
                                                        StartDate__c = Date.today(), End_Date__c = Date.today().addDays(14));
            insert encounter;


        }
    
        Test.startTest();        
        Map<String, Object> requestMap1 = new Map<String, Object>(); 
        requestMap1.put(RelatedListController.FIELDS_PARAM, 'Name');
        //requestMap1.put(RelatedListController.RELATED_FIELD_API_NAME_PARAM, 'WorkOrderId');
        requestMap1.put(RelatedListController.RECORD_ID_PARAM, recId);
        requestMap1.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
        requestMap1.put(RelatedListController.SOBJECT_API_NAME_PARAM, 'HealthCloudGA__EhrEncounter__c');
        requestMap1.put(RelatedListController.SORTED_BY_PARAM, 'Name');
        requestMap1.put(RelatedListController.SORTED_DIRECTION_PARAM, 'ASC');
                
        String jsonData1 = RelatedListController.initData(JSON.serialize(requestMap1));
        Map<String, Object> responseMap1 = (Map<String, Object>)JSON.deserializeUntyped(jsonData1);
        List<Object> records1 = (List<Object>)responseMap1.get(RelatedListController.RECORDS_PARAM);
        //System.assert(!records1.isEmpty());

        Map<String, Object> requestMap2 = new Map<String, Object>(); 
        requestMap2.put(RelatedListController.FIELDS_PARAM, 'Name');
        //requestMap2.put(RelatedListController.RELATED_FIELD_API_NAME_PARAM, 'WorkOrderId');
        requestMap2.put(RelatedListController.RECORD_ID_PARAM, recId);
        requestMap2.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
        requestMap2.put(RelatedListController.SOBJECT_API_NAME_PARAM, 'HealthCloudGA__Clinical_Assessment_Response__c');
        requestMap2.put(RelatedListController.SORTED_BY_PARAM, 'Name');
        requestMap2.put(RelatedListController.SORTED_DIRECTION_PARAM, 'ASC');
                
        String jsonData2 = RelatedListController.initData(JSON.serialize(requestMap2));
        Map<String, Object> responseMap2 = (Map<String, Object>)JSON.deserializeUntyped(jsonData2);
        List<Object> records2 = (List<Object>)responseMap2.get(RelatedListController.RECORDS_PARAM);
        //System.assert(!records2.isEmpty());

        Map<String, Object> requestMap3 = new Map<String, Object>(); 
        requestMap3.put(RelatedListController.FIELDS_PARAM, 'Name,Arrival_Date__c');
        //requestMap3.put(RelatedListController.RELATED_FIELD_API_NAME_PARAM, 'WorkOrderId');
        requestMap3.put(RelatedListController.RECORD_ID_PARAM, recId);
        requestMap3.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
        requestMap3.put(RelatedListController.SOBJECT_API_NAME_PARAM, 'ContactEncounter');
        requestMap3.put(RelatedListController.SORTED_BY_PARAM, 'Name');
        requestMap3.put(RelatedListController.SORTED_DIRECTION_PARAM, 'ASC');
                
        String jsonData3 = RelatedListController.initData(JSON.serialize(requestMap3));
        Map<String, Object> responseMap3 = (Map<String, Object>)JSON.deserializeUntyped(jsonData3);
        List<Object> records3 = (List<Object>)responseMap3.get(RelatedListController.RECORDS_PARAM);
        //System.assert(!records3.isEmpty());

        Map<String, Object> requestMap4 = new Map<String, Object>(); 
        requestMap4.put(RelatedListController.FIELDS_PARAM, 'Name,Worked_in_disability_service__c');
        //requestMap4.put(RelatedListController.RELATED_FIELD_API_NAME_PARAM, 'WorkOrderId');
        requestMap4.put(RelatedListController.RECORD_ID_PARAM, recId);
        requestMap4.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
        requestMap4.put(RelatedListController.SOBJECT_API_NAME_PARAM, 'ContactEncounter');
        requestMap4.put(RelatedListController.SORTED_BY_PARAM, 'Name');
        requestMap4.put(RelatedListController.SORTED_DIRECTION_PARAM, 'ASC');
                
        String jsonData4 = RelatedListController.initData(JSON.serialize(requestMap4));
        Map<String, Object> responseMap4 = (Map<String, Object>)JSON.deserializeUntyped(jsonData4);
        List<Object> records4 = (List<Object>)responseMap4.get(RelatedListController.RECORDS_PARAM);
        //System.assert(!records4.isEmpty());

        Map<String, Object> requestMap5 = new Map<String, Object>(); 
        requestMap5.put(RelatedListController.FIELDS_PARAM, 'Name');
        //requestMap5.put(RelatedListController.RELATED_FIELD_API_NAME_PARAM, 'WorkOrderId');
        requestMap5.put(RelatedListController.RECORD_ID_PARAM, recId);
        requestMap5.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
        requestMap5.put(RelatedListController.SOBJECT_API_NAME_PARAM, 'HealthCloudGA__EhrEncounter__c');
        requestMap5.put(RelatedListController.SORTED_BY_PARAM, 'Name');
        requestMap5.put(RelatedListController.SORTED_DIRECTION_PARAM, 'ASC');
                
        String jsonData5 = RelatedListController.initData(JSON.serialize(requestMap5));
        Map<String, Object> responseMap5 = (Map<String, Object>)JSON.deserializeUntyped(jsonData5);
        List<Object> records5 = (List<Object>)responseMap5.get(RelatedListController.RECORDS_PARAM);
        //System.assert(!records5.isEmpty());
        //String iconName = (String)responseMap.get(RelatedListController.ICON_NAME_PARAM);
        //System.assert(String.isNotBlank(iconName));
        
        Map<String, Object> requestMap6 = new Map<String, Object>(); 
        requestMap6.put(RelatedListController.FIELDS_PARAM, 'Name');
        //requestMap5.put(RelatedListController.RELATED_FIELD_API_NAME_PARAM, 'WorkOrderId');
        requestMap6.put(RelatedListController.RECORD_ID_PARAM, recId);
        requestMap6.put(RelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
        requestMap6.put(RelatedListController.SOBJECT_API_NAME_PARAM, 'ContactEncounter');
        requestMap6.put(RelatedListController.SORTED_BY_PARAM, 'Name');
        requestMap6.put(RelatedListController.SORTED_DIRECTION_PARAM, 'ASC');
        requestMap6.put(RelatedListController.FIELDS_PARAM, 'Recent_Travel_Overseas__c');
                
        String jsonData6 = RelatedListController.initData(JSON.serialize(requestMap6));
        Map<String, Object> responseMap6 = (Map<String, Object>)JSON.deserializeUntyped(jsonData6);
        List<Object> records6 = (List<Object>)responseMap6.get(RelatedListController.RECORDS_PARAM);
        Test.stopTest();
    }
}