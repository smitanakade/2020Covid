/**
* @Author             : DHHS
* @Description        : Send Email To Queue
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 09/11/2021     Aref S                PBI 309115 : Email Notification To Queue when a Confirmed Case is Auto-allocated  
**/

public class SendEmailToConfirmedCaseQueue {
    
    @testVisible
    private static Boolean EmailSent = false;

     /**
     * Send emails for all the cases
     */
    public void sendEmailToCaseQueues(List<Case> cases)
    {
        Map<Id,Set<Id>> casesByOwnerIds=new Map<Id,Set<Id>>();
        Map<Id,List<string>> emailsByOwnerIds=new Map<Id,List<string>>();
      
        try {


            //Group case ids for each queue(OwnerId)
            for(Case c:cases)
            {
                Set<Id> caseIds=new Set<Id>();            
                if (casesByOwnerIds.containsKey(c.OwnerId))
                {
                    caseIds=casesByOwnerIds.get(c.OwnerId);
                }
                
                caseIds.add(c.Id); 
                casesByOwnerIds.put(c.OwnerId, caseIds); 
            }
           

            //Email ids for each queue
            for(Group gm:[SELECT Id,Email FROM Group WHERE Id IN:casesByOwnerIds.keySet() AND (Email!=null) AND Type='Queue'])
            {
                List<string> emails=new List<string>();                
                if (emailsByOwnerIds.containsKey(gm.Id))
                {
                    emails=emailsByOwnerIds.get(gm.Id); 
                } 
                emails.add(gm.Email); 
                emailsByOwnerIds.put(gm.Id, emails);
            } 

           
            //Send Email for each case
            if (!emailsByOwnerIds.isEmpty())
            {
                EmailTemplate caseAllocationTemplate = [SELECT Id,Body,Subject FROM EmailTemplate WHERE DeveloperName='Case_Allocation_Email'];            
                if (caseAllocationTemplate!=null)
                {
                    List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                    for(Id ownerId:casesByOwnerIds.keyset()){
                        List<string> toAddresses=emailsByOwnerIds.get(ownerId);
                        Set<Id> caseIds=casesByOwnerIds.get(ownerId);
                        if (caseIds!=null && !caseIds.isEmpty())
                        {
                            for(Id caseId:caseIds)
                            {
                                mails.add(createEmail(caseAllocationTemplate, caseId, toAddresses)); 
                            }                    
                        }
                                
                    }               
                    if (mails.size()>0)
                    {
                        Messaging.sendEmail(mails);
                    }
                   
                }
            }
            EmailSent=true;
            
        } catch (Exception exp) {
            ApplicationLogUtility.createlog('SendEmailToConfirmedCaseQueue','sendEmailToCaseQueues',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
        }

    }

      /**
     * Create single email message for a case. 
     * */
    @testVisible
    private Messaging.SingleEmailMessage createEmail(EmailTemplate template,Id whatId,list<string> toAddresses){
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toaddresses = toAddresses;
        message.TemplateId = template.Id;
        message.setTreatBodiesAsTemplate(true);
        message.setSubject(template.Subject);
        message.optOutPolicy = 'FILTER';
        message.setWhatId(whatId);
        message.setPlainTextBody(template.Body);
        message.setSaveAsActivity(false);        
        return message;
    } 
    
}
