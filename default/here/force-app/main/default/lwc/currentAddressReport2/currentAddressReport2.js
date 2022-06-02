/*
 * @Author             : Sai Kallu
 * @Description        : Lightning Report to display the Current Address from LWC(Current Address)
 * @Modification Log   : 
 * --------------------------------------------------------------------------------------
 * Date           Author      		    Details
 * --------------------------------------------------------------------------------------
 * 03/11/2021     Sai Kallu        Feature 308700 : New LWC Component to show current address on report(LWC)
   08/12/2021     Sai Kallu        Feature 341410 : Enhancement to Custom Current Address Report for HEP  
*/


import { LightningElement,api,wire,track } from 'lwc';
import getRecordList from '@salesforce/apex/currentAddressReportController.getRecordList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
{ label: 'Record Number', fieldName: 'RecordURL', type: 'url',sortable: true,
typeAttributes: {label: { fieldName: 'RecordNumber' }, target: '_blank'}},
{
    label: 'Account Name',
    fieldName: 'AccountURL',
    type: 'string',
    sortable: false,
    cellAttributes: { alignment: 'left' },
    type: 'url',
    typeAttributes: {label: { fieldName: 'AccountName' }, target:'_blank'}
},
{ label: 'First Name', fieldName: 'FirstName', type: 'string' },
{ label: 'Last Name', fieldName: 'LastName', type: 'string' },
{ label: 'Record Type', fieldName: 'RecordRecordType', type: 'string' },
{ label: 'Status', fieldName: 'Status', type: 'string' },
{ label: 'Record Owner', fieldName: 'RecordOwner', type: 'string' },
{ label: 'Birthdate', fieldName: 'Birthdate', type: 'string' },
{ label: 'Calculated Onset Date', fieldName: 'CalculatedOnsetDate', type: 'string', sortable: true },
{ label: 'Current Address Line 1', fieldName: 'CurrentAddressLine1', type: 'string' },
{ label: 'Current Address Line 2', fieldName: 'CurrentAddressLine2', type: 'string' },
{ label: 'Current Suburb', fieldName: 'CurrentSuburb', type: 'string' },
{ label: 'Current Post Code', fieldName: 'CurrentPostCode', type: 'string' }
];

export default class CurrentAddressReport2 extends LightningElement {
@track data = [] ;
columns = columns;
defaultSortDirection = 'asc';
sortDirection = 'asc';
sortedBy;
@api NumberOfDays = '7';
librariesLoaded = false;
maxRows=1000;
tableElement;
@track totalRecords;
loadMoreStatus;
@api totalNumberOfRows;
@api recordtype = 'Confirmed Case';
isLoaded;
areDetailsVisible;
@api start_date;
@api end_date;

// Used to sort the 'Record Number' column	
sortBy(field, reverse, primer) {	
    const key = primer	
        ? function (x) {	
                return primer(x[field]);	
            }	
        : function (x) {	
                return x[field];	
            };	
    return function (a, b) {	
        a = key(a);	
        b = key(b);	
        return reverse * ((a > b) - (b > a));	
    };	
}

onHandleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.data];
    cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
    this.data = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
}

isLoaded = true;
connectedCallback() {
    var today = new Date();
    //var date = new Date();
    today.setHours(today.getHours() + 11);
    this.end_date = today.toISOString();
    today.setDate(today.getDate() - 14);
    this.start_date = today.toISOString().split('T')[0];
    this.isLoaded = true;
    this.updateTheRecordList();  
}

//Connected callback will run when the component is initialized
updateTheRecordList(){
    
    getRecordList({NumberOfDays : this.NumberOfDays,recordType : this.recordtype, startDate : this.start_date, endDate : this.end_date})
        .then(result => {
            if(result){
                this.data = result ;
                this.totalRecords = result.length;
                this.isLoaded = false;
                if(result.length > 0){
                    this.areDetailsVisible = true;
                }
                else{
                    this.areDetailsVisible = false;
                }
               
            }
            else{
                this.showToast('Error','error','There is an error');
                this.areDetailsVisible = false;
                
            }
        })
        .catch(error => {
            console.log('Error: ', error);
            this.isLoaded = false;
            this.showToast('Error','error','Too many records. Please check the Date range');
            
            
        })
        
}

// this method validates the data and creates the csv file to download
downloadCSVFile() { 

    let rowEnd = '\n';
    let csvString = '';
    // this set elminates the duplicates if have any duplicate keys
    let rowData = new Set();

    // getting keys from data
    this.data.forEach(function (record) {
        Object.keys(record).forEach(function (key) {
            rowData.add(key);
        });
    });

    // Array.from() method returns an Array object from any object with a length property or an iterable object.
    rowData = Array.from(rowData);
    
    // splitting using ','
    csvString += rowData.join(',');
    csvString += rowEnd;

    // main for loop to get the data based on key value
    for(let i=0; i < this.data.length; i++){
        let colValue = 0;

        // validating keys in data
        for(let key in rowData) {
            if(rowData.hasOwnProperty(key)) {
                // Key value 
                // Ex: Id, Name
                let rowKey = rowData[key];
                // add , after every value except the first.
                if(colValue > 0){
                    csvString += ',';
                }
                // If the column is undefined, it as blank in the CSV file.
                let value = this.data[i][rowKey] === undefined ? '' : this.data[i][rowKey];
                csvString += '"'+ value +'"';
                colValue++;
            }
        }
        csvString += rowEnd;
    }

    var today = new Date();
    var date = today.getFullYear()+'-'+(today.getMonth()+1)+'-'+today.getDate();
    // Creating anchor element to download
    let downloadElement = document.createElement('a');

    // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
    downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
    downloadElement.target = '_self';
    // CSV File Name
    downloadElement.download = today + ' Current Address Report.csv';
    // below statement is required if you are using firefox browser
    document.body.appendChild(downloadElement);
    // click() Javascript function to download CSV file
    downloadElement.click(); 
}

showToast(title, variant, message) {
    const event = new ShowToastEvent({
        variant: variant,
        title: title,
        message: message,
    });
    this.dispatchEvent(event);
}

handleSelect(evt)
    {
        this.recordtype = evt.target.value;
        this.isLoaded = true;
        this.updateTheRecordList(); 
       
    }

    handleDateChange = (evt) => {
        let field_name = evt.target.name;
        if(field_name === 'startdate')
            this.start_date = evt.target.value; 
        if(field_name === 'enddate')
            this.end_date = evt.target.value; 
        if(this.end_date != null && this.start_date !=null){
            if(this.end_date < this.start_date){
                this.showToast('Error','error','End Date cannot be less than Start Date');
            }
    else{
        this.isLoaded = true;
        this.updateTheRecordList();
        }
    }
        
    }
    
    
}