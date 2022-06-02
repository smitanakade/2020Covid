/**
 * @Author             : Xiang Zheng
 * @Description        : Duplicate Check Delta trigger
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 15/10/2021     Xiang Zheng       PBI 320275: Merge fix - Priority for non-negatives
**/
trigger DuplicateCheckDeltaTrigger on dupcheck__dcDelta__c (before insert) {
    new DuplicateCheckDeltaTriggerHandler().run();
}