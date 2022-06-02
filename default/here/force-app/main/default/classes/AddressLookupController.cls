public  with sharing class AddressLookupController {
    public AddressLookupController() {

   }
    @AuraEnabled
    public static Boolean updateAccountAction(Account acc) {
        update acc;
        return true;
    }
    @AuraEnabled
    public static Account getAccountAddress(Id workOrderId) {
        WorkOrder wo = [SELECT AccountId FROM WorkOrder WHERE Id =: workOrderId];
       return [SELECT Id, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry 
                FROM Account WHERE Id =: wo.AccountId];
    }
}