/**
 * @Author             : Darko Jovanovic
 * @Description        : Account trigger
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 28/11/2020     Darko Jovanovic       Feature 230036: Duplicate Check tool implementation - Initial version
**/
trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new AccountTriggerHandler().run();
}
