import { LightningElement,wire,api,track } from 'lwc';
import { getRecord, updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getSobjectRecordFieldValue from '@salesforce/apex/SystemUtils.getSobjectRecordFieldValue';
import getSobjectRecordFieldValueFromRelatedObject from '@salesforce/apex/SystemUtils.getSobjectRecordFieldValueFromRelatedObject';

export default class MultiSelectPicklistExtendedForm extends LightningElement {
    @api title;
    @api objectApiName;
    @api recordId;

    @track yourSelectedValues;

    @api sourceobject; //from property
    @api sourcefield; //from property
    @api targetobject; //from property
    @api targetfield; //from property
    @api targetrelationshipfield; //from property
    @api targetrecordid; //Automatically calculated

    @api existingvalues = [];

    connectedCallback() {
        this.getExistingFieldValues();
    }

    handleSubmit2() {
        const fields = {};

        //This could be a lookup or default id field
        if (this.targetrelationshipfield == 'Id') {
            this.targetrecordid = this.recordId;
            fields['Id'] = this.recordId;  //Id = 001xxxxx
        } else {
            fields['Id'] = this.targetrecordid;
        }
        fields[this.targetfield] = this.yourSelectedValues;

        const recordInput = {
            fields: fields
        };

        updateRecord(recordInput).then((record) => {
            this.getExistingFieldValues();
            this.showToast('Success', 'Record updated successfully!' , 'success');
        }).catch(error => {
            console.log(error);
        });

        getRecordNotifyChange([{recordId: this.recordId}]);
    }

    handleOnItemSelected(event) {
        if (event.detail) {
            this.yourSelectedValues = "";
            let self = this;

            event.detail.forEach(function (eachItem) {
                self.yourSelectedValues += eachItem.value + ";";
            });
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            variant : variant,
            message: message,
        });
        this.dispatchEvent(event);
    }

    getExistingFieldValues() {

        if (this.targetrelationshipfield == 'Id') {
            getSobjectRecordFieldValue({ objectAPIName: this.targetobject, fieldAPIName: this.targetfield, recordid: this.recordId })
                .then((result) => {
                if (result) {
                    this.existingvalues = result.split(';');
                } else {
                    this.existingvalues = '';
                }
            })

        } else {
            getSobjectRecordFieldValue({ objectAPIName: this.objectApiName, fieldAPIName: this.targetrelationshipfield, recordid:  this.recordId })
                .then((result) => {
                if (result) {
                    this.targetrecordid = result;

                    /*getSobjectRecordFieldValue({ objectAPIName: this.targetobject, fieldAPIName: this.targetfield, recordid:  this.targetrecordid })
                        .then((result) => {
                        if (result) {
                            this.existingvalues = result.split(';');
                        } else {
                            this.existingvalues = '';
                        }
                    })*/
                }
            })

            getSobjectRecordFieldValueFromRelatedObject({ childObjectAPIName: this.objectApiName, parentObjectAPIName:  this.targetobject
                                        , relationshipfieldAPIName: this.targetrelationshipfield,   fieldAPIName: this.targetfield, recordid:  this.recordId })
                .then((result) => {
                if (result) {
                    this.existingvalues = result.split(';');
                } else {
                    this.existingvalues = '';
                }
            })





        }
    }
}