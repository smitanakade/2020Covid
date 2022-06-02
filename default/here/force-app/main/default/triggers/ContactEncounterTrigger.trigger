/**
 * @Author             : YPerera
 * @Description        : Trigger for ContactEncounterTrigger
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 29/04/2021     YPerera		        
**/
trigger ContactEncounterTrigger on ContactEncounter (before insert, after insert, before update, after update, before delete, after delete, after undelete) {

    new ContactEncounterTriggerHandler().run();
    
}