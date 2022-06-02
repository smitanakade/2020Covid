/**
 * @Author             : Chris Zhuang
 * @Description        : Batch Notification Email Service
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 16/03/2021     Chris Zhuang          Batch Notification Email Service
**/
public with sharing class BatchNotificationEmailService {
    public static final String BATCH_NOTIFICATION_EMAIL_SETTING = 'Notification_Email_Settings';

    public static void sendEmail(String batchJobName, Integer totalRecord, Integer failedRecord) {
        

        try{
            //get Global Email Settings
            List<Batch_Notification_Email_Settings__mdt> emailSetting =  [SELECT MasterLabel, Reply_to_Address__c, Sender_Display_Name__c, Email_Subject__c, Email_Body__c FROM Batch_Notification_Email_Settings__mdt 
            WHERE Is_Email_Setting__c = TRUE AND DeveloperName =: BATCH_NOTIFICATION_EMAIL_SETTING];

            if (emailSetting.isEmpty()) {
            //if there is not email settings found.
            return;
            }

            //get a list of person who want to receive the batch notification emails
            List<String> toEmailList = new  List<String>();
            For (Batch_Notification_Email_Settings__mdt es : [SELECT MasterLabel, To_Email_Address__c FROM Batch_Notification_Email_Settings__mdt 
            WHERE To_Email_Address__c != NULL AND Is_Email_Setting__c = FALSE]) {
            toEmailList.add(es.To_Email_Address__c);
            }

            //send email to the list of email address above
            if (!toEmailList.isEmpty()) {
                Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
                semail.setReplyTo(emailSetting[0].Reply_to_Address__c);
                semail.setSenderDisplayName(emailSetting[0].Sender_Display_Name__c);
                semail.setSubject(emailSetting[0].Email_Subject__c);
                semail.setToAddresses(toEmailList);
                semail.setPlainTextBody(String.format(emailSetting[0].Email_Body__c, new List<String>{batchJobName, String.valueOf(totalRecord), String.valueOf(failedRecord)}));
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
            }
        }catch(Exception exp){
            ApplicationLogUtility.createlog('BatchNotificationEmailService','sendEmail',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
    }
}