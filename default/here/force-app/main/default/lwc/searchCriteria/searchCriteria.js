import { LightningElement,track, api } from 'lwc';

export default class SearchCriteria extends LightningElement {

    @api searchType;
    recordNumber;
    firstName;
    middlename;
    lastName;
    dateOfBirth;
    mobile;
    homePhone;
    email;
    @api selectedrecordTypes;
    

    handleSearch() {
        console.log('firing search Event');
        const searchEvent = new CustomEvent("search", { detail: { recordNumber: this.recordNumber, firstName: this.firstName, middleName: this.middleName,lastName: this.lastName, dateOfBirth: this.dateOfBirth, mobile:this.mobile,homePhone: this.homePhone,email: this.email,selectedrecordTypes: this.selectedrecordTypes } });
        this.dispatchEvent(searchEvent);
    }

    handleClear(){
        this.recordNumber = '';
        this.firstName  = '';
        this.lastName  = '';
        this.middleName ='';
        this.dateOfBirth = '';
        this.mobile = '';
        this.homePhone ='';
        this.email ='';

        let multiSelectPicklist = this.template.querySelector('c-multi-select-pick-list');
        if (multiSelectPicklist) {
            multiSelectPicklist.clear();
        }
        
        const clearEvent = new CustomEvent("clearsearch");
        this.dispatchEvent(clearEvent);
    }

    handleChange(event) {
        const field = event.target.name;

        if (field === 'recordNumber') {
            this.recordNumber = event.target.value;
        }
        else if (field === 'firstName') {
            this.firstName = event.target.value;
        }
        else if (field === 'middleName') {
            this.middleName = event.target.value;
        }
        else if (field === 'lastName') {
            this.lastName = event.target.value;
        }
        else if (field === 'dateOfBirth') {
            this.dateOfBirth = event.target.value;
        }
        else if (field === 'mobile') {
            this.mobile = event.target.value;
        }
        else if (field === 'homePhone') {
            this.homePhone = event.target.value;
        }
        else if (field === 'email') {
            this.email = event.target.value;
        }
    }

    handleValueChange(event){
        console.log(JSON.stringify(event.detail));
        this.selectedrecordTypes = JSON.stringify(event.detail);
        console.log(this.selectedrecordTypes);
    }

    get options() {
        return [
            { label: 'COVID-19 Case Assessment', value: 'COVID_19_Case_Assessment' },
            { label: 'Close Contact', value: 'Close_Contact' },
            { label: 'Secondary Close Contact', value: 'Secondary_Close_Contact' },
            { label: 'Casual Contact', value: 'Casual_Contact' },
            { label: 'COVID-19 Case Screening', value: 'COVID_19_Case_Screening' },
        ];
    }

   
}