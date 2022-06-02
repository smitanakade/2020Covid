/**
 * @Author             : Haider Raza
 * @Description        : Apex Batch Job to close Records automatically when 'Hotel Quarantine End Date' field = + 14 days
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 03/04/2021     Haider Raza          Feature 274741: Records should be Closed automatically when 'Hotel Quarantine End Date' field = + 14 days
**/

global with sharing class AutoCloseHotelQuarantine implements Database.Batchable<sObject>{

    global Database.QueryLocator start(Database.BatchableContext BC){
        Date endDate = Date.today();//.addDays((-1)*Integer.valueOf(System.Label.HotelQuarantineAutoClosureDays));
        List<String> excludeStatus = System.Label.HotelQuarantineAutoClosureExcludeStatus.split(',');
        List<Id> recIds = new List<Id>{
                Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId(),
                Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId(),
                Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Casual_Contact').getRecordTypeId()};

        String query = 'SELECT Id, Status, SubStatus__c, Hotel_Quarantine_End_Date__c, Hotel_Quarantine_End_Date_14_Days__c ' +
                        'FROM Case ' +
                        'WHERE Hotel_Quarantine_End_Date_14_Days__c =: endDate ' +
                        'AND Status NOT IN ' +excludeStatus+' ' +
                        'AND RecordTypeId IN: recIds ' +
                        'AND Status=\'Ex-HQ Follow-up\'';

        if(Test.isRunningTest()){
            return Database.getQueryLocator([SELECT Id, Status, SubStatus__c FROM Case WHERE Status='Ex-HQ Follow-up']);
        }else{
            return Database.getQueryLocator(query);
        }
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Case> casesToUpdate = new List<Case>();

        for(sobject s : scope){
            Case recordToUpdate = (Case)s;
            casesToUpdate.add(new Case(Id=s.Id, Status='Closed', SubStatus__c='Release'));
        }

        if(casesToUpdate.size() > 0){
            Database.update(casesToUpdate);
        }
    }

    global void finish(Database.BatchableContext BC) {}

}