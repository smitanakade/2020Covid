/**
* @Author             : Sukumar
* @Description        : ContactPointAddress Trigger helper class
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
*28/10/2021		 Sukumar			  Bug#332253 : Incorrect error message when new CPA is added when CPA with no "Active To" date already exists
**/
public with sharing class ContactPointAddressTriggerHelper {
    Public static void validateActiveToDate(List<ContactPointAddress> listOfCPAs ){
        set<Id> setParentIds = new set<Id>();
        List<ContactPointAddress> listOfCPAsWithActiveToDate = new List<ContactPointAddress>();
        map<Id, List<ContactPointAddress>> mapParentIdAndCPAs = new map<Id, List<ContactPointAddress>>();

        try{
			for(contactPointAddress cpa: listOfCPAs){
				setParentIds.add(cpa.ParentId);
			}

			map<Id, Integer> mapCPAsWithBlankActiveToDate = new map<Id, Integer>();
			if(!setParentIds.isEmpty()){
				for(ContactPointAddress cpa: [SELECT Id, ActiveToDate, parentId FROM ContactPointAddress WHERE ParentId IN:setParentIds AND ActiveToDate = NULL]){
					if(!mapCPAsWithBlankActiveToDate.containsKey(cpa.ParentId)){
						mapCPAsWithBlankActiveToDate.put(cpa.ParentId, 1);
					}
					else{
						mapCPAsWithBlankActiveToDate.put(cpa.ParentId,  mapCPAsWithBlankActiveToDate.get(cpa.ParentId) + 1);  
					}
				}
			}

			for(contactPointAddress cpa: listOfCPAs){
				if(!cpa.Set_by_Trigger__c){
					if(cpa.ActiveToDate == null && cpa.Save_with_blank_Active_To_Date__c == false && (mapCPAsWithBlankActiveToDate.get(cpa.ParentId) == 0 || mapCPAsWithBlankActiveToDate.get(cpa.ParentId) == null )){
						cpa.addError('By not setting "Active To" date, this address may be taken as current address. <br/> To save without an end date, please check "Save with blank Active To Date" box');
					}
					else if(mapCPAsWithBlankActiveToDate.get(cpa.ParentId) > 0 && cpa.ActiveToDate == null && cpa.Save_with_blank_Active_To_Date__c == false){
						cpa.addError('Please populate "Active To" in previous Contact Point Address entries if required. <br/> To save, please check "Save with blank Active To Date" box');
					}
				}
			}
		}catch(Exception exp){
            ApplicationLogUtility.createlog('ContactPointAddressTriggerHelper','validateActiveToDate',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }  
    }
}