/*
 * @Author             : Jiten Joysar
 * @Description        : DHHS Calendar Component to display and select dates for PCC
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 09/12/2020     Jiten Joysar          DHHS_pccCalendar : Initial version
 * 12/03/2021     YPerera               PBI259628 - Potentially Infectious period for PCC
*/

import { LightningElement,api,wire, track } from 'lwc';
import MOMENT from '@salesforce/resourceUrl/momentJS';
import {loadScript} from 'lightning/platformResourceLoader' ; // to load momemt Js
// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService'; 
import DATESELECTEDMC from '@salesforce/messageChannel/Date_Selected__c'; // Message Service to publish an event

// Case fields to retrive
const FIELDS = ['Case.Day_0_Exposure_to_the_confirmed_case__c',
                'Case.Day_11_Test__c',
                'Case.Day14_Anticipated_last_day_of_quarantine__c',
								'Case.First_date_of_exposure_to_positive_case__c'
                ];

var interval0=[]; //first exposure date
//var interval1=[];  // first 48 hours since PCC exposure
var interval2=[];  // Potentially Infectious Period

export default class Dhhs_pccCalendar extends LightningElement {

    @api recordId;
    @wire(MessageContext)
    messageContext;
    @track selectedDateToPass;

    isLibLoaded = false;
    dateContext; // variable to capture the Date
    selectedDate;
    today;
		@track fde; //first day of exposure
    @track day0; // Day0 field
    @track day11; // Day 11 field 
    @track day14; // Day 14 field 
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
    /* Wired Function to get Record (Case object) */
    /****************************************************/
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    getRecord({error,data})
    {
        if (data) {
            loadScript(this, MOMENT+'/moment.min.js').then(()=>{
                this.dateContext = moment();
                this.today=moment();
								this.fde = data.fields.First_date_of_exposure_to_positive_case__c.displayValue;
                this.day0 = data.fields.Day_0_Exposure_to_the_confirmed_case__c.displayValue;
                this.day11 = data.fields.Day_11_Test__c.displayValue;
                this.day14 = data.fields.Day14_Anticipated_last_day_of_quarantine__c.displayValue;

								var day14moment = moment(data.fields.Day14_Anticipated_last_day_of_quarantine__c.displayValue, "DD-MM-YYYY");

                var basedate;
                if (this.today.diff(day14moment, 'days') > 0) {
                    basedate = day14moment; //Day 14 is in the past
                } else {
                    basedate = this.today;
                }
                var potentiallyInfectiousDays = (moment(basedate, "DD-MM-YYYY")-moment(data.fields.First_date_of_exposure_to_positive_case__c.displayValue, "DD-MM-YYYY"))/8.64e7;

                //var potentiallyInfectiousDays = (moment(moment(), "DD-MM-YYYY")-moment(data.fields.First_date_of_exposure_to_positive_case__c.displayValue, "DD-MM-YYYY"))/8.64e7;
                this.setIntervals( new moment((moment(data.fields.First_date_of_exposure_to_positive_case__c.displayValue, "DD-MM-YYYY")).toISOString()), potentiallyInfectiousDays);
                //this.day0 = moment(data.fields.Day_0_Exposure_to_the_confirmed_case__c.displayValue, "DD-MM-YYYY");
                //this.day11 = moment(data.fields.Day_11_Test__c.displayValue, "DD-MM-YYYY");
                //this.day14 = moment(data.fields.Day14_Anticipated_last_day_of_quarantine__c.displayValue, "DD-MM-YYYY");

                /*
                this.symptomOnsetDate = data.fields.Calculated_Onset_Date__c.displayValue;
                this.isolationDate = data.fields.Home_isolation_date_Commenced__c.displayValue;
                this.firstTestDate = data.fields.Date_of_Test__c.displayValue;
                // Determine Infectious Period
                var infectiousPeriodDays;
                if(data.fields.Clearance_eligibility_assessment_date__c.displayValue){
                    infectiousPeriodDays = (moment(data.fields.Clearance_eligibility_assessment_date__c.displayValue, "DD-MM-YYYY")-moment(data.fields.Calculated_Onset_Date__c.displayValue, "DD-MM-YYYY"))/8.64e7;
                }
                else{
                    infectiousPeriodDays = (moment(moment(), "DD-MM-YYYY")-moment(data.fields.Calculated_Onset_Date__c.displayValue, "DD-MM-YYYY"))/8.64e7;
                }
                
                */
                this.refreshDateNodes();
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
    setIntervals(startdate, noOfDays){

				interval0[0]=startdate.clone();
				interval0[0].add(0, 'days');

				//interval1[0]=startdate.clone();
				//interval1[0].add(1,'days');

        // First 48 hours since PCC exposure
        /*for (let i=0; i<2; i++){
           interval1[i]=startdate.clone();
           interval1[i].add(i,'days');
        }*/
       
        // Potentially Infectious Period
        for (let i=0; i < (noOfDays-1); i++){
            interval2[i]=startdate.clone();
            interval2[i].add(i+1,'days');
        }
    }

		isInInterval0(date){
        var toret = false;
        interval0.forEach((element)=>{

        if(element.isSame(date,'day')){
            toret=true;
            return;
        }
        })
        return toret;
    }

    /*isInInterval1(date){
        var toret = false;
        interval1.forEach((element)=>{

        if(element.isSame(date,'day')){
            toret=true;
            return;
        }
        })
        return toret;
    }*/

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

                        // Potentially Infectious Period
                        else if (this.isInInterval2(day)) {
                            className = 'interval2';
                        }
                        // First 48 hours since PCC exposure
                        /*else if (this.isInInterval1(day)) {
                            className = 'interval1';
                        }*/
												// First exposure date
												else if (this.isInInterval0(day)) {
                            className = 'interval0';
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
            title: 'PCC CALENDAR COMPONENT ERROR',
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