/**
 * @Author             : Pratyush Chalasani
 * @Description        : Merged Case trigger handler
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 29/03/2021     Pratyush Chalasani    Hotfix 272728: Initial version - Update Merged Case with previous Case IDs
**/
trigger MergedCaseTrigger on Merged_Case__e (after insert) {
    new MergedCaseTriggerHandler().run();
}