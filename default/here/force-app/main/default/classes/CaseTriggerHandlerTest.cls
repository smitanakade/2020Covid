/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : CaseTriggerHandler test class
 * @Modification Log   :  
 * ---------------------------------------------------
 * Date           Author      		    Details 
 * ---------------------------------------------------
 * 29/11/2020     Darko Jovanovic       Feature 230036: Duplicate Check tool implementation - initial version
 * 09/04/2021     Pratyush Chalasani    Hotfix 276114: Update Case trigger to capture merged CaseNumber values synchronously
 * 09/07/2021     Sai Kallu      	    Feature 277236: Cross Border Notifications - Identification
 * 20/09/2021     Pratyush Chalasani   Feature 323048: Shift trigger functions to dcPluginMerge (removed code from here)
**/
@isTest
public class CaseTriggerHandlerTest {

    @testSetup static void setup() {
        // Create common test accounts
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'name';
        validEmailTemplate.DeveloperName = 'unique_name_addSomethingSpecialHere';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.FolderId = UserInfo.getUserId();
        insert validEmailTemplate;   
    }

    // Since classes called by the handler have their own test classes, we just need to ensure test coverage for the handler. 
    // As such, it'll be a very simple test
    @isTest
    static void testCoverage() {
        // Create Person Account
        List<Account> personAccList = TestDataFactory.createAccount(1, 'Active','Person Account');
        // Create case for the person and then update it
        List<Case> caseListExp = TestDataFactory.createCases(personAccList.get(0), 1, 'Isolate', 'Exposure Management');
        caseListExp[0].Subject = 'Test - Update';
        update caseListExp;
    }

    @isTest
    static void testbatchInsert() {
        // Create Person Account
        List<Account> personAccList = TestDataFactory.createAccount(40, 'Active','Person Account');
        // Create case for the person and then update it
        List<Account> resultList=[Select id from Account];
        System.assertEquals(40, resultList.size());
        List<Case> accountToInsert = new List<Case>();
        for(Account a : personAccList) {
            //282278: Updated Status to "Active" and Substatus to null
            List<Case> caseListExp = TestDataFactory.createCasesNoInsert(a, 1, 'Active', 'Casual Contact');
            caseListExp[0].Subject = 'Test - Update';
            caseListExp[0].SubStatus__c = null;
            accountToInsert.add(caseListExp[0]);
        }

        Test.startTest();
        insert accountToInsert;
        Test.stopTest();
    }

    @isTest
    static void testvalidateCrossBorderIdentificationFlags() {
        // Insert account and then update it
        Test.startTest();
        List<Account> accountList = TestDataFactory.createAccount(1, 'Active','Person Account');
        list<case> closeConList = TestDataFactory.createCases(accountList[0], 1, 'Quarantine', 'Close Contact');
        list<case> conCaseList = TestDataFactory.createCases(accountList[0], 1, 'Quarantine', 'COVID-19 Case Assessment');
        list<case> expMList = TestDataFactory.createCases(accountList[0], 1, 'Quarantine', 'Exposure Management');
        closeConList[0].Requires_cross_border_data_transfer__c = True;
        closeConList[0].Cross_border_data_transfer_complete__c = True;
        update closeConList;
        conCaseList[0].Cross_border_data_transfer_complete__c = False;
        update conCaseList;
        system.assertNotEquals(Null, accountList);
        list<string> toAddresses  = new list<string>();
        //Added in order to cover email message triggering
        toAddresses.add(userInfo.getUserEmail());
        emailTemplate validEmailTemplate = [SELECT DeveloperName, OwnerId, Id, Name, IsActive, Subject, HtmlValue, Body FROM EmailTemplate where Name = 'name']; 
        Messaging.SingleEmailMessage sm = CrossBorderNotificationEmail.sendEmail(validEmailTemplate,conCaseList[0].Id, toAddresses);
        Test.stopTest();
        system.assertNotEquals(Null, sm);
        system.assertNotEquals(Null, accountList); 
    }
     
}