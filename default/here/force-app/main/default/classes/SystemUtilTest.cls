/**
 * @Author             : YPerera
 * @Description        : Test class for SystemUtils
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 26/10/2021     YPerera		        Created
**/

@isTest
private class SystemUtilTest {
    
    @isTest
    static void testGetPickListValuesInObjectAsMap() {
        Map<String, String> results = SystemUtils.getPickListValuesInObjectAsMap('Case', 'Status');
		System.assert(results != null);        
    }
    
    @isTest
    static void testGetPickListValuesInObjectAsJSON() {
        String results = SystemUtils.getPickListValuesInObjectAsJSON('Case', 'Status');
        System.assert(results != null);        
    }
    
    @isTest
    static void testGetFieldLabelInObject() {
        String result = SystemUtils.getFieldLabelInObject('Case', 'Status');
        System.assert(result != null);        
    }
    
    @isTest
    static void testGetSobjectRecordFieldValue() {
        Account a = new Account(Name = 'Test');
        insert a;
        
        a = [SELECT Name FROM Account WHERE Id = :a.Id];
        
        String result = SystemUtils.getSobjectRecordFieldValue('Account', 'Name', a.Id);
        System.assertEquals('Test', result);
    }
    
    @isTest
    static void testGetSobjectRecordFieldValueFromRelatedObject() {
        Account a = new Account(Name = 'Test');
        insert a;
        
        a = [SELECT Name FROM Account WHERE Id = :a.Id];
        
        Case c = new Case(AccountId = a.Id);
        insert c;
        
        String result = SystemUtils.getSobjectRecordFieldValueFromRelatedObject('Case', 'Account', 'AccountId', 'Name', c.Id);
        System.assertEquals('Test', result);
    }
    
    
    
    
    
    

}