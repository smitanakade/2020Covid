/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : Duplicate Check - service class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 26/11/2020     Darko Jovanovic       Feature 230036: Duplicate Check tool implementation - initial version
 * 03/02/2021     Darko Jovanovic       Hotfix 258459: Added dcUpsert and dcMerge methods
**/
public class DuplicateCheckService {

    public static final String CONST_SKIP_INSERT_STATUS = 'In Progress';
    public static final String CONST_INSERT_STATUS      = 'Inserted';
    public static final Integer CONST_DEFAULT_PRIORITY  = 10;
    
    /**
    * @description Process Duplicate Check queues, whether to insert or not. 
    * More specifically, for Duplicate Check tool, Unique Import / API Bulk Insert is turned off at the object level (Duplicate Check > Object Name > Object Name Settings tab)
    * The reason for this is so that we can control the insertion of records into the Duplicate Check queue to avoid race condition errors (e.g. if we're inserting account records, then cases for those account while the duplicate merge is running). Thus the purpose of this method. 
    * ASSUMPTIONS: 
    * - Custom fields for Duplicate Check are present on the object being inserted/updated
    * - All objects in objectNewMap and objectOldMap are of the same object type (e.g. all Accounts or all Coontacts etc)
    * @param objectListNew - List of objects inserted/updated
    * @param objectListOld - List of objects inserted/updated - old values (null for inserts, only set for updates) 
    * @return List<dupcheck__dcDelta__c> Duplicate queue records inserted, if any
    */
    public static List<dupcheck__dcDelta__c> processDuplicateCheckQueue(Map<Id, SObject> objectNewMap, Map<Id, SObject> objectOldMap) {
        List<dupcheck__dcDelta__c> duplicateQueue = new List<dupcheck__dcDelta__c>();
        // Since Unique Import / API Bulk Insert means more than 1 record in Duplicate Check tool, we check whether more than one record was updated. Other scenarios (Single API etc) are handled by the Duplicate Check trigger
        if (objectNewMap.size() <= 1) return duplicateQueue;
        // Get list of fields for the object - we'll need them below
        Set<String> sObjectFieldList = ((objectNewMap.values())[0]).getSobjectType().getDescribe().fields.getMap().keySet();
        // For each record
        for (SObject obj : objectNewMap.values())
        {
            // Check whether dc check is to be skipped for this particular record (could be either standard or custom flag)
            Boolean skipDcCheck = false;
            String skipDcCheckStandardFieldName = 'dupcheck__dc3DisableDuplicateCheck__c';
            String skipDcCheckCustomFieldName   = 'dc3DisableDuplicateCheck__c';
            if (sObjectFieldList.contains(skipDcCheckStandardFieldName.toLowerCase())) {
                skipDcCheck = (Boolean) obj.get(skipDcCheckStandardFieldName);
            } else {
                if (sObjectFieldList.contains(skipDcCheckCustomFieldName.toLowerCase())) {
                    skipDcCheck = (Boolean) obj.get(skipDcCheckCustomFieldName);
                }
            }
            if (!skipDcCheck) {
                // Check whether the duplicate queue status flag exists and whether it's been set to a value to indicate to skip the queue insert
                Id objectId             = (Id) obj.get('Id');
                String queueStatus      = (String) obj.get('DC_queue_status__c');
                Integer queuePriority   = Integer.valueOf((Decimal) obj.get('DC_queue_priority__c'));
                if (queuePriority == null)  queuePriority = CONST_DEFAULT_PRIORITY;
                Boolean insertIntoQueue = false;
                if (objectOldMap == null) {
                    // Insert - insert if queue status if not the one to skip
                    if (queueStatus != CONST_SKIP_INSERT_STATUS) {
                        insertIntoQueue = true;
                    }
                } else {
                    // Update - insert only if queue status was changed from In Progress to Inserted. Duplicate Check does not perform checks for bulk updates
                    String previousQueueStatus = (String)(objectOldMap.get(objectId)).get('DC_queue_status__c');
                    if (queueStatus == CONST_INSERT_STATUS && previousQueueStatus == CONST_SKIP_INSERT_STATUS) {
                        insertIntoQueue = true;
                    }
                }
                if (insertIntoQueue == true) {
                    dupcheck__dcDelta__c queueRecord = new dupcheck__dcDelta__c();
                    queueRecord.dupcheck__object__c      = objectId;
                    queueRecord.dupcheck__Priority__c    = queuePriority;
                    queueRecord.dupcheck__Type__c        = 'BULK_INSERT';
                    duplicateQueue.add(queueRecord);
                }
            }  
        }    
        insert duplicateQueue;
        return duplicateQueue;
    }

