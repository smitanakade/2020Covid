/**
 * @Author             : Pratyush Chalasani
 * @Description        : PE handler for merging account addresses
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date          Author                Details
 * ---------------------------------------------------
 * 19/09/2021    Pratyush Chalasani    Feature 330329: Address Management - ELR merge rules (blank address)
 * 28/10/2021    Pratyush Chalasani    Hotfix 332208: CPA entry is created after merging the ELR record with missing Suburb
**/

public class AccountPEHandler {
    
   
        
    /** Async framework method for inserts
     * 
     */
    public static void asyncInsert(List<Account> accounts) {
        //PBI 316825 - Creating Support Officer Task Aynchronously.
         AccountTriggerHelper.createTaskforCulturalSupportOfficer(accounts, null);   
     }
 
      /** Async framework method for updates
      * 
      */
 
     public static void asyncUpdate(List<Account> accounts, Map<Id, SObject> oldAccounts) {
        //PBI 316825 - Creating Support Officer Task Aynchronously.
        AccountTriggerHelper.createTaskforCulturalSupportOfficer(accounts, oldAccounts);      
     }

    public static void insertMergedAddresses(List<Account_Changed_Address__e> changeEvents) {
        List<ContactPointAddress> changedAddresses = new List<ContactPointAddress>();
        
        List<Account> copiedAddresses = new List<Account>();

        Set<Id> masterIDs = new Set<Id>();
        Set<Id> mergedIDs = new Set<Id>();

        Map<Id, Id> mergedToMaster = new Map<Id, Id>();

        for (Account_Changed_Address__e changed: changeEvents) {
            masterIDs.add(changed.Account_ID__c);
            mergedIDs.add(changed.Merged_ID__c);

            mergedToMaster.put(changed.Merged_ID__c, changed.Account_ID__c);
        }

        Map<Id, Account> masterAccountMap = new Map<Id, Account>([SELECT Id, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, CreatedDate FROM Account WHERE (Id IN :masterIDs) FOR UPDATE]);

        for (Account merged: [SELECT Id, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, CreatedDate FROM Account WHERE (Id IN :mergedIDs) AND (IsDeleted = true) AND (CreatedBy.Name = 'Integration User') ALL ROWS]) {
            Account master = masterAccountMap.get(mergedToMaster.get(merged.Id));

            if (isAddressBlank(master) && !isAddressBlank(merged)) { // #330329
                // If the master address is blank and the merged address is not,
                // then copy the address from merged to master instead of creating a CPA record

                master.PersonMailingStreet     = merged.PersonMailingStreet;
                master.PersonMailingCity       = merged.PersonMailingCity;
                master.PersonMailingState      = merged.PersonMailingState;
                master.PersonMailingPostalCode = merged.PersonMailingPostalCode;
                master.PersonMailingCountry    = merged.PersonMailingCountry;

                copiedAddresses.add(master);
            } else if (!isAddressBlank(merged) && isAddressDifferent(master, merged)) {
                // #305103, #332208
                // Only add a CPA record if the merged address is not blank and is different to master address

                changedAddresses.add(new ContactPointAddress(
                    ParentId       = master.Id,
                    Name           = 'Merged Address',
                    AddressType    = 'ELR',
                    ActiveFromDate = merged.CreatedDate.date(),
                    ActiveToDate   = merged.CreatedDate.date(),
                    Street         = merged.PersonMailingStreet,
                    City           = merged.PersonMailingCity,
                    State          = merged.PersonMailingState,
                    PostalCode     = merged.PersonMailingPostalCode,
                    Country        = merged.PersonMailingCountry
                ));
            }
        }

        try {
            if (!changedAddresses.isEmpty()) insert changedAddresses;

            if (!copiedAddresses.isEmpty()) {
                // Copy addresses without running all the triggers again
                TriggerHandler.bypass('AccountTriggerHandler');
                update copiedAddresses;
                TriggerHandler.clearBypass('AccountTriggerHandler');
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }

    // #330329: Address is considered blank if any of the Street, City, or Postcode fields are blank
    private static Boolean isAddressBlank(Account acc) {
        return (String.isBlank(acc.PersonMailingStreet) || String.isBlank(acc.PersonMailingCity) || String.isBlank(acc.PersonMailingPostalCode));
    }

    private static Boolean isAddressDifferent(Account master, Account merged) {
               // #330329: Only return true if the account being merged has all the Street, City and Postcode fields filled
        return (String.isNotBlank(merged.PersonMailingStreet) && String.isNotBlank(merged.PersonMailingCity) && String.isNotBlank(merged.PersonMailingPostalCode)) &&

               // The rest of this logic is from #305103
               ((master.PersonMailingStreet != null)     && !master.PersonMailingStreet.equalsIgnoreCase(merged.PersonMailingStreet)) ||
               ((master.PersonMailingCity != null)       && !master.PersonMailingCity.equalsIgnoreCase(merged.PersonMailingCity)) ||
               ((master.PersonMailingState != null)      && !master.PersonMailingState.equalsIgnoreCase(merged.PersonMailingState)) ||
               ((master.PersonMailingPostalCode != null) && !master.PersonMailingPostalCode.equalsIgnoreCase(merged.PersonMailingPostalCode)) ||
               ((master.PersonMailingCountry != null)    && !master.PersonMailingCountry.equalsIgnoreCase(merged.PersonMailingCountry));
    }
}