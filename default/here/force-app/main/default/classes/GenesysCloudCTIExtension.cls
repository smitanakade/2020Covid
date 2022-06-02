/**
 * @Author             : Darko Jovanovic
 * @Description        : Genesys Cloud CTI Extension. This class contains functionality to extend telephony integration between Genesys and Salesforce
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 13/01/2021     Darko Jovanovic       Feature 245116: Genesys Cloud implementation - Initial version
**/
global class GenesysCloudCTIExtension implements purecloud.CTIExtension.SaveLog {

    public static FINAL Id CONST_CALL_REC_TYPE_ID   = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Log_A_Call').getRecordTypeId();
    public static FINAL String CONST_TASK_TYPE      = 'Call - Telephony Integration';

    // We're extending onSaveLog method since it's not possible to set record type via Genesys Cloud configuration 
    public String onSaveLog(String data) {
        System.debug('data: ' + data);
        Map<String, Object> saveLogData = (Map<String, Object>) JSON.deserializeUntyped(data);
        Map<String, Object> interaction = ( Map<String, Object>) saveLogData.get('interaction');
        Map<String, Object> callLog = ( Map<String, Object>) saveLogData.get('callLog');
        Boolean isDisconnected = (Boolean) interaction.get('isDisconnected');
        String callLogId = '';
        if (isDisconnected) {
            Task t = (Task) JSON.deserialize(JSON.serialize(callLog), Task.class);
            t.RecordTypeId  = CONST_CALL_REC_TYPE_ID;
            t.Type          = CONST_TASK_TYPE;
            System.debug('t.whatId: ' + t.whatId);
            if (t.whatId != null) {
                // If the Task is related to a case, default the Person Account contact record associated with the case if whoId is empty
                if (t.whatId.getSobjectType() == Schema.Case.SObjectType) {
                    System.debug('t.whoId: ' + t.whoId);
                    if (t.whoId == null) {
                        Id contactId = 
                            [SELECT Account.PersonContactId
                            FROM Case
                            WHERE Id = :t.whatId].Account.PersonContactId;
                        if (!String.isBlank(contactId)) {
                            t.whoId = contactId;
                        }
                    }
                }
            } else {
                // If the task is associated with a Person Account Contact, default in the Case associated with the Person Account - but only if there's one Case in the event period
                if (t.whoId != null) {
                    List<Case> caseList = 
                        [SELECT Id
                        FROM Case
                        WHERE Event_period_passed__c = false
                        AND AccountId IN 
                           (SELECT AccountId 
                           FROM Contact
                           WHERE Id = :t.whoId)];
                    if (caseList.size() == 1) {
                        t.whatId = caseList[0].Id;
                    }
                }
            }
            System.debug('t.whatId final: ' + t.whatId);
            System.debug('t.whoId final: ' + t.whoId);
            upsert t;
            callLogId = t.Id;
        }
        return callLogId; 
    }
}