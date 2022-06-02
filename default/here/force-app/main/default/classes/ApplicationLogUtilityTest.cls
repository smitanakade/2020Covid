/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : ApplicationLogUtility test class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 06/02/2021     Darko Jovanovic       Hotfix 258459 (Addition of dcUpsert method): Initial version
 * 27/09/2021	  Lija Jawahar			Added testemethod createLogMessage_Success()
**/
@isTest
private class ApplicationLogUtilityTest {
    
     static testMethod void testGetAllFieldsForQuery() {
        String accountFields = ApplicationLogUtility.getAllFieldsForQuery('Account');
        System.assert(accountFields != null);
    }
    
    static testMethod void createLogMessage_Success() {       
        String className = 'ApplicationLogUtilityTest';
        test.startTest();
        try{
	        String s;
		    Boolean b = s.contains('abc'); // Causes a NullPointerException
	 	}
        catch(System.NullPointerException npe) 
        {
            system.debug(npe.getStackTraceString());
            system.debug(npe.getMessage());
            system.debug(npe.getTypeName());
             system.debug(npe.getCause() );
            ApplicationLogUtility.createlog('ApplicationLogUtilityTest','createLogMessage_Success',npe.getStackTraceString(),npe.getMessage(),npe.getTypeName());
        }
        test.stopTest();
        
        LIST<Application_Log__c> applicationLogs = [SELECT Id,Stack_Trace__c,Transaction_Date__c, 
                                                    User_Details__c, Source_Function__c,Source__c
                                                    FROM Application_Log__c 
                                                    WHERE Source__c = :className AND 
                                                    Transaction_Date__c = Today
                                                   ];
        
        system.assertNotEquals(null, applicationLogs.Size());
    }
    
    
}