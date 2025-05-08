import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveFile from '@salesforce/apex/CSVimportfunctionality.saveFile';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getOpportunityName from '@salesforce/apex/CSVimportfunctionality.getOpportunityName';

export default class ImportCSVClone extends NavigationMixin(LightningElement) {
    @api opportunityId;
    @track opportunityName;
    @track data;
    @track fileName = '';
    @track errorMessage = '';
    @track UploadFile = 'Upload CSV File';
    @track showLoadingSpinner = false;
    @track isTrue = false;
    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    content;
    MAX_FILE_SIZE = 1500000;
    visible = false;

    @wire(getOpportunityName, { opportunityId: '$opportunityId' })
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
    }

    connectedCallback() {
        console.log('OUTPUT : connected callback ', this.opportunityId);
        console.log('OUTPUT : opportunityName', this.opportunityName);
    }

    handleFilesChange(event) {
        this.errorMessage = '';
        if (event.target.files.length > 0) {
            this.filesUploaded = event.target.files;
            this.fileName = this.filesUploaded[0].name;
            if (!this.fileName.toLowerCase().endsWith('.csv')) {
                this.errorMessage = 'Error. Please make sure your file is in a CSV format.';
                this.filesUploaded = [];
                this.fileName = '';
                return;
            }
            console.log('OUTPUT : this ', this.fileName);
        }
    }

    handleSave() {
        if (this.filesUploaded.length > 0) {
            this.uploadFile();
            console.log('OUTPUT :record id ', this.opportunityId);
        } else {
            this.errorMessage = 'Please select a CSV file to upload!!';
        }
    }

    uploadFile() {
        if (this.filesUploaded[0].size > this.MAX_FILE_SIZE) {
            console.log('File Size is too large');
            this.errorMessage = 'File size exceeds the maximum allowed limit.';
            return;
        }

        this.showLoadingSpinner = true;

        this.fileReader = new FileReader();

        this.fileReader.onloadend = () => {
            this.fileContents = this.fileReader.result;
            let rows = this.fileContents.split(/\r\n|\n/); // Split CSV into rows
            console.log('Total Rows:', rows);

            if (rows.length > 51) {
                this.errorMessage = 'Error: CSV file should not have more than 50 rows.';
                this.fileName = '';
                this.showLoadingSpinner = false;
                return;
            }
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
                    console.log('OUTPUT : result=> ', result);
                    if (result.startsWith("Error")) {
                        // Convert new lines (`\n`) to `<br/>` for display
                        this.errorMessage = result.replace(/\n/g, '<br/>');
                        this.fileName = '';
                        console.log('this.errorMessage--->', this.errorMessage);
                    } else {
                        this.fileName = this.fileName + '-' + result;
                        this.errorMessage = '';
                    }
                    // if (result.startsWith("Error")) {
                    //     let formattedMessage = result.replace(/\n/g, '<br/>');
                    //     this.fileName = this.fileName + '-' + formattedMessage;
                    //     console.log('this.fileName--->', this.fileName);

                    // setTimeout(() => {
                    //     let errorContainer = this.template.querySelector('.error-message');
                    //     if (errorContainer) {
                    //         errorContainer.innerHTML = formattedMessage; // Inject HTML content

                    //     }
                    // }, 0);
                    //this.fileName = formattedMessage;
                    /*this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'File Upload Error',
                            message: formattedMessage,
                            variant: 'error',
                            mode: 'sticky'
                        })
                    );*/
                    // } else {
                    //     this.fileName = this.fileName + '-' + result;
                    // }
                    this.isTrue = false;
                    this.showLoadingSpinner = false;
                })
                .catch(error => {
                    console.error('Error while saving file:', error);
                });
        } catch (error) {
            console.error('Unexpected error:', error);
            this.showLoadingSpinner = false;
        }
    }

    renderedCallback() {
        if (this.errorMessage) {
            let errorContainer = this.template.querySelector('.error-message');
            if (errorContainer) {
                errorContainer.innerHTML = this.errorMessage; // Inject HTML for line breaks
            }
        }
    }

    handleBackClick() {
        window.history.back();
    }
}