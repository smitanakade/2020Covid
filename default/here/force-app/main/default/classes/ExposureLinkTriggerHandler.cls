/**
 * @Author             : Jiten Joysar 
 * @Description        : Exposure Link Trigger Handler
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 12/04/2021     Jiten Joysar          Feature 270254: Case Allocation
 * 17/09/2021     Pratyush Chalasani    Revert 270278: Reverting code to JJ's previous version (see commit 3bc43d8bf6cbeb4c046b5b58aae3c54ae633a3b8)
**/
public class ExposureLinkTriggerHandler extends TriggerHandler{
    
    private static Map<Id,Case> exposureRecordsMap;
    private static Map<Id,Case> linkedRecordsMap;
    private static List<Case> linkedRecordListToUpdate = new List<Case>();

    public override void afterInsert() {
       
        identifyExposureLinkRecordsForCaseAllocation();
    }

    /********************************************************************/
    /* Case allocation - Function to filter Exposure Link records which are 
     required to process case allocation logic for linked record
    /*******************************************************************/
    private static void identifyExposureLinkRecordsForCaseAllocation(){

        List<Id> exposureRecordIds = new List<Id>();
        List<Id> linkedRecordIds = new List<Id>();
        for (Exposure_Link__c exposureLinkObj : (List<Exposure_Link__c>) Trigger.new){
            if(exposureLinkObj.Linked_Record__c != null){
                exposureRecordIds.add(exposureLinkObj.Exposure_Record__c);
                linkedRecordIds.add(exposureLinkObj.Linked_Record__c);
            }
        }  
        
        if(linkedRecordIds.size() > 0){

            linkedRecordsMap = new Map<ID, Case>([SELECT Id, recordTypeId, status, ownerId, Is_case_allocation_completed__c, (SELECT Id, Exposure_Record__r.Site_type__c, Exposure_Record__r.RecordTypeId, Exposure_Record__r.ownerId FROM Linked_Records_Linked__r WHERE Exposure_Record__r.Site_type__c = 'Exposure site' ORDER BY CreatedDate DESC) from Case WHERE Id IN : linkedRecordIds FOR UPDATE]);
            exposureRecordsMap = new Map<ID, Case>([SELECT Id, recordTypeId, ownerId, Site_type__c from Case WHERE Id IN : exposureRecordIds FOR UPDATE]);
            processLinkedRecordWithCaseAlllocation();

        } 
    }
    
    /********************************************************************/
    /* Case allocation - Process Linked records (Case records) with 
    exposure link/ outbreak case allocation
    /*******************************************************************/
    private static void processLinkedRecordWithCaseAlllocation(){

        if(linkedRecordsMap != null && linkedRecordsMap.size() > 0){

            for (Exposure_Link__c exposureLinkObj : (List<Exposure_Link__c>) Trigger.new){
                
                if(linkedRecordsMap.containsKey(exposureLinkObj.Linked_Record__c)){
                    case linkedRecord = linkedRecordsMap.get(exposureLinkObj.Linked_Record__c);
                    case exposureRecord = exposureRecordsMap.get(exposureLinkObj.Exposure_Record__c);
                    
                    if( CaseQueueAllocator.RECORDTYPE_BY_ID.get(exposureRecord.RecordTypeId).DeveloperName == 'Outbreak' &&
                       (CaseQueueAllocator.RECORDTYPE_BY_ID.get(linkedRecord.RecordTypeId).DeveloperName == 'Close_Contact' || CaseQueueAllocator.RECORDTYPE_BY_ID.get(linkedRecord.RecordTypeId).DeveloperName == 'Secondary_Close_Contact') && 
                       linkedRecord.status == 'Identify' && (exposureRecord.Site_type__c == 'Exposure site' || exposureRecord.Site_type__c == 'Outbreak') && 
                       linkedRecord.ownerId != exposureRecord.ownerId){

                            if(exposureRecord.Site_type__c == 'Outbreak'){
                                // Check if there are existing Site exposure with same person (According to AC3)
                                List<Exposure_Link__c> existingRelatedExposureRecordList = linkedRecord.Linked_Records_Linked__r;
                                if(existingRelatedExposureRecordList != null && existingRelatedExposureRecordList.size() > 0){

                                    for (Exposure_Link__c existingExposureRecord : existingRelatedExposureRecordList){

                                        if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(existingExposureRecord.Exposure_Record__r.RecordTypeId).DeveloperName == 'Outbreak' && existingExposureRecord.Exposure_Record__r.ownerId != linkedRecord.ownerId){
                                            linkedRecord.ownerId = existingExposureRecord.Exposure_Record__r.ownerId;
                                            linkedRecord.Is_case_allocation_completed__c = true;
                                            linkedRecordListToUpdate.add(linkedRecord);
                                            break;
                                        }
                                    }    
                                } else{
                                    linkedRecord.ownerId = exposureRecord.ownerId;
                                    linkedRecord.Is_case_allocation_completed__c = true;
                                    linkedRecordListToUpdate.add(linkedRecord);
                                }
                            } else{
                                linkedRecord.ownerId = exposureRecord.ownerId;
                                linkedRecord.Is_case_allocation_completed__c = true;
                                linkedRecordListToUpdate.add(linkedRecord);
                            }
                
                            
                    }
                }

            } 
            if(linkedRecordListToUpdate != null && linkedRecordListToUpdate.size() > 0)
                update linkedRecordListToUpdate;
        }
    }    
}