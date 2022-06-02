/*
 * @Author             : Jiten Joysar
 * @Description        : DHHS CEP list View
 * @Modification Log   : 
 * --------------------------------------------------------------------------------------
 * Date           Author      		    Details
 * --------------------------------------------------------------------------------------
 * 26/11/2020     Jiten Joysar          Dhhs_CEPListView : Initial version
*/
import { LightningElement, api, track, wire } from 'lwc';  
// Import message service features required for subscribing and the message channel
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
// Import CEP created Message channel
import CEPCreated from '@salesforce/messageChannel/CEP_Created__c';
// Import selected Record Message channel
import selectedRecord from '@salesforce/messageChannel/Selected_Record__c';
import MOMENT from '@salesforce/resourceUrl/momentJS';
import {loadScript} from 'lightning/platformResourceLoader' ; // to load momemt Js
import fetchRecords from '@salesforce/apex/DHHS_CustomListViewDataTableController.fetchRecs';
// Import NavigationMixin
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; 
import {refreshApex} from '@salesforce/apex';

export default class Dhhs_CEPListView extends NavigationMixin(LightningElement) {

    /********************************************************************/
    /* Variable Declaration */
    /********************************************************************/   
    @wire(MessageContext)
    messageContext;
    @track listRecs;  // List of records to pass as Data table attribute
    @track initialListRecs;  // List of records 
    @track error;  
    @track columns;  
    @api recordId;
    @api relatedObject;
    @api fields;
    @api relatedField;
    @api tableColumns;
    @api title;
    @api iconDetails;
    @api totalRowCounts;
    @api orderBy;
    @api additionalFilter;
    @track additionalFilterValue;
    sortedBy;
    @track isRowSelected = false;
    @track preSelectedRows = [];
    @track selectedEncounterId;
    @track CEPIdSelected;
    isloaded = false;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    @track orderbyCopy;
    @track wiredRecordsResults;

