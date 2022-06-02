/**
* @Author             : DHHS
* @Description        : Survey Response trigger helper
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 20/11/2021     Abbas Bagichawala      //PBI 338777,338791,338791,339298,339021 - Confirmed Case Interview Survey
* 20/11/2021     Smita Kagde            //PBI 340230,338740
* 20/11/2021     Abbas Bagichawala      //PBI 341542 - Added changes to trancate string for FirstName,LastName,Email. 

**/
public class CSRTriggerHelper {
    Public static final id PERSON_ACCOUNT_RT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
    Public static final id CLOSE_CONTACT_RT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
    Public static final id CE_WSC_RT  = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByName().get('Work/Study/Care').getRecordTypeId();
    Public static final id CE_TH_RT  = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByName().get('Travel History').getRecordTypeId();
    Public static final id CONTACT_CONFIRMED_CASE_RT = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByName().get('Contact with Confirmed Case').getRecordTypeId();
    Public static final String ACCOUNT_DETAILS = 'Account Details';
    Public static final String CAR_DETAILS = 'CAR - Details';
    Public static final String HMIP_DETAILS = 'HMIP Details';
    Public static final String WSC_DETAILS = 'WSC - Details';
    Public static final String EHR_DETAILS = 'EHR Details';
    Public static final String THistory_DETAILS = 'Travel History';
    public static Map<String, String> mapSurveyAboriginalValuesToAPI = new Map<String, String>{
            'Aboriginal'.toLowerCase() => 'ABORIGINAL',
            'Torres Strait islander'.toLowerCase() => 'TORRES_STRAIT_ISLANDER ',
            'Both Aboriginal and Torres strait islander'.toLowerCase() => 'BOTH',
            'Prefer not to say'.toLowerCase() => 'DECLINE',
            'Not Aboriginal or Torres Strait Islander'.toLowerCase() => 'NEITHER',
            'Unknown'.toLowerCase() => 'UNKNOWN'
    };
    public static final String TRAVEL_HISTORY_DEFAULT_COUNTRY_CODE = 'UNK';
    public static final String TRAVEL_HISTORY_CONTACT_ENCOUNTER_NAME = 'Case self-filled survey travel';
    public static Map<String, String> employmentStatusPicklistMap;

