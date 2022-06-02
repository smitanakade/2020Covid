/**
 * @Author             : Santosh
 * @Description        : recordAddressHandler test class
 * @Modification Log   :  
 * ---------------------------------------------------
 * Date           Author      		    Details 
 * ---------------------------------------------------
*30/08/2021		 Santosh			  Feature 307648 : New LWC Component to show current address on record
**/
@isTest
public class recordAddressHandlerTest {
    
    
    @isTest
    static void testrecordAddress(){
        
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        Case caseRecord = caseListExp[0];
        recordAddressHandler.fetchaddress(caseListExp[0].id);
        //Create CPAS 
        List<ContactPointAddress> cpas = TestDataFactory.createCPAsforaccount(personAccList.get(0),'Work',Date.today(),2);
        recordAddressHandler.fetchaddress(caseListExp[0].id);
        //create a Health Care Encounter
        List<HealthCloudGA__EhrEncounter__c> encounters = TestDataFactory.createHospitalRecordsForCases(caseListExp, 'Hospital admission', Date.today());
        recordAddressHandler.fetchaddress(caseListExp[0].id);
        
        recordAddressHandler.updatecurrentid(caseListExp[0].id, cpas[0].id, 'CPA');
        recordAddressHandler.fetchaddress(caseListExp[0].id);
        recordAddressHandler.updatecurrentid(caseListExp[0].id, encounters[0].id, 'HMIP');
        recordAddressHandler.fetchaddress(caseListExp[0].id);
        recordAddressHandler.updatecurrentid(caseListExp[0].id, personAccList[0].id, 'PRA');
        recordAddressHandler.fetchaddress(caseListExp[0].id);
        recordAddressHandler.updateprimaryresidentialaddress(personAccList[0].id,'Teststreet','Testcity','testcountry','teststate','2134',false);
        recordAddressHandler.fetchPRAAddress(personAccList[0].id);
        recordAddressHandler.fetchCPAAddress(cpas[0].id);
        
    }

}