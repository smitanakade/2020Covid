import { LightningElement, api,wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import CASE_ID from '@salesforce/schema/WorkOrder.CaseId'


export default class DHHS_CaseMovementCloseContactContainer extends LightningElement {

    @api recordId;
    error;
    record;
    @api hidecontactsandcep = false;
    classname = 'slds-col slds-size_4-of-12';

    @wire(getRecord, { recordId: '$recordId', fields: [CASE_ID] })
    wiredAccount({ error, data }) {
        if (data) {
            this.record = data.fields;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record  = {CaseId:{value:this.recordId}};
        }
        debugger;
    }

    connectedCallback(){
        if(this.hidecontactsandcep){
            this.classname = 'slds-col slds-size_6-of-12'
        }
    console.log(this.recordId);


        debugger;
    }
}