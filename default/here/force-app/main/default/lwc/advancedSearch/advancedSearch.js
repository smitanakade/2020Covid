import { LightningElement, api } from 'lwc';

export default class AdvancedSearch extends LightningElement {

    //Default search type has been set as Individual. Different search type can be passed from calling component
    @api searchType = 'Individual';

   search(event) {
        const recordNumber = event.detail.recordNumber;
        const firstName = event.detail.firstName;
        const middleName = event.detail.middleName; //  316878
        const lastName = event.detail.lastName;
        const dateOfBirth = event.detail.dateOfBirth;
        const mobile = event.detail.mobile;
        const homePhone = event.detail.homePhone; //  316878
        const email = event.detail.email; // 316878
        const selectedrecordTypes = event.detail.selectedrecordTypes; //  316878
        this.template.querySelector("c-search-result").search(recordNumber,firstName,middleName,lastName,dateOfBirth,mobile,homePhone,email,selectedrecordTypes);
        
    }

    clearSearch(event) {
        this.template.querySelector("c-search-result").clearSearch();
    }
}