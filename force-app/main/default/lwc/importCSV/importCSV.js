import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveFile from '@salesforce/apex/ImportFunctionality.saveFile';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
//import getOpportunityName from '@salesforce/apex/ImportFunctionality.getOpportunityName';

export default class ImportCSV extends NavigationMixin(LightningElement) {
    @track columns = [
        { label: 'Online Manual Log-Ins', fieldName: 'Name' },
        { label: 'First Name', fieldName: 'First Name', type: 'text' },
        { label: 'Last Name', fieldName: 'Last Name' },
        { label: 'Email Address', fieldName: 'Email Address' },
        { label: 'Company Name', fieldName: 'Company Name' },
        { label: 'Address Line 1', fieldName: 'Address Line 1' },
        { label: 'City', fieldName: 'City' },
        { label: 'State', fieldName: 'State' },
        { label: 'Postal Code', fieldName: 'Postal Code' },
        { label: 'Country', fieldName: 'Country' },
        { label: 'Work Phone', fieldName: 'Work Phone' }
    ];

    @track opportunityId;
    @api recordId;
    @track opportunityName;
    @track data;
    @track fileName = '';
    @track firstName = '';
    @track UploadFile = 'Upload CSV File';
    @track showLoadingSpinner = false;
    @track isTrue = false;
    selectedRecords;
    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    content;
    MAX_FILE_SIZE = 1500000;
    visible = false;

    /*@wire(getOpportunityName, { opportunityId: '$opportunityId' })
    wiredOpportunityName({ error, data }) {
        if (data) {
            this.opportunityName = data;
            console.log('Fetched Opportunity Name:', this.opportunityName);
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error',
                })
            );
        }
    }*/

    // connectedCallback() {
    //     console.log('Opportunity ID from Quick Action:', this.recordId);
    // }


    @wire(CurrentPageReference)
    getPageReference(currentPageReference) {
        if (currentPageReference) {
            const urlParams = currentPageReference.state;
            this.recordId = urlParams['oppId']; // Retrieve the recordId from the query string
            console.log('Record Id:', this.recordId);
        }
    }

    handleFilesChange(event) {
        if (event.target.files.length > 0) {
            this.filesUploaded = event.target.files;
            this.fileName = this.filesUploaded[0].name;
            console.log('OUTPUT : this ', this.fileName);
        }
    }

    handleSave() {
        if (this.filesUploaded.length > 0) {
            this.uploadFile();
            console.log('OUTPUT :record id ', this.opportunityId);
        } else {
            this.fileName = 'Please select a CSV file to upload!!';
        }
    }

    uploadFile() {
        if (this.filesUploaded[0].size > this.MAX_FILE_SIZE) {
            console.log('File Size is too large');
            return;
        }

        this.showLoadingSpinner = true;

        this.fileReader = new FileReader();

        this.fileReader.onloadend = () => {
            this.fileContents = this.fileReader.result;
            this.processCSV();
        };

        this.fileReader.readAsText(this.filesUploaded[0]);
    }

    processCSV() {
        console.log('OUTPUT : this.opportunityId ======>', this.opportunityId);
        console.log('OUTPUT : fileContents==>', this.fileContents);

        try {
            saveFile({ base64Data: JSON.stringify(this.fileContents), OpportunityId: this.opportunityId })
                .then(result => {
                    console.log('result=> ', result);
                    // this[NavigationMixin.Navigate]({
                    //     type: 'standard__recordPage',
                    //     attributes: {
                    //         recordId: this.opportunityId,
                    //         actionName: 'view'
                    //     }
                    // });

                    // // Delay returning to CSV_Upload
                    // setTimeout(() => {
                    //     this[NavigationMixin.Navigate]({
                    //         type: 'standard__navItemPage',
                    //         attributes: { apiName: 'CSV_Upload' },
                    //         state: { oppId: this.opportunityId }
                    //     });
                    // }, 2000);
                })
                .catch(error => {
                    console.error('Error while saving file:', error);
                });
        } catch (error) {
            console.error('Unexpected error:', error);
            this.showLoadingSpinner = false;
        }
    }

    handleBackClick() {
        window.history.back();
    }
}