import { LightningElement,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';


import getSyncData from '@salesforce/apex/SyncEventsAirDataControllerForLWC.getSyncData';
export default class Lwc_air_data extends NavigationMixin(LightningElement){
     @api recordId;
     @wire(CurrentPageReference)
wiredPageRef(pageRef) {
    if (pageRef) {
        this.recordId = pageRef.state.recordId;
    }
}
    /*@wire(getSyncData,{event_Id:'$recordId'})result({data,error}){
        if(data==true)
        {
            
            const evt = new ShowToastEvent({
                title:'Success',
                message:'Record Updated Successfully',
                variant:'success'
            });
            this.dispatchEvent(evt);
        }
        else
        {
            
            const evt = new ShowToastEvent({
                title:'Fail',
                message:'Please Contact your System Administrator',
                variant:'error'
            });
            this.dispatchEvent(evt);
        }        
        const closeAction = new CloseActionScreenEvent();
        this.dispatchEvent(closeAction);
    }*/
    connectedCallback(){
        this.Submit();

    }
    Submit(){
        getSyncData({ eventId: this.recordId })
        .then(result => {
            if(result==true)
        {
            
            const evt = new ShowToastEvent({
                title:'Success',
                message:'Record Updated Successfully',
                variant:'success'
            });
            this.dispatchEvent(evt);
            const closeAction = new CloseActionScreenEvent();
        this.dispatchEvent(closeAction);
        this.navigateToRecordPage();
        }
        else{
            const closeAction = new CloseActionScreenEvent();
            this.navigateToRecordPage();

        }
        })
        .catch(error => {
            const evt = new ShowToastEvent({
                title:'Fail',
                message:'Please Contact your System Administrator',
                variant:'error'
            });
            this.dispatchEvent(evt);
        });
        const closeAction = new CloseActionScreenEvent();
        this.dispatchEvent(closeAction);
}
navigateToRecordPage() {
this[NavigationMixin.Navigate]({
    type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Event__c',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            },
});
}
}