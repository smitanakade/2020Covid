/**
 * @Author             : Sten Ebenau (Plauti, Duplicate Check Vendor)
 * @Description        : Generic plugin for Duplicate Check
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 04/02/2021     Sten Ebenau       Hotfix 258164: Initial version - Duplicate Check search performance improvement
 * 05/02/2021     Darko Jovanovic   Hotfix 258342: Incorporate custom merge rules by overriding Merge Set Field master: https://support.duplicatecheck.com/development-guide/apex-plugin-generic#mergeSetFieldPlugin
 * 17/02/2021     Gabriel Ludik		Hotfix 261538: Reason for Exclusion depends on Requires Special Handling & Opt out of phone calls. Business decided to always take non-blank value - removed code, using DC merge rules
 * 19/02/2021     Gabriel Ludik		Hotfix 261969: Change order for Case found by
 * 24/02/2021     Gabriel Ludik     Hotfix 262493: Added debug statements on request from Duplicate Check team
 * 25/03/2021    Pratyush Chalasani Hotfix 266142,266294: Add rules for Contact hospital prior symptoms fields
 * 26/03/2021    Pratyush Chalasani Feature 266032,266050,266046,266296: Add rules for Person Sex, Language Spken at Home, Country of Birth, Record Owner fields
 * 07/04/2021    Pratyush Chalasani Feature 266306,266059,266139: Added rules for Status & SubStatus, Initial Interview Completed Time & Checkbox fields
 * 08/04/2021    Pratyush Chalasani Hotfix 275639: Fixed precedence for Integration User
 * 12/04/2021    Pratyush Chalasani Hotfix 275639-276133: Fixes for Merge defects
 * 15/04/2021    Pratyush Chalasani Hotfix 276135-277235: Fixes for Merge defects
 * 19/04/2021    Pratyush Chalasani Hotfix 278247,278151: Fixes for Merge defects in UAT
 * 21/04/2021    Pratyush Chalasani Hotfix 279005,279006: Fixes for Merge defects in UAT
 * 22/04/2021    Pratyush Chalasani Hotfix: 279586: Fix for substatus selection when status and record types are different
 * 28/09/2021    Aref Samad         Feature:319580: Merge records with 'Ex-HQ Follow up' status so that data is not lost during the merging process
 * 05/10/2021    Pratyush Chalasani Feature 321606: Marketing Cloud - Merge Rules for Marketing Cloud Day 0 flag
 * 29/09/2021    Sukumar Salla      PBI 313212: Add rules for 'Send Initial email notification' and 'Time and date of initial email sent'
 * 05/10/2021    Lija Jawahar       Feature:319578: Released clearance information 
 * 25/11/2021    Aref S             PBI 318055 AC01:Update status/sub-status when 'contact' merged to PCC/SCC/CA 
**/
global with sharing class dcPluginGeneral implements dupcheck.dc3PluginInterface {

    private static Set<String> implementedEvents = new Set<String>{'CACHE_PUT', 'CACHE_GET', 'MERGE_SET_FIELD'};

    // ------------------------------------------------------------
    // INTERFACE METHODS
    // ------------------------------------------------------------

    global Boolean isAvailable(dupcheck.dc3Plugin.PluginEventType eventType) {
        return dcPluginGeneral.implementedEvents.contains(eventType.name());
    }

    global Object execute(dupcheck.dc3Plugin.PluginEventType eventType, Object eventData) {
        switch on eventType {
            when CACHE_PUT {
                cachePut((Map<String, Object>) eventData);
                return null;
            }
            when CACHE_GET {
                return cacheGet((Map<String, Object>) eventData);
            }
            when MERGE_SET_FIELD {
                return this.mergeSetField((dupcheck.dc3PluginModel.MergeSetFieldInput) eventData);
            }
            when else {
                return null;
            }
        }
    }

    public void cachePut(Map<String, Object> input) {
        String cacheName = 'local.dcMetaData.' + (String) input.get('cacheName');
        Cache.Session.put(cacheName, input.get('cacheData'));
    }

    public Object cacheGet(Map<String, Object> input) {
        String cacheName = 'local.dcMetaData.' + (String) input.get('cacheName');
        return Cache.Session.get(cacheName);
    }
    
    public dupcheck.dc3PluginModel.MergeSetFieldOutput mergeSetField(dupcheck.dc3PluginModel.MergeSetFieldInput input) {
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);
        // ---------------
        // GET MASTER RECORD AND MAP EACH RECORD BY ID
        // ---------------
        Sobject masterRecord;
        Map<Id, SObject> recordByIdMap = new Map<Id, SObject>();
        // Get the Master record and the Last Created record
        for (Sobject objectData : input.objectDataList) {
            // Get field values from the Master Case record
            if (objectData.Id == input.masterRecordId) {
                masterRecord = objectData;
            }
            // Add to record map
            recordByIdMap.put(objectData.Id, objectData);
        }
        System.debug('dcPluginGeneral masterRecord: ' + masterRecord);
        Id masterRecordId       = masterRecord.Id;

        // Mpa of User names to IDs for use with secondary precedence checks
        Map<String, Id> userMap = new Map<String, Id>();
        for (User u: [SELECT Id, Name, Profile.Name FROM User WHERE IsActive = true]) {
            // Skip if it's the wrong type of Integration User
            if (u.Name == 'Integration User' && u.Profile.Name != 'Integration User') continue;

            userMap.put(u.Name, u.Id);
        }

        Map<String, Id> recordTypeMap = new Map<String, Id>();

        Map<String, Schema.RecordTypeInfo> recordTypeInfo = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        for (String recTypeName: recordTypeInfo.keySet()) {
            Schema.RecordTypeInfo info = recordTypeInfo.get(recTypeName);

            recordTypeMap.put(recTypeName, info.getRecordTypeId());
        }


        Id caseAssessmentRecordTypeID = recordTypeMap.get('COVID_19_Case_Assessment');

        // ---------------
        // PERSON ACCOUNT MERGE RULES
        // ---------------
        System.debug('dcPluginGeneral input.objectPrefix: ' + input.objectPrefix);
        if (input.objectPrefix == '001P') {
            // Aboriginal or Torres Strait Islander - merge based on precedence
            (new ABTSIPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Aboriginal_or_Torres_Strait_Islander__c', output);
            // Interpreter required
            (new InterpreterReqPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Interpreter_required__c', output);
            // // Requires special handling
            (new ReqSpecialHandlingPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Requires_Special_Handling__c', output);                                       
            // Sex
            (new SexComparator(userMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Sex__c', output);
            // Specify if other sex (same logic as for Sex__c field)
            (new SexComparator(userMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Specify_if_other_sex__c', output);
            // Language Spoken at Home
            (new LanguageSpokenAtHomeComparator(userMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Language_spoken_at_home__c', output);
            // Country of Birth
            (new CountryOfBirthComparator(userMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Country_of_birth__c', output);
        }
        // ---------------
        // CASE MERGE RULES
        // ---------------
        if (input.objectPrefix == Schema.SObjectType.Case.getKeyPrefix()) {
            // Record type - get top precedence and set if different record type
            String recordTypeFieldAPIName = 'RecordTypeId';
            dcPluginPrecedenceAbstract.PrecedenceBaseResult result = (new CaseRecordTypePrecedence()).getHighestPrecedence(input.objectDataList, recordByIdMap, recordTypeFieldAPIName, output.fieldSourceMap.get(recordTypeFieldAPIName));
            Id newRecordTypeId = result.topPrecedenceFieldValue;
            Id masterRecordTypeId = (Id) masterRecord.get(recordTypeFieldAPIName);            
            if ((newRecordTypeId != null) && (masterRecordTypeId != newRecordTypeId)) {
                // Set the new record type
                // For some reason, we have to use custom value for record type. As such, using customValueMap to set the record type id
                if (!Test.isRunningTest()) {
                    // Also, for some reason the test class doesn't like this statement but it works fine otherwise
                    output.fieldSourceMap.put(recordTypeFieldAPIName, 'custom');
                }                
                output.customValueMap.put(recordTypeFieldAPIName, newRecordTypeId);
            } 
            // Case Found By - merge based on precedence
            (new CaseFoundByPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Case_Found_By__c', output);
            // EPI Classification - merge based on precedence
            (new EpiClassificationPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Epi_Classification__c', output);
            // Event Classification - merge based on precedence
            (new EventClassificationPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Case_Classification__c', output);                                      
            // Event Type - merge based on precedence
            (new EventTypePrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Event_Type__c', output);                 
            // Priority - merge based on precedence
            (new PriorityPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Priority', output);
            // Travel Overseas 14 days prior to symptoms - merge based on precedence
            (new TravelOs14DaysPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Case_Travel_Overseas_14d_Prior_Symtoms__c', output);
            // Travel to Wuhan - merge based on precedence
            (new WuhanTravelPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Travel_to_Wuhan__c', output);
            // Contact hospital 48 hours prior symptoms - merge based on precedence
            (new ContactHospitalPriorSymptomsPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Contact_hospital_48_hours_prior_symptoms__c', output);
            // Contact hospital 14 days prior symptoms - merge based on precedence
            (new ContactHospitalPriorSymptomsPrecedence()).applyPrecedenceRule(input.objectDataList, recordByIdMap, 'Contact_hospital_14_days_prior_symptoms__c', output);
            // Record Owner
            (new RecordOwnerComparator(userMap, recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'OwnerId', output);
            // Status
            (new StatusComparator(recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Status', output);
            // Sub-Status
            (new SubStatusComparator(recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'SubStatus__c', output);
            // Initial Interview Completed Time
            (new InitialInterviewCompletedTimeComparator(recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Initial_Interview_Completed_Time__c', output);
            // Initial Interview Completed Checkbox
            (new InitialInterviewCompletedCheckboxComparator(recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Initial_Interview_completed__c', output);
            // #321606: Marketing Cloud PCC Day 0 picklist
            (new MCDay0PicklistComparator(recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Marketing_Cloud_PCC_Day_0__c', output);
             // Time and Date of sent initial email
            (new TimeAndDateOfSentInitialEmailComparator(recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Time_and_Date_of_sent_initial_email__c', output);
            // Send initial notification email
            (new SendInitialNotificationEmailCheckboxComparator(recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Send_initial_notification_email__c', output);
            //#319578 Released - Case_Cleared_from_Isolation__c
            (new ReleaseComparator(recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Case_Cleared_from_Isolation__c', output);
             //#319578 DateReleased - 	Date_Cleared_from_Isolation__c	
            (new DateReleaseComparator(recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Date_Cleared_from_Isolation__c', output);
             //#319578 Has Clearance Letter Been Sent  Has_Clearance_Letter_Been_Sent__c
            (new ClearanceLetterReleaseComparator(recordTypeMap)).applyPrecedenceRule(masterRecord, input.objectDataList, 'Has_Clearance_Letter_Been_Sent__c', output);
        }
       
        System.debug('dcPluginGeneral output: ' + output);
        return output;
         
    }

    // ------------------------------------------------------------
    // PRECEDENCE RULES
    // ------------------------------------------------------------

    // ACCOUNT PRECEDENCE RULES 

    // Precedence for Aboriginal or Torres Strait Islander values
    public class ABTSIPrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'UNKNOWN' {
                    precedence = 2;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 1;
                }
            }
            System.debug('dcPluginGeneral ABTSIPrecedence: ' + precedence);
            return precedence;
        }
    }

    // Precedence for Interpreter Required values
    public class InterpreterReqPrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'Yes' {
                    precedence = 1;
                }
                when 'No' {
                    precedence = 2;
                }
                when 'Unknown' {
                    precedence = 3;
                }
                when 'Not stated' {
                    precedence = 4;
                }
                when 'Not applicable' {
                    precedence = 5;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 6;
                }
            }
            System.debug('dcPluginGeneral InterpreterReqPrecedence: ' + precedence);
            return precedence;
        }
    }
    
    // Precedence for Requires Special Handling values
    public class ReqSpecialHandlingPrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'Yes' {
                    precedence = 1;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 2;
                }
            }
            System.debug('dcPluginGeneral ReqSpecialHandlingPrecedence: ' + precedence);
            return precedence;
        }
    }

    // Comparator for Sex Field
    public class SexComparator extends dcPluginComparatorAbstract {
        String IntegrationUser, ADFService;

        public SexComparator(Map<String, Id> userMap) {
            this.IntegrationUser = (String)userMap.get('Integration User');
            this.ADFService      = (String)userMap.get('ADF Service');
        }

        public override Integer compare(SObject master, SObject current) {
            Integer precedence = getHighestPrecedence('Sex__c', master, current);

            if (precedence == EQUAL) {
                precedence = getHighestPrecedence('CreatedById', master, current);
            }

            return precedence;
        }

        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;

            if (fieldName == 'Sex__c') {
                switch on fieldValue {
                    when 'Not stated' {
                        precedence = 1;
                    }
                    when 'UNKNOWN' {
                        precedence = 1;
                    }
                    when null {
                        precedence = 999;
                    }
                    when else {
                        precedence = 0;
                    }
                }
            } else if (fieldName == 'CreatedById') {
                if (fieldValue == IntegrationUser) {
                    precedence = 1;
                } else if (fieldValue == ADFService) {
                    precedence = 2;
                } else {
                    precedence = 0;
                }
            }

            return precedence;
        }
    }

    // Comparator for LanguageSpokenAtHome Field
    public class LanguageSpokenAtHomeComparator extends dcPluginComparatorAbstract {
        String IntegrationUser, ADFService;

        public LanguageSpokenAtHomeComparator(Map<String, Id> userMap) {
            this.IntegrationUser = (String)userMap.get('Integration User');
            this.ADFService      = (String)userMap.get('ADF Service');
        }

        public override Integer compare(SObject master, SObject current) {
            Integer precedence = getHighestPrecedence('Language_spoken_at_home__c', master, current);

            if (precedence == EQUAL) {
                precedence = getHighestPrecedence('CreatedById', master, current);
            }

            return precedence;
        }

        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;

            if (fieldName == 'Language_spoken_at_home__c') {
                switch on fieldValue {
                    when 'Other' {
                        precedence = 1;
                    }
                    when 'Missing/Unknown' {
                        precedence = 2;
                    }
                    when null {
                        precedence = 999;
                    }
                    when else {
                        precedence = 0;
                    }
                }
            } else if (fieldName == 'CreatedById') {
                if (fieldValue == IntegrationUser) {
                    precedence = 1;
                } else if (fieldValue == ADFService) {
                    precedence = 2;
                } else {
                    precedence = 0;
                }
            }

            return precedence;
        }
    }

    // Comparator for CountryOfBirth Field
    public class CountryOfBirthComparator extends dcPluginComparatorAbstract {
        String IntegrationUser, ADFService;

        public CountryOfBirthComparator(Map<String, Id> userMap) {
            this.IntegrationUser = (String)userMap.get('Integration User');
            this.ADFService      = (String)userMap.get('ADF Service');
        }

        public override Integer compare(SObject master, SObject current) {
            Integer precedence = getHighestPrecedence('Country_of_birth__c', master, current);

            if (precedence == EQUAL) {
                precedence = getHighestPrecedence('CreatedById', master, current);
            }

            return precedence;
        }

        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;

            if (fieldName == 'Country_of_birth__c') {
                switch on fieldValue {
                    when 'UNK' {
                        precedence = 1;
                    }
                    when null {
                        precedence = 999;
                    }
                    when else {
                        precedence = 0;
                    }
                }
            } else if (fieldName == 'CreatedById') {
                if (fieldValue == IntegrationUser) {
                    precedence = 1;
                } else if (fieldValue == ADFService) {
                    precedence = 2;
                } else {
                    precedence = 0;
                }
            }

            return precedence;
        }
    }

    // CASE PRECEDENCE RULES 

    // Precedence for Case Record Type values
    public class CaseRecordTypePrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            String recordTypeDeveloperName;
            if (!String.isBlank(val)) {
                recordTypeDeveloperName = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosById().get(val).getDeveloperName();
            }           
            switch on recordTypeDeveloperName {
                when 'COVID_19_Case_Assessment' {
                    precedence = 1;
                }	
                when 'Close_Contact' {
                    precedence = 2;
                }
                when 'Secondary_Close_Contact' {
                    precedence = 3;
                }
                when 'Casual_Contact' {
                    precedence = 4;
                }
                when 'Acquisition_Contact' {
                    precedence = 5;
                }
                when 'COVID_19_Case_Screening' {
                    precedence = 6;
                }
                when 'Unclassified_Contact' {
                    precedence = 7;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 8;
                }
            }
            System.debug('dcPluginGeneral CaseRecordTypePrecedence: ' + precedence);
            return precedence;
        }
    }

    // Precedence for Case Found By values
    public class CaseFoundByPrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'Contact Tracing' {
                    precedence = 1;
                }
                when 'Clinical Presentation' {
                    precedence = 2;
                }
                when 'Screening' {
                    precedence = 3;
                }
                when 'Non-Victorian Diagnosis' {
                    precedence = 4;
                }
                when 'Outbreak Investigation' {
                    precedence = 5;
                }
                when 'Serology' {
                    precedence = 6;
                }
                when 'Clinical and epidemiology' {
                    precedence = 7;
                }
                when 'Routine Follow-Up' {
                    precedence = 8;
                }
                when 'Undertaking' {
                    precedence = 9;
                }
                when 'Unknown or blank' {
                    precedence = 10;
                }
                when 'External Contact Tracing' {
                    precedence = 11;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 12;
                }
            }
            System.debug('dcPluginGeneral CaseFoundByPrecedence: ' + precedence);
            return precedence;
        }
    }

    // Precedence for Epi Classification values
    public class EpiClassificationPrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'Epidemiologically linked to a laboratory confirmed case' {
                    precedence = 1;
                }
                when 'Secondary Contact - External follow up' {
                    precedence = 2;
                }
                when 'Secondary Contact - Internal follow up' {
                    precedence = 3;
                }
                when 'Part of cluster' {
                    precedence = 4;
                }
                when 'Outbreak' {
                    precedence = 5;
                }
                when 'Sporadic case' {
                    precedence = 6;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 7;
                }
            }
            System.debug('dcPluginGeneral EpiClassificationPrecedence: ' + precedence);
            return precedence;
        }
    }

    // Precedence for Event Classification values
    public class EventClassificationPrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'Confirmed' {
                    precedence = 1;
                }
                when 'Suspected' {
                    precedence = 2;
                }
                when 'At Risk' {
                    precedence = 3;
                }
                when 'Not notifiable' {
                    precedence = 4;
                }
                when 'Probable' {
                    precedence = 5;
                }
                when 'Rejected' {
                    precedence = 6;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 7;
                }
            }
            System.debug('dcPluginGeneral EventClassificationPrecedence: ' + precedence);
            return precedence;
        }
    }

    // Precedence for Event Type values
    public class EventTypePrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'Case' {
                    precedence = 1;
                }
                when 'Contact/exposed person' {
                    precedence = 2;
                }
                when 'Control' {
                    precedence = 3;
                }
                when 'Study Participant' {
                    precedence = 4;
                }
                when 'Sample' {
                    precedence = 5;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 6;
                }
            }
            System.debug('dcPluginGeneral EventTypePrecedence: ' + precedence);
            return precedence;
        }
    }

    // Precedence for Priority values
    public class PriorityPrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'High' {
                    precedence = 1;
                }
                when 'Medium' {
                    precedence = 2;
                }
                when 'Low' {
                    precedence = 3;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 4;
                }
            }
            System.debug('dcPluginGeneral PriorityPrecedence: ' + precedence);
            return precedence;
        }
    }

    // Travel Overseas 14 days prior to symptoms values
    public class TravelOs14DaysPrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'Yes' {
                    precedence = 1;
                }
                when 'No' {
                    precedence = 2;
                }
                when 'Unknown' {
                    precedence = 3;
                }
                when 'Not stated' {
                    precedence = 4;
                }
                when 'Not applicable' {
                    precedence = 5;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 6;
                }
            }
            System.debug('dcPluginGeneral TravelOs14DaysPrecedence: ' + precedence);
            return precedence;
        }
    }

    // Travel to Wuhan values
    public class WuhanTravelPrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'Yes' {
                    precedence = 1;
                }
                when 'No' {
                    precedence = 2;
                }
                when 'Unknown' {
                    precedence = 3;
                }
                when 'Not stated' {
                    precedence = 4;
                }
                when 'Not applicable' {
                    precedence = 5;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 6;
                }
            }
            System.debug('dcPluginGeneral WuhanTravelPrecedence: ' + precedence);
            return precedence;
        }
    }

    // Precedence for Contact hospital xx prior symptoms
    public class ContactHospitalPriorSymptomsPrecedence extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'Yes' {
                    precedence = 1;
                }
                when 'No' {
                    precedence = 2;
                }
                when 'Not stated' {
                    precedence = 3;
                }
                when 'Not applicable' {
                    precedence = 4;
                }
                when 'Unknown' {
                    precedence = 5;
                }
                when else {
                    precedence = 999;
                }
            }
            return precedence;
        }
    }

    // Comparator for Record Owner Field
    public class RecordOwnerComparator extends dcPluginComparatorAbstract {
        String IntegrationUser, ADFService;

        public RecordOwnerComparator(Map<String, Id> userMap, Map<String, Id> recordTypeMap) {
            this.IntegrationUser = (String)userMap.get('Integration User');
            this.ADFService      = (String)userMap.get('ADF Service');

            storeCaseRecordTypes(recordTypeMap);
        }

        public override Integer compare(SObject master, SObject current) {
            Integer precedence = getHighestPrecedence('RecordTypeId', master, current);

            System.debug('[MERGE] RT: ' + precedence);

            if (precedence == EQUAL) {
                precedence = getHighestPrecedence('OwnerId', master, current);

                System.debug('[MERGE] Owner: ' + precedence);
            }

            return precedence;
        }

        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;

            if (fieldName == 'RecordTypeId') {
                precedence = caseRecordTypePrecedence(fieldValue);
            } else if (fieldName == 'OwnerId') {
                if (fieldValue == IntegrationUser) {
                    precedence = 1;
                } else if (fieldValue == ADFService) {
                    precedence = 2;
                } else {
                    precedence = 0;
                }
            }

            return precedence;
        }
    }

    // Comparator for Status Field
    public class StatusComparator extends dcPluginComparatorAbstract {
        public StatusComparator(Map<String, Id> recordTypeMap) {
            storeCaseRecordTypes(recordTypeMap);
        }

        public override Integer compare(SObject masterRecord, SObject currentRecord) {
            Integer precedence = EQUAL; // default if no rules match

            Id masterRecordTypeID  = (Id)masterRecord.get('RecordTypeId');
            Id currentRecordTypeID = (Id)currentRecord.get('RecordTypeId');

            if (masterRecordTypeID == CA && currentRecordTypeID == CA) {
                DateTime masterEvent  = (DateTime)masterRecord.get('Event_Date__c');
                DateTime currentEvent = (DateTime)currentRecord.get('Event_Date__c');

                precedence = (masterEvent < currentEvent) ? MASTER : (currentEvent < masterEvent) ? CURRENT : EQUAL;
            } else if (masterRecordTypeID == currentRecordTypeID) {
                precedence =this.getPrecedenceBasedOnRecentDay0(masterRecord,currentRecord);
            } else if (masterRecordTypeID != currentRecordTypeID) {
                precedence = getHighestPrecedence('RecordTypeId', masterRecord, currentRecord);
            }

            // Additional logic to ensure Ex-HQ Follow up status is merged
            // Moved the Recent Day0 precedence logic in private method getPrecedenceBasedOnRecentDay0
            // In case record type is not equal between master and current, the record type precedence need to run 
            // then this logic in addition
            if (masterRecord.get('Status')=='Ex-HQ Follow-up' || currentRecord.get('Status')=='Ex-HQ Follow-up')
            {
                precedence =this.getPrecedenceBasedOnRecentDay0(masterRecord,currentRecord);

                //Ensure the HQ Resident is set to true if status is EX HQ Follow up for validation rule
                if ((precedence==MASTER && masterRecord.get('Status')=='Ex-HQ Follow-up') ||
                    (precedence==CURRENT && currentRecord.get('Status')=='Ex-HQ Follow-up'))
                    {
                        customValueMap.put('HQ_Resident__c', true);
                    }                    
            }


            // //PBI 318055 AC01:Update status/sub-status when 'contact' merged to PCC/SCC/CA 
            if ((isRecordTypePCCorSCC(masterRecord.get('RecordTypeId').toString()) && isRecordTypeOtherThenPCCorSCC(currentRecord.get('RecordTypeId').toString()) &&
                currentRecord.get('Status')=='Active') ||
                (isRecordTypePCCorSCC(currentRecord.get('RecordTypeId').toString()) && isRecordTypeOtherThenPCCorSCC(masterRecord.get('RecordTypeId').toString()) &&
                masterRecord.get('Status')=='Active'))
            {                
                customValueMap.put('Status', 'Identify');                                       
            }

            return precedence;
        }

        private Integer getPrecedenceBasedOnRecentDay0(SObject masterRecord, SObject currentRecord)
        {
            Integer precedence=EQUAL;
            Date masterDay0  = (Date)masterRecord.get('Day_0_Calculated__c');
            Date currentDay0 = (Date)currentRecord.get('Day_0_Calculated__c');

            precedence = (masterDay0 > currentDay0) ? MASTER : (currentDay0 > masterDay0) ? CURRENT : EQUAL;

            if (precedence == EQUAL) {
                precedence = getHighestPrecedence('Status', masterRecord, currentRecord);
            }
            return precedence;
        }

        /**
        * @description Get precedent for Status/Record Type
        * @author Pratyush Chalasani 26/03/2021 
        * @param fieldName --Name of the field to compare and apply precedence
        * @param fieldValue  -- Value of the field to compare and apply precedence
        * @return Integer -- return the precedence based on field value
        * @revision
        * 28/09/2021    Aref Samad  Feature: 319580 Add Ex-HQ Follow-up as higher precedence then Closed
        **/
        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;

            if (fieldName == 'RecordTypeId') {
                precedence = caseRecordTypePrecedence(fieldValue);
            } else if (fieldName == 'Status') {
                switch on fieldValue {
                    when 'Quarantine' {
                        precedence = 0;
                    }
                    when 'Identify' {
                        precedence = 1;
                    }
                    when 'Ex-HQ Follow-up' {
                        precedence = 2;
                    }
                    when 'Closed' {
                        precedence = 3;
                    }
                    when else {
                        precedence = 999;
                    }                
                }
            }

            return precedence;
        }
       
    }

    // Comparator for Sub-Status Field
    public class SubStatusComparator extends dcPluginComparatorAbstract {
        public SubStatusComparator(Map<String, Id> recordTypeMap) {
            storeCaseRecordTypes(recordTypeMap);
        }

        public override Integer compare(SObject masterRecord, SObject currentRecord) {
            Integer precedence = EQUAL; // default if no rules match

            String masterStatus = (String)masterRecord.get('Status');
            String currentStatus = (String)currentRecord.get('Status');

            Id masterRecordTypeID  = (Id)masterRecord.get('RecordTypeId');
            Id currentRecordTypeID = (Id)currentRecord.get('RecordTypeId');

            if (masterStatus != currentStatus) {
                // If Status values are different, use the same rules as for Status
                if (masterRecordTypeID == CA && currentRecordTypeID == CA) {
                    DateTime masterEvent  = (DateTime)masterRecord.get('Event_Date__c');
                    DateTime currentEvent = (DateTime)currentRecord.get('Event_Date__c');

                    precedence = (masterEvent < currentEvent) ? MASTER : (currentEvent < masterEvent) ? CURRENT : EQUAL;
                } else if (masterRecordTypeID == currentRecordTypeID) {
                    Date masterDay0  = (Date)masterRecord.get('Day_0_Calculated__c');
                    Date currentDay0 = (Date)currentRecord.get('Day_0_Calculated__c');

                    precedence = (masterDay0 > currentDay0) ? MASTER : (currentDay0 > masterDay0) ? CURRENT : EQUAL;

                    if (precedence == EQUAL) {
                        // If Day-0 is the same, then take precedence from Status
                    	precedence = getHighestPrecedence('Status', masterRecord, currentRecord);
                    }
                } else if (masterRecordTypeID != currentRecordTypeID) {
                    // If Status and Record Type are different, take precedence from RecordTypeId
                	precedence = getHighestPrecedence('RecordTypeId', masterRecord, currentRecord);
                }
            } else if (masterStatus == currentStatus && masterRecordTypeID != currentRecordTypeID) {
                // If Status is the same but Record Type is different, take precedence from RecordTypeId
                precedence = getHighestPrecedence('RecordTypeId', masterRecord, currentRecord);
            } else {
                // If Status is the same and Record Type is the same, take precedence from SubStatus
                precedence = getHighestPrecedence('SubStatus__c', masterRecord, currentRecord);
            }

             // //PBI 318055 AC01:Update status/sub-status when 'contact' merged to PCC/SCC/CA
             if ((isRecordTypePCCorSCC(masterRecord.get('RecordTypeId').toString()) && isRecordTypeOtherThenPCCorSCC(currentRecord.get('RecordTypeId').toString()) &&
                currentRecord.get('Status')=='Active') ||
                (isRecordTypePCCorSCC(currentRecord.get('RecordTypeId').toString()) && isRecordTypeOtherThenPCCorSCC(masterRecord.get('RecordTypeId').toString()) &&
                masterRecord.get('Status')=='Active'))
            {                
                customValueMap.put('SubStatus__c', 'In Progress');                                       
            }

            return precedence;
        }

        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;

            if (fieldName == 'RecordTypeId') {
                precedence = caseRecordTypePrecedence(fieldValue);
            } else if (fieldName == 'SubStatus__c') {
                switch on fieldValue {
                    when 'Escalated' {
                        precedence = 1;
                    }
                    when 'In Progress' {
                        precedence = 2;
                    }
                    when 'Complete' {
                        precedence = 3;
                    }
                    when 'Unallocated' {
                        precedence = 4;
                    }
                    when 'Confirmed Case' {
                        precedence = 5;
                    }
                    when 'Deceased' {
                        precedence = 6;
                    }
                    when 'Lost to follow up', 'Unsuccessful' {
                        precedence = 7;
                    }
                    when 'Release' {
                        precedence = 8;
                    }
                    when else {
                        precedence = 999;
                    }
                }
            } else if (fieldName == 'Status') {
                switch on fieldValue {
                    when 'Quarantine' {
                        precedence = 0;
                    }
                    when 'Identify' {
                        precedence = 1;
                    }
                    when 'Closed' {
                        precedence = 2;
                    }
                    when else {
                        precedence = 999;
                    }
                }
            }

            return precedence;
        }
    }

    // Comparator for InitialInterviewCompletedTime Field
    public class InitialInterviewCompletedTimeComparator extends dcPluginComparatorAbstract {
        public InitialInterviewCompletedTimeComparator(Map<String, Id> recordTypeMap) {
            storeCaseRecordTypes(recordTypeMap);
        }

        public override Integer compare(SObject masterRecord, SObject currentRecord) {
            Integer precedence = EQUAL; // default if no rules match
            
            DateTime masterModified  = (DateTime)masterRecord.get('CreatedDate');
            DateTime currentModified = (DateTime)currentRecord.get('CreatedDate');            

            Id masterRecordTypeID  = (Id)masterRecord.get('RecordTypeId');
            Id currentRecordTypeID = (Id)currentRecord.get('RecordTypeId');

            if (masterRecordTypeID == currentRecordTypeID) {
                SObject newRecord = (masterModified >= currentModified) ? masterRecord : currentRecord;
                SObject oldRecord = (newRecord.Id == masterRecord.Id) ? currentRecord : masterRecord;
                
                if (masterRecordTypeID == PCC || masterRecordTypeID == SCC) {
                    Date newDay0 = (masterRecordTypeID == PCC) ?
                                        (Date)newRecord.get('Day_0_Exposure_to_the_confirmed_case__c') :
                                        (Date)newRecord.get('Day_0_Exposure_to_primarycc__c');

                    DateTime oldInterviewTime = (DateTime)oldRecord.get('Initial_Interview_Completed_Time__c');
                    
                    if ((newDay0 == null && oldInterviewTime != null) || (newDay0 <= oldInterviewTime)) {
                        precedence = (oldRecord.Id == masterRecord.Id) ? MASTER : CURRENT;
                    }
                } else if (masterRecordTypeID == CA) {
                    precedence = (oldRecord.Id == masterRecord.Id) ? MASTER : CURRENT;
                }
            } else {
                precedence = getHighestPrecedence('RecordTypeId', masterRecord, currentRecord);
            }

            return precedence;
        }
        
        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;

            if (fieldName == 'RecordTypeId') {
                precedence = caseRecordTypePrecedence(fieldValue);
            }
            
            return precedence;
        }
    }

    public class InitialInterviewCompletedCheckboxComparator extends dcPluginComparatorAbstract {
       public InitialInterviewCompletedCheckboxComparator(Map<String, Id> recordTypeMap) {
            storeCaseRecordTypes(recordTypeMap);
        }

        public override Integer compare(SObject masterRecord, SObject currentRecord) {
            Integer precedence = EQUAL; // default if no rules match
            
            DateTime masterModified  = (DateTime)masterRecord.get('CreatedDate');
            DateTime currentModified = (DateTime)currentRecord.get('CreatedDate');            

            Id masterRecordTypeID  = (Id)masterRecord.get('RecordTypeId');
            Id currentRecordTypeID = (Id)currentRecord.get('RecordTypeId');

            Boolean masterTicked  = (Boolean)masterRecord.get('Initial_Interview_completed__c');
            Boolean currentTicked = (Boolean)currentRecord.get('Initial_Interview_completed__c');

            if (masterRecordTypeID == currentRecordTypeID) {
                SObject newRecord = (masterModified >= currentModified) ? masterRecord : currentRecord;
                SObject oldRecord = (newRecord.Id == masterRecord.Id) ? currentRecord : masterRecord;
                
                if (masterRecordTypeID == PCC || masterRecordTypeID == SCC) {
                    Date newDay0 = (masterRecordTypeID == PCC) ?
                                        (Date)newRecord.get('Day_0_Exposure_to_the_confirmed_case__c') :
                                        (Date)newRecord.get('Day_0_Exposure_to_primarycc__c');

                    DateTime oldInterviewTime = (DateTime)oldRecord.get('Initial_Interview_Completed_Time__c');

                    /*
                     * This is a workaround for a problem in the dupcheck package merging.
                     * Setting a custom value for a non-text field throws an error.
                     * Here, we set a text flag that will be picked up by the Case trigger,
                     * which will then update the initial interview time and checkbox fields.
                     */
                    Boolean setInitialInterview = (newDay0 > oldInterviewTime);
                    if(oldInterviewTime!=null){
                        customValueMap.put('Set_Initial_Interview__c', setInitialInterview ? 'F' : 'T');
                    }
                    if (setInitialInterview) {
                        // Try to preselect the blank checkbox
                        precedence = (masterTicked == null || masterTicked == false) ? MASTER : ((currentTicked == null && currentTicked == false) ? CURRENT : EQUAL);
                    } else {
                        // Try to preselect the ticked checkbox
                        precedence = (masterTicked != null && masterTicked == true) ? MASTER : ((currentTicked != null && currentTicked == true) ? CURRENT : EQUAL);
                    }
                } else if (masterRecordTypeID == CA) {
                    precedence = (oldRecord.Id == masterRecord.Id) ? MASTER : CURRENT;
                }
            } else {
                precedence = getHighestPrecedence('RecordTypeId', masterRecord, currentRecord);
            }

            return precedence;
        }
        
        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;

            if (fieldName == 'RecordTypeId') {
                precedence = caseRecordTypePrecedence(fieldValue);
            }
            
            return precedence;
        }
    }

    //#313212: Comparator for TimeAndDateOfInitialEmail Field
    public class TimeAndDateOfSentInitialEmailComparator extends dcPluginComparatorAbstract {
        public TimeAndDateOfSentInitialEmailComparator(Map<String, Id> recordTypeMap) {
            storeCaseRecordTypes(recordTypeMap);
        }

        public override Integer compare(SObject masterRecord, SObject currentRecord) {
            Integer precedence = EQUAL; // default if no rules match    

            Id masterRecordTypeID  = (Id)masterRecord.get('RecordTypeId');
            Id currentRecordTypeID = (Id)currentRecord.get('RecordTypeId');

            if (masterRecordTypeID == currentRecordTypeID && masterRecordTypeID == PCC) {

                DateTime masterInitialEmailSentDateTime = (DateTime)masterRecord.get('Time_and_Date_of_sent_initial_email__c');
                DateTime currentInitialEmailSentDateTime = (DateTime)currentRecord.get('Time_and_Date_of_sent_initial_email__c');

                if((masterInitialEmailSentDateTime == null && currentInitialEmailSentDateTime != null) 
                    || (masterInitialEmailSentDateTime != null && currentInitialEmailSentDateTime != null && currentInitialEmailSentDateTime > masterInitialEmailSentDateTime)){
                    precedence =  CURRENT;
                }
                else if((masterInitialEmailSentDateTime != null && currentInitialEmailSentDateTime == null) 
                        || (masterInitialEmailSentDateTime != null && currentInitialEmailSentDateTime != null && masterInitialEmailSentDateTime > currentInitialEmailSentDateTime )){
                    precedence =  MASTER;
                }
                else if(masterInitialEmailSentDateTime == null && currentInitialEmailSentDateTime == null){
                    precedence = EQUAL;
                }
                    
            } else {
                precedence = getHighestPrecedence('RecordTypeId', masterRecord, currentRecord);
            }

            return precedence;
        }
        
        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;

            if (fieldName == 'RecordTypeId') {
                precedence = caseRecordTypePrecedence(fieldValue);
            }
            
            return precedence;
        }
    }

    // #313212: Comparator for SendInitialNotificationEmail Field
    public class SendInitialNotificationEmailCheckboxComparator extends dcPluginComparatorAbstract {
        public SendInitialNotificationEmailCheckboxComparator(Map<String, Id> recordTypeMap) {
             storeCaseRecordTypes(recordTypeMap);
         }
 
         public override Integer compare(SObject masterRecord, SObject currentRecord) {
             Integer precedence = EQUAL; // default if no rules match
                        
             Id masterRecordTypeID  = (Id)masterRecord.get('RecordTypeId');
             Id currentRecordTypeID = (Id)currentRecord.get('RecordTypeId');
 
             Boolean masterTicked  = (Boolean)masterRecord.get('Send_initial_notification_email__c');
             Boolean currentTicked = (Boolean)currentRecord.get('Send_initial_notification_email__c');
 
             if (masterRecordTypeID == currentRecordTypeID && masterRecordTypeID == PCC) {
                precedence =  masterTicked == false ? MASTER : (currentTicked == false ? CURRENT : EQUAL); 
             } else {
                 precedence = getHighestPrecedence('RecordTypeId', masterRecord, currentRecord);
             }
 
             return precedence;
         }
         
         public override Integer getPrecedence(String fieldName, String fieldValue) {
             Integer precedence = 0;
 
             if (fieldName == 'RecordTypeId') {
                 precedence = caseRecordTypePrecedence(fieldValue);
             }
             
             return precedence;
         }
    }

    // #321606: Marketing Cloud - Merge Rules for Marketing Cloud Day 0
    public class MCDay0PicklistComparator extends dcPluginComparatorAbstract {
        public MCDay0PicklistComparator(Map<String, Id> recordTypeMap) {
             storeCaseRecordTypes(recordTypeMap);
         }
 
         public override Integer compare(SObject masterRecord, SObject currentRecord) {
            Integer precedence = EQUAL; // default if no rules match
                    
            Id masterRecordTypeID  = (Id)masterRecord.get('RecordTypeId');
            Id currentRecordTypeID = (Id)currentRecord.get('RecordTypeId');

            String masterValue  = (String)masterRecord.get('Marketing_Cloud_PCC_Day_0__c');
            String currentValue = (String)currentRecord.get('Marketing_Cloud_PCC_Day_0__c');

            if (masterRecordTypeID == currentRecordTypeID) {
                precedence =  String.isBlank(masterValue) ? CURRENT : (String.isBlank(currentValue) ? MASTER: EQUAL);
            } else {
                precedence = getHighestPrecedence('RecordTypeId', masterRecord, currentRecord);
            }

            return precedence;
         }
         
         public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;

            if (fieldName == 'RecordTypeId') {
                precedence = caseRecordTypePrecedence(fieldValue);
            }
            
            return precedence;
         }
    }

    public class ReleaseComparator extends dcPluginComparatorAbstract {
        public ReleaseComparator(Map<String, Id> recordTypeMap) {
             storeCaseRecordTypes(recordTypeMap);
         }
 
         public override Integer compare(SObject masterRecord, SObject currentRecord) {

            Integer precedence = EQUAL; // default if no rules match

            Id masterRecordTypeID  = (Id)masterRecord.get('RecordTypeId');
            Id currentRecordTypeID = (Id)currentRecord.get('RecordTypeId');

            if (masterRecordTypeID == currentRecordTypeID) {
                
                // Logic to merge record with Active and Inactive Status
                Set<String> activeStatuses = new Set<String> {'Identify', 'Quarantine', 'Trace', 'Isolate'};
                Set<String> inActiveStatuses = new Set<String> { 'Ex-HQ Follow-up', 'Closed'};

                Boolean masterReleased = (masterRecord.get('Case_Cleared_from_Isolation__c') == 'Yes')? TRUE : FALSE;
                Boolean currentReleased = (currentRecord.get('Case_Cleared_from_Isolation__c') == 'Yes')? TRUE : FALSE;
				
                if((activeStatuses.contains((String)masterRecord.get('Status')) && activeStatuses.contains((String)currentRecord.get('Status'))) ||
                    (activeStatuses.contains((String)masterRecord.get('Status')) && inActiveStatuses.contains((String)currentRecord.get('Status'))) ||
                    (inActiveStatuses.contains((String)masterRecord.get('Status')) && activeStatuses.contains((String)currentRecord.get('Status')))
                ){
                    precedence = (masterReleased != TRUE) ? MASTER : (currentReleased != TRUE) ? CURRENT : EQUAL;
                } else if(inActiveStatuses.contains((String)masterRecord.get('Status')) && inActiveStatuses.contains((String)currentRecord.get('Status'))){
                    precedence = (masterReleased == TRUE) ? MASTER : (currentReleased == TRUE) ? CURRENT : EQUAL;    
                } 

                if (precedence == EQUAL) {
                    precedence = getHighestPrecedence('Case_Cleared_from_Isolation__c', masterRecord, currentRecord);
                }
            } 
            return precedence;
            
         }
         
        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;
            if (fieldName == 'Case_Cleared_from_Isolation__c') {
                switch on fieldValue {
                    when 'Yes' {
                        precedence = 1;
                    }
                    when 'No' {
                        precedence = 2;
                    }
                    when else {
                        precedence = 999;
                    }
                }
            } 
            return precedence;
         }
     }



     public class DateReleaseComparator extends dcPluginComparatorAbstract {
        public DateReleaseComparator(Map<String, Id> recordTypeMap) {
             storeCaseRecordTypes(recordTypeMap);
         }
 
         public override Integer compare(SObject masterRecord, SObject currentRecord) {
            Integer precedence = EQUAL; // default if no rules match

            Id masterRecordTypeID  = (Id)masterRecord.get('RecordTypeId');
            Id currentRecordTypeID = (Id)currentRecord.get('RecordTypeId');

            if (masterRecordTypeID == currentRecordTypeID) {
                
                // Logic to merge record with Active and Inactive Status
                Set<String> activeStatuses = new Set<String> {'Identify', 'Quarantine', 'Trace', 'Isolate'};
                Set<String> inActiveStatuses = new Set<String> { 'Ex-HQ Follow-up', 'Closed'};
                
                Boolean isMasterRecent = ((DateTime)masterRecord.get('Date_Cleared_from_Isolation__c') >= (DateTime)currentRecord.get('Date_Cleared_from_Isolation__c'))? TRUE : FALSE ;
                Boolean isMasterNotNull = (DateTime)masterRecord.get('Date_Cleared_from_Isolation__c') != null? TRUE : FALSE ;
                Boolean isCurrentNotNull = (DateTime)currentRecord.get('Date_Cleared_from_Isolation__c') != null? TRUE : FALSE ;
                if((activeStatuses.contains((String)masterRecord.get('Status')) && activeStatuses.contains((String)currentRecord.get('Status'))) ||
                    (inActiveStatuses.contains((String)masterRecord.get('Status')) && inActiveStatuses.contains((String)currentRecord.get('Status'))) ){
                       //335195
                        if(isMasterRecent && isMasterNotNull){
                            precedence =  MASTER; 
                        } else if (isCurrentNotNull) {
                            precedence =  CURRENT ;
                        } else {
                            precedence =  MASTER;
                        }
                } else if (inActiveStatuses.contains((String)masterRecord.get('Status')) && activeStatuses.contains((String)currentRecord.get('Status'))){
                    precedence =  CURRENT ;
                } else if (activeStatuses.contains((String)masterRecord.get('Status')) && inActiveStatuses.contains((String)currentRecord.get('Status'))){
                    precedence =  MASTER;
                } 
                if (precedence == EQUAL) {
                    precedence = getHighestPrecedence('Date_Cleared_from_Isolation__c', masterRecord, currentRecord);
                }
            } 
            return precedence;
         }
         
        public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;
            if (fieldName == 'Date_Cleared_from_Isolation__c') {
                switch on fieldValue {
                    when '' {
                        precedence = 1;
                    }
                    when else {
                        precedence = 999;
                    }
                }
            } 
            return precedence;
        }
     } 
     
     
     public class ClearanceLetterReleaseComparator extends dcPluginComparatorAbstract {
        public ClearanceLetterReleaseComparator(Map<String, Id> recordTypeMap) {
             storeCaseRecordTypes(recordTypeMap);
         }
 
         public override Integer compare(SObject masterRecord, SObject currentRecord) {
            Integer precedence = EQUAL; // default if no rules match

            Id masterRecordTypeID  = (Id)masterRecord.get('RecordTypeId');
            Id currentRecordTypeID = (Id)currentRecord.get('RecordTypeId');

            if (masterRecordTypeID == currentRecordTypeID) {
                
                // Logic to merge record with Active and Inactive Status
                Set<String> activeStatuses = new Set<String> {'Identify', 'Quarantine', 'Trace', 'Isolate'};
                Set<String> inActiveStatuses = new Set<String> { 'Ex-HQ Follow-up', 'Closed'};

                Boolean masterReleased = (masterRecord.get('Has_Clearance_Letter_Been_Sent__c') == 'Yes')? TRUE : FALSE;
                Boolean currentReleased = (currentRecord.get('Has_Clearance_Letter_Been_Sent__c') == 'Yes')? TRUE : FALSE;
				
                if((activeStatuses.contains((String)masterRecord.get('Status')) && activeStatuses.contains((String)currentRecord.get('Status'))) ||
                    (activeStatuses.contains((String)masterRecord.get('Status')) && inActiveStatuses.contains((String)currentRecord.get('Status'))) ||
                    (inActiveStatuses.contains((String)masterRecord.get('Status')) && activeStatuses.contains((String)currentRecord.get('Status')))
                ){
                    precedence = (masterReleased != TRUE) ? MASTER : (currentReleased != TRUE) ? CURRENT : EQUAL;
                } else if(inActiveStatuses.contains((String)masterRecord.get('Status')) && inActiveStatuses.contains((String)currentRecord.get('Status'))){
                    precedence = (masterReleased == TRUE) ? MASTER : (currentReleased == TRUE) ? CURRENT : EQUAL;    
                } 

                if (precedence == EQUAL) {
                    precedence = getHighestPrecedence('Has_Clearance_Letter_Been_Sent__c', masterRecord, currentRecord);
                }
            } 
            return precedence;
         }
         
         public override Integer getPrecedence(String fieldName, String fieldValue) {
            Integer precedence = 0;
            if (fieldName == 'Has_Clearance_Letter_Been_Sent__c	') {
                switch on fieldValue {
                    when 'Yes' {
                        precedence = 1;
                    }
                    when 'No' {
                        precedence = 2;
                    }
                    when else {
                        precedence = 999;
                    }
                }
            } 
            return precedence;
         }
     }

    public class MergeRuleException extends Exception {}

}