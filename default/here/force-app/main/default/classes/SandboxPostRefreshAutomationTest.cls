@isTest
public class SandboxPostRefreshAutomationTest {
    
    static testMethod void testCopyScript() {
        Test.startTest();
        SandboxPostRefreshAutomation targetClass = new SandboxPostRefreshAutomation();
        Test.testSandboxPostCopyScript(targetClass, UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
         Test.stopTest();
     
    }
    
     @isTest
	static void testcreateAccount() {
         
        Id brecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Place Or Organisation').getRecordTypeId();
            Account account = new Account();
            account.RecordTypeId=brecordTypeId;
           account.Name  = 'Victorian Health Workers';
            account.Type ='Victorian Health Workers';
        
        Test.startTest();
        insert account;
        List<Account> lstacc = [select id from Account where id =:account.id  ];
        Test.stopTest();        
		system.assertEquals(1,lstacc.size()); //This assert checks if Account record is created in system or not.        
    }
}