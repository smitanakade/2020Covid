/**
 * @Author             : Santosh
 * @Description        : Helper class for ContactEncounterTrigger
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 29/04/2021     Santosh		        Initial version
 * 29/11/2021     Sai Kallu				332083 - Household Close Contact Day 0 set to Date of First Positive Test Date of linked Case - logic change
**/
public class ContactEncounterTriggerHelper {
    public static final Id ContactEncounter_TravelHistory_RECORD_TYPE_ID = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Travel_History').getRecordTypeId();
    
    public static final Map<Id, Schema.RecordTypeInfo> contactEncounterRecordTypes = Schema.SObjectType.ContactEncounter.getRecordTypeInfosById();
    
    public static void updatestartitime(List<ContactEncounter> newrecords){
        List<User> intergrationuser =New List<User>();  
        try{
            intergrationuser = [select id from user where username like '%integration.user%' and Isactive = true limit 1];   
            if(intergrationuser.size()>0 && Userinfo.getUserId() == intergrationuser[0].id){
                for(ContactEncounter CE: newrecords){
                    if(CE.StartTime != null && CE.RecordTypeId == ContactEncounter_TravelHistory_RECORD_TYPE_ID ){
                        CE.StartTime = CE.StartTime.addDays(-14);
                    }
                } 
            }
        }catch(Exception exp){
            ApplicationLogUtility.createlog('ContactEncounterTriggerHelper','updatestartitime',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        } 
    }
    
     @testvisible
    public static void updateToMostRecentEndDateOnPCC(List<ContactEncounter> encounters, Map<Id, ContactEncounter> oldMap) {
        try {
            List<Id> contactEncountersList = new List<Id>();
            List<Case> casesToUpdate = new List<Case>();
            
            List<ContactEncounterParticipant> cepsToUpdate = new List<ContactEncounterParticipant>();
            
            for (ContactEncounter ce : encounters) {
                if (ce.RecordTypeId != null && contactEncounterRecordTypes.get(ce.RecordTypeId).getName() == 'Movement'
                    && ce.Type__c == 'Case Movement' && ce.Record__c != null
                    && ce.End_Time__c != oldMap.get(ce.Id).End_Time__c) {
                    contactEncountersList.add(ce.Id);
                }
            }
            
            if (!contactEncountersList.isEmpty()) {
                
                for (ContactEncounterParticipant cep : [SELECT Parent_Record__c/*confirmedcase*/, Record__c/*close contact*/, ContactEncounterId, Contact_Type__c, End_Time__c 
                                                        , ContactEncounter.End_Time__c,Relationship_to_case__c
                                                        , Record__r.Day_0_Exposure_to_the_confirmed_case__c
                                                        FROM ContactEncounterParticipant 
                                                        WHERE Contact_Type__c = 'Close contact' 
                                                        AND ContactEncounterId IN :contactEncountersList
                                                        ]) {
                    //bugfix - 342100  
                	if (cep.ContactEncounter.End_Time__c > cep.Record__r.Day_0_Exposure_to_the_confirmed_case__c && cep.Relationship_to_case__c == 'Household') {
                		casesToUpdate.add(new Case(Id = cep.Record__c, Day_0_Exposure_to_the_confirmed_case__c = (cep.ContactEncounter.End_Time__c).date() ));
                    }
                                                            
                    if (cep.End_Time__c != cep.ContactEncounter.End_Time__c) {
                        cep.End_Time__c = cep.ContactEncounter.End_Time__c;
                        cepsToUpdate.add(cep);
                    }
                }
            }
            
            if (!casesToUpdate.isEmpty()) update casesToUpdate;
            if (!cepsToUpdate.isEmpty()) update cepsToUpdate;
            
            
            
        }catch(Exception exp){ ApplicationLogUtility.createlog('ContactEncounterTriggerHelper','updateToMostRecentEndDateOnPCC',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());throw exp;} 
    }
    
    public class ContactEncounterTriggerHandlerException extends Exception {} 
    

}