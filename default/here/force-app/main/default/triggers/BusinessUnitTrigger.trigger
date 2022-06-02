/*
Author: Rahul Ankireddypalli

@Modification Log   : 
---------------------------------------------------
Date           Author      		    Details
---------------------------------------------------
07/06/2021     Rahul Ankireddypalli       Intial Version : PBI 270261
*/trigger BusinessUnitTrigger on Business_Unit__c (before insert, before update) {
    new BusinessUnitHandler().run();  
}