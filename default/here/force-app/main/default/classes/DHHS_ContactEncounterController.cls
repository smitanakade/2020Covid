/**
 * @description       : 
 * @author            : haider.raza@dhhs.vic.gov.au
 * @group             : 
 * @last modified on  : 11-13-2020
 * @last modified by  : haider.raza@pentasoft.com.au
 * Modifications Log 
 * Ver   Date         Author                         Modification
 * 1.0   11-10-2020   haider.raza@dhhs.vic.gov.au   Initial Version
 * 2.0   06-12-2021   Sukumar Salla                 Bug# 340866: UAT - Sprint 16 - PBI332971 - Linked Exposure Site field should populate when adding via Long form
**/
public with sharing class DHHS_ContactEncounterController {       

    @AuraEnabled
    public static Case fetchCase(String caseId){
        try {
            System.debug('Getting CaseID:'+caseId);
            return [SELECT Id,Calculated_Onset_Date__c,Clearance_eligibility_assessment_date__c, Day_0_Exposure_to_the_confirmed_case__c, First_date_of_exposure_to_positive_case__c, RecordType.Name
            FROM Case
            WHERE Id=:caseId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getCaseIdByRecordId(String recordId){
    if(recordId.startsWith('500')){
        return recordId;
    }
        WorkOrder worder = [SELECT CaseId from WorkOrder Where Id =:recordId];
        return worder.CaseId;
    }

    @AuraEnabled
    public static ContactEncounter createDirectContactEncounter(ContactEncounter contactEnc){

        contactEnc.EstimatedParticipantCount= 1;
        System.debug('$$$$$' +contactEnc);

        if(contactEnc.LocationId==null){
            throw new AuraHandledException('Invalid Location');
        }
        contactEnc.Location__c = contactEnc.LocationId;
        //Validation on EndDate> StartDate
        if(contactEnc.StartTime > contactEnc.End_Time__c){
            throw new AuraHandledException('Start date can\'t be greater than end date');
        }

        Case aCase = DHHS_ContactEncounterController.fetchCase(contactEnc.Record__c);

        //String tmpStr = aCase.Calculated_Onset_Date__c;
        //DateTime onsetDateTimeTz = aCase.Calculated_Onset_Date__c;
        //DateTime onsetDateTimeTzAdjusted = getGMT(onsetDateTimeTz);

        System.debug('*** aCase:' +aCase);

        if(aCase.RecordType.Name == 'COVID-19 Case Assessment' && aCase.Calculated_Onset_Date__c == null){
            throw new AuraHandledException('Symptom Onset Date is required when creating a movement for a Confirmed Case.');
        }

        // System.Debug('*** contactEnc.StartTime :'+contactEnc.StartTime );
        // System.Debug('*** contactEnc.End_Time__c :'+contactEnc.End_Time__c );
        // System.debug('*** aCase.Calculated_Onset_Date__c:'+aCase.Calculated_Onset_Date__c);
        // System.debug('*** getGMT(aCase.Calculated_Onset_Date__c):'+getGMT(aCase.Calculated_Onset_Date__c));
        // System.debug('*** getGMT(aCase.Calculated_Onset_Date__c.addDays(-14):'+getGMT(aCase.Calculated_Onset_Date__c.addDays(-14)));
        // System.debug( Datetime.newInstance(aCase.Calculated_Onset_Date__c.year(), aCase.Calculated_Onset_Date__c.month(), aCase.Calculated_Onset_Date__c.day()).format('yyyy-MM-dd') );

    
        // this code has issues because some of the dates we use for Calculated Onset have a time and some do not.
        // System.Debug('***1 StartTime in GMT is: '+ contactEnc.StartTime + ' Acquisition in GMT is: ' +getGMT(aCase.Calculated_Onset_Date__c.addDays(-14)) );
        // if(contactEnc.StartTime < getGMT(aCase.Calculated_Onset_Date__c.addDays(-14)) && aCase.RecordType.Name == 'COVID-19 Case Assessment'){
        //     System.Debug('***2 StartTime in GMT is: '+ contactEnc.StartTime + ' Acquisition in GMT is: ' +getGMT(aCase.Calculated_Onset_Date__c.addDays(-14)) );
        //     throw new AuraHandledException('Start date can\'t be before acquisition period!');
        // }

        // ONLY do this if we need to set the time of the Calculated Onset Date Time to 00:00AM.
        // Date newCalcOnsetDate = Date.newInstance(aCase.Calculated_Onset_Date__c.year(),aCase.Calculated_Onset_Date__c.month(),aCase.Calculated_Onset_Date__c.day());
        // Datetime newCalcOnsetDateTime = Datetime.newInstance(newCalcOnsetDate,Time.newInstance(0,0,0,0));
        // System.debug('*** newCalcOnsetDateTime:'+newCalcOnsetDateTime);
        // DateTime acquisitionStartDateTime = newCalcOnsetDateTime.addDays(-14);
        // System.Debug('***1 StartTime in GMT is: '+ contactEnc.StartTime + ' acquisitionStartDateTime: ' +acquisitionStartDateTime );
        // DateTime acquisitionStartDateTimeGMT = getGMT(acquisitionStartDateTime);
        // System.Debug('***1 StartTime in GMT is: '+ contactEnc.StartTime + ' acquisitionStartDateTimeGMT: ' +acquisitionStartDateTimeGMT );

        // // change this to only check the dates and where the end time < acquisitionStartDate (no time)

        // if(contactEnc.StartTime < acquisitionStartDateTimeGMT && aCase.RecordType.Name == 'COVID-19 Case Assessment'){
        //     System.Debug('***2 StartTime in GMT is: '+ contactEnc.StartTime + ' Acquisition in GMT is: ' + acquisitionStartDateTimeGMT );
        //     throw new AuraHandledException('Start date can\'t be before acquisition period!');
        // }

        // if(contactEnc.StartTime < getGMT(newCalcOnsetDateTime.addDays(-14)) && aCase.RecordType.Name == 'COVID-19 Case Assessment'){
        //     System.Debug('***2 StartTime in GMT is: '+ contactEnc.StartTime + ' Acquisition in GMT is: ' +getGMT(newCalcOnsetDateTime.addDays(-14)) );
        //     throw new AuraHandledException('Start date can\'t be before acquisition period!');
        // }

        // This seems to work for Calc onset date has time and no time....
        System.Debug('*** contactEnc.End_Time:'+contactEnc.End_Time__c);
        System.Debug('*** contactEnc.End_Time.date():'+contactEnc.End_Time__c.date());
        System.Debug('*** aCase.Calculated_Onset_Date__c:'+aCase.Calculated_Onset_Date__c);
        System.Debug('*** aCase.Calculated_Onset_Date__c.addDays(-14):'+aCase.Calculated_Onset_Date__c.addDays(-14));
        System.Debug('*** aCase.Calculated_Onset_Date__c.addDays(-14).dateGMT():'+aCase.Calculated_Onset_Date__c.addDays(-14).dateGMT());
        //Changes as per the bugfix 254723, inorder to save the case movement reagrdless of what date it is
        if (aCase.RecordType.Name != 'Close Contact'){
            if (contactEnc.End_Time__c.date() < aCase.Calculated_Onset_Date__c.addDays(-14).dateGMT()) {
                System.Debug('*** contactEnc.End_Time.date(): '+ contactEnc.End_Time__c.date() + ' aCase.Calculated_Onset_Date__c.addDays(-14).dateGMT() ' +aCase.Calculated_Onset_Date__c.addDays(-14).dateGMT() );
                throw new AuraHandledException('End date can\'t be before acquisition period!');
            }   
        }

        Datetime infectiousEnd;
        if (aCase.Clearance_eligibility_assessment_date__c != null)
            infectiousEnd = aCase.Clearance_eligibility_assessment_date__c;
        else
            infectiousEnd = System.Today();
        
        //System.Debug('*** getGMT(infectiousEnd):'+getGMT(infectiousEnd));

        //if(contactEnc.End_Time__c > infectiousEnd && aCase.RecordType.Name == 'COVID-19 Case Assessment'){
        System.Debug('*********** START ************ Check End Date is within infectious period...');
        System.Debug('*** contactEnc.End_Time__c:'+contactEnc.End_Time__c);
        System.Debug('*** contactEnc.End_Time.date():'+contactEnc.End_Time__c.date());
        System.Debug('*** aCase.Clearance_eligibility_assessment_date__c :'+ aCase.Clearance_eligibility_assessment_date__c );
        System.Debug('*** System.Today():'+System.Today());
        System.Debug('*** infectiousEnd:'+infectiousEnd);
        System.Debug('*** infectiousEnd.dateGMT():'+infectiousEnd.dateGMT());
        System.Debug('*********** END ************ Check End Date is within infectious period...');
        if(contactEnc.End_Time__c.date() > infectiousEnd.dateGMT() && aCase.RecordType.Name == 'COVID-19 Case Assessment'){
            throw new AuraHandledException('End date can\'t be after the infectious period!');
        }
        

        Long timeDifferenceInMinutes = (contactEnc.End_Time__c.getTime() - contactEnc.StartTime.getTime())  /60000;

        if(aCase.RecordType.Name == 'Close Contact' && aCase.Day_0_Exposure_to_the_confirmed_case__c == null){
            throw new AuraHandledException('Day 0 is required when creating a movement for a Primary Close Contact.');
        }

        // 8 Dec 2020 WI: 229966
        //During a PCC interview, The Date/Time of the CE record should be >= [PCC's record Day 0: Exposure to the confirmed case] AND <= Today.
        System.Debug('*********** START ************ Check Start Date >= Day0 for PCC');
        System.Debug('*** contactEnc.End_Time__c.date():'+contactEnc.End_Time__c.date());
        System.Debug('*** aCase.Day_0_Exposure_to_the_confirmed_case__c :'+aCase.Day_0_Exposure_to_the_confirmed_case__c );
        System.Debug('*********** END ************ Check Start Date >= Day0 for PCC');
        //Changes as per the the bug number 254723
        //if (aCase.RecordType.Name == 'Close Contact' && contactEnc.End_Time__c.date() < aCase.Day_0_Exposure_to_the_confirmed_case__c )
        //   throw new AuraHandledException('End date must be >= Day 0 when interviewing a Primary Close Contact!');
        if (aCase.RecordType.Name == 'Close Contact' && contactEnc.End_Time__c.date() <= aCase.First_date_of_exposure_to_positive_case__c )
            throw new AuraHandledException('End date must be > First date of exposure when interviewing a Primary Close Contact!');

        

        // old approach
        // System.Debug('*** contactEnc.StartTime:'+contactEnc.StartTime);
        // System.Debug('*** aCase.Day_0_Exposure_to_the_confirmed_case__c:'+aCase.Day_0_Exposure_to_the_confirmed_case__c);
        // if (aCase.RecordType.Name == 'Close Contact' && contactEnc.StartTime < getGMT(aCase.Day_0_Exposure_to_the_confirmed_case__c))
        //     throw new AuraHandledException('Start date must be >= Day 0 when interviewing a Primary Close Contact!');
        System.Debug('*********** START ************ Check End Date <= Today PCC');
        System.Debug('*** contactEnc.End_Time__c.date():'+contactEnc.End_Time__c.date());
        System.Debug('*** System.Today():'+System.Today());
        System.Debug('*********** END ************ Check End Date <= Today PCC');
        if (aCase.RecordType.Name == 'Close Contact' && contactEnc.End_Time__c.date() > System.Today())
            throw new AuraHandledException('End date must be <= to today\'s date');
        


        try{
            contactEnc.RecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByName().get('Movement').getRecordTypeId();
            contactEnc.EncounterDuration = Integer.valueOf(timeDifferenceInMinutes);

            // Link Exposure management Record (#340866)
            Id exposureSiteRCTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Outbreak').getRecordTypeId();
            List<String> emrStatus = new List<String>{'New', 'Active', 'Inactive', 'Escalated'};
            List<Case> exposureSites = [Select Id FROM Case WHERE RecordTypeId =: exposureSiteRCTypeId AND Status IN: emrStatus AND LocationAddress__c =: contactEnc.LocationId Order By CreatedDate DESC LIMIT 1];
            contactEnc.Exposure_Site_Id__c = exposureSites.size()>0 ? exposureSites[0].Id: null;

            insert contactEnc;

            return contactEnc;
        }catch(Exception ex){
            throw new AuraHandledException('Insertion of Movement failed');
        }
    }

    //PBI# 332615 - Location mappings 
    @AuraEnabled
    public static map<string, string> fetchLocationsMappings(){
        try {
            map<string, string> mapLocationMappings = new map<string, string>();
            for(Locations_Mapping__mdt lm: [SELECT Id, MasterLabel, Encounter_Type__c, Location__c FROM Locations_Mapping__mdt]){
                mapLocationMappings.put(lm.Encounter_Type__c, lm.Location__c);
            }
            return !mapLocationMappings.isEmpty() ? mapLocationMappings : null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // public static Datetime getGMT(Datetime l)
    // {    
    //     Date d = l.dateGmt();
    //     Time t = l.timeGmt();
    //     return Datetime.newInstance(d,t);
    // }

    // public Date removeTimeFromDateTime(DateTime dateTimeIn)
    // {
    //     System.Debug('*** dateTimeIn:'+dateTimeIn);
    //     Date dateOnly = Date.newInstance(dateTimeIn.year(),dateTimeIn.month(),dateTimeIn.day());
    //     System.Debug('*** dateOnly:'+dateOnly);

    //     return dateOnly;
    // }



}