/*
Author: Amar Reddy

@Modification Log   : 
---------------------------------------------------
Date           Author      		    Details
---------------------------------------------------
03/02/2021     Darko Jovanovic       Feature 255889: Modified to use common trigger framework
*/
trigger EHRObservationTrigger on HealthCloudGA__EhrObservation__c (after insert) 
{
    new EHRObservationTriggerHandler().run();
}