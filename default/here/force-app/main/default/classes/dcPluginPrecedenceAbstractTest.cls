/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : Base class for applying field precedence rules. 
 *                       It is envisaged that for each field where precedence rules are needed, corresponding class will be created extending this class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 11/02/2021     Darko Jovanovic   Hotfix 258342 (Custom Merge Rules): Initial version
**/
@isTest
private class dcPluginPrecedenceAbstractTest {
    
    @isTest
    static void testApplyPrecedenceRule() {
        // Create 7 accounts and set a different created date for them, in chronological order
        List<Account> personAccountList = TestDataFactory.createAccount(7, 'Active','Person Account');
        Test.setCreatedDate(personAccountList[0].Id, DateTime.newInstance(2013,12,12));
        Test.setCreatedDate(personAccountList[1].Id, DateTime.newInstance(2014,12,12));
        Test.setCreatedDate(personAccountList[2].Id, DateTime.newInstance(2015,12,12));
        Test.setCreatedDate(personAccountList[3].Id, DateTime.newInstance(2016,12,12));
        Test.setCreatedDate(personAccountList[4].Id, DateTime.newInstance(2017,12,12));
        Test.setCreatedDate(personAccountList[5].Id, DateTime.newInstance(2018,12,12));
        Test.setCreatedDate(personAccountList[6].Id, DateTime.newInstance(2019,12,12));
        // Set middle name
        personAccountList[0].MiddleName = 'Test2';
        personAccountList[1].MiddleName = 'Test1';
        personAccountList[2].MiddleName = 'Test1';
        personAccountList[3].MiddleName = '';
        personAccountList[4].MiddleName = 'Test1'; // this is the one that should be picked (highest priority, latest date of that priority)
        personAccountList[5].MiddleName = 'Test2';
        personAccountList[6].MiddleName = 'Test3'; // this is the one that would've been picked by default merge rules (e.g. last created). However, it's not of highest priority so it should be overriden
        update personAccountList;
        Test.startTest();
        // Re-do the query to get created dates
        Map<Id, Account> recordByIdMap = new Map<Id, Account>();
        personAccountList = 
            [SELECT Id, MiddleName, CreatedDate 
            FROM Account 
            WHERE Id In :personAccountList];
        for (Account acc : personAccountList) {
            recordByIdMap.put(acc.Id, acc);
        }
        // Set the default result of the merge rules (last created)
        Map<String, Id> defaultResultMap = new Map<String, Id>();
        defaultResultMap.put('MiddleName', personAccountList[6].Id);
        dupcheck.dc3PluginModel.MergeSetFieldInput input = new dupcheck.dc3PluginModel.MergeSetFieldInput('001P', personAccountList[0].Id, defaultResultMap, personAccountList);
        dupcheck.dc3PluginModel.MergeSetFieldOutput output = new dupcheck.dc3PluginModel.MergeSetFieldOutput(input);
        // Now calculate the precedence and verify the record id from which to pick the value from was changed correctly
        (new MiddleNamePrecedenceClass()).applyPrecedenceRule(personAccountList, recordByIdMap, 'MiddleName', output);
        Test.stopTest();
        System.assertEquals(personAccountList[4].Id, output.fieldSourceMap.get('MiddleName'));
    }

    // Abstract class implementation used for testing purposes
    private class MiddleNamePrecedenceClass extends dcPluginPrecedenceAbstract {
        public override Integer getFieldPrecedence(String val) {
            Integer precedence;
            switch on val {
                when 'Test1' {
                    precedence = 1;
                }
                when 'Test2' {
                    precedence = 2;
                }
                when null {
                    precedence = 999;
                }
                when else {
                    precedence = 3;
                }
            }
            return precedence;
        }
    } 

}
