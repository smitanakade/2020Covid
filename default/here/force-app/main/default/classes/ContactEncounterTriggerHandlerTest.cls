/**
 * @Author             : YPerera
 * @Description        : Test class for ContactEncounterTriggerHandler
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details 
 * ---------------------------------------------------
 * 3/5/2021       YPerera		        Initial version
**/
@IsTest
private class ContactEncounterTriggerHandlerTest {

    @IsTest
    private static void testPCCChangeDay0ExposureDateToLatest() {
        try{
            Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
            personAc.PersonMailingPostalCode = null;
            update personAc;

            Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = personAc.Id);
            insert entl;

            String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
            Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Trace', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                                AccountId = personAc.Id, Symptoms_Onset_Date__c = System.Today().addDays(-5), Date_of_Test__c = System.Today().addDays(-2), Clearance_eligibility_assessment_date__c = System.Today().addDays(12), EntitlementId = entl.Id);
            insert cse;


            Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Quarantine', 'Close Contact').get(0);
            acase.Day_0_Exposure_to_the_confirmed_case__c = (System.now().addDays(-3)).date();
            Test.startTest();
            insert acase;
            
            Schema.Location loc1 = New Schema.Location();
            loc1.Name = 'test';
            insert loc1;
            ContactEncounter contactEnc = new ContactEncounter ();
            contactEnc.Location__c = loc1.Id;
            contactEnc.LocationId = loc1.Id;
            contactEnc.Record__c = acase.Id;
            contactEnc.StartTime = System.now().addDays(-4);
            contactEnc.End_Time__c = System.now().addDays(-3);
            contactEnc.Name = 'At Home';
            DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
            
            ContactEncounterParticipant newCEP = new ContactEncounterParticipant();
            newCEP.ContactEncounterId = contactEnc.Id;
            newCEP.contactId = DHHS_CEPController.getPersonContactId(String.valueOf(personAc.Id)).PersonContactId;
            newCEP.Contact_Type__c = 'Close contact';
            newCEP.Parent_Record__c = cse.Id;
            newCEP.Record__c = acase.Id;
            newCEP.Relationship_to_Case__c = 'Airline';
            newCEP.Specify_relationship_to_case__c = 'Co-worker';
            newCEP.End_Time__c = System.now().addDays(-4);
            newCEP.Description__c = '';
            
            insert newCEP;
           

            Case c = [SELECT RecordTypeId, Day_0_Exposure_to_the_confirmed_case__c FROM Case WHERE RecordTypeId = :CaseTriggerHelper.CASE_CLOSE_CONTACT_RECORD_TYPE];
            System.assert(c != null);
            System.assert( (contactEnc.End_Time__c).date() == c.Day_0_Exposure_to_the_confirmed_case__c);
            
            contactEnc.End_Time__c = System.now().addDays(-2);
            update contactEnc;

            Case c2 = [SELECT Day_0_Exposure_to_the_confirmed_case__c FROM Case WHERE RecordTypeId = :CaseTriggerHelper.CASE_CLOSE_CONTACT_RECORD_TYPE];
            System.assertNotEquals((contactEnc.End_Time__c).date(), c2.Day_0_Exposure_to_the_confirmed_case__c);
            
            ContactEncounterParticipant cep = [SELECT Id, End_Time__c FROM ContactEncounterParticipant WHERE Id = :newCEP.Id];
            System.assertEquals((contactEnc.End_Time__c).date(), cep.End_Time__c.date());
			
            Test.stopTest();
        }catch(Exception exp){
            ApplicationLogUtility.createlog('ContactEncounterTriggerHandlerTest','testPCCChangeDay0ExposureDateToLatest',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }

    }
    
    
      @IsTest
    private static void testPCCChangeDay0ExposureDateToLatest1() {
        try{
            Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
            personAc.PersonMailingPostalCode = null;
            update personAc;

            Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = personAc.Id);
            insert entl;

            String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
            Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Trace', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                                AccountId = personAc.Id, Symptoms_Onset_Date__c = System.Today().addDays(-5), Date_of_Test__c = System.Today().addDays(-2), Clearance_eligibility_assessment_date__c = System.Today().addDays(12), EntitlementId = entl.Id);
            insert cse;


            Case acase = TestDataFactory.createCasesnoInsert(personAc, 1, 'Quarantine', 'Close Contact').get(0);
            acase.Day_0_Exposure_to_the_confirmed_case__c = (System.now().addDays(-3)).date();
            Test.startTest();
            insert acase;
            
            Schema.Location loc1 = New Schema.Location();
            loc1.Name = 'test';
            insert loc1;
            ContactEncounter contactEnc = new ContactEncounter ();
            contactEnc.Location__c = loc1.Id;
            contactEnc.LocationId = loc1.Id;
            contactEnc.Record__c = acase.Id;
            contactEnc.StartTime = System.now().addDays(-4);
            contactEnc.End_Time__c = System.now().addDays(-3);
            contactEnc.Name = 'At Home';
            DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
            
            
            ContactEncounterParticipant newCEP = new ContactEncounterParticipant();
            newCEP.ContactEncounterId = contactEnc.Id;
            newCEP.contactId = DHHS_CEPController.getPersonContactId(String.valueOf(personAc.Id)).PersonContactId;
            newCEP.Contact_Type__c = 'Close contact';
            newCEP.Parent_Record__c = cse.Id;
            newCEP.Record__c = acase.Id;
            newCEP.Relationship_to_Case__c = 'Household';
            newCEP.Specify_relationship_to_case__c = 'Co-worker';
            newCEP.End_Time__c = System.now().addDays(-4);
            newCEP.Description__c = '';
            
            insert newCEP;
            
            List<ContactEncounter> lstCE = [select id, End_Time__c from contactEncounter where id=:contactEnc.Id ];
            lstCE[0].End_Time__c = System.now().addDays(-2);
            update lstCE;
            
            List<ContactEncounter> lstCEs = [select id, End_Time__c from contactEncounter where id=:contactEnc.Id ];
            System.assertEquals(true,lstCEs[0].End_Time__c != null);

            Test.stopTest();
        }catch(Exception exp){
            ApplicationLogUtility.createlog('ContactEncounterTriggerHandlerTest','testPCCChangeDay0ExposureDateToLatest',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }

    }
}