@isTest
public class DHHSPrintCaseExtensionTest {

    static testMethod void TestData() 
    {
        
        String recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
        Account acc= new Account(RecordTypeID=recordTypeId, FirstName='FirstName', LastName='LastName',PersonMailingStreet='1 Flinders St',
                                 PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test@salesforce.com', PersonHomePhone='+6130000001',PersonMobilePhone='+6140000001');
        insert acc;


        Case cse = new Case(recordTypeId=confirmedCaseRecordTypeId ,Status='Quarantine' ,SubStatus__c='In Progress',Subject='Test',
        AccountId=acc.Id, Confirmation_Date__c=System.Today()-6);

      
        insert cse;

       
        /** Minimum data set as we are reliant on tests within the Service class to provide coverage of the SELECT logic **/
        
        Test.StartTest(); 
        
        PageReference pageRef = Page.DHHSPrintCase;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(cse.Id));
        
        ApexPages.StandardController cseController = new  ApexPages.StandardController(cse);         
        DHHSPrintCaseExtension testExtn = new DHHSPrintCaseExtension(cseController);
        
        /** We need to prove the controller anbd page work correctly, not the data rovided by the service **/
        system.assertNotEquals(null, testExtn.svc, 'Service class has not initialised correctly using a valid case id');
        
        /** We expect the following calls to exist to support the PDF page, check we have the right record **/
        system.assertEquals(testExtn.svc.Record.Id, cse.Id, 'We saved a case and provided this Id to the controller, the service class failed to return a valid record');
        
        /** Now assert we get 'something' back, i.e. not null **/
        system.assertNotEquals(null, testExtn.svc.WorkOrders, 'Service class failed to return valid data for section: WorkOrders');
        system.assertNotEquals(null, testExtn.svc.DetailClearance, 'Service class failed to return valid data for section: DetailClearance');
        system.assertNotEquals(null, testExtn.svc.PrivacyStatement, 'Service class failed to return valid data for section: PrivacyStatement');
        system.assertNotEquals(null, testExtn.svc.Details, 'Service class failed to return valid data for section: Details');
        system.assertNotEquals(null, testExtn.svc.GeneralPresentation, 'Service class failed to return valid data for section: GeneralPresentation');
        system.assertNotEquals(null, testExtn.svc.EpidemiologicalRisks, 'Service class failed to return valid data for section: EpidemiologicalRisks');
        system.assertNotEquals(null, testExtn.svc.OutbreakDetails, 'Service class failed to return valid data for section: OutbreakDetails');
        system.assertNotEquals(null, testExtn.svc.ContactsAndMovements, 'Service class failed to return valid data for section: ContactsAndMovements');
        system.assertNotEquals(null, testExtn.svc.PublicHealthActions, 'Service class failed to return valid data for section: PublicHealthActions');
        system.assertNotEquals(null, testExtn.svc.FollowUpPayments, 'Service class failed to return valid data for section: FollowUpPayments');
        system.assertNotEquals(null, testExtn.svc.FollowUpEducation, 'Service class failed to return valid data for section: FollowUpEducation');
        system.assertNotEquals(null, testExtn.svc.Demographics, 'Service class failed to return valid data for section: Demographics');
        system.assertNotEquals(null, testExtn.svc.CloseContacts, 'Service class failed to return valid data for section: CloseContacts');
        system.assertNotEquals(null, testExtn.svc.ContactsWithConfirmedCases, 'Service class failed to return valid data for section: ContactsWithConfirmedCases');
        system.assertNotEquals(null, testExtn.svc.confirmedCEPRecords, 'Service class failed to return valid data for section: confirmedCEPRecords');
        system.assertNotEquals(null, testExtn.svc.closedCEPRecords, 'Service class failed to return valid data for section: closedCEPRecords');

        /** Related lists return FALSE as no data **/
        system.assertNotEquals(true, testExtn.svc.HasContactEncounters, 'Service class failed to return valid data for section: ContactEncounters');
        system.assertNotEquals(true, testExtn.svc.HasClinicalAssesmentResponses, 'Service class failed to return valid data for section: ClinicalAssesmentResponses');
        system.assertNotEquals(true, testExtn.svc.HasEHREncouters, 'Service class failed to return valid data for section: EHREncouters');
        system.assertNotEquals(true, testExtn.svc.HasCaseMovements, 'Service class failed to return valid data for section: CaseMovements');
        system.assertNotEquals(true, testExtn.svc.HasContactsWithConfirmedCases, 'Service class failed to return valid data for section: has ContactsWithConfirmedCases');
        system.assertNotEquals(true, testExtn.svc.HasCloseContacts, 'Service class failed to return valid data for section: check for CloseContacts');


        Test.StopTest();
    }
}