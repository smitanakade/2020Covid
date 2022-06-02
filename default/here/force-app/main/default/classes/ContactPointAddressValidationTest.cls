@isTest
public with sharing class ContactPointAddressValidationTest {
    @isTest
    public static void testContactPointAddressValidation(){
        Account personAc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        ContactPointAddress CPA1 = TestDataFactory.createCPARecord(personAc,1,false).get(0);
        CPA1.Save_with_blank_Active_To_Date__c = true;
        insert CPA1;

        String CPAMessage1 = ContactPointAddressValidation.getMessage(CPA1.id);
        System.assertEquals(CPAMessage1, 'By not setting "Active To date", this address may be taken as current address');
        
        ContactPointAddress CPA2 = TestDataFactory.createCPARecord(personAc,1,false).get(0);
        CPA2.Save_with_blank_Active_To_Date__c = true;
        insert CPA2;

        String CPAMessage2 = ContactPointAddressValidation.getMessage(CPA2.id);
        System.assertEquals(CPAMessage2, 'Please populate "Active To Date" in previous Contact Point Address entries if required');

    }
}

