import { LightningElement,track,wire,api } from 'lwc';
import getCases                 from '@salesforce/apex/DHHS_CEPCaseListSmallController.getCases';
import getCasesbyrecordnumber   from '@salesforce/apex/DHHS_CEPCaseListSmallController.getCasesbyRecordNumber';

const caseColumns = [ 
    { label: 'Case Type', fieldName: 'RecordTypeName', type: 'text'}, 
    { label: 'CaseNumber', fieldName: 'CaseNumber', type: 'text'},
    { label: 'Status', fieldName: 'Status', type: 'text'}, 
    { label: 'Day 0', fieldName: 'Day_0_Calculated__c', type: 'text'}
];

export default class Dhhs_CEPCaseListSmall extends LightningElement {
    @track cases;
    @track error; 
    @track caseColumns = caseColumns;
    @track accountIdFromEvent;
    @api showcaselist;
    @track selectedRows;
    @track preSelectedRows = [];
   // @api personIdSelected;

   getSelectedRecord(event) {
       //debugger;
        this.selectedRows = event.detail.selectedRows;
        if(this.selectedRows[0] && this.selectedRows[0].CaseId){
            this.preSelectedRows = [this.selectedRows[0].Id];
            var selectedCase = new CustomEvent(
                "selectcase",
                {
                    detail : this.selectedRows[0].CaseId
                }
            );
            this.dispatchEvent(selectedCase);
        }
    }

    //String accountId, string customSettingDevName

    @api
    getRelatedCases(accountId)
    {   
        this.selectedRows = undefined;
        this.preSelectedRows = [];
        if ( accountId ) { 
            getCases( { accountId : accountId, customSettingDevName : 'Default' } )   
            .then(result => { 
                console.log(JSON.stringify(result, null, '\t'));
                if (result) {
                    let preparedCases = [];
                    result.forEach(caseObj => {
                        let preparedCase = {};
                        preparedCase.RecordTypeName = caseObj.RecordType.Name;
                        preparedCase.CaseNumber = caseObj.CaseNumber;
                        preparedCase.CaseId = caseObj.Id;
                        preparedCase.Status = caseObj.Status;
                        preparedCase.Day_0_Calculated__c = caseObj.Day_0_Calculated__c;

                        preparedCases.push(preparedCase);
                    });
                    this.cases = preparedCases;
                }
                if (result.error) {
                    this.error = result.error;
                }

                console.log('Flattened : \t' + JSON.stringify(this.cases, null, '\t'));
   
            }) 
            .catch(error => { 
                this.error = error; 
            }); 
        } else 
            this.cases = undefined; 
        // debugger;
        // if (Object.entries(this.cases).length === 0)
        //     return 'false';
        // else 
        //if (Object.keys(this.cases).length === 0 && this.cases.constructor === Object)
            //return 'DONE';
        // else 
        //     return 'false';
    }

    //327529 - shortform enhancement search by record number
    @api
    getRecord(recordNumber)
    {   
        this.selectedRows = undefined;
        this.preSelectedRows = [];
        if ( recordNumber ) { 
            getCasesbyrecordnumber( { recordNumber : recordNumber } )   
            .then(result => { 
                console.log(JSON.stringify(result, null, '\t'));
                if (result) {
                    let preparedCases = [];
                    result.forEach(caseObj => {
                        let preparedCase = {};
                        preparedCase.RecordTypeName = caseObj.RecordType.Name;
                        preparedCase.CaseNumber = caseObj.CaseNumber;
                        preparedCase.CaseId = caseObj.Id;
                        preparedCase.Status = caseObj.Status;
                        preparedCase.Day_0_Calculated__c = caseObj.Day_0_Calculated__c;

                        preparedCases.push(preparedCase);
                    });
                    this.cases = preparedCases;
                }
                if (result.error) {
                    this.error = result.error;
                }

                console.log('Flattened : \t' + JSON.stringify(this.cases, null, '\t'));
   
            }) 
            .catch(error => { 
                this.error = error; 
            }); 
        } else 
            this.cases = undefined; 
      
    }
   
    // handleKeyChange( event ) { 
    //     //const strLastName = event.target.value; 
    //     const accountId = '0012O000008zjoMQAQ';
    //     if ( accountId ) { 
    //         getCases( { accountId } )   
    //         .then(result => { 
    //             console.log(JSON.stringify(result, null, '\t'));
    //             if (result) {
    //                 let preparedCases = [];
    //                 result.forEach(caseObj => {
    //                     let preparedCase = {};
    //                     preparedCase.RecordTypeName = caseObj.RecordType.Name;
    //                     preparedCase.CaseNumber = caseObj.CaseNumber;
    //                     preparedCases.push(preparedCase);
    //                 });
    //                 this.cases = preparedCases;
    //             }
    //             if (result.error) {
    //                 this.error = result.error;
    //             }

                
    //             console.log('Flattened : \t' + JSON.stringify(this.cases, null, '\t'));

   
    //         }) 
    //         .catch(error => { 
    //             this.error = error; 
    //         }); 
    //     } else 
    //     this.cases = undefined; 
    // }

    
}