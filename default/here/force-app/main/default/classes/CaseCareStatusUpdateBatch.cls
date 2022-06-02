/**
 * @Author             : Subbiah Kumaravel
 * @Description        : Set In care pathway or Self care pathway, 
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 21/10/2021     Subbiah Kumaravel        Initial version
 * 7/12/2021      Smita Kagde              PBI 341177
**/
global class CaseCareStatusUpdateBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Name,Record__c,Record__r.Account.Age_Value__pc,RecordTypeId,Record_Created_Status__c,Subject__c,
                                        Survey_Name__c,Do_you_need_support__c,Record__r.Clinical_Care_Status__c,Have_received_both_doses_of_the_vaccine__c,How_many_doses_of_vaccine__c,
										had_any_symptoms_in_the_last_5days__c, How_sick_do_you_feel__c,Do_you_see_doctors_regularly__c,Happy_to_contact_your_GP_for_clinical_ca__c 
                                        From Survey_Response__c
                                        WHERE Record__r.Clinical_Care_Status__c Not IN('In care pathway','Self care pathway') and Record_Created_Status__c =false and Subject__c = 'Confirmed Case Initial Triage']);
	}

    public void execute(Database.BatchableContext bc, List<Survey_Response__c> responses){
        // process each batch of records
		
		Map<Id,String> recordStatusMap = new Map<Id,String>();
        List<Case> recordsToBeUpdated = new List<Case>();
        List<Survey_Response__c> lstSurveys = new List<Survey_Response__c>();
        RecordMCReadyLastRun__c previousRun = RecordMCReadyLastRun__c.getInstance();
        decimal agevalue = previousRun.AgeCriteria__c;
        boolean isCriteriaMet = false;

        try{
            for(Survey_Response__c response : responses){	
                //system.debug('Id==>'+response.Id+';;age-----------------==>'+response.Record__r.Account.Age_Value__pc);
                if((response.Record__r.Account.Age_Value__pc >= agevalue) || response.Do_you_need_support__c =='Yes' || (response.How_many_doses_of_vaccine__c=='0' || response.How_many_doses_of_vaccine__c == '1') || response.How_sick_do_you_feel__c=='More Sick' || response.Do_you_see_doctors_regularly__c == 'Yes' ){
                    recordStatusMap.put(response.Record__c, 'In care pathway');
                    isCriteriaMet = true;
                } else if((response.Record__r.Account.Age_Value__pc < agevalue) && response.Do_you_need_support__c == 'No' && response.Have_received_both_doses_of_the_vaccine__c == 'Yes' && response.How_sick_do_you_feel__c != 'More Sick' && response.Do_you_see_doctors_regularly__c == 'No' && response.Happy_to_contact_your_GP_for_clinical_ca__c == 'Yes'){
                    recordStatusMap.put(response.Record__c, 'Self care pathway');
                    isCriteriaMet = true;
                }
                if(isCriteriaMet){                
                    lstSurveys.add(new Survey_Response__c(Id=response.Id, Record_Created_Status__c=true));                
                }
            }

            for(Id recordId : recordStatusMap.keySet()){
                recordsToBeUpdated.add(new Case(Id=recordId, Clinical_Care_Status__c=recordStatusMap.get(recordId)));
            }     

            if(recordsToBeUpdated.size() > 0){
                update recordsToBeUpdated;
            }
            
            if(lstSurveys.size() > 0){
                update lstSurveys;
            }
        }catch(Exception exp){
            ApplicationLogUtility.createlog('CaseCareStatusUpdateBatch','execute',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }    

    public void finish(Database.BatchableContext bc){
        
    }    
}