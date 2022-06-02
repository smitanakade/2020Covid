import { LightningElement, track, api } from 'lwc';

export default class WorkOrderPage extends LightningElement {

    //334338
    @track travelHistoryColumns = [
        { label: 'Type', fieldName: 'LinkName', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_top' } },
        { label: 'Start Time', fieldName: 'StartTime', type: 'date' },
        { label: 'Overseas in past 14 days?', fieldName: 'Recent_Travel_Overseas__c', type: 'text' },
        { label: 'Country', fieldName: 'Country__c', type: 'text' }
        
    ];

    @track ehrImmunizationColumns = [
        { label: 'EHR IMMUNIZATION', fieldName: 'LinkName', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_top' } },
        { label: 'Have you had a COVID-19 vaccine?', fieldName: 'Have_you_had_a_COVID_19_vaccine__c', type: 'checkbox' },
        { label: 'Doses', fieldName: 'Dose_Received__c', type: 'text' }

    ];

    @track hmipColumns = [
        { label: 'Name', fieldName: 'LinkName', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_top' } },
        { label: 'Presented to', fieldName: 'Presented_to__c', type: 'text' },
        { label: 'Start Date', fieldName: 'StartDate__c', type: 'date' },
        { label: 'Date Admitted', fieldName: 'Date_admitted__c', type: 'date' }

    ];

    @track clinicalAssessmentResponseColumns = [
        { label: 'Name', fieldName: 'LinkName', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_top' } },
        { label: 'Did the case have any symptoms', fieldName: 'Did_person_have_symptoms__c', type: 'text' },
        { label: 'Date of first symptoms', fieldName: 'HealthCloudGA__OnsetOfSymptoms__c', type: 'date' }
        
    ];
   
    @track caseMovementColumns = [
        { label: 'Calculated Day', fieldName: 'CalculatedDay__c', type: 'text',sortable:true},
        { label: 'Name of movement', fieldName: 'LinkName', type: 'url',sortable:true, typeAttributes: { label: { fieldName: 'Name' }, target: '_top' } },
        { label: 'Location', fieldName: 'Location_Name__c', type: 'text',sortable:true },
        { label: 'Start Time', fieldName: 'StartTime', type: 'date',sortable:true, typeAttributes: {day: 'numeric',month: 'short',year: 'numeric',hour: '2-digit',minute: '2-digit',second: '2-digit',hour12: true}},
        { label: 'Duration (Hours)', fieldName: 'Duration__c', type: 'text',sortable:true },
        { label: 'Linked Exposure Site', fieldName: 'ExposureSiteIdUrl', type: 'url',sortable:true , typeAttributes: { label: { fieldName: 'ExposureSiteID' }, target: '_top', tooltip : {fieldName: 'ExposureSiteDetails'} } },        
        { label: 'Incorrect Information Provided', fieldName: 'Incorrect_Information_Provided__c', type: 'boolean',sortable:true },
        { label: 'Notes', fieldName: 'Movement_Notes__c', type: 'text',sortable:true }
   ];

    @track workStudyCareColumns = [
        { label: 'Employment Status', fieldName: 'Employment_Status__c', type: 'text'},
        { label: 'Name', fieldName: 'LinkName', type: 'url' , typeAttributes: { label: { fieldName: 'Name' }, target: '_top' } },
        { label: 'Location', fieldName: 'Location_Name__c', type: 'text' },
        { label: 'Contact Details', fieldName: 'Description', type: 'text' }
        
    ];

    
    
    @api recordId;
    @track clinical;
    @track movements;
    @track workstudycare;
    @track contacts;
    @api sObjectTarget;
    @api sObjectTargetProxy;
    connectedCallback(){
        if (!this.sObjectTarget){
            this.sObjectTarget = this.sObjectTargetProxy;
        }
    }
    customActions = [{ label: 'Custom action', name: 'custom_action' }];
    
    get showCardIsClinical(){
        if (this.sObjectTarget == 'clinical')
            return true;
        return false;
    }

    get showCardIsMovement(){
        if (this.sObjectTarget == 'movements')
            return true;
        return false;
    }

    get showWorkStudyCare(){
        if (this.sObjectTarget == 'workstudycare')
            return true;
        return false;
    }
    @api
    customHandler() {
        alert("It's a custom action!");
    }

    handleWorkOrderIdChange(event) {
        this.workOrderId = event.detail.value[0];
    }
}