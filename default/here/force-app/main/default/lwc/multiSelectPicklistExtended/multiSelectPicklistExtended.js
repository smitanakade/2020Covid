import { LightningElement, api, track, wire } from "lwc";

import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

import getPicklistValuesList from '@salesforce/apex/SystemUtils.getPickListValuesInObjectAsMap';
import getFieldLabelInObject from '@salesforce/apex/SystemUtils.getFieldLabelInObject';
import getSobjectRecordFieldValue from '@salesforce/apex/SystemUtils.getSobjectRecordFieldValue';

export default class MultiSelectPicklistExtended extends LightningElement {

    @api label = ""; //Name of the dropDown
    @api maxselected = 2; //Max selected item display
    @api options; // List of items to display
    @api showfilterinput = false; //show filterbutton
    @api showrefreshbutton = false; //show the refresh button
    @api showclearbutton = false; //show the clear button
    @api comboplaceholder = "Select a value";

    @track _initializationCompleted = false;
    @track _selectedItems = "Select a value";
    @track _filterValue;
    @track _mOptions;
    @track _yourSelectedValuesFlow = "";

    @api objectapiname;
    @api fieldapiname;
    @api recordid;
    @api existingvalues = [];

    @api existingvaluesFlow;

    @api get yourSelectedValuesFlow() {
        return this._allValues;
    }

    set yourSelectedValuesFlow(value) {
        this._allValues = value;
    }

    constructor() {
        super();
        this._filterValue = "";
        this.showfilterinput = true;
        this.showrefreshbutton = true;
        this.showclearbutton = true;
    }

    renderedCallback() {
        let self = this;
        if (!this._initializationCompleted) {
            this.template
                .querySelector(".ms-input")
                .addEventListener("click", function (event) {
                        self.onDropDownClick(event.target);
                        event.stopPropagation();
                });

            this.template.addEventListener("click", function (event) {
                event.stopPropagation();
            });

            document.addEventListener("click", function (event) {
                self.closeAllDropDown();
            });

            this._initializationCompleted = true;
            this.setPickListName();
        }
    }

    handleItemSelected(event) {
        let self = this;

        this._mOptions.forEach(function (eachItem) {
            if (eachItem.key == event.detail.item.key) {
                eachItem.selected = event.detail.selected;
                return;
            }
        });
        this.setPickListName();
        this.onItemSelected();
    }

    filterDropDownValues(event) {
        this._filterValue = event.target.value;
        this.updateListItems(this._filterValue);
    }

    closeAllDropDown() {
        Array.from(this.template.querySelectorAll(".ms-picklist-dropdown")).forEach(
        function (node) {
            node.classList.remove("slds-is-open");
        });
    }

    onDropDownClick(dropDownDiv) {
        let classList = Array.from(
            this.template.querySelectorAll(".ms-picklist-dropdown")
        );

        if (!classList.includes("slds-is-open")) {
            this.closeAllDropDown();
            Array.from(
                this.template.querySelectorAll(".ms-picklist-dropdown")
            ).forEach(function (node) {
                node.classList.add("slds-is-open");
            });
        } else {
            this.closeAllDropDown();
        }
    }

    onRefreshClick(event) {
        this._filterValue = "";
        this.initArray(this);
        this.updateListItems("");
        this.onItemSelected();
    }

    onClearClick(event) {
        this._filterValue = "";
        this.updateListItems("");
    }

    connectedCallback() {
        this.initArray(this);
    }

    initArray(context) {
        context._mOptions = new Array();

        if (context.options) {
            context.options.forEach(function (eachItem) {
                context._mOptions.push(JSON.parse(JSON.stringify(eachItem)));
            });
        } else if (context.objectapiname && context.fieldapiname) {
            getPicklistValuesList({ objectAPIName: context.objectapiname, fieldAPIName: context.fieldapiname })
                .then((result) => {
               if (this.existingvaluesFlow) {
                   this.existingvalues = this.existingvaluesFlow.split(';');
               }

               for (let key in result) {
                    context._mOptions.push({value:result[key], key:key, selected:context.existingvalues.includes(key)});
               }

                this.updateListItems("");
            })

            getFieldLabelInObject({ objectAPIName: context.objectapiname, fieldAPIName: context.fieldapiname })
                .then((result) => {
                context.label = result;
            })
        }

    }

    updateListItems(inputText) {
        Array.from(this.template.querySelectorAll("c-pick-list-item")).forEach(
            function (node) {
                if (!inputText) {
                    node.style.display = "block";
                } else if (
                    node.item.value
                       .toString()
                       .toLowerCase()
                       .indexOf(inputText.toString().trim().toLowerCase()) != -1
                ) {
                    node.style.display = "block";
                } else {
                    node.style.display = "none";
                }
            });
        this.setPickListName();
    }

    setPickListName() {
        let selecedItems = this.getSelectedItems();
        let selections = "";
        if (selecedItems.length < 1) {
            selections = this.comboplaceholder;
        } else if (selecedItems.length > this.maxselected) {
            selections = selecedItems.length + " Options Selected";
        } else {
            selecedItems.forEach((option) => {
                selections += option.value + ",";
            });
        }
        this._selectedItems = selections;
    }

    @api
    getSelectedItems() {
        let resArray = new Array();
        this._mOptions.forEach(function (eachItem) {
            if (eachItem.selected) {
                resArray.push(eachItem);
            }
        });
        return resArray;
    }

	@api
    getSelectedItemsFlow() {
        let __yourSelectedValuesFlow = "";
        this._mOptions.forEach(function (eachItem) {
            if (eachItem.selected) {
                __yourSelectedValuesFlow += eachItem.value + ";";
            }
        });
        return __yourSelectedValuesFlow;
    }

    onItemSelected() {
        const evt = new CustomEvent("itemselected", {
            detail: this.getSelectedItems(),
        });
        this.dispatchEvent(evt);

        let __yourSelectedValuesFlow = this.getSelectedItemsFlow();

        const attributeChangeEvent = new FlowAttributeChangeEvent(
            "yourSelectedValuesFlow",
            __yourSelectedValuesFlow
        );
        this.dispatchEvent(attributeChangeEvent);
    }

}