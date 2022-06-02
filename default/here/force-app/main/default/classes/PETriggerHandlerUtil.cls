/*
    Author: Pratyush Chalasani

    @Modification Log 
    ---------------------------------------------------
    Date           Author      		    Details
    ---------------------------------------------------
    26/08/2021     Pratyush Chalasani    Feature 295615: Asynchronous trigger processing
    03/09/2021     Pratyush Chalasani    Bugfix 318716: Fix Update trigger recursion, and missing ID value 
*/
public class PETriggerHandlerUtil {
    // Used for unit tests to determine if the correct events were processed
    @testVisible
    private static List<SObject> publishedEvents;
    @testVisible
    private static Boolean asyncInserted = false;
    @testVisible
    private static Boolean asyncUpdated = false;

    public static List<String> getAllFields(String objectName) {
        List<String> fields = new List<String>();

        // Get all fields for object
        Map<String, SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

        for (SObjectField field: fieldMap.values()) {
            Schema.DescribeFieldResult f = field.getDescribe();
            if (f.getType().name() != 'TEXTAREA') fields.add(f.getName());
        }

        // return all non-text area fields
        return fields;
    }

    // Called from TriggerHandler
    // Event should be "insert" or "update"
    public static void publishAsyncEvents(String objectName, String event, List<SObject> records, Map<Id, SObject> oldMap) {
        try {
            // Get all fields for object
            Map<String, SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

            // Find all Long Text fields
            Set<String> textAreaFields = new Set<String>();
            for (SObjectField field: fieldMap.values()) {
                Schema.DescribeFieldResult f = field.getDescribe();
                if (f.getType().name() == 'TEXTAREA') textAreaFields.add(f.getName());
            }

            List<SObject> updates = new List<SObject>();

            for (SObject record: records) {
                String oldValues = '{}';

                if (oldMap != null) {
                    // Records in Trigger.OldMap are read only
                    // Clone record in order to strip out Long Text field values
                    // clone options: preserve ID, shallow clone, preserve readonly timestamp, preserve autonumbers
                    SObject cloned = oldMap.get(record.Id).clone(true, false, true, true);
                            
                    // Set all Long Text fields to null
                    for (String fieldName: textAreaFields) cloned.put(fieldName, null);

                    oldValues = JSON.serialize(cloned, true);
                }
                
                // Serialise old field values as JSON string
                switch on objectName {
                    when 'Case' {
                        updates.add(new Case_Async_Operation__e(Event__c = event, Record_ID__c = record.Id, Old_Values__c = oldValues));
                    }

                     //Process Accounts
                    when 'Account' {
                        updates.add(new Account_Async_Operation__e(Event__c = event, Record_ID__c = record.Id, Old_Values__c = oldValues));
                    }
                  
                    /*when 'WorkOrder' {
                    }*/
                }
            }
            
            System.debug('Publishing: ' + updates);

            EventBus.publish(updates);

            if (Test.isRunningTest()) publishedEvents = updates;
        } catch (Exception exp) {
            //Placeholder for error logging. For now just re-throw the exception
            ApplicationLogUtility.createlog('PETriggerHandlerUtil','publishAsyncEvents',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    public static void process(String objectName, Set<Id> insertIDs, Map<Id, SObject> oldValueMap) {
        try {
            if (Test.isRunningTest()) {
                asyncInserted = false;
                asyncUpdated = false;
            }

            String fieldList = String.join(getAllFields(objectName),',');

            switch on objectName {
                when 'Case' {
                    if (!insertIDs.isEmpty()) {
                        if (Test.isRunningTest()) asyncInserted = true;

                        CasePEHandler.asyncInsert((List<Case>)Database.query('SELECT ' + fieldList + ' FROM Case WHERE Id IN :insertIDs'));
                    }
                
                    if (!oldValueMap.keySet().isEmpty()) {
                        Set<Id> updateIDs = oldValueMap.keySet();

                        if (Test.isRunningTest()) asyncUpdated = true;

                        CasePEHandler.asyncUpdate((List<Case>)Database.query('SELECT ' + fieldList + ' FROM Case WHERE Id IN :updateIDs'), oldValueMap);
                    }
                }
              
                 //Process account records 
                 when 'Account' {
                    if (!insertIDs.isEmpty()) {
                        if (Test.isRunningTest()) asyncInserted = true;

                        AccountPEHandler.asyncInsert((List<Account>)Database.query('SELECT ' + fieldList + ' FROM Account  WHERE Id IN :insertIDs'));
                    }
                
                    if (!oldValueMap.keySet().isEmpty()) {
                        Set<Id> updateIDs = oldValueMap.keySet();

                        if (Test.isRunningTest()) asyncUpdated = true;

                        AccountPEHandler.asyncUpdate((List<Account>)Database.query('SELECT ' + fieldList + ' FROM Account WHERE Id IN :updateIDs'), oldValueMap);
                    }
                }
                
                /*when 'WorkOrder' {
                    if (!insertIDs.isEmpty()) {
                        if (Test.isRunningTest()) asyncInserted = true;

                    }
                
                    if (!updateIDs.isEmpty()) {
                        if (Test.isRunningTest()) asyncUpdated = true;

                    }
                }*/
            }
        } catch (Exception exp) {
            //Placeholder for error logging. For now just re-throw the exception           
            ApplicationLogUtility.createlog('PETriggerHandlerUtil','process',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;          
        }
    }
}