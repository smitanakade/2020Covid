/*
 * @Author             : Jiten Joysar
 * @Description        : DHHS Calendar Component to display and select dates
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 08/11/2020     Jiten Joysar          DHHS_Calendar : Initial version
 * 04/03/2020     Jiten Joysar          Added logic for PBI 260447
 * 08/12/2021     Sai Kallu             Added logic for PBI 340986
*/

import { LightningElement,api,wire, track } from 'lwc';
import MOMENT from '@salesforce/resourceUrl/momentJS';
import {loadScript} from 'lightning/platformResourceLoader' ; // to load momemt Js
// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService'; 
import DATESELECTEDMC from '@salesforce/messageChannel/Date_Selected__c'; // Message Service to publish an event
// importing to get the object info 
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
// importing Case shcema
import CASE_OBJECT from '@salesforce/schema/Case';
// Case fields to retrive
const FIELDS = ['Case.Calculated_Onset_Date__c',
                'Case.Home_isolation_date_Commenced__c',
                'Case.Date_of_Test__c',
                'Case.Clearance_eligibility_assessment_date__c',
                'Case.RecordTypeId',
                'Case.Asymptomatic__c','Case.HC_Symptom_Onset_Date__c'
                ];

var interval1=[];  // Acquisition Peiod
var interval2=[];  // Overlap Period
var interval3=[];  // Infectious Period

export default class Dhhs_calendar extends LightningElement {

    @api recordId;
    @wire(MessageContext)
    messageContext;
		@api hidemessage = false;
    @track symptomOnsetDate;
    @track isolationDate;
    @track firstTestDate;
    @track selectedDateToPass;
    
    rtValues; // case recordType
    isPCCRecordType ; // Boolean value to check Primary close contact 
    loadCalendar = false;
    isLibLoaded = false;
    dateContext; // variable to capture the Date
    selectedDate;
    today;
    day0; // Day0 field is used to do calcalation
    control = {isReady:"test"};

    connectedCallback () {
        var targetProxy = new Proxy(this.control, {
            set: function (target, key, value) {
                console.log(`${key} set to ${value}`);
                target[key] = value;
                return true;
            }
        });
    }
    
    
    /****************************************************/
    /* Wired Function to get object info (Case object) */
    /****************************************************/
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseObjectInfo({data, error}) {
        if(data) {
            
            const rtInfos = data.recordTypeInfos;
            // getting map values
            this.rtValues = Object.values(rtInfos);
        }
        else if(error) {
            window.console.log('Error ===> '+JSON.stringify(error));
        }
    }

    /****************************************************/
    /* Wired Function to get Record (Case object) */
    /****************************************************/
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    getRecord({error,data})
    {
        if (data) {
            loadScript(this, MOMENT+'/moment.min.js').then(()=>{

                // check for Primary Close contact Record Type 
                console.log('data.fields.RecordTypeId --> '+ JSON.stringify(data.fields.RecordTypeId));
                for(let i = 0; i < this.rtValues.length; i++) {
                    if(this.rtValues[i].recordTypeId === data.fields.RecordTypeId.value && 
                        this.rtValues[i].name === 'Close Contact') {
                        this.isPCCRecordType = true;
                    }
                }
                // check for PCC recordtype
                if(!this.isPCCRecordType){
                    this.loadCalendar = true;
                    this.dateContext = moment();
                    this.today=moment();
                    this.day0 = moment(data.fields.Calculated_Onset_Date__c.displayValue, "DD-MM-YYYY");
                    this.symptomOnsetDate = data.fields.HC_Symptom_Onset_Date__c.displayValue;//340986
                    this.isolationDate = data.fields.Home_isolation_date_Commenced__c.displayValue;
                    this.firstTestDate = data.fields.Date_of_Test__c.displayValue;
                    this.calculatedOnsetDate = data.fields.Calculated_Onset_Date__c.displayValue; // PBI-321022
                    this.asymptomatic = data.fields.Asymptomatic__c.value == true ? 'Yes' : 'No';  // PBI-321022
                    // Calculate overlapping period
                    var overlapPeriodDays
                    // Check if first Test date is before (calculated onset date - 2)
                    if(this.firstTestDate && moment(this.firstTestDate, "DD-MM-YYYY") < (moment(data.fields.Calculated_Onset_Date__c.displayValue, "DD-MM-YYYY").subtract(2, 'day'))){
                        // Added logic for PBI 260447
                        overlapPeriodDays = ((moment(data.fields.Calculated_Onset_Date__c.displayValue, "DD-MM-YYYY") - moment(this.firstTestDate, "DD-MM-YYYY"))/8.64e7)+2;
                    }
                    // If first Test date is not before (calculated onset date - 2) then set overlap days to two days
                    else{
                        overlapPeriodDays = 2;
                    }
                    
                    // Determine Infectious Period
                    var infectiousPeriodDays;
                    if(data.fields.Clearance_eligibility_assessment_date__c.displayValue){
                        infectiousPeriodDays = (moment(data.fields.Clearance_eligibility_assessment_date__c.displayValue, "DD-MM-YYYY")-moment(data.fields.Calculated_Onset_Date__c.displayValue, "DD-MM-YYYY"))/8.64e7;
                    }
                    else{
                        infectiousPeriodDays = (moment(moment(), "DD-MM-YYYY")-moment(data.fields.Calculated_Onset_Date__c.displayValue, "DD-MM-YYYY"))/8.64e7;
                    }
                    this.setIntervals( new moment(this.day0.toISOString()),infectiousPeriodDays, overlapPeriodDays);
                    this.refreshDateNodes();
                }
                
            }).catch(error=>{
                console.error(error);
                this.showErrorToast(error.body.message);
            }).finally(()=>{
                this.isLibLoaded = true;
            })
        } else if (error) {
            this.error = error;
            this.showErrorToast(error.body.message);
        }
    }

