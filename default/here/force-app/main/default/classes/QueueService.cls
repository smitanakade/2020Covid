/*********************************************************************************
 *** @ClassName         : QueueService
 *** @Author		    : marsson
 *** @Created date    	: 10/02/2021
 **********************************************************************************/
public with sharing class QueueService {

    private static Map<String,Group> allQueuesByQueueName;
    private static List<Queue_Allocation__c> allqueueAllocationRules;

    //Singletonish way of getting List of all the Queues by name.
    public static Map<String,Group> getAllQueuesByQueueName(){
        if(allQueuesByQueueName==null){
            allQueuesByQueueName = getQueuesbyQueueName(null);
        }
        return allQueuesByQueueName;
    }

    //Returns a list of queues mapped by Queue name
    public static Map<String,Group> getQueuesbyQueueName(Set<String> groupNames){
        Map<String,Group>queueByQueueName= new Map<String,Group>();
        List<Group> queues;
        if(groupNames!=null){
            queues= [select Name, Id from Group where Type = 'Queue' AND Name IN: groupNames ];
        }else{
            queues= [select Id,Name from Group where Type = 'Queue'];
        }
        for(Group grp : queues){
            queueByQueueName.put(grp.Name, grp);
        }
        return queueByQueueName;
    }

    public static List<Queue_Allocation__c> getAllQueueAllocation(){
        if(allqueueAllocationRules==null){
            allqueueAllocationRules =[Select Id,Implementation_Class__c,Name, Age_Limit__c,Mailing_Address__c,Postcode__c,Sequence__c,Queue_Name__c,Record_Type__c,Upper_Mailing_Address__c
            FROM Queue_Allocation__c ORDER BY Sequence__c ASC ];
        }
        return allqueueAllocationRules;

    }




}