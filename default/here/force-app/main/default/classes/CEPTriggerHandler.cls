/*
Description: CEP Handler to cover scenarios for existing close contact, confirmed case and no close contact.
Triggered from CEP 
Date: 1/12/2020
Author: Amar Reddy

Handler updated to cover scenarios for secondary close contact.
Date: 2/12/2020
@Modification Log   : 
---------------------------------------------------
Date           Author               Details
---------------------------------------------------
03/02/2021     Darko Jovanovic       Feature 255889: Modified to use common trigger framework
06/04/2021     Jiten Joysar          Feature 270252: Added logic to handle household case records
17/09/2021	   Pratyush Chalasani	 Revert 270278: Removing code for case multiple alloccation
09/11/2021	   Sai Kallu             Feature 332083: Household Close Contact Day 0 set to Date of First Positive Test Date of linked Case - logic change
*/
public class CEPTriggerHandler extends TriggerHandler {    
    public override void beforeInsert() {
        CEPTriggerHandler.identifyCloseContacts(Trigger.new);
    }

    public override void afterUpdate(){
        CEPTriggerHandler.updateRelatedRecordsOnGoingExposureCheck(Trigger.new, (Map<Id, ContactEncounterParticipant>) Trigger.oldMap);
        CEPTriggerHandler.updateDay0CloseContacts(Trigger.new);
    }
    
    public override void afterInsert(){
        CEPTriggerHandler.updateDay0CloseContacts(Trigger.new);
    }

    /**
     * Updates the PCC/SCC with the On-going exposure check when the related CEP is updated
     */
    public static void updateRelatedRecordsOnGoingExposureCheck(List<ContactEncounterParticipant> newCEPs, Map<Id, ContactEncounterParticipant> oldCEPsById) {
        List<ContactEncounterParticipant> cepstoProcesss = new List<ContactEncounterParticipant>();
        List<Case> casesToUpdate = new List<Case>();

        try {
            for (ContactEncounterParticipant cep : newCEPs) {
                if ((cep.Contact_Type__c == 'Secondary Close Contact' || cep.Contact_Type__c == 'Close contact')
                        && ((!cep.On_going_exposure__c && oldCEPsById.get(cep.Id).On_going_exposure__c) || (cep.On_going_exposure__c && !oldCEPsById.get(cep.Id).On_going_exposure__c))) {
                    cepstoProcesss.add(cep);
                }
            }

            if (!cepstoProcesss.isEmpty()) {
                for (ContactEncounterParticipant cep : cepstoProcesss) {
                    casesToUpdate.add(new Case(Id = cep.Record__c, On_going_exposure__c = cep.On_going_exposure__c));
                }

                if (!casesToUpdate.isEmpty()) update casesToUpdate;
            }
        } catch (Exception e) { }

    }

