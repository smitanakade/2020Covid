import { LightningElement,api } from 'lwc';

export default class DlwcListComponent extends LightningElement {
    @api record;
    @api fieldname;
    @api iconname;
    @api objectApiName;
    loading = true;
    showMoreDetails = false;

    @api hidelist;

    /**
     * Event Fires when we select record from dropdown 
     */
    handleSelect(event){
        event.preventDefault();
        const selectedRecord = new CustomEvent(
            "select",
            {
                detail : this.record.Id
            }
        );
        /* fire the event to be handled on the Parent Component */
        this.dispatchEvent(selectedRecord);
    }

    onRecordLoad(){
        this.loading = false;
    }

    toggleDetails(event){
        this.showMoreDetails = !this.showMoreDetails;
        const rowId = event.currentTarget.dataset.id;
        //console.log('rowId', rowId);
        let elements = this.template.querySelector(`div[data-id="${rowId}"]`);
        elements.classList.toggle('slds-hide');  
        /*let elements = this.template.querySelectorAll(`div[data-id="${rowId}"]`);
        elements.forEach(element => {
            element.classList.toggle('slds-hide');            
        });*/
    }

    get toShowDetails(){
        console.log('toShowDetails', this.showMoreDetails);
        this.loading = false;
        return this.showMoreDetails;
    }

    get icon(){
        return (this.showMoreDetails ? 'utility:down' : 'utility:right');
    }

    get showLabel(){
        return (this.showMoreDetails ? '' : '');
    }
}