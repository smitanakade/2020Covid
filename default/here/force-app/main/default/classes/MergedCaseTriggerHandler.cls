/**
 * @Author             : Pratyush Chalasani
 * @Description        : Merged Case trigger handler
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 29/03/2021     Pratyush Chalasani    Hotfix 272728: Initial version - Update Merged Case with previous Case IDs
**/
public with sharing class MergedCaseTriggerHandler {
    public void run() {
        if(trigger.isAfter && trigger.isInsert) {
            AfterInsert(trigger.new);
        }
    }

    public void AfterInsert(List<Merged_Case__e> mergedCaseList) {
        updateMasterCase(mergedCaseList);
    }

    public void updateMasterCase(List<Merged_Case__e> mergedCaseList) {
        List<Case> listCaseToUpdate = new List<Case>();
        
        for(Merged_Case__e mergedCase : mergedCaseList) {
            //listCaseToUpdate.add(new Case(Id = mergedCase.Master_Case_ID__c, Merged_Case_IDs__c = mergedCase.Merged_Case_IDs__c));
        }
        
        if(listCaseToUpdate.size() > 0)
            update listCaseToUpdate;
    }
}