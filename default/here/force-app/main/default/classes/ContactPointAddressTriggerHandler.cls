/**
* @Author             : Sukumar Salla
* @Description        : Contact Point Address trigger handler
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author      		    Details
* ---------------------------------------------------
* 06/09/2021     Sukumar Salla        PBI 304103: Address Management - UI Changes
**/

public class ContactPointAddressTriggerHandler extends TriggerHandler{
    public override void beforeInsert() {
        ContactPointAddressTriggerHelper.validateActiveToDate((List<ContactPointAddress>)Trigger.New);
    }
    public override void beforeUpdate() {
        ContactPointAddressTriggerHelper.validateActiveToDate((List<ContactPointAddress>)Trigger.New);
    }
}