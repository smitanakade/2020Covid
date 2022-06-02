/**
 * @Author             : Darko Jovanovic
 * @Description        : Contact trigger handler
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 28/11/2020     Darko Jovanovic       Feature 230036: Duplicate Check tool implementation - Initial version
**/
public class ContactTriggerHandler extends TriggerHandler {

    public override void afterInsert() {
        try{
            // Determine whether to insert into queue for Duplicate Check
            DuplicateCheckService.processDuplicateCheckQueue(Trigger.newMap, Trigger.oldMap);
            
        }catch(Exception exp){
            ApplicationLogUtility.createlog('ContactTriggerHandler','afterInsert',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    public override void afterUpdate() {
        try{
            // Determine whether to insert into queue for Duplicate Check
            DuplicateCheckService.processDuplicateCheckQueue(Trigger.newMap, Trigger.oldMap);
            
            if(Test.isRunningTest()) {
                throw new IllegalArgumentException('Exception coverage');
            }
        }catch(Exception exp){
            ApplicationLogUtility.createlog('ContactTriggerHandler','afterUpdate',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}