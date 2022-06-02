/*
* Name: DHHS_MessageDeliveryErrorScheduler
* Developer: Calvin Noronha
* Created Date: Sept 25
* Purpose: Scheduled class to create an interview work order record if there is a message delivery error
* 
* 
*/
global class DHHS_MessageDeliveryErrorScheduler implements Schedulable {
    static string ERROR_STR = 'Error';
    global void execute(SchedulableContext sc){
        
        Datetime intervalMins = Datetime.now().addMinutes(-15);
        List<MessagingDeliveryError> mdeRecords = new List<MessagingDeliveryError>();
        //Fetch records
        mdeRecords = [select id,FlowEntity,Type from MessagingDeliveryError 
                      WHERE LastModifiedDate >= :intervalMins];
        
        id queueId;
        //PF 13 Oct 2020 changed to now reference the case's queue
        //Group queueName = [Select Id from Group where type='Queue'and DeveloperName='Trace_Case_queue' LIMIT 1];
        //if (queueName!=null)
        //   queueId = queueName.Id;
            
        
        System.debug('mdeRecords is' + mdeRecords);
        
        try{
            List<WorkOrder> woList = new List<WorkOrder>();
            String woRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByName().get('Interview').getRecordTypeId();
            String caseConfirmedRecordTypeID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('COVID-19 Case Assessment').getRecordTypeId();
            String caseCloseContactRecordTypeID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Close Contact').getRecordTypeId();
            List<Account> accList = new List<Account>();
            Set<Id> accIds = new Set<Id>(); 
            //Do first pass to gather account ids
            for (MessagingDeliveryError mdeRecord:mdeRecords)
            {
                System.debug('I am here 3');
                if(mdeRecord.FlowEntity != null)
                {
                    //Assume flowEntity has Account Id. 
                    accIds.add(mdeRecord.FlowEntity);
                }
            }
            
            //Query for account and their case
            Map<Id, Account> accountMap = new Map<Id, Account> ([select id,(select id,RecordTypeId,OwnerId from Cases where Status='Quarantine' OR Status='Trace' Order BY LastModifiedDate DESC)
                                                                 from Account where id in :accIds]);        
            
            for (MessagingDeliveryError mdeRecord:mdeRecords)
            {
                //Check if error
                if(mdeRecord.FlowEntity != null &&
                   mdeRecord.Type == ERROR_STR)
                {
                    System.debug('I am here 4');
                    //Create work order record
                    WorkOrder woRecord = new WorkOrder();
                    
                    //Check in the account Map for the related case. 
                    Account acc = accountMap.get(mdeRecord.FlowEntity);
                    if (acc != null && acc.cases!=null)
                    {
                        
                        woRecord.CaseId = acc.cases[0].id;
                        Id recordTypeId = acc.cases[0].RecordTypeId;
                        //PF 13 Oct 2020 changed to work on Case's queue
                        queueId = acc.cases[0].OwnerId;
                        if (recordTypeId==caseConfirmedRecordTypeID)
                        {
                            woRecord.Subject = 'Interview confirmed case';
                        }
                        else if (recordTypeId==caseCloseContactRecordTypeID)
                        {
                            woRecord.Subject = 'Interview close contact';
                        }
                        woRecord.AccountId = acc.id;
                        if (queueId!=null)
                        {
                            woRecord.OwnerId = queueId;
                        }
                    }               
                    
                    
                    woRecord.RecordTypeId = woRecordTypeID;
                    
                    //Add to list
                    woList.add(woRecord);
                }
            }
            //Insert the list
            insert(woList);
        }
        
        catch (Exception ex)
        {
            System.debug ('Exception is ' + ex);
        }
        
        
        
        
    }
    
}