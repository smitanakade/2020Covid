@isTest
public class CDLTriggerHandlerTest {
    
   @isTest()
    public static void test_CaseNotes() {
        
        Id accountRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Id covidAssessmentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
        Id interviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();

    	Test.startTest();
    	Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='Test1 FName', LastName='Test1 LName',PersonMailingStreet='101 Collins Street',
                         PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test11112@gmail.com', PersonHomePhone='1234567',PersonMobilePhone='+614444');
        insert accountRecord;
        
        Id contactId = [Select PersonContactId from Account where Id=:accountRecord.Id][0].PersonContactId;

        Case caseAssessment = new Case(recordTypeId=covidAssessmentRecordTypeId ,Status='Identify',Subject='Test closeContact',
                             AccountId=accountRecord.Id, ContactId = contactId);
        //Case closeContact = new Case(recordTypeId=closeContactRecordTypeId ,Status='Identify',AccountId=accountRecord.Id);
        insert caseAssessment;
        
        WorkOrder w2 = new WorkOrder(CaseId = caseAssessment.Id, Status = 'New', RecordTypeId = interviewWORecordTypeId);

        insert w2;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sub.id;
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=w2.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        Test.stopTest();
    }
    
        public static void testWONotes(){
        Id accountRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Id covidAssessmentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
        Id interviewWORecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Interview').getRecordTypeId();

        Test.startTest();
    	Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='Test1 FName', LastName='Test1 LName',PersonMailingStreet='101 Collins Street',
                         PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test11112@gmail.com', PersonHomePhone='1234567',PersonMobilePhone='+614444');
        insert accountRecord;
        
        Id contactId = [Select PersonContactId from Account where Id=:accountRecord.Id][0].PersonContactId;

        Case caseAssessment = new Case(recordTypeId=covidAssessmentRecordTypeId ,Status='Identify',Subject='Test closeContact',
                             AccountId=accountRecord.Id, ContactId = contactId);
        //Case closeContact = new Case(recordTypeId=closeContactRecordTypeId ,Status='Identify',AccountId=accountRecord.Id);
        insert caseAssessment;
        
        WorkOrder w2 = new WorkOrder(CaseId = caseAssessment.Id, Status = 'New', RecordTypeId = interviewWORecordTypeId);

        insert w2;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sub.id;
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=caseAssessment.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
            
        ContentDocumentLink contentlinkC=new ContentDocumentLink();
        contentlinkC.LinkedEntityId=caseAssessment.id;
        contentlinkC.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlinkC.ShareType = 'I';
        contentlinkC.Visibility = 'AllUsers'; 
           
            
        insert contentlinkC;
        
        ContentDocumentLink cdl = [select id, linkedentityid from ContentDocumentLink where linkedentityid = :w2.Id];
        System.assert(cdl!=null);
        
        
        
        Test.stopTest();

	}
}