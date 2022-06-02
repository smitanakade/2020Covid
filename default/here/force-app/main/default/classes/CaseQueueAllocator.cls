/*********************************************************************************
 *** @ClassName         : CaseQueueAllocator
 *** @Author		    : marsson
 *** @Created date    	: 10/02/2021
 *** NOTES:  
  For this constructor, we MUST pass the map of account related to the Cases. The implementation of this piece is suboptimal, as it has to be a
  complete copy of the FLOW implementation. That left little design choice.
  Recomend to implement a proper command pattern + decorator.

 **********************************************************************************/

public with sharing class CaseQueueAllocator {

    public final static String FALLBACK_QUEUE = 'COVID Coordination Unit';
    public final static Map<Id,RecordTypeInfo> RECORDTYPE_BY_ID=Schema.SObjectType.Case.getRecordTypeInfosById();
    public final static Map<String,Group>QUEUE_BY_NAME = QueueService.getAllQueuesByQueueName();
    public static List<Queue_Allocation__c> apexRulesToBeProcessed = [SELECT Implementation_Class__c, Queue_Name__c from Queue_Allocation__c WHERE Implementation_Class__c !=null ];
  	public List<Queue_Allocation__c> apexRulesToBeProcessedReset = new List<Queue_Allocation__c>();
    public List<Queue_Allocation__c> defaultallocationRules = new List<Queue_Allocation__c>();
    public List<Business_Unit__c> allBusinessunits = new List<Business_Unit__c>();
    
    public  static Map<Id,Account> relatedAccountsById;
    private List<Case>casesToAllocate= new List<Case>();


    public void run(){
        execute();
    }

    public CaseQueueAllocator(List<Case> cases, Map<Id,Account> accountsByIds) {
        if(apexRulesToBeProcessed.size() == 0 || apexRulesToBeProcessed == null){
            apexRulesToBeProcessed = [SELECT Implementation_Class__c, Queue_Name__c from Queue_Allocation__c WHERE Implementation_Class__c !=null ];
        }
        relatedAccountsById = accountsByIds;
        //This must be done to run the default rules

        apexRulesToBeProcessed.add(New Queue_Allocation__c(Implementation_Class__c='CaseQueueProcessVirtual'));
        
         if(apexRulesToBeProcessedReset.isEmpty()){
            apexRulesToBeProcessedReset = apexRulesToBeProcessed.clone();  
          }
        defaultallocationRules = QueueService.getAllQueueAllocation();
        allBusinessunits = [select id, Queue_name__c, Reroute_Queue_name__c, Reroute_Ownership_ON__c from Business_Unit__c where  queue_name__c != ''];
        preExecute(cases);

    }

    private void preExecute(List<Case> cases){

      casesToAllocate = cases;
    }
    private void execute(){


        for(Case acase:casesToAllocate ){
              
                if(!apexRulesToBeProcessed.isEmpty()){
                    Queue_Allocation__c nextOne = CaseQueueAllocator.apexRulesToBeProcessed.remove(0);
                    //System.debug('ALLOCATION='+nextOne.Implementation_Class__c);
                    IQueueProcess instance = (IQueueProcess)Type.forName(nextOne.Implementation_Class__c).newInstance();
                    instance.setCase(acase);
                      //Santosh Changes- start 
                    instance.setdefaultAllocationRules(defaultallocationRules);
                    instance.setBusinessUnits(allBusinessunits);
                    if(nextOne.Implementation_Class__c !='CaseQueueProcessVirtual') {
                        instance.setAllocationRules(new List<Queue_Allocation__c>{nextOne},false);
                    }else{
                        instance.setAllocationRules(null,true);
                    }
                    
                    // Santosh changes- end 
                    instance.execute();
                }
              
                if(!apexRulesToBeProcessedReset.isEmpty() && apexRulesToBeProcessed.size() < apexRulesToBeProcessedReset.size()){
                    apexRulesToBeProcessed.clear();
                    apexRulesToBeProcessed = apexRulesToBeProcessedReset.clone(); 
                }
                
            
        }

    }

}