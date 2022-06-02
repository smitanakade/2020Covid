/*
 * @Author             : DHHS
 * @Description        : DHHS Work Order related list component
 * @Modification Log   : 
 * --------------------------------------------------------------------------------------
 * Date           Author      		    Details
 * --------------------------------------------------------------------------------------
 * 26/11/2020     Aref S                PBI-332746 Add sorting for Case movement grid
*/
import { LightningElement, track, api,wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import WorkOrderRelatedListHelper from "./workOrderRelatedListHelper";
import { subscribe, unsubscribe, MessageContext,publish } from 'lightning/messageService';
import interviewEdited from '@salesforce/messageChannel/ShortFormInterview__c';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { getRecord } from 'lightning/uiRecordApi';

import CE_OBJECT from '@salesforce/schema/ContactEncounter';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import CASE_ID from '@salesforce/schema/WorkOrder.CaseId';
import ACCOUNT_ID from '@salesforce/schema/WorkOrder.AccountId';
import getContactId from '@salesforce/apex/ShortformClinicalTabControler.getContactId';
//import { subscribe, unsubscribe, MessageContext,publish } from 'lightning/messageService';
//import REFRESHRL from "@salesforce/messageChannel/ShortFormInterview__c";

import haveAnySymptoms_FIELD from '@salesforce/schema/HealthCloudGA__Clinical_Assessment_Response__c.Did_person_have_symptoms__c';
import dateOfFirstSymptoms_FIELD from '@salesforce/schema/HealthCloudGA__Clinical_Assessment_Response__c.HealthCloudGA__OnsetOfSymptoms__c';
import patient_FIELD from '@salesforce/schema/HealthCloudGA__Clinical_Assessment_Response__c.HealthCloudGA__Patient__c';
import case_FIELD from '@salesforce/schema/HealthCloudGA__Clinical_Assessment_Response__c.Record__c';
import presentedFIELD from '@salesforce/schema/HealthCloudGA__EhrEncounter__c.Presented_to__c';
import startDate_FIELD from '@salesforce/schema/HealthCloudGA__EhrEncounter__c.StartDate__c';
import dateadministered_FIELD from '@salesforce/schema/HealthCloudGA__EhrImmunization__c.Date_Administered__c';
import dose_FIELD from '@salesforce/schema/HealthCloudGA__EhrImmunization__c.Dose_Received__c';
import covidVaccine_FIELD from '@salesforce/schema/HealthCloudGA__EhrImmunization__c.Have_you_had_a_COVID_19_vaccine__c';

import name_FIELD from '@salesforce/schema/ContactEncounter.Name';
import calculatedDay_FIELD from '@salesforce/schema/ContactEncounter.CalculatedDay__c';
import startTime_FIELD from '@salesforce/schema/ContactEncounter.StartTime';
import endTime_FIELD from '@salesforce/schema/ContactEncounter.End_Time__c';
import location_FIELD from '@salesforce/schema/ContactEncounter.Location__c';
import movementNotes_FIELD from '@salesforce/schema/ContactEncounter.Movement_Notes__c';
import incorrectInformation_FIELD from '@salesforce/schema/ContactEncounter.Incorrect_Information_Provided__c';
import recentTravel_FIELD from '@salesforce/schema/ContactEncounter.Recent_Travel_Overseas__c';
import country_FIELD from '@salesforce/schema/ContactEncounter.Country__c';
import employmentStatus_FIELD from '@salesforce/schema/ContactEncounter.Employment_Status__c';
import occupation_FIELD from '@salesforce/schema/ContactEncounter.Occupation__c';
import workStudyCareName_FIELD from '@salesforce/schema/ContactEncounter.Work_Study_Care_Name__c';
import withinPeriodOfInterest_FIELD from '@salesforce/schema/ContactEncounter.Within_Period_of_Interest__c';
import description_FIELD from '@salesforce/schema/ContactEncounter.Description';
import TickerSymbol from "@salesforce/schema/Account.TickerSymbol";

export default class WorkOrderRelatedList extends NavigationMixin(LightningElement) {
    @track state = {};
    @api sobjectApiName;
    @api relatedFieldApiName;
    @api numberOfRecords = 100;
    @api sortedBy;
    @api sortedDirection = "ASC";
    @api rowActionHandler;
    @api fields;
    @api columns;
    @api customActions = [];
    @api hideNewButton = false;
    @api type = '';
    @api recordId;
    isloading = false;
    @track showCreateExposureSiteDialog = false;
    @track cerecordid;
    
    caseId;
    accountId;
    //messageContext;
    subscriptionInterviewEdited=null;
    helper = new WorkOrderRelatedListHelper();

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: [CASE_ID,ACCOUNT_ID] })
    wiredAccount({ error, data }) {
        if (data) {
            this.caseId = data.fields.CaseId.value;   
            this.accountId = data.fields.AccountId.value;       
            console.log('caseid----------------'+this.caseid);   
            console.log('accountId----------------'+this.accountId);   
        } else if (error) {
            this.error = error;
        }
    }

    
    connectedCallback()
    {        
        this.subscribeToMessageChannel();
        this.init();
    }

    subscribeToMessageChannel() {
        console.log('inside subscription');
       
        if (this.subscriptionInterviewEdited) {
            console.log('retrune');
            return;
            
        }
        this.subscriptionInterviewEdited = subscribe(
          this.messageContext,
          interviewEdited, (message) => {
              console.log('message');
              this.handleRefreshData();
        });
    }

    get recordId() {
        return this.state.recordId;
    }

    set recordId(value) {        
        this.state.recordId = value;        
    }
    get hasRecords() {
        return this.state.records != null && this.state.records.length;
    }

    get dtContainerClass(){
        return 'slds-is-relative ' +  (this.type == 'casemovement'?'data-table-container-wo':'data-table-container');
    }

    get icon(){
        if(this.sobjectApiName == 'HealthCloudGA__Clinical_Assessment_Response__c'){
            return 'standard:custom';
        }
        else if (this.sobjectApiName == 'HealthCloudGA__EhrImmunization__c'){
            return 'standard:immunization';
        }
        else if (this.sobjectApiName =='HealthCloudGA__EhrEncounter__c'){
            return 'standard:procedure';           
        }
        else if(this.sobjectApiName == 'ContactEncounter' && this.type == 'casemovement'){
            return 'standard:address';
        }
       
        else if(this.sobjectApiName == 'ContactEncounter' && this.type == 'workstudycare'){
            return 'standard:work_contract';
        }

        else if (this.sobjectApiName == 'ContactEncounter'  && this.type == 'travelhistory'){  //334338
            return 'custom:custom20';
        }
    }
  
    async init() {
        
        this.isloading = true;
        this.state.showRelatedList = this.recordId != null;
        console.log('.....ContactEncounter this.state.showRelatedList =='+this.state.showRelatedList);
        if (! (this.recordId
            && this.sobjectApiName            
            && this.fields
            && this.columns)) {
            this.state.records = [];
            return;
        }

        this.state.fields = this.fields;
        console.log('fielkdaggg '+this.state.fields);
        this.state.relatedFieldApiName= this.relatedFieldApiName;
        this.state.recordId= this.recordId;
        this.state.numberOfRecords= this.numberOfRecords;
        this.state.sobjectApiName= this.sobjectApiName;
        this.state.sortedBy= this.sortedBy;
        this.state.sortedDirection= this.sortedDirection;
        this.state.defaultSortDirection= 'asc';
        this.state.customActions= this.customActions;

        if (this.type == 'casemovement'){
            this.labelName = 'Case Movements';
        }
        else if (this.type == 'workstudycare'){
            this.labelName = 'Work Study Care';
        }
        else if (this.type == 'travelhistory'){
            this.labelName = 'Travel History';
        }
        
        const data = await this.helper.fetchData(this.state,this.labelName);
        if (data)
        {
            this.state.records = data.records;        
            this.state.iconName = data.iconName;
            this.state.sobjectLabel = data.sobjectLabel;
            this.state.sobjectLabelPlural = data.sobjectLabelPlural;            
            this.state.title = data.title;             
            this.state.parentRelationshipApiName = data.parentRelationshipApiName;
            this.state.columns = this.helper.initColumnsWithActions(this.columns, this.customActions, this.labelName);           
        }
        this.isloading = false;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (this.rowActionHandler) {
            this.rowActionHandler.call()
        } else {
            switch (actionName) {
                //case "delete":
                    //this.handleDeleteRecord(row);
                   // break;
                case "edit":
                    this.handleEditRecord(row);
                    break;
                case "createExposureSite":
                    this.handleCreateExposureSite(row);
                    break;
                default:
            }
        }
    }

    handleGotoRelatedList() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordRelationshipPage",
            attributes: {
                recordId: this.recordId,
                relationshipApiName: this.state.parentRelationshipApiName,
                actionName: "view",
                objectApiName: this.sobjectApiName
            }
        });
    }

    handleCreateRecord() {
        const newEditPopup = this.template.querySelector("c-related-list-new-edit-popup");
        newEditPopup.recordId = null;
        newEditPopup.recordName = null;        
        newEditPopup.sobjectApiName = this.sobjectApiName;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;
        newEditPopup.show();
    }

    @track recordTypeId;
    @wire(getObjectInfo, { objectApiName: CE_OBJECT })
    getobjectInfo(result) {
        if (result.data) {
            const rtis = result.data.recordTypeInfos;
            this.recordTypeId = Object.keys(rtis).find((rti) => rtis[rti].name === 'Travel History');
        }
    }

    handleNewCreateRecord() {
        const newEditPopup = this.template.querySelector("c-short-form-new-record");
        newEditPopup.recordId = null;
        newEditPopup.recordName = null;        
        newEditPopup.sobjectApiName = this.sobjectApiName;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;

        

        if(this.sobjectApiName == 'HealthCloudGA__Clinical_Assessment_Response__c'){

            const defaultValues = encodeDefaultFieldValues({
                Record__c: this.caseId,
                HealthCloudGA__Patient__c : this.accountId
            });

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { 
                    objectApiName: 'HealthCloudGA__Clinical_Assessment_Response__c',
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: defaultValues
                }
            });
            //this.fields = [case_FIELD,haveAnySymptoms_FIELD,dateOfFirstSymptoms_FIELD,patient_FIELD];
        }
        else if (this.sobjectApiName == 'HealthCloudGA__EhrImmunization__c'){

            let defaultValues={};

            getContactId({workOrderId : this.recordId}).then((resp)=>{
                console.log('resp--============',resp);
                if(resp != null){
                    defaultValues = encodeDefaultFieldValues({
                        Contact__c: resp,
                    });
                }
                console.log('defaultValues******************',defaultValues);
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: { 
                        objectApiName: 'HealthCloudGA__EhrImmunization__c',
                        actionName: 'new'
                    },
                    state: {
                        defaultFieldValues: defaultValues
                    }
                });
            }).catch((err) => {
                console.log('err-----------------',JSON.stringify(err));
            });
            
            //this.fields = [covidVaccine_FIELD,dose_FIELD,dateadministered_FIELD]
        }
        else if (this.sobjectApiName =='HealthCloudGA__EhrEncounter__c'){
            const defaultValues = encodeDefaultFieldValues({
                Record__c: this.caseId
            });

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { 
                    objectApiName: 'HealthCloudGA__EhrEncounter__c',
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: defaultValues
                }
            });
            //this.fields = [presentedFIELD,startDate_FIELD]
        }
      
        else if (this.sobjectApiName == 'ContactEncounter' && this.type == 'travelhistory'){
            let defaultValues={};
            
            getContactId({workOrderId : this.recordId}).then((resp)=>{
                console.log('resp--============',resp);
                if(resp != null){
                    defaultValues = encodeDefaultFieldValues({
                        Contact_Person__c: resp,
                        Record__c: this.caseId
                    });
                }
                console.log('defaultValues as per travelhistory******************'+defaultValues);
                console.log('defaultValues id******************'+this.recordTypeId);
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: { 
                        objectApiName: 'ContactEncounter',
                        actionName: 'new'
                    },
                    state: {
                        defaultFieldValues: defaultValues,
                        recordTypeId: this.recordTypeId 
                    }
                });
            }).catch((err) => {
                console.log('err-----------------',JSON.stringify(err));
            });

            
        }
   
        else if(this.sobjectApiName == 'ContactEncounter' && this.type == 'casemovement'){
            this.fields = [name_FIELD,calculatedDay_FIELD,startTime_FIELD,endTime_FIELD,location_FIELD,movementNotes_FIELD,incorrectInformation_FIELD];
            newEditPopup.show();
        }
        // How to make this work for Work/study/care ??
        else if(this.sobjectApiName == 'ContactEncounter' && this.type == 'workstudycare'){
           this.fields = [name_FIELD,employmentStatus_FIELD,occupation_FIELD,location_FIELD,withinPeriodOfInterest_FIELD,endTime_FIELD,description_FIELD];
           newEditPopup.show();
        }

         
        console.log('------------------',newEditPopup.sobjectApiName);
        
    }

    handleEditRecord(row) {
        if(this.sobjectApiName == 'HealthCloudGA__Clinical_Assessment_Response__c'){
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { 
                    recordId: row.Id,
                    objectApiName: 'HealthCloudGA__Clinical_Assessment_Response__c',
                    actionName: 'edit'
                }
            });
            //this.fields = [case_FIELD,haveAnySymptoms_FIELD,dateOfFirstSymptoms_FIELD,patient_FIELD];
        }
        else if (this.sobjectApiName == 'HealthCloudGA__EhrImmunization__c'){
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { 
                    recordId: row.Id,
                    objectApiName: 'HealthCloudGA__EhrImmunization__c',
                    actionName: 'edit'
                }
            });
            //this.fields = [covidVaccine_FIELD,dose_FIELD,dateadministered_FIELD]
        }
        else if (this.sobjectApiName =='HealthCloudGA__EhrEncounter__c'){
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { 
                    recordId: row.Id,
                    objectApiName: 'HealthCloudGA__EhrEncounter__c',
                    actionName: 'edit'
                }
            });
            //this.fields = [presentedFIELD,startDate_FIELD]
        }
        else if(this.sobjectApiName == 'ContactEncounter' && this.type == 'casemovement'){
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { 
                    recordId: row.Id,
                    objectApiName: 'ContactEncounter',
                    actionName: 'edit'
                }
            });
            //this.fields = [presentedFIELD,startDate_FIELD]
        }
        else if(this.sobjectApiName == 'ContactEncounter' && this.type == 'casemovement'){
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { 
                    recordId: row.Id,
                    objectApiName: 'ContactEncounter',
                    actionName: 'edit'
                }
            });
            //this.fields = [presentedFIELD,startDate_FIELD]
        }
        else if(this.sobjectApiName == 'ContactEncounter' && this.type == 'travelhistory'){ //334338
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { 
                    recordId: row.Id,
                    objectApiName: 'ContactEncounter',
                    actionName: 'edit'
                }
            });
        }
        else{
            const newEditPopup = this.template.querySelector("c-related-list-new-edit-popup");
            newEditPopup.recordId = row.Id;
            newEditPopup.recordName = row.Name;
            newEditPopup.sobjectApiName = this.sobjectApiName;
            newEditPopup.sobjectLabel = this.state.sobjectLabel;
            newEditPopup.show();
        }
    }


    handleRefreshData(event) {
        console.log('save fired');
        console.log('agghg',this.fields);
        //const fieldsP = this.fields;
        ///var data={"id" : 1, "second" : "abcd"};
        if (Array.isArray(this.fields)){
            console.log('inside');
            var fieldsS = [];
            this.fields.forEach(o => {
                console.log('apiname '+o.fieldApiName);
                fieldsS.push(o.fieldApiName);
                });
                if (this.type == 'workstudycare'){
                    fieldsS.push('Location_Name__c');
                
                }
                if (this.type == 'travelhistory'){
                    fieldsS.push('Name');
                
                }
            console.log('log 1',this.fieldsS);
            
            this.fields = fieldsS.join();
            console.log('log 2 ',this.fields);
        }
        this.init();
    }

     /********************************************************************/
    /* Function to handle onclick sorting Action on selected field */
    /********************************************************************/
    handleSortingAction(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.state.records];
        const numberPrimer = (value) =>{
            var changedValue=value;
            if (sortedBy==='CalculatedDay__c')
            {
                changedValue=('' + value).trim().substring(4);
            }
            var fixValue=''+ (changedValue===undefined?(sortedBy==='Duration__c'?-1:''):changedValue);          
            return (fixValue.match(/^-?\d+(\.\d+)*$/)? parseFloat(fixValue) :fixValue);    
        } 
        cloneData.sort( this.sortBy( sortedBy, sortDirection === 'asc' ? 1 : -1,numberPrimer ) );
        this.state.records = cloneData;
        this.sortedDirection = sortDirection;
        this.sortedBy = sortedBy;
        this.state.sortedBy= this.sortedBy;
        this.state.sortedDirection= this.sortedDirection;
    }

    /********************************************************************/
    /* Function to compare list data and Sort it */
    /********************************************************************/
    sortBy( field, reverse, primer ) {
        var newField=field;
        if (field==='LinkName')
        {
            newField='Name';
        }

        const key = primer
            ? function( x ) {                 
                  return primer(x[newField]);
              }
            : function( x ) {
                  return x[newField];
              };
        return function( a, b ) {
            a = key(a)?key(a):'';
            b = key(b)?key(b):'';
            
            return reverse * ( ( a > b ) - ( b > a ) );
        };
    }

    
    /********************************************************************/
    /* Function to close create exposure site dialog */
    /********************************************************************/
     handleCreateExposureSite(row){
        this.cerecordid = row.Id;
        this.showCreateExposureSiteDialog = true;
    }

    /********************************************************************/
    /* Function to close create exposure site dialog */
    /********************************************************************/
    handleDialogClose(){
        this.showCreateExposureSiteDialog = false;
    }
}