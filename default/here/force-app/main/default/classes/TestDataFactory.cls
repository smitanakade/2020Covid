/**
 * @description       : Test Data Factory to create Data for common Objects
 * @author            : CRM Squad 2
 * @group             : CRM Squad 2
 * @last modified on  : 12-02-2020
 * @last modified by  : CRM Squad 2
 * Modifications Log 
 * Ver   Date         Author               Modification
 * 1.0   11-23-2020   CRM Squad 2          Initial Version
 * 1.1   03-11-2021   Hasantha E           253228 - Added createCasePerAccount
 * 1.2   07-04-2021   Pratyush Chalasani   Added CreatedDate parameter for when inserting Account records
 * 1.3   09-06-2021   Rahul Ankireddypalli Added createBusinessUnitRecord() for Testing the updated Business Unit Records
 * 1.4   09-07-2021   Sukumar Salla        Added createCPARecord
**/
@IsTest
public with sharing class TestDataFactory {

    /**
    * @description create Cases object record
    * @author CRM Squad 2 | 11-23-2020 
    * @param acc 
    * @param numCases 
    * @param caseStatus 
    * @param recordTypeName 
    * @return List<Case> 
    **/
    public static List<Case> createCases(Account acc, Integer numCases, String caseStatus, String recordTypeName) {

        Entitlement entl = new Entitlement(Name='TestEntitlement', AccountId=acc.Id);
        insert entl;
        List<Case> caseList = new List<Case>();
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        for(integer i=1;i<=numCases;i++){
        Case caseRec = new Case(status=caseStatus ,subject='Test Case'+i, RecordTypeId = recordTypeId, SubStatus__c='In Progress',
        AccountId=acc.Id, Symptoms_Onset_Date__c=System.Today(), EntitlementId=entl.Id);
        caseList.add(caseRec);
        }

        insert caseList;
        return caseList;
    }
    public static List<Case> createCasesNoInsert(Account acc, Integer numCases, String caseStatus, String recordTypeName) {

        Entitlement entl = new Entitlement(Name='TestEntitlement', AccountId=acc.Id);
        insert entl;
        List<Case> caseList = new List<Case>();
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        for(integer i=1;i<=numCases;i++){
        Case caseRec = new Case(status=caseStatus ,subject='Test Case'+i, RecordTypeId = recordTypeId, SubStatus__c='In Progress',
        AccountId=acc.Id, Symptoms_Onset_Date__c=System.Today(), EntitlementId=entl.Id);
        caseList.add(caseRec);
        }

        return caseList;
    }

    public static List<WorkOrder> createWorkOrdersNoInsert(Account accRec,Case caseRec, Integer numworkOrders, String workOrderStatus, String recordTypeName,String subject) {
        List<WorkOrder> workOrderList = new List<WorkOrder>();
        Id recordTypeId  = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
         for(integer i=1;i<=numworkOrders;i++){
           WorkOrder ordRec=new WorkOrder();
           ordRec.recordTypeId=recordTypeId;
           ordRec.Status=workOrderStatus;
           ordRec.subject=subject;
           ordRec.AccountId=accRec.Id;
           ordRec.CaseId=caseRec.Id;
           workOrderList.add(ordRec);
         }
       
       return workOrderList;
     
       }

    /**
    * @description create Account object record
    * @author CRM Squad 2 | 11-23-2020 
    * @param numAccounts 
    * @param accStatus 
    * @param recType 
    * @return List<Account> 
    **/
    public static List<Account> createAccount(Integer numAccounts, String accStatus, String recType) {
        return createAccount(numAccounts, accStatus, recType, null);
    }

    /**
    * @description create Account object record (with specifiec CreatedDate)
    * @author CRM Squad 2 | 07-04-2021 
    * @param numAccounts 
    * @param accStatus 
    * @param recType 
    * @param createdDate
    * @return List<Account> 
    **/
    public static List<Account> createAccount(Integer numAccounts, String accStatus, String recType, Datetime createdDate) {

        List<Account> accList = new List<Account>();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recType).getRecordTypeId();
        for(integer i=1;i<=numAccounts;i++){
        Account account = new Account();
        account.Status__c=accStatus;
        account.RecordTypeId=recordTypeId;
            if(recType=='Person Account'){
                account.FirstName = 'Test';
                account.LastName=recType+i;
                account.PersonMailingStreet='test@yahoo.com';
                account.PersonMailingPostalCode='12345'; 
                account.PersonMailingCity='SFO'; 
                account.PersonEmail='test@yahoo.com'; 
                account.PersonHomePhone='';
                account.PersonMobilePhone='+611234';
            }else{
                account.Name = recType+i;
            }

            if (createdDate != null) {
                account.CreatedDate = createdDate;
            }

            accList.add(account);
        }

        insert accList;
        
        return accList;
    }

     /**
    * @description create Account object record (with specifiec CreatedDate) without  insert into database
    * @param numAccounts 
    * @param accStatus 
    * @param recType 
    * @param createdDate
    * @return List<Account> 
    **/
    public static List<Account> createAccountNoInsert(Integer numAccounts, String accStatus, String recType, Datetime createdDate) {

        List<Account> accList = new List<Account>();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recType).getRecordTypeId();
        for(integer i=1;i<=numAccounts;i++){
        Account account = new Account();
        account.Status__c=accStatus;
        account.RecordTypeId=recordTypeId;
            if(recType=='Person Account'){
                account.FirstName = 'Test';
                account.LastName=recType+i;
                account.PersonMailingStreet='test@yahoo.com';
                account.PersonMailingPostalCode='12345'; 
                account.PersonMailingCity='SFO'; 
                account.PersonEmail='test@yahoo.com'; 
                account.PersonHomePhone='';
                account.PersonMobilePhone='+611234';
            }else{
                account.Name = recType+i;
            }

            if (createdDate != null) {
                account.CreatedDate = createdDate;
            }

            accList.add(account);
        }

      
        
        return accList;
    }
    
    /** create Contact object record
    * @description 
    * @author CRM Squad 2 | 11-23-2020 
    * @param accList 
    * @return List<Contact> 
    **/
    public static List<Contact> createContact(List<Account> accList) {

        List<Contact> conList = new List<Contact>();

        for(integer i=0;i<accList.size();i++){
        Contact con = new Contact(AccountId = accList.get(i).ID, FirstName = 'Test', LastName='Contact'+i);
        conList.add(con);
        }

        insert conList;
        
        return conList;
    }
    /** create ContactEncounter Record
    * @description 
    * @author CRM Squad 2 | 11-23-2020 
    * @param conList 
    * @return List<ContactEncounter> 
    **/
    public static List<ContactEncounter> createContactEncounter(List<Contact> conList){
        List<ContactEncounter> conEncList = new List<ContactEncounter>();

        for(integer i=0;i<conList.size();i++){
            ContactEncounter conEnc = new ContactEncounter(Contact_Person__c = conList.get(i).ID, Name='Test Encounter'+i,StartTime=System.today());
            conEncList.add(conEnc);
        }
        insert conEncList;
        return conEncList;
    }

    /**
    * @description create Health Worker User to Run As User
    * @author CRM Squad 2 | 11-23-2020 
    * @return User 
    **/
    Public static User createHealthWorkerUser(){

        Profile profile = [select Id from Profile where Name='Health Worker' LIMIT 1];
        User userRecord = new User( Alias = 'contst', Email='standarduser_healthworker@testorg.com', 
        EmailEncodingKey='UTF-8', FirstName = 'Test', LastName='User' , LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = profile.Id, 
        TimeZoneSidKey='Australia/Sydney', UserName= 'testUser-healthworker@dhhs.goc.au.testuser', IsActive = true);  

        insert userRecord;
        return userRecord;
    }

    Public static User createAdminUser(){

        Profile profile = [select Id from Profile where Name='System Administrator' LIMIT 1];
        User userRecord = new User( Alias = 'contst', Email='standarduser_admin@testorg.com', 
        EmailEncodingKey='UTF-8', FirstName = 'Test', LastName='User' , LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = profile.Id, 
        TimeZoneSidKey='Australia/Sydney', UserName= 'testUser-admin@dhhs.goc.au.testuser', IsActive = true);  

        insert userRecord;
        return userRecord;
    }

    /**
    * @description  create Queue Allocation For Case RecordType
    * @author CRM Squad 2 | 12-02-2020 
    * @return List<Queue_Allocation__c> 
    **/
    Public static List<Queue_Allocation__c> createQAllocationForCaseRecordType(){

                //Set Data Queue Allocation - due to change from assignment rule to flow - US 240609
                Schema.DescribeSObjectResult caseSobjectDesc = Case.SObjectType.getDescribe();
                List<Schema.RecordTypeInfo> caseRecTypeInfoList = caseSobjectDesc.getRecordTypeInfos();

                List<Queue_Allocation__c> qaList  = new List<Queue_Allocation__c>();
                for(Integer i=0;i<caseRecTypeInfoList.size(); i++){
                    Queue_Allocation__c qaRec = new Queue_Allocation__c(Record_Type__c = caseRecTypeInfoList.get(i).getName(), Sequence__c = i, Queue_Name__c='Team Six');
                    qaList.add(qaRec);
                }

                insert qaList;
                return qaList;
    }

    /**
    * @description  create Queue Allocation For Work Order RecordType
    * @author CRM Squad 2 | 12-02-2020 
    * @return List<Queue_Allocation__c> 
    **/
    Public static List<Queue_Allocation__c> createQAllocationForWorkOrderRecordType(){    

        //Set Data Queue Allocation - due to change from assignment rule to flow - US 240609

        Schema.DescribeSObjectResult woSobjectDesc = WorkOrder.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> woRecTypeInfoList = woSobjectDesc.getRecordTypeInfos();
        List<Queue_Allocation__c> qaList  = new List<Queue_Allocation__c>();

        for(Integer i=0;i<woRecTypeInfoList.size(); i++){
            Queue_Allocation__c qaRec = new Queue_Allocation__c(Record_Type__c = woRecTypeInfoList.get(i).getName(), Sequence__c = i, Queue_Name__c='Team Six');
            qaList.add(qaRec);
        }
        insert qaList;

        return qaList;
    }

    /**
     * @description  Create a Hospital record (HealthCloudGA__EhrEncounter__c) for a list of cases
     * @author Duncan Bridges
     * @return List<HealthCloudGA__EhrEncounter__c> 
     * This requires that the running user has Health Cloud Permission set licence and the relevant permission sets to create a work order
    */
    public static List<HealthCloudGA__EhrEncounter__c> createHospitalRecordsForCases(List<Case> cases, String presentedToValue, Date startDate) {
        List<HealthCloudGA__EhrEncounter__c> encounters = new List<HealthCloudGA__EhrEncounter__c>();
        for(Case rec : cases){
            HealthCloudGA__EhrEncounter__c encounter = new HealthCloudGA__EhrEncounter__c(Record__c = rec.id, Presented_to__c = presentedToValue, StartDate__c = startDate, End_Date__c = startDate.addDays(14));
            encounters.add(encounter);
        }

        //TODO add DML permission check
        insert encounters;
        return encounters;
    }

     /**
     * @description  Create a Hospital records for a list of cases with admission and discharge date 
     * @author Santosh
     * @return List<HealthCloudGA__EhrEncounter__c> 
    */
    public static List<HealthCloudGA__EhrEncounter__c> createHMIPs(List<Case> cases, String presentedToValue, Date startDate) {
        List<HealthCloudGA__EhrEncounter__c> encounters = new List<HealthCloudGA__EhrEncounter__c>();
        for(Case rec : cases){
            HealthCloudGA__EhrEncounter__c encounter = new HealthCloudGA__EhrEncounter__c(Record__c = rec.id, Presented_to__c = presentedToValue, Date_admitted__c = startDate, Date_discharged__c = startDate.addDays(14));
            encounters.add(encounter);
        }

        //TODO add DML permission check
        insert encounters;
        return encounters;
    }
    
    /**
     * @description  Create a contact point address (ContactPointAddress) for a list of accounts
     * @author Santosh
     * @return List<ContactPointAddress> 
     * This requires that the running user has Health Cloud Permission set licence and the relevant permission sets to create a work order
    */
    public static List<ContactPointAddress> createCPAsforaccount(Account acc, String Type, Date startDate, integer numberofcpas) {
        List<ContactPointAddress> CPAs = new List<ContactPointAddress>();
        for(Integer n =0; n < numberofcpas; n++){
            ContactPointAddress CPA = new ContactPointAddress(name='TestCPA', ParentId = acc.id, AddressType = Type, ActiveFromDate = startDate, ActiveToDate = startDate.addDays(14));
            CPA.street = 'Test Street';
      	    CPA.city = 'TestCity';
       		CPA.country = 'Test Country';
       		CPA.state = 'Test State';
      	    CPA.postalcode = 'Test Pcode';
            CPAs.add(CPA);
        }

        //TODO add DML permission check
        insert CPAs;
        return CPAs;
    }
   
    
   /**
    * @description create Cases object record per number of account passed
    * @author CRM Squad 2 | 11-23-2020
    * @param acc
    * @param numCases
    * @param caseStatus
    * @param recordTypeName
    * @return List<Case>
    **/
     public static List<Case> createCasePerAccount(List<Account> accounts ,String caseStatus, String subStatus, String recordTypeId) {
         accounts = [SELECT Id, PersonContactId FROM Account WHERE Id =: accounts];
        Integer numCases = accounts.size();
        // create list of entitlements per account
        List<Entitlement> entitlements = new List<Entitlement>();
        for(integer i=0;i<numCases;i++) {
            entitlements.add(new Entitlement(Name = 'TestEntitlement', AccountId = accounts[i].Id));
        }
        insert entitlements;

        // create list of cases
        List<Case> caseList = new List<Case>();
        
        for(integer i=0;i<numCases;i++) {
            Case caseRec = new Case(
                    status = caseStatus ,
                	SubStatus__c = subStatus,
                    subject = 'Test Case'+i,
                    RecordTypeId = recordTypeId,
                    AccountId = accounts[i].Id,
                    ContactId = accounts[i].PersonContactId,
                    Symptoms_Onset_Date__c = Date.today(),
                    EntitlementId = entitlements[i].Id,
                    Clearance_eligibility_assessment_date__c = Date.today(),
                    Clinical_Care_Management__c = null
            );

            caseList.add(caseRec);
        }

        insert caseList;
        return [
                SELECT  Id
                        , status
                        , SubStatus__c
                        , subject
                        , RecordTypeId
                        , AccountId
                        , ContactId
                        , Symptoms_Onset_Date__c
                        , EntitlementId
                        , OwnerId
                        , Clearance_eligibility_assessment_date__c
                FROM Case
                WHERE ID =: caseList
        ];
    }
        /**
     * @description  Create a BusinessUnitRecord 
     * @author Rahul Ankireddypalli
     * @return List<Business_Unit__c> 
     * This creates Business Unit Records for the test Class BusinessUnitHelperTest
    */
    public static Business_Unit__c createBusinessUnitRecord() {

                Business_Unit__c buRec = new Business_Unit__c(
                    Queue_Name__c = 'Albury Wodonga',
                	Reroute_Queue_Name__c = 'Grampians',
                    Reroute_Ownership_ON__c = false,
                    Capacity__c = null
            );
                insert buRec;
                return buRec;
    }

    /**
     * @description  Create a CPARecord 
     * @author Rahul Ankireddypalli
     * @return List<ContactPointAddress> 
     * This creates contatPointAddress Records for the test Class ContactPointAddressValidation
    */
    public static List<ContactPointAddress> createCPARecord(Account accounts,integer num, boolean isInsert) {

        string CPAparentid = accounts.id;
        List<ContactPointAddress> cpaList = new List<ContactPointAddress>();
        for(integer i=0;i<num;i++) {
        ContactPointAddress CPARec = new ContactPointAddress(
            Name = 'Test CPA record'+i,
            AddressType = 'Home',
            ParentId = CPAparentid,
            ActiveFromDate = System.today(),
            ActiveToDate = null
            );
            cpaList.add(CPARec);
        }
        if(isInsert){
             insert cpaList;
        }
        return cpaList;
    
}
}