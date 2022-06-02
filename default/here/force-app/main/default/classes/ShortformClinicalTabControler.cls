/*
 * @Author             : Xiang Zheng
 * @Description        : related PBI 318325, controler of the dhhs_Shortform_ClinicalTab LWC
 * @Modification Log   : 
 * --------------------------------------------------------------------------------------
 * Date           Author      		    Details
 * --------------------------------------------------------------------------------------
 * 04/09/2021     Xiang Zheng           Initial version
 * 17/09/2021     Xiang Zheng           add createWSCRecord method for PBI 321059
 * 22/10/2021     Hemant SIngh          PBI-330249: Populating StartDate field in HMIP record for 'Hospital Admission'
 * 17/11/2021     LJ                    PBI- 334338 update for  Travel history details
*/
public without sharing class ShortformClinicalTabControler {

    //save related records
    @AuraEnabled
    public static String createRecords(FormWrapper theData){
        system.debug('theData-------------------'+theData);
        String message;
        Id accountId;


        WorkOrder theWorkOrder = [SELECT Id, Case.Id, Case.Contact_hospital_14_days_prior_symptoms__c,Case.AccountId, AccountId,Clinical_Information_First_Submit__c FROM WorkOrder WHERE Id = :theData.workOrderId];

        
        if(theWorkOrder != null){
            if(theWorkOrder.AccountId == null && (theWorkOrder.Case == null || theWorkOrder.Case.AccountId == null)){
                message = 'Account Or Case is empty.';
                return message;
            }

            try{
                //update Contact_hospital_14_days_prior_symptoms__c field on Case
                Case theCase = theWorkOrder.Case;
                theCase.Contact_hospital_14_days_prior_symptoms__c = theData.contactHospital14DaysPriorSymptoms;
                theCase.Was_aware_of_contact_with_ve_case__c = theData.wasAwareOfContactWithCase;
                theCase.Isolation_Quarantine_48_hrs_prior_to_sym__c = theData.isolationQuarantine48HrsPriorToSym;

                if(theData.ifYesCommencedOn != null){
                    theCase.If_yes_Commenced_on__c = Date.valueOf(theData.ifYesCommencedOn);
                }

                if(theData.haveAnySymptoms == 'No'){
                    theCase.Asymptomatic__c	= true;
                }
                
                update theCase;
                
                //create Clinical Assessment Response record when 'Did the case have symptoms?' is 'Yes'
                if(theData.haveAnySymptoms == 'yes'){
                    HealthCloudGA__Clinical_Assessment_Response__c newCAR = new HealthCloudGA__Clinical_Assessment_Response__c();
                    newCAR.Did_person_have_symptoms__c = theData.haveAnySymptoms;

                    if(theData.dateOfFirstSymptoms != null){
                        newCAR.HealthCloudGA__OnsetOfSymptoms__c = Date.valueOf(theData.dateOfFirstSymptoms);
                    }
                    
                    newCAR.Record__c = theCase.Id;
                    newCAR.HealthCloudGA__Patient__c = theWorkOrder.AccountId==null?theWorkOrder.Case.AccountId:theWorkOrder.AccountId;
                    insert newCAR;
                }
                
                //create EHR Immunization record when 'Date of first symptoms' has value
                if(theData.hadVaccine == 'true'){  
                    HealthCloudGA__EhrImmunization__c newEI = new HealthCloudGA__EhrImmunization__c();
                    newEI.Have_you_had_a_COVID_19_vaccine__c = theData.hadVaccine == 'true'?true:false;
                    newEI.Dose_Received__c = theData.dose;

                    Id theAccountId = theWorkOrder.AccountId==null?theWorkOrder.Case.AccountId:theWorkOrder.AccountId;
                    List<Contact> theContact = [SELECT Id FROM Contact WHERE AccountId = :theAccountId LIMIT 1];
                    if(theContact.size() > 0){
                        newEI.Contact__c = theContact[0].Id;
                    }
                    insert newEI;
                } 

                //create HMIP record when 'When did you commence home isolation?' has value
                if(theData.startDate != null){  
                    HealthCloudGA__EhrEncounter__c newEE = new HealthCloudGA__EhrEncounter__c();
                    newEE.StartDate__c = Date.valueOf(theData.startDate);
                    newEE.Record__c = theCase.Id;
                    newEE.Presented_to__c = 'Home isolation';
                    insert newEE;
                }

                //Create contactEncounter details for Travel details 334338
                if(theData.recentTravelOverseas == 'Yes'){  

                    ContactEncounter newContactEncounterRec = new ContactEncounter();

                    Id travelHistoryRecordtypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Travel_History').getRecordTypeId();

                    Id theAccountId = theWorkOrder.AccountId==null?theWorkOrder.Case.AccountId:theWorkOrder.AccountId;
                    List<Contact> theContact = [SELECT Id FROM Contact WHERE AccountId = :theAccountId LIMIT 1];
                    if(theContact.size() > 0){
                        newContactEncounterRec.Contact_Person__c = theContact[0].Id;
                    }

                    
                    newContactEncounterRec.RecordTypeId = travelHistoryRecordtypeId;
                    newContactEncounterRec.Name = 'Returned Traveller';
                    newContactEncounterRec.Recent_Travel_Overseas__c = theData.recentTravelOverseas;
                    newContactEncounterRec.Country__c = theData.countryOverseas;
                    newContactEncounterRec.Work_Order__c = theWorkOrder.Id;
                    newContactEncounterRec.Record__c = theCase.Id;
                    newContactEncounterRec.StartTime = System.now();

                    insert newContactEncounterRec;
                }


                //create HMIP record when 'If you are currently in Hospital, what date were you admitted?' has value
                if(theData.dateAdmitted != null){  
                    HealthCloudGA__EhrEncounter__c newEE1 = new HealthCloudGA__EhrEncounter__c();
                    newEE1.Date_admitted__c = Date.valueOf(theData.dateAdmitted);
                    newEE1.StartDate__c = Date.valueOf(theData.dateAdmitted);
                    newEE1.HealthCloudGA__Account__c = theData.hospital;
                    newEE1.Record__c = theCase.Id;
                    newEE1.Presented_to__c = 'Hospital admission';
                    insert newEE1;
                }

                theWorkOrder.Clinical_Information_First_Submit__c = system.now();
                update theWorkOrder;
                
                message = 'success';
            }catch(Exception ex){
                message = ex.getMessage();
                System.debug('Exception occurred ------------'+ex.getMessage());
            }
        }

        return message;
    }

    //check the account record type, it should be 'Business' 
    @AuraEnabled(cacheable=true)
    public static String checkAccountRecordType(String accountId){
        String result = 'false';
        List<Account> acc = [SELECT Id FROM Account WHERE Id = :accountId AND recordType.Name = 'Business'];

        if(acc!=null && !acc.isEmpty()){
            result = 'true';
        }
        return result;
    }

    //wrapper class
    public class FormWrapper{
        @AuraEnabled
        public String workOrderId{get;set;}

        @AuraEnabled
        public String haveAnySymptoms{get;set;}

        @AuraEnabled
        public String dateOfFirstSymptoms{get;set;}

        @AuraEnabled
        public String hadVaccine{get;set;}

        @AuraEnabled
        public String dose{get;set;}

        @AuraEnabled
        public String startDate{get;set;}

        @AuraEnabled
        public String contactHospital14DaysPriorSymptoms{get;set;}

        @AuraEnabled
        public String dateAdmitted{get;set;}

        @AuraEnabled
        public String hospital{get;set;}

        @AuraEnabled
        public String wasAwareOfContactWithCase{get;set;}

        @AuraEnabled
        public String isolationQuarantine48HrsPriorToSym{get;set;}

        @AuraEnabled
        public String ifYesCommencedOn{get;set;}

        @AuraEnabled
        public String countryOverseas{get;set;}

        @AuraEnabled
        public String recentTravelOverseas{get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static workorder getdisabilitydetails( Id workorderid) {
        return [ SELECT Id, caseid, case.Does_record_have_disability__c, case.Does_record_receive_disability_support__c FROM workorder where id = :workorderid  LIMIT 1 ];
    }

    //save ContactEncounter record
    @AuraEnabled
    public static String createWSCRecord(ContactEncounter theData){
        String message;
        String recordTypeId  = Schema.getGlobalDescribe().get('ContactEncounter').getDescribe().getRecordTypeInfosByName().get('Work/Study/Care').getRecordTypeId();
        
        try{
            if(theData.Occupation__c != null){
                Occupation__c occ = [SELECT Name FROM Occupation__c WHERE Id = :theData.Occupation__c];
                theData.Name = occ.Name;//required field
            }

            if(String.isEmpty(theData.Name)){
                theData.Name = theData.Employment_Status__c;
            }

            if(String.isEmpty(theData.Name)){
                theData.Name = 'Unknown';
            }

            theData.StartTime = System.now();//required field

            WorkOrder wo = [SELECT Id, CaseId  FROM WorkOrder WHERE Id = :theData.Work_Order__c];
            theData.Record__c  = wo.CaseId;
            theData.RecordTypeId = recordTypeId;

            insert theData;

            message = 'success';
        }catch(Exception ex){
            message = ex.getMessage();
            System.debug('Exception occurred ------------'+ex.getMessage());
        }

        return message;
    }

    @AuraEnabled
    public static String getContactId(String workOrderId){
        System.debug('workOrderId------------'+workOrderId);
        String contactId;
        WorkOrder theWorkOrder = [SELECT Case.Id,Case.AccountId, AccountId FROM WorkOrder WHERE Id = :workOrderId];

        Id theAccountId = theWorkOrder.AccountId==null?theWorkOrder.Case.AccountId:theWorkOrder.AccountId;
        List<Contact> theContact = [SELECT Id FROM Contact WHERE AccountId = :theAccountId LIMIT 1];
        if(theContact.size() > 0){
            contactId = theContact[0].Id;
        }

        return contactId;
    }
}