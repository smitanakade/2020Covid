import { LightningElement,wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import CASE_ID from '@salesforce/schema/WorkOrder.CaseId';
import enddate from '@salesforce/schema/ContactEncounter.End_Time__c';
import name from '@salesforce/schema/ContactEncounter.Name';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, MessageContext,publish } from 'lightning/messageService';
import UPDATEINTERVIEW from '@salesforce/messageChannel/ShortFormInterview__c';
import empstatus from '@salesforce/schema/ContactEncounter.Employment_Status__c';

// importing to get the object info 
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
// importing Case shcema
import ContactEncounter from '@salesforce/schema/ContactEncounter';

export default class ShortFormNewRecord extends LightningElement {
    showModal = false
    @api sobjectLabel
    @api sobjectApiName    
    @api recordId
    @api recordName
    @api fields
    @api type ='';
    caseid = '';
    rtValues; // case recordType
    rectypeid = '';
    enddate = '';
    empstatus = '';

    @api show() {
        this.showModal = true;
    }

    @api hide() {
        this.showModal = false;
    }
    handleClose() {
        console.log('test');
        this.showModal = false;     
    }
    handleDialogClose(){
        this.handleClose()
    }

    @wire(getRecord, { recordId: '$recordId', fields: [CASE_ID] })
    wiredAccount({ error, data }) {
        if (data) {
            this.caseid = data.fields.CaseId.value;     
            console.log('caseid'+this.caseid);   
        } else if (error) {
            this.error = error;
            
        }
    }

    /*@wire(getRecord, { recordId: '$recordId', fields: [enddate] })
    wiredAccount({ error, data }) {
        if (data) {
            this.enddate = data.fields.enddate.value;     
            console.log('enddate'+this.enddate);   
        } else if (error) {
            this.error = error;
            
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [empstatus] })
    wiredAccount({ error, data }) {
        if (data) {
            this.empstatus = data.fields.Employment_Status__c.value;     
            //console.log('enddate'+this.enddate);   
        } else if (error) {
            this.error = error;
            
        }
    }*/

    

    connectedCallback(){
        console.log('recordId'+this.recordId); 
        console.log('type'+this.type);  
    }

    /****************************************************/
    /* Wired Function to get object info (Case object) */
    /****************************************************/
    @wire(getObjectInfo, { objectApiName: ContactEncounter })
    ContactEncounterObjectInfo({data, error}) {
        if(data) {
            
            const rtInfos = data.recordTypeInfos;
            // getting map values
            this.rtValues = Object.values(rtInfos);
            for(let i = 0; i < this.rtValues.length; i++) {
                if(this.rtValues[i].name === 'Movement' && this.type == 'casemovement') {
                    this.rectypeid = this.rtValues[i].recordTypeId;
                    
                }
                if(this.rtValues[i].name === 'Work/Study/Care' && this.type == 'workstudycare') {
                    this.rectypeid = this.rtValues[i].recordTypeId;
                }
            }

            //this.startDate = this.today;
        }
        else if(error) {
            window.console.log('Error ===> '+JSON.stringify(error));
        }
    }

    isNew(){
        return this.recordId == null
    }
    get header(){
        if (this.sobjectApiName != 'ContactEncounter'){
            return this.isNew() ? `New ${this.sobjectLabel}` : `Edit ${this.recordName}`;
        }
        else if (this.type == 'casemovement'){
            return this.isNew() ? `New Case Movement` : `Edit ${this.recordName}`;
        }
        else if (this.type == 'workstudycare'){
            return this.isNew() ? `New Work Study Care` : `Edit ${this.recordName}`;

        }
    }

    handleSave(){
        console.log('aggh' +this.fields);
        /*if  (this.fields.includes(Employment_Status__c)){
            if (this.fields.End_Time__c != null){
                this.startDate = this.fields.End_Time__c;
            }
            else {
                var today = new Date();
                this.startDate = this.today;
            }
        }*/
        
        this.template.querySelector('lightning-record-form').submit(this.fields);
        console.log('gegeg');
        //this.showModal = false;  
       
    }    
    handleSuccess(event){

        this.hide();
        /*
        const message12 = {
            workOrderId: this.recordId
        };
        publish(this.messageContext, UPDATEINTERVIEW, message12);
        
        
        if(this.isNew()){
            if(event.detail.fields.Name){
                name = event.detail.fields.Name.value
            }else if(event.detail.fields.LastName){
                name = [event.detail.fields.FirstName.value, event.detail.fields.LastName.value].filter(Boolean).join(" ")
            }
        } 
        name = name ? `"${name}"` : ''
        */
        let name = this.isNew() ? '' : this.recordName ;
        const message = `${this.sobjectLabel} ${name} successfully ${(this.isNew() ? "created" : "saved")}.`
        const evt = new ShowToastEvent({
            title: message,
            variant: "success"
        });
        this.dispatchEvent(evt);
        const fieldsP = event.detail.fields;
        this.dispatchEvent(new CustomEvent("refreshdata",{detail:fieldsP}));                  
    } 

    handleSubmit(event){
        event.preventDefault();       
        const fields = event.detail.fields;
        console.log('saving'+this.caseid);   
        fields.Record__c = this.caseid; 
        if (this.type == 'workstudycare' ){
            let d = new Date();
            fields.StartTime = (fields.End_Time__c != null) ? fields.End_Time__c : d.toISOString(); 
        }
    
        this.template.querySelector('lightning-record-form').submit(fields);
    }
    
    handleError(event){
        console.log(JSON.stringify(event.detail));
        const evt = new ShowToastEvent({
            title: message,
            variant: "Error"
        });
        this.dispatchEvent(evt);
    }
     
}