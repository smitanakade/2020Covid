/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : Test class - DuplicateCheckMergeREST
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 07/02/2021     Darko Jovanovic       Hotfix 258459 (Addition of dcMerge method): Initial version
**/
@isTest
private class DuplicateCheckMergeRESTTest {
    
    // The actual service itself is tested heavily in DuplicateCheckServiceTest. We just test the call here
    @isTest(SeeAllData=true)
    static void testDcMergeService() {
        // Create an account
        Account personAccount = TestDataFactory.createAccount(1, 'Active','Person Account')[0];
        // Create a new account
        Account newAccount = personAccount.clone(false, true);
        // Call the service
        DuplicateCheckMergeREST.dcMerge(newAccount, new List<Id>{personAccount.Id});
    }

}