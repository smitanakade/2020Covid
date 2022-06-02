/*
 * @Author             : Xiang Zheng
 * @Description        : related PBI 318325
 * @Modification Log   : 
 * --------------------------------------------------------------------------------------
 * Date           Author      		    Details
 * --------------------------------------------------------------------------------------
 * 04/09/2021     Xiang Zheng        Initial version
 * 12/11/2021     Lija Jawahar       Included Travel Details 334338
*/
import { LightningElement,wire,api,track} from 'lwc';
import { subscribe, unsubscribe, MessageContext,publish } from 'lightning/messageService';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';

//334338
import CE_OBJECT from '@salesforce/schema/ContactEncounter';
import Recent_Travel_Overseas from '@salesforce/schema/ContactEncounter.Recent_Travel_Overseas__c';
import CECountry from '@salesforce/schema/ContactEncounter.Country__c';

import CAR_OBJECT from '@salesforce/schema/HealthCloudGA__Clinical_Assessment_Response__c';
import EHRI_OBJECT from '@salesforce/schema/HealthCloudGA__EhrImmunization__c';
import CASE_OBJECT from '@salesforce/schema/Case';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import Did_person_have_symptoms from '@salesforce/schema/HealthCloudGA__Clinical_Assessment_Response__c.Did_person_have_symptoms__c';
import Dose_Received from '@salesforce/schema/HealthCloudGA__EhrImmunization__c.Dose_Received__c';
import Contact_hospital from '@salesforce/schema/Case.Contact_hospital_14_days_prior_symptoms__c';
import Was_aware from '@salesforce/schema/Case.Was_aware_of_contact_with_ve_case__c';
import Isolation_Quarantine from '@salesforce/schema/Case.Isolation_Quarantine_48_hrs_prior_to_sym__c';

import createNewRecords from '@salesforce/apex/ShortformClinicalTabControler.createRecords';
import checkAccRecordType from '@salesforce/apex/ShortformClinicalTabControler.checkAccountRecordType';
import UPDATEINTERVIEW from '@salesforce/messageChannel/ShortFormInterview__c';

import FIRST_SUBMIT from '@salesforce/schema/WorkOrder.Clinical_Information_First_Submit__c';
import ACCOUNTID from '@salesforce/schema/WorkOrder.AccountId';
import Country from '@salesforce/schema/Lead.Country';
import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';

const workOrderFields = [FIRST_SUBMIT,ACCOUNTID];

export default class Dhhs_Shortform_ClinicalTab extends LightningElement {
    @api recordId;

    //first sbumit flag
    firstSubmit=false;

    //get the value of Clinical_Information_First_Submit__c field, if it is null, then it is the first submit, show the input form
    @wire (getRecord, {recordId: '$recordId', fields: workOrderFields})
    theWorkOrder(result){
        if(result.data){
            if(result.data.fields.Clinical_Information_First_Submit__c.value == null){
                this.firstSubmit = true;
            }
        }
    }

    //@track jsonText = "{\"details\":[{\"key\":\"Birth Date\",\"value\":\"PersonBirthdate\"},{\"key\":\"Mobile\",\"value\":\"PersonMobilePhone\"},{\"key\":\"Email\",\"value\":\"PersonEmail\"}]}"

    //spinner flag
    showSpinner = false;

    accountRecordType;

    //depende field flag
    showDateOfFirstSymptoms;
    showDateOfFirstSymptoms_error;
    showDose;
    showHospital;
    showCommencedOn;
    showCommencedOn_error;
    showStartDate;
    showStartDate_error;
    showDateAdmitted_error;
    showHospitalError;
    showCountry; //334338
   // @track threcordTypeId;

    //field values
    @track haveAnySymptoms;
    @track dateOfFirstSymptoms;
    @track hadVaccine;
    @track dose;
    @track startDate;
    @track contactHospital14DaysPriorSymptoms;
    @track dateAdmitted;
    @track hospital;
    @track wasAwareOfContactWithCase;
    @track isolationQuarantine48HrsPriorToSym;
    @track ifYesCommencedOn;
    @track recentTravelOverseas//334338
    @track countryOverseas//334338
    
