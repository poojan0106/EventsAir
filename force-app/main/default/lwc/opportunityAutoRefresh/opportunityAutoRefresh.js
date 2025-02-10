import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import REFRESH_FIELD from '@salesforce/schema/Opportunity.Refresh_On_Load__c';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';

export default class RefreshOnLoad extends LightningElement {
    @api recordId;
    wiredOpportunity;

    @wire(getRecord, { recordId: '$recordId', fields: [REFRESH_FIELD] })
    wiredRecord(result) {
        this.wiredOpportunity = result;
        if (result.data) {
            const shouldRefresh = result.data.fields.Refresh_On_Load__c.value;
            if (shouldRefresh) {
                this.resetRefreshField();  // Step 2: Reset the field before reloading
            }
        } else if (result.error) {
            this.showToast('Error loading Opportunity data', 'error');
        }
    }

    resetRefreshField() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[REFRESH_FIELD.fieldApiName] = false;

        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.showToast('Page will refresh', 'info');
                refreshApex(this.wiredOpportunity);
                setTimeout(() => {
                    location.reload();
                }, 1000);
            })
            .catch(error => {
                this.showToast('Error updating field', 'error');
                console.error(error);
            });
    }

    showToast(message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Notification', message, variant }));
    }
}