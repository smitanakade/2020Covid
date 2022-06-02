/*
    Author: Pratyush Chalasani

    @Modification Log
    ---------------------------------------------------
    Date           Author      		    Details
    ---------------------------------------------------
    12/08/2021     Pratyush Chalasani    Feature 295615: Asynchronous trigger processing
    15/10/2021     Aref Samad            PBI 326876 - Case Changed to Confirmed
                                         Fix parameter for PETriggerHandlerUtil.process call   
*/
trigger CasePETrigger on Case_Async_Operation__e (after insert) {
    // old value maps
    Set<Id> insertIds = new Set<Id>();
    Map<Id, SObject> updateMap = new Map<Id, SObject>();

    // Build map of record IDs to old values
    for (Case_Async_Operation__e op: Trigger.NEW) {
        SObject oldRecord = String.isNotBlank(op.Old_Values__c) ? (Case)JSON.deserialize(op.Old_Values__c, Case.class) : null;
        
        if (op.Event__c == 'insert') insertIds.add(op.Record_ID__c);
        if (op.Event__c == 'update') updateMap.put(op.Record_ID__c, oldRecord);
    }

    PETriggerHandlerUtil.process('Case', insertIds, updateMap);
}