    get formattedSelectedDate() {
        return this.isLibLoaded? this.dateContext.format('YYYY-MM-DD'):''
    }

    get year() {
        return this.isLibLoaded? this.dateContext.format('Y'):''
    }

    get month() {
        return this.isLibLoaded? this.dateContext.format('MMMM'):''
    }

    previousMonth() {
        this.dateContext = moment(this.dateContext).subtract(1, 'month');
        this.refreshDateNodes();
    }

    nextMonth() {
        this.dateContext = moment(this.dateContext).add(1, 'month');
        this.refreshDateNodes();
    }

    goToday() {
        this.selectedDate = this.today;
        this.dateContext = this.today;
        this.refreshDateNodes();
    }

    
    /****************************************************/
    /* Function to handle Date selection event */
    /****************************************************/
    @api
    setSelected(e) {
        const selectedDate = this.template.querySelector('.selected');
        if (selectedDate) {
            selectedDate.className = this.lastClass;
        }
        // use destructuring to get e.target.dataset.date
        const {date} = e.target.dataset;
        if(date === this.selectedDateToPass){
            e.target.className = this.lastClass;
            this.selectedDateToPass = undefined;
            const message = {
                date: ''
            };
            publish(this.messageContext, DATESELECTEDMC, message);
        }else{
            this.selectedDate = moment(date);
            this.dateContext = moment(date);
            this.lastClass = e.target.className;
            this.selectedDateToPass = date;
            e.target.className =  'selected '+e.target.className;
            const message = {
                date: moment(date).toISOString()
            };
            publish(this.messageContext, DATESELECTEDMC, message);
        }
    }

    /****************************************************/
    /* Set the time interval for Acquisition Peiod, 
        Overlap Period and Infectious Period */
    /****************************************************/
    setIntervals(startdate, noOfDays, noOfOverlapDays){

        // Acquisition Peiod 
        for (let i=0; i<14; i++){
           interval1[i]=startdate.clone();
           interval1[i].add(i-14,'days');
        }
        
        // Overlap Period
        for (let i=0; i<noOfOverlapDays; i++){
            interval2[i]=startdate.clone();
            interval2[i].add(i-noOfOverlapDays,'days');
        }

        // Infectious Period
        for (let i=0; i < (noOfDays); i++){
            interval3[i]=startdate.clone();
            interval3[i].add(i,'days');
        }
    }

    isInInterval1(date){
        var toret = false;
        interval1.forEach((element)=>{

        if(element.isSame(date,'day')){
            toret=true;
            return;
        }
        })
        return toret;
    }

    isInInterval2(date){
        var toret = false;
        interval2.forEach((element)=>{

            if(element.isSame(date,'day')){
                toret=true;
                return;
            }
        })
        return toret;
    }

    isInInterval3(date){
        var toret = false;
        interval3.forEach((element)=>{

        if(element.isSame(date,'day')){
            toret=true;
            return;
        }
        })

        return toret;
    }
    
    
    /********************************************************/
    /* Function to Refresh the Date Nodes after each event */
    /********************************************************/
    refreshDateNodes() {

        // reset dates variable
        this.dates = [];
        const currentMoment = moment(this.dateContext);
        
        // startOf mutates moment, hence clone before use
        const start = this.dateContext.clone().startOf('month');
        
        // check for the total weeks value which is rounded to 53 weeks
        let startWeek;
        if(start.week() === 53){
            startWeek = 1;
        }
        else{
            startWeek = start.week();
        }
        
        // months do not always have the same number of weeks. eg. February
        const numWeeks = moment.duration(currentMoment.endOf('month') - start).weeks() + 1;

        // iterate over the weeks
        for (let week = startWeek; week <= startWeek + numWeeks; week++) {
            Array(7)
                .fill(0)
                .forEach((n, i) => {

                    const currentMomentForDayCalculation = moment(this.dateContext);
                    const day = currentMomentForDayCalculation
                        .week(week)
                        .startOf('week')
                        .clone()
                        .add(n + i, 'day');   
                    let className = '';
                    if (day.month() === this.dateContext.month()) {
                        if (day.isSame(this.today, 'day')) {
                            className = 'today';
                        } else if (day.isSame(this.selectedDate, 'day')) {
                            className = 'selected';
                        } 
                        /* removing Symptom Onset date
                        else if (day.isSame(this.day0, 'day')) {
                            className = 'day0';
                        } */
                        else if (this.isInInterval2(day)) {
                            className = 'interval2';
                        }
                        else if (this.isInInterval1(day)) {
                            className = 'interval1';
                        }
                        else if (this.isInInterval3(day)) {
                            className = 'interval3';
                        }
                        else {
                            className = 'date';
                        }
                    } else {
                        className = 'padder';
                    }
                    this.dates.push({
                        className,
                        formatted: day.format('YYYY-MM-DD'),
                        text: day.format('DD')
                    });
                }
                );
        }
    }

    /****************************************************/
    /* Function to handle ERROR Toast */
    /****************************************************/
    showErrorToast(errorMessage) {
        const evt = new ShowToastEvent({
            title: 'CALENDAR COMPONENT ERROR',
            message: 'Some unexpected error, '+errorMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    /****************************************************/
    /* Function to handle SUCCESS Toast message */
    /****************************************************/
    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Toast Success',
            message: 'Operation sucessful',
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
}