/* 
    Author: Arun

    @Modification Log 
    ---------------------------------------------------
    Date           Author      		    Details
    ---------------------------------------------------
    2/11/2021     Arun    Feature 333509: Asynchronous trigger processing for Account
     
    
*/
trigger AccountPETrigger on Account_Async_Operation__e (after insert) {
    // old value maps
    Set<Id> insertIds = new Set<Id>();
    Map<Id, SObject> updateMap = new Map<Id, SObject>();

    // Build map of record IDs to old values
    for (Account_Async_Operation__e op: Trigger.NEW) {
        SObject oldRecord = String.isNotBlank(op.Old_Values__c) ? (Account)JSON.deserialize(op.Old_Values__c, Account.class) : null;
        
        if (op.Event__c == 'insert') insertIds.add(op.Record_ID__c);
        if (op.Event__c == 'update') updateMap.put(op.Record_ID__c, oldRecord);
    }

    PETriggerHandlerUtil.process('Account', insertIds, updateMap);
}