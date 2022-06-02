/* eslint-disable guard-for-in */
/* eslint-disable no-console */
import initDataMethod from "@salesforce/apex/RelatedListController.initData";

export default class WorkOrderRelatedListHelper {

    fetchData(state,labelName) {
        let jsonData = Object.assign({}, state);
        jsonData.numberOfRecords = state.numberOfRecords + 1;
        jsonData = JSON.stringify(jsonData);
        console.log('BEFORE initDataMethod');
        console.log(jsonData);
        //var label = labelName;
        return initDataMethod({ jsonData })
            .then(response => {
                console.log('related list response');
                
                console.log(response);
                
                const data = JSON.parse(response);

                console.log('related list response after json.parse');
                console.log(data);
                console.log('labelagg' +labelName);
                return this.processData(data, state,labelName);
            })
            .catch(error => {
                console.log('ERROR initDataMethod');
                console.log(error);
            });
    }

    processData(data, state,label){
        console.log('inside process data');
        const records = data.records;
        //console.log('records '+records[0]);
        this.generateLinks(records);
        console.log('records.length -->'+records.length );
        var noRec = Math.min(state.numberOfRecords, records.length);
        console.log('ghga'+data.sobjectLabelPlural);
        console.log('ghirn'+label);
        if (records.length > state.numberOfRecords) {
            records.pop();
            console.log('label '+label);
            //console.log('plural'+this.data.sobjectLabelPlural);
            
        } else {
            if (data.sobjectLabelPlural == 'Contact Encounter' && label == 'Case Movements'){//&& this.state.fields.includes(Arrival_Date__c)){
                data.title = 'Case Movements' + '('+noRec+')'  ;

            }
            else if (data.sobjectLabelPlural == 'Contact Encounter' && label == 'Work Study Care'){
                console.log('inside condition');
                data.title = 'Work Study Care'  + '('+noRec+')'  ;
            }
            else if (data.sobjectLabelPlural == 'Contact Encounter' && label == 'Travel History'){
                console.log('inside condition');
                data.title = 'Travel History'  + '('+noRec+')'  ;
            }
            else{
                data.title = `${data.sobjectLabelPlural} (${Math.min(state.numberOfRecords, records.length)})`
            }
        }     
        return data
    }


    initColumnsWithActions(columns, customActions, labelName) {
        if (!customActions.length) {
            customActions = [
                { label: 'Edit', name: 'edit' }
            ];

            if(labelName == 'Case Movements'){
                customActions.push({label: 'Create Exposure Site', name: 'createExposureSite'});
            }
        }
        return [...columns, { type: 'action', typeAttributes: { rowActions: customActions } }]
    }

    generateLinks(records) {
        records.forEach(record => {
            record.LinkName = '/' + record.Id;
            for (const propertyName in record) {
                const propertyValue = record[propertyName];
                if (typeof propertyValue === 'object') {
                    const newValue = propertyValue.Id ? ('/' + propertyValue.Id) : null;
                    this.flattenStructure(record, propertyName + '_', propertyValue);
                    if (newValue !== null) {
                        record[propertyName + '_LinkName'] = newValue;
                    }
                }

                if(propertyName === 'Exposure_Site_ID__r'){
                    record.ExposureSiteIdUrl = '/'+record[propertyName].Id;
                    record.ExposureSiteID =  record[propertyName].CaseNumber;
                    record.ExposureSiteDetails = 'Subject: ' + record[propertyName].Subject ;
                }
            }
        });

    }

    flattenStructure(topObject, prefix, toBeFlattened) {
        for (const propertyName in toBeFlattened) {
            const propertyValue = toBeFlattened[propertyName];
            if (typeof propertyValue === 'object') {
                this.flattenStructure(topObject, prefix + propertyName + '_', propertyValue);
            } else {
                topObject[prefix + propertyName] = propertyValue;
            }
        }
    }
}