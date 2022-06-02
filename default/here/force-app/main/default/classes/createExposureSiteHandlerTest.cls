/**
 * @Author             : Sukumar
 * @Description        : createExposureSiteHandler test class
 * @Modification Log   :  
 * ---------------------------------------------------
 * Date           Author      		    Details 
 * ---------------------------------------------------
*18/11/2021		 Sukumar			  Feature 332971-OBM - New Exposure Site creation from Case Movement/Contact Encounter screens Pt1
**/
@isTest
public class createExposureSiteHandlerTest { 
    @isTest
    static void testContactEncounterData(){
        
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        List<Account> orgAccList = TestDataFactory.createAccount(5, 'Active','Place Or Organisation');
        List<Case> caseListCCC = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'COVID-19 Case Assessment');
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Exposure Management');
        Case caseRecord = caseListCCC[0];
        Case expMgmtRecord = caseListExp[0];

        List<Contact> conList = TestDataFactory.createContact(orgAccList);
  
        List<ContactEncounter> conEncList = TestDataFactory.createContactEncounter(conList);           
        
        contactEncounter ce = createExposureSiteHandler.getContactEncounter(string.valueOf(conEncList[0].Id));
        System.assertEquals(true, ce != null);

        contactEncounter updatedce = createExposureSiteHandler.updateContactEncounter(string.valueOf(expMgmtRecord.Id), string.valueOf(conEncList[0].Id));
        contactEncounter uce = [Select id, Exposure_Site_ID__c from contactEncounter WHERE id=: updatedce.Id];
        System.assertEquals(true, uce.Exposure_Site_ID__c != null);
       
        
    }

}