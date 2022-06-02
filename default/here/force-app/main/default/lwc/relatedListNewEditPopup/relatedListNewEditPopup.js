import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RelatedListNewEditPopup extends LightningElement {
    showModal = false
    @api sobjectLabel
    @api sobjectApiName    
    @api recordId
    @api recordName

    @api show() {
        this.showModal = true;
    }

    @api hide() {
        this.showModal = false;
    }
    handleClose() {
        console.log('inside');
        this.showModal = false;     
    }

    handleDialogClose(){
        this.handleClose()
    }

    isNew(){
        return this.recordId == null
    }
    get header(){
        return this.isNew() ? `New ${this.sobjectLabel}` : `Edit ${this.recordName}`
    }

    handleSave(){
        this.template.querySelector('lightning-record-form').submit();
       
    }    
    handleSuccess(event){
        this.hide()
        let name = this.recordName
        if(this.isNew()){
            if(event.detail.fields.Name){
                name = event.detail.fields.Name.value
            }else if(event.detail.fields.LastName){
                name = [event.detail.fields.FirstName.value, event.detail.fields.LastName.value].filter(Boolean).join(" ")
            }
        } 
        name = name ? `"${name}"` : ''
        
        const message = `${this.sobjectLabel} ${name} was ${(this.isNew() ? "created" : "saved")}.`
        const evt = new ShowToastEvent({
            title: message,
            variant: "success"
        });
        this.dispatchEvent(evt);
        this.dispatchEvent(new CustomEvent("refreshdata"));                  
    }    
      
}