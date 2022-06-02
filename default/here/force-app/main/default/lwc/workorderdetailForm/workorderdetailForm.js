/*
 * @Author             : Hemant Singh
 * @Description        : This is designed to be placed on a Work Order Confirmed Case flexipage
 *                       The goal is to show/update key information of the Work order and  related Person account
 *                       
 * @Modification Log   : 
 * --------------------------------------------------------------------------------------
 * Date           Author      		    Details
 * --------------------------------------------------------------------------------------
 * 06/09/2021     Hemant Singh       Initial version
*/

import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import DOB_FIELD from '@salesforce/schema/Account.PersonBirthdate';
import SEX_FIELD from '@salesforce/schema/Account.Sex__c';
import ACCOMMODATION_TYPE_FIELD from '@salesforce/schema/Account.Accommodation_type__c';
import IF_OTHER_SPECIFY_FIELD from '@salesforce/schema/Account.if_Other_Specifiy__c';
import MAILING_ADDRESS_FIELD from '@salesforce/schema/Account.PersonMailingAddress';
import MOBILE_FIELD from '@salesforce/schema/Account.PersonMobilePhone';
import EMAIL_FIELD from '@salesforce/schema/Account.PersonEmail';
import NAME_OF_PARENT_FIELD from '@salesforce/schema/Account.Name_of_Parent__c';
import ATSI_FIELD from '@salesforce/schema/Account.Aboriginal_or_Torres_Strait_Islander__c';
import SUP_OFFICER_FIELD from '@salesforce/schema/Account.Cultural_Support_Officer_Required__c';
import COUNTRY_OF_BIRTH_FIELD from '@salesforce/schema/Account.Country_of_birth__c';
import LANGUAGE_SPOKEN_FIELD from '@salesforce/schema/Account.Language_spoken_at_home__c';
import INTERPRETER_REQUIRED_FIELD from '@salesforce/schema/Account.Interpreter_required__c';
import TRANSLATED_DOCUMENTS_FIELD from '@salesforce/schema/Account.Translated_documents_required__c';
import DOCUMENTS_LANGUAGE_FIELD from '@salesforce/schema/Account.Document_Language__c';
import ADDRESS_READONLY_FIELD from '@salesforce/schema/Account.Residential_Address__c';
import ACCOUNT_ID_FIELD from '@salesforce/schema/WorkOrder.AccountId';

import PERSON_INTERVIEWD_FIELD from '@salesforce/schema/WorkOrder.Person_Interviewed__c';
import INTERVIEWED_BY_FIELD from '@salesforce/schema/WorkOrder.Interviewed_By__c';
import DATE_OF_INTERVIEW_FIELD from '@salesforce/schema/WorkOrder.Date_of_Interview__c';
import WO_NUMBER_FIELD from '@salesforce/schema/WorkOrder.WorkOrderNumber';
import OWNERS_TEAM_FIELD from '@salesforce/schema/WorkOrder.Owner_s_Team__c';
import CREATED_BY_FIELD from '@salesforce/schema/WorkOrder.CreatedById';
import LAST_MODIFIED_BY_FIELD from '@salesforce/schema/WorkOrder.LastModifiedById';
import PRIORITY_FIELD from '@salesforce/schema/WorkOrder.Priority';
import MANUALLY_ALLOCATED_FIELD from '@salesforce/schema/WorkOrder.Manually_Allocated__c';
import ESCALATION_REASON_FIELD from '@salesforce/schema/WorkOrder.Escalation_reason__c';
import CULTURAL_IDENTITY_FIELD from '@salesforce/schema/Account.Cultural_Identity__c';
//import ADDRESS_LABEL from '@salesforce/label/c.Work_Order_Address_Text';

import UPDATEINTERVIEW from '@salesforce/messageChannel/ShortFormInterview__c';

export default class WorkorderdetailForm extends NavigationMixin(LightningElement) {

    @api recordId;
    subscription = null;
    
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_ID_FIELD] })
    acct;
    
    interviewfields = [PERSON_INTERVIEWD_FIELD, INTERVIEWED_BY_FIELD, DATE_OF_INTERVIEW_FIELD, PRIORITY_FIELD, MANUALLY_ALLOCATED_FIELD]; 
    systemfields = [CREATED_BY_FIELD, LAST_MODIFIED_BY_FIELD, WO_NUMBER_FIELD, OWNERS_TEAM_FIELD, ESCALATION_REASON_FIELD];
    casedetailfields = [NAME_FIELD, ADDRESS_READONLY_FIELD]; 
    demographicsfields = [ATSI_FIELD, SUP_OFFICER_FIELD, COUNTRY_OF_BIRTH_FIELD, CULTURAL_IDENTITY_FIELD, LANGUAGE_SPOKEN_FIELD, INTERPRETER_REQUIRED_FIELD, TRANSLATED_DOCUMENTS_FIELD, DOCUMENTS_LANGUAGE_FIELD];
    furtherdetailfields = [DOB_FIELD, SEX_FIELD, ACCOMMODATION_TYPE_FIELD, MOBILE_FIELD, IF_OTHER_SPECIFY_FIELD, EMAIL_FIELD, NAME_OF_PARENT_FIELD];
    
    get propertyId() {
        return getFieldValue(this.acct.data, ACCOUNT_ID_FIELD);
    }
  
    
    activeSections = ['Interview', 'Case Details', 'Further Details', 'Demographics', 'System Information'];
    
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
       
    }
   // label = {
   //     ADDRESS_LABEL
   // };
    
    @wire(MessageContext)
    messageContext;

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                UPDATEINTERVIEW,
                (message) => this.handleMessage(message)               
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }
    handleMessage(message) {
        this.recordId = message.recordId;
    }
   
  }