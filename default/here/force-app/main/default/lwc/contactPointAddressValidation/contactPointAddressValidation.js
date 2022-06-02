import {LightningElement, api, track, wire} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAddressValidationMessage from "@salesforce/apex/ContactPointAddressValidation.getMessage";


/*
    Author : Rahul Ankireddypalli
    PBI 3041093 : AddressManagement UI Changes
    This Page is Used to Invoke ContactPointAddressValidation LWC component from VF PAge

*/
export default class ContactPointAddressValidation extends LightningElement {
    @api recordId;
    @track validationMessage = '';
    @track showMessage = false;
    connectedCallback(){
       this.showMessage = true;
       this.getAddressValidations();
       if(this.validationMessage != ''){
        this.showWarningToast(this.validationMessage);
       }
    }
    getAddressValidations(){
        getAddressValidationMessage({CPArecordId : this.recordId})
        .then(result => {
            if(result != null){
                this.validationMessage = result;
            }
            else{
                this.showMessage = false;
            }
        })
        .catch(error => {
            this.error = error;
        });
    }

    handleMessage() {
        this.showMessage = false;
        }


    /****************************************************/
    /* Function to handle WARNING Toast message */
    /****************************************************/
    showWarningToast(warningMessage) {
    const evt = new ShowToastEvent({
        title: '  WARNING !!!',
        message: warningMessage,
        variant: 'warning',
        mode: 'dismissible'
    });
    this.dispatchEvent(evt);
    }
    
}

