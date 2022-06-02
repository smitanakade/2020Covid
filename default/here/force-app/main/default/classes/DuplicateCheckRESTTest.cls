/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : Test class - DuplicateCheckRESTTest
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 07/02/2021     Darko Jovanovic       Hotfix 258459 (Addition of dcUpsert method): Initial version
**/
@isTest
private class DuplicateCheckRESTTest {
    
    // The actual service itself is tested heavily in DuplicateCheckServiceTest. We just test the call here
    @isTest
    static void testDcUpsertService() {
        // Create an account
        Account personAccount = TestDataFactory.createAccount(1, 'Active','Person Account')[0];
        // Create a new account. As Dupe Check uses SOSL, this new account won't be identified as a dupe since we're not setting Test.setFixedSearchResults
        Account newAccount = TestDataFactory.createAccount(1, 'Active','Person Account')[0];
        // Call the service
        DuplicateCheckREST.dcUpsert(newAccount, 85, true);
    }

}