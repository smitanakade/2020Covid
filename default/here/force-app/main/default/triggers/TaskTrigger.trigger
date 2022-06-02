/**
 * @Author             : marcelo.cost
 * @Description        : Task Trigger
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 10/12/2020     marcelo.cost          Initial version
 * 16/03/2021     Nikhil Verma          254881: add before insert, before update events
**/

trigger TaskTrigger on Task (before insert, after insert, before update) {
	new TaskTriggerHandler().run();
}