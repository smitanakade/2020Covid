@isTest
public class AccountAddressValidationBatchTest {
    
    @testSetup
    static void setupTestData() {
        try{
            Id accountRecordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
            Account accountRecord = new Account(RecordTypeID=accountRecordTypeId  , FirstName='\'FName\'', LastName='\'LName\'',PersonMailingStreet='101 Collins Street',
                    PersonMailingPostalCode='3000', PersonMailingCity='Melbourne', PersonMailingState='VIC', AddressValidationStatus__c='Pending');
            insert accountRecord;
        }catch(Exception exp){
            ApplicationLogUtility.createlog('AccountAddressValidationBatchTest','setupTestData',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
        
    }
    
    @isTest static void AccountAddressValidationBatchTest01() {
        try{
            Test.startTest();
            
            AccountAddressValidationBatch b = new AccountAddressValidationBatch();
            database.executebatch(b, 25);
            
            Test.stopTest(); 
            
            List<Account> acc =[Select Id, FirstName, LastName, AddressValidationStatus__c From Account Where AddressValidationStatus__c != 'No Match' AND FirstName = '\'FName\''];
            System.assertEquals(acc.size(), 1);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('AccountAddressValidationBatchTest','AccountAddressValidationBatchTest01',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}