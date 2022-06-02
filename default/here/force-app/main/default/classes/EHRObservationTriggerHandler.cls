/*
Author: Amar Reddy

@Modification Log   : 
---------------------------------------------------
Date           Author      		    Details 
---------------------------------------------------
03/02/2021     Darko Jovanovic       Feature 255889: Modified to use common trigger framework
04/08/2021     Rejosh Mohan			 PBI 301959: Modified displayLatestTestResults method to include additional recordtypes
*/
public class EHRObservationTriggerHandler extends TriggerHandler
{   

    public override void afterInsert() {
        EHRObservationTriggerHandler.displayLatestTestResults(Trigger.new);
        EHRObservationTriggerHandler.copyPCCTestResultToSCC(Trigger.new);
    }

    @testVisible
    private static void displayLatestTestResults(List<HealthCloudGA__EhrObservation__c> EHRObservations)
    {
        List<Case> casesToBeUpdated = new List<Case>();
        Map<Id, Case> caseRecords = new Map<Id, Case>();
        for(HealthCloudGA__EhrObservation__c EHRObservation :EHRObservations )
        {
            caseRecords.put(EHRObservation.Record__c, EHRObservation.Record__r);
        }
        for(HealthCloudGA__EhrObservation__c ehrObservation : [Select Id,HealthCloudGA__IssuedDate__c ,Record__r.Latest_EHR_Observation__c,Record__r.Latest_EHR_Observation__r.HealthCloudGA__IssuedDate__c  
                                                                        from HealthCloudGA__EhrObservation__c where 
                                                                        Record__c=:caseRecords.keySet() and ( Record__r.RecordType.DeveloperName='Close_Contact' or Record__r.RecordType.DeveloperName='COVID_19_Case_Assessment' or Record__r.RecordType.DeveloperName='Secondary_Close_Contact' or Record__r.RecordType.DeveloperName='Casual_Contact'
																		or Record__r.RecordType.DeveloperName='COVID_19_Case_Screening' or Record__r.RecordType.DeveloperName='Unclassified_Contact' or Record__r.RecordType.DeveloperName='Acquisition_Contact') and 
                                                                        //Record__r.Latest_EHR_Observation__c!=null and Record__r.Latest_EHR_Observation__r.HealthCloudGA__IssuedDate__c!=null and 
                                                                        //HealthCloudGA__IssuedDate__c > Record__r.Latest_EHR_Observation__r.HealthCloudGA__IssuedDate__c and
                                                                        Id=:EHRObservations] )
        {        
            if( ehrObservation.Record__r.Latest_EHR_Observation__c==null || (ehrObservation.Record__r.Latest_EHR_Observation__c!=null && (ehrObservation.Record__r.Latest_EHR_Observation__r.HealthCloudGA__IssuedDate__c==null || ehrObservation.HealthCloudGA__IssuedDate__c > ehrObservation.Record__r.Latest_EHR_Observation__r.HealthCloudGA__IssuedDate__c) ) )
            {
                ehrObservation.Record__r.Latest_EHR_Observation__c = ehrObservation.Id;
                casesToBeUpdated.add(ehrObservation.Record__r);
            }           
        }               
        if(casesToBeUpdated.size()>0)
        {
            Database.update(casesToBeUpdated);
        }
    }
    
    @testVisible
    private static void copyPCCTestResultToSCC(List<HealthCloudGA__EhrObservation__c> EHRObservations)
    {
        List<Case> secondaryCloseContactsToBeUpdated = new List<Case>();
        Map<Id, Case> primaryCloseContacts = new Map<Id, Case>();
        for(HealthCloudGA__EhrObservation__c EHRObservation :EHRObservations )
        {
            primaryCloseContacts.put(EHRObservation.Record__c, EHRObservation.Record__r);
        }        
        for(Case closeContact : [Select Id,
                                    (Select Id,Parent_Record__c, Parent_Record__r.Latest_EHR_Observation__r.HealthCloudGA__IssuedDate__c, 
                                            Record__c,Record__r.Parent_Record_EHR_Observation__r.HealthCloudGA__IssuedDate__c 
                                     from Contact_Encounter_Participants__r
                                     where Contact_Type__c='Secondary Close Contact' and Parent_Record__c!=null and 
                                           Parent_Record__r.RecordType.DeveloperName='Close_Contact' and Record__c!=null and 
                                           Record__r.RecordType.DeveloperName='Secondary_Close_Contact')                                    
                                 from Case where Id=:primaryCloseContacts.keySet() and RecordType.DeveloperName='Close_Contact'] )
        {
            System.debug('Close Contact *** '+closeContact);
            for(ContactEncounterParticipant cep : closeContact.Contact_Encounter_Participants__r)
            {
                System.debug('Inside for loop *** '+cep);
                if(cep.Parent_Record__r.Latest_EHR_Observation__c!=null && //cep.Parent_Record__r.Latest_EHR_Observation__r.HealthCloudGA__IssuedDate__c!=null &&
                   ( cep.Record__r.Parent_Record_EHR_Observation__c==null || 
                   ( cep.Record__r.Parent_Record_EHR_Observation__c!=null && 
                   (cep.Record__r.Parent_Record_EHR_Observation__r.HealthCloudGA__IssuedDate__c==null || (cep.Record__r.Parent_Record_EHR_Observation__r.HealthCloudGA__IssuedDate__c!=null && cep.Parent_Record__r.Latest_EHR_Observation__r.HealthCloudGA__IssuedDate__c > cep.Record__r.Parent_Record_EHR_Observation__r.HealthCloudGA__IssuedDate__c))) ))
                {
                    System.debug('Inside if *** '+cep);
                    cep.Record__r.Parent_Record_EHR_Observation__c = cep.Parent_Record__r.Latest_EHR_Observation__c;
                    secondaryCloseContactsToBeUpdated.add(cep.Record__r);                   
                }
            }
        }
        if(secondaryCloseContactsToBeUpdated.size() >0)
        {
            System.debug('secondaryCloseContactsToBeUpdated *** '+secondaryCloseContactsToBeUpdated);
            Database.update(secondaryCloseContactsToBeUpdated);
        }           
    }
}