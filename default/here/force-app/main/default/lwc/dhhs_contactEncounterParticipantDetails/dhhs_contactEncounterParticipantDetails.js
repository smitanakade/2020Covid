import {LightningElement, api, wire, track} from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import CONTACTENCOUNTERID_FIELD 		from '@salesforce/schema/ContactEncounterParticipant.ContactEncounterId';
import PERSONID_FIELD			        from '@salesforce/schema/ContactEncounterParticipant.ContactId';
import CONTACTTYPE_FIELD		        from '@salesforce/schema/ContactEncounterParticipant.Contact_Type__c';
import PARENTRECORDID_FIELD     	    from '@salesforce/schema/ContactEncounterParticipant.Parent_Record__c';
import RECORDID_FIELD           		from '@salesforce/schema/ContactEncounterParticipant.Record__c';
import RELTOPARENTRECORD_FIELD     	    from '@salesforce/schema/ContactEncounterParticipant.Relationship_to_Case__c';
import SPECIFYRELTOPARENTRECORD_FIELD   from '@salesforce/schema/ContactEncounterParticipant.Specify_relationship_to_case__c';
//import STARTTIME_FIELD     	        from '@salesforce/schema/ContactEncounterParticipant.StartTime';
//import ENDTIME_FIELD                  from '@salesforce/schema/ContactEncounterParticipant.End_Time__c';
import ONGOINGEXPOSURE_FIELD       	    from '@salesforce/schema/ContactEncounterParticipant.On_going_exposure__c';
import DESCRIPTION_FIELD                from '@salesforce/schema/ContactEncounterParticipant.Description__c';  // new field
import CEP                              from '@salesforce/schema/ContactEncounterParticipant';
import ACCOUNT                          from '@salesforce/schema/Account';

import getPersonContactId               from '@salesforce/apex/DHHS_CEPController.getPersonContactId';
import checkCasesExistForPersonId       from '@salesforce/apex/DHHS_CEPController.checkCasesExistForPersonId';
import checkCasesExistForRecordNumber   from '@salesforce/apex/DHHS_CEPController.checkCasesforRecordNumber';
import createCEP                        from '@salesforce/apex/DHHS_CEPController.createCEP'

import { subscribe, unsubscribe, MessageContext,publish } from 'lightning/messageService';
import SELECTEDMOVEMENT from '@salesforce/messageChannel/Selected_Record__c';
import CEPCREATED from '@salesforce/messageChannel/CEP_Created__c';
import SEARCHRESULT from '@salesforce/messageChannel/Search_Result__c';


export default class Dhhs_contactEncounterParticipantDetails extends LightningElement {
    
    @api recordId;
    @api movementId;
    @api movementName;
    @api startDateTime;
   //@api endDateTime;
    @api typeOfEncounter;
    @api relationshipToCasePick1;
    @api relationshipToCasePick2;
    @api description;
    @track personSelected = '';
    @api recNumber = '';
    @track personIdSelected = '';
    @track selectedCase = '';
    @api showcaselist = false;
    @api personAccountRecordType;
    
    _title;
    _message;
    _variant;
    contactEncounterId;
    relationshipToRecordOptions;
    relationshipToRecordPick;
    specifyRelationshipToRecordOptions;
    specifyRelationshipToRecordPick;
    //ongoingExposer;
    //showongoingexposure;

    @api disablePersonsearch = false;
    @api diaableRecordSearch = false;
    
    @track jsonText = "{\"details\":[{\"key\":\"Birth Date\",\"value\":\"PersonBirthdate\"},{\"key\":\"Mobile\",\"value\":\"PersonMobilePhone\"},{\"key\":\"Residential Address\",\"value\":\"Address_Text__pc\"},{\"key\":\"Email\",\"value\":\"PersonEmail\"}]}"
    @track jsonRecText = "{\"details\":[{\"key\":\"Account Name\",\"value\":\"Account.Name\"},{\"key\":\"Case Number\",\"value\":\"CaseNumber\"},{\"key\":\"Record Type\",\"value\":\"RecordType.Name\"}]}"

    @track disabledCondition = false;

    @wire(getObjectInfo, { objectApiName: CEP })
    cepMetadata;

    @wire(getObjectInfo, { objectApiName: ACCOUNT })
    accountMetadata;
    getpersonAccountRecordType(){
        return this.accountMetadata.data.defaultRecordTypeId;
    }
    
    @wire(MessageContext)
    messageContext;

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

    @wire(getPicklistValues, {   recordTypeId: '$cepMetadata.data.defaultRecordTypeId', fieldApiName: CONTACTTYPE_FIELD })
    setPicklistOptions3({error, data}) {
        if (data) {
            this.typeOfEncounterOptions = data.values;

        } else if (error) {
            console.log(error);
        }
    }

