import {LightningElement, api, wire, track} from 'lwc';
import getcasemovements from '@salesforce/apex/ShortformController.getcontacts';
import CEP from '@salesforce/schema/ContactEncounterParticipant';
import ACCOUNT from '@salesforce/schema/Account';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import RELTOPARENTRECORD_FIELD     	    from '@salesforce/schema/ContactEncounterParticipant.Relationship_to_Case__c';
import SPECIFYRELTOPARENTRECORD_FIELD   from '@salesforce/schema/ContactEncounterParticipant.Specify_relationship_to_case__c';
import getPersonContactId               from '@salesforce/apex/DHHS_CEPController.getPersonContactId';
import checkCasesExistForRecordNumber   from '@salesforce/apex/DHHS_CEPController.checkCasesforRecordNumber';
import createpcc                        from '@salesforce/apex/ShortformController.saveclosecontact';
import checkCasesExistForPersonId       from '@salesforce/apex/DHHS_CEPController.checkCasesExistForPersonId';
import CASE_ID                          from '@salesforce/schema/WorkOrder.CaseId';
import { getRecord }                    from 'lightning/uiRecordApi';

import { subscribe, unsubscribe, MessageContext, publish } from 'lightning/messageService';
import SEARCHRESULT from '@salesforce/messageChannel/Search_Result__c';

const actions = [
    { label: 'Edit', name: 'Edit' },
];
const columns = [
    {
        label: 'Contact',
        fieldName: 'contacturl',
        type: 'url',
        typeAttributes: {label: { fieldName: 'contactname'},target: '_top',
        tooltip: "Contact"},
        
        sortable: true
    },
    {
        label: 'Last day of Exposure Day 0',
        fieldName: 'starttime',
        type: 'date'
    },
    {
        label: 'Record Number',
        fieldName: 'caseurl',
        type: 'url',
        typeAttributes: {label: { fieldName: 'casenumber'},target: '_top',
        tooltip: "Record Number" } 
    } ,
        
   
    {
        label: 'Phone',
        fieldName: 'phone',
        type: 'text'
    },
    {
        label: 'Address',
        fieldName: 'accountaddress',
        type: 'text'
    },
    {
        label: 'Relationship to case',
        fieldName: 'relationship',
        type: 'text'
    },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];


export default class Dhhs_Shortform_ContactsRelatedList extends LightningElement {

    @api recordId;
    @track data =[];
    @track isModalOpen = false;
    @track row;
    @track isloading = false;
    @track cepId;
    @track cardtitle = 'Close Contacts';
    columns = columns;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    @track jsonText = "{\"details\":[{\"key\":\"Birth Date\",\"value\":\"PersonBirthdate\"},{\"key\":\"Mobile\",\"value\":\"PersonMobilePhone\"},{\"key\":\"Residential Address\",\"value\":\"Address_Text__pc\"},{\"key\":\"Email\",\"value\":\"PersonEmail\"}]}"
    showpopup = false;
    shownew = false;
    actiontitle = '';
    personSelected;
    personIdSelected;
    relationshipToRecordOptions;
    relationshipToRecordPick;
    specifyRelationshipToRecordOptions;
    specifyRelationshipToRecordPick;
    lastdate;
    issaveloading = false;
    caseid = '';
    ongoingexposure = false;

    @api showcaselist = false;
    @track recNumber = '';
    @track disablePersonsearch = false;
    @track disableRecordSearch = false;
    @api isRequiredPersonsearch = false;
    @api isRequiredRecordSearch = false;
    @track jsonRecText = "{\"details\":[{\"key\":\"Case Number\",\"value\":\"CaseNumber\"},{\"key\":\"Account Name\",\"value\":\"Account.Name\"},{\"key\":\"Record Type\",\"value\":\"RecordType.Name\"}]}"

    @wire(getRecord, { recordId: '$recordId', fields: [CASE_ID] })
    wiredAccount({ error, data }) {
        if (data) {
            this.caseid = data.fields.CaseId.value ;
        } else if (error) {
            this.error = error;
        }
        debugger;
    }

    connectedCallback(){
        console.log('Record id'+this.recordId);
        this.fetchcasemovements();
    }

