import { LightningElement, api, wire, track } from 'lwc';
import { subscribe, unsubscribe, MessageContext,publish } from 'lightning/messageService';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CE from '@salesforce/schema/ContactEncounter';
import ROLEINSETTING_FIELD from '@salesforce/schema/ContactEncounter.Role_in_Setting__c';
import HEALTHCARESETTING_FIELD from '@salesforce/schema/ContactEncounter.Healthcare_Setting_Type__c';
import WARDORLOCATION_FIELD from '@salesforce/schema/ContactEncounter.Ward_or_location__c';
import HEALTHCARESETTINGOTHER_FIELD from '@salesforce/schema/ContactEncounter.Healthcare_Setting_Other__c';
import OTHERPRIVATEPRACTICE_FIELD from '@salesforce/schema/ContactEncounter.Other_Private_Practice_Clinic__c';
import HCSETTINGFORPATIENT_FIELD from '@salesforce/schema/ContactEncounter.HC_setting_for_Patient_or_visitor__c';
import OTHERSPECIFICPRACTICE_FIELD from '@salesforce/schema/ContactEncounter.Other_Specified_Private_Practice_Clinic__c';
import MOMENT from '@salesforce/resourceUrl/momentJS';
import { ShowToastEvent }       from 'lightning/platformShowToastEvent';
import createContactEncounter   from '@salesforce/apex/DHHS_ContactEncounterController.createDirectContactEncounter';
import ESTPARTICIPANTS_FIELD 	from '@salesforce/schema/ContactEncounter.EstimatedParticipantCount';
import LOCATIONID_FIELD 		from '@salesforce/schema/ContactEncounter.LocationId';
import NAME_FIELD				from '@salesforce/schema/ContactEncounter.Name';
import STARTDATETIME_FIELD		from '@salesforce/schema/ContactEncounter.StartTime';
import ENDDATETIEM_FIELD		from '@salesforce/schema/ContactEncounter.End_Time__c';
import MOVEMENTNOTES_FIELD		from '@salesforce/schema/ContactEncounter.Movement_Notes__c';
import CASEID_FIELD				from '@salesforce/schema/ContactEncounter.Record__c';
import LOCATION_FIELD           from '@salesforce/schema/ContactEncounter.LocationId';
import SAMPLEMC                 from '@salesforce/messageChannel/Date_Selected__c';
import UPDATEMOVEMENT           from '@salesforce/messageChannel/Encounter_Created__c';
import { loadScript } from "lightning/platformResourceLoader";
import UPDATEINTERVIEW1 from '@salesforce/messageChannel/ShortFormInterview__c';




// not certain how to refer to the the managed package - wrapping this in a flow and calling from apex.
//import createContactEncounter from '@salesforce/apex/HealthCloudGA.HcCreateContactEncounterAction.HcCreateContactEncounterActionInput';
//import createContactEncounter from '@salesforce/apex/HealthCloudGA.HcCreateContactEncounterAction';

export default class DHHS_POC_CaseMovementCloseContactLWC extends LightningElement {
    startdatetime;
    enddatetime;
    movementname;
    movementdetails;
    isrecurringmovement;
    newContactEncounterRecord;
    workedTrainedVolunteeredOptions;
    specificSettingsOptions;
    otherPrivatePracticeOptions;
    HCsettingForPatientVisitorOptions;
    specificsettingsname;
    worktrainedname;
    otherPrivatePractice;
    wardlocation;
    otherSpecifiedPrivatePractice;
    healthcareSetting;
    HCsettingForPatientVisitor;
    renderOtherPrivatePractice;
    renderOtherSpecifiedPrivatePractice;
    renderHealthcareSetting;
    renderHCsettingForPatientVisitor;
    renderHCW;
    loctionId;

    locationMappings; 
    locations; 
    recordTypeIds;

    _title;
    caseId;
    _message;
    _variant
    isloaded = false;
    jsonText = "{\"details\":[{\"key\":\"Address\",\"value\":\"Address__c\"},{\"key\":\"City\",\"value\":\"City__c\"},{\"key\":\"Postal Code\",\"value\":\"Postal_Code__c\"}]}"
    @api
    get recordId() {
        return this.caseId;
    }
    set recordId(value) {
        if(value)
        this.caseId = value;
    }

    @wire(MessageContext)
    messageContext;

    renderspecificsettings;
    renderwardlocation;