    handleChange(event) {
        this.disabledCondition = false;
        switch (event.target.name) {
            case 'relationshipToRecordPick':
                this.relationshipToRecordPick = event.target.value;
                break;
            case 'specifyRelationshipToRecordPick':
                this.specifyRelationshipToRecordPick = event.target.value;
                break;
            case 'typeOfEncounter':
                //debugger;
                this.typeOfEncounter = event.target.value;
                /*if (this.typeOfEncounter == 'Close contact' || this.typeOfEncounter == 'Secondary Close Contact')
                    this.showongoingexposure = true;
                else{
                    this.showongoingexposure = false;
                    this.ongoingExposer=false;
                }*/
                break; 
            /*case 'ongoingExposer':
                //debugger;
                this.ongoingExposer = event.target.checked;
                break;*/
            // case 'startDateTime':
            //     this.startDateTime = event.target.value;
            //     break;
            // case 'endDateTime':
            //     this.endDateTime = event.target.value;
            //     break;
            case 'description':
                this.description = event.target.value;
                break;

        }
    }
   
    //326923
    handleRecSelected(event) {
        console.log('<--handleRecSelected -- event.detail-->'+event.detail);
        this.disabledCondition = false;
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
                        this.personIdSelected = result.Account.PersonContactId;
                        console.log('this.personIdSelected -->'+this.personIdSelected );
                        this.template.querySelector('c-dhhs_-c-e-p-case-list-small').getRecord(this.recNumber);
                    }
                    else 
                        this.showcaselist = false; 
        }).catch((err)=>{
            console.log(err);
        });

    }
    

    handelPersonSelected(event) {
        console.log('<--handelPersonSelected-->')
        this.personSelected = event.detail;
        this.disableRecordSearch = true;
        this.getPersonIdForAccountId(this.personSelected);
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
        this.disabledCondition = false;
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

    handleCaseSelected(event){
        this.selectedCase = event.detail;
    }
   

    handleSubmitNewCEP(){
        this.disableRecordSearch = false;
        this.disablePersonsearch = false;
        if (this.isFormValid()) {
            this.createContactEncounterParticipant();
        }else{
            console.log('Invalid Form');
        }
    }

    createContactEncounterParticipant(){
        this.disabledCondition = true;
        //debugger;
        console.log('*** typeOfEncounter: '+this.typeOfEncounter);
        console.log('*** recordId: '+this.recordId);
        console.log('*** movementId: '+this.movementId);
        console.log('*** movementName: '+this.movementName);
        console.log('*** startDateTime: '+this.startDateTime);
        //console.log('*** endDateTime: '+this.endDateTime);
        console.log('*** relationshipToCasePick1: '+this.relationshipToRecordPick);
        console.log('*** relationshipToCasePick2: '+this.specifyRelationshipToRecordPick);
        //console.log('*** ongoingExposer: '+this.ongoingExposer);

        let newCEPRecord = {
            [CONTACTENCOUNTERID_FIELD.fieldApiName]         :   this.movementId,
            [PERSONID_FIELD.fieldApiName]                   :   this.personIdSelected,
            [CONTACTTYPE_FIELD.fieldApiName]                :   this.typeOfEncounter,
            [PARENTRECORDID_FIELD.fieldApiName]             :   this.recordId,
            [RECORDID_FIELD.fieldApiName]                   :   this.selectedCase,
            [RELTOPARENTRECORD_FIELD.fieldApiName]          :   this.relationshipToRecordPick,
            [SPECIFYRELTOPARENTRECORD_FIELD.fieldApiName]   :   this.specifyRelationshipToRecordPick,
            //[STARTTIME_FIELD.fieldApiName]                  :   this.startDateTime.toISOString, // Apex class not able to set this field.
            //[ENDTIME_FIELD.fieldApiName]                    :   this.endDateTime.toISOString,  // Set to the value of the CE.EndTime
            [DESCRIPTION_FIELD.fieldApiName]                :   this.description,
            //[ONGOINGEXPOSURE_FIELD.fieldApiName]            :   this.ongoingExposer,

        };
    

        createCEP({ newCEP : newCEPRecord})
            .then((result)=>{
                this.disabledCondition = false;
                this._message = 'Contact saved!';
                this._title = 'Success';
                this._variant = 'success';
                this.showNotification();
                console.log('before published');
                const payload = {
                    CEPId: result.Id
                };
                publish(this.messageContext, CEPCREATED, payload);
                console.log('<-- createCEP CEPId--> ' + JSON.stringify(payload));
                this.resetAll();
            }).catch((err)=>{
            console.log(err);
            //debugger;
            this._message = 'Error inserting contact -- '+err.body.message;
            this._title = 'Failed';
            this._variant = 'error';
            this.disabledCondition = false;
            this.showNotification();
        });
        
    }

    resetAll(){
        //debugger;
        this.relationshipToRecordPick = null;
        this.specifyRelationshipToRecordPick = null;
        this.typeOfEncounter = null;
        this.selectedCase = null;
        this.ContactEncounterId = null;
        this.startDateTime= null;
        //this.endDateTime = null;
        this.description = null;
        //this.contactEncounterId = null;
        //this.movementName = null;
        this.showcaselist= false;
        //this.ongoingExposer = null;
       // this.showongoingexposure = false;
        this.personIdSelected = null;
        this.personSelected = null;
        this.recNumber = null;
        this.selectedCase = null;
        this.disableRecordSearch = false;
        this.disablePersonsearch = false;

        this.template.querySelectorAll("c-type-ahead-component").forEach(element => {
            console.log('calling restart');
            element.restartSearch();
        });
        //this.template.querySelector("c-type-ahead-component").restartSearch();
    }

    @api
    isFormValid() {
        //debugger;
        let isvalidtosubmit = true;

        // typeOfEncounter field
        if (!this.template.querySelector("[data-id=typeofencounter]").value) {
            this.template.querySelector("[data-id=typeofencounter]").setCustomValidity("This field cannot be blank.");
            isvalidtosubmit = false;
        }
        else {
            this.template.querySelector("[data-id=typeofencounter]").setCustomValidity("");
            isvalidtosubmit = true;
        }
        this.template.querySelector("[data-id=typeofencounter]").reportValidity();

        //relationshiptorecordpick field
        if (!this.template.querySelector("[data-id=relationshiptorecordpick]").value) {
            this.template.querySelector("[data-id=relationshiptorecordpick]").setCustomValidity("This field cannot be blank.");
            isvalidtosubmit = false;
        }
        else {
            this.template.querySelector("[data-id=relationshiptorecordpick]").setCustomValidity("");
            isvalidtosubmit = true;
        }
        this.template.querySelector("[data-id=relationshiptorecordpick]").reportValidity();

        //Specifyrelationshiptorecordpick field
        if (!this.template.querySelector("[data-id=specifyrelationshiptorecordpick]").value) {
            this.template.querySelector("[data-id=specifyrelationshiptorecordpick]").setCustomValidity("This field cannot be blank.");
            isvalidtosubmit = false;
        }
        else {
            this.template.querySelector("[data-id=specifyrelationshiptorecordpick]").setCustomValidity("");
            isvalidtosubmit = true;
        }
        this.template.querySelector("[data-id=specifyrelationshiptorecordpick]").reportValidity();
        

        // //Start / End Dates
        if (this.personIdSelected == ""){
            this._message = 'Error inserting Contact - Please select a person or record';
            this._title = 'Failed';
            this._variant = 'error';
            this.showNotification();
            isvalidtosubmit = false;
        }

        if (this.movementId == "" || this.movementName == "" ){
            this._message = 'Error inserting Contact - Please select/create a movement';
            this._title = 'Failed';
            this._variant = 'error';
            this.showNotification();
            isvalidtosubmit = false;
        }

        return isvalidtosubmit;
        
    }
  


    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (this.subscription) {
            return;
        }
        if (this.subscriptionsearchResult) {
            return;
        }
              

        this.subscription = subscribe(
            this.messageContext,
            SELECTEDMOVEMENT, (message) => {
                this.disabledCondition = false;
                this.handleSelectedMovementMessage(message);
            }); 

         /****Subscribe to Search_Result__c***************/
         this.subscriptionsearchResult = subscribe(
            this.messageContext,
            SEARCHRESULT, (message) => {
                this.handleMessageForSearchResult(message);
          });
    }

    //unsubscribeToMessageChannel(){
    unsubscribeMC() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessageForSearchResult(message) {
        // check whether it is a reset 
        if(message.isReset === "True"){
            this.disabledCondition = false;
            this.disableRecordSearch = false;
            this.disablePersonsearch = false;
            this.showcaselist = false; 
            this.personIdSelected = '';
            this.personSelected = '';
            this.recNumber = '';
            this.selectedCase = '';
        }
    }


    @api
    handleSelectedMovementMessage(message)
    {
        this.disabledCondition = false;
        this.movementId = message.recordId;
        this.movementName = message.recordName;
    }

    // handleMessage(message) {
    //     this.startDateTime = message.date;
    //     this.endDateTime = message.date;

    // }

    // Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    // Helper
    dispatchToast(error) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error loading contact',
                message: reduceErrors(error).join(', '),
                variant: 'error'
            })
        );
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