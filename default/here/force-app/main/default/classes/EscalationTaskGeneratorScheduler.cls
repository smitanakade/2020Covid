/**
 * Created by marcelo.cost on 17/12/20.
 */

public with sharing class EscalationTaskGeneratorScheduler implements Schedulable{

    public static void execute(SchedulableContext sc)
    {
        Database.executeBatch(new EscalationTaskGeneratorBatch(),200);
    }
}