    get nameOfMovementOptions() {
        return [

            // Commented as part of PBI - 262570 { label: 'Aged Care Facility', value: 'Aged Care Facility' },
            { label: 'Cafe/restaurant', value: 'Cafe/restaurant' },
            { label: 'Childcare centre', value: 'Childcare centre' },
            { label: 'Cinemas/theatres', value: 'Cinemas/theatres' },
            { label: 'Clubs/bars', value: 'Clubs/bars' },
            { label: 'Correctional facility (youth and adult facilities)', value: 'Correctional facility (youth and adult facilities)' },
            // Commented as part of PBI - 262570 { label: 'Dentist', value: 'Dentist' },
            // Commented as part of PBI - 262570 { label: 'Disability service', value: 'Disability service' },
            { label: 'Gym/sports centre', value: 'Gym/sports centre' },
            // Commented as part of PBI - 262570 { label: 'Healthcare facility (e.g hospital)', value: 'Healthcare facility (e.g hospital)' },
            { label: 'Hotel/conference centre', value: 'Hotel/conference centre' },
            // Commented as part of PBI - 262570 { label: 'Medical clinic (e.g. GP)', value: 'Medical clinic (e.g. GP)' },
            { label: 'Museum/gallery', value: 'Museum/gallery' },
            { label: 'Place of worship', value: 'Place of worship' },
            { label: 'Pools/aquatic centres', value: 'Pools/aquatic centres' },
            { label: 'Private Residence - home', value: 'Private Residence - home' },
            { label: 'Private residence - social', value: 'Private residence - social' },
            { label: 'Public transport', value: 'Public transport' },
            // Commented as part of PBI - 262570 { label: 'Rehabilitation facility', value: 'Rehabilitation facility' },
            { label: 'Shopping centres/ large retailers', value: 'Shopping centres / large retailers' },
            { label: 'Taxis or rideshares (e.g. Uber, Didi etc)', value: 'Taxis or rideshares (e.g. Uber, Didi etc)' },
            { label: 'Workplace', value: 'Workplace' },
            { label: 'Education (e.g Primary School / University)', value: 'Education (e.g Primary School / University)' },
            { label: 'Flight (Domestic)', value: 'Flight (Domestic)' },
            { label: 'Flight (International)', value: 'Flight (International)' },
            { label: 'Others', value: 'Others' },
            // added as part of PBI - 262570
            { label: 'Healthcare, aged care or disability setting', value: 'Healthcare, aged care or disability setting' },
            // added as part of PBI - 289108
            { label: 'Private Transport', value: 'Private Transport' },
            { label: 'Shop/Small Retail', value: 'Shop/Small Retail' },
            { label: 'Airport Terminal', value: 'Airport Terminal' }
        ];
    }

    @wire(getObjectInfo, { objectApiName: CE })
    ceMetadata;

    @wire(getPicklistValues, {   recordTypeId: '$ceMetadata.data.defaultRecordTypeId', fieldApiName: HEALTHCARESETTING_FIELD })
    setPicklistOptions({error, data}) {
        if (data) {
            this.specificSettingsOptions = data.values;

        } else if (error) {
            console.log(error);
        }
    }

    @wire(getPicklistValues, {   recordTypeId: '$ceMetadata.data.defaultRecordTypeId', fieldApiName: ROLEINSETTING_FIELD })
    setPicklistOptions2({error, data}) {
        if (data) {
            this.workedTrainedVolunteeredOptions = data.values;

        } else if (error) {
            console.log(error);
        }
    };

    @wire(getPicklistValues, {   recordTypeId: '$ceMetadata.data.defaultRecordTypeId', fieldApiName: OTHERPRIVATEPRACTICE_FIELD })
    setPicklistOptions3({error, data}) {
        if (data) {
            this.otherPrivatePracticeOptions = data.values;

        } else if (error) {
            console.log(error);
        }
    };
    @wire(getPicklistValues, {   recordTypeId: '$ceMetadata.data.defaultRecordTypeId', fieldApiName: HCSETTINGFORPATIENT_FIELD })
    setPicklistOptions4({error, data}) {
        if (data) {
            this.HCsettingForPatientVisitorOptions = data.values;

        } else if (error) {
            console.log(error);
        }
    };

