/**
 * @Author             : Chris Zhuang
 * @Description        : TEST for Batch Notification Email Service
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 16/03/2021     Chris Zhuang          TEST for Batch Notification Email Service
**/
@isTest
private class BatchNotificationEmailServiceTest {
    @IsTest
    static void Test_SendEmail() {
        try{
            Test.startTest();
            BatchNotificationEmailService.sendEmail('testBatchJob', 100, 6);
            Test.stopTest();

            // check the emailMessage
            List<emailMessage> emailList = [select Id, TextBody from emailMessage];
            if (!emailList.isEmpty()) {
                System.assertEquals('The testBatchJob batch job completed and successfully! A total of 100 number of records were processed with 6 number of errors', emailList[0].TextBody, 'Emails have been sent.');
            }
        }catch(Exception exp){
            ApplicationLogUtility.createlog('BatchNotificationEmailServiceTest','Test_SendEmail',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            throw exp;
        }
        
    }
}