    fetchcasemovements(){
        this.isloading = true;
        getcasemovements({workorderid: this.recordId })
        .then(result => {
            this.data = result;
            if(this.data.length > 0){
                this.cardtitle = 'Close Contacts ('+ this.data.length + ')';
            }
            this.isloading = false;

           
            console.log('result'+JSON.stringify(result));  
         })
        .catch(error =>{
            this.isloading = false;
            console.log('Error fetching search data'+JSON.stringify(error));
        });
    }

    handleRefreshData(){
        this.fetchcasemovements();
    }
    

    // Used to sort the 'Age' column
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleRowAction(event){
     //TODO Handle Row Action
     const actionName = event.detail.action.name;
     this.row = event.detail.row;
     this.cepId=this.row.cepId;
     switch (actionName) {
         case 'Edit':
             console.log('row value =>' + JSON.stringify(this.row));
             console.log('CEP Id:'+this.cepId);
             this.handleEdit();
             break;
         default:
     }
    }

    handleEdit() {
        // to open modal set isModalOpen tarck value as true
        this.shownew = false;
        this.isModalOpen = true;
        this.actiontitle = 'Edit Contact Encounter Participant';
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        this.shownew = false;
        this.relationshipToRecordPick = '';
        this.specifyRelationshipToRecordPick = '';
        this.disableRecordSearch = false;
        this.disablePersonsearch = false;
    }

    handlenew(){
        this.isModalOpen = true;
        this.shownew = true;
        this.showcaselist = false; 
        this.actiontitle = 'New Close Contact';
        this.disableRecordSearch = false;
        this.disablePersonsearch = false;
        this.personSelected = '';
        this.personIdSelected = '';
        this.selectedCase = '';
    }

    handleSuccess() {
        this.isModalOpen = false;
        this.relationshipToRecordPick = '';
        this.specifyRelationshipToRecordPick = '';
        this.disableRecordSearch = false;
        this.disablePersonsearch = false;
        this.fetchcasemovements();
    }
    

