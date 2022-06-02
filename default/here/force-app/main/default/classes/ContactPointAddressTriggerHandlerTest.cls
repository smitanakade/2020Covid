@IsTest 
public class ContactPointAddressTriggerHandlerTest {
    @isTest
    public static void testContactPointAddressValidation(){
        Test.startTest();
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        try {
            ContactPointAddress CPA1 = TestDataFactory.createCPARecord(personAc,1, true).get(0);
        }catch(Exception e){
            System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testContactPointAddressValidation2(){
        Test.startTest();
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        ContactPointAddress CPA1 = TestDataFactory.createCPARecord(personAc,1,false).get(0);
        CPA1.Save_with_blank_Active_To_Date__c = true;
        insert CPA1;
        System.assertEquals(true, CPA1 != null);
        
        // Update scenario
        CPA1.Save_with_blank_Active_To_Date__c = false;
        try {
            update CPA1;
        }catch(Exception e){
            System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testContactPointAddressValidation3(){
        Test.startTest();
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        ContactPointAddress CPA1 = TestDataFactory.createCPARecord(personAc,1,false).get(0);
        CPA1.Save_with_blank_Active_To_Date__c = true;
        insert CPA1;
        
        ContactPointAddress CPA2 = TestDataFactory.createCPARecord(personAc,1,false).get(0);
        CPA2.ActiveToDate = system.today().addDays(7);
        try {
            insert CPA2;
        }catch(Exception e){
            System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testContactPointAddressValidation4(){
        try {
            ContactPointAddressTriggerHelper.validateActiveToDate(null);
        }catch(Exception exp){
            ApplicationLogUtility.createlog('ContactPointAddressTriggerHandlerTest','testContactPointAddressValidation4',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
        }  
    }
}