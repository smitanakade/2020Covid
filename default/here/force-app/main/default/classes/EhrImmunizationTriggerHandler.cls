/*
Author: Arun

@Modification Log   :  
---------------------------------------------------
Date           Author      		    Details
---------------------------------------------------
15/06/2021     Arun       Feature 272348: Modified to use common trigger framework 
19/10/2021     Xiang      Feature 330357: Marketing Cloud - TREVI changes for PCC Triage message
*/
public class EhrImmunizationTriggerHandler extends TriggerHandler
{   
    public override void afterInsert() {
        EhrImmunizationTriggerHelper.updatePersonAccount(Trigger.new,null);
    }

    public override void afterUpdate() {
        EhrImmunizationTriggerHelper.updatePersonAccount(Trigger.new,(Map<Id,HealthCloudGA__EhrImmunization__c>)Trigger.oldMap);
    }
    
    public override void afterDelete() {
        EhrImmunizationTriggerHelper.updatePersonAccountDelete((Map<Id,HealthCloudGA__EhrImmunization__c>)Trigger.oldMap);
    }
}