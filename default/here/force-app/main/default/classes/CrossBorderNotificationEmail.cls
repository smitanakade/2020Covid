/**
* @Author             : Sai Kallu
* @Description        : Case trigger handler
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author                 Details
* ---------------------------------------------------
* 23/06/2021     Sai Kallu             Feature 277236: Cross Border Notifications - Identification

**/

public class CrossBorderNotificationEmail {
    
    public static Id closeContactRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Close_Contact').getRecordTypeId();
    public static Id confirmedCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('COVID_19_Case_Assessment').getRecordTypeId();
    
    // Feature 277236: Cross Border Notifications - Identification
    public static void validateCrossBorderIdentificationFlags(map<id,sObject> recMap, map<id,sObject> oldMap){
        
        set<Case> caseList = new set<Case>();
        list<sObject> recList = new list<sObject>(recMap.values());
        
        for(sObject sObj : recList){
            Case caseRec = (Case) sObj;
            Case oldCase = (Case) oldMap.get(caseRec.Id);
            if(caseRec.Requires_cross_border_data_transfer__c != oldCase.Requires_cross_border_data_transfer__c && caseRec.Requires_cross_border_data_transfer__c && (caseRec.RecordTypeId == closeContactRecordTypeId || caseRec.RecordTypeId == confirmedCaseRecordTypeId)) {
                caseList.add(caseRec);
                system.debug(caseRec);
                
            }
            
            if(caseRec.Cross_border_data_transfer_complete__c != oldCase.Cross_border_data_transfer_complete__c && caseRec.Cross_border_data_transfer_complete__c && caseRec.Cross_border_data_transfer_complete_date__c == null){
                caseRec.Cross_border_data_transfer_complete_date__c = system.now();
            }
            if(caseRec.Cross_border_data_transfer_complete__c != oldCase.Cross_border_data_transfer_complete__c && caseRec.Cross_border_data_transfer_complete__c == FALSE)
            {
                caseRec.Cross_border_data_transfer_complete_date__c = NULL;
            }
        }
        
        try{
            EmailTemplate closeContacttemplateId;
                if(caseList.size() > 0){
                closeContacttemplateId = [SELECT DeveloperName, OwnerId, Id, Name, IsActive, Subject, HtmlValue, Body FROM EmailTemplate where DeveloperName = 'Email_DIME_to_notify_other_jurisdiction_Close_Contact'];
            }
            
            String[] toAddresses = new String[] {System.Label.DIME_team_Email_Id};
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                for(Case caseRec : caseList){
                mails.add(CrossBorderNotificationEmail.sendEmail(closeContacttemplateId, caseRec.Id, toAddresses));         
            }
             Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);

        }
        catch(Exception e){
            Application_Log__c appLog = new Application_Log__c(Message__c = e.getMessage(),Stack_Trace__c = e.getStackTraceString(),Source__c = 'CrossBorderNotificationEmail',Source_Function__c = 'validateCrossBorderIdentificationFlags', Transaction_Date__c = System.now());
            insert appLog;
            system.debug('e.getLineNumber ' + e.getLineNumber());
            system.debug('e.getMessage ' + e.getMessage());
        }
    }
    
    
    public static Messaging.SingleEmailMessage sendEmail(EmailTemplate template,Id whatId,list<string> toAddresses){
        system.debug('Inside Send Email Method');
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toaddresses = toAddresses;
        message.TemplateId = template.Id;
        message.setTreatBodiesAsTemplate(true);
        message.setSubject(template.Subject);
        message.optOutPolicy = 'FILTER';
        message.setWhatId(whatId);
        message.setPlainTextBody(template.Body);
        message.setSaveAsActivity(false);
        system.debug('Message ' + message);
        return message;
    } 
    
    //Feature 277236: Cross Border Notifications - Identification
    //Method to run before the insertion of record.
    //Email sent and TimeStamp to update
    public static void validateCrossBorderIdentificationFlagsInsert(List<Sobject> recordList) {
        
        set<Case> caseSet = new set<Case>();
        for(Sobject sObj: recordList){
            Case caseRec = (Case) sObj;
            if(caseRec.Requires_cross_border_data_transfer__c && (caseRec.RecordTypeId == closeContactRecordTypeId || caseRec.RecordTypeId == confirmedCaseRecordTypeId)){
                caseSet.add(caseRec);               
            }
        }
        
        list<case> caseList = [SELECT Id,Cross_border_data_transfer_complete__c,Cross_border_data_transfer_complete_date__c FROM case WHERE Id IN:caseSet];
        list<case> caseUpdateList = new list<case>();
        try{
        for(case caseRec : caseList){
            if(caseRec.Cross_border_data_transfer_complete__c && (caseRec.Cross_border_data_transfer_complete_date__c == null || caseRec.Cross_border_data_transfer_complete_date__c == system.now())){
                caseRec.Cross_border_data_transfer_complete_date__c = system.now();
                    caseUpdateList.add(caseRec);
            }
        }
        update caseUpdateList;
            EmailTemplate closeContacttemplateId;
                if(caseList.size() > 0){
                closeContacttemplateId = [SELECT DeveloperName, OwnerId, Id, Name, IsActive, Subject, HtmlValue, Body FROM EmailTemplate where DeveloperName = 'Email_DIME_to_notify_other_jurisdiction_Close_Contact'];
            }
            
            String[] toAddresses = new String[] {System.Label.DIME_team_Email_Id};
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                for(Case caseRec : caseList){
                mails.add(CrossBorderNotificationEmail.sendEmail(closeContacttemplateId, caseRec.Id, toAddresses));         
            }
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            
            
        }
        catch(Exception e){
            Application_Log__c appLog = new Application_Log__c(Message__c = e.getMessage(),Stack_Trace__c = e.getStackTraceString(),Source__c = 'CrossBorderNotificationEmail',Source_Function__c = 'validateCrossBorderIdentificationFlagsInsert', Transaction_Date__c = System.now());
            insert appLog;
            system.debug('e.getLineNumber ' + e.getLineNumber());
            system.debug('e.getMessage ' + e.getMessage());
        }
    
        
    }
    
}