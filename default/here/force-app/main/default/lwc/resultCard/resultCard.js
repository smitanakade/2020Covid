import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { copyTextToClipboard } from 'c/copyTextToClipboard';
const CARD_WRAPPER_SELECTED_CLASS = 'card-wrapper selected';
const CARD_WRAPPER_UNSELECTED_CLASS  = 'card-wrapper';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class ResultCard extends NavigationMixin(LightningElement) {

    @api searchType;
    @api record;
    @api selectedRecordId;
    caseNumberLabel;
    caseRecordTypeLabel;
    caseStatusLabel;
    caseEventDateLabel;

    get cardClass() { 
        if(this.selectedRecordId == this.record.Id){
        //if(this.selectedRecordIds.includes(this.record.Id)){
           return CARD_WRAPPER_SELECTED_CLASS;
        }else{
            return CARD_WRAPPER_UNSELECTED_CLASS;
        }
    }

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseInfo({ data, error }) {
        if(data){ 
            this.caseNumberLabel = data.fields.CaseNumber.label;
            this.caseRecordTypeLabel = data.fields.RecordTypeId.label;
            this.caseStatusLabel = data.fields.Status.label;
            this.caseEventDateLabel = data.fields.Event_Date__c.label;
        }
    }

    // Fires event with the Id of the Case that has been selected.
    handleRecordClick() { 
        //copy case number to clipboard
        copyTextToClipboard(this.record.CaseNumber);
        this.selectedRecordId = this.record.Id;
        const selectEvent = new CustomEvent("recordselect",{ detail: {recId :this.record.Id} });
        this.dispatchEvent(selectEvent);
    }

    handleRecordView(event){

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
              url:event.target.dataset.id
            },
        });
    }

    handleEHRView(event){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
              url:event.target.dataset.id
            },
        });
    }
}