     /**
     * PBI 338777 
     * @description createCAR - This method is used to create Clinical assessnment record and is related to case and account.
     * @param  newCSR  List of new customer survey response
     */ 
    Public static void createCAR(List<Survey_Response__c> newCSR ){
        Map<String,Survey_Response__c> mapCaseToCSR = new Map<String,Survey_Response__c>();
        for(Survey_Response__c csrObj : newCSR)
        {
            system.debug('CSR Record ***'+csrObj );
            if(csrObj.subject__c!=null && csrObj.Record__c!=null && csrObj.subject__c == CAR_DETAILS){
                mapCaseToCSR.put(csrObj.Record__c,csrObj);
            }  
        }
        List<Case> carCaseList = new List<Case>();
        List<HealthCloudGA__Clinical_Assessment_Response__c> healthCARList = new List<HealthCloudGA__Clinical_Assessment_Response__c>();
        if(!mapCaseToCSR.isEmpty()){
			carCaseList = [Select id,Accountid from case where id in: mapCaseToCSR.keyset()];
        	            
        }
        
        for(Case caseObj : carCaseList){
            Survey_Response__c csrObj = mapCaseToCSR.get(caseObj.id);
            HealthCloudGA__Clinical_Assessment_Response__c healthCAR = new HealthCloudGA__Clinical_Assessment_Response__c();
            healthCAR.Name = 'Case Interview Survey Response';
            healthCAR.Record__c = caseObj.id;
            boolean isAllowed = false;
            if(String.isNotBlank(csrObj.had_any_symptoms_in_the_last_5days__c ))
            {
                isAllowed = true;
                healthCAR.Did_person_have_symptoms__c = csrObj.had_any_symptoms_in_the_last_5days__c;
            }
            if(csrObj.what_date_did_you_first_become_unwell__c!=null){
            	isAllowed = true;
            	healthCAR.HealthCloudGA__OnsetOfSymptoms__c = csrObj.what_date_did_you_first_become_unwell__c;    
            }
            if(String.isNotBlank(caseObj.Accountid))
            	healthCAR.HealthCloudGA__Patient__c = caseObj.Accountid;
            
            if(isAllowed)
            	healthCARList.add(healthCAR);
        }
        if(healthCARList.size()>0){
            try{
            	insert healthCARList;
            }
        	catch(Exception exp){
        		ApplicationLogUtility.createlog('CSRTriggerHelper','createCAR',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            }
        }
        system.debug('CAR Inserted'+healthCARList);
    }
    
    /**
     * 338791
     * @description createHMIP - This method is used to create Hospital, Medical and Isolation Presentation.
     * @param  newCSR  List of new customer survey response
     */ 
    Public static void createHMIP(List<Survey_Response__c> newCSR ){
        List<Survey_Response__c> hmipList = new List<Survey_Response__c>();
        for(Survey_Response__c csrObj : newCSR)
        {
            if(csrObj.subject__c!=null && csrObj.Record__c!=null && csrObj.subject__c == HMIP_DETAILS){
                hmipList.add(csrObj);
            }  
        }
        List<HealthCloudGA__EhrEncounter__c> createHMIPList = new List<HealthCloudGA__EhrEncounter__c>();
        for(Survey_Response__c srObj : hmipList){
            HealthCloudGA__EhrEncounter__c hmipObj = new HealthCloudGA__EhrEncounter__c();
            if(srObj.What_date_did_you_start_to_isolate__c!=null){
            	hmipObj.Record__c  = srObj.record__c; 
                hmipObj.StartDate__c = srObj.What_date_did_you_start_to_isolate__c;
                hmipObj.Presented_to__c = 'Home isolation';
                createHMIPList.add(hmipObj);    
            }
        }
        if(createHMIPList.size()>0){
            try{
            	insert createHMIPList;
            }
        	catch(Exception exp){
        		ApplicationLogUtility.createlog('CSRTriggerHelper','createHMIP',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            }
        }
        system.debug('HMIP Inserted'+createHMIPList);
    }
    
    /**
     * 339298
     * @description createContactEncounterWSC - This method is used to create contactEncounter of record type .
     * @param  newCSR  List of new customer survey response
    */ 
    public static void createContactEncounterWSC(List<Survey_Response__c> newCSR ) {
        Map<String, String> occupationMap = new Map<String, String>();
        List<Survey_Response__c> wscList = new List<Survey_Response__c>();
        Set<String> occNames = new Set<String>();
        for (Survey_Response__c csrObj : newCSR) {
            if (csrObj.Record__c != null && csrObj?.Subject__c == WSC_DETAILS) {
                wscList.add(csrObj);
                String csrOccupation = csrObj.What_is_your_job_title__c != 'Other'
                        ? csrObj.What_is_your_job_title__c : csrObj.Other_Occupation__c;
                if (String.isNotBlank(csrOccupation)) {
                    occNames.add(csrOccupation);
                }
            }
        }
        if (!occNames.isEmpty()) {
            for (Occupation__c occObj : [SELECT Name,Id FROM Occupation__c WHERE Name IN :occNames]) {
                occupationMap.put(occObj.Name, occObj.Id);
            }
        }
        List<ContactEncounter> contactEncounterList = new List<ContactEncounter>();
        for (Survey_Response__c csrObj : wscList) {
            // Include if either job title or employment status is not blank
            if (String.isNotBlank(csrObj?.What_is_your_job_title__c) || String.isNotBlank(csrObj?.What_is_your_employment_status__c)) {
                if (employmentStatusPicklistMap == null) {
                    employmentStatusPicklistMap = getActivePicklistValues('ContactEncounter', 'Employment_Status__c');
                }
                ContactEncounter wscObj = new ContactEncounter();
                wscObj.Record__c = csrObj.Record__c;
                wscObj.RecordTypeId = CE_WSC_RT;
                wscObj.Description = csrObj.name_of_your_main_place_of_employment__c ;
                wscObj.StartTime = System.today();
                String csrOccupation = csrObj.What_is_your_job_title__c != 'Other'
                        ? csrObj.What_is_your_job_title__c : csrObj.Other_Occupation__c ;
                String occName = csrOccupation;
                if (csrObj?.What_is_your_employment_status__c == 'Prefer not to answer'
                        || String.isBlank(csrOccupation)) {
                    occName = csrObj.What_is_your_employment_status__c;
                    wscObj.Employment_Status__c = null;
                } else {
                    wscObj.Employment_Status__c = employmentStatusPicklistMap.get(csrObj.What_is_your_employment_status__c);
                }
                wscObj.Name = occName;
                wscObj.Occupation__c = occupationMap.get(occName);
                contactEncounterList.add(wscObj);
            }
            try {
                insert contactEncounterList;
            } catch (Exception exp) {
                ApplicationLogUtility.createlog('CSRTriggerHelper', 'createContactEncounterWSC', exp.getStackTraceString(), exp.getMessage(), exp.getTypeName());
            }
        }

        System.debug('WSC Inserted' + contactEncounterList);
    }
     /**
     * 340230
     * @description createContactEncounterTravelHistory - This method is used to create contactEncounter of record type Travel history.
     * @param  newCSR  List of new customer survey response
    */ 
    public static void createContactEncounterTravelHistory (List<Survey_Response__c> newCSR ) {
        List<ContactEncounter> contactEncounterList = new List<ContactEncounter>();

        for (Survey_Response__c csrObj : newCSR) {
            if (csrObj.Subject__c == THistory_DETAILS && csrObj.Returned_from_overseas_in_the_past_14day__c == 'Yes') {
                ContactEncounter thCEObj = new ContactEncounter();
                thCEObj.Recent_Travel_Overseas__c = csrObj.Returned_from_overseas_in_the_past_14day__c;
                thCEObj.Recent_Travel_Overseas_Notes__c = csrObj.Countries_visited_in_the_past_14_days__c;
                thCEObj.RecordTypeId = CE_TH_RT;
                thCEObj.Country__c = TRAVEL_HISTORY_DEFAULT_COUNTRY_CODE;
                thCEObj.Record__c = csrObj.Record__c;
                thCEObj.Name = TRAVEL_HISTORY_CONTACT_ENCOUNTER_NAME;
                thCEObj.StartTime = csrObj.What_date_did_you_arrive__c == null ? System.today() : csrObj.What_date_did_you_arrive__c;
                contactEncounterList.add(thCEObj);
            }
        }

        try {
            insert contactEncounterList;
        } catch (Exception exp) {
            ApplicationLogUtility.createlog('CSRTriggerHelper', 'createContactEncounterTravelHistory', exp.getStackTraceString(), exp.getMessage(), exp.getTypeName());
        }
    }
        
    /**
    * PBI - 339278  
    * @description createEHRImmunization - This method is used to create EHR Immunization record. 
    * @param  newCSR  List of new customer survey response
    */ 
    Public static void createEHRImmunization(List<Survey_Response__c> newCSR ){
        Map<String,Survey_Response__c> mapCaseToCSR = new Map<String,Survey_Response__c>();
        List<Case> ehrCaseList = new List<Case>();
        List<HealthCloudGA__EhrImmunization__c> ehrImmunizationList = new List<HealthCloudGA__EhrImmunization__c>();
        for(Survey_Response__c csrObj : newCSR)
        {
            if(csrObj.subject__c!=null && csrObj.Record__c!=null && csrObj.subject__c == EHR_DETAILS){
                mapCaseToCSR.put(csrObj.Record__c,csrObj);
            }  
        }
		
        if(!mapCaseToCSR.isEmpty()){
        	ehrCaseList = [Select id,Account.personcontactid from case where id in: mapCaseToCSR.keyset()];
        }
        
        for(Case caseObj : ehrCaseList){
            Survey_Response__c csrObj = mapCaseToCSR.get(caseObj.id);
            HealthCloudGA__EhrImmunization__c ehrObj = new HealthCloudGA__EhrImmunization__c();
            if(String.isNotBlank(csrObj.Have_you_had_a_COVID_19_vaccine__c) && csrObj.Have_you_had_a_COVID_19_vaccine__c=='Yes'){
            	ehrObj.Validation_Status__c = '2';
            	if(caseObj.accountId !=null && caseObj.account.personcontactid!=null)
            		ehrObj.contact__c = caseObj.account.personcontactid;
           		ehrObj.Dose_Received__c = '2nd';
                ehrObj.Have_you_had_a_COVID_19_vaccine__c = true;
                ehrImmunizationList.add(ehrObj);    
            }  
        }
        
        if(ehrImmunizationList.size()>0){
            try{
            	insert ehrImmunizationList;
            }
        	catch(Exception exp){
        		ApplicationLogUtility.createlog('CSRTriggerHelper','createEHRImmunization',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            }
        }
        system.debug('EHR Inserted'+ehrImmunizationList);
    }
	
    /**
    * PBI - 339021  
    * @description createSingleCloseContactPersonAccount - This method runs in async mode. 
    * It is used to create Primary Close contact record. New records created are(Contact Encounter,Record,Contact Encounter Participant,Person Account) 
    * @param  newCSR  List of new customer survey response Ids
    */ 
    
    @future
    Public static void createSingleCloseContactPersonAccount(List<String> newCSRIDs){
    	Account acc;
        ContactEncounter ce;
        String primaryCaseId = '';
        String LivewithPerson = '';
        for(Survey_Response__c srObj: [select id,Record__c,subject__c,Do_you_live_with_this_person__c,Date_you_last_had_contact_with_this_pers__c,Street__c,City__c,PostCode__c,State__c,First_Name__c,Last_Name__c,DOB__c,Mobile_Phone__c from Survey_Response__c where id in : newCSRIDs]){
            String CSRSubject = srObj.subject__c;
            if(String.isNotBlank(CSRSubject) && srObj.Record__c!=null &&  CSRSubject.contains('Close Contact')){
                LivewithPerson = srObj.Do_you_live_with_this_person__c;
            	String Country = '';
                if(String.isNOtBlank(srObj.Street__c) || String.isNOtBlank(srObj.PostCode__c) || String.isNOtBlank(srObj.State__c) || String.isNOtBlank(srObj.City__c))
                    Country = 'Australia';
                
                if(String.isNotBlank(srObj.First_Name__c)) srObj.First_Name__c =  fetchTruncatedString(40,srObj.First_Name__c);
                if(String.isNotBlank(srObj.Last_Name__c)) srObj.Last_Name__c =  fetchTruncatedString(80,srObj.Last_Name__c);
                acc = createCCPersonAccount(srObj.First_Name__c,srObj.Last_Name__c,srObj.DOB__c,srObj.Street__c,srObj.City__c,srObj.PostCode__c,srObj.State__c,Country,srObj.Mobile_Phone__c,srObj.record__c);
                ce = createCCContactEncounter(srObj.record__c,srObj.Date_you_last_had_contact_with_this_pers__c);
                primaryCaseId = srObj.record__c;
                if(String.isNotBlank(primaryCaseId)){
            Case caseObj = [select id,Date_of_Test__c,Calculated_Onset_Date__c,createdDate from case where id = :primaryCaseId limit 1];
            String relationshipToCase = 'Household-like'; 
            if(LivewithPerson=='Yes')
            {
                relationshipToCase = 'Household';
                if(caseObj!=null){
                	if(caseObj.Date_of_Test__c!=null)
            			ce.StartTime = caseObj.Date_of_Test__c;
                	else if(caseObj.Calculated_Onset_Date__c!=null)
                    	ce.StartTime = caseObj.Calculated_Onset_Date__c;    
                	else
                        ce.StartTime = caseObj.createdDate;   
                }
            }
            try{
            	insert acc;
                system.debug('Account Inserted'+acc);
                insert ce;
                system.debug('CE Inserted'+ce);
                Case CloseContact = createCloseContactCase(acc);
                insert CloseContact;
                system.debug('Close Contact Inserted'+CloseContact);
                ContactEncounterParticipant cep = createContactEncounterParticipant(CloseContact.id,primaryCaseId,ce.id,acc.id,relationshipToCase);
                insert cep;  
                system.debug('CEP Inserted'+cep);    
            }catch(Exception exp){
        		ApplicationLogUtility.createlog('CSRTriggerHelper','createSingleCloseContactPersonAccount',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            }
            
        }
      }    
            //caseIds.add(srObj.record__c);
        }
        
       	        
    }
    
    Public static ContactEncounter createCCContactEncounter(Id caseId,Date startTime){
        ContactEncounter ce = new ContactEncounter();
        ce.RecordTypeId = CONTACT_CONFIRMED_CASE_RT;
        ce.StartTime = startTime;
        ce.Location = null;
        ce.record__c = caseId;
        ce.Name = 'Case Interview';
        return ce; 	    
    }

    Public static Account createCCPersonAccount(String FirstName,String LastName,Date dob,String street,String suburb,String postcode,String state,string country, String mobile,Id caseId){
        Account acc = new Account();
        acc.recordtypeid = PERSON_ACCOUNT_RT;
        acc.FirstName = FirstName;
        acc.LastName = LastName;
        acc.PersonBirthdate = dob;
        acc.PersonMobilePhone = mobile;
        acc.PersonMailingStreet= Street;
        acc.PersonMailingCity = suburb;
        acc.PersonMailingPostalCode = PostCode;
        acc.PersonMailingCountry = Country;
        acc.PersonMailingState = State;
        return acc;
    }
    
    Public static Case createCloseContactCase(Account accObj){
        Case newCase = new Case();
        newCase.RecordTypeId = CLOSE_CONTACT_RT;
        newCase.Case_Classification__c = 'At Risk';
        newCase.Epi_Classification__c = 'Epidemiologically linked to a laboratory confirmed case';
        newCase.Case_Found_By__c = 'Contact tracing';
        newCase.Status = 'Identify';
        newCase.SubStatus__c = 'In Progress';
        newCase.AccountId = accObj.id;
        return newCase;
    }
    
    Public static ContactEncounterParticipant createContactEncounterParticipant(String newCaseId,String PrimaryCaseId,String newContactEncounterID,String newAccountId,String relationshiptocase){
        ContactEncounterParticipant cep = new ContactEncounterParticipant();
        cep.Parent_Record__c = PrimaryCaseId;
        cep.Record__c = newCaseId;
        cep.ContactEncounterId = newContactEncounterID;
        cep.Account__c = newAccountId;
        cep.Contact_Type__c = 'Close contact';
        cep.Relationship_to_Case__c = relationshiptocase;
        //cep.Specify_relationship_to_case__c	 = specifyrelationshiptocase;
        return cep;
    }
    
    Public static String fetchTruncatedString(Integer maxSize,String sizeString){
        if(sizeString.length() > maxSize ){
            sizeString = sizeString.substring(0, maxSize);
        }
        return sizeString;
    }
    
	/**
     * @description Retrieve active picklist values
     * @param objectApiName API name of the sobject
     * @param fieldAPIName API name of the picklist field
     *
     * @return Map<String,String>
     */
    public static Map<String,String> getActivePicklistValues(String objectApiName, String fieldAPIName) {
        Map<String,String> mapLabelTOApi = new Map<String,String>();
        for (Schema.PicklistEntry entry : SystemUtils.getPickListValuesInObject(objectApiName, fieldAPIName)) {
            if (entry.isActive()) {
                mapLabelTOApi.put(entry.getLabel(),entry.getValue());
            }
        }
        return mapLabelTOApi;
    }    
    
    /**
     * @description updateAccount - This method is used to update Acccount details.
     * @param  newCSR  List of new customer survey response
     */ 
    Public static void updateAccount(List<Survey_Response__c> newCSR ){
        Map<String,Survey_Response__c> mapCaseToCSR = new Map<String,Survey_Response__c>();
       
        for(Survey_Response__c csrObj : newCSR)
        {
            system.debug('Custom Survey Response*******'+newCSR);
            if(String.isNotBlank(csrObj.subject__c) && csrObj.subject__c == CSRTriggerHelper.ACCOUNT_DETAILS && csrObj.Record__c!=null){
                            system.debug('---Subject=='+csrObj.subject__c+'--Record__c***'+csrObj.Record__c);
                mapCaseToCSR.put(csrObj.Record__c,csrObj);
            }  
        }
        Map<String,String> mapCaseToAccount = new Map<String,String>();
        Map<String,String> mapCountryOfBirthValues;
        if(!mapCaseToCSR.isEmpty()){
            mapCountryOfBirthValues = getActivePicklistValues('Account','Country_of_birth__c');
         	for(Case caseObj : [select id,AccountId from Case where id in : mapCaseToCSR.keyset()]){
                system.debug('---Here at account');
                mapCaseToAccount.put(caseObj.id,caseObj.AccountId);    
            }   
        }
        
        List<Account> updateAccountList = new List<Account>();
           for(String srObjId : mapCaseToCSR.keyset()){
            Survey_Response__c csrObj = mapCaseToCSR.get(srObjId);
            Account accObj = new Account();
            String picklist ='';
            accObj.id = mapCaseToAccount.get(srObjId);    
            if(String.isNotBlank(csrObj.First_Name__c))  accObj.FirstName = fetchTruncatedString(40,csrObj.First_Name__c);
            if(String.isNotBlank(csrObj.First_Name__c)) accObj.LastName = fetchTruncatedString(80,csrObj.Last_Name__c);
            if(String.isNotBlank(csrObj.Email__c)) accObj.PersonEmail = fetchTruncatedString(80,csrObj.Email__c);
            if(csrObj.DOB__c != NULL) accObj.PersonBirthdate = csrObj.DOB__c;
            if(String.isNotBlank(csrObj.Sex__c))accObj.Sex__c = csrObj.Sex__c;
            if(String.isNotBlank(csrObj.Street__c))accObj.PersonMailingStreet= csrObj.Street__c;
            if(String.isNotBlank(csrObj.City__c))  accObj.PersonMailingCity = csrObj.City__c;
            if(String.isNotBlank(csrObj.PostCode__c))accObj.PersonMailingPostalCode = csrObj.PostCode__c;
            if(String.isNotBlank(csrObj.Country__c))accObj.PersonMailingCountry =csrObj.Country__c;
            if(String.isNotBlank(csrObj.State__c))accObj.PersonMailingState =csrObj.State__c;
            if(String.isNotBlank(csrObj.Mobile_Phone__c))accObj.PersonMobilePhone = csrObj.Mobile_Phone__c;
            if(String.isNotBlank(csrObj.primary_language_spoken_at_home__c) && csrObj.primary_language_spoken_at_home__c !='Prefer not to answer') accObj.Language_spoken_at_home__c = csrObj.primary_language_spoken_at_home__c;
            if(String.isNotBlank(csrObj.cultural_background_or_ethnicity__c) && csrObj.cultural_background_or_ethnicity__c !='Prefer not to answer')accObj.Cultural_Identity__c = csrObj.cultural_background_or_ethnicity__c;
            if(String.isNotBlank(csrObj.What_type_of_property_is_this__c))accObj.Accommodation_type__c =csrObj.What_type_of_property_is_this__c;
            if(String.isNotBlank(csrObj.Do_you_require_an_Aboriginal_Support__c)) accObj.Cultural_Support_Officer_Required__c = csrObj.Do_you_require_an_Aboriginal_Support__c;                
            if(String.isNotBlank(csrObj.identify_Aboriginal_or_Torres__c)) {
                accObj.Aboriginal_or_Torres_Strait_Islander__c = mapSurveyAboriginalValuesToAPI.get(
                        csrObj.identify_Aboriginal_or_Torres__c.trim().toLowerCase());
            }
			if(mapCountryOfBirthValues!=null && String.isNotBlank(csrObj.What_is_your_country_of_birth__c) && mapCountryOfBirthValues.get(csrObj.What_is_your_country_of_birth__c)!=null)
            accObj.Country_of_birth__c  = mapCountryOfBirthValues.get(csrObj.What_is_your_country_of_birth__c);
               
		updateAccountList.add(accObj);	
        }  
        
        if(updateAccountList.size()>0){
            try{
                system.debug('*******'+updateAccountList);
            	update updateAccountList;
            }
        	catch(Exception exp){
        		ApplicationLogUtility.createlog('CSRTriggerHelper','updateAccount',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            }
        }
    }
}