    //wrapper class for backend
    formWrapper = {};

    //get object info for record type id
    @wire(getObjectInfo, { objectApiName: CAR_OBJECT })
    carInfo;

    @wire(getObjectInfo, { objectApiName: EHRI_OBJECT })
    ehriInfo;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseInfo;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountInfo;

    //334338
    recordTypeId='';
    @wire(getObjectInfo, { objectApiName: CE_OBJECT })
    getObjectInfo(result) {
        if (result.data) {
            const rtis = result.data.recordTypeInfos;
            console.log('result => ', JSON.stringify(result.data.recordTypeInfos));
            this.recordTypeId = Object.keys(rtis).find((rti) => rtis[rti].name === 'Travel History');
            console.log('this.recordTypeId ==>'+this.recordTypeId );
        }
    }

    //get picklist options
    @wire(getPicklistValues,{recordTypeId: '$carInfo.data.defaultRecordTypeId',fieldApiName: Did_person_have_symptoms})
    haveSymptomsOptions;

    @wire(getPicklistValues,{recordTypeId: '$ehriInfo.data.defaultRecordTypeId',fieldApiName: Dose_Received})
    doseReceivedOptions;

    @wire(getPicklistValues,{recordTypeId: '$caseInfo.data.defaultRecordTypeId',fieldApiName: Contact_hospital})
    contacthospitalOptions;

    @wire(getPicklistValues,{recordTypeId: '$caseInfo.data.defaultRecordTypeId',fieldApiName: Was_aware})
    wasAwareOptions;

    @wire(getPicklistValues,{recordTypeId: '$caseInfo.data.defaultRecordTypeId',fieldApiName: Isolation_Quarantine})
    isolationQuarantineOptions;

    //334338
    @wire(getPicklistValues,{recordTypeId: '$recordTypeId',fieldApiName: CECountry})
    countryOptions;

    //334338
    @wire(getPicklistValues,{recordTypeId: '$recordTypeId',fieldApiName: Recent_Travel_Overseas})
    recentTravelOverseasOptions;

    

       
    //handle change for recent Travel overseas
    handleChangeForTravel(event) {
        this.recentTravelOverseas = event.detail.value;
        if(event.detail.value == 'Yes'){
            this.showCountry = true;
        }else{
            this.showCountry = false;
        }
    }

    //handle change for Country
    handleChangeForCountry(event) {
        this.countryOverseas = event.detail.value;
    }


    //hand change Did_person_have_symptoms field
    handleChange1(event) {
        this.haveAnySymptoms = event.detail.value;
        if(event.detail.value == 'Yes'){
            this.showDateOfFirstSymptoms = true;
        }else{
            this.showDateOfFirstSymptoms = false;
            this.dateOfFirstSymptoms = null;
        }
    }

    //hand change Have_you_had_a_COVID_19_vaccine field
    handleChange2(event) {
        this.hadVaccine = event.target.checked;
        if (event.target.checked){
            this.showDose = true;
        }else{
            this.showDose = false;
            this.dose = null;
        }
    }

    //hand change HealthCloudGA__OnsetOfSymptoms field
    handleChange3(event) {
        if(new Date(event.detail.value) > new Date()){
            this.showDateOfFirstSymptoms_error = true;
            this.dateOfFirstSymptoms = null;
        }else{
            this.showDateOfFirstSymptoms_error = false;
            this.dateOfFirstSymptoms = event.detail.value;
        }
    }

    //hand change Dose_Received field
    handleChange4(event) {
        this.dose = event.detail.value;
    }

    //hand change date_admitted field
    handleChange5(event) {
        if(new Date(event.detail.value) > new Date()){
            this.showDateAdmitted_error = true;
            this.dateAdmitted = null;
        }else{
            this.showDateAdmitted_error = false;
            this.dateAdmitted = event.detail.value;

            if(event.detail.value != null){
                this.showHospital = true;
                /*
                const rtis = this.accountInfo.data.recordTypeInfos;
                console.log('recordTypeInfos-------------------',rtis);
                console.log('======================',Object.keys(rtis).find(rti => rtis[rti].name === 'Place Or Organisation'));
                this.accountRecordType = Object.keys(rtis).find(rti => rtis[rti].name === 'Place Or Organisation');
                */
            }else{
                this.showHospital = false;
                this.hospital = null;
                this.showHospitalError = false;
            }
        }
    }

