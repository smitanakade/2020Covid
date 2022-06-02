/*
Description: Housing Assessment Trigger
Date: 12/8/2021
Author: Xiang Zheng

@Modification Log   : 
---------------------------------------------------
Date           Author      		    Details
---------------------------------------------------
12/8/2021     Xiang Zheng          bug 243373: replace the 'New Assessment Name' process builder, because the NOW function in PB can only get GMT time. 
*/
public with sharing class HousingAssessmentTriggerHandler extends TriggerHandler{

    public override void beforeInsert() {
        HousingAssessmentTriggerHandler.newAssessmentName(Trigger.new);
    }

    //replace the 'New Assessment Name' process builder
    @testVisible
    private static void newAssessmentName(List<HealthCloudGA__HousingAssessment__c> newAssessments){

        List<Id> caesIds = new  List<Id>();
        Map<Id,Case> caseMap;

        for(HealthCloudGA__HousingAssessment__c na: newAssessments){
            caesIds.add(na.Record__c);
        }

        if(caesIds.size() != 0){
            caseMap = new Map<Id,Case>([SELECT id, AccountId FROM Case WHERE id = :caesIds]);
        }

        for(HealthCloudGA__HousingAssessment__c na: newAssessments){
            if(String.isNotEmpty(na.template__c)){
                if(caseMap != null){
                    na.HealthCloudGA__Account__c = caseMap.get(na.Record__c) != null?caseMap.get(na.Record__c).AccountId:null;
                    na.Name = na.template__c + ' - ' + String.valueOf(System.now());
                }
            }else{
                na.Name = String.valueOf(System.now());
            }
        }
    }
}