/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : AccountTriggerHandler test class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 29/11/2020     Darko Jovanovic       Feature 230036: Duplicate Check tool implementation - initial version
 * 23/06/2021     Sai Kallu      	   Feature 277236: Cross Border Notifications - Identification
**/
@isTest
public class AccountTriggerHandlerTest {

    // Since classes called by the handler have their own test classes, we just need to ensure test coverage for the handler. 
    // As such, it'll be a very simple test
    @isTest
    static void testCoverage() {
        // Insert account and then update it
        List<Account> accountList = TestDataFactory.createAccount(1, 'Active','Person Account');
        accountList[0].FirstName = 'Test - Update';
        update accountList;
    }
    /** 
    @isTest
    static void testCoverage2() {
        // Insert account and then update it
        List<Account> accountList = TestDataFactory.createAccount(1, 'Active','Person Account');
        accountList[0].FirstName = 'Test - Update';
        update accountList;
        list<case> closeConList = TestDataFactory.createCases(accountList[0], 1, 'Quarantine', 'Close Contact');
        list<case> conCaseList = TestDataFactory.createCases(accountList[0], 1, 'Quarantine', 'COVID-19 Case Assessment');
        list<case> expMList = TestDataFactory.createCases(accountList[0], 1, 'Quarantine', 'Exposure Management');
        accountList[0].Requires_cross_border_data_transfer__c = True;
        accountList[0].Cross_border_data_transfer_complete__c = True;
        update accountList;
        accountList[0].Cross_border_data_transfer_complete__c = False;
        update accountList;
        system.assertNotEquals(Null, accountList);
    }
    **/

}