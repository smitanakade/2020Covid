/*
 * @Author             : Duncan Bridges
 * @Description        : This is designed to be placed on a Record(Case) flexipage
 *                       The goal is to show/update key information of the related Person account
 *                       Which is impossible to do with a quickaction because 
 *                       Person Account - specific fields are not supported with quick actions
 * @Modification Log   : 
 * --------------------------------------------------------------------------------------
 * Date           Author      		    Details
 * --------------------------------------------------------------------------------------
 * 02/02/2020     Duncan Bridges        Initial version
 * 14/07/2021     Sai Kallu             Added fields from Record as per the PBI 277236
*/
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import DOB_FIELD from '@salesforce/schema/Account.PersonBirthdate';
import MOBILE_FIELD from '@salesforce/schema/Account.PersonMobilePhone';
import EMAIL_FIELD from '@salesforce/schema/Account.PersonEmail';
import LANGUAGE_SPOKEN_FIELD from '@salesforce/schema/Account.Language_spoken_at_home__c';
import INTERPRETER_REQUIRED_FIELD from '@salesforce/schema/Account.Interpreter_required__c';
import TRANSLATED_DOCUMENTS_FIELD from '@salesforce/schema/Account.Translated_documents_required__c';
import DOCUMENTS_LANGUAGE_FIELD from '@salesforce/schema/Account.Document_Language__c';
import ACCOUNT_ID_FIELD from '@salesforce/schema/Case.AccountId';
import ATSI_FIELD from '@salesforce/schema/Account.Aboriginal_or_Torres_Strait_Islander__c';
import SUP_OFFICER_FIELD from '@salesforce/schema/Account.Cultural_Support_Officer_Required__c';

export default class DemographicInformationForm extends NavigationMixin(LightningElement) {
    @api recordId;
    
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_ID_FIELD] })
    acct;
    
    accountfields = [NAME_FIELD, DOB_FIELD, MOBILE_FIELD, EMAIL_FIELD, LANGUAGE_SPOKEN_FIELD, INTERPRETER_REQUIRED_FIELD
    , TRANSLATED_DOCUMENTS_FIELD, DOCUMENTS_LANGUAGE_FIELD, ATSI_FIELD,SUP_OFFICER_FIELD]
   
        
     
    get propertyId() {
        return getFieldValue(this.acct.data, ACCOUNT_ID_FIELD);
    }

   
    /*handleCaseSubmit(event) {
        event.preventDefault();
        const casefields = event.detail.casefields;
        this.template.querySelector('#caseForm').submit(casefields);
    }

    handleCaseSuccess() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }*/

    /*handleAccountSubmit(event) {
        debugger;

        event.preventDefault();
        const accountfields = event.detail.accountfields;
        this.template.querySelector('#accountForm').submit(accountfields);
    }*/

    /*handleAccountSuccess() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }*/
}