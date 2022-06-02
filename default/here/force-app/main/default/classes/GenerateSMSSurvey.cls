/**
* @Author             : DHHS
* @Description        : Generate Survey Link for Record
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author                Details 
* ---------------------------------------------------
* 30/09/2021     Aref Samad         PBI-322220 Remove Live Message dependency, use MC journey API to send SMS
**/
public class GenerateSMSSurvey {  
    
    public class FlowInputs {
        @InvocableVariable public string caseId;
        @InvocableVariable public string surveyId;
        @InvocableVariable public string surveyName;
        @InvocableVariable public string messageTemplateDeveloperName;
    }
    
    public class SmsSurveyException extends Exception {}
    
    // Invoked by Flow called "Send Survey in SMS"
    @InvocableMethod
    public static void CreateSurveyInv(List<FlowInputs> request) {
        
       // System.debug('***CreateSurveyInv - START');
        string caseId = request[0].caseId;
        string surveyId = request[0].surveyId;
        string surveyName = request[0].surveyName;
        string messageTemplateDevName = request[0].messageTemplateDeveloperName;       
        
        CreateSurveyInvWorker(caseId, surveyId, surveyName, messageTemplateDevName);
        
        System.enqueueJob(new GenerateSMSJourneyApiQueue(caseId));
        
    }
    
    // Invoked by Scheduled Apex Batch Process
    public static void CreateSurveyInv(Case currentCase){
        
        //System.debug('***CreateSurveyInv - START');
        
        // Retrive Custom Metadata describing mapping between templates and surveys
        Messaging_Template_Survey__mdt[] sMeta = [Select DeveloperName, MessagingTemplateName__c, SMS_Template_Developer_Name__c, 
                                                    Survey_Template_Developer_Name__c from Messaging_Template_Survey__mdt];
        //System.debug('***sMeta: '+sMeta);
        // Retrive the ID of each survey using the Developer Name
        Map<String, String> surveyMapping = new Map<String, String>();
        for (Survey s : [SELECT Id, DeveloperName FROM Survey]) {
            surveyMapping.put(s.DeveloperName, s.Id);
        }
        
        for (Messaging_Template_Survey__mdt day : smeta) {
            if(day.Survey_Template_Developer_Name__c != null && surveyMapping.get(day.Survey_Template_Developer_Name__c) != null) {
                Id surveyID = surveyMapping.get(day.Survey_Template_Developer_Name__c);
                switch on day.DeveloperName {
                    when 'Day_0' {
                        if (currentCase.Close_Contact_Record_Age__c == 0 && (currentCase.Status == 'Quarantine' || (currentCase.Status == 'Identify' && currentCase.Permit_Type__c == 'Red'))) {
                            CreateSurveyInvWorker(currentCase.id, surveyID, day.Survey_Template_Developer_Name__c, day.SMS_Template_Developer_Name__c);
                        }
                    }
                    when 'Day_1_9'{
                        if (((currentCase.Close_Contact_Record_Age__c >= 1 && currentCase.Close_Contact_Record_Age__c <= 9) || (currentCase.Close_Contact_Record_Age__c > 12 && currentCase.Permit_Type__c != 'Red')) && (currentCase.Status == 'Quarantine' || (currentCase.Status == 'Identify' && currentCase.Permit_Type__c == 'Red'))) {
                            CreateSurveyInvWorker(currentCase.id, surveyID, day.Survey_Template_Developer_Name__c, day.SMS_Template_Developer_Name__c);
                        }
                    }
                    when 'Day_10'{
                        if (currentCase.Close_Contact_Record_Age__c == 10 && currentCase.Status == 'Quarantine' && currentCase.Permit_Type__c != 'Red') {
                            CreateSurveyInvWorker(currentCase.id, surveyID, day.Survey_Template_Developer_Name__c, day.SMS_Template_Developer_Name__c);
                        }
                    }
                    when 'Day_11'{
                        if (currentCase.Close_Contact_Record_Age__c == 11 && (currentCase.Status == 'Quarantine' || (currentCase.Status == 'Identify' && currentCase.Permit_Type__c == 'Red'))) {
                            CreateSurveyInvWorker(currentCase.id, surveyID, day.Survey_Template_Developer_Name__c, day.SMS_Template_Developer_Name__c);
                        }
                    }
                    when 'Day_12'{
                        if ((currentCase.Close_Contact_Record_Age__c == 12 || (currentCase.Permit_Type__c == 'Red' && currentCase.Close_Contact_Record_Age__c >= 15 && currentCase.Close_Contact_Record_Age__c <= 24)) && (currentCase.Status == 'Quarantine' || (currentCase.Status == 'Identify' && currentCase.Permit_Type__c == 'Red'))) {
                            CreateSurveyInvWorker(currentCase.id, surveyID, day.Survey_Template_Developer_Name__c, day.SMS_Template_Developer_Name__c);
                        }
                    }
                    when 'Clear_Close_Contact' {
                        if (currentCase.Close_Contact_Record_Age__c == 14 && currentCase.Permit_Type__c == 'Red' && (currentCase.Status == 'Quarantine' || currentCase.Status == 'Identify')) {
                            CreateSurveyInvWorker(currentCase.id, surveyID, day.Survey_Template_Developer_Name__c, day.SMS_Template_Developer_Name__c);
                        }
                    }
                    when 'Daily_SCC_Notification'{
                        if (currentCase.Day_0_Exposure_to_primarycc__c < Date.today() && currentCase.Status == 'Quarantine') {
                            CreateSurveyInvWorker(currentCase.id, surveyID, day.Survey_Template_Developer_Name__c, day.SMS_Template_Developer_Name__c);
                        }
                    }
                    //Changes made as per user story 237774 to use Clearance_eligibility_assessment_date__c         
                    when 'Daily_Case_Notification'{
                        if (currentCase.Clearance_eligibility_assessment_date__c > Date.today() && currentCase.Status == 'Isolate') {
                            CreateSurveyInvWorker(currentCase.id, surveyID, day.Survey_Template_Developer_Name__c, day.SMS_Template_Developer_Name__c);
                        }
                    }
                    //Changes made as per user story 239169 to use Clearance_eligibility_assessment_date__c         
                    when 'Cleared_Case_Notification'{
                        if (currentCase.Clearance_eligibility_assessment_date__c == Date.today() && currentCase.Status == 'Isolate') {
                            CreateSurveyInvWorker(currentCase.id, surveyID, day.Survey_Template_Developer_Name__c, day.SMS_Template_Developer_Name__c);
                        }
                    }
                    when else {
                        System.debug('*** NOT IN METADATA   '+ day.DeveloperName);
                    }
                }
            }
        }
    }
    
