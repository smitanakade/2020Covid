import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';

import ACCOUNT_ID_FIELD from '@salesforce/schema/WorkOrder.AccountId';
import updateAccountAction from '@salesforce/apex/AddressLookupController.updateAccountAction'; 
import getAccountAddress from '@salesforce/apex/AddressLookupController.getAccountAddress';

import UPDATEINTERVIEW from '@salesforce/messageChannel/ShortFormInterview__c';


export default class AddressLookupWO extends NavigationMixin(LightningElement) {

    @api recordId;
    
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_ID_FIELD] })
    wOrder;

    //@wire(getRecord, { recordId: '$wOrder.AccountId', fields: [ACCOUNT_ID_FIELD_1, STREET_ADDRESS_FIELD] })
    acct;
    
    //casedetailfields = [NAME_FIELD, MAILING_ADDRESS_FIELD]; 
    //demographicsfields = [ATSI_FIELD, SUP_OFFICER_FIELD, COUNTRY_OF_BIRTH_FIELD, LANGUAGE_SPOKEN_FIELD, INTERPRETER_REQUIRED_FIELD, TRANSLATED_DOCUMENTS_FIELD, DOCUMENTS_LANGUAGE_FIELD];
    
    //spinner flag
    showSpinner = false;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        getAccountAddress({ workOrderId: this.recordId })
        .then(result => {
            this.acct = result;
            
         })
        .catch(error => {
            this.error = error;
        });
    }

    get propertyId() {
        return getFieldValue(this.acct.data, ACCOUNT_ID_FIELD);
    }
  
    
     
   changeHandler(event) {
        this.acct.PersonMailingStreet =  event.target.street;
        this.acct.PersonMailingCity =  event.target.city;
        this.acct.PersonMailingState =  event.target.province;
        this.acct.PersonMailingPostalCode = event.target.postalCode;
        this.acct.PersonMailingCountry = event.target.country;
         
        console.log('City => ' , event.target.city);
        console.log('Province => ' , event.target.province);
        console.log('Country => ' , event.target.country);
        console.log('postal Code => ' , event.target.postalCode);
    }

    updateAccount() {

        this.showSpinner = true;
        
        updateAccountAction({ acc: this.acct })
            .then(result => {
                const evt = new ShowToastEvent({
                    title: 'Success!',
                    message: 'Address updated Successfully!',
                    variant: 'success',
                });

                this.showSpinner = false;
                this.dispatchEvent(evt);

                const message13 = {
                    workOrderId: this.recordId
                };
                publish(this.messageContext, UPDATEINTERVIEW, message13);
               //location.reload();
            })
            .catch(error => {
                this.error = error;
            });
    }
    
  }