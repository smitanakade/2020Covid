/*
Author: Arun

@Modification Log   : 
---------------------------------------------------
Date           Author      		    Details 
---------------------------------------------------
15/06/2021     Arun       Feature 272348: Update person account details
*/
trigger EhrImmunizationTrigger on HealthCloudGA__EhrImmunization__c (after insert,after delete,after update) 
{
    new EhrImmunizationTriggerHandler().run();
}