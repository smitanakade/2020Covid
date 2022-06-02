/**
 * @Author             : Sukumar Salla
 * @Description        : ContactPointAddress trigger
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 06/09/2021     Sukumar Salla       PBI 304103: Address Management - UI Changes
**/

trigger ContactPointAddressTrigger on ContactPointAddress (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new ContactPointAddressTriggerHandler().run();
}