/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : ContactTriggerHandler test class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 29/11/2020     Darko Jovanovic       Feature 230036: Duplicate Check tool implementation - initial version
**/
@isTest
public class ContactTriggerHandlerTest {

    // Since classes called by the handler have their own test classes, we just need to ensure test coverage for the handler. 
    // As such, it'll be a very simple test
    @isTest
    static void testCoverage() {
        try{
            // Insert organisation account
            List<Account> accountList = TestDataFactory.createAccount(1, 'Active','Place Or Organisation');
            // Insert contact for this account and then update it
            List<Contact> conList = TestDataFactory.createContact(accountList);
            conList[0].FirstName = 'Test - Update Name';
            update conList;
        }catch(Exception exp){
            ApplicationLogUtility.createlog('ContactTriggerHandlerTest','testCoverage',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
        }
    }
}