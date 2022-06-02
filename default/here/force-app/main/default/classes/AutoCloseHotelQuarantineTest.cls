
@IsTest
private class AutoCloseHotelQuarantineTest {
    @testSetup
    static void setupTestData() {
        Id accountRecordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();

        Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='Test FName', LastName='Test LName',PersonMailingStreet='101 Collins Street',
                PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonEmail='test@gmail.com', PersonHomePhone='1234567',PersonMobilePhone='+614444');
        insert accountRecord;

        Case closeContact = new Case(recordTypeId=closeContactRecordTypeId,
                                        Status='Ex-HQ Follow-up',
                                        Subject='Test',
                                        HQ_Resident__c=true,
                                        AccountId=accountRecord.Id,
                                        Day_0_Exposure_to_the_confirmed_case__c=System.Today()-6);
        insert closeContact;
    }

    @IsTest
    static void testAutoCloseHotelQuarantine(){
        Test.startTest();
        Database.executeBatch(new AutoCloseHotelQuarantine(), 200);
        Test.stopTest();

        System.assert([SELECT Id, Status FROM Case WHERE Status='Closed'].size() == 1);
    }
}