    /**
    * @description Custom Duplicate Check (DC) upsert. This method makes use of Duplicate Check Apex API to:
    * 1. Perform a DC search to check if the record about to be inserted is a duplicate, based on the mergeScore
    * 2. If so, use DC merge to merge it with the existing record according to the Merge Rules and returns the merged record
    * 3. If not, simply inserts the new record and returns it
    * @param objectData - SObject to be inserted/updated
    * @param mergeScore - Score needed to automatically merge the record
    * @param performDupeCheck - Whether to perform a search for duplicates and subsequent merge if any found. If false, the record will simply be inserted
    * @return DCResult - Record inserted or the merged record
    */
    public static DCResult dcUpsert(SObject objectData, Double mergeScore, Boolean performDupeCheck) {
        // -----------------------------
        // INIT
        // -----------------------------
        DCResult result = new DCResult();
        result.objectData   = objectData;
        result.isCreated    = true;
        Schema.DescribeSObjectResult sObjectDescribeResult = objectData.getSObjectType().getDescribe();
        System.debug('Input - objectData: ' + objectData);
        System.debug('Input - mergeScore: ' + mergeScore);
        // -----------------------------
        // CHECK IF UPDATE
        // -----------------------------
        if (objectData.id != null) {
            // If Object Id was provided, then simply perform an update - no need to run Duplicate Check search/merge
            System.debug('Existing record - simply update, no need to run Duplicate Check search/merge');
            result.isCreated = false;
            update objectData;
            return result;
        }
        // -----------------------------
        // INSERT RECORD
        // -----------------------------
        if (!performDupeCheck) {
            // If Duplicate Check and subsequent merge is to be skipped, simply return the inserted record
            System.debug('Inserting record - no dupe check');
            insert objectData;
            return result;
        }
        // Check objectPrefix. This can only be done once Record Type is retrieved (as Record Type can be blank initially)
        String objectPrefix     = sObjectDescribeResult.getKeyPrefix();
        if (objectPrefix == '001') {
            if ((Id) objectData.get('RecordTypeId') == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId()) {
                objectPrefix = '001P';
            }
        }
        System.debug('objectPrefix: ' + objectPrefix);
        // -----------------------------
        // CHECK FOR DUPLICATES
        // -----------------------------
        // Call Duplicate Check Apex API doSearch method to check for duplicates
        System.debug('Checking for duplicates');
        Map<String, List<dupcheck.dc3SearchResult>> searchResult;
        Set<Id> matchingDuplicates = new Set<Id>();
        dupcheck.dc3Api dcApi = new dupcheck.dc3Api(); 
        try {
            if (test.isRunningTest()) {
              searchResult = new Map<String, List<dupcheck.dc3SearchResult>>();
              searchResult.put('500', new List<dupcheck.dc3SearchResult>());
              dupcheck.dc3SearchResult dup1 = new dupcheck.dc3SearchResult();
              dup1.score = 100;
              dup1.objectData = [SELECT ID FROM Case LIMIT 1];
              searchResult.get('500').add(dup1);
            } else {
              searchResult = dcApi.doSearch(objectData.getPopulatedFieldsAsMap().clone(), objectPrefix);
            }
        }
        catch (dupcheck.dc3Exception.ConfigurationException e) {
            // No object configuration
            System.debug('No Duplicate Check configuration specified - simply return the inserted record');
            insert objectData;
            return result;
        }
        catch (dupcheck.dc3Exception.NoScenarioException e) {
            // No scenarios exception
            System.debug('No scenarios specified - simply return the inserted record');
            insert objectData;
            return result;
        }
        catch (Exception e) {
            // Other exception
            throw e;
        }
        // Extract duplicate records if they match the given score
        System.debug('searchResult: ' + searchResult);
        if (searchResult.containsKey(objectPrefix)) { 
            for (dupcheck.dc3SearchResult firstDuplicate : searchResult.get(objectPrefix)) {
                if (firstDuplicate.score >= mergeScore) {
                    System.debug('Potential duplicate: ' + firstDuplicate.objectData);
                    System.debug('Duplicate score: ' + firstDuplicate.score);
                    matchingDuplicates.add(firstDuplicate.objectData.Id);
                }
            }   
        }
        // -----------------------------
        // MERGE DUPLICATES, IF ANY
        // -----------------------------
        if (!matchingDuplicates.isEmpty()) {
            System.debug('Duplicates found - merge');
            return dcMerge(objectData, matchingDuplicates);
        } else {
            insert objectData;
            System.debug('No duplicate found');
        }
        return result;
    }

    /**
    * @description Custom Duplicate Check (DC) merge. This method makes use of Duplicate Check Apex API to merge the give record after insertion
    * @param objectData - SObject to be inserted
    * @param matchingDuplicates - Ids of matching duplicates returned by Duplicate Check search
    * @return SObject - Merged record
    */
    public static DCResult dcMerge(SObject objectData, Set<Id> matchingDuplicates) {
        Schema.DescribeSObjectResult sObjectDescribeResult = objectData.getSObjectType().getDescribe();
        String objectAPIName    = sObjectDescribeResult.getName();
        System.debug('Input - objectData: ' + objectData);
        System.debug('Input - matchingDuplicates: ' + matchingDuplicates);
        System.debug('objectAPIName: ' + objectAPIName);
        // First, insert the record
        insert objectData;
        System.debug('Insert finished');
        // Records to merge list = matching duplicates + newly-inserted record
        matchingDuplicates.add(objectData.Id);
        List<SObject> recordsToMerge = database.query('SELECT ' + UtilityClass.getAllFieldsForQuery(objectAPIName) + ' FROM ' + objectAPIName + ' WHERE Id IN :matchingDuplicates');
        System.debug('Query finished');
        // Get the master record and perform the merge according to the merge rules
        dupcheck.dc3Api dcApi = new dupcheck.dc3Api(); 
        SObject masterRecord = dcApi.getMergeMaster(recordsToMerge);
        System.debug('masterRecord: ' + masterRecord);
        Boolean mergeSuccess = dcApi.doMerge(recordsToMerge, masterRecord);
        if (!mergeSuccess) {
            throw new DCUpsertMergeException();
        }
        System.debug('Merge finished');
        DCResult result = new DCResult();
        result.objectData   = masterRecord;
        result.isCreated    = false;
        return result;
    }

    public class DCResult {
        // Record data
        public SObject objectData;
        // If true, it's a brand new record. Otherwise, it was merged
        public Boolean isCreated;
    }

    // Merge exception
    public class DCUpsertMergeException extends Exception {}
    
}