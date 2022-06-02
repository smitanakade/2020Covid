import {LightningElement, api, track, wire} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import NotSupportedMessage from '@salesforce/label/c.NotSupportedMessage';
import {FlowNavigationNextEvent, FlowNavigationFinishEvent, FlowNavigationBackEvent} from 'lightning/flowSupport';
import {get} from "c/dhhsUtil";

export default class recordDetailFSC extends LightningElement {
    @api recordId;
    @api recordTypeId;
    @api mode = 'view';
    @api objectApiName;
    @api flowNavigationOnSave = false;
    @api flowNavigationOnCancel = false;
    @api flowNavigationOnCancelDirection = "next";
    @api isCancelButton = false;
    @api availableActions = [];
    @api showCancelButton = false;
    @api suppressToast = false;
    @api SaveBtnLabel = 'Save';
    @api CancelBtnLabel = 'Cancel';
    @api columnsize = 2;
    @api suppressUnderline = false;
    

    @track elementSize = 6;
    @track objectData;
    @track recordData;
    @track fieldsToDisplay = [];
    @track notSupportedFields = [];
    @track loadFinished = false;
    @track errors = [];

    //@api isLoaded = false;

    labels = {
        successMessage: 'Success',
        errorMessage: 'Error',
        recordSaveSuccessMessage: 'Record has been saved successfully'
    };

    restrictedFields = ['SystemModstamp'];
    readOnlyFields = ['LastModifiedDate', 'LastModifiedById', 'LastViewedDate', 'LastReferencedDate', 'CreatedDate', 'CreatedById', 'SystemModstamp'];

    connectedCallback() {
        this.cancelNavigationDirection = (this.flowNavigationOnCancelDirection.toLowerCase() === 'previous') ? 'back' : 'next';
        this.elementSize = this.columnsize? (12/this.columnsize) : 6;
    }



    @api
    get fields() {
        return this.fieldsToDisplay.join();
    }

    get fieldData() {
        return this.fieldsToDisplay.filter(curField => {
            return this.recordId || (!this.recordId && !this.readOnlyFields.includes(curField));
        }).map(curField => {
            let isError = !!this.notSupportedFields.find(curNSField => curNSField === curField) || !curField;
            return {
                fieldName: curField,
                isError: isError,
                isOutput: this.readOnlyFields.includes(curField),
                errorMessage: isError ? NotSupportedMessage + ' ' + (curField ? curField : 'null') : ''
            }
        });
    }

    searchEventHandler(event) {
        this.fields = event.detail.value;
    }

    set fields(value) {
        this.errors = [];
        if (value) {
            let fieldsArray = value.replace(/^[,\s]+|[,\s]+$/g, '').replace(/\s*,\s*/g, ',').split(',');
            this.fieldsToDisplay = fieldsArray.filter(curFieldName => !this.restrictedFields.includes(curFieldName));
        } else {
            this.fieldsToDisplay = [];
        }
    }

    @wire(getRecord, {recordId: '$recordId', layoutTypes: 'Compact'})
    wiredRecord({error, data}) {
        if (error) {
            console.log(error.body[0].message)
        } else if (data) {
            this.recordData = data;
            if (!this.objectApiName && this.recordData) {
                this.objectApiName = this.recordData.apiName;
            }
        }
    }

    @wire(getObjectInfo, {objectApiName: '$objectApiName'})
    _getObjectInfo({error, data}) {
        if (error) {
            console.log(error.body[0].message);
        } else if (data) {
            this.objectData = data;

            if (this.objectData && this.fieldsToDisplay && this.fieldsToDisplay.length === 0) {
                this.fieldsToDisplay = Object.values(this.objectData.fields).map(curField => curField.apiName);
            }

            this.notSupportedFields = this.getNotSupportedField(this.fieldsToDisplay);
            this.loadFinished = true;
        }
    }