    subscribeToMessageChannel() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(
            this.messageContext,
            SAMPLEMC, (message) => {
                this.handleMessage(message);
                console.log('SUBSCRIBED TO THE CHANNEL');
            });
    }

    handleSelectedLocation(event){

        console.log('I AM SELECTED!!!' + event.detail);
        this.locationId=event.detail;

    }

    handleMessage(message){
        debugger;
        console.log(message);
        //this.loadMomentJs();

        this.template.querySelectorAll('lightning-input').forEach(each => {
            console.log(each);
            if (each.name =="startdatetime" || each.name =="enddatetime") {
                each.value = message.date;
            }
            this.startdatetime = moment(message.date);
            this.enddatetime =moment(message.date);
        });
    }

    unsubscribeMC() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        if(!this.isLoaded){
            loadScript(this, MOMENT+'/moment.min.js');
            this.isLoaded= true;}
    }


    handleAllDayEvent(event){
        console.log(this.startdatetime);

        if(this.startdatetime){
            this.startdatetime.hour(0);
            this.startdatetime.minute(0);

            this.template.querySelector("[data-id=startdatetime]").value = this.startdatetime.toISOString();
            console.log('SETTING TO '+this.startdatetime.toISOString());

            this.enddatetime = this.startdatetime.clone();
            this.enddatetime.hour(23);
            this.enddatetime.minute(59);

            this.template.querySelector("[data-id=enddatetime]").value = this.enddatetime.toISOString();

        }

    }

    handleChange(event) {
        switch (event.target.name) {
            case 'movementname':
                this.movementname = event.target.value;
                this.renderHCW = (event.target.value == 'Healthcare, aged care or disability setting');
                break;
            case 'startdatetime':
                this.startdatetime = moment(event.target.value);
                break;
            case 'enddatetime':
                this.enddatetime = moment(event.target.value);
                break;
            case 'movementdetails':
                this.movementdetails = event.target.value;
                break
            case 'recurringmovement':
                this.isrecurringmovement = event.target.checked;
                break
            case 'typeahead':
                break;
            case 'worktrainedvolunteered':
                //Console.log((event.target.value == 'Worked') || (event.target.value = 'Trained') || (event.target.value = 'Volunteered'));
                this.worktrainedname = event.target.value;
                this.renderspecificsettings = ((event.target.value == 'Worked') || (event.target.value == 'Trained (e.g. as student on a clinical placement)') || (event.target.value == 'Volunteered'));
                this.HCsettingForPatientVisitor = '';
                this.specificsettingsname = '';
                this.otherPrivatePractice = '';
                this.healthcareSetting = '';
                this.otherSpecifiedPrivatePractice = '';
                this.wardlocation = '';
                this.renderHCsettingForPatientVisitor = ((event.target.value == 'Attended as patient/ client') || (event.target.value == 'Visited') || (event.target.value == 'Other'));
                this.renderwardlocation = (event.target.value == 'Hospital (other ward/location, or not specified)');
                this.renderOtherSpecifiedPrivatePractice = undefined;
                this.renderOtherPrivatePractice = (event.target.value == 'Other private practice/clinic'); 
                this.renderHealthcareSetting = (event.target.value == 'Other healthcare setting');
                break;
            case 'specificsettings':
                this.specificsettingsname = event.target.value;
                this.otherPrivatePractice = '';
                this.healthcareSetting = '';
                this.otherSpecifiedPrivatePractice = '';
                this.wardlocation = '';
                this.renderwardlocation = (event.target.value == 'Hospital (other ward/location, or not specified)');
                this.renderOtherPrivatePractice = (event.target.value == 'Other private practice/clinic'); 
                this.renderHealthcareSetting = (event.target.value == 'Other healthcare setting');
                break;
            case 'otherPrivatePractice':
                this.otherPrivatePractice = event.target.value;
                this.otherSpecifiedPrivatePractice = '';
                this.renderOtherSpecifiedPrivatePractice = (event.target.value == 'Other');
                break; 
            case 'otherSpecifiedPrivatePractice':
                this.otherSpecifiedPrivatePractice = event.target.value;
                break;    
            case 'HCsettingForPatientVisitor':
                this.HCsettingForPatientVisitor = event.target.value;
                break; 
            case 'healthcareSetting':
                this.healthcareSetting = event.target.value;
                break;     
            case 'wardlocation':
                this.wardlocation = event.target.value;
                break; 

        }
    }

    handleSubmit(event) {
        console.log('Clicked');
        if (this.isFormValid(event)) {
            this.createContactEncounter(event);
        }else{
            consloe.log('Invalid Form');
        }
    }


    createContactEncounter(event) {

        //this.locationId = String(records.Id);

        // console.log('*** startdatetime: '+ this.startdatetime.toISOString());
        // debugger;
        // let ltzStartDateTime = (new Date(this.startdatetime)).toLocaleString();
        // console.log('*** ltzStartDateTime: '+ ltzStartDateTime);
        // let formattedStartDate = (new Date(ltzStartDateTime));
        // //let tmp = formattedDate.toISOString();

        // let ltzEndDateTime = (new Date(this.enddatetime)).toLocaleString();
        // let formattedEndDate = (new Date(ltzEndDateTime));
       

        //console.log('*** formattedDate: '+ formattedDate);

        let newcontactencounterrecord = {
            [LOCATIONID_FIELD.fieldApiName]		: this.locationId,
            [NAME_FIELD.fieldApiName]			: this.movementname,
            [STARTDATETIME_FIELD.fieldApiName]	: this.startdatetime.toISOString(),
            //[STARTDATETIME_FIELD.fieldApiName]	: formattedStartDate.toISOString(),
            [ENDDATETIEM_FIELD.fieldApiName]	: this.enddatetime.toISOString(),
            //[ENDDATETIEM_FIELD.fieldApiName]	: formattedEndDate.toISOString(),
            [MOVEMENTNOTES_FIELD.fieldApiName]	: this.movementdetails,
            [CASEID_FIELD.fieldApiName]			: this.recordId,
            [ROLEINSETTING_FIELD.fieldApiName]          : this.worktrainedname,
            [HEALTHCARESETTING_FIELD.fieldApiName]      : this.specificsettingsname,
            [WARDORLOCATION_FIELD.fieldApiName]         : this.wardlocation,
            [HEALTHCARESETTINGOTHER_FIELD.fieldApiName] : this.healthcareSetting,
            [OTHERSPECIFICPRACTICE_FIELD.fieldApiName]  : this.otherSpecifiedPrivatePractice,
            [OTHERPRIVATEPRACTICE_FIELD.fieldApiName]   : this.otherPrivatePractice,
            [HCSETTINGFORPATIENT_FIELD.fieldApiName]    : this.HCsettingForPatientVisitor,

        };

        debugger;

        createContactEncounter({ contactEnc : newcontactencounterrecord})
            .then((result)=>{
                this._message = 'Contact movement saved!';
                this._title = 'Success';
                this._variant = 'success';
                this.showNotification();
                this.resetAll(event);

                const message = {
                    encounterId: result.Id
                };
                publish(this.messageContext, UPDATEMOVEMENT, message);
                publish(this.messageContext, UPDATEINTERVIEW1, message);

                // PBI-332615: grey out loc lookup after ce creation
                const locLookupMessage = {
                    disable: true
                };
                publish(this.messageContext, ENABLELOCATIONLOOKUP, locLookupMessage);
            }).catch((err)=>{

            console.log(err);
            debugger;
            this._message = 'Error inserting case movement -- '+err.body.message;
            this._title = 'Failed';
            this._variant = 'error';
            this.showNotification();
        });
    }

    resetAll(event){
        if(this.template.querySelector("[data-id=recurringmovement]").checked){
            //this.template.querySelector("[data-id=startdatetime]").value = undefined;
            //this.template.querySelector("[data-id=enddatetime]").value = undefined;
            this.startdatetime= null;
            this.enddatetime = null;

        }else{
            this.template.querySelector("[data-id=movementname]").value = undefined;
            this.template.querySelector("[data-id=movementdetails]").value = undefined;
            this.template.querySelector("[data-id=startdatetime]").value = undefined;
            this.template.querySelector("[data-id=enddatetime]").value = undefined;
            this.template.querySelector("c-type-ahead-component").restartSearch();
            this.locationId = null;
            this.movementname = null;
            this.startdatetime= null;
            this.enddatetime = null;
            if(this.movementdetails) this.movementdetails = null;
            this.recordId = null;
            if(this.template.querySelector("[data-id=worktrainedname]")) this.template.querySelector("[data-id=worktrainedname]").value = undefined;
            if(this.template.querySelector("[data-id=specificsettingsname]")) this.template.querySelector("[data-id=specificsettingsname]").value = undefined;
            if(this.template.querySelector("[data-id=otherPrivatePractice]")) this.template.querySelector("[data-id=otherPrivatePractice]").value = undefined;
            if(this.template.querySelector("[data-id=wardlocation]")) this.template.querySelector("[data-id=wardlocation]").value = undefined;
            if(this.template.querySelector("[data-id=otherSpecifiedPrivatePractice]")) this.template.querySelector("[data-id=otherSpecifiedPrivatePractice]").value = undefined;
            if(this.template.querySelector("[data-id=healthcareSetting]")) this.template.querySelector("[data-id=healthcareSetting]").value = undefined;
            if(this.template.querySelector("[data-id=HCsettingForPatientVisitor]")) this.template.querySelector("[data-id=HCsettingForPatientVisitor]").value = undefined;
            if(this.specificsettingsname) this.specificsettingsname = null;
            if(this.worktrainedname) this.worktrainedname = null;
            if(this.otherPrivatePractice) this.otherPrivatePractice = null;
            if(this.wardlocation) this.wardlocation = null;
            if(this.otherSpecifiedPrivatePractice) this.otherSpecifiedPrivatePractice = null;
            if(this.healthcareSetting) this.healthcareSetting = null;
            if(this.HCsettingForPatientVisitor) this.HCsettingForPatientVisitor = null;
            if(this.renderspecificsettings) this.renderspecificsettings = undefined;
            if(this.renderHCsettingForPatientVisitor) this.renderHCsettingForPatientVisitor = undefined;
            if(this.renderwardlocation) this.renderwardlocation = undefined;
            if(this.renderOtherSpecifiedPrivatePractice) this.renderOtherSpecifiedPrivatePractice = undefined;
            if(this.renderOtherPrivatePractice) this.renderOtherPrivatePractice = undefined;
            if(this.renderHealthcareSetting) this.renderHealthcareSetting = undefined;
            if(this.renderHCW) this.renderHCW = undefined;

        }
    }

    isFormValid(event) {
        let isvalidtosubmit;
        if (!this.template.querySelector("[data-id=movementname]").value) {
            this.template.querySelector("[data-id=movementname]").setCustomValidity("This field cannot be blank.");
            isvalidtosubmit = false;
        }
        else {
            this.template.querySelector("[data-id=movementname]").setCustomValidity("");
            isvalidtosubmit = true;
        }
        this.template.querySelector("[data-id=movementname]").reportValidity();

        if (!this.template.querySelector("[data-id=startdatetime]").value) {
            this.template.querySelector("[data-id=startdatetime]").setCustomValidity("This field cannot be blank.");
            isvalidtosubmit = false;
        }
        else {
            this.template.querySelector("[data-id=startdatetime]").setCustomValidity("");
            if(isvalidtosubmit == undefined){
                isvalidtosubmit = true;
            }
        }
        this.template.querySelector("[data-id=startdatetime]").reportValidity();

        if (!this.template.querySelector("[data-id=enddatetime]").value) {
            this.template.querySelector("[data-id=enddatetime]").setCustomValidity("Cannot be blank.");
            isvalidtosubmit = false;
        }
        else {
            this.template.querySelector("[data-id=enddatetime]").setCustomValidity("");
            if(isvalidtosubmit == undefined){
                isvalidtosubmit = true;
            }
        }
        this.template.querySelector("[data-id=enddatetime]").reportValidity();

        if (this.template.querySelector("[data-id=movementname]").value && this.template.querySelector("[data-id=movementname]").value === 'Healthcare, aged care or disability setting' && !this.template.querySelector("[data-id=worktrainedname]").value) {
            this.template.querySelector("[data-id=worktrainedname]").setCustomValidity("This field cannot be blank.");
            if(isvalidtosubmit){
                isvalidtosubmit = false;
            }    
        }
        else if(this.template.querySelector("[data-id=movementname]").value && this.template.querySelector("[data-id=movementname]").value === 'Healthcare, aged care or disability setting' && this.template.querySelector("[data-id=worktrainedname]").value){
            this.template.querySelector("[data-id=worktrainedname]").setCustomValidity("");
            if(isvalidtosubmit == undefined){
                isvalidtosubmit = true;
            }
        }
        if(this.renderHCW){
            this.template.querySelector("[data-id=worktrainedname]").reportValidity();
        }

        if (this.renderspecificsettings && !this.template.querySelector("[data-id=specificsettingsname]").value) {
            this.template.querySelector("[data-id=specificsettingsname]").setCustomValidity("This field cannot be blank.");
            if(isvalidtosubmit){
                isvalidtosubmit = false;
            }    
        }
        else if(this.renderspecificsettings && this.template.querySelector("[data-id=specificsettingsname]").value){
            this.template.querySelector("[data-id=specificsettingsname]").setCustomValidity("");
            if(isvalidtosubmit == undefined){
                isvalidtosubmit = true;
            }
        }
        if(this.renderspecificsettings){
            this.template.querySelector("[data-id=specificsettingsname]").reportValidity();
        }

        if (this.renderwardlocation && !this.template.querySelector("[data-id=wardlocation]").value) {
            this.template.querySelector("[data-id=wardlocation]").setCustomValidity("This field cannot be blank.");
            if(isvalidtosubmit){
                isvalidtosubmit = false;
            }    
        }
        else if(this.renderwardlocation && this.template.querySelector("[data-id=wardlocation]").value){
            this.template.querySelector("[data-id=wardlocation]").setCustomValidity("");
            if(isvalidtosubmit == undefined){
                isvalidtosubmit = true;
            }
        }
        if(this.renderwardlocation){
            this.template.querySelector("[data-id=wardlocation]").reportValidity();
        }

        // otherPrivatePractice
        if (this.renderOtherPrivatePractice && !this.template.querySelector("[data-id=otherPrivatePractice]").value) {
            this.template.querySelector("[data-id=otherPrivatePractice]").setCustomValidity("This field cannot be blank.");
            if(isvalidtosubmit){
                isvalidtosubmit = false;
            }    
        }
        else if(this.renderwarenderOtherPrivatePracticerdlocation && this.template.querySelector("[data-id=otherPrivatePractice]").value){
            this.template.querySelector("[data-id=otherPrivatePractice]").setCustomValidity("");
            if(isvalidtosubmit == undefined){
                isvalidtosubmit = true;
            }
        }
        if(this.renderOtherPrivatePractice){
            this.template.querySelector("[data-id=otherPrivatePractice]").reportValidity();
        }

        // otherSpecifiedPrivatePractice
        if (this.renderOtherSpecifiedPrivatePractice && !this.template.querySelector("[data-id=otherSpecifiedPrivatePractice]").value) {
            this.template.querySelector("[data-id=otherSpecifiedPrivatePractice]").setCustomValidity("This field cannot be blank.");
            if(isvalidtosubmit){
                isvalidtosubmit = false;
            }    
        }
        else if(this.renderOtherSpecifiedPrivatePractice && this.template.querySelector("[data-id=otherSpecifiedPrivatePractice]").value){
            this.template.querySelector("[data-id=otherSpecifiedPrivatePractice]").setCustomValidity("");
            if(isvalidtosubmit == undefined){
                isvalidtosubmit = true;
            }
        }
        if(this.renderOtherSpecifiedPrivatePractice){
            this.template.querySelector("[data-id=otherSpecifiedPrivatePractice]").reportValidity();
        }

        // healthcareSetting
        if (this.renderHealthcareSetting && !this.template.querySelector("[data-id=healthcareSetting]").value) {
            this.template.querySelector("[data-id=healthcareSetting]").setCustomValidity("This field cannot be blank.");
            if(isvalidtosubmit){
                isvalidtosubmit = false;
            }    
        }
        else if(this.renderHealthcareSetting && this.template.querySelector("[data-id=healthcareSetting]").value){
            this.template.querySelector("[data-id=healthcareSetting]").setCustomValidity("");
            if(isvalidtosubmit == undefined){
                isvalidtosubmit = true;
            }
        }
        if(this.renderHealthcareSetting){
            this.template.querySelector("[data-id=healthcareSetting]").reportValidity();
        }

        // HCsettingForPatientVisitor
        if (this.renderHCsettingForPatientVisitor && !this.template.querySelector("[data-id=HCsettingForPatientVisitor]").value) {
            this.template.querySelector("[data-id=HCsettingForPatientVisitor]").setCustomValidity("This field cannot be blank.");
            if(isvalidtosubmit){
                isvalidtosubmit = false;
            }    
        }
        else if(this.renderHCsettingForPatientVisitor && this.template.querySelector("[data-id=HCsettingForPatientVisitor]").value){
            this.template.querySelector("[data-id=HCsettingForPatientVisitor]").setCustomValidity("");
            if(isvalidtosubmit == undefined){
                isvalidtosubmit = true;
            }
        }
        if(this.renderHCsettingForPatientVisitor){
            this.template.querySelector("[data-id=HCsettingForPatientVisitor]").reportValidity();
        }

        return isvalidtosubmit;
    }

    showNotification() {
        const evt = new ShowToastEvent({
            title: this._title,
            message: this._message,
            variant: this._variant,
        });
        this.dispatchEvent(evt);
    }

}