    /****************************************************/
    /* Function to handle ERROR Toast */
    /****************************************************/
    showErrorToast(errorMessage) {
        const evt = new ShowToastEvent({
            title: 'Short Form Error',
            message: 'Some unexpected error, '+errorMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    /****************************************************/
    /* Function to handle SUCCESS Toast message */
    /****************************************************/
    showSuccessToast(successMessage) {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: successMessage,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    hasValidData() {
        let isvalidtosubmit = true;
        
        // lastdayofexposureday0 field
        if (!this.template.querySelector(".lastdayofexposureday").value) {
            this.template.querySelector(".lastdayofexposureday").setCustomValidity("This field cannot be blank.");
            isvalidtosubmit = false;
        }
        else {
            this.template.querySelector(".lastdayofexposureday").setCustomValidity("");
            isvalidtosubmit = true;
        }
        this.template.querySelector(".lastdayofexposureday").reportValidity();

        console.log('has valid data:: '+isvalidtosubmit);
        return isvalidtosubmit;
    }

    submitdetails(){
        
        let d = new Date(this.lastdate);

        if (this.hasValidData()) {
            this.issaveloading = true;
            if(this.personSelected != ''){
                createpcc({accountid: this.personSelected,primaryrecordid : this.caseid,selectedCaseId: this.selectedCase,lastdayofexposure : d.toISOString(),relationshiptocase: this.relationshipToRecordPick, specifyrelationshiptocase: this.specifyRelationshipToRecordPick })

                .then(result => {
                    if(result == 'success'){
                        this.fetchcasemovements();
                        this.showSuccessToast('New Close Contact Created Successfully');
                    }else{
                        this.showErrorToast('PCC is not created. Please report to your admin');
                    }
                    this.isModalOpen = false;
                    this.issaveloading = false;
                   
                 })
                .catch(error =>{ 
                    this.isModalOpen = false;
                    this.issaveloading = false;
                    this.showErrorToast('System error. Please report to your admin');
                    console.log('Error fetching search data'+JSON.stringify(error));
                });
            } else {
                this.showErrorToast('Please select a person or a record');
                this.issaveloading = false;
            }
        }       
    }

    



    @wire(getObjectInfo, { objectApiName: ACCOUNT })
    accountMetadata;
    getpersonAccountRecordType(){
        return this.accountMetadata.data.defaultRecordTypeId;
    }
    @wire(getObjectInfo, { objectApiName: CEP })
    cepMetadata;

       @wire(getPicklistValues, {   recordTypeId: '$cepMetadata.data.defaultRecordTypeId', fieldApiName: RELTOPARENTRECORD_FIELD })
    setPicklistOptions({error, data}) {
        if (data) {
            this.relationshipToRecordOptions = data.values;

        } else if (error) {
            console.log(error);
        }
    }

    @wire(getPicklistValues, {   recordTypeId: '$cepMetadata.data.defaultRecordTypeId', fieldApiName: SPECIFYRELTOPARENTRECORD_FIELD })
    setPicklistOptions2({error, data}) {
        if (data) {
            this.specifyRelationshipToRecordOptions = data.values;

        } else if (error) {
            console.log(error);
        }
    }
    handleChange(event) {

        switch (event.target.name) {
            case 'relationshipToRecordPick':
                this.relationshipToRecordPick = event.target.value;
                break;
            case 'specifyRelationshipToRecordPick':
                this.specifyRelationshipToRecordPick = event.target.value;
                break;
            case 'sex':
                this.sexValue = event.target.value;
                break;

        }
    }
    handleDateChange(event){
        this.lastdate = event.detail.value;
        console.log('sancheck'+ this.lastdate);
    }

    //handleCheckBoxChange(event){
    //    this.ongoingexposure = event.target.checked;
    // }

    handelPersonSelected(event) {
        //debugger;
        this.personSelected = event.detail;
        this.disableRecordSearch = true;
        console.log('this.disableRecordSearch-->'+this.disableRecordSearch)
       // this.getPersonIdForAccountId(this.personSelected);
        this.searchForCasesForPersonId();
    }

    getPersonIdForAccountId(accountId){
        //debugger;
        getPersonContactId({ personAccountId : accountId})
                .then((result)=>{
                    //debugger;
                    if (result.PersonContactId != '') {
                        //debugger;
                        this.personIdSelected = result.PersonContactId
                    }
                    else 
                        this.showcaselist = false; 
            }).catch((err)=>{
                console.log(err);
                //debugger;
        });

    }
    searchForCasesForPersonId(){
        //debugger;
        checkCasesExistForPersonId({ personId : this.personSelected})
                .then((result)=>{
                   // debugger;
                    if (result.Id != '') {
                        this.showcaselist = true;
                        this.template.querySelector('c-dhhs_-c-e-p-case-list-small').getRelatedCases(this.personSelected);
                    }
                    else 
                        this.showcaselist = false; 
            }).catch((err)=>{

            console.log(err);
            //debugger;
        });

    }
    
    //327529
    handleRecSelected(event) {
        console.log('<--event.detail-->'+event.detail);
        this.disablePersonsearch = true;
        this.recNumber = event.detail;
        this.searchForCasesForRecordNumber();
    }

   
    searchForCasesForRecordNumber(){
        checkCasesExistForRecordNumber({ recordNumber : this.recNumber})
                .then((result)=>{
                    if (result.Id != '') {
                        console.log('tresult -->'+result);
                        this.showcaselist = true;
                        this.personSelected = result.AccountId;
                        this.template.querySelector('c-dhhs_-c-e-p-case-list-small').getRecord(this.recNumber);
                    }
                    else 
                        this.showcaselist = false; 
            }).catch((err)=>{

            console.log(err);
            //debugger;
        });

    }
    
    handleCaseSelected(event){
        this.selectedCase = event.detail;
    }

    @wire(MessageContext)
    messageContext;

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
       
        if (this.subscriptionsearchResult) {
            return;
        }
     
         /****Subscribe to Search_Result__c***************/
         this.subscriptionsearchResult = subscribe(
            this.messageContext,
            SEARCHRESULT, (message) => {
                this.handleMessageForSearchResult(message);
          });
    }

    //unsubscribeToMessageChannel(){
    unsubscribeMC() {
        unsubscribe(this.subscriptionsearchResult);
        this.subscriptionsearchResult = null;
    }

    handleMessageForSearchResult(message) {
        // check whether it is a reset 
        if(message.isReset === "True"){
           this.disableRecordSearch = false;
           this.disablePersonsearch = false;
           this.showcaselist = false; 
        }
    }

     // Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
     connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

}