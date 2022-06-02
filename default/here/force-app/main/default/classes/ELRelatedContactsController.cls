/**
 * @description       : Exposure Link Related Contacts Controller
 * @author            : CRM Squad 2
 * @group             : CRM Squad 2
 * @last modified on  : 12-07-2020
 * @last modified by  : CRM Squad 2
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   11-20-2020   CRM Squad 2   Initial Version
**/
public with sharing class ELRelatedContactsController {
    /**
    * @description 
    * @author CRM Squad 2 | 11-20-2020 
    * @param recordId 
    * @param linkedCaseRecordType 
    * @return list<ContactEncounterParticipant> 
    **/
    @AuraEnabled(Cacheable = true)
    public static list<ContactEncounterParticipantWrapper> getIndividualsLinkedToCase(String recordId, String linkedCaseRecordType) {


    String expRecId = '';
    Set<String> compositeKeySet = new Set<String>();

    List<ContactEncounterParticipant> contEncParticipantList = new List<ContactEncounterParticipant>();
    List<ContactEncounterParticipantWrapper>  wrapperList  =new List<ContactEncounterParticipantWrapper>();

    String objectName = getObjectName(recordId);
    ID currentELLinkedRecordId=null;

	//The lwc of this class only support Case and Exposure Link object
    if(objectName=='Case'){
        expRecId = recordId;
    }else if (objectName=='Exposure_Link__c'){
        Exposure_Link__c expLink = [Select Exposure_Record__c,Linked_Record__c from Exposure_Link__c where ID=:recordId  WITH SECURITY_ENFORCED];
        expRecId = expLink.Exposure_Record__c;
        currentELLinkedRecordId = expLink.Linked_Record__c;
    }else{
        throw new CustomException('This object is not supported for this component');
    }

    List <Exposure_Link__c> existingELList = [select Linked_Record__c, Linked_Record__r.RecordType.Name, Exposure_Record__c from  Exposure_Link__c  where  Exposure_Record__c=:expRecId WITH SECURITY_ENFORCED LIMIT 1000];
    Set<Id> existingELCaseSet = new Set<Id>(); //All Linked_Record__c
    Set<Id> searchCaseSet = new Set<Id>();
    
        for(Exposure_Link__c elRecord: existingELList){
            existingELCaseSet.add(elRecord.Linked_Record__c);
            if (String.isNotBlank(linkedCaseRecordType) && elRecord.Linked_Record__r.RecordType.Name == linkedCaseRecordType ) {
                searchCaseSet.add(elRecord.Linked_Record__c);
            }
        }

    if(objectName=='Case'){
        //if rectype is empty , return all the linked records irrespective of record type
        if(String.isBlank(linkedCaseRecordType)){
            searchCaseSet = existingELCaseSet;
        }

    }  else if(objectName=='Exposure_Link__c'){
        Set<ID> linkIdSet = new Set<ID>();
        System.debug('currentELLinkedRecordId is:'+currentELLinkedRecordId);
        linkIdSet.add(currentELLinkedRecordId);
        searchCaseSet = linkIdSet; // add this currentELLinkedRecordId to the searchCaseSet
        System.debug('Linked Set is:'+linkIdSet);
    }

    //handle caseSet is empty
        if(!searchCaseSet.isEmpty()){

            contEncParticipantList = [SELECT ID, Record__c, Record__r.CaseNumber,Record__r.Recordtype.Name,Contact.Name,ContactEncounter.Name,Relationship_to_case__C,Parent_Record__c, Parent_Record__r.CaseNumber,Parent_Record__r.Contact.Name from ContactEncounterParticipant where Parent_Record__c in :searchCaseSet  and record__c !=null WITH SECURITY_ENFORCED];

               for(ContactEncounterParticipant contactparticipant : contEncParticipantList){
                    ContactEncounterParticipantWrapper wrapper = new ContactEncounterParticipantWrapper();
                    wrapper.participant = contactparticipant;
                    wrapper.linkExists = existingELCaseSet.contains(contactparticipant.Record__c); // check if the Record__c from CEP exist in the ALL Exposure Link records (Linked_Record__c of Exposure Link)
                    wrapperList.add(wrapper);
                }
        }
     return wrapperList;
    }

    /**
    * @description Gets Object Named using record ID
    * @author CRM Squad 2 | 11-20-2020 
    * @param currentRecordId 
    * @return String 
    **/
    @testVisible
    private static String getObjectName(String currentRecordId) {
        Id recId = (Id)currentRecordId;
        Schema.SObjectType objectType = recId.getsobjecttype();
        return String.valueOf(objectType);
    }


    public class ContactEncounterParticipantWrapper{
        @AuraEnabled
        public ContactEncounterParticipant participant{get;set;}
        @AuraEnabled
        public Boolean linkExists{get;set;}
    }

    //Custom Exception class
    public class CustomException extends Exception {
    }
}