    @testVisible
    private static void identifyCloseContacts(List<ContactEncounterParticipant> cepRecords) 
    {
        List<Case> closeContactsToBeInserted = new List<Case>();
        List<Case> closeContactsToBeUpdated = new List<Case>();        
        List<Case> confirmedCases = new List<Case>();
        String title; 
        String content;
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
        Id secondaryCloseContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
        Id acquisitionContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Acquisition_Contact').getRecordTypeId();
        Id casualContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Casual_Contact').getRecordTypeId();
        Id unclassifiedContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Unclassified_Contact').getRecordTypeId();
        Map<Id, String> caseIdRecordTypeName = new Map<Id, String>();
        Map<Id, Case> caseRecordMap = new Map<Id, Case>();
        Map<ContactEncounterParticipant, Case> cepClosecontact = new Map<ContactEncounterParticipant, Case>();
        
        // Added as part of PBI-270252
        List<Id> contactIds = new List<Id>();
        Map<Id, Contact> personAccountMap = new Map<Id, Contact>();
        
        for( ContactEncounterParticipant cepRecord : cepRecords )
        {        
            if(cepRecord.Record__c!=null)
            {
                caseIdRecordTypeName.put(cepRecord.Record__c, cepRecord.Record__c);       
            }
            
            if(cepRecord.Parent_Record__c!=null)
            {
                caseIdRecordTypeName.put(cepRecord.Parent_Record__c, cepRecord.Parent_Record__c);       
            }
            
            // Added as part of PBI-270252
            if(cepRecord.ContactId != null){
                contactIds.add(cepRecord.ContactId);
            }
            
        }
        
        // Added as part of PBI-270252
        for(Contact contactObj : [Select Id, AccountId, Account.Head_of_household__c, Account.Household_member__c from Contact where Id IN :contactIds]){
            personAccountMap.put(contactObj.Id, contactObj);
        }
        
        for( Case caseRecord : [Select CaseNumber,status, OwnerId, RecordType.DeveloperName, Day_0_Exposure_to_the_confirmed_case__c,First_date_of_exposure_to_positive_case__c,
                                Day_0_Exposure_to_primarycc__c,Primary_close_contact_Day_11_test__c,Initial_Interview_completed__c,Confirmation_Date__c,Related_case_confirmation_date__c,
                                Primary_close_contact_Day_14__c,On_going_exposure__c,Day_11_Test__c,Day14_Anticipated_last_day_of_quarantine__c,Day_15_Anticipated_release_date__c
                                from Case where Id =:caseIdRecordTypeName.keySet()] )
        {
            //caseIdRecordTypeName.put(caseRecord.Id, caseRecord.RecordType.DeveloperName); 
            caseRecordMap.put(caseRecord.Id, caseRecord);  
            System.debug('caseRecordMap in' + caseRecordMap);
        }
        
        System.debug('caseRecordMap ' + caseRecordMap);
        for( ContactEncounterParticipant cepRecord : cepRecords )
        {            
            if(cepRecord.Record__c == null)
            {   
                if(cepRecord.Contact_Type__c == 'Secondary Close Contact'){
                    //Secondary Close Contact
                    Case secCloseContact = new Case(); 
                    secCloseContact.Status = 'Identify'; 
                    secCloseContact.ContactId = cepRecord.ContactId;
                    
                    // Added new code for PBI - 270239
                    if(cepRecord.account__c != null){
                        secCloseContact.accountId = cepRecord.account__c;
                        
                    }else{
                        if(personAccountMap.containsKey(cepRecord.ContactId)){
                            secCloseContact.accountId = personAccountMap.get(cepRecord.ContactId).AccountId;
                        }
                    }
                    
                    secCloseContact.RecordTypeId = secondaryCloseContactRecordTypeId;
                    secCloseContact.On_going_exposure__c = cepRecord.On_going_exposure__c ;
                    //Populate Related Case COnfirmation Date and Status on Close Contact
                    

                    if(caseRecordMap.get(cepRecord.parent_record__c) != null && caseRecordMap.get(cepRecord.parent_record__c).RecordTypeId == closeContactRecordTypeId){

                        if(caseRecordMap.get(cepRecord.parent_record__c).Initial_Interview_completed__c){
                    	  secCloseContact.Day_0_Exposure_to_the_confirmed_case__c = caseRecordMap.get(cepRecord.parent_record__c).Day_0_Exposure_to_the_confirmed_case__c;
                    	  //secCloseContact.Day_0_Exposure_to_primarycc__c = caseRecordMap.get(cepRecord.parent_record__c).Day_0_Exposure_to_the_confirmed_case__c;
                    	 secCloseContact.Primary_close_contact_Day_11_test__c = caseRecordMap.get(cepRecord.parent_record__c).Day_11_Test__c;

                    	   secCloseContact.Primary_close_contact_Day_14__c = caseRecordMap.get(cepRecord.parent_record__c).Day14_Anticipated_last_day_of_quarantine__c;
                            secCloseContact.Status = 'Quarantine';
                    	  }
                         secCloseContact.Day_15_Anticipated_release_date__c = caseRecordMap.get(cepRecord.parent_record__c).Day_15_Anticipated_release_date__c;
                         secCloseContact.Day_0_Exposure_to_primarycc__c = cepRecord.End_Time__c!=null?cepRecord.End_Time__c.date():(cepRecord.StartTime!=null?cepRecord.StartTime.date():null);

                    }                  
                    // new code added for PBI - 270252
                    if(secCloseContact.Status == 'Identify' && cepRecord.parent_record__c != null && caseRecordMap.containsKey(cepRecord.parent_record__c) && 
                       caseRecordMap.get(cepRecord.parent_record__c).RecordType.DeveloperName == 'Close_Contact' && (cepRecord.Relationship_to_Case__c == 'Household' || (personAccountMap.containsKey(cepRecord.ContactId) && personAccountMap.get(cepRecord.ContactId).Account.Head_of_household__c) || (personAccountMap.containsKey(cepRecord.ContactId) && personAccountMap.get(cepRecord.ContactId).Account.Household_member__c))){
                           secCloseContact.OwnerId = caseRecordMap.get(cepRecord.parent_record__c).OwnerId;
                           secCloseContact.Is_case_allocation_completed__c = true;
                       }
                    //Test changes ends 
                    
                    //Reusing existing method for closeContacts to create Secondary Close Contacts and relate to CEP record
                    closeContactsToBeInserted.add(secCloseContact);
                    cepClosecontact.put(cepRecord, secCloseContact); 
                    
                }else if(cepRecord.Contact_Type__c == 'Close contact'){
                    //Close Contact 
                    Case closeContact = new Case(); 
                    closeContact.Status = 'Identify';                
                    closeContact.ContactId = cepRecord.ContactId;
                    
                    // Added new code for PBI - 270239
                    if(cepRecord.account__c != null){
                        closeContact.accountId = cepRecord.account__c;
                    }    
                    else{
                        if(personAccountMap.containsKey(cepRecord.ContactId)){
                            closeContact.accountId = personAccountMap.get(cepRecord.ContactId).AccountId;
                        }
                    }
                    
                    closeContact.RecordTypeId = closeContactRecordTypeId;
                    closeContact.Day_0_Exposure_to_the_confirmed_case__c = cepRecord.End_Time__c.date();
                    closeContact.First_date_of_exposure_to_positive_case__c = cepRecord.Start_Time__c.date(); //Defect 265444
                    closeContact.On_going_exposure__c = cepRecord.On_going_exposure__c ;

                    //Populate Related Case COnfirmation Date and Status on Close Contact
                    if(caseRecordMap.get(cepRecord.parent_record__c) != null && 
                       caseRecordMap.get(cepRecord.parent_record__c).RecordTypeId == confirmedCaseRecordTypeId && 
                       caseRecordMap.get(cepRecord.parent_record__c).Initial_Interview_completed__c){
                           closeContact.Related_case_confirmation_date__c = caseRecordMap.get(cepRecord.parent_record__c).Confirmation_Date__c;
                           closeContact.status = 'Quarantine';
                       }
                    
                    // new code added for PBI - 270252
                    if(closeContact.Status == 'Identify' && cepRecord.parent_record__c != null && caseRecordMap.containsKey(cepRecord.parent_record__c) && 
                       caseRecordMap.get(cepRecord.parent_record__c).RecordType.DeveloperName == 'COVID_19_Case_Assessment' && 
                       (cepRecord.Relationship_to_Case__c == 'Household' || (personAccountMap.containsKey(cepRecord.ContactId) && personAccountMap.get(cepRecord.ContactId).Account.Head_of_household__c) || (personAccountMap.containsKey(cepRecord.ContactId) && personAccountMap.get(cepRecord.ContactId).Account.Household_member__c))){
                           closeContact.OwnerId = caseRecordMap.get(cepRecord.parent_record__c).OwnerId;
                           closeContact.Is_case_allocation_completed__c = true;
                       }
                    //Test changes ends
                    
                    closeContactsToBeInserted.add(closeContact);
                    cepClosecontact.put(cepRecord, closeContact);
                }else if(cepRecord.Contact_Type__c == 'Acquisition Contact'){
                    //Acquisition Contact
                    Case acqCloseContact = new Case(); 
                    acqCloseContact.Status = 'Active';
                    acqCloseContact.Day_0_Exposure_to_the_confirmed_case__c = cepRecord.End_Time__c.date();
                    acqCloseContact.ContactId = cepRecord.ContactId;
                    
                    // Added new code for PBI - 270239
                    if(cepRecord.account__c != null){
                        acqCloseContact.accountId = cepRecord.account__c;
                        
                    }else{
                        if(personAccountMap.containsKey(cepRecord.ContactId)){
                            acqCloseContact.accountId = personAccountMap.get(cepRecord.ContactId).AccountId;
                        }
                    }
                    acqCloseContact.RecordTypeId = acquisitionContactRecordTypeId;
                    closeContactsToBeInserted.add(acqCloseContact);
                    cepClosecontact.put(cepRecord, acqCloseContact);
                }else if(cepRecord.Contact_Type__c == 'Casual Contact'){
                    //Casual Contact
                    Case casualCloseContact = new Case(); 
                    casualCloseContact.Status = 'Active';
                    casualCloseContact.Day_0_Exposure_to_the_confirmed_case__c = cepRecord.End_Time__c.date();
                    casualCloseContact.ContactId = cepRecord.ContactId;
                    
                    // Added new code for PBI - 270239
                    if(cepRecord.account__c != null){
                        casualCloseContact.accountId = cepRecord.account__c;
                        
                    }else{
                        if(personAccountMap.containsKey(cepRecord.ContactId)){
                            casualCloseContact.accountId = personAccountMap.get(cepRecord.ContactId).AccountId;
                        }
                    }
                    casualCloseContact.RecordTypeId = casualContactRecordTypeId;
                    closeContactsToBeInserted.add(casualCloseContact);
                    cepClosecontact.put(cepRecord, casualCloseContact);
                }else if(cepRecord.Contact_Type__c == 'Unclassified Contact'){
                    //Unclassified Contact
                    Case unclassCloseContact = new Case(); 
                    unclassCloseContact.Status = 'Active';
                    unclassCloseContact.Day_0_Exposure_to_the_confirmed_case__c = cepRecord.End_Time__c.date();
                    unclassCloseContact.ContactId = cepRecord.ContactId;
                    
                    // Added new code for PBI - 270239
                    if(cepRecord.account__c != null){
                        unclassCloseContact.accountId = cepRecord.account__c;
                        
                    }else{
                        if(personAccountMap.containsKey(cepRecord.ContactId)){
                            unclassCloseContact.accountId = personAccountMap.get(cepRecord.ContactId).AccountId;
                        }
                    }
                    unclassCloseContact.RecordTypeId = unclassifiedContactRecordTypeId;
                    closeContactsToBeInserted.add(unclassCloseContact);
                    cepClosecontact.put(cepRecord, unclassCloseContact);
                }    
            }           
            else if(cepRecord.Record__c != null)
            {
                Case existingCase = caseRecordMap.get(cepRecord.Record__c);
                Case parentCase = (cepRecord.Parent_Record__c != null ? caseRecordMap.get(cepRecord.Parent_Record__c) : null);
                
                if(cepRecord.Contact_Type__c == 'Secondary Close Contact' && existingCase.RecordType.DeveloperName == 'Secondary_Close_Contact'
                   && cepRecord.End_Time__c!=null && parentCase.Day_0_Exposure_to_the_confirmed_case__c!=null && 
                   cepRecord.End_Time__c > parentCase.Day_0_Exposure_to_the_confirmed_case__c && parentCase != null){
                       existingCase.Day_0_Exposure_to_the_confirmed_case__c = parentCase.Day_0_Exposure_to_the_confirmed_case__c;
                       // existingCase.Day_0_Exposure_to_primarycc__c = parentCase.Day_0_Exposure_to_primarycc__c;
                       existingCase.Day_0_Exposure_to_primarycc__c = cepRecord.End_Time__c.date();
                       existingCase.Primary_close_contact_Day_11_test__c = parentCase.Day_11_Test__c;
                       existingCase.Primary_close_contact_Day_14__c = parentCase.Day14_Anticipated_last_day_of_quarantine__c;
                       existingCase.On_going_exposure__c = (!existingCase.On_going_exposure__c) ? cepRecord.On_going_exposure__c : existingCase.On_going_exposure__c;
                       existingCase.Day_15_Anticipated_release_date__c = parentCase.Day_15_Anticipated_release_date__c;
                       
                       closeContactsToBeUpdated.add(existingCase);
                       //Update closeContactsToBeUpdated and Add a Note to them in the below steps
                   }
                else if(existingCase.RecordType.DeveloperName == 'Close_Contact' && cepRecord.End_Time__c!=null &&  existingCase.Day_0_Exposure_to_the_confirmed_case__c!=null && cepRecord.End_Time__c > existingCase.Day_0_Exposure_to_the_confirmed_case__c)
                {             
                    existingCase.Day_0_Exposure_to_the_confirmed_case__c= (cepRecord.End_Time__c).date();
                    existingCase.On_going_exposure__c = (!existingCase.On_going_exposure__c) ? cepRecord.On_going_exposure__c : existingCase.On_going_exposure__c;

                    closeContactsToBeUpdated.add(existingCase); 
                    //Update closeContactsToBeUpdated and Add a Note to them in the below steps
                }
                else if(existingCase.RecordType.DeveloperName == 'Close_Contact' && cepRecord.Start_Time__c!=null &&  existingCase.First_date_of_exposure_to_positive_case__c!=null && cepRecord.Start_Time__c < existingCase.First_date_of_exposure_to_positive_case__c)
                {                    
                    existingCase.First_date_of_exposure_to_positive_case__c= (cepRecord.Start_Time__c).date(); //Defect 265444
                    
                    closeContactsToBeUpdated.add(existingCase); 
                    //Update closeContactsToBeUpdated and Add a Note to them in the below steps
                }
                else if(existingCase.RecordType.DeveloperName == 'COVID_19_Case_Assessment' ) 
                {
                    confirmedCases.add(existingCase);                
                }
                
                //New changes starts
                if(existingCase.RecordType.DeveloperName == 'Close_Contact' && (parentCase != null) &&parentCase.Initial_Interview_completed__c==true){
                    System.debug('parentCase.Initial_Interview_completed__c .... ' + parentCase.Initial_Interview_completed__c);      
                    System.debug('parentCase.Confirmation_Date__c ' + parentCase.Confirmation_Date__c);
                    
                    existingCase.Related_case_confirmation_date__c = parentCase.Confirmation_Date__c;
                    existingCase.Status = 'Quarantine';
                    if(!closeContactsToBeUpdated.contains(existingCase)){
                        closeContactsToBeUpdated.add(existingCase); 
                    }    
                }else if(existingCase.RecordType.DeveloperName == 'Secondary_Close_Contact' && (parentCase != null) && parentCase.Initial_Interview_completed__c==true){
                    existingCase.Status = 'Quarantine';
                    if(!closeContactsToBeUpdated.contains(existingCase)){
                        closeContactsToBeUpdated.add(existingCase); 
                    } 
                }
                //New changes ends
                
                //erting contact -- Insert failed. First exception on row 0; first error: CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, CEPTrigger: execution of BeforeInsert caused by: System.SObjectException: SObject row was retrieved via SOQL without querying the requested field: Case.Status Class.CEPTriggerHandler.identifyCloseContacts: line 248, column 1 Class.CEPTriggerHandler.beforeInsert: line 19, column 1 Class.TriggerHandler.run: line 75, column 1 Trigger.CEPTrigger: line 14, column 1: []
                
                // new code added for PBI - 270252
                if(existingCase.Status == 'Identify' && cepRecord.parent_record__c != null && caseRecordMap.containsKey(cepRecord.parent_record__c) && 
                   caseRecordMap.get(cepRecord.parent_record__c).RecordType.DeveloperName == 'COVID_19_Case_Assessment' && 
                   (existingCase.RecordType.DeveloperName == 'Close_Contact' || existingCase.RecordType.DeveloperName == 'Secondary_Close_Contact') &&
                   (cepRecord.Relationship_to_Case__c == 'Household' || 
                    (personAccountMap.containsKey(cepRecord.ContactId) && personAccountMap.get(cepRecord.ContactId).Account.Head_of_household__c) || 
                    (personAccountMap.containsKey(cepRecord.ContactId) && personAccountMap.get(cepRecord.ContactId).Account.Household_member__c))){
                        existingCase.OwnerId = caseRecordMap.get(cepRecord.parent_record__c).OwnerId;
                        existingCase.Is_case_allocation_completed__c = true;
                        if(!closeContactsToBeUpdated.contains(existingCase)){
                            closeContactsToBeUpdated.add(existingCase); 
                        }
                    }
            }   System.debug('closeContactsToBeUpdated' + closeContactsToBeUpdated);
        }

        try
        {
            if(closeContactsToBeInserted.size()>0 )
            {            
                Database.insert(closeContactsToBeInserted);
                System.debug('******'+closeContactsToBeInserted);
                
                List<ContactEncounterParticipant> cepNoteList = new List<ContactEncounterParticipant>();
                
                for( ContactEncounterParticipant cepRecord : cepClosecontact.keySet() )            
                {
                    if(cepRecord.Record__c == null)
                    {
                        System.debug('Update Record__c for CEP'+cepRecord);
                        //Update CEP.Record__c field with new Close Contact.ID
                        cepRecord.Record__c = cepClosecontact.get(cepRecord).Id;  
                        cepNoteList.add(cepRecord);
                    }
                }
                
                addNoteForPCCInsert(cepNoteList);
            }
            
            //Add a Note to Close Contacts
            if( closeContactsToBeUpdated.size()>0 )
            {
             
                Database.update(closeContactsToBeUpdated);
    
                /*Create a Note for the close contact record.
                Subject: New contact encounter
                Text: Close Contact : <record_num> Day 0 has been updated due to an encounter with this record: <record_number>
                */
                title = 'New contact encounter';
                content = 'Close Contact : <case_number> Day 0 has been updated due to an encounter with this record: <case_number>'; 
                addNote(closeContactsToBeUpdated, title, content );                
            }                        
            
            if( confirmedCases.size()>0 )
            {
                System.debug('ADDING NOTE TO THE CONFIRMED CASE');
                /*Create a Note and add to the confirmed case record
                Subject: New contact encounter
                Text: Confirmed case: <case_num> has had an encounter with another confirmed case: <case_Num>
                */
                title = 'New contact encounter';
                content = 'Confirmed case: <case_number> has had an encounter with another confirmed case: <case_number>';
                addNote(confirmedCases, title, content );
                 
            }
        }
        catch(Exception excep)
        {
            System.debug('Exception occurred '+excep.getMessage());
        }
    }
    
