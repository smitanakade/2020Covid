/*
Description: Housing Assessment Trigger
Date: 12/8/2021
Author: Xiang Zheng
*/
trigger HousingAssessmentTrigger on HealthCloudGA__HousingAssessment__c (before insert) {
    new HousingAssessmentTriggerHandler().run();
}