    /********************************************************************/
    /* Use connected Callback LifeCycle hook to Initialize and parse 
       columns into Object structure when component is inserted into DOM */
    /********************************************************************/ 
    connectedCallback() {
        /********************************************************************/
        /* Convert columns captured from Properties into Object structure */
        /********************************************************************/ 
        this.subscribeToMessageChannel();
        if (!this.tableColumns){
            this.tableColumns='[{label:"Contact Type",fieldName:"Contact_Type__c",sortable:true}, {label:"Name",fieldName:"ContactName",sortable:true},{label:"Phone Number",fieldName:"PhoneNumber",sortable:true}, {label:"Address",fieldName:"Address",sortable:true}, {label:"Location",fieldName:"Location",sortable:true}, {label:"Relationship to Case",fieldName:"Relationship_to_Case__c",sortable:true}, {label:"Start Date",fieldName:"StartTime", type: "date",sortable:true, typeAttributes: {day: "numeric", month: "short", year: "numeric", hour: "2-digit",minute: "2-digit",second: "2-digit", hour12: true}}, {label:"End Date",fieldName:"End_Time__c", type: "date",sortable:true, typeAttributes: {day: "numeric", month: "short", year: "numeric", hour: "2-digit",minute: "2-digit",second: "2-digit", hour12: true}}, {type:"action",typeAttributes:{rowActions:[{label:"View",name:"view"},{label:"Edit",name:"edit"} ]}}]';
        }
        this.columns = JSON.parse( this.tableColumns.replace( /([a-zA-Z0-9]+?):/g, '"$1":' ).replace( /'/g, '"' ) );
        if(!this.isLoaded){
            loadScript(this, MOMENT+'/moment.min.js');
            this.isLoaded= true;
        }
        this.orderbyCopy = this.orderBy;
    }

    /********************************************************************/
    /* Function to return Parameters seperated by '-', this Parameters 
        are passed to Apex controller to fetch results */
    /********************************************************************/
    get paramVals() { 
        return this.relatedObject + '-' + this.fields + '-' +   
               this.relatedField + '-' + this.recordId + '-' + 
               this.orderBy + '-'+ this.totalRowCounts + '-' +
               this.additionalFilter +'-'+this.additionalFilterValue;  
    }

    /********************************************************************/
    /* Wire function to fetch the records */
    /********************************************************************/
    @wire(fetchRecords, {listValues: '$paramVals'})  
    wiredRecs(result) {
        
        this.wiredRecordsResults = result;
        // Success
        if (this.wiredRecordsResults.data){
            this.wiredRecordsResults.data = this.wiredRecordsResults.data.map(row=>{
                // Check for related records
                if((row.ContactEncounter.Location__r && row.ContactEncounter.Location__r.Name) || row.Contact.Name || row.Contact.MobilePhone){
                    
                    if(row.ContactEncounter.Location__r && row.ContactEncounter.Location__r.Name){
                        row = {...row, Location: row.ContactEncounter.Location__r.Name};
                    }
                    if(row.Contact.Name){
                        row = {...row, ContactName: row.Contact.Name};
                    }
                    if(row.Contact.MobilePhone){
                         row = {...row, PhoneNumber: row.Contact.MobilePhone};
                    }
                    if(row.Contact.Address_Text__c){
                        row = {...row, Address: row.Contact.Address_Text__c};
                    }
                    return row;
                }
                else{
                    return row;
                }
            })
            
            // check for pre-selected values in list and push it as first element 
            if(this.isRowSelected && this.CEPIdSelected){
                // set pre selected values
                this.preSelectedRows = [this.CEPIdSelected];
                // reset list
                this.listRecs = [];
                // push the newly created value as first one
                this.wiredRecordsResults.data.map(row=>{
                    if(row.Id === this.CEPIdSelected){
                        this.listRecs.push(row);
                    }
                })
                
                this.wiredRecordsResults.data.map(row=>{
                    
                    if(row.Id !== this.CEPIdSelected){
                        this.listRecs.push(row);
                    }
                })
                
            }else{
                this.listRecs = this.wiredRecordsResults.data;
            }
            
            this.initialListRecs = this.wiredRecordsResults.data;
        } else if (this.wiredRecordsResults.error) {
            this.listRecs = null;
            this.initialListRecs = null;
            this.error = this.wiredRecordsResults.error;
            this.showErrorToast(this.wiredRecordsResults.error.body.message);
        }
    }
    
    /********************************************************************/
    /* Function to handle onclick sorting Action on selected field */
    /********************************************************************/
    handleSortingAction(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.listRecs];
        cloneData.sort( this.sortBy( sortedBy, sortDirection === 'asc' ? 1 : -1 ) );
        this.listRecs = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    /********************************************************************/
    /* Function to compare list data and Sort it */
    /********************************************************************/
    sortBy( field, reverse, primer ) {
        const key = primer
            ? function( x ) {
                  return primer(x[field]);
              }
            : function( x ) {
                  return x[field];
              };
        return function( a, b ) {
            a = key(a);
            b = key(b);
            return reverse * ( ( a > b ) - ( b > a ) );
        };
    }

    /********************************************************************/
    /* Function to filter records based on Keyword entered */
    /********************************************************************/
    handleKeywordSeach(event) {
        const searchKey = event.target.value.toLowerCase(); 
        if (searchKey) {
            this.listRecs = this.initialListRecs;
             if ( this.listRecs ) {
                // Create a new object if value match with Criteria 
                let recs = [];
                for ( let rec of this.listRecs ) {
                    let valuesArray = Object.values( rec );
                    for ( let val of valuesArray ) {
                        // Addditional check for related Parent object field
                        if(!(typeof val === 'object')){
                            if ( val.toLowerCase().includes( searchKey ) ) {
                                recs.push( rec );
                                break;
                            }
                        }
                    }
                }
                // Assign filtered list
                this.listRecs = recs;
             }
 
        }  else {
            // Assign full list 
            this.listRecs = this.initialListRecs;
        }
 
    } 
    /********************************************************************/
    /* Function to encapsulate logic for Lightning message service 
        subscribe */
    /********************************************************************/
    subscribeToMessageChannel() {

        /********************************************************************/
        /* Subscribe to CEP_Created message channel */
        /********************************************************************/
        if (this.subscriptionEncounterCreated) {
            return;
        }
        this.subscriptionCEPCreated = subscribe(
          this.messageContext,
          CEPCreated, (message) => {
              this.handleMessageForCEPCreatedChannel(message);
        });
    }
    
    /********************************************************************/
    /* Function to encapsulate logic for Lightning message service 
        unsubscribe */
    /********************************************************************/
    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
        unsubscribe(this.subscriptionEncounterCreated);
        this.subscriptionEncounterCreated = null;
    }

    /********************************************************************/
    /* Function to handle Message For CEP Created Message Channel*/
    /********************************************************************/
    @api
    handleMessageForCEPCreatedChannel(messageEncounterId) {

        // Set Row Selected Attributes
        this.isRowSelected = true;
        this.CEPIdSelected = messageEncounterId.CEPId;
        // use refreshApex functionality to update list
        refreshApex(this.wiredRecordsResults);
    }

    /********************************************************************/
    /* Function to handle ERROR Toast message */
    /********************************************************************/
    showErrorToast(errorMessage) {
        const evt = new ShowToastEvent({
            title: this.title.toUpperCase() +' COMPONENT ERROR',
            message: 'Some unexpected error, '+errorMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    /********************************************************************/
    /* Function to handle SUCCESS Toast message */
    /********************************************************************/
    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Toast Success',
            message: 'Operation sucessful',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    /********************************************************************/
    /* Function to handle WARNING Toast message */
    /********************************************************************/
    showWarningToast(warningMessage) {
        const evt = new ShowToastEvent({
            title: 'ERROR',
            message: warningMessage,
            variant: 'warning',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    /********************************************************************/
    /* Function to handle Info Toast message */
    /********************************************************************/
    showInfoToast() {
        const evt = new ShowToastEvent({
            title: 'Toast Info',
            message: 'Operation will run in background',
            variant: 'info',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    /********************************************************************/
    /* Function to handle Row Actions */
    /********************************************************************/
    handleRowAction(event) {
        // get action name
        const actionName = event.detail.action.name;
        // get row details
        const row = event.detail.row;
        switch (actionName) {
            // View Action
            case 'view':
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        actionName: 'view',
                    },
                }).then(url => {
                     window.open(url);
                });
                break;
            // Edit action    
            case 'edit':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: this.relatedObject,
                        actionName: 'edit'
                    }
                });
                break;
            // Clone action    
            case 'clone':
                const message = {
                    selectedRecordId: row.Id
                };
                // Publish an event to clone Selected Record Channel
                publish(this.messageContext, cloneSelectedRecord, message);
                break;    
            default:
        }
    }

    /********************************************************************/
    /* Function to handle Row Selection */
    /********************************************************************/
    handleRowSelection = event => {
        var selectedRows = event.detail.selectedRows;
        this.publishEventToSelectedRecordChannel(selectedRows[0].Id);
    }

    /********************************************************************/
    /* Function to Publish an Event to Selected record message Channel */
    /********************************************************************/
    publishEventToSelectedRecordChannel( selectedEncID) {
        const message = {
            recordId: selectedEncID
        };
        // Publish an event to clone Selected Record Channel
        publish(this.messageContext, selectedRecord, message);
    }
}