import { LightningElement,wire,api,track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import fetchdata   from '@salesforce/apex/recordAddressHandler.fetchaddress';
import fetchcpadata  from '@salesforce/apex/recordAddressHandler.fetchCPAAddress';
import updatecurrentid   from '@salesforce/apex/recordAddressHandler.updatecurrentid';
import updatecurrentaddress   from '@salesforce/apex/recordAddressHandler.updateprimaryresidentialaddress';
import fetchpradata  from '@salesforce/apex/recordAddressHandler.fetchPRAAddress';

const CONFIELDS = [
    'Contact.AccountId',
];

const RECFIELDS = [
    'Case.AccountId',
];

export default class RecordAddress extends LightningElement {

    @api recordId; 
    @api objectApiName ;
    @track addressvalues = [];
    value = '';
    currentstreet = '';
    currentcity = '';
    currentcountry = '';
    currentprovince = '';
    currentpostalcode = '';
    newstreet = '';
    newcity = '';
    newcountry = '';
    newprovince = '';
    newpostalcode = '';
    cpastreet = '';
    cpacity = '';
    cpacountry = '';
    cpaprovince = '';
    cpapostalcode = '';
    currentid = '';
    currenttype = '';
    addressType = '';
    relatedAccountName = '';
    createnewcpa = false;
    createnewhmip = false;
    createnewpra = false;
    recordtype = '';
    objecttype = '';
    objectid = '';
    assigntorecord = false;
    selectedid = '';
    selectedtype = '';
    isloading = false;
    showcreateoredit = false;
    rendermode = '';
    headervalue = '';
    ispraupdate = false;
    iscpa = false;
    iscpaedit = false;
    ishmip = false;
    selectedCPAId='';

    
    @wire(getRecord, { recordId: '$recordId', fields: RECFIELDS })
    case;
    get accountId(){
        return this.case.data.fields.AccountId.value;
    }


   /* @wire(getRecord, { recordId: '$recordId', fields: CONFIELDS })
    contact;
    get AccountId(){
        return this.contact.data.fields.AccountId.value;
    }*/
    
    get createaddressoptions() {
         return [
                     { label: 'Contact Point Address', value: 'CPA' },
                     { label: 'Hospital and Hotel Presentation', value: 'HMIP' },
                     { label: 'Primary/Residential Address', value: 'PRA' },
                 ];
     }

     connectedCallback(){
        this.isloading = true;
        this.fetchaddressvalues();
        setInterval(() => {
            this.fetchaddressvalues();
         }, 30000);
    }

     handleselectionchange(event){     
        const aid = event.target.getAttribute('data-id');
        this.selectedid = event.target.getAttribute('data-id');
        this.selectedtype = event.target.getAttribute('data-recordtype');
        this.template.querySelectorAll("[data-type='selectbutton']").forEach(element => {        
            if(element.getAttribute("data-id") == aid){
                element.checked = true;
                }else{
                    element.checked = false;  
                }            
        });
     }

    handleformsave(){
        this.isloading = true;
        updatecurrentid({caseid : this.recordId, currentid: this.selectedid , currenttype: this.selectedtype})
        .then(result=>{
            if(result){
                this.fetchaddressvalues();
            }   
            console.log(JSON.stringify(result)); 
        })
        .catch(error=>{
            this.isloading = false;
            console.log(JSON.stringify(error)); 
        });
    }

     handleformcancel(){
     this.template.querySelectorAll("[data-type='selectbutton']").forEach(element => {
            element.checked = false;          
         });
     }

     handleeditclick(event){
        let x = event.target;
        while (x.nodeName !== "SPAN") {
          x = x.parentNode;
        }
        var aid = x.getAttribute('data-id');
        var rtype = x.getAttribute('data-recordtype');
        this.objectid = aid;
        this.showcreateoredit = true; 
         switch(rtype){
            case "CPA":
                this.fetchCPAAddress();
                this.recordtype = 'Contact Point Address';
                this.objecttype = 'ContactPointAddress';
                this.iscpa = false;
                this.iscpaedit = true;
                this.ishmip = false;
                this.ispra = false;
                break;
            case "HMIP":
                this.recordtype = 'Hospital, Medical and Isolation Presentation';
                this.objecttype = 'HealthCloudGA__EhrEncounter__c';
                this.iscpa = false;
                this.iscpaedit = false;
                this.ishmip = true;
                this.ispra = false;
                break;
            case "PRA":
                this.fetchPRAAddress();
                this.recordtype = 'Primary/Residential Address';
                this.objecttype = 'Account';
                this.iscpa = false;
                this.iscpaedit = false;
                this.ishmip = false;
                this.ispra = true;
                this.ispraupdate = true;
                break;
         }
     } 

    fetchCPAAddress(){
        fetchcpadata({cpaId : this.objectid})
        .then(result=>{
           if(result){
               this.cpastreet = result.Street;
               this.cpacity = result.City;
               this.cpacountry = result.Country;
               this.cpaprovince = result.State;
               this.cpapostalcode = result.PostalCode;
           }
        })
        .catch(error=>{
        });
    }

    fetchPRAAddress(){
        fetchpradata({accountid : this.objectid})
        .then(result=>{
           if(result){
               this.newstreet = result.PersonMailingStreet;
               this.newcity = result.PersonMailingCity;
               this.newcountry = result.PersonMailingCountry;
               this.newprovince = result.PersonMailingState;
               this.newpostalcode = result.PersonMailingPostalCode;
               
           }
        })
        .catch(error=>{
        });
    }

    fetchaddressvalues(){
    fetchdata({caseid : this.recordId})
    .then(result=>{

        if(result){
            this.currentstreet = result.street;
            this.currentcity = result.city;
            this.currentcountry = result.country;
            this.currentprovince = result.province;
            this.currentpostalcode = result.postcode;
            this.currentid = result.id;
            this.relatedAccountName = result.relatedAccountName != undefined && result.relatedAccountName != null ? result.relatedAccountName : '';
            this.currenttype = result.type;
            this.addressvalues = result.addressoptions;

            if(result.addressType != null && result.addressType != undefined){
                this.addressType = ' ('+ result.addressType+')';
            }
            else{
                this.addressType = '';
            }

            switch(this.currenttype){
                case "CPA":
                    this.headervalue = 'Contact Point Address' + this.addressType;
                    break;
                case "HMIP":
                    this.headervalue = 'Hospital and Hotel Presentation' + this.addressType + '\r\n' + this.relatedAccountName;
                    break;
                case "PRA":
                    this.headervalue = 'Primary (Residential Address)';
                    break;
             }

        }
        this.isloading = false;
        
     })
    .catch(error=>{
        this.isloading = false;

    });
        
    }
    
    handleChange(event) { 
        this.value = event.detail.value;
        if(this.value == 'CPA'){
            this.resetpraaddress();
            this.showcreateoredit = true; 
            this.ishmip = false;
            this.ispra = false;
            this.iscpa = true;
            this.iscpaedit = false;
            this.recordtype = 'Contact Point Address'
            this.objecttype = 'ContactPointAddress';
            this.objectid = '';
        }
        if(this.value == 'HMIP'){
            this.showcreateoredit = true; 
            this.ishmip = true;
            this.ispra = false;
            this.iscpa = false;
            this.iscpaedit = false;
            this.assigntorecord = true;
            this.recordtype = 'Hospital, Medical and Isolation Presentation';
            this.objecttype = 'HealthCloudGA__EhrEncounter__c';
            this.objectid = '';
        }
        if(this.value == 'PRA'){
            this.resetnewaddress();
            this.showcreateoredit = true; 
            this.ispra = true;
            this.iscpa = false;
            this.iscpaedit = false;
            this.ishmip = false;
            this.recordtype = 'Primary/Residential Address';
        }
    }

    closepopup(){
        this.showcreateoredit = false;
        this.iscpa = false;
        this.iscpaedit = false;
        this.ishmip = false; 
        this.ispra = false;
        this.ispraupdate = false;
        this.value = ''; 
        this.assigntorecord = false;
        this.recordtype = '';
        this.objecttype = '';
        this.objectid = '';
    } 

    resetnewaddress(){
        this.newstreet = '';
        this.newcity = ''; 
        this.newcountry = '';
        this.newprovince = '';
        this.newpostalcode = ''; 
    }

    resetpraaddress(){
        this.cpastreet = '';
        this.cpacity = '';
        this.cpaprovince = '';
        this.cpacountry = '';
        this.cpapostalcode = '';
    }

    handleaddresschange(event) {
        this.newstreet = event.target.street;
        this.newcity = event.target.city;
        this.newprovince = event.target.province;
        this.newcountry = event.target.country;
        this.newpostalcode = event.target.postalCode;
    }

    handleCpaAddressChange(event){
        this.cpastreet = event.target.street;
        this.cpacity = event.target.city;
        this.cpaprovince = event.target.province;
        this.cpacountry = event.target.country;
        this.cpapostalcode = event.target.postalCode;
    }

    handleprasave(){
        this.isloading = true;
        updatecurrentaddress({accountid : this.accountId, street: this.newstreet , city: this.newcity, country : this.newcountry, province : this.newprovince, postalcode : this.newpostalcode, isupdate: this.ispraupdate})
        .then(result=>{
            this.isloading = false;
            if(result){
                this.showSuccessToast('Account Primary/Residential Address updated Successfully');
                this.fetchaddressvalues();
                this.closepopup();
            }
         })
        .catch(error=>{
            this.isloading = false;
        });
    }

    handlecurrentaddressedit(){
        this.showcreateoredit = true; 
        if(this.currenttype == 'CPA'){
            this.ispra = false; 
            this.iscpa = false;
            this.iscpaedit = true;
            this.ishmip = false;
            this.objecttype = 'ContactPointAddress';
            this.recordtype = 'Contact Point Address';
            this.objectid = this.currentid;
        }
        if(this.currenttype == 'HMIP'){
            this.ispra = false; 
            this.ishmip = true;
            this.iscpa = false;
            this.iscpaedit = false;
            this.recordtype = 'Hospital, Medical and Isolation Presentation';
            this.objecttype = 'HealthCloudGA__EhrEncounter__c';
            this.objectid = this.currentid;
        }
        if(this.currenttype == 'PRA'){
            this.ispra = true; 
            this.ispraupdate = true;
            this.iscpa = false;
            this.iscpaedit = false;
            this.ishmip = false;
            this.recordtype = 'Primary/Residential Address';
            this.newstreet = this.currentstreet;
            this.newcity = this.currentcity; 
            this.newcountry = this.currentcountry;
            this.newprovince = this.currentprovince;
            this.newpostalcode = this.currentpostalcode;
        }
    }

    handlesuccess(){
        this.isloading = false;
        const modevalue = (this.objectid == '') ? 'Added' : 'Updated';
        if(this.objecttype == 'ContactPointAddress'){
            this.showSuccessToast('Contact Point Address '+ modevalue+' Successfully');
        }
        if(this.objecttype == 'HealthCloudGA__EhrEncounter__c'){
            this.showSuccessToast('Hospital, Medical and Isolation Presentation Address '+ modevalue+' Successfully');
        }
        
        this.fetchaddressvalues();
        this.closepopup();
    }

    handlesubmit(event){
        this.isloading = true;
        if(this.objecttype == 'ContactPointAddress'){
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        if(fields.ActiveFromDate == null || fields.ActiveFromDate == undefined){
            this.showErrorToast('Please provide Active from Date');   
            this.isloading = false; 
        }else{
            fields.ParentId = this.accountId;
            fields.Street = this.cpastreet;
            fields.City = this.cpacity;
            fields.Country = this.cpacountry;
            fields.State = this.cpaprovince;
            fields.PostalCode = this.cpapostalcode;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
        
        }else{
            if(this.objecttype == 'HealthCloudGA__EhrEncounter__c'){
                event.preventDefault(); 
                const fields = event.detail.fields;
                fields.Record__c = this.recordId ;
                this.template.querySelector('lightning-record-form').submit(fields);
            }
        }
     }

    handleerror(){
        this.isloading = false;
        this.showErrorToast('Something went wrong!');
    }

    handleRefresh(){
        this.isloading = true;
        this.fetchaddressvalues();
    }

        /****************************************************/
    /* Function to handle SUCCESS Toast message */
    /****************************************************/
    showSuccessToast(successmessage) {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: successmessage,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    /****************************************************/
    /* Function to handle WARNING Toast message */
    /****************************************************/
    showWarningToast(warningMessage) {
        const evt = new ShowToastEvent({
            title: 'ERROR',
            message: warningMessage,
            variant: 'warning',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    /****************************************************/
    /* Function to handle Info Toast message */
    /****************************************************/
    showInfoToast() {
        const evt = new ShowToastEvent({
            title: 'Toast Info',
            message: 'Operation will run in background',
            variant: 'info',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
     /****************************************************/
    /* Function to handle ERROR Toast */
    /****************************************************/
    showErrorToast(errorMessage) {
        const evt = new ShowToastEvent({
            title: 'Address Error',
            message: errorMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    

}