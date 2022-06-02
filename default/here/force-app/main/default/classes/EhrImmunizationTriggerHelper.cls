/*
Author: Arun
 
@Modification Log   :  
---------------------------------------------------
Date           Author      		    Details
---------------------------------------------------
15/06/2021     Arun       Feature 272348: Update Person Account with Vaccination details
19/10/2021     Xiang      Feature 330357: Marketing Cloud - TREVI changes for PCC Triage message
25/10/2021     Xiang      Feature 331107: Logic change for calculating Fully vaccinated person
*/
public with sharing class EhrImmunizationTriggerHelper {

    //Where there are more than one immunization record and one of the immunization record is deleted, then based on remaining immunization records check for field Dose received value 2 or more and Validation Status != "Incorrect Vaccine Linked", 
    //then update the Person.Person is fully vaccinated field to TRUE else FALSE  
    public static void updatePersonAccountDelete(Map<Id,HealthCloudGA__EhrImmunization__c> oldEHRMap){
        Set<Id> contactSet = new Set<Id>();
        List<Contact> contactUpdateList = new List<Contact>();

        for(HealthCloudGA__EhrImmunization__c ehr: oldEHRMap.values()){
            if(ehr.contact__c != null){
                contactSet.add(ehr.contact__c);
            }
        }

        //get related contacts with Immunizations
        List<Contact> contactList = [SELECT Id, Any_vaccination_details_recorded__c, (SELECT Id,Dose_Received__c,Validation_Status__c FROM EHR_Immunizations__r) FROM Contact WHERE Id = :contactSet];

        for(Contact con: contactList){
            Contact tempCon = new Contact();
            tempCon.Id = con.Id;
            
            if(con.EHR_Immunizations__r.size() == 0){
                //if there has no Immunizations under the contact, then set Any_vaccination_details_recorded__c to false 
                tempCon.Any_vaccination_details_recorded__c = false;
            }else{
                //check all Immunizations under the contact, if one of them Validation_Status__c != 6, and Dose_Received__c = 2nd, 3rd, 4th, 5th set the Any_vaccination_details_recorded__c to true other wise set it to false
                for(HealthCloudGA__EhrImmunization__c ehr: con.EHR_Immunizations__r){
                    tempCon.Any_vaccination_details_recorded__c = false;
                    if((ehr.Validation_Status__c == '1' || ehr.Validation_Status__c == '2') &&  ehr.Dose_Received__c != null && ehr.Dose_Received__c != '1st'){
                        tempCon.Any_vaccination_details_recorded__c = true;
                        break;
                    }
                }
            }

            //check the the Any_vaccination_details_recorded__c is chnaged or not.
            if(tempCon.Any_vaccination_details_recorded__c != con.Any_vaccination_details_recorded__c){
                contactUpdateList.add(tempCon);
            }
        }

        //update the contact list.
        if(!contactUpdateList.isEmpty()){
            update contactUpdateList;
        }
    }

    //Where there are more than one immunization record and one of those EHR immunization record is marked with Validation status "Incorrect Vaccine Linked", 
    //then based on remaining immunization records, check for the field Dose received with value 2 or more and Validation Status != "Incorrect Vaccine Linked", 
    //then update the Person.Person is fully vaccinated field to TRUE else FALSE
    public static void updatePersonAccount(List<HealthCloudGA__EhrImmunization__c> newEHR, Map<Id,HealthCloudGA__EhrImmunization__c> OldMap){
        //Define variables
        Set<Id> ehrSet = new Set<Id>();
        Set<Id> contactSet = new Set<Id>();
        List<HealthCloudGA__EhrImmunization__c> ehrList=new List<HealthCloudGA__EhrImmunization__c>(); 
        Set<Contact> contactListToUpdate=new Set<Contact>();
        List<Contact> contactUpdateList = new List<Contact>();
   
        for(HealthCloudGA__EhrImmunization__c ehr: newEHR){
            if(ehr.contact__c != null){
                if(OldMap == null){
                    contactSet.add(ehr.contact__c);
                }else{
                    if(ehr.Dose_Received__c != OldMap.get(ehr.Id).Dose_Received__c || ehr.Validation_Status__c != OldMap.get(ehr.Id).Validation_Status__c){
                        contactSet.add(ehr.contact__c);
                    }
                }
            }
        }

        //get related contacts with Immunizations
        List<Contact> contactList = [SELECT Id, Any_vaccination_details_recorded__c, (SELECT Id,Dose_Received__c,Validation_Status__c FROM EHR_Immunizations__r) FROM Contact WHERE Id = :contactSet];

        for(Contact con: contactList){
            Contact tempCon = new Contact();
            tempCon.Id = con.Id;

            //check all Immunizations under the contact, if one of them Validation_Status__c != 6, and Dose_Received__c = 2nd, 3rd, 4th, 5th set the Any_vaccination_details_recorded__c to true other wise set it to false
            for(HealthCloudGA__EhrImmunization__c ehr: con.EHR_Immunizations__r){
                tempCon.Any_vaccination_details_recorded__c = false;
                if((ehr.Validation_Status__c == '1' || ehr.Validation_Status__c == '2') && ehr.Dose_Received__c != null && ehr.Dose_Received__c != '1st'){
                    tempCon.Any_vaccination_details_recorded__c = true;
                    break;
                }
            }

            //check the the Any_vaccination_details_recorded__c is chnaged or not.
            if(tempCon.Any_vaccination_details_recorded__c != con.Any_vaccination_details_recorded__c){
                contactUpdateList.add(tempCon);
            }   
        }

        //update the contact list.
        if(!contactUpdateList.isEmpty()){
            update contactUpdateList;
        }
    }
}