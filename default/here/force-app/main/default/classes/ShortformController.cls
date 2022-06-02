public with sharing class ShortformController {

     @AuraEnabled
    public static List<contactWrapper> getcontacts( Id workorderid) {
        List<contactWrapper> response = new List<contactWrapper>();
        System.debug('WWWWork Order ID'+ workorderid);
        workorder inscopeworkorder = [select id,accountId,caseid from workorder where id = :workorderid LIMIT 1];

        List<ContactEncounterParticipant> CEPS = [ SELECT Id, Record__c, Record__r.casenumber, Record__r.Subject,Record__r.Relationship_to_case__c,
                                                 Account__c, ContactId, Contact.name, Contact.FirstName, Contact.LastName, StartTime,
                                                 Account__r.PersonMobilePhone, Account__r.Name, Name, Age, Account__r.PersonMailingAddress, 
                                                 ContactEncounterId,Relationship_to_Case__c, ContactEncounter.Name FROM ContactEncounterParticipant where Parent_Record__c = : inscopeworkorder.caseid ];
        
        for(ContactEncounterParticipant CEP : CEPS){
          
            contactWrapper CW = New contactWrapper();
            CW.contactname = CEP.Contact.name;
            CW.contactFirstName = CEP.Contact.FirstName;
            CW.contactLastName = CEP.Contact.LastName;
            CW.contacturl = '/'+CEP.ContactId;
            CW.casenumber = CEP.Record__r.casenumber;
            CW.caseurl = '/'+CEP.Record__c;
            CW.caseSubject = CEP.Record__r.Subject;
            CW.phone = CEP.Account__r.PersonMobilePhone;
            if(CEP.Account__r.PersonMailingAddress != null){
             CW.accountaddress = CEP.Account__r.PersonMailingAddress.getStreet()+','+CEP.Account__r.PersonMailingAddress.getCity()+','+CEP.Account__r.PersonMailingAddress.getState()+','+CEP.Account__r.PersonMailingAddress.getPostalCode()+','+CEP.Account__r.PersonMailingAddress.getCountry();
            }else{
             CW.accountaddress = '';   
            }
            CW.relationship = CEP.Relationship_to_case__c;
            CW.cepId = CEP.Id;
            CW.cepName = CEP.Name;
            CW.cepAge = CEP.Age;
            CW.ceId = CEP.ContactEncounterId;
            CW.ceName = CEP.ContactEncounter.Name;
            CW.starttime = CEP.StartTime;
            response.add(CW);

        }

        return response;
     }

     @TestVisible
     private class contactWrapper {
        @AuraEnabled
        public string cepId {get;set;}
        @AuraEnabled
        public Integer cepAge {get;set;}
        @AuraEnabled
        public String ceId {get;set;}
        @AuraEnabled
        public String ceName {get;set;}
        @AuraEnabled
        public string contacturl {get;set;}
        @AuraEnabled
        public String contactname {get;set;}
        @AuraEnabled
        public String contactFirstName {get;set;}
        @AuraEnabled
        public String contactLastName {get;set;}
        @AuraEnabled
        public String caseurl {get;set;}
        @AuraEnabled
        public String casenumber {get;set;}
        @AuraEnabled
        public String caseSubject {get;set;}
        @AuraEnabled
        public String phone {get;set;}
        @AuraEnabled
        public string accountaddress {get;set;}
        @AuraEnabled
        public String relationship {get;set;}
        @AuraEnabled
        public String cepName {get;set;}
        @AuraEnabled
        public datetime starttime {get;set;}
    }
    
    
    @AuraEnabled
    public static string saveclosecontact(Id accountid, Id primaryrecordid,String selectedCaseId, date lastdayofexposure, string relationshiptocase, string specifyrelationshiptocase){
    try {

            system.debug(selectedCaseId);
            Case caseRec = new Case();
            if(String.isNotBlank(selectedCaseId)){
                caseRec =   [SELECT Id,Calculated_Onset_Date__c,Date_of_Test__c, Clearance_eligibility_assessment_date__c, 
                                    Day_0_Exposure_to_the_confirmed_case__c, RecordType.Name
                            FROM Case
                            WHERE Id=:selectedCaseId];
            } else { 
            
                /*
                A record of type 'Close Contact' is created with the values as specified in the edit screen as well as the following default values:
                Event Classification = At Risk
                Epi Classification = ​Epidemiologically linked to a confirmed case
                Case found by = ​Contact tracing
                Status = Identify
                Sub-Status = In Progress
                Account - accountid 
                */
                Case newCase = new Case();
                newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
                newCase.Case_Classification__c = 'At Risk';
                newCase.Epi_Classification__c = 'Epidemiologically linked to a laboratory confirmed case';
                newCase.Case_Found_By__c = 'Contact tracing';
                newCase.Status = 'Identify';
                newCase.SubStatus__c = 'In Progress';
                newCase.AccountId = accountid;
                newCase.Day_0_Exposure_to_the_confirmed_case__c = lastdayofexposure==null? System.today():lastdayofexposure;
                system.debug('Day_0_Exposure_to_the_confirmed_case__c --->' + newCase.Day_0_Exposure_to_the_confirmed_case__c);
                //newCase.On_going_exposure__c=ongoingexposure;
                insert newCase;

                caseRec = newCase;
            }

            // Create contact encounter 
            /*
            A Contact Encounter record is created with the following values:
                Type = Case Movement//formula field
                Encounter Type = Contact with confirmed case//cannot find the field
                Start Time = value of the 'Last day of Exposure Day 0' field// where is the 'Last day of Exposure Day 0'?
                Please update to todays date if no date provided above
                Location = blank
                record__c = primaryrecordid
            */
            ContactEncounter ce = new ContactEncounter();
            ce.RecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByName().get('Contact with Confirmed Case').getRecordTypeId();
            ce.StartTime = lastdayofexposure == null? System.now(): lastdayofexposure;
            system.debug('lastdayofexposure --->' + ce.StartTime);
            ce.Location = null;
            ce.record__c = primaryrecordid;
            ce.Name = 'case interview';
            insert ce;


            // Create Contact Encounter participant 
            /*
            A Contact Encounter Participant is created with the following values:
            Parent Record = [Record number of case] - primaryrecordid
            Record = [Record of close contact] - tempPCC
            Account = [Account of close contact] - accountid
            Contact Type = Close Contact
            Relationship to Case = [value entered into the edit screen for this field on the record] - relationshiptocase
            Specify relationship to case = [value entered into the edit screen for this field on the record] -specifyrelationshiptocase
            */
            ContactEncounterParticipant cep = new ContactEncounterParticipant();
            cep.Parent_Record__c = primaryrecordid;
            cep.Record__c = caseRec.Id;
            cep.ContactEncounterId = ce.Id;
            cep.Account__c = accountid;
            cep.Contact_Type__c = 'Close contact';
            cep.Relationship_to_Case__c = relationshiptocase;
            //cep.On_going_exposure__c = ongoingexposure;
            cep.Specify_relationship_to_case__c	 = specifyrelationshiptocase;
            
            insert cep;

            return 'success';
        } catch (Exception exp) {
            ApplicationLogUtility.createlog('ShortformController','saveclosecontact',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            return 'fail';
        }
    }
}