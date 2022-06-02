/*
 * @Author             : Jiten Joysar
 * @Description        : DHHS PathologySlip Extension to load dynamic data required for the pdf page
 * @Modification Log   : 
 * -------------------------------------------------------------------------
 * Date           Author      		    Details
 * -------------------------------------------------------------------------
 * 24/02/2021     Jiten Joysar          Initial version
*/
public class DHHSPathologySlipExtension {
    
    public final Case recordDetails {get; private set;}

    /********************************************************************/
    /* constructor to get record Id on load of the page 
    /********************************************************************/
    public DHHSPathologySlipExtension(ApexPages.StandardController stdController) {
        this.recordDetails = getCaseRecordDetails(((Case)stdController.getRecord()).Id);
    }
    
    /********************************************************************/
    /* Function to query case details from Database based on parrameter
        passed (Case Id) */
    /********************************************************************/
    public Case getCaseRecordDetails(Id caseId){
        return [SELECT Id,
                        AccountId,
                        CaseNumber,
                        Account.LastName,
                        Account.FirstName,
                        Account.PersonBirthdate,
                        Account.Sex__c,
                        Account.PersonMailingAddress,
                        Account.PersonMailingStreet,
                        Account.PersonMailingCity,
                        Account.PersonMailingState,
                        Account.PersonMailingPostalCode,
                        Account.PersonMailingCountry,
                        Account.PersonHomePhone,
                        Account.Fax,
                        Account.PersonMobilePhone
                FROM CASE WHERE ID =: caseId];
    }
}