    getNotSupportedField(fieldsToVerify) {
        let notSupportedFields = [];
        if (this.objectData) {
            fieldsToVerify.forEach(curFied => {
                if (curFied !== '' && typeof this.objectData.fields[curFied] === 'undefined') {
                    notSupportedFields.push(curFied);
                }
            });
        }
        return notSupportedFields;
    }

    get isViewMode() {
        return this.mode.toLowerCase() === 'view';
    }

    get isError() {
        return this.errors.length > 0;
    }

    handleSuccess(event) {
        this.recordId = event.detail.id;
        let recordName = event.detail.fields["Name"] === undefined ? event.detail.fields.FirstName.value + ' ' + event.detail.fields.LastName.value : event.detail.fields.Name.value;

        if(!this.suppressToast){
            this.loadFinished = true;
            this.showToast(this.labels.successMessage, this.labels.recordSaveSuccessMessage, 'success', true);
        }
        // is Flow Navigation selected?
        if (this.flowNavigationOnSave) {
            // check if FINISH is allowed on the flow screen
            if (this.availableActions.find(action => action === 'FINISH')) {
                const navigateFinishEvent = new FlowNavigationFinishEvent();
                this.dispatchEvent(navigateFinishEvent);
            }
            // check if NEXT is allowed on the flow screen
            if (this.availableActions.find(action => action === 'NEXT')) {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }
        } else { //modal cancel
            event.preventDefault();
            const save = new CustomEvent(
                "save",{
                    detail : {
                        id : this.recordId,
                        name : recordName
                    }
                });
            /* fire the event to be handled on the Parent Component */
            this.loadFinished = true;
            this.dispatchEvent(save);
        }
    }

    handleCancel(event) {
        // set output value to true
        this.isCancelButton = true;
        // reset field values
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
        // handle automatic Flow navigation
        if (this.flowNavigationOnCancel) {
            if (this.cancelNavigationDirection === 'back') {
                // check if BACK is allowed on the flow screen
                if (this.availableActions.find(action => action === 'BACK')) {
                    const navigateBackEvent = new FlowNavigationBackEvent();
                    this.dispatchEvent(navigateBackEvent);
                }
            }
            // check if FINISH is allowed on the flow screen
            if (this.availableActions.find(action => action === 'FINISH')) {
                const navigateFinishEvent = new FlowNavigationFinishEvent();
                this.dispatchEvent(navigateFinishEvent);
            }
            // check if NEXT is allowed on the flow screen
            if (this.availableActions.find(action => action === 'NEXT')) {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }
        } else { //modal cancel
            event.preventDefault();
            const cancel = new CustomEvent(
                "cancel",{});
            /* fire the event to be handled on the Parent Component */
            this.dispatchEvent(cancel);
        }
    }

    handleError(event) {
        const errors = get(event.detail,"output.errors");
        // read backend errors
        let isNoErrorFound = true;
        if(Array.isArray(errors)) {
            errors.map(e => {
                // read duplicate records errors
                if(e.errorCode === 'DUPLICATES_DETECTED') {
                    // read the match results to get the details
                    if(Array.isArray(e.duplicateRecordError.matchResults)) {
                        let matchResults = get(e,"duplicateRecordError.matchResults");
                        if(Array.isArray(matchResults)) {
                            // find the match result duplicate ids
                            matchResults.map(mr => {
                                let matchRecordIds = get(mr,"matchRecordIds");
                                // show the message with the clickable links
                                this.showToast(this.labels.errorMessage, event.detail.message + ': ' + event.detail.detail, 'error', false,matchRecordIds);
                                isNoErrorFound = false;
                            });
                        }
                    }
                }
            });
        }
        // generic error message
        if(isNoErrorFound) {
            this.showToast(this.labels.errorMessage, event.detail.message + ': ' + event.detail.detail, 'error', true);
        }
    }

    showToast(title, message, variant, autoClose, idsToNavigate = []) {
        this.template.querySelector('c-fbc_toast-message').showCustomNotice({
            detail: {
                title: title, message: message, variant: variant, autoClose: autoClose, idsToNavigate: idsToNavigate
            }
        });
    }
}