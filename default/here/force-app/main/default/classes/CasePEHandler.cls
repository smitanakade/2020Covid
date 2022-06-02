/*
    Author: Pratyush Chalasani

    @Modification Log
    --------------------------------------------------- 
    Date           Author      		    Details
    ---------------------------------------------------
    26/08/2021     Pratyush Chalasani    Feature 295615: Asynchronous trigger processing
    14/10/2021     Aref Samad            Feature 326876 - Case Changed to Confirmed
    03/11/2021     Aref Samad            Feature 309115 : Email Notification To LPHUs/Queue when a Confirmed Case is Auto-allocated from Informatics Queue      
     
*/
public class CasePEHandler {
    public static void asyncInsert(List<Case> cases) {

    }

    public static void asyncUpdate(List<Case> cases, Map<Id, SObject> oldCases) {
        
        //Feature 326876 - Case Changed to Confirmed
        CaseTriggerHelper.processConfirmedRecordsAsync(cases, oldCases);  
        
        //PBI 309115 Email Notification To LPHUs/Queue when a Confirmed Case is Auto-allocated from Informatics Queue
        CaseTriggerHelper.sendQueueAssignmentNotificationToMembersAsync(cases, oldCases);
       
    }
}
