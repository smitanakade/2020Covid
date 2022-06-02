/**
 * @Author             : YPerera
 * @Description        : Handler class for ContactEncounterTrigger
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 29/04/2021     YPerera		        Initial version
**/
public class ContactEncounterTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert() {
       ContactEncounterTriggerHelper.updatestartitime((List<ContactEncounter>)Trigger.new);
    }

    public override void afterUpdate() {
        ContactEncounterTriggerHelper.updateToMostRecentEndDateOnPCC((List<ContactEncounter>)Trigger.new, (Map<Id, ContactEncounter>)Trigger.oldMap);
    }
    
   

}