import { LightningElement, api,wire,track } from 'lwc';
import Disability_FIELD from '@salesforce/schema/Case.Does_record_receive_disability_support__c';
import HW_FIELD from '@salesforce/schema/Case.Healthcare_Worker__c';
import HQ_FIELD from '@salesforce/schema/Case.HQ_staff_or_Household__c';
import CASE_ID from '@salesforce/schema/WorkOrder.CaseId';
import { getRecord } from 'lightning/uiRecordApi';
import createRecord from '@salesforce/apex/ShortformClinicalTabControler.createWSCRecord';
import { subscribe, unsubscribe, MessageContext,publish } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import UPDATEINTERVIEW from '@salesforce/messageChannel/ShortFormInterview__c';

export default class Dhhs_Shortform_disabilitydetails extends LightningElement {

    @api recordId;
    error;
    record;
    caseid = '';
    isloading = false;
    detailClassname = 'slds-accordion__section slds-is-open';
    detailIconname = 'utility:chevrondown';

    wscClassname = 'slds-accordion__section slds-is-open';
    wscIconname = 'utility:chevrondown';

    endTime_error = false;

    fields = [Disability_FIELD,HW_FIELD,HQ_FIELD];

    //handle toggle of Details tab
    detailToggle(){
        if(this.detailClassname.includes('open')){
            this.detailClassname = 'slds-accordion__section';
            this.detailIconname = 'utility:add';
        }else{
            this.detailClassname = 'slds-accordion__section slds-is-open';
            this.detailIconname = 'utility:chevrondown';
        }
    }

    //handle toggle of Work/Study/Care entry tab
    wscToggle(){
        if(this.wscClassname.includes('open')){
            this.wscClassname = 'slds-accordion__section';
            this.wscIconname = 'utility:add';
        }else{
            this.wscClassname = 'slds-accordion__section slds-is-open';
            this.wscIconname = 'utility:chevrondown';
        }
    }

    
    @wire(getRecord, { recordId: '$recordId', fields: [CASE_ID] })
    wiredAccount({ error, data }) {
        if (data) {
            this.caseid = data.fields.CaseId.value ;
           
        } else if (error) {
            this.error = error;
        }
        debugger;
    }

    @wire(MessageContext)
    messageContext;

    handleSubmit(event){
            event.preventDefault();       // stop the form from submitting
            const fields = event.detail.fields;
            if(fields.Does_record_receive_disability_support__c == 'Yes'){
                fields.Does_record_have_disability__c = 'Yes';
            }
            this.template.querySelector('lightning-record-form').submit(fields);
    }

    //handle the end time field change, do date time validation
    handleChange(event){
        if(new Date(event.target.value) > new Date()){
            this.endTime_error = true;
        }else{
            this.endTime_error = false;
        }
    }

    //save the form
    wscSubmit(event){
        if(this.endTime_error){
            this.showToast("Date time last attended should not be a future time.");
            return;
        }

        const inputFields = this.template.querySelectorAll('lightning-input-field');//get all the input fields

        const contactEncounter={};//data object pass to backend

        //set value to ghe data object from the input fields
        inputFields.forEach(field => {
            switch (field.fieldName) {
                case 'Employment_Status__c':
                    contactEncounter.Employment_Status__c = field.value;
                case 'Occupation__c':
                    contactEncounter.Occupation__c = field.value;
                case 'Location__c':
                    contactEncounter.Location__c = field.value;
                case 'Within_Period_of_Interest__c':
                    contactEncounter.Within_Period_of_Interest__c = field.value;
                case 'End_Time__c':
                    contactEncounter.End_Time__c = field.value;    
                case 'Description':
                    contactEncounter.Description = field.value;   
            }
        });

        contactEncounter.Work_Order__c = this.recordId;

        //call backend save funtion
        createRecord({theData : contactEncounter}).then((resp)=>{
            this.showSpinner = false;
            this.showToast(resp);

            const message12 = {
                workOrderId: this.recordId
            };
            publish(this.messageContext, UPDATEINTERVIEW, message12);

            this.handleReset();
        }).catch((err) => {
            this.showSpinner = false;
            console.log(JSON.stringify(err));
            this.showToast(null);
        });
    }

    //reset all the fields in the edit form after save
    handleReset() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
     }

    //show toast message
    showToast(result) {
        let message;
        let type;

        if(result == 'success'){
            type = 'success';
            message = 'Related records have been saved.';
        }else{
            type = 'error';
            message = result;
        }

        const event = new ShowToastEvent({
            title: 'Message',
            message: message,
            variant: type,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}