    @testVisible
    private static void addNote(List<Case> caseRecords, String title, String content)
    {
        List<ContentNote> notes = new List<ContentNote>();
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        System.debug('in NOTES');  
        
        for( Case caseRecord : caseRecords)
        {
            ContentNote note = new ContentNote();
            content = content.replace('<case_number>', caseRecord.CaseNumber); 
            note.Content = Blob.valueof(content);
            note.Title = title;
            notes.add(note);                
        }
        Database.insert(notes);
        Integer i=0;
        for(ContentNote note : notes)
        {
            ContentDocumentLink link = new ContentDocumentLink();
            link.LinkedEntityId = caseRecords[i].Id;
            link.ContentDocumentId = note.Id;
            link.ShareType = 'I';
            links.add(link);
            i++;      
        }
        Database.insert(links);
        System.debug('ADDED NOTES');  
    }
    
    
    @testVisible
    private static void addNoteForPCCInsert(List<ContactEncounterParticipant> CEPRecords){
        if(CEPRecords.isEmpty()){
            return;
        }
        
        String title = 'New contact encounter';
        String content = 'Confirmed case: <confirmCase_Number> has had an encounter with another confirmed case: <case_number>';
        
        List<ContentNote> notes = new List<ContentNote>();
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        System.debug('in NOTES');  
        
        Set<Id> caseIds = new Set<Id>();
        for( ContactEncounterParticipant cepRecord : CEPRecords){
            caseIds.add(cepRecord.Parent_Record__c);
        	caseIds.add(cepRecord.Record__c);
        }
    
    	Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id, CaseNumber FROM Case WHERE Id = :caseIds]);
        
        for( ContactEncounterParticipant cepRecord : CEPRecords)
        {
            ContentNote note = new ContentNote();
            content = content.replace('<case_number>', caseMap.get(cepRecord.Record__c)==Null?'':caseMap.get(cepRecord.Record__c).CaseNumber); 
            content = content.replace('<confirmCase_Number>', caseMap.get(cepRecord.Parent_Record__c)==Null?'':caseMap.get(cepRecord.Parent_Record__c).CaseNumber); 
            note.Content = Blob.valueof(content);
            note.Title = title;
            notes.add(note);                
        }
        Database.insert(notes);
        Integer i=0;
        for(ContentNote note : notes)
        {
            ContentDocumentLink link = new ContentDocumentLink();
            link.LinkedEntityId = CEPRecords[i].Parent_Record__c;
            link.ContentDocumentId = note.Id;
            link.ShareType = 'I';
            links.add(link);
            i++;      
        }
        Database.insert(links);
        System.debug('ADDED NOTES');  
    }  

    //Added as part of the PBI #332083 --Household Close Contact Day 0 set to Date of First Positive Test Date of linked Case - logic change
    
    public static void updateDay0CloseContacts(List<ContactEncounterParticipant> cepRecords) {
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
        Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
        Id secondaryCloseContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId();
        Id acquisitionContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Acquisition_Contact').getRecordTypeId();
        Id casualContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Casual_Contact').getRecordTypeId();
        Id unclassifiedContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Unclassified_Contact').getRecordTypeId();
        Map<Id, String> caseIdRecordTypeName = new Map<Id, String>();
        Map<Id, Case> caseRecordMap = new Map<Id, Case>();
        Map<ContactEncounterParticipant, Case> cepClosecontact = new Map<ContactEncounterParticipant, Case>();
        
        List<Id> contactIds = new List<Id>();
        Map<Id, Contact> personAccountMap = new Map<Id, Contact>();
        List<Case> closeContactsToBeInserted = new List<Case>();
        List<Case> closeContactsToBeUpdated = new List<Case>();        
        List<Case> confirmedCases = new List<Case>();
        
        try{
            for( ContactEncounterParticipant cepRecord : cepRecords )
            {        
                if(cepRecord.Record__c!=null)
                {
                    caseIdRecordTypeName.put(cepRecord.Record__c, cepRecord.Record__c);       
                }
                
            }
            
            list<ContactEncounterParticipant> cepRecordsList = [SELECT Id, Parent_Record__c,Record__r.RecordType.DeveloperName,Record__r.Relationship_to_case__c,Relationship_to_Case__c,Record__r.Day_0_Exposure_to_the_confirmed_case__c,Parent_Record__r.Date_of_Test__c,
                                                                Record__c FROM ContactEncounterParticipant WHERE Record__c IN :caseIdRecordTypeName.keySet()];
            
            map<Id, Case> closeContactToUpdate = new map<Id, Case>();
            map<Id, list<case>> closeContact = new map<Id, list<case>>();
            for(ContactEncounterParticipant cepRecord : cepRecordsList){
                if(cepRecord.Record__r.RecordType.DeveloperName == 'Close_Contact' && cepRecord.Relationship_to_case__c == 'Household'){
                    if(closeContact.containskey(cepRecord.Record__c)){
                        list<case> caseList = new  list<case>();
                        case c = new case();
                        c.Id = cepRecord.Parent_Record__c;
                        c.Date_of_Test__c = cepRecord.Parent_Record__r.Date_of_Test__c;
                        caseList.addall(closeContact.get(cepRecord.Record__c));
                        caseList.add(c);
                        closeContact.put(cepRecord.Record__c,caseList);
                    }
                    else{
                        list<case> caseList = new  list<case>();
                        case c = new case();
                        c.Id = cepRecord.Parent_Record__c;
                        c.Date_of_Test__c = cepRecord.Parent_Record__r.Date_of_Test__c;
                        
                        caseList.add(c);
                        closeContact.put(cepRecord.Record__c,caseList);
                    }
                }
            }
            for( Id id : closeContact.keyset() ){
                list<case> caseList = new  list<case>();
                caseList.addAll(closeContact.get(id));
                date smallestDate;
                for(case c : caseList){
                    if(smallestDate == Null ){
                        smallestDate = c.Date_of_Test__c;
                    }
                    else{
                        if(smallestDate > c.Date_of_Test__c){
                            smallestDate = c.Date_of_Test__c;
                        }
                    }
                }
                case c = new case();
                c.Id = id;
                c.Day_0_Exposure_to_the_confirmed_case__c = smallestDate;
                closeContactToUpdate.put(c.Id,c);
            }
            
            closeContactsToBeUpdated.addAll(closeContactToUpdate.values());
            update closeContactsToBeUpdated;
            
        }
        catch(Exception e){
            Application_Log__c appLog = new Application_Log__c(Message__c = e.getMessage(),Stack_Trace__c = e.getStackTraceString(),Source__c = 'CEPTriggerHandler',Source_Function__c = 'updateDay0CloseContacts', Transaction_Date__c = System.now());
            insert appLog;
            system.debug('e.getLineNumber ' + e.getLineNumber());
            system.debug('e.getMessage ' + e.getMessage());
        }  
    }
}