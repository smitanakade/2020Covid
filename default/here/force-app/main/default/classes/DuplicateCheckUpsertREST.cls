/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : Duplicate Check - custom dcUpsert REST service
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 07/02/2021     Darko Jovanovic       Hotfix 258459 (Addition of dcUpsert method): Initial version
**/
@RestResource(urlMapping='/CustomDupeCheckAPI/dhhsDCUpsert/*')
global without sharing class DuplicateCheckUpsertREST {

    /**
    * @description Custom Duplicate Check (DC) upsert. See DuplicateCheckService.dcUpsert method for description.
    * @param objectData - SObject to be inserted/updated
    * @param mergeScore - Score needed to automatically merge the record
    * @param performDupeCheck - Whether to perform a search for duplicates and subsequent merge if any found. If false, the record will simply be inserted
    * @return DCResponse - sObject data and whether it was created or merged
    */
    @HttpPost
    global static DCResponse dcUpsert(SObject objectData, Double mergeScore, Boolean performDupeCheck) {
        DuplicateCheckService.dcResult result = DuplicateCheckService.dcUpsert(objectData, mergeScore, performDupeCheck);
        DCResponse resp = new DCResponse();
        resp.objectData = result.objectData;
        resp.isCreated  = result.isCreated;
        return resp;
    }

    global class DCResponse {
        // Record data
        public SObject objectData;
        // If true, it's a brand new record. Otherwise, it was merged
        public Boolean isCreated;
    }

}
