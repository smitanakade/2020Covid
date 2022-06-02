import { LightningElement, wire,track, api } from 'lwc';
import findRecords from '@salesforce/apex/DLWC_TypeAheadController.fetchLookUpValues';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

// Import message service features required for publishing and the message channel
import { subscribe,MessageContext,publish } from 'lightning/messageService';
// Import  search result Message channel
import SEARCHRESULT from '@salesforce/messageChannel/Search_Result__c';


export default class typeAheadComponent extends LightningElement {
    @track records;
    @track error;   
    @track selectedRecord;
    @track searchKey;
    @api iconname;
    @api objectName;
    @api searchfield;
    @api displayField;
    @api noRecDisplay;
    @api label;
    @api pluralLabel;

    @api recordId;
    @api createRecord = false;
    @api availableActions = ['NEXT'];
    @api displayFieldJson;
    @api displayTitleFieldJson;
    @api recordType;
    @api recordTypeId;
    @api showCancelButton;
    @api isCreateNewScreen;
    @api isRequired;
    @api createFields;
    @track showModal = false;
    @track hasSelected;
    @api selectedRecordName;
    @api disableInput;
    @api disableCreate;


    @wire(MessageContext)
   messageContext;

    connectedCallback(){
        if(this.recordId) {
            this.hasSelected = true;
        }
        if(this.displayTitleFieldJson != null) {
            this.displayTitleFieldJson = this.displayTitleFieldJson.split(',');
        }       
    }  

    /**
     * Get search results from sobject and display to user 
     */
    handleChange(event){
        this.searchKey = event.target.value;
        this.selectedRecord = undefined;
        /* Call the Salesforce Apex class method to find the Records */
        if(this.searchKey !== undefined && this.searchKey.length >=2) {
            
            findRecords({
                searchString : this.searchKey, 
                sObjectAPIName : this.objectName, 
                searchField : this.searchfield,
                displayField : this.displayField,
                recordCount : this.noRecDisplay,
                recordType : this.recordType,
                recordTypeIds: this.recordTypeId
            })
            .then(result => {
                this.records = result;
                const searchfld = (this.searchfield.indexOf(',') >=0 ? this.searchfield.split(',')[0] : this.searchfield );
                for(let i=0; i < this.records.length; i++){
                    const rec = this.records[i];
                   // this.records[i].Name = rec[this.searchfield];
                   this.records[i].Name = rec[searchfld];
                    //subtitle
                    if(this.displayTitleFieldJson != null) {
                        let searchTitle = [];
                        for (const field of this.displayTitleFieldJson) {
                            searchTitle.push(this.records[i][field]);
                            searchTitle.push(this.records[i]['Location_Severity__c']);
                        }
                        this.records[i].title = searchTitle;
                    }
                     //more details
                    let detailsField = JSON.parse(this.displayFieldJson);
                    for (const field of detailsField.details) {
                        if((field.value).includes('.')){
                            const fieldArr =(field.value).split('.');
                            if(this.records[i][fieldArr[0]] != null){
                                field.value = this.records[i][fieldArr[0]][fieldArr[1]];
                            } else {
                                field.value = null;
                            }
                        } else {
                            field.value = this.records[i][field.value];
                        }  
                    }
                    this.records[i].details = detailsField;
                }
                if(this.records.length == 0) {             
                    this.records.push({"Name": "No results found", "icon":"utility:search"});
                } 
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.records = undefined;
            });
        }
        else {
            this.firingRemoveEvent();
        }
    }
    /**
     * Event fires when we select record from typeahead dropdown
     */
    handleSelect(event){
        //debugger;
        this.hasSelected = true;
        const selectedRecordId = event.detail;
        this.selectedRecord = this.records.find( record => record.Id === selectedRecordId);
        this.selectedRecordName = this.selectedRecord.Name;
        this.recordId = selectedRecordId;
        this.createRecord = false;

        event.preventDefault();
        const selectedRecord = new CustomEvent(
            "select",
            {
                detail : event.detail
            }
        );
        /* fire the event to be handled on the Parent Component */
        this.dispatchEvent(selectedRecord);

    }

    /**
     * event to clear drop down list
     */
    firingRemoveEvent() {
        this.selectedRecord = undefined;
        this.records = undefined;
        
    }

    handleCreate() {
        this.createRecord = true;

        if (this.availableActions.find(action => action === 'NEXT')) {
            // navigate to the next screen
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }  
    }

    handleSuccess(event) {
        console.log('onsuccess event recordEditForm', event.detail.id);
    }

    openModal() {
        this.showModal = true;
    }
    
    closeModal() {      
        this.showModal = false;
    }

    setLookup(event) {  
        this.hasSelected = true;   
        this.selectedRecord = event.detail;
        this.recordId = event.detail.id; 
        this.selectedRecordName = event.detail.name;
        this.closeModal();

        const payload = { isReset : "True" };
        // Respond to UI event by publishing messageSeRemoveEvent(); 
        publish(this.messageContext, SEARCHRESULT, payload);
        console.log('published events');

        // Dec 3 WO:244038 if new record created return the new record id.
        event.preventDefault();
        const selectedRecord = new CustomEvent(
            "select",
            {
                detail : event.detail.id
            }
        );
        /* fire the event to be handled on the Parent Component */
        this.dispatchEvent(selectedRecord);

    }
    @api restartSearch() {   
        this.hasSelected = false; 
        this.searchKey = '';
        this.recordId = '';
        this.selectedRecordName = '';
        this.firingRemoveEvent();

        const payload = { isReset : "True" };
        // Respond to UI event by publishing messageSeRemoveEvent(); 
        publish(this.messageContext, SEARCHRESULT, payload);
    }

    /**
     * validate on click of the next button, add any validation conditions
     * @returns {{isValid: boolean, errorMessage: string}|{isValid: boolean}}
     */
    @api
    validate() { 
        // if there is no value selected before navigation
        if(this.isRequired && !this.hasSelected) {
            // If the component is invalid, return the isValid parameter
            // as false and return an error message.
            return {
                isValid: false,
                errorMessage: this.label+' is required',
            };
        } else {
            return { isValid: true };
        }
    }

}