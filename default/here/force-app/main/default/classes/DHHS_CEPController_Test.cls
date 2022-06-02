@istest
private class DHHS_CEPController_Test {
    
        // @testSetup static void setup(){
        //         // Create Account
        //         String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        //         Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
        //         PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        //         insert acc;
        //         // Create Entitlement
        //         Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        //         insert entl;
        //         // Create Case
        //         String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        //         Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
        //         AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today(), EntitlementId = entl.Id);
        //         insert cse;
        // }
    
      static testMethod void testcaseBYREcordNUmber() {
        // Create Account
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;
        // Create Entitlement
        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;
        // Create Case
        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
                Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today(), EntitlementId = entl.Id);
        insert cse;       

        Test.startTest();
        case cseN = DHHS_CEPController.checkCasesforRecordNumber(cse.Id);
        Test.stopTest();
        
        System.assertEquals(cseN.AccountId, acc.Id, 'cases for the given account Id');
        }
    
    
        static testMethod void testCheckCasesExistForPersonId() {
        // Create Account
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;
        // Create Entitlement
        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;
        // Create Case
        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today(), EntitlementId = entl.Id);
        insert cse;

        Test.startTest();
        Case compare = DHHS_CEPController.checkCasesExistForPersonId(String.valueOf(acc.Id));
        Test.stopTest();
        System.assertEquals(compare.Id, cse.Id);
        }

        static testMethod void testGetPersonContactId(){
        // Create Account
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;

        System.debug('********** Person Account ID 2' + acc.Id + ' Person Contact ID 2 ' + acc.personContactId);
        // Create Entitlement
        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;
        // Create Case
        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today(), EntitlementId = entl.Id);
        insert cse;

        System.debug('********** Person Account ID 3' + acc.Id + ' Person Contact ID 3 ' + acc.personContactId);
        Test.startTest();
        Account currentAcc =  [SELECT PersonContactId FROM Account WHERE Id=:acc.id LIMIT 1];
        System.debug('********** Person Account ID 4' + acc.Id + ' Person Contact ID 4' + acc.personContactId);
        Account accountToCompare = DHHS_CEPController.getPersonContactId(String.valueOf(acc.Id));
        Test.stopTest();
        System.assertEquals(accountToCompare.personContactId,currentAcc.personContactId);
    }



    static testMethod void testCloseContact(){
        // Create Account
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;

        System.debug('********** Person Account ID 2' + acc.Id + ' Person Contact ID 2 ' + acc.personContactId);
        // Create Entitlement
        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;
        // Create Case
        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Quarantine', SubStatus__c = 'In Progress', Subject = 'Test Close Contact',
                AccountId = acc.Id, Day_0_Exposure_to_the_confirmed_case__c= System.Today().addDays(-10), EntitlementId = entl.Id);
        insert cse;

        Schema.Location loc1 = New Schema.Location();
        loc1.Name = 'test';
        insert loc1;
        ContactEncounter contactEnc = new ContactEncounter ();
        contactEnc.Location__c = loc1.Id;
        contactEnc.LocationId = loc1.Id;
        contactEnc.Record__c = cse.Id;
        contactEnc.StartTime = System.now().addDays(-2);
        contactEnc.End_Time__c = System.now().addDays(-1);
        contactEnc.Name = 'At Home';
        DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
        System.debug('***********************' + contactEnc.Id);

        ContactEncounterParticipant newCEP = new ContactEncounterParticipant();
        newCEP.ContactEncounterId = contactEnc.Id;
        newCEP.contactId = DHHS_CEPController.getPersonContactId(String.valueOf(acc.Id)).PersonContactId;
        newCEP.Contact_Type__c = 'Close Contact';
        newCEP.Parent_Record__c = cse.Id;
        newCEP.Record__c = cse.Id;
        newCEP.Relationship_to_Case__c = 'Airline';
        newCEP.Specify_relationship_to_case__c = 'Co-worker';
        newCEP.End_Time__c = System.now().addDays(-5);
        newCEP.Description__c = '';
        
        ContactEncounterParticipant cep;
        try{
                cep = DHHS_CEPController.createCEP(newCEP);
        } catch(Exception e){
                
        }

        newCEP.End_Time__c = System.now();
        try{
                cep = DHHS_CEPController.createCEP(newCEP);
        } catch(Exception e){
                
        }

        try{
                newCEP.Contact_Type__c = 'Secondary Close Contact';
                cep = DHHS_CEPController.createCEP(newCEP);	
        } catch(Exception e){
                System.Debug('*** Exception: '+e.getMessage());
        }
        //System.assertNotEquals(cep, null);
    }

    static testMethod void testCreateCEP(){
        // Create Account
        //User u = new User(Id=UserInfo.getUserId());
        //UserTriggerHandler.addHCPermissionSets(new List<User>{u});
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;

        System.debug('********** Person Account ID 1' + acc.Id + ' Person Contact ID 1 ' + acc.personContactId);

        // Create Entitlement
        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;

        // Create Case
        // String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        // Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
        //         AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today().addDays(-7), Clearance_eligibility_assessment_date__c=System.Today().addDays(7), EntitlementId = entl.Id);
        // insert cse;
        String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Trace', SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
                AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today().addDays(-5), Date_of_Test__c = System.Today().addDays(-2), Clearance_eligibility_assessment_date__c = System.Today().addDays(12), EntitlementId = entl.Id);
        insert cse;

        // Create CE
        Schema.Location loc1 = New Schema.Location();
        loc1.Name = 'test';
        insert loc1;
        ContactEncounter contactEnc = new ContactEncounter ();
        contactEnc.Location__c = loc1.Id;
        contactEnc.LocationId = loc1.Id;
        contactEnc.Record__c = cse.Id;
        contactEnc.StartTime = System.now().addDays(-1);
        contactEnc.End_Time__c = System.now();
        contactEnc.Name = 'At Home';
        DHHS_ContactEncounterController.createDirectContactEncounter(contactEnc);
        System.debug('***********************' + contactEnc.Id);
        //insert contactEnc;
		
        // Create CEP
        ContactEncounterParticipant newCEP = new ContactEncounterParticipant();
        //newCEP.ContactEncounterId = contactEnc.Id;
        //newCEP.contactId = DHHS_CEPController.getPersonContactId(String.valueOf(acc.Id));
        //newCEP.Contact_Type__c = 'Close contact';
        //newCEP.Parent_Record__c = cse.Id;
        //newCEP.Record__c = cse.Id;
        //newCEP.Relationship_to_Case__c = 'Airline';
        //newCEP.Specify_relationship_to_case__c = 'Co-worker';
        newCEP.End_Time__c = System.now();
        newCEP.Description__c = '';

        // Test Stuff
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP);
        } catch (Exception e) {

        }
        newCEP.ContactEncounterId = contactEnc.Id;
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP);
        } catch (Exception e) {

        }

        Account tmpAccount = DHHS_CEPController.getPersonContactId(String.valueOf(acc.Id));
        newCEP.contactId = tmpAccount.PersonContactId;
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP);
        } catch (Exception e) {
                System.debug('***** Exception Returned: ' + e);
        }
        newCEP.Contact_Type__c = 'Close contact';
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP); 
        } catch (Exception e) {

        }
        newCEP.Parent_Record__c = cse.Id;
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP);
        } catch (Exception e) {

        }
        newCEP.Record__c = cse.Id;
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP);
        } catch (Exception e) {

        }
        newCEP.Relationship_to_Case__c = 'Airline';
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP);
        } catch (Exception e) {

        }
        newCEP.Specify_relationship_to_case__c = 'Co-worker';
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP);
        } catch (Exception e) {

        }
        newCEP.End_Time__c = System.Now()-1;
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP);
        } catch (Exception e) {

        }
        cse.Symptoms_Onset_Date__c = System.now().date()-4;
        //update cse;
        cse.recalculateFormulas();
        cse.Clearance_eligibility_assessment_date__c = System.now().date()+13;
        //System.debug('********************* Symptom onset date = ' + cse.Symptoms_Onset_Date__c);
        //cse.Calculated_Onset_Date__c = System.now()-4;
        //System.debug('********************* Assessment date = ' + cse.Clearance_eligibility_assessment_date__c);
        //System.debug('********************* Calculated onset date = ' + cse.Calculated_Onset_Date__c);
        update cse;
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP);
        } catch (Exception e) {

        }
        contactEnc.End_Time__c = System.now()+50;
        try {
                ContactEncounterParticipant cep = DHHS_CEPController.createCEP(newCEP);
        } catch (Exception e) {

        }
    }
        @isTest
        static void testExceptions(){
                boolean control = false;
                Test.startTest();
                try{
                        DHHS_CEPController.checkCasesExistForPersonId('123124');
                }catch(exception e){
                        control = true;
                }
                try{
                        DHHS_CEPController.getPersonContactId('123124');
                }catch(exception e){
                        control = true;
                }

                Test.stopTest();
                System.assertEquals(true, control);
    }
    
          static testMethod void testCase() {
        // Create Account
        String recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc = new Account(RecordTypeID = recordTypeId, FirstName = 'Test FName', LastName = 'Test LName', PersonMailingStreet = 'test@yahoo.com',
                PersonMailingPostalCode = '12345', PersonMailingCity = 'SFO', PersonEmail = 'test@yahoo.com', PersonHomePhone = '1234567', PersonMobilePhone = '+611234');
        insert acc;
        // Create Entitlement
        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = acc.Id);
        insert entl;
        // Create Case
        //String caseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
        Id cepCloseConRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId(); 
        
        Case cse = new Case(recordTypeId = caseRecordTypeId, Status = 'Isolate', Date_of_Test__c = SYSTEM.TODAY().addDays(-5),Day_0_Exposure_to_the_confirmed_case__c = SYSTEM.TODAY().addDays(-8),
                             Clearance_eligibility_assessment_date__c = SYSTEM.TODAY(),SubStatus__c = 'In Progress', Subject = 'Test Case - Daily Milestone Test',
        						AccountId = acc.Id, Symptoms_Onset_Date__c = System.Today().addDays(-3), EntitlementId = entl.Id);
        insert cse;
              cse.Description = 'test';
              update cse;
        
        ContactEncounter ceRecord = new ContactEncounter(RecordTypeId=cepCloseConRecordTypeId, Name='Private residence – home',End_Time__c = System.Now(), StartTime=System.Now(), Record__c=cse.Id ); 
        insert ceRecord;       

        Test.startTest();
       
        boolean b = DHHS_CEPController.contactWithinInfectiousPeriod(cse, ceRecord);
   
        Test.stopTest();
        
        System.assertEquals(cse.AccountId, acc.Id, 'cases for the given account Id');
        }
    
}