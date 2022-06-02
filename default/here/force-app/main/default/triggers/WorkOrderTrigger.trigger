/*
Author: Henna Mullaji 

@Modification Log   : 
---------------------------------------------------
Date           Author      		    Details 
---------------------------------------------------
03/02/2021     Darko Jovanovic       Feature 255889: Modified to use common trigger framework
29/04/2021     Pratyush Chalasani    Hotfix 281213: Added "before update" event to handle WorkOrder allocations
*/
trigger WorkOrderTrigger on WorkOrder (before insert, before update, after update) {
    new WorkOrderTriggerHandler().run();   
}