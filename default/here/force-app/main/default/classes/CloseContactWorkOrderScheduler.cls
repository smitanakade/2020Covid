
/**
 * @Author             : Chris Zhuang
 * @Description        : Scheduler for create Secondary Close Contact Clearance WorkOrder
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 16/03/2021     Chris Zhuang          Feature 269161: All interview work orders should be automatically be created when new confirmed case or new primary close contact record is created - Part 3 (AC03)
**/
public with sharing class CloseContactWorkOrderScheduler implements Schedulable{
    public static void execute(SchedulableContext sc){
        Database.executeBatch(new CloseContactWorkOrderBatchJob(),200);
    }
}
