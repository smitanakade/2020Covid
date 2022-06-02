import { LightningElement, track, api } from "lwc";
import search from "@salesforce/apex/AdvancedSearchService.search";
import searchResultWarning from '@salesforce/label/c.Exposure_Search_Max_Records_Warning';
const REC_LIMIT = 100;

export default class SearchResult extends LightningElement {

  @api searchType;
  @track records = [];
  @track selectedRecordId;
  refineSearchMsg = false;
  label = {searchResultWarning};
  recordLimit = REC_LIMIT;
  isLoading = false;

 //  316828
 @api search(recordNumber, firstName,middleName, lastName, dateOfBirth, mobile,homePhone, email,selectedrecordTypes) {
    this.isLoading = true;
    const criteria = {recordNumber: recordNumber,
      firstName: firstName,
      middleName: middleName,  // 316828
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      mobile: mobile , 
      homePhone: homePhone, // 316828
      email: email, //  316828
      selectedrecordTypes: selectedrecordTypes  // 316828
    }; 

    search({payload: JSON.stringify(criteria),recLimit:REC_LIMIT,searchType:this.searchType})
      .then((result) => {

        let resultArray = [...result];
        if(resultArray.length>REC_LIMIT){
          this.refineSearchMsg = true;
          //to remove last record as the query is limited to 101 to find if more than 100 record exists
          resultArray.pop();
        }else{
          this.refineSearchMsg = false;
        }

        this.records = resultArray.map((record) => {
            
            let formattedEventDate = '';
            let formattedBirthDate = '';

            if(record.Event_Date__c){
            let eventDate = new Date(record.Event_Date__c);
            formattedEventDate = eventDate.toLocaleString("en-GB", {
                year: "numeric",
                month: "2-digit",
                day: "2-digit",
                timeZone: "Australia/Sydney"
              });
            }
            if(record.Account.PersonBirthdate){
            let birthDate = new Date(record.Account.PersonBirthdate);
            formattedBirthDate = birthDate.toLocaleString("en-AU", {
              year: "numeric",
              month: "2-digit",
              day: "2-digit",
              hour12: true,
              timeZone: "Australia/Sydney"
            });
            }
            return {
          ...record,          
          caseLink: `/lightning/r/Case/${record.Id}/view`,
          accountLink: `/lightning/r/Account/${record.AccountId}/view`,
          EHRLink:`/lightning/r/HealthCloudGA__EhrObservation__c/${record.Latest_EHR_Observation__c}/view`,
          formattedEventDate: formattedEventDate,
          formattedBirthDate: formattedBirthDate
        }});
        console.log(JSON.stringify(this.records));
        this.error = undefined;
        this.isLoading = false;
      })
      .catch((error) => {
        this.error = error;
        console.log(JSON.stringify(this.error));
        this.records = undefined;
        this.isLoading = false;
      });

  }

  @api clearSearch() {
    this.records = [];
    this.refineSearchMsg = false;
  }


  updateSelectedCard(event) {
    if (this.selectedRecordId != event.detail.recId) {
      this.selectedRecordId = event.detail.recId;
    } else {
      this.selectedRecordId = undefined;
    }
  }

  get recordExists() {
    return this.records.length > 0;
  }
}