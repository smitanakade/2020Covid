/**
 * @Author             : Santosh Bompally
 * @Description        : EHRProcedure trigger Handler
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 05/08/2021     Santosh Bompally       Feature 269587: processes for Rapid Antigen Testing test types
**/
public class EHRProcedureTriggerHandler extends TriggerHandler{
    
    
    public override void afterUpdate() {
        
         EHRProcedureTriggerHelper.createELRTask((List<HealthCloudGA__EHRProcedure__c>)Trigger.new , (Map<Id, HealthCloudGA__EHRProcedure__c>)Trigger.oldMap);
    }

}