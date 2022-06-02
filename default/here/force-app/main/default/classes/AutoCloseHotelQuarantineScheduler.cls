

global with sharing class AutoCloseHotelQuarantineScheduler implements Schedulable{
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new AutoCloseHotelQuarantine(),200);
    }
}