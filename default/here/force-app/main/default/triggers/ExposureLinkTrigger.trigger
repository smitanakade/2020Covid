/**
 * @Author             : Jiten Joysar 
 * @Description        : Exposure Link Trigger
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 12/04/2021     Jiten Joysar          Feature 270254: Case Allocation
**/
trigger ExposureLinkTrigger on Exposure_Link__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    new ExposureLinkTriggerHandler().run();
}