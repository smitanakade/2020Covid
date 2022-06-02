/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : UtilityClass test class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 06/02/2021     Darko Jovanovic       Hotfix 258459 (Addition of dcUpsert method): Initial version
**/
@isTest
private class UtilityClassTest {
    
    @isTest
    static void testGetAllFieldsForQuery() {
        String accountFields = UtilityClass.getAllFieldsForQuery('Account');
        System.assert(accountFields != null);
    }

}
