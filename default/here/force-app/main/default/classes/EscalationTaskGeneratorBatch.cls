/**
 * @Author             : marcelo.cost
 * @Description        : No response survey task generator - daily batch
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 17/12/2020     marcelo.cost        Initial version
 * 29/04/2021     Hemant Singh        Bugfix 275334: Consider Opt out of SMS
**/

public with sharing class EscalationTaskGeneratorBatch implements Database.Batchable <sObject>, Database.Stateful{

    public final Id  CONFIRMED_CASE_RECORDTYPE = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
    public final Id  CLOSECONT_CASE_RECORDTYPE = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
    public final Id  SECCLOSEC_CASE_RECORDTYPE = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Secondary Close Contact').getRecordTypeId();
    public final set<Id> CASE_RECORDTYPES = new Set<Id>{CONFIRMED_CASE_RECORDTYPE,CLOSECONT_CASE_RECORDTYPE,SECCLOSEC_CASE_RECORDTYPE};

    public Database.QueryLocator start(Database.BatchableContext BC){

        DateTime limitDate= Datetime.now().addDays(-2);

        return Database.getQueryLocator([Select Id,Last_Check_in_Date__c,Status,RecordTypeId,OwnerId,Account.PersonHasOptedOutOfSMS__c,Account.PersoncontactID from Case WHERE
        RecordTypeId IN :CASE_RECORDTYPES
        AND Last_Check_in_Date__c < :limitDate
        AND Account.PersonHasOptedOutOfSMS__c = False
        AND (Status='Quarantine' OR Status='Isolate')
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Case> scope){
        List<Task> tasksToInsert = new List<Task>();
        try{
            for(Case aCase : scope ){
                Task newCall = new Task(Subject='No response survey', TaskSubtype='Call', OwnerId=aCase.OwnerId,WhatId= aCase.Id,WhoId=aCase.Account?.PersonContactId, ActivityDate=Date.today());
                tasksToInsert.add(newCall);
            }
            insert tasksToInsert;
        }catch(Exception exp){
            ApplicationLogUtility.createlog('EscalationTaskGeneratorBatch','execute',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }

    //Any post processing steps here
    public void finish(Database.BatchableContext BC){
    }

}