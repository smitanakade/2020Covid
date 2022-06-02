public class CaseService{

    private final Case CaseObj;
    private final  List<ContactEncounter> confirmedCEPs;
    private final  List<ContactEncounter> closedCEPs;


    public CaseService(Id caseId)
    {
        this(caseId, DateTime.newInstance(0));
    }
        
    public CaseService(Id caseId, DateTime RecordExtractLastRun){
        CaseObj = [SELECT Id,
                        RecordExtractLastRun__c,
                        If_Yes_Exclusion_letter_sent_by_DHHS__c,
                        Information_sent_on__c,
                        Person_Interviewed__c,
                        if_Other_Specifiy__c,
                        Case_Cleared_from_Isolation__c,
                        Date_Cleared_from_Isolation__c,
                        Has_Clearance_Letter_Been_Sent__c,
                        Interviewed_by__c,
                        Date_of_interview__c,
                        Initial_Interview_completed__c,
                        Statement_to_case_or_person_representing__c,
                        AccountId,
                        Case_Classification__c,
                        Origin,
                        Description,
                        Include_In_Whispir_Communication__c,
                        Symptoms_Onset_Date__c,
                        Date_of_Test__c,
                        Priority,
                        Status,
                        SubStatus__c,
                        OwnerId,
                        Confirmation_Date__c,
                        Clearance_eligibility_assessment_date__c,
                        Severely_Ill__c,
                        Immunocompromised__c,
                        Sensitive__c,
                        Other_Sensitive_Settings__c,
                        CreatedById,
                        Subject,
                        SuppliedEmail,
                        ContactId,
                        Investigation_type__c,
                        LastModifiedById,
                        RecordTypeId,
                        PHESS_ID__c,
                        PHESS_ID_name__c,
                        Notify_doctor_on_intent_to_contact_case__c,
                        If_yes_Notified_Doctor_on__c,
                        Doctor_Name_Instance__c,
                        Case_contact_with_confirmed_case__c,
                        //Case_contact_hospital_prior_symptoms__c,
                        //Case_contact_hospital_48h_prior_symptoms__c,
                        Contact_hospital_14_days_prior_symptoms__c,
                        Contact_hospital_48_hours_prior_symptoms__c,
                        case_travel_in_AUS_14d_prior_symptoms__c,
                        Case_Travel_Overseas_14d_Prior_Symtoms__c,
                        Prior_symptom_has_case_been_in_isolation__c,
                        If_Yes_Specify_Setting__c,
                        If_Yes_Specify_Setting_48h__c,
                        If_Yes_Choose_destination__c,
                        If_Overseas_Specify_Country__c,
                        Related_to_an_outbreak__c,
                        Outbreak_record__c,
                        Investigation_Outbreak_PHESS_ID__c,
                        Outbreak_setting_type__c,
                        Relationship_to_outbreak__c,
                        Other_Relationship_Details__c,
                        Case_have_the_COVID_Safe_app__c,
                        Total_Number_of_Contacts_Identified__c,
                        COVIDsafe_app__c,
                        Case_in_a_high_rist_occupation__c,
                        if_Yes_Exclusion_discussed_with_case__c,
                        Date_exclusion_letter_sent_by_DHHS__c,
                        Date_of_exclusion_discussed__c,
                        If_Yes_Infection_control_guidelines_sen__c,
                        Date_on_infection_control_guideline_sent__c,
                        Part_of_Cluster_or_outbreak__c,
                        If_Yes_PHESS_Exposure_site_ID__c,
                        Voluntary_home_quarantine_commenced__c,
                        If_yes_Commenced_on__c,
                        Notify_doctor_hospital_if_symptom_worsen__c,
                        If_Yes_informed_on__c,
                        All_close_contacts_contacted__c,
                        All_close_contacts_identified__c,
                        Public_exposure_sites_identified__c,
                        Public_exposure_sites_documented__c,
                        Has_a_PPE_request_been_lodged__c,
                        PPE_request_lodged_on__c,
                        Has_a_relief_accom_request_been_lodged__c,
                        Relief_accom_lodged_on__c,
                        Public_health_actions_completed__c,
                        Other_actions__c,
                        Are_you_currently_working_from_home__c,
                        Are_you_currently_taking_leave__c,
                        Receive_financial_assistance__c,
                        Receive_any_other_form_of_income__c,
                        Preventing_transmission_of_COVID_19_disc__c,
                        If_yes_Date_discussed__c,
                        Case_provided_with_factsheet__c,
                        Fact_sheet_sent_on__c,
                        Information_sent__c,
                        Privacy_information_requested_by_case__c,
                        Privacy_information_sent_on__c,
                        Directed_to_website_for_further_info__c,
                        Website_information_sent_on__c,
                        Account.LastName,
                        Account.FirstName,
                        Account.PersonBirthdate,
                        Account.HealthCloudGA__Age__pc,
                        Account.Sex__c,
                        Account.HealthCloudGA__Gender__pc,
                        Account.PersonMailingStreet,
                        Account.PersonMailingCity,
                        Account.PersonMailingState,
                        Account.PersonMailingPostalCode,
                        Account.PersonMailingCountry,
                        Account.PersonOtherStreet,
                        Account.PersonOtherCity,
                        Account.PersonOtherState,
                        Account.PersonOtherPostalCode,
                        Account.PersonOtherCountry,
                        Account.PersonHomePhone,
                        Account.PersonMobilePhone,
                        Account.PersonEmail,
                        Account.Name_of_Parent__c,
                        Account.Aboriginal_or_Torres_Strait_Islander__c,
                        Account.Country_of_birth__c,
                        Account.year_arrived_in_Australia__c,
                        Account.Language_spoken_at_home__c,
                        Account.Alive_deceased__c,
                        Account.Date_of_Death__c,
                        Account.Cause_of_death__c,
                        Where_is_the_case_currently__c,
                        Hotel_detention_date_commenced__c,
                        Hotel_Address__c,
                        Clearance_criteria_for_this_case__c,
                (SELECT ID,
                        Person_Interviewed__c,
                        Person_Interviewed_Detail__c,
                        Case_Interview_Completed__c,
                        Consent_Given__c,
                        Interviewed_By__c,
                        Date_of_Interview__c
                 FROM WorkOrders),
                (SELECT ID,
                        Name,
                        HealthCloudGA__OnsetOfSymptoms__c,
                        Did_person_have_symptoms__c,
                        Acute_respiratory_distress_syndrome_ARD__c,
                        Cough__c,
                        Diarrhoea__c,
                        Fever__c,
                        HealthCloudGA__FeverOverThreshold__c,
                        Measured_temp_or_self_reported_fever__c,
                        HealthCloudGA__SubjectiveFever__c,
                        Pneumonia__c,
                        Pneumonia_diagnosed_by__c,
                        Pneumonitis__c,
                        Shortness_of_breath__c,
                        Sore_throat__c,
                        Other_symptoms__c,
                        HealthCloudGA__OtherSymptoms__c,
                        Clinical_Notes__c,
                        X1st_active_result_s_specimen_collectio__c,
                        Received_oxygen_therapy__c,
                        Intubated__c,
                        Received_ECMO__c,
                        Chronic_Respiratory_Conditions__c,
                        Cardiovascular_Disease__c,
                        Diabetes_mellitus_Type1__c,
                        Diabetesmellitus_Type2__c,
                        Immunosuppression__c,
                        Immunosuppressive_therapy__c,
                        Haemoglobinopathies__c,
                        NeurologicalDisability__c,
                        Renal_Failure__c,
                        Morbid_obesity__c,
                        Metabolic_diseases__c,
                        Pregnancy__c,
                        No_Conditions_Identified__c,
                        Specify_other_symptoms__c,
                        Other_Conditions__c,
                        Specify_other_conditions__c,
                        Temperature__c,
                        HealthCloudGA__OtherChronicDiseases__c,
                        HealthCloudGA__OtherChronicDiseasesNotes__c
                FROM Clinical_Assessment_Responses__r WHERE LastModifiedDate >:RecordExtractLastRun),
                (SELECT ID,
                        NAME,
                        Presented_to__c,
                        Admitted_to_Hospital__c,
                        Presented_due_to_2019__c,
                        StartDate__c,
                        End_Date__c,
                        Discharge_Status__c,
                        Discharged_deceased__c,
                        Deceased_date__c,
                        Admitted_to_ICU__c,
                        Was_case_isolated_on_arrival__c,
                        Were_they_ventilated__c,
                        UR_number__c,
                        Doctor_Name_c__c,
                        HealthCloudGA__Account__r.Name,
                        HealthCloudGA__Account__r.Site,
                        HealthCloudGA__Account__r.ShippingStreet,
                        HealthCloudGA__Account__r.ShippingCity,
                        HealthCloudGA__Account__r.ShippingState,
                        HealthCloudGA__Account__r.ShippingCountry,
                        HealthCloudGA__Account__r.ShippingPostalCode,
                        HealthCloudGA__Account__r.Phone,
                        HealthCloudGA__Account__r.Sic,
                        HealthCloudGA__Account__r.Email_work__c,
                        HealthCloudGA__Account__r.Fax,
                        Infection_Control_Notified__c,
                        ICC_Notified_On__c,
                        ICC_Notified_Name__c,
                        ICC_Notified_Phone__c,
                        Notes__c
                FROM EHR_Encounters__r
                WHERE HealthCloudGA__Account__r.LastModifiedDate >:RecordExtractLastRun
                OR LastModifiedDate >:RecordExtractLastRun),
                (SELECT ID,
                        NAME,
                        Classification__c,
                        Classification_Date__c
                FROM ClassificationHistory__r WHERE LastModifiedDate >:RecordExtractLastRun),
                (SELECT ID,
                        NAME,
                        StartTime,
                        RecordType.Name,
                        RecordType.DeveloperName,
                        EncounterDuration,
                        Duration__c,
                        Employment_Status__c,
                        Contact_Person__r.Name,
                        Location__r.Address__c,
                        Location__r.City__c,
                        Location__r.State_Territory__c,
                        Location__r.Postal_Code__c,
                        Location__r.Country__c,
                        End_Time__c,
                        Type__c,
                        Normal_Hours_of_Attendance__c,
                        Location__r.Name,
                        Location__r.VisitorAddress.Street,
                        Location__r.County__c,
                        Location__r.VisitorAddress.City,
                        Location__r.VisitorAddress.State,
                        Location__r.VisitorAddress.Country,
                        Location__r.VisitorAddress.PostalCode,
                        Description
                FROM Contact_Encounters__r
                WHERE Location__r.LastModifiedDate >:RecordExtractLastRun
                OR LastModifiedDate >:RecordExtractLastRun)
                FROM CASE WHERE ID =: caseId];

        closedCEPs = [
                SELECT ID,
                Location__r.VisitorAddress.Country,
                (SELECT ID,
                        NAME,
                        Contact_Type__c,
                        StartTime,
                        EncounterDuration,
                        DateofEncounter__c,
                        Age,
                        Relationship_to_Case__c,
                        Close_Contact_Record__r.Account.Name,
                        Close_Contact_Record__r.Account.PersonMobilePhone,
                        Close_Contact_Record__r.Account.ShippingStreet,
                        Close_Contact_Record__r.Account.ShippingCity,
                        Close_Contact_Record__r.Account.ShippingState,
                        Close_Contact_Record__r.Account.ShippingPostalCode,
                        Close_Contact_Record__r.Account.ShippingCountry,
                        Close_Contact_Record__r.Account.PersonMailingStreet,
                        Close_Contact_Record__r.Account.PersonMailingCity,
                        Close_Contact_Record__r.Account.PersonMailingState,
                        Close_Contact_Record__r.Account.PersonMailingPostalCode,
                        Close_Contact_Record__r.Account.PersonMailingCountry,
                        Close_Contact_Record__r.Account.PersonOtherStreet,
                        Close_Contact_Record__r.Account.PersonOtherCity,
                        Close_Contact_Record__r.Account.PersonOtherState,
                        Close_Contact_Record__r.Account.PersonOtherPostalCode,
                        Close_Contact_Record__r.Account.PersonOtherCountry,
                        Close_Contact_Record__r.Account.PersonEmail,
                        Close_Contact_Record__r.Account.Email_work__c,
                        Close_Contact_Record__r.CaseNumber,
                        Close_Contact_Record__r.PHESS_ID__c
                    FROM ContactEncounterParticipants
                    WHERE Contact_Type__c = 'Close contact'
                    AND(Close_Contact_Record__r.LastModifiedDate >:RecordExtractLastRun
                    OR Close_Contact_Record__r.Account.LastModifiedDate >:RecordExtractLastRun
                    OR LastModifiedDate >:RecordExtractLastRun))
        FROM ContactEncounter
        WHERE RecordType.DeveloperName = 'Close_Contact'
        AND Record__c =: caseId
        ];


        confirmedCEPs = [
                SELECT ID,
                (SELECT
                        NAME,
                        Contact_Type__c,
                        ContactEncounter.Location__r.VisitorAddress.Country,
                        StartTime,
                        EncounterDuration,
                        DateofEncounter__c,
                        Age,
                        Relationship_to_Case__c,
                        Confirmed_Case_Record__r.Account.Name,
                        Confirmed_Case_Record__r.Account.PersonMobilePhone,
                        Confirmed_Case_Record__r.Account.ShippingStreet,
                        Confirmed_Case_Record__r.Account.ShippingCity,
                        Confirmed_Case_Record__r.Account.ShippingState,
                        Confirmed_Case_Record__r.Account.ShippingCountry,
                        Confirmed_Case_Record__r.Account.ShippingPostalCode,
                        Confirmed_Case_Record__r.Account.PersonMailingStreet,
                        Confirmed_Case_Record__r.Account.PersonMailingCity,
                        Confirmed_Case_Record__r.Account.PersonMailingState,
                        Confirmed_Case_Record__r.Account.PersonMailingPostalCode,
                        Confirmed_Case_Record__r.Account.PersonMailingCountry,
                        Confirmed_Case_Record__r.Account.PersonOtherStreet,
                        Confirmed_Case_Record__r.Account.PersonOtherCity,
                        Confirmed_Case_Record__r.Account.PersonOtherState,
                        Confirmed_Case_Record__r.Account.PersonOtherPostalCode,
                        Confirmed_Case_Record__r.Account.PersonOtherCountry,
                        Confirmed_Case_Record__r.Account.PersonEmail,
                        Confirmed_Case_Record__r.Account.Email_work__c,
                        Confirmed_Case_Record__r.CaseNumber,
                        Confirmed_Case_Record__r.PHESS_ID__c
                    FROM ContactEncounterParticipants
                    WHERE Contact_Type__c = 'Known positive contact'
                    AND( ContactEncounter.Location__r.LastModifiedDate >:RecordExtractLastRun
                    OR Confirmed_Case_Record__r.LastModifiedDate >:RecordExtractLastRun
                    OR Confirmed_Case_Record__r.Account.LastModifiedDate >:RecordExtractLastRun
                    OR LastModifiedDate >:RecordExtractLastRun))
                FROM ContactEncounter
                WHERE RecordType.DeveloperName = 'Contact_with_Confirmed_Case'
                AND Record__c =: caseId
        ];


    }

    public Case Record
    {
        get
        {
            return this.CaseObj;
        }
    }
    public List<ContactEncounter> confirmedCEPRecords
    {
        get
        {
            return this.confirmedCEPs;
        }
    }
    public List<ContactEncounter> closedCEPRecords
    {
        get
        {
            return this.closedCEPs;
        }
    }
    public List<WorkOrder> WorkOrders
    {
        get
        {
            return this.CaseObj.WorkOrders;
        }
    }

    public Case DetailClearance
    {
        get
        {
            return this.CaseObj;
        }
    }
    
    public Case PrivacyStatement
    {
        get
        {
            return this.CaseObj;
        }
    }
    
    public Case Details
    {
        get
        {
            return this.CaseObj;
        }
    }
  
    public Case GeneralPresentation
    {
        get
        {
            return this.CaseObj;
        }
    }
    
    public Case EpidemiologicalRisks
    {
        get
        {
            return this.CaseObj;
        }
    }

    public Case OutbreakDetails
    {
        get
        {
            return this.CaseObj;
        }
    }
    
    public Case ContactsAndMovements
    {
        get
        {
            return this.CaseObj;
        }
    }
    
    public Case PublicHealthActions
    {
        get
        {
            return this.CaseObj;
        }
    }
    
    public Case FollowUpPayments
    {
        get
        {
            return this.CaseObj;
        }
    }
    
    public Case FollowUpEducation
    {
        get
        {
            return this.CaseObj;
        }
    }
    
     public Case Demographics
     {
        get
        {
            return this.CaseObj;
        }
    }
    
    public boolean hasContactEncounters
    {
        get
        {
            return ContactEncounters.size() > 0;
        }
    } 
    public List<ContactEncounter> ContactEncounters
    {

        get
        {
            List<ContactEncounter> result = new List<ContactEncounter>();
            for(ContactEncounter ce : CaseObj.Contact_Encounters__r)
                if(ce.RecordType.DeveloperName == 'Work_Study_Care')
                    result.add(ce);
            return result;
        }
    }
    
    public boolean hasClinicalAssesmentResponses
    {
        get
        {
            return ClinicalAssesmentResponses.size() > 0;
        }
    } 
    public List<HealthCloudGA__Clinical_Assessment_Response__c> ClinicalAssesmentResponses
    {
        get
        {
          
            return this.CaseObj.Clinical_Assessment_Responses__r;
        }
    }
    
    public boolean hasEHREncouters
    {
        get
        {
            return EHREncouters.size() > 0;
        }
    } 
    public List<HealthCloudGA__EhrEncounter__c> EHREncouters
    {

        get
        {
          
            return this.CaseObj.EHR_Encounters__r ;
        }
    }  

    public boolean hasCaseMovements
    {
        get
        {
            return CaseMovements.size() > 0;
        }
    }   
    public List<ContactEncounter> CaseMovements
    {
        get
        {
            List<ContactEncounter> result = new List<ContactEncounter>();
            for(ContactEncounter ce : CaseObj.Contact_Encounters__r)
                if(ce.RecordType.DeveloperName == 'Movement')
                    result.add(ce);
            return result;
        }
    }
    
    public boolean hasContactsWithConfirmedCases
    {
        get
        {
            return this.confirmedCEPs.size() > 0;
        }
    }
    public List<ContactEncounter> ContactsWithConfirmedCases
    {

        get
        {
          
            return this.confirmedCEPs;
        }
    }  
    
    public boolean hasCloseContacts
    {
        get
        {
            return this.closedCEPs.size() > 0;
        }
    }
    public List<ContactEncounter> CloseContacts
    {
        get
        {
          
            return this.closedCEPs;
        }
    }  
}