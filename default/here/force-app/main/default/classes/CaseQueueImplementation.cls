/*
 * @Author             : marcelo.cost
 * @Description        : 
 * @Modification Log   : 
 * -------------------------------------------------------------------------
 * Date           Author                Details
 * -------------------------------------------------------------------------
 * 18/02/2021     marcelo.cost          Initial version
 * 11/03/2021     Jiten Joysar          Added additinal global class
 * 17/03/2021     Rahul Ankireddypalli  Added GreenZone global Class PBI: 271921
 * 01/07/2021     Rahul Ankireddypalli  Modified GreenZone global Class PBI : 299815
*/
global with sharing class CaseQueueImplementation {
    
    global class Prison extends CaseQueueProcessVirtual {
        
        public override Queue_Allocation__c checkForMatchOnAllocationRule() {
            for (Queue_Allocation__c queueAlloc : allocationRules) {
                if (addressHasKeywords(CaseQueueAllocator.relatedAccountsById.get(currentCase.AccountId).PersonMailingAddress, new Set<String>{
                        'prison', 'youth justice', 'correctional centre'
                })){
                    return queueAlloc;
                }
            }
        return null;

        }
    }

    global class GreenZone extends CaseQueueProcessVirtual {
        
        public override Queue_Allocation__c checkForMatchOnAllocationRule() {
            for (Queue_Allocation__c queueAlloc : allocationRules) {
              
          if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName == 'Casual_Contact' && currentCase.permit_Type__c == 'Green' && currentCase.Status == 'Active' ){                                 
                    return queueAlloc;
                }
            }
        return null;
        }
    }
    
    global class OrangeZone extends CaseQueueProcessVirtual {   
        public override Queue_Allocation__c checkForMatchOnAllocationRule() {
            for (Queue_Allocation__c queueAlloc : allocationRules) {
          if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName == 'Casual_Contact' && currentCase.permit_Type__c == 'Orange' && currentCase.Status == 'Active' ){                       
                    return queueAlloc;
                }
            }
        return null;
        }
    }
        
    global class RedZone extends CaseQueueProcessVirtual {  
        public override Queue_Allocation__c checkForMatchOnAllocationRule() {
            for (Queue_Allocation__c queueAlloc : allocationRules) {
                if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName == 'Close_Contact' && currentCase.permit_Type__c == 'Red' && currentCase.Status == 'Identify'){
                    return queueAlloc;
                }
            }
        return null;
        }
    }
    /********************************************************************
    * @Author             : Jiten Joysar
    * @Description        : Class to Process International traveller case records
                            Added for Feature 270253
    /*******************************************************************/

    global class PCCSCCInternationalTraveller extends CaseQueueProcessVirtual { 
        public override Queue_Allocation__c checkForMatchOnAllocationRule() {
            for (Queue_Allocation__c queueAlloc : allocationRules) {
                if((CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName == 'Close_Contact' || CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName == 'Secondary_Close_Contact') 
                && currentCase.Status == 'Identify' &&
                CaseQueueAllocator.relatedAccountsById.get(currentCase.AccountId).Additional_Detail__c.contains('CQ-')){
                    return queueAlloc;
                }
            }
        return null;
        }
    }
    global class PCCSCCQuarantineDefault extends CaseQueueProcessVirtual {
        public override Queue_Allocation__c checkForMatchOnAllocationRule() {
            for (Queue_Allocation__c queueAlloc : allocationRules) {
                if((CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName == 'Close_Contact' || CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName == 'Secondary_Close_Contact') 
                && currentCase.Status == 'Quarantine'){
                    return queueAlloc;
                }
            }
        return null;
        }
    }

    /********************************************************************
    * @Author             : Duncan Bridges
    * @Description        : Class to Process International traveller case records
                            Added for Feature 270236
    /********************************************************************/
    global class ConfirmedCaseInternationalTraveller extends CaseQueueProcessVirtual {
        public override Queue_Allocation__c checkForMatchOnAllocationRule() {
            for (Queue_Allocation__c queueAlloc : allocationRules) {
                if((CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName == 'COVID_19_Case_Assessment') 
                && currentCase.Status == 'Trace' &&
                currentCase.Case_Classification__c == 'Confirmed' &&
                CaseQueueAllocator.relatedAccountsById.get(currentCase.AccountId).Additional_Detail__c.contains('CQ-')){
                    return queueAlloc;
                }
            }
        return null;
        }
    }

    /********************************************************************
    * @Author             : Duncan Bridges
    * @Description        : Assign to Informatics team for Confirmed Cases that do not have the event classification of confirmed
    /********************************************************************/  
    global class Informatics extends CaseQueueProcessVirtual {
        public override Queue_Allocation__c checkForMatchOnAllocationRule() {
            for (Queue_Allocation__c queueAlloc : allocationRules) {
                if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName == 'COVID_19_Case_Assessment' 
                        && currentCase.Status == 'Trace' 
                        && currentCase.Case_Classification__c != 'Confirmed'){
                    return queueAlloc;
                }
            }
        return null;
        }
    }

    /********************************************************************
    * @Author             : Rahul Ankireddypalli
    * @Description        : Class to Process Casual Contact Record case records
                            Added for Feature 271921
    /********************************************************************/
    global class CasualContactNoPermitType extends CaseQueueProcessVirtual {
        public override Queue_Allocation__c checkForMatchOnAllocationRule() {
            for (Queue_Allocation__c queueAlloc : allocationRules) {
                if(CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName == 'Casual_Contact' && currentCase.Status == 'Active' && currentCase.permit_Type__c == Null ){             
                    return queueAlloc;
                }
            }
        return null;
        }
    }
}