    /*
    Author: Rahul Ankireddypalli
    @Modification Log   : 
    ---------------------------------------------------
    Date           Author      		    Details
    ---------------------------------------------------
    07/06/2021     Rahul Ankireddypalli  Feature 270261: Intial Version

    */
    public class BusinessUnitHandler extends TriggerHandler {
    
        public override void beforeInsert() {
            BusinessUnitHelper.getEmailFromGroup((List<Business_Unit__c>) Trigger.new);
        }

        public override void beforeUpdate() {
            BusinessUnitHelper.getEmailFromGroup((List<Business_Unit__c>) Trigger.new);
        }
   
    }