/**
 * @Author             : Krishna Suram
 * @Description        : Test class for Set Account field on ContactEncounterParticipant scheduler class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author              Details
 * ---------------------------------------------------
 * 31/10/2021     Krishna Suram        Initial version
 * 
**/
 @isTest
public class CEP_AccountFieldScheduler_Test {
    
    static Testmethod void testCEPScheduler(){
        try{
            Test.startTest();
            String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
            String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
            Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                    PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
            insert acc;
            Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
            insert entl;
            Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Quarantine', SubStatus__c = 'In Progress', Subject = 'Test Close Contact',
                    AccountId = acc.Id, Day_0_Exposure_to_the_confirmed_case__c= System.Today().addDays(-10), EntitlementId = entl.Id);
            insert cse;
            
            Schema.Location loc1 = New Schema.Location();
            loc1.Name = 'test';
            insert loc1;
            ContactEncounter contactEnc = new ContactEncounter ();
            contactEnc.Location__c = loc1.Id;
            contactEnc.LocationId = loc1.Id;
            contactEnc.Record__c = cse.Id;
            contactEnc.StartTime = System.now().addDays(-2);
            contactEnc.End_Time__c = System.now().addDays(-1);
            contactEnc.Name = 'At Home';
            DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
            System.debug('***********************' + contactEnc.Id);
        
            ContactEncounterParticipant newCEP = new ContactEncounterParticipant();
            newCEP.ContactEncounterId = contactEnc.Id;
        // newCEP.contactId =;
            newCEP.Contact_Type__c = 'Close Contact';
            newCEP.Parent_Record__c = cse.Id;
            newCEP.Record__c = cse.Id;
            newCEP.Relationship_to_Case__c = 'Airline';
            newCEP.Specify_relationship_to_case__c = 'Co-worker';
            newCEP.End_Time__c = System.now().addDays(-5);
            newCEP.Description__c = '';
            insert newCEP;
            ContactEncounterParticipant newCEP2 = new ContactEncounterParticipant();
            newCEP2.ContactEncounterId = contactEnc.Id;
        // newCEP.contactId =;
            newCEP2.Contact_Type__c = 'Close Contact';
            newCEP2.Parent_Record__c = cse.Id;
            newCEP2.Record__c = cse.Id;
            newCEP2.Relationship_to_Case__c = 'Airline';
            newCEP2.Specify_relationship_to_case__c = 'Co-worker';
            newCEP2.End_Time__c = System.now().addDays(-5);
            newCEP2.Description__c = '';
            insert newCEP2;
            newCEP.Account__c = cse.AccountId;
            update newCEP;
            newCEP.Account__c = cse.AccountId;
            update newCEP2;
            CEP_AccountFieldScheduler sch = new CEP_AccountFieldScheduler();
            String schedule = '0 0 23 * * ?'; 
            System.schedule('CEPAccountfieldupdate',schedule , sch);
            Test.stopTest();
        }catch(Exception exp){
            ApplicationLogUtility.createlog('CEP_AccountFieldScheduler_Test','testCEPScheduler',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
        }
    }
}