/**
* @Author             : DHHS
* @Description        : Account trigger helper
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 05/08/2021     Smita Kagde           PBI-308974 Marketing Cloud - Ensure phone formatting retained on update from frontend
* 26/08/2021     Pratyush Chalasani    Feature 305103: Address Management - ELR merge rules
* 06/09/2021     Pratyush Chalasani    Bugfix 318957:  CPA address with ELR is not created when person account primary address is different to incoming ELR primary address
* 20/09/2021     Pratyush Chalasani   Feature 323048: Shift trigger functions to dcPluginMerge (removed code from here)
* 12/11/2021     Arun                 Bugfix : 336523 : Update the task creation with WhoID and Recordtype
* 
**/
public class AccountTriggerHelper {
    Public static void modifyPersonMobileNumber(List<Account> newAcc ){
        String phone='';
        String otherPhone='';
        List<Account> updateAcc = new List<Account>();
        for(Account acc : newAcc ){
            if(acc.PersonMobilePhone != null){
                phone = acc.PersonMobilePhone.replaceAll('[A-Za-z\\D]','');
                if (acc.PersonMobilePhone != phone){
                        acc.PersonMobilePhone =  phone;
                }                  
                    acc.PersonMobilePhone = remUnwantedNumber(acc.PersonMobilePhone);                                      
            }
            if(acc.Other_Mobile_Phone__c != null){
                otherPhone = acc.Other_Mobile_Phone__c.replaceAll('[A-Za-z\\D]','');
                if (acc.Other_Mobile_Phone__c != otherPhone){
                        acc.Other_Mobile_Phone__c =  otherPhone;
                }
                    acc.Other_Mobile_Phone__c = remUnwantedNumber(acc.Other_Mobile_Phone__c);                     
                }
            acc.Phone = acc.PersonMobilePhone;
            updateAcc.add(acc);
            }           
        }
        Public Static String remUnwantedNumber(String givenphoneNo){
            if(givenphoneNo != null){
            if(givenphoneNo.startsWith('004')||givenphoneNo.startsWith('04') || givenphoneNo.startsWith('4')){
                if(givenphoneNo.startsWith('04')){                      
                        givenphoneNo= '61'+givenphoneNo.substring(1,givenphoneNo.length());
                }
                else if(givenphoneNo.startsWith('004')){ 
                    givenphoneNo= '61'+givenphoneNo.substring(2,givenphoneNo.length());
                }else if(givenphoneNo.startsWith('4')){ 
                    givenphoneNo= '61'+givenphoneNo;
                }
            }
            }
        return givenphoneNo;
            
    }
    /**
     * @description createTaskforCulturalSupportOfficer - Executed from a Async handler method
     * @param  accountList  List of new Accounts
     * @param  oldSObjectMap List of old map
     */ 
    public static void createTaskforCulturalSupportOfficer(List<Account> accountList,Map<Id,SObject> oldSObjectMap){
     
        Map<Id,Account> newAccountMap=new Map<Id,Account>();
        Map<Id,Account> oldaccountMap=new Map<Id,Account>();
        if(!accountList.isEmpty()){
            for(Account accRecord : accountList){
                newAccountMap.put(accRecord.Id,accRecord);
            }
        }

        if(oldSObjectMap!=null){
            for(Account acc:(List<Account>)oldSObjectMap.values()){
                oldaccountMap.put(acc.Id,acc);
            }
            if(newAccountMap!=null){
                createTaskforCulturalSupportOfficer(newAccountMap,oldaccountMap);
            }
        }
        else{
            if(newAccountMap!=null){
                createTaskforCulturalSupportOfficer(newAccountMap,null);
            }
        }

    }

    /**
    * @description create Task for Cultural Support Officer
    * @param newaccountMap 
    * @param oldaccountMap 
    **/
    public static void createTaskforCulturalSupportOfficer(Map<Id,Account> newaccountMap,Map<Id,Account> oldaccountMap){
        Map<Id,Id> accountToRecordMap=new Map<Id,Id>();
        List<Task> taskList=new List<Task>();
        Set<Id> existingCasewithTasks=new Set<Id>();

        Id queueId=getQueueID(Label.Aboriginal_Health_Officer_Queue_Name);
        if(oldaccountMap==null){oldaccountMap = new Map<Id,Account>();}
        //Create a map of Accounts and cases
        for(Case caseRec : [select Id,Accountid from Case where AccountID IN : newaccountMap.keySet() order by LastModifiedDate DESC]){
            if(!accountToRecordMap.ContainsKey(caseRec.AccountId)){
                accountToRecordMap.put(caseRec.AccountId,caseRec.Id);
            }
          
        }

         //Check if there is already an existing Task
        for(Task taskRec : [select whatID,Id ,AccountID from Task where Subject = : Label.Aborginal_Health_Officer_Task_Subject AND 
                                whatID IN :accountToRecordMap.values() ]){
            
                existingCasewithTasks.add(taskRec.WhatId);
            }

    try{
                    if(accountToRecordMap!=null){
                    for(Account accRec: newaccountMap.values()){
                        if((accountToRecordMap.get(accRec.Id)!=null && 
                            oldaccountMap.get(accRec.Id)==null || 
                            oldaccountMap.get(accRec.Id).Cultural_Support_Officer_Required__c!= newaccountMap.get(accRec.Id).Cultural_Support_Officer_Required__c) &&
                            newaccountMap.get(accRec.Id).Cultural_Support_Officer_Required__c=='Yes' &&
                            !existingCasewithTasks.contains(accountToRecordMap.get(accRec.Id))){
                                //Create Task
                                System.debug('Create Task:' + accRec);
                                taskList.add(setAborginalTaskValues(accountToRecordMap.get(accRec.Id),queueId,accRec.PersonContactId));
                            }
                    }
                }
                    if(!taskList.isEmpty()){
                        insert taskList;
                    }
                }

    catch(Exception exp){
        
        ApplicationLogUtility.createlog('AccountTriggerHelper','createTaskforCulturalSupportOfficer',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
    }
    

}

private static Task setAborginalTaskValues(Id RelatedToId,Id queueId,ID whoIDRec ){
    Task taskRec=new Task();
    taskRec.Subject=Label.Aborginal_Health_Officer_Task_Subject;
    taskRec.WhatId=RelatedToId;
    taskRec.Manually_Allocated__c=true;
    taskRec.type='Follow up';
    taskRec.Status='Not Started';
    //Update whoID and Recordtype
    taskRec.WhoID=whoIdRec;
    taskRec.RecordTypeId=Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Log_A_Call').getRecordTypeId();
    if(queueId!=null || queueId!=''){
        taskRec.OwnerId=queueId;
    }
   return taskRec;
}

public static Id getQueueID(String QueueName){

  //  Id groupId;
    Id groupId= [select Id,Name,Type  from Group where DeveloperName = :QueueName and Type='Queue' Limit 1].Id;
    return groupId;
}
}