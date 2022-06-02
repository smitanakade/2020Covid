/*********************************************************************************
 *** @ClassName         : BusinessUnitHelper
 *** @Author		    : Rahul Ankireddypalli
 *** @Created date    	: 09/06/2021 
 *** NOTES:
        This Test Class Tests the BusinessUnitHelper insert and updates error message when a Invalid Queue Name is entered 
        which doesnot have a corresponding emailId in the Group Object


 **********************************************************************************/
@IsTest
public with sharing class BusinessUnitHelperTest {

    @IsTest
    private static void testwithQueueBadInsert(){
        // Create Business Unit Record
        Business_Unit__c buRec = new Business_Unit__c();
        buRec.Queue_Name__c = 'Test Business Unit';
        buRec.Reroute_Queue_Name__c = 'Grampians';
        try{
            Test.startTest();
            insert buRec;
            Test.stopTest();
        }
     catch(Exception err) {
        System.assert(err.getMessage().contains('Insert failed'));
        System.assert(err.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        System.assert(err.getMessage().contains('Please Enter a Valid Queue Name'));
        } 
    }

    @IsTest
    private static void testwithRerouteBadQueueInsert(){
        // Create Business Unit Record
        Business_Unit__c buRec = new Business_Unit__c();
        buRec.Queue_Name__c = 'Grampians';
        buRec.Reroute_Queue_Name__c = 'Test Business Unit';
        try{
            Test.startTest();
            insert buRec;
            Test.stopTest();
        }
     catch(Exception err) {
        System.assert(err.getMessage().contains('Insert failed'));
        System.assert(err.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        System.assert(err.getMessage().contains('Please Enter a valid Reroute Queue Name'));
        } 
    }

    @IsTest
    private static void testwithQueueBadUpdate(){
        // Create Business Unit Record
        Business_Unit__c buRec = TestDataFactory.createBusinessUnitRecord();
        buRec.Queue_Name__c = 'COVID Coordination Unit';

        try{
            Test.startTest();
            update buRec;
            Test.stopTest();
        }
     catch(Exception err) {
        System.assert(err.getMessage().contains('Update failed'));
        System.assert(err.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        System.assert(err.getMessage().contains('Queue Name doesnot have a corresponding Email id in Group object'));
        } 
    }

    @IsTest
    private static void testwithRerouteBadQueueUpdate(){
        // Create Business Unit Record
        Business_Unit__c buRec = TestDataFactory.createBusinessUnitRecord();
        buRec.Reroute_Queue_Name__c = 'COVID Coordination Unit';

        try{
            Test.startTest();
            update buRec;
            Test.stopTest();
        }
     catch(Exception err) {
        System.assert(err.getMessage().contains('Update failed'));
        System.assert(err.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        System.assert(err.getMessage().contains('Reroute Queue Name doesnot have a corresponding Email id in Group Object'));
        } 
    }

    @IsTest
    private static void testwithBothQueueIncorrectInsert(){
        // Create Business Unit Record
        Business_Unit__c buRec = new Business_Unit__c();
        buRec.Queue_Name__c = 'Test Business Unit';
        buRec.Reroute_Queue_Name__c = 'Test Business Unit1';
        try{
            Test.startTest();
            insert buRec;
            Test.stopTest();
        }
     catch(Exception err) {
        System.assert(err.getMessage().contains('Insert failed'));
        System.assert(err.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        System.assert(err.getMessage().contains('Please Enter a Valid Queue Name'));
        System.assert(err.getMessage().contains('Please Enter a valid Reroute Queue Name'));
        } 
    }

    
}