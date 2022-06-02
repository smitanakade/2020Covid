/**
* @Author             : Darko Jovanovic
* @Description        : Account trigger handler
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author      		    Details
* ---------------------------------------------------
* 28/11/2020     Darko Jovanovic       Feature 230036: Duplicate Check tool implementation - Initial version
* 05/08/2021     Smita Kagde           PBI-308974 Marketing Cloud - Ensure phone formatting retained on update from frontend
* 23/06/2021     Sai Kallu      	   Feature 277236: Cross Border Notifications - Identification
* 26/08/2021     Pratyush Chalasani    Feature 305103: Address Management - ELR merge rules
* 06/09/2021     Pratyush Chalasani    Bugfix 318957:  CPA address with ELR is not created when person account primary address is different to incoming ELR primary address
* 20/09/2021     Pratyush Chalasani   Feature 323048: Shift trigger functions to dcPluginMerge (removed code from here)
* 01/11/2021     Arun                  Async Trigger Handler and create Support Task

**/
public class AccountTriggerHandler extends TriggerHandler {
    
    public override void afterInsert() {
        // Determine whether to insert into queue for Duplicate Check
        DuplicateCheckService.processDuplicateCheckQueue(Trigger.newMap, Trigger.oldMap);
      //For asynch trigger handler (should be at the end)
      PETriggerHandlerUtil.publishAsyncEvents('Account', 'insert', Trigger.New, Trigger.oldMap);
 }
    
    public override void afterUpdate() {
        // Determine whether to insert into queue for Duplicate Check
        DuplicateCheckService.processDuplicateCheckQueue(Trigger.newMap, Trigger.oldMap);
        //For asynch trigger handler (should be at the end)
        PETriggerHandlerUtil.publishAsyncEvents('Account', 'update', Trigger.New, Trigger.oldMap);
  }
    public override void beforeInsert() {
        //PBI-308974
		AccountTriggerHelper.modifyPersonMobileNumber((List<Account>)Trigger.new );
    }
    public override void beforeUpdate() {
        //PBI-308974
        AccountTriggerHelper.modifyPersonMobileNumber((List<Account>)Trigger.new);
    }

    public override void afterDelete() {
        
    }

    /*
    public override void beforeUpdate() {
        //Feature 277236: Cross Border Notifications - Identification
        CrossBorderNotification.validateCrossBorderIdentificationFlags(Trigger.newMap, Trigger.oldMap);
    }
    */
    
}