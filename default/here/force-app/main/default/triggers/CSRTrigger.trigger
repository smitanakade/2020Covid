/**
 * @Author             : DHHS
 * @Description        : Customer Survey Response trigger
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 20/11/2021     Abbas Bagichawala       : //PBI XXXXXX - Confirmed Case Interview Survey
**/
trigger CSRTrigger on Survey_Response__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    System.debug('CSR TRIGGER Started');
    new CSRTriggerHandler().run();
    System.debug('CSR Trigger Ended');
}