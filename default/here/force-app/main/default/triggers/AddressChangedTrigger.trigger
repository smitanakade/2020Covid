/**
* @Author             : Pratyush Chalasani
* @Description        : Account platform event trigger
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author      		    Details
* ---------------------------------------------------
* 26/08/2021     Pratyush Chalasani    Feature 305103: Address Management - ELR merge rules
**/
trigger AddressChangedTrigger on Account_Changed_Address__e (after insert) {
    //#305103
    AccountPEHandler.insertMergedAddresses((List<Account_Changed_Address__e>)Trigger.New);
}