/**
* @Author             : Sai Kallu
* @Description        : currentAddressReportCOntroller test class
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author      		    Details 
* ---------------------------------------------------
*09/10/2021		 Sai Kallu			  Feature 308700 : New LWC Component to show current address on report
**/


@isTest
public class currentAddressReportControllerTest {
    
    @isTest
    static void testrecordAddress(){
        
        
        List<Account> personAccList = TestDataFactory.createAccount(3, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 4, 'Isolate', 'COVID-19 Case Assessment');
        Case caseRecord = caseListExp[0];
        
        //Create CPAS 
        List<ContactPointAddress> cpas = TestDataFactory.createCPAsforaccount(personAccList.get(0),'Work',Date.today(),2);
        
        //create a Health Care Encounter
        List<HealthCloudGA__EhrEncounter__c> encounters = TestDataFactory.createHospitalRecordsForCases(caseListExp, 'Hospital admission', Date.today());
        list<currentAddressReportController.addresswrapper> aw = new list<currentAddressReportController.addresswrapper> ();
        
        Case caseRecord2 = caseListExp[1];
        caseRecord2.CurrentAddressId__c = cpas[0].Id;
        caseRecord2.CurrentAddressType__c = 'CPA';
        Case caseRecord3 = caseListExp[2];
        caseRecord3.CurrentAddressId__c = encounters[0].Id;
        caseRecord3.CurrentAddressType__c = 'HMIP';
        Case caseRecord4 = caseListExp[3];
        caseRecord4.CurrentAddressId__c = personAccList[0].Id;
        caseRecord4.CurrentAddressType__c = 'PRA';
        update caseListExp;
        
        Account account = personAccList.get(1);
        test.startTest();
        List<ContactPointAddress> cpas2 = TestDataFactory.createCPAsforaccount(personAccList.get(2),'Discharge',Date.today(),2);
        List<Case> caseListExp2 = TestDataFactory.createCases(account, 4, 'Isolate', 'COVID-19 Case Assessment');
        List<ContactPointAddress> cpas3 = TestDataFactory.createCPAsforaccount(personAccList.get(1),'Work',Date.today(),2);
        Account acc = personAccList[1];
        acc.PersonMailingStreet='';
        acc.PersonMailingPostalCode=''; 
        acc.PersonMailingCity=''; 
        acc.ShippingCountry = '';
        acc.ShippingCity = '';
        acc.ShippingStreet = '';
        acc.ShippingPostalCode = '';
        update acc;
        
        List<Case> caseListExp3 = TestDataFactory.createCases(personAccList[2], 4, 'Isolate', 'COVID-19 Case Assessment');
        List<HealthCloudGA__EhrEncounter__c> encounters2 = TestDataFactory.createHospitalRecordsForCases(caseListExp3, 'Hospital admission', Date.today());
        List<Account> nonPersonAccountLst = TestDataFactory.createAccount(2,'Active','Household', SYSTEM.now());
        Account nonPersonAccount = nonPersonAccountLst[0];
        nonPersonAccount.ShippingCountry = 'AUS';
        nonPersonAccount.ShippingCity = 'Mel';
        nonPersonAccount.ShippingStreet = 'abc';
        nonPersonAccount.ShippingPostalCode = '3000';
        update nonPersonAccount;
        encounters2[0].HealthCloudGA__Account__c =  nonPersonAccountLst[0].Id;
        update encounters2[0];
        Account account2 = nonPersonAccountLst[0];
        account2.PersonMailingStreet='';
        account2.PersonMailingPostalCode=''; 
        account2.PersonMailingCity=''; 
        update account2;
        encounters[0].HealthCloudGA__Account__c = account2.Id;
        update encounters[0];
        date d = system.today();
        date d1 = system.today().adddays(-3);
        string startDate = string.valueOf(d1);
        string endDate = string.valueOf(d);
        aw.addall(currentAddressReportController.getRecordList('Confirmed Case', startDate, endDate));
        aw.addall(currentAddressReportController.getRecordList('Close Contact', startDate, endDate));
        test.stoptest();
        
    }
    
    
}