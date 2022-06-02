import { LightningElement, track, api  } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getInitialData from '@salesforce/apex/VaccinationDetailsController.getInitialData';
import createhealthCloudRecordOnSubmit from '@salesforce/apex/VaccinationDetailsController.createhealthCloudRecordOnSubmit';
import HEALTHCLOUDGA_EHRIMMUNIZATION from '@salesforce/schema/HealthCloudGA__EhrImmunization__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class VaccinationDetails extends NavigationMixin(LightningElement)
{
    contactId;
    @track showExistingRecords = false;
    @track lstEhrImmunizationDetails = [];
    healthCloudGAEHRIRecord = {};
    @api recordId;

   
    connectedCallback() 
    {
       this.fetchEhrImmunizationDetailsTable();
    }
    fetchEhrImmunizationDetailsTable()
    {
        getInitialData({ contactId: this.recordId })
            .then(result => {
                var responseData = result;
                if (responseData.isSuccess) 
                {
                    console.log(responseData);
                    this.fetchEhrImmunizationDetailsTableHandler(responseData);
                }
                else 
                {
                    showToast(responseData.message);
                }
                this.showSpinner = false;
            })
            .catch(error => {
                showToast(error.message);
                this.showSpinner = false;
            })

    }
    fetchEhrImmunizationDetailsTableHandler(responseData)
     {
        var response = JSON.parse(responseData.response);      
        this.lstEhrImmunizationDetails = response.lsthealthCloudRecords;
     }

    handleFieldChange(e)
     {        
            this.healthCloudGAEHRIRecord[e.currentTarget.fieldName] = e.target.value;
        
     
    }
    saveForm()
    {
            createhealthCloudRecordOnSubmit({contactId: this.recordId,healthCloudObj: { ...this.healthCloudGAEHRIRecord, sobjectType: HEALTHCLOUDGA_EHRIMMUNIZATION.objectApiName }}).then(result => {
                var responseData = result;
               
                if (responseData.isSuccess)
                 {
                    var response = JSON.parse(responseData.response);
                    this.lstEhrImmunizationDetails = response.lsthealthCloudRecords;
                    this.showToast('Success','success', 'Vaccination Details Added');
                 }
                 else
                 {
                    showToast(responseData.message);
                    this.showToast('Error','error', 'Insertion Failed');
                 }
                })
                .catch(error => {
                    this.showToast('Error','error', 'Insertion Failed');
                    this.showSpinner = false;
                })
                this.clearForm();
      
    }
    clearForm()
    {
        this.template.querySelectorAll('lightning-input-field[data-id="reset"]').forEach(element => {
            element.value = null;
          });

    }  

    showToast(title, variant, message) {
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }
}
