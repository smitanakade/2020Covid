/**
 * @Author             : Santosh Bompally
 * @Description        : EHRProcedure trigger
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 05/08/2021     Santosh Bompally       Feature 269587: processes for Rapid Antigen Testing test types
**/
trigger EHRProcedureTrigger on HealthCloudGA__EHRProcedure__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	new EHRProcedureTriggerHandler().run();
}