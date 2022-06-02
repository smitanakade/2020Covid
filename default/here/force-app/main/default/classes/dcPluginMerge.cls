/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : Merge plugin for Duplicate Check
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 11/02/2021     Darko Jovanovic    Hotfix 258342 (Incorporate custom merge rules): Initial version
 * 01/11/2021     Pratyush Chalasani Hotfix 333183: Record IDs no longer searchable (shift logic from afterMerge to beforeMerge)
**/
global class dcPluginMerge implements dupcheck.dc3Plugin.InterfaceMerge {
    // #261231: Mapping from MasterRecord ID to merged case numbers
    private static Map<Id, List<String>> mergedCaseMap = new Map<Id, List<String>>();
    //Added this flag to check the Mergeing Scenario PBI 336537
    Public static boolean isMerging=false;
    global void beforeMerge(String objectPrefix, SObject masterRecord, List<SObject> mergedRecordList) {
        try {
            //Added this flag to check the Mergeing Scenario PBI 336537
            isMerging=true;
            if (objectPrefix == '500') {
                // #261231: Store all CaseNumbers from deleted Cases, mapped to Master Case Id
                List<String> mergedNumbers = mergedCaseMap.get(masterRecord.Id);

                if (mergedNumbers == null) {
                    mergedNumbers = new List<String>();
                }

                for (Case merged: (List<Case>)mergedRecordList) {
                    mergedNumbers.add(merged.CaseNumber);
                }

                if (mergedNumbers != null && !mergedNumbers.isEmpty()) {
                    masterRecord.put('Merged_Case_IDs__c', formatCaseNumbers((String)masterRecord.get('Merged_Case_IDs__c'), mergedNumbers));
                }
            }
        } catch (Exception e) {
            ApplicationLogUtility.createlog('dcPluginMerge', 'beforeMerge', e.getStackTraceString(), e.getMessage(), e.getTypeName());

            throw e;
        }
    }
 
    global void mergeFailed(String objectPrefix, SObject masterRecord, Set<Id> mergedRecordsIds, dupcheck.dc3Exception.MergeException exceptionData) {
        return;
    }
 
    global void afterMerge(String objectPrefix, SObject masterRecord, Set<Id> mergedRecordIds) {
        try {
            // If a Person Account record was merged, find all the re-parented cases and rebuild the index for them so they are correctly identified as duplicates (as we use AccountId in the scenario)
            // We also have to reset the AccountIdText__c field which is used for indexing. 
            // Reason why we have to do this is because when cases are re-parented, the trigger doesn't run and hence the Duplicate Search index is not rebuilt
            if (objectPrefix == '001P') {
                List<Case> reparentedCaseList = 
                    [SELECT Id
                    FROM Case
                    WHERE AccountId = :masterRecord.Id];
                Set<Id> caseIds = new Set<Id>();
                for (Case reparentedCase : reparentedCaseList) 
                {
                    caseIds.add(reparentedCase.Id);
                    reparentedCase.AccountIdText__c = masterRecord.Id;
                } 
                if (!caseIds.isEmpty()) {
                    // Update AccountIdText__c field before running the indexing process so the field will get included in the index. For performance reasons, skip the Case trigger
                    TriggerHandler.bypass('CaseTriggerHandler');
                    update reparentedCaseList;
                    // Rebuild index for the related cases
                    dupcheck.dc3Api.doIndex(caseIds);
                }

                //#305103: If the primary address from a merged account is different to the master account,
                // then publish an event to asynchronously store it as a ContactPointAddress
                List<Account_Changed_Address__e> changeEvents = new List<Account_Changed_Address__e>();

                for (Id mergedID: mergedRecordIds) {
                    changeEvents.add(new Account_Changed_Address__e(Account_ID__c = masterRecord.Id, Merged_ID__c = mergedID));
                }

                if (!changeEvents.isEmpty()) {
                    try {
                        EventBus.publish(changeEvents);
                    } catch (Exception e) {
                        System.debug('Publish exception: ' + e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            ApplicationLogUtility.createlog('dcPluginMerge', 'afterMerge', e.getStackTraceString(), e.getMessage(), e.getTypeName());

            throw e;
        }
    }

    /**
    * @description Parses existing case numbers, appends new case numbers to list, and returns formatted string
    * @param original   Merged case numbers currently stored against a master Case
    * @param newNumbers List of new case numbers to be added
    * @return Comma separated list of case numbers
    **/
    private static String formatCaseNumbers(String original, List<String> newNumbers) {
        List<String> allNumbers = new List<String>();
        
        // Build a list of merged numbers already stored for Case, trimming any excess whitespace
        if (String.isNotBlank(original)) {
            for (String num: original.split(',')) {
                String trimmed = (num == null) ? '' : num.trim();

                if (String.isNotBlank(trimmed)) allNumbers.add(trimmed);
            }
        }
        
        if (!newNumbers.isEmpty()) {
            for (String num: newNumbers) {
                if (!allNumbers.contains(num)) allNumbers.add(num);
            }
        }

        return String.join(allNumbers, ',');
    }
}