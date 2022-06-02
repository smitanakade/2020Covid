/**
 * Created by marcelo.cost on 18/2/21.
 */
/*
 * @Author             : marcelo.cost
 * @Description        : 
 * @Modification Log   : 
 * -------------------------------------------------------------------------
 * Date           Author                Details
 * -------------------------------------------------------------------------
 * 18/02/2021     marcelo.cost          Initial version
 * 11/05/2021     Rahul Ankireddypalli  Added Logic to change the case record owner as per PBI 270261
 */

public virtual with sharing class CaseQueueProcessVirtual implements IQueueProcess {

    boolean succeeded = false;
    public Case currentCase;
    public List<Queue_Allocation__c> allocationRules = new List<Queue_Allocation__c>();
    public List<Queue_Allocation__c> defaultallocationRules = new List<Queue_Allocation__c>();
    public List<Business_Unit__c> allBusinessunits = new List<Business_Unit__c>();

    public void setCase(Case aCase){
        currentCase = aCase;
    }
     //Santosh Changes- start 
    public void setAllocationRules(List <Queue_Allocation__c> queueAllocations, boolean casequeueprocessvirtualcheck){
        if(!casequeueprocessvirtualcheck){
           allocationRules = queueAllocations; 
        }else{
           allocationRules = defaultallocationRules.clone();
        }
        
    }
    public void setdefaultAllocationRules(List <Queue_Allocation__c> defaultqueueAllocations){
          defaultallocationRules = defaultqueueAllocations; 
      }
    public void setBusinessUnits(List <Business_Unit__c> businessunits){
          allBusinessunits = businessunits; 
      }
	// Santosh changes- end 

    


    public Boolean execute(){
        try {
            system.debug('queueallocation record in try block is');
            
            assignOwnerForCaseBasedOnRule(checkForMatchOnAllocationRule());
 
        } catch (Exception e){
            system.debug('queueallocation record in catch block is');
            currentCase.OwnerId = CaseQueueAllocator.QUEUE_BY_NAME.get(CaseQueueAllocator.FALLBACK_QUEUE).Id;
        }

        if(!succeeded){
            if(!CaseQueueAllocator.apexRulesToBeProcessed  .isEmpty()){
               Queue_Allocation__c nextOne = CaseQueueAllocator.apexRulesToBeProcessed.remove(0);
               //TODO Exception Handler is being done by another team. Once that is ready make sure that the following exception is integrated so it doesn't fail silently
               IQueueProcess instance;
               try{
                    instance = (IQueueProcess)Type.forName(nextOne.Implementation_Class__c).newInstance();
                } catch(Exception e){
                    System.debug('Failed to retrieve the next queueAllocator. There is probably a Queue Allocation rule with a non-existing override method name');
                    System.debug(e.getMessage());
                }
                if(instance != null){
                    instance.setCase(currentCase);
                    //This have to be done as this class needs all the queues
                    //Santosh Changes- start 
                    instance.setdefaultAllocationRules(defaultallocationRules);
                    instance.setBusinessUnits(allBusinessunits);
                    if(nextOne.Implementation_Class__c !='CaseQueueProcessVirtual') {
                        instance.setAllocationRules(new List<Queue_Allocation__c>{nextOne},false);
                    }else{
                        instance.setAllocationRules(null,true);
                    }
                    
                    // Santosh changes- end 
                   succeeded = instance.execute();
                }
            }

        }
        if(succeeded==false){
            currentCase.OwnerId = CaseQueueAllocator.QUEUE_BY_NAME.get(CaseQueueAllocator.FALLBACK_QUEUE).Id;
        }
        return succeeded;

    }

    public virtual Queue_Allocation__c checkForMatchOnAllocationRule() {
        

        //Rule is simple, the wrapper is sorted by priority. The first one that matches goes through as selected. 
        for (Queue_Allocation__c queuealloc : allocationRules) {

                        
            if(queuealloc.Implementation_Class__c!=null){
                continue;
            }
            //1st eliminates recordtype issues. Recordtype of the queue alloc object must either be All or the same as the Case.
            if (queueAlloc.Record_Type__c != 'All' && queueAlloc.Record_Type__c != CaseQueueAllocator.RECORDTYPE_BY_ID.get(currentCase.RecordTypeId).DeveloperName) {
                continue;
            }

            //Now we check the postcode IF IT EXISTS, It must match the one on the record.
            // modified below condition for PBI 277160 
            if (queueAlloc.Postcode__c != null && queueAlloc.Postcode__c != CaseQueueAllocator.relatedAccountsById.get(currentCase.AccountId).PersonMailingPostalCode && currentCase.Status != 'Ex-HQ Follow-up') {
                continue;
            }

            // added new if condition for PBI 277160 
            if (queueAlloc.Postcode__c != null && queueAlloc.Postcode__c != CaseQueueAllocator.relatedAccountsById.get(currentCase.AccountId).PersonOtherPostalCode && currentCase.HQ_Resident__c && currentCase.Status == 'Ex-HQ Follow-up') {
                continue;
            }

            //Now we check the Age Limit IF IT EXISTS, It must be lower than the one on the record.
            if (queueAlloc.Age_Limit__c != null && queueAlloc.Age_Limit__c > CaseQueueAllocator.relatedAccountsById.get(currentCase.AccountId).Age_Value__pc) {
                continue;
            }

            //If address exists, the rule is: if current adress does not CONTAINS ignore.
            if (queueAlloc.Mailing_Address__c != null && !addressHasKeywords(CaseQueueAllocator.relatedAccountsById.get(currentCase.AccountId).PersonMailingAddress, new Set<String>{queueAlloc.Mailing_Address__c})) {
                continue;
            } 
            
            

            return queuealloc;
        }

        return null;
    }


    protected Boolean addressHasKeywords(Address addr, Set<String> keywords) {
        //Just null checking
        String conjunction = addr?.getStreet() == null ? '' : addr.getStreet() + ' ' + (addr?.getState() == null ? '' : addr.getState());

        for (String str : keywords) {
            if (conjunction.containsIgnoreCase(str)) {
                return true;
            }
        }
        return false;
    }

    public virtual void assignOwnerForCaseBasedOnRule(Queue_Allocation__c rule) {     
        /*// Added Logic to set the Queue Name by checking the Business Unit record as per PBI 270261 */
       
        if(rule != null){
            
            string queuename = rule.Queue_name__c;
           
            if(allBusinessunits.size()>0){
                for(Business_Unit__c BU : allBusinessunits){
                    if(BU.Queue_name__c == queuename && BU.Reroute_Ownership_ON__c){
                       queuename =  BU.Reroute_Queue_name__c;
                    }
                }
            }
            currentCase.OwnerId = CaseQueueAllocator.QUEUE_BY_NAME.get(queuename).Id;
            succeeded = true;
       

           }
       
        
         }

 
}