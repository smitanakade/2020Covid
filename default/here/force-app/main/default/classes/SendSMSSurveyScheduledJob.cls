public class SendSMSSurveyScheduledJob implements Schedulable {
    public void execute(SchedulableContext SC){
        GenerateSMSSurveyBatchProcess b = new GenerateSMSSurveyBatchProcess();
        database.executebatch(b, 10);
    }
}