    //hand change StartDate field
    handleChange6(event) {
        if(new Date(event.detail.value) > new Date()){
            this.showStartDate_error = true;
            this.startDate = null;
        }else{
            this.showStartDate_error = false;
            this.startDate = event.detail.value;
        }
    }

    //hand change Contact_hospital_14_days_prior_symptoms field
    handleChange7(event) {
        this.contactHospital14DaysPriorSymptoms = event.detail.value;
    }
    @wire(MessageContext)
    messageContext;

    //hand change HealthCloudGA__Account__c field
    handleChange8(event) {
        let tempAccountId = event.target.value;
        checkAccRecordType({accountId : tempAccountId}).then((resp)=>{
            if(resp == 'true'){
                this.hospital = tempAccountId;
                this.showHospitalError = false;
            }else{
                this.showHospitalError = true;
            }
        }).catch((err) => {
            console.log('err-----------------',JSON.stringify(err));
        });
    }

    //hand change Was_aware_of_contact_with_ve_case__c field
    handleChange9(event) {
        this.wasAwareOfContactWithCase = event.detail.value;
    }

    //hand change Isolation_Quarantine_48_hrs_prior_to_sym__c field
    handleChange10(event) {
        this.isolationQuarantine48HrsPriorToSym = event.detail.value;
        if(event.detail.value == 'Yes'){
            this.showCommencedOn = true;
            this.showStartDate = false;
            const today = new Date();
            this.startDate = today.toISOString().split('T')[0];
        }else{
            this.showCommencedOn = false;
            this.showStartDate = true;
            this.startDate = null;
        }
    }

    //hand change If_yes_Commenced_on__c field
    handleChange11(event) {
        if(new Date(event.detail.value) > new Date()){
            this.showCommencedOn_error = true;
            this.ifYesCommencedOn = null;
        }else{
            this.showCommencedOn_error = false;
            this.ifYesCommencedOn = event.detail.value;
        }
    }

    //handle save
    handleSave(event){

        if(this.showHospitalError == true){
            this.showToast('Please select a hospital.');
            return;
        }

        this.showSpinner = true;

        //updated for 334338
        this.formWrapper = {
            workOrderId : this.recordId,
            haveAnySymptoms: this.haveAnySymptoms, 
            dateOfFirstSymptoms: this.dateOfFirstSymptoms, 
            hadVaccine: this.hadVaccine, 
            dose: this.dose, 
            startDate: this.startDate, 
            contactHospital14DaysPriorSymptoms: this.contactHospital14DaysPriorSymptoms, 
            dateAdmitted: this.dateAdmitted, 
            hospital: this.hospital,
            wasAwareOfContactWithCase: this.wasAwareOfContactWithCase,
            isolationQuarantine48HrsPriorToSym: this.isolationQuarantine48HrsPriorToSym,
            ifYesCommencedOn: this.ifYesCommencedOn,
            recentTravelOverseas : this.recentTravelOverseas,
            countryOverseas : this.countryOverseas

        }

        console.log('formWrapper-------------------------',this.formWrapper);

        createNewRecords({theData : this.formWrapper}).then((resp)=>{
            console.log('resp++++++++++++++++++++++++++++',resp);
            this.showSpinner = false;
            this.showToast(resp);
            const message12 = {
                workOrderId: this.recordId
            };
            publish(this.messageContext, UPDATEINTERVIEW, message12);
            console.log('agege');
        }).catch((err) => {
            console.log('err============================',err);
            this.showSpinner = false;
            console.log(JSON.stringify(err));
            this.showToast(null);
        });
    }

    //show toast message
    showToast(result) {
        let message;
        let type;

        if(result == 'success'){
            type = 'success';
            message = 'Related records have been saved.';
            this.firstSubmit = false;
        }else{
            type = 'error';
            message = result;
        }

        const event = new ShowToastEvent({
            title: 'Message',
            message: message,
            variant: type,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}