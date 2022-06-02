/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : Duplicate Check - custom dcMerge REST service
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 07/02/2021     Darko Jovanovic       Hotfix 258459 (Addition of dcMerge method): Initial version
**/
@RestResource(urlMapping='/CustomDupeCheckAPI/dhhsDCMerge/*')
global without sharing class DuplicateCheckMergeREST {

    /**
    * @description Custom Duplicate Check (DC) merge. For description, see the corresponding method in DuplicateCheckService
    * @param objectData - SObject to be inserted
    * @param matchingDuplicates - Ids of matching duplicates returned by Duplicate Check search
    * @return DCResponse - sObject data and whether it was created or merged
    */
    @HttpPost
    global static DCResponse dcMerge(SObject objectData, List<Id> matchingDuplicates) {
        DuplicateCheckService.dcResult result = DuplicateCheckService.dcMerge(objectData, new Set<Id>(matchingDuplicates));
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