/*
    Created by: YPerera
    
    @Modification Log   :
    ---------------------------------------------------
    Date           Author      		    Details
    24/03/2021     YPerera           	Feature 265632: Close Contact Clearance Work Order - Close Contact Day 14 Notification
    ---------------------------------------------------
*/
public with sharing class GenerateCloseContactClearanceWOScheduler implements Schedulable {
    
    public static void execute(SchedulableContext sc){
        Database.executeBatch(new GenerateCloseContactClearanceWOBatch(), 200);
    }
    
}