    //Use parameters to update Case
    private static void CreateSurveyInvWorker(String caseId, String surveyId, String surveyName, String messageTemplateDevName){
        string communityId;
        string surveyLink; 
        Account acc;
        
        //System.debug('***START CreateSurveyInv - caseId: '+caseId+ ' surveyId:' +surveyId+ ' surveyName:' +surveyName+ ' messageTemplateDevName:' +messageTemplateDevName);
        
        Survey_SMS_Setting__mdt sMeta = [Select Community__c, DateTime_Format__c from Survey_SMS_Setting__mdt LIMIT 1];
        
        //Create survey invitation for the person account if it exists
        Case myCase = [select Id, CaseNumber, AccountId, Account.PersonContactId, MessagingTemplate__c, SurveyLinkURL__c  from case where id = :caseId];
        
        if (myCase.AccountId == null)
            throw new SmsSurveyException('There is no Account related to the case.');
        
        communityId = [select Id from Network where Name =: sMeta.Community__c].Id;   
        
        // two of the sms should not have survey
        // can we skip the generate survey and update surveylinkURL__c if if isnt?
        // just update MessagingTemplate field
        if (surveyName != null && surveyName != ''){
            string invGenTime = '_' + System.now().format(sMeta.DateTime_Format__c);
            SurveyInvitation SInv = new SurveyInvitation();
            SInv.Name = myCase.CaseNumber +  invGenTime;
            SInv.CommunityId = communityId;
            SInv.SurveyId = surveyId;
            SInv.ParticipantId = myCase.Account.PersonContactId;
            SInv.OptionsAllowGuestUserResponse = true;
            SInv.Record__c = myCase.Id;
            
            insert SInv;
            //System.debug('*** Invite ' + SInv.Id);
            
            /*This is where the survey invitation is related to another object through the SubjectId. It is related to the caseID */
            
            SurveySubject SS = new SurveySubject();
            SS.SubjectId = myCase.Id;
            SS.ParentId = SInv.Id;
            SS.Name = surveyName + '_' + myCase.Id + invGenTime;
            insert SS;
            
            /*This saves the survey link and name against the Case record.
            There is a Process Builder called 'Send Survey SMS on the Case that looks for this link being updated and does the actual sending of the message*/
            SurveyInvitation newInv = [select Id, name, invitationlink from surveyinvitation where Name = :Sinv.Name]; 
            surveyLink = newInv.InvitationLink;
            
            myCase.SurveyLinkURL__c = surveyLink;
           // System.debug('*** surveyLink:' + surveyLink);
            myCase.SurveyInvitationId__c = newInv.Id;
            //System.debug('***  newInv.Id:' +  newInv.Id);
        }
        
        myCase.MessagingTemplate__c = messageTemplateDevName;
                       
        update myCase;
    }    
    
}