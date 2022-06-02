/**
 * Created by hans on 20/10/20.
 */

import {LightningElement,api} from 'lwc';
import {NavigationMixin} from "lightning/navigation";
export default class FbcRecordItem extends NavigationMixin(LightningElement) {
    @api recordid;
    @api label;
    handleSelect(event){
        this.navigateStandardRecordPage(this.recordid,'view')(this);
    }

    navigateStandardRecordPage = (recordId,action) =>  (context) => {
        context[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: action
            },
        });
    }

}