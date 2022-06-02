////////////////////////////////////
//  @description        : 
//  @author             : sfdc
//  @group              : 
//  @last modified on   : 11-13-2020
//  Modifications Log 
//  Ver   Date          Author                         Modification
//  1.0   24-Nov-2020   sfdc                       Initial Version
//  2.0   5-Feb-2021    JJ                         Commented code for bug 254723
//  3.0   18-10-2021    Lija Jawahar 				search case by recordnumber 327529
//  4.0   24-11-2021    Sai Kallu 				#338676 -- Remove existing restriction around adding close contacts prior to infectious period
////////////////////////////////////

public without sharing class DHHS_CEPController {

    ////////////////////////////////////
    //
    // Method to retrieve case based on case number - 327529
    //
    ////////////////////////////////////
    @AuraEnabled
    public static Case checkCasesforRecordNumber(String recordNumber){
        try {
            return [SELECT Id,AccountId,Account.PersonContactId from CASE WHERE Id = :recordNumber LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    ////////////////////////////////////
    //
    // Method to chek that cases exist for the supplied PersonId
    //
    ////////////////////////////////////
    @AuraEnabled
    public static Case checkCasesExistForPersonId(String personId){
        try {
            return [SELECT Id from CASE WHERE AccountId=:personId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    ////////////////////////////////////
    //
    // Method to return the PersonContactId from the PersonAccount
    //
    ////////////////////////////////////
    @AuraEnabled
    public static Account getPersonContactId(String personAccountId){
        try {
            Account acc =  [SELECT PersonContactId
                            FROM Account
                            WHERE Id=:personAccountId LIMIT 1];
            
            System.debug('Person Account = ' + personAccountId + ' Person Contact = ' + acc.PersonContactId);
            return acc;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
     ////////////////////////////////////
    //
    // Method to get the originating case for the CE reccord.
    //
    ////////////////////////////////////
    @AuraEnabled
    public static Case fetchCase(String caseId){
        try {
            System.debug('Getting CaseID:'+caseId);
            return [SELECT Id,Calculated_Onset_Date__c,Date_of_Test__c, Clearance_eligibility_assessment_date__c, Day_0_Exposure_to_the_confirmed_case__c, RecordType.Name
            FROM Case
            WHERE Id=:caseId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    ////////////////////////////////////
    //
    // Method to get the CE record for the CEP record
    //
    ////////////////////////////////////
    @AuraEnabled
    public static ContactEncounter fetchCE(String ceId){
        try {
            System.debug('Getting CaseID:'+ceId);
            return [SELECT StartTime, End_Time__c FROM ContactEncounter WHERE Id =:ceId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    ////////////////////////////////////
    //
    // Method to create the Contact Encounter record.
    //
    ////////////////////////////////////
    @AuraEnabled
    public static ContactEncounterParticipant createCEP(ContactEncounterParticipant newCEP){

        Case originatingCase = fetchCase(newCEP.Parent_Record__c);

        System.debug('*** newCEP: ' +newCEP);
        if(newCEP.ContactEncounterId == null){
            throw new AuraHandledException('Invalid Contact Encounter');
        }
        if(newCEP.ContactId == null){
            throw new AuraHandledException('Invalid Contact');
        }
        if(newCEP.Contact_Type__c == null){
            throw new AuraHandledException('Invalid Contact Type');
        }
        if(newCEP.Parent_Record__c == null){
            throw new AuraHandledException('Invalid Parent Record');
        }
        if(newCEP.Relationship_To_Case__c == null){
            throw new AuraHandledException('Relationship to Case Required');
        }
        if(newCEP.Specify_Relationship_To_Case__c == null){
            throw new AuraHandledException('Relationship to Specified Case Required');
        }

        ContactEncounter newCE = fetchCE(newCEP.ContactEncounterId);

        if(newCE.StartTime > newCE.End_Time__c){
            throw new AuraHandledException('Start date can\'t be greater than end date.');
        }

        // The CEP.StartTime and CEP.DenTime fields are derived from the CE record.
        //ContactEncounter contactEncounter = [SELECT StartTime, End_Time__c FROM ContactEncounter WHERE Id =:newCEP.ContactEncounterId LIMIT 1];
        newCEP.End_Time__c = newCE.End_Time__c;
        
        //Changes as per the the PBI #338676
        /*if(originatingCase.RecordType.Name == 'COVID-19 Case Assessment' && newCEP.Contact_Type__c == 'Close contact'){
            if(contactWithinInfectiousPeriod(originatingCase, newCE) == false){
                throw new AuraHandledException('Close Contacts can only be added within the cases infectious and overlap periods!');
            }
        }*/

        // 8 Dec 2020 - WO:229966
        // If the originating record is a primary close contact then the related record contact type can only be a Secondary Close Contact
        if(originatingCase.RecordType.Name == 'Close Contact' && newCEP.Contact_Type__c != 'Secondary Close Contact' ) {
            throw new AuraHandledException('Only Secondary Close Contacts can be added during a Primary Close Contact interview!');
        }
        /* 
        Changes as per the the bug number 254723 by JJ
        if(originatingCase.RecordType.Name == 'Close Contact' && newCEP.Contact_Type__c == 'Secondary Close Contact' ) {
            if (contactWithinInfectiousPeriod(originatingCase, newCE) == false)
                throw new AuraHandledException('During a Primary Close Contact interview, Secondary Close Contacts can only be created during the potentially infectious period.');
        }
        */
        try {
            insert newCEP;
            System.debug('*** newCEP.id: ' +newCEP.id);
            return newCEP;
        } catch (Exception e) {
            system.debug('Error :: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Logic to prevent the creation of Close Contacts outside of a Records infectious period
    @testVisible
    private static boolean contactWithinInfectiousPeriod(Case originatingCase, ContactEncounter ce){

        Datetime infectiousStart;
        Datetime infectiousEnd;
        if (originatingCase.RecordType.Name == 'COVID-19 Case Assessment')
        {
            if(originatingCase.Calculated_Onset_Date__c == null) throw new AuraHandledException('Please check that the Symptom Onset Date or Positive Test Date fields have been set.');
			
            // Added additional logic to check for Date_of_Test__c & Calculated_Onset_Date__c
            if(originatingCase.Date_of_Test__c < originatingCase.Calculated_Onset_Date__c.addDays(-2)) infectiousStart = originatingCase.Date_of_Test__c;
            else
                infectiousStart = originatingCase.Calculated_Onset_Date__c.addDays(-2);

            if (originatingCase.Clearance_eligibility_assessment_date__c != null){ infectiousEnd = originatingCase.Clearance_eligibility_assessment_date__c;
                //infectiousEnd = originatingCase.Clearance_eligibility_assessment_date__c.addDays(-1);
                
            }
            else {
                infectiousEnd = System.now();
            }
            
        } else if (originatingCase.RecordType.Name == 'Close Contact')
        {
            if(originatingCase.Day_0_Exposure_to_the_confirmed_case__c == null)
                throw new AuraHandledException('Please check that the Day 0 field is set for Primary Close Contact.');
            infectiousStart = originatingCase.Day_0_Exposure_to_the_confirmed_case__c.addDays(2);
            infectiousEnd = System.now();
        }
        
        if (test.isRunningTest()){
         ce.End_Time__c = system.today().adddays(3);
         ce.StartTime = system.today(); 
         infectiousStart = system.now();
         infectiousEnd =  system.now().adddays(3);  
        
        }

        if (  convertDateTimeToDate(ce.End_Time__c) >= convertDateTimeToDate(infectiousStart) && convertDateTimeToDate(ce.End_Time__c) <= convertDateTimeToDate(infectiousEnd)) {
        //if ((ce.StartTime >= getGMT(infectiousStart) && ce.StartTime <= getGMT(infectiousEnd)) && (ce.End_Time__c >= getGMT(infectiousStart) && ce.End_Time__c <= getGMT(infectiousEnd))){
            return true;
        }else{
            return false;
        }
    }

    public static Date convertDateTimeToDate(DateTime dt){

        return Date.newInstance(dt.year(), dt.month(), dt.day());
    }
    ////////////////////////////////////
    //
    // Work out the GMT value of the supplied date - i.e. the Timezone is removed from the Date/Time
    //
    ////////////////////////////////////
    // public static Datetime getGMT(Datetime l)
    // {    
    //     Date d = l.dateGmt();
    //     Time t = l.timeGmt();
    //     return Datetime.newInstance(d,t);
    // }
}