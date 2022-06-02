/*********************************************************************************
 *** @ClassName         : NotesServiceTest
 *** @Author		    : DBridges
 *** @Created date    	: 16/03/2021

 **********************************************************************************/
@isTest
public with sharing class NotesServiceTest {
    @isTest
    private static void NotesServiceTest() {
        Account acc = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        Test.startTest();
        ContentVersion ver = NotesService.generateNoteforObjectId(acc.Id, 'this is the body', 'title');
        System.assertEquals('title', ver.Title);

    }
}
