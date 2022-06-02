/**
* @Author             : Sai Kallu
* @Description        : CurrentAddressReportController
* @Modification Log   :
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
*6/10/2021     Sai Kallu  Feature 308700 : New LWC Component to show current address on report(LWC)
*08/12/2021    Sai Kallu  Feature 341410 : Enhancement to Custom Current Address Report for HEP

**/


public with sharing class currentAddressReportController {
    
    /*************************************************
* fetchaddress - Method  to generate the addresswrapper to be returned to the currentAddressreport LWC component.
* **********************************************/
    
    public static Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
    public static Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
    //public static Id secondaryCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Secondary_Close_Contact').getRecordTypeId(); 
    
    
    @AuraEnabled
    public static list<addresswrapper> getRecordList(string recordType, string startDate, string endDate) {
        // Query the incoming case
        map<Id, addresswrapper> caseAddressWrapperMap = new  map<Id, addresswrapper>();
        
        datetime start_Date;
        datetime end_Date;
        date d = system.today().addDays(-14);
         List<addresswrapper> addresswrapperlist = new List<addresswrapper>();
        try{
        start_Date = date.valueOf(startDate); 
        if (startDate != Null){
            date sdate = date.valueOf(startDate);
            start_Date = DateTime.newInstance(sdate.year(), sdate.month(), sdate.day(), 0 , 0, 0); 
        }
        else{
            start_Date = DateTime.newInstance(d.year(), d.month(), d.day(), 0 , 0, 0); 
            //start_Date = d.addDays(-14);
        }
        if (endDate != Null){
            date edate = date.valueOf(endDate);
            end_date = DateTime.newInstance(edate.year(), edate.month(), edate.day(), 23 , 59, 59); 
            //end_Date = date.valueOf(endDate); 
        }	
        else{
            end_Date = system.now();
        }
        
        List<Id> recordTypeIdList = new  list<Id>();
        if(recordType == 'Confirmed Case'){
            recordTypeIdList.add(confirmedCaseRecordTypeId);    
        }
        if(recordType == 'Close Contact'){
            recordTypeIdList.add(closeContactRecordTypeId);    
        }
        if(recordType == 'Confirmed Case and Close Contact'){
            recordTypeIdList.add(confirmedCaseRecordTypeId); recordTypeIdList.add(closeContactRecordTypeId);   
        }
        
                
        List<Case> caselist =  [SELECT CurrentAddressId__c,accountid,  Account.LastName,Account.FirstName, Account.PersonMailingAddress,CurrentAddressType__c,RecordType.Name,CaseNumber, Status, Owner.Name, Calculated_Onset_Date__c, Account.Name, Account.PersonBirthdate
                                FROM Case WHERE Calculated_Onset_Date__c >= :start_Date AND Calculated_Onset_Date__c <= :end_Date AND Status != 'Closed' AND RecordTypeId IN: recordTypeIdList];
        Map<Id, case> caseMap = new Map<Id, case>();
        List<string> cpaList = new List<string>();
        List<string> hmipList = new List<string>();
        List<string> praList = new List<string>();
        List<case> caseIdList = new List<case>();
        Map<Id,list<HealthCloudGA__EhrEncounter__c>> caseHMIPMap = new Map<Id,list<HealthCloudGA__EhrEncounter__c>>();
        List<Id> accIdList = new List<Id>();
        Map<Id, List<Case>> accCaseMap = new Map<Id, List<Case>>();
        Map<Id, List<ContactPointAddress>> cpaCaseMap = new Map<Id, List<ContactPointAddress>>();
        set<Id> accountIdSet = new  set<Id>();
        map<Id, Account> accountMap = new map<Id, Account>(); 
        
        // Iterating through Case Records
        // try{
            for(case c : caseList){
                if(c.CurrentAddressType__c != '' && C.CurrentAddressType__c != NULL){
                    
                    
                    if(c.CurrentAddressType__c == 'CPA'){
                        cpaList.add(c.CurrentAddressId__c);
                        caseMap.put(c.CurrentAddressId__c,c);
                        accountIdSet.add(c.AccountId);
                    }
                    if(c.CurrentAddressType__c == 'HMIP'){
                        hmipList.add(c.CurrentAddressId__c);
                        caseMap.put(c.CurrentAddressId__c,c);
                        accountIdSet.add(c.AccountId);
                    }
                    if(c.CurrentAddressType__c == 'PRA'){
                        praList.add(c.CurrentAddressId__c);
                        caseMap.put(c.CurrentAddressId__c,c);
                        accountIdSet.add(c.AccountId);
                    }
                } 
                else{
                    caseIdList.add(c);
                    accountIdSet.add(c.AccountId);
                }
                
            }
            list<Account> accountList = [SELECT Id, ShippingAddress,LastName,FirstName, PersonMailingAddress , ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, PersonMailingCity, PersonMailingStreet, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry FROM Account WHERE Id IN:accountIdSet];
            for(Account a : accountList){
                accountMap.put(a.ID,a);
            }
            if(cpaList.size()>0){
                List<ContactPointAddress> currentCPA = [select id,ParentId, address,ActiveFromDate,ActiveToDate from ContactPointAddress where id IN: cpaList];
                for(ContactPointAddress cpa : currentcpa){
                    accountIdSet.add(cpa.ParentId);
                }
                
                if(currentCPA != null){
                    for(ContactPointAddress cpa : currentCPA){
                        case cpaAddressCase = caseMap.get(cpa.id);
                        Address currentCPAaddress = cpa.address;
                        Address accountAddress = accountMap.get(cpa.ParentId).PersonMailingAddress;
                        if(!caseAddressWrapperMap.containskey(caseMap.get(cpa.id).Id)){
                            
                            
                            if(currentCPAaddress != null){  
                                if(accountAddress != null){
                                    addressWrapper aw = new addresswrapper(caseMap.get(cpa.id).Id,caseMap.get(cpa.id).CaseNumber,caseMap.get(cpa.id).Account.Name,caseMap.get(cpa.id).RecordType.name,
                                                                           caseMap.get(cpa.id).Status,caseMap.get(cpa.id).owner.Name,string.valueof (caseMap.get(cpa.id).Account.PersonBirthdate),
                                                                           string.valueof (caseMap.get(cpa.id).Calculated_Onset_Date__c),currentCPAaddress.street,currentCPAaddress.state,currentCPAaddress.city,currentCPAaddress.postalcode,caseMap.get(cpa.id).Account.FirstName,caseMap.get(cpa.id).Account.LastName, '/'+caseMap.get(cpa.id).Id,'/'+caseMap.get(cpa.id).AccountId);
                                    
                                    caseAddressWrapperMap.put(caseMap.get(cpa.id).Id,aw);
                                }
                                else{
                                    addressWrapper aw = new addresswrapper(caseMap.get(cpa.id).Id,caseMap.get(cpa.id).CaseNumber,caseMap.get(cpa.id).Account.Name,caseMap.get(cpa.id).RecordType.name,
                                                                           caseMap.get(cpa.id).Status,caseMap.get(cpa.id).owner.Name,string.valueof (caseMap.get(cpa.id).Account.PersonBirthdate), string.valueof (caseMap.get(cpa.id).Calculated_Onset_Date__c),currentCPAaddress.street,currentCPAaddress.state,currentCPAaddress.city,currentCPAaddress.postalcode,caseMap.get(cpa.id).Account.FirstName,caseMap.get(cpa.id).Account.LastName, '/'+caseMap.get(cpa.id).Id,'/'+caseMap.get(cpa.id).AccountId);
                                    
                                    caseAddressWrapperMap.put(caseMap.get(cpa.id).Id,aw);
                                }
                                
                            }
                        }
                    }
                    
                }
            }
            if(hmipList.size() > 0 ){
                List<HealthCloudGA__EhrEncounter__c> currentHMIPList = [select id,Record__c,record__r.Account.FirstName, record__r.Account.LastName,record__r.AccountId,HealthCloudGA__Account__r.ShippingAddress,Date_admitted__c,Date_discharged__c from HealthCloudGA__EhrEncounter__c where id IN: hmipList];
                if(currentHMIPList != null){
                    
                    for(HealthCloudGA__EhrEncounter__c currentHMIP : currentHMIPList){
                        case hmipAddressCase = caseMap.get(currentHMIP.id);
                        Address currentHMIPaddress = currentHMIP.HealthCloudGA__Account__r.ShippingAddress;
                         Address accountAddress = accountMap.get(currentHMIP.Record__r.AccountId).PersonMailingAddress;
                        system.debug('Line 130 ' + accountAddress);
                        if(!caseAddressWrapperMap.containskey(caseMap.get(currentHMIP.id).Id)){
                            if(currentHMIPaddress != null){ 
                                if(accountAddress != null){
                                    addressWrapper aw = new addresswrapper(caseMap.get(currentHMIP.id).Id,caseMap.get(currentHMIP.id).CaseNumber,caseMap.get(currentHMIP.id).Account.Name,caseMap.get(currentHMIP.id).RecordType.name,
                                                                           caseMap.get(currentHMIP.id).Status,caseMap.get(currentHMIP.id).owner.Name,string.valueof (caseMap.get(currentHMIP.id).Account.PersonBirthdate),string.valueof (caseMap.get(currentHMIP.id).Calculated_Onset_Date__c),currentHMIPaddress.street,currentHMIPaddress.state,currentHMIPaddress.city,currentHMIPaddress.postalcode,caseMap.get(currentHMIP.id).Account.FirstName,caseMap.get(currentHMIP.id).Account.LastName,'/'+caseMap.get(currentHMIP.id).Id,'/'+caseMap.get(currentHMIP.id).AccountId);
                                    caseAddressWrapperMap.put(caseMap.get(currentHMIP.id).Id,aw);
                                }
                                else{
                                    addressWrapper aw = new addresswrapper(caseMap.get(currentHMIP.id).Id,caseMap.get(currentHMIP.id).CaseNumber,caseMap.get(currentHMIP.id).Account.Name,caseMap.get(currentHMIP.id).RecordType.name,
                                                                           caseMap.get(currentHMIP.id).Status,caseMap.get(currentHMIP.id).owner.Name,
                                                                           string.valueof (caseMap.get(currentHMIP.id).Account.PersonBirthdate),string.valueof (caseMap.get(currentHMIP.id).Calculated_Onset_Date__c),currentHMIPaddress.street,currentHMIPaddress.state,currentHMIPaddress.city,currentHMIPaddress.postalcode,caseMap.get(currentHMIP.id).Account.FirstName,caseMap.get(currentHMIP.id).Account.LastName, '/'+caseMap.get(currentHMIP.id).Id,'/'+caseMap.get(currentHMIP.id).AccountId);
                                    caseAddressWrapperMap.put(caseMap.get(currentHMIP.id).Id,aw);   
                                }
                            }
                        }
                    }
                }
                
            }
            
            if(praList.size() > 0 ){
                List<Account> currentPRAList = [select id,PersonMailingAddress, FirstName, LastName from Account where id IN: praList];
                if(currentPRAList != null){
                    for(Account currentPRA : currentPRAList){
                        case praAddressCase = caseMap.get(currentPRA.id);
                        Address currentPRAaddress = currentPRA.PersonMailingAddress;
                        if(!caseAddressWrapperMap.containskey(caseMap.get(currentPRA.id).Id)){
                            if(currentPRAaddress != null) {
                                addressWrapper aw = new addresswrapper(caseMap.get(currentPRA.id).Id,caseMap.get(currentPRA.id).CaseNumber,caseMap.get(currentPRA.id).Account.Name,caseMap.get(currentPRA.id).RecordType.name,
                                                                       caseMap.get(currentPRA.id).Status,caseMap.get(currentPRA.id).owner.Name,string.valueof (caseMap.get(currentPRA.id).Account.PersonBirthdate),
                                                                       string.valueof (caseMap.get(currentPRA.id).Calculated_Onset_Date__c),currentPRAaddress.street,currentPRAaddress.state,currentPRAaddress.city,currentPRAaddress.postalcode,caseMap.get(currentPRA.id).Account.FirstName,caseMap.get(currentPRA.id).Account.LastName, '/'+caseMap.get(currentPRA.id).Id,'/'+caseMap.get(currentPRA.id).AccountId);
                                caseAddressWrapperMap.put(caseMap.get(currentPRA.id).Id,aw);
                                
                            }
                            
                        }
                    }
                }
                
            }
            if(caseIdList.size() > 0){
                date todysdate = Date.today();
                List<HealthCloudGA__EhrEncounter__c> currentHMIP = [select id,Record__r.Account.FirstName,Record__r.Account.LastName,HealthCloudGA__Account__r.ShippingAddress,HealthCloudGA__Account__r.FirstName, HealthCloudGA__Account__r.LastName,Record__r.AccountId,HealthCloudGA__Account__r.PersonMailingAddress,Date_admitted__c,Date_discharged__c,Record__c,Record__r.CaseNumber,Record__r.Account.Name,Record__r.RecordType.Name,
                                                                    Record__r.Status,Record__r.Account.PersonBirthdate, Record__r.Owner.Name,Record__r.Calculated_Onset_Date__c,End_Date__c,StartDate__c from HealthCloudGA__EhrEncounter__c where Record__c = :caseIdList AND StartDate__c <= :todysdate AND ( End_Date__c = null OR End_Date__c >= :todysdate) Order by End_Date__c desc NULLS First, StartDate__c desc];
                for(HealthCloudGA__EhrEncounter__c hmip : currentHMIP){
                    if(caseHMIPMap.containsKey(hmip.Record__c)){
                        List<HealthCloudGA__EhrEncounter__c> hmipadrsList = new List<HealthCloudGA__EhrEncounter__c>();
                        hmipadrsList.addAll(caseHMIPMap.get(hmip.Record__c));
                        hmipadrsList.add(hmip);
                        caseHMIPMap.put(hmip.Record__c,hmipadrsList);
                    }
                    else{
                        List<HealthCloudGA__EhrEncounter__c> hmipadrsList = new List<HealthCloudGA__EhrEncounter__c>();
                        hmipadrsList.add(hmip);
                        caseHMIPMap.put(hmip.Record__c,hmipadrsList);
                    }
                }
                
                for(case c : caseidList){
                    
                    if(c.AccountId != NULL){
                        if(caseHMIPMap.containsKey(c.Id)) {
                            
                        }  
                        else{
                            accIdList.add(c.AccountId);
                            if(accCaseMap.containsKey(c.accountId)){
                                List<Case> allCaseList = new List<Case>();
                                allCaseList.addAll(accCaseMap.get(c.AccountId));
                                allCaseList.add(c);
                                accCaseMap.put(c.AccountId, allCaseList);
                            }
                            else{
                                List<Case> allCaseList = new List<Case>();
                                allCaseList.add(c);
                                accCaseMap.put(c.AccountId, allCaseList);
                            }
                        }
                    }
                }
                if(caseHMIPMap != null && caseHMIPMap.size()>0){
                    List<Id> hmipCaseIdList = new List<Id>();
                    hmipCaseIdList.addall(caseHMIPMap.keySet());
                    
                    for(Id caseId : hmipCaseIdList){
                        List<HealthCloudGA__EhrEncounter__c> hmipcaseList = new List<HealthCloudGA__EhrEncounter__c>();
                        hmipcaseList.addAll(caseHMIPMap.get(caseId));
                        Address currentHMIPaddress = hmipcaseList[0].HealthCloudGA__Account__r.ShippingAddress;
                        //Address accountAddress = hmipcaseList[0].HealthCloudGA__Account__r.PersonMailingAddress;
                        Address accountAddress = accountMap.get( hmipcaseList[0].Record__r.AccountId).PersonMailingAddress;
                        if(!caseAddressWrapperMap.containskey(hmipcaseList[0].Record__r.Id)){
                            if(currentHMIPaddress != null) { 
                                if(accountAddress != NULL){
                                    addressWrapper aw = new addresswrapper(hmipcaseList[0].Record__r.Id,hmipcaseList[0].Record__r.CaseNumber,hmipcaseList[0].Record__r.Account.Name,hmipcaseList[0].Record__r.RecordType.name,
                                                                           hmipcaseList[0].Record__r.Status,hmipcaseList[0].Record__r.owner.Name,string.valueof (hmipcaseList[0].Record__r.Account.PersonBirthdate), string.valueof (hmipcaseList[0].Record__r.Calculated_Onset_Date__c),currentHMIPaddress.street,currentHMIPaddress.state,currentHMIPaddress.city,currentHMIPaddress.postalcode,hmipcaseList[0].Record__r.Account.FirstName, hmipcaseList[0].Record__r.Account.LastName,'/'+hmipcaseList[0].Record__r.Id,'/'+hmipcaseList[0].Record__r.AccountId);
                                    
                                    caseAddressWrapperMap.put(hmipcaseList[0].Record__r.Id,aw);
                                }
                                else{
                                    addressWrapper aw = new addresswrapper(hmipcaseList[0].Record__r.Id,hmipcaseList[0].Record__r.CaseNumber,hmipcaseList[0].Record__r.Account.Name,hmipcaseList[0].Record__r.RecordType.name,
                                                                           hmipcaseList[0].Record__r.Status,hmipcaseList[0].Record__r.owner.Name,string.valueof (hmipcaseList[0].Record__r.Account.PersonBirthdate), 
                                                                           string.valueof (hmipcaseList[0].Record__r.Calculated_Onset_Date__c),currentHMIPaddress.street,currentHMIPaddress.state,currentHMIPaddress.city,currentHMIPaddress.postalcode,hmipcaseList[0].Record__r.Account.FirstName, hmipcaseList[0].Record__r.Account.LastName, '/'+hmipcaseList[0].Record__r.Id,'/'+hmipcaseList[0].Record__r.AccountId);
                                    caseAddressWrapperMap.put(hmipcaseList[0].Record__r.Id,aw);
                                }
                            }
                        }
                    }
                    
                }
                
                if(accIdList != null && accIdList.size() > 0){
                    List<ContactPointAddress> currentCPAList = [select id,address,ActiveFromDate,ActiveToDate, ParentId from ContactPointAddress where ParentId IN :accIdList AND  Addresstype != 'Discharge'  AND  ActiveFromDate <= :todysdate AND ( ActiveToDate = null OR ActiveToDate >= :todysdate) Order by ActiveToDate desc NULLS First ,ActiveFromDate desc];
                    
                    if(currentCPAList != null && currentCPAList.size()>0){
                        for(ContactPointAddress currentCPA : currentCPAList){
                            if(cpaCaseMap.containsKey(currentCPA.parentId)){
                                List<ContactPointAddress> cpa = new List<ContactPointAddress>();
                                cpa.addAll(cpaCaseMap.get(currentCPA.parentId));
                                cpa.Add(currentCPA);
                                cpaCaseMap.put(currentCPA.parentId, cpa);
                            }
                            else{
                                List<ContactPointAddress> cpa = new List<ContactPointAddress>();
                                cpa.Add(currentCPA);
                                cpaCaseMap.put(currentCPA.parentId, cpa);
                            }
                            
                            
                        }
                        for(id accId :accIdList){
                            if(cpaCaseMap.containskey(accId)){
                                List<ContactPointAddress> cpaLst = new List<ContactPointAddress>();
                                cpaLst.addAll(cpaCaseMap.get(accId));
                                cpaLst.sort();
                                integer size = cpaLst.size() - 1;
                                Address currentCPAaddress = cpaLst[size].address; 
                                Address accountAddress = accountMap.get(accId).PersonMailingAddress;
                                for(case cpaAddressCase : accCaseMap.get(accId)){
                                    if(!caseAddressWrapperMap.containskey(cpaAddressCase.Id)){
                                        if(currentCPAaddress != null ) { 
                                            if(accountAddress != null){
                                                addressWrapper aw = new  addresswrapper(cpaAddressCase.Id,cpaAddressCase.CaseNumber,cpaAddressCase.Account.Name,cpaAddressCase.RecordType.name,
                                                                                        cpaAddressCase.Status,cpaAddressCase.owner.Name,string.valueof (cpaAddressCase.Account.PersonBirthdate),string.valueof (cpaAddressCase.Calculated_Onset_Date__c),currentCPAaddress.street,currentCPAaddress.state,currentCPAaddress.city,currentCPAaddress.postalcode,cpaAddressCase.Account.FirstName, cpaAddressCase.Account.LastName, '/'+cpaAddressCase.Id,'/'+cpaAddressCase.AccountId);
                                                
                                                caseAddressWrapperMap.put(cpaAddressCase.Id,aw); 
                                            }
                                            else{
                                                addressWrapper aw = new  addresswrapper(cpaAddressCase.Id,cpaAddressCase.CaseNumber,cpaAddressCase.Account.Name,cpaAddressCase.RecordType.name,
                                                                                        cpaAddressCase.Status,cpaAddressCase.owner.Name,string.valueof (cpaAddressCase.Account.PersonBirthdate),string.valueof (cpaAddressCase.Calculated_Onset_Date__c),currentCPAaddress.street,currentCPAaddress.state,currentCPAaddress.city,currentCPAaddress.postalcode,cpaAddressCase.Account.FirstName, cpaAddressCase.Account.LastName, '/'+cpaAddressCase.Id,'/'+cpaAddressCase.AccountId);
                                                
                                                caseAddressWrapperMap.put(cpaAddressCase.Id,aw); 
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if(accIdList != null && accIdList.size() > 0)
                    {
                        //fetch the discharge address
                        List<ContactPointAddress> DischargedCPA = [select id,address,ParentId,ActiveFromDate,ActiveToDate from ContactPointAddress where ParentId IN :accIdList AND  Addresstype = 'Discharge' AND   ActiveFromDate <= :todysdate AND ( ActiveToDate = null OR ActiveToDate >= :todysdate)  Order by ActiveToDate desc NULLS First ,ActiveFromDate desc];
                        if(DischargedCPA != null && DischargedCPA.size()>0){
                            for(ContactPointAddress currentCPA : DischargedCPA){
                                if(cpaCaseMap.containsKey(currentCPA.parentId)){
                                    List<ContactPointAddress> cpa = new List<ContactPointAddress>();
                                    cpa.addAll(cpaCaseMap.get(currentCPA.parentId));
                                    cpa.Add(currentCPA);
                                    cpaCaseMap.put(currentCPA.parentId, cpa);
                                }
                                else{
                                    List<ContactPointAddress> cpa = new List<ContactPointAddress>();
                                    cpa.Add(currentCPA);
                                    cpaCaseMap.put(currentCPA.parentId, cpa);
                                }
                                
                                
                            }
                            for(id accId :accIdList){
                                List<ContactPointAddress> cpaLst = new List<ContactPointAddress>();
                                integer size;
                                if(cpaCaseMap.containsKey(accId)){
                                cpaLst.addAll(cpaCaseMap.get(accId));
                                cpaLst.sort();
                                size = cpaLst.size() - 1;
                            	}
                                Address currentCPAaddress;
                                if(cpaLst != NULL && cpaLst.size()>0){
                                    currentCPAaddress = cpaLst[size].address; 
                                }
                                for(case cpaAddressCase : accCaseMap.get(accId)){
                                    if(!caseAddressWrapperMap.containskey(cpaAddressCase.Id)){
                                        if(currentCPAaddress != null)  { 
                                            addressWrapper aw = new addresswrapper(cpaAddressCase.Id,cpaAddressCase.CaseNumber,cpaAddressCase.Account.Name,cpaAddressCase.RecordType.name,
                                                                                   cpaAddressCase.Status,cpaAddressCase.owner.Name,string.valueof (cpaAddressCase.Account.PersonBirthdate),string.valueof (cpaAddressCase.Calculated_Onset_Date__c),currentCPAaddress.street,currentCPAaddress.state,currentCPAaddress.city,currentCPAaddress.postalcode,cpaAddressCase.Account.FirstName, cpaAddressCase.Account.LastName, '/'+cpaAddressCase.Id,'/'+cpaAddressCase.AccountId);
                                            caseAddressWrapperMap.put(cpaAddressCase.Id,aw);
                                            
                                        }
                                        
                                    }
                                }
                                
                            }}
                        
                        
                    }
                    if(accIdList != null && accIdList.size() > 0) {
                        
                        List<Account> currentPRALst = [select id,PersonMailingAddress from Account where id IN :accIdList];
                        if(currentPRALst != null && currentPRALst.size() > 0){
                            for(Account currentPRA : currentPRALst){
                                Address currentPRAaddress = currentPRA.PersonMailingAddress;
                                for(case praAddressCase : accCaseMap.get(currentPRA.Id)){
                                    if(!caseAddressWrapperMap.containskey(praAddressCase.Id)){
                                        if(currentPRAaddress != null) { 
                                            addressWrapper aw = new   addresswrapper(praAddressCase.Id,praAddressCase.CaseNumber,praAddressCase.Account.Name,praAddressCase.RecordType.name,
                                                                                     praAddressCase.Status,praAddressCase.owner.Name,string.valueof (praAddressCase.Account.PersonBirthdate), 
                                                                                     string.valueof (praAddressCase.Calculated_Onset_Date__c),currentPRAaddress.street,currentPRAaddress.state,currentPRAaddress.city,currentPRAaddress.postalcode,praAddressCase.Account.FirstName, praAddressCase.Account.LastName, '/'+praAddressCase.Id,'/'+praAddressCase.AccountId);
                                            
                                            caseAddressWrapperMap.put(praAddressCase.Id,aw); 
                                        }
                                    }
                                }
                            } 
                        }
                    }
                }
                
            }
        }
        
        catch(Exception e){
            Application_Log__c appLog = new Application_Log__c(Message__c = e.getMessage(),Stack_Trace__c = e.getStackTraceString(),Source__c = 'CurrentAddressReportController',Source_Function__c = 'getRecordList', Transaction_Date__c = System.now());
            insert appLog;
            system.debug('e.getLineNumber ' + e.getLineNumber());
            system.debug('e.getMessage ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
            
        }   
        if(caseAddressWrapperMap != NULL){
            addresswrapperlist.addAll(caseAddressWrapperMap.values());
            
        }
        return addresswrapperlist;
        
        
    }
    
    /*************************************************
* addresswrapper - wrapper class to hold all address parameters including the possible values on a record
*
* **********************************************/
    public class addresswrapper{
        @AuraEnabled
        public string RecordNumber {get;set;}
        @AuraEnabled
        public string AccountName {get;set;}
        @AuraEnabled
        public string RecordRecordType {get;set;}
        @AuraEnabled
        public string Status  {get;set;}
        @AuraEnabled
        public string RecordOwner {get;set;}
        @AuraEnabled
        public string Birthdate  {get;set;}
        @AuraEnabled
        public string CalculatedOnsetDate {get;set;}
        @AuraEnabled
        public string CurrentAddressLine1 {get;set;}
        @AuraEnabled
        public string CurrentAddressLine2 {get;set;}
        @AuraEnabled
        public string CurrentSuburb {get;set;}
        @AuraEnabled
        public string CurrentPostCode {get;set;}
        @AuraEnabled
        public string RecordId {get;set;}
        @AuraEnabled
        public string FirstName {get;set;}
        @AuraEnabled
        public string LastName {get;set;}
         @AuraEnabled
        public string AccountURL {get;set;}
         @AuraEnabled
        public string RecordURL {get;set;}
        
        addresswrapper(string RecordId,string RecordNumber, string AccountName, string RecordRecordType, string Status, string RecordOwner,string Birthdate,string CalculatedOnsetDate, string CurrentAddressLine1,string CurrentAddressLine2
                       ,string CurrentSuburb,string CurrentPostCode,string FirstName, string LastName, string RecordURL, string AccountURL){
                           this.RecordNumber = RecordNumber;
                           this.AccountName = AccountName;
                           this.FirstName = FirstName;
                           this.LastName = LastName;
                           this.RecordRecordType = RecordRecordType;
                           this.Status = Status;
                           this.RecordOwner = RecordOwner;
                           this.Birthdate = Birthdate;
                           this.CalculatedOnsetDate = CalculatedOnsetDate;
                           this.CurrentAddressLine1 = CurrentAddressLine1;
                           this.CurrentAddressLine2 = CurrentAddressLine2;
                           this.CurrentSuburb = CurrentSuburb;
                           this.CurrentPostCode = CurrentPostCode;
                           this.RecordId = RecordId;
                           this.AccountURL = AccountURL;
                           this.RecordURL = RecordURL;
                       }
        
        
        
    }
}