/**
 * @Author             : Sukumar
 * @Description        : createExposureSiteHandler class
 * @Modification Log   :  
 * ---------------------------------------------------
 * Date           Author      		    Details 
 * ---------------------------------------------------
*18/11/2021		 Sukumar			  Feature 332971-OBM - New Exposure Site creation from Case Movement/Contact Encounter screens Pt1
 22/11/2021      Sukumar              Bug#  338505 - SIT - PBI 332971 - Blank "Create Exposure Site" page in short form and long form
**/
public with sharing class createExposureSiteHandler {
    @AuraEnabled
    public static ContactEncounter getContactEncounter(string contactEncounterRecordId){
        ContactEncounter ce = [Select Id, Record__c, StartTime, End_Time__c, Record__r.CaseNumber, LocationId, Location__c, Location.Name, Record__r.Account.Name, Movement_Notes__c, Location__r.Name
                               FROM ContactEncounter WHERE Id =: contactEncounterRecordId];
        return ce;
    }

    @AuraEnabled
    public static ContactEncounter updateContactEncounter(string exposureSiteId, string contactEncounterRecordId){
        contactEncounter ce = new contactEncounter(Id = contactEncounterRecordId, Exposure_Site_ID__c = exposureSiteId);
        update ce;
        
        return [Select Id, Exposure_Site_ID__r.CaseNumber from ContactEncounter WHERE ID =: contactEncounterRecordId];
    }
}
