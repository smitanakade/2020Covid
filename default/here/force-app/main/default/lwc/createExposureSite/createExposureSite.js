import { LightningElement,wire,api,track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import MY_OBJECT from '@salesforce/schema/Case';
// Import message service features required for subscribing and the message channel
import { publish, MessageContext } from 'lightning/messageService';
import UPDATEMOVEMENT  from '@salesforce/messageChannel/Encounter_Created__c';
import UPDATEINTERVIEW1 from '@salesforce/messageChannel/ShortFormInterview__c';
import getContactEncounter from '@salesforce/apex/createExposureSiteHandler.getContactEncounter';
import updateContactEncounter from '@salesforce/apex/createExposureSiteHandler.updateContactEncounter';

export default class CreateExposureSite extends NavigationMixin(LightningElement) {
    @api recordId; 
    @api ceRecordId;
    @api objectApiName ;
    @track caseRecord;
    @track exposureStartDateTime;
    @track exposureEndDateTime;
    @track fourteenDaysPost;
    @track facilityNotificationRequired;
    @track location;
    @track defaultSubject;
    @track subject;
    @track status;
    @track siteType;
    @track notes;
    @track recordTypeId;
    @track showLoading;
    @track showEditForm;
    @track exposureSiteId;
    @track exposureSiteRecordNumber;
    @api contactencounterid;

    @wire(MessageContext)
    messageContext;

    @wire(getObjectInfo, { objectApiName: MY_OBJECT })
    handleObjectInfo({error, data}) {
        if (data) {
            const rtis = data.recordTypeInfos;
            console.log(JSON.stringify(rtis));
            this.recordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Exposure Management');
        }
    }

    connectedCallback(){
        if(this.contactencounterid != '' && this.contactencounterid != undefined){
            this.ceRecordId = this.contactencounterid;
        }
        this.objectApiName = 'Case';
        this.getContactEncounterData();
    }

    getContactEncounterData(){
        this.showEditForm = false;
        getContactEncounter({contactEncounterRecordId: this.ceRecordId})
        .then(result=>{
            console.log('result ==> ' + JSON.stringify(result));
            if(result.Record__c != undefined){
                this.caseRecord = result.Record__r.CaseNumber;
            }
            this.exposureStartDateTime = result.StartTime;
            this.exposureEndDateTime = result.End_Time__c;
            var endTime = new Date(this.exposureEndDateTime);
            endTime.setDate(endTime.getDate() + 14);
            this.fourteenDaysPost = endTime.toISOString();
            this.location= result.LocationId;
            this.facilityNotificationRequired = 'Yes';
            var currentDate = new Date();
            var currentMonth = currentDate.getMonth() + 1;
            var currentYear = currentDate.getFullYear();
            this.defaultSubject = 'COVID-19 ' + currentYear + currentMonth + ' ' + result.Location.Name;
            this.subject = this.defaultSubject;
            this.status = 'New';
            this.notes = result.Movement_Notes__c;
            this.showEditForm = true;

        })
        .catch(error=>{
            
        })
    }

    updateContactEncounterData(){
        updateContactEncounter({contactEncounterRecordId: this.ceRecordId, exposureSiteId: this.exposureSiteId})
        .then(result=>{
           this.showLoading = false;
           this.exposureSiteRecordNumber = result.Exposure_Site_ID__r.CaseNumber;
           // show toast message
             const evt = new ShowToastEvent({
                title: 'Success',
                message: 'Exposure Site created successfully: ' +  this.exposureSiteRecordNumber,
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            this.closeQuickAction();
            this.navigateToAccountPage();
        })
        .catch(error=>{
            
        })
    }

    close(){
        this.closeQuickAction();
    }
   
   handleDHHSNotifiedFacility(event){
       this.value = event.detail.value;
       if(this.value != null){
         this.facilityNotificationRequired = 'No';
       } 
       else if(this.value == null){
         this.facilityNotificationRequired = 'Yes';
       }
   }

   handleSiteType(event){
       this.siteType = event.detail.value;
       this.subject = this.defaultSubject+' ' + this.siteType;
   }

    handleSubmit(event){
        this.showLoading = true;
        event.preventDefault(); 
        this.showresourceloading = true; 
        const fields = event.detail.fields;   
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event){
        this.exposureSiteId = event.detail.id;
        if(this.exposureSiteId != null){
            this.updateContactEncounterData();
        }
    }

    closeQuickAction() {
        if(this.contactencounterid != undefined){
            this.handleDialogClose();
        }
        const closeQA = new CustomEvent('close');
        this.dispatchEvent(closeQA);
        this.showEditForm = true;
    }

    handleDialogClose() {
        const message = {
            encounterId: this.ceRecordId
        };
        publish(this.messageContext, UPDATEMOVEMENT, message);
        publish(this.messageContext, UPDATEINTERVIEW1, message);

        // close the dialog 
        const closedialog = new CustomEvent('closedialog');
        this.dispatchEvent(closedialog);   
        this.hide();
    }

    navigateToAccountPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:  this.exposureSiteId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }
}