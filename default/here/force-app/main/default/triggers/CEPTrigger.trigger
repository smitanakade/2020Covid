/*
Description: CEP Trigger 
Date: 1/12/2020
Author: Amar Reddy

@Modification Log   : 
---------------------------------------------------
Date           Author      		    Details
---------------------------------------------------
03/02/2021     Darko Jovanovic       Feature 255889: Modified to use common trigger framework
*/
trigger CEPTrigger on ContactEncounterParticipant(before insert, after update, after insert)
{
    new CEPTriggerHandler().run();
}