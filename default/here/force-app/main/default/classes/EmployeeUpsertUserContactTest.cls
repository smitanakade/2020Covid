/**
 * this test class was only created for code coverage and deployment. 
 * origins of the EmployeeUpsertUserContact class has not been determined (unmanaged or managed pkg)
 * for some reason this class could not be deactivated
 * instead of deleting and potentially impacting a feature, a test class was created
 */
@isTest
public with sharing class EmployeeUpsertUserContactTest {
    @IsTest
    static void testEmployeeContact() {
        try{
            Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            Set<Id> usrSet = new Set<Id>();
            User usr = new User(LastName = 'John',
                FirstName='Doe',
                Alias = 'jdoe',
                Email = 'test@test.com',
                Username = 'test@dhhs.dtti.test',
                ProfileId = profileId.id,
                TimeZoneSidKey = 'GMT',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LocaleSidKey = 'en_US'
            );
            insert usr; 
            usrSet.add(usr.Id);
            EmployeeUpsertUserContact.execute(usrSet);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('EmployeeUpsertUserContactTest','testEmployeeContact',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}