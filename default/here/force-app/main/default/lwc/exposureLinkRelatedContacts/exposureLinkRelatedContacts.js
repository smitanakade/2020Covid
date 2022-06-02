import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getIndividualsLinkedToCase from "@salesforce/apex/ELRelatedContactsController.getIndividualsLinkedToCase";

const columns = [
    {
        label: 'Record', hideDefaultActions: "true", fieldName: 'recordLink', type: 'url', typeAttributes: {
            label: {
                fieldName: 'record'
            }
        }
    },
    { label: 'Record Type', hideDefaultActions: "true", fieldName: 'recordType' },
    {
        label: 'Contact', hideDefaultActions: "true", fieldName: 'contactLink', type: 'url', typeAttributes: {
            label: {
                fieldName: 'contact'
            }
        }
    },
    {
        label: 'Movement', hideDefaultActions: "true", fieldName: 'movementLink', type: 'url', typeAttributes: {
            label: {
                fieldName: 'movement'
            }
        }
    },
    { label: 'Relationship to case', hideDefaultActions: "true", fieldName: 'caseRelationship' },
    {
        label: 'Parent Record', hideDefaultActions: "true", fieldName: 'parentRecordLink', type: 'url', typeAttributes: {
            label: {
                fieldName: 'parentRecord'
            }
        }
    },
    { label: 'Parent Record Contact', hideDefaultActions: "true", fieldName: 'parentRecordContact' },
    { label: 'Linked', type:'boolean', hideDefaultActions: "true", fieldName: 'alreadyLinked' },
];

export default class IndividualContactList extends LightningElement {

    @track columns = columns;
    @track individualList = [];
    wiredIndividualList;
    @api recordId;
    error;
    @api headerName;
    @api recTypeName = '';

    @wire(getIndividualsLinkedToCase, {recordId:'$recordId', linkedCaseRecordType: '$recTypeName' })
    getIndividualList(result) {
        this.wiredIndividualList = result;
        console.log(JSON.stringify(result));
        if (result.data) {
            this.individualList = result.data.map(rec => ({
                recId: rec.participant.Record__c,
                record: rec.participant.Record__r.CaseNumber, recordType: rec.participant.Record__r.RecordType.Name, contact: rec.participant.Contact.Name, movement: rec.participant.ContactEncounter.Name, caseRelationship: rec.participant.Relationship_to_Case__c, parentRecord: rec.participant.Parent_Record__r.CaseNumber,
                parentRecordContact: rec.participant.Parent_Record__r.Contact.Name,
                recordLink: `/lightning/r/ContactEncounterParticipant/${rec.participant.Id}/view`,
                contactLink: `/lightning/r/Account/${rec.participant.Contact.Id}/view`,
                movementLink: `/lightning/r/ContactEncounter/${rec.participant.ContactEncounter.Id}/view`,
                parentRecordLink: `/lightning/r/Case/${rec.participant.Parent_Record__r.Id}/view`,
                alreadyLinked: rec.linkExists
            }));
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.individualList = [];
        }
    }

    get title(){
        return `${this.headerName} (${this.individualList.length})`;
    }
    get displayDatatable(){
        return this.individualList.length>0;
    }
    refresh() {
        refreshApex(this.wiredIndividualList);
      }
}