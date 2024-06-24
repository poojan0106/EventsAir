//customfx.js for FX version 2.0
//If the function returns "1" FX will continue on with functionality as normal.  If the function returns "0" FX will not execute the requested operation.
// if you are using Google Analytics and have created the array _gaq in your HTML, setting expocadfx_report_events to "true" and checking "Use API" in
// the Save FX Options will add events in EXPOCAD FX to the Google Analytics data.
var expocadfx_report_events = true;
var FXmessage = null;
var expocadCredentials = null;
var sfdcOriginUrl = null;

window.addEventListener("message", receiveMessage, false);

function checkCustom() {
  return "1";	//DO NOT EDIT THIS FUNCTION
}

function receiveMessage(event) {

  if ( 
	/[.]visual[.]force[.]com$/.test(event.origin) ||
    /[.]salesforce[.]com$/.test(event.origin) ||
	/[.]lightning[.]force[.]com$/.test(event.origin)) {
    sfdcOriginUrl = event.origin;
    FXmessage = event;
    if (event.data.toString() == "fxSalesLogout") {
      doLogout();
    }
	if (event.data.toString() == "zoombooth") {
		doZoomBooth();
	}
    else {
      expocadCredentials = event.data.toString();
    }
  }
}

function getCredentials() {
  return expocadCredentials;
}
function logThis( value) {
  console.log( "From Flash:  " + value);
}
function exhibitorListClick(exID, exName, boothNum) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exName, 'ExhibitorListClick', boothNum]);
  }
  // Click on Exhibitor List code here...
  return "1";
}
function availableListClick(boothDimensions, boothArea, boothList) {
  // Click on Available Booth List code here...
  return "1";
}
function categoryListClick(category, bthList) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'CategoryListClick', category, bthList]);
  }
  // Click on Category List code here...
  return "1";
}
function categoryMemberClick(exhName, exhId, bthList) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exhName, 'CategoryListClick', bthList]);
  }
  // Click on Exhibitor in Category List code here...
  return "1";
}
function countryListClick(country, bthList) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'CategoryListClick', country, bthList]);
  }
  // Click on Category List code here...
  return "1";
}
function countryMemberClick(exhName, exhId, bthList) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exhName, 'countryListClick', bthList]);
  }
  // Click on Exhibitor in Category List code here...
  return "1";
}
function pavilionListClick(pavilion, bthList) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'PavilionListClick', pavilion, bthList]);
  }
  // Click on Pavilion List code here...
  return "1";
}
function pavilionMemberClick(exhName, exhId, bthList) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exhName, 'PavilionListClick', bthList]);
  }
  // Click on Booth in Pavilion List code here...
  return "1";
}
function showInShowListClick(showInShow, bthList) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'ShowInShowListClick', pavilion, bthList]);
  }
  // Click on Show In Show List code here...
  return "1";
}
function showInShowMemberClick(exhName, exhId, bthList) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exhName, 'ShowInShowListClick', bthList]);
  }
  // Click on Booth in Show In Show List code here...
  return "1";
}
function rBoothClick(boothNum, exID, exName) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exName, 'ContactInfo', boothNum]);
  }
  //Rented booth code here...
  
    if(confirm("Are you sure you want to select Rented booth " + boothNum + "?" + "\nRented to: " + exName + "\nID: " + exID)) {
	  // The is the message that posts back to the parent window, passing it the booth number clicked
	  FXmessage.source.postMessage("Booth: " + boothNum, sfdcOriginUrl);
	  FXmessage.source.postMessage("Exhibitor ID: " + exID, sfdcOriginUrl);
	  FXmessage.source.postMessage("Exhibitor Name: " + exName, sfdcOriginUrl);
	  doLogout();
	FXmessage.source.postMessage("CloseFX", sfdcOriginUrl);
  }
  //Switch to zero so exhibitor info popup does not occur in the FX event
  return "0";
}
function rBoothAFavs(boothNum, exID, exName) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exName, 'AddToFavs', boothNum]);
  }
  //Add rented booth to favorites code here...
  return "1";
}
function rBoothRFavs(boothNum, exID, exName) {
  //Remove rented booth to favorites code here...
  return "1";
}
function rBoothEmail(boothNum, exID, email, exName) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exName, 'EmailExhibitor', boothNum]);
  }
  //Rented booth email code here...
  return "1";
}
function rBoothWeb(boothNum, exID, web, exName) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exName, 'WebsiteClick', boothNum]);
  }
  //Rented booth web code here...

  //alert( "Booth web click: " + boothNum + "  id: " + exID + "  web: " + web + "  name: " + exName);
  return "1";
}
function googleMapIt(boothNum, exID, exhName) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    boothNum = "Booth " + boothNum;
    _gaq.push(['_trackEvent', exhName, 'Map', boothNum]);
  }
  //Google Map Button click code here...
  return "1";
}
function printExInfo(boothNum, exID, exName) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exName, 'PrintExhibitorInfo', boothNum]);
  }
  //Print exhibitor information code here...
  return "1";
}
function aBoothClick(boothNum) {
  //Available booth code here...
  //if (FXmessage === null) {
    //return "1";
  //}
  if(confirm("Are you sure you want to select booth " + boothNum)) {
	  // The is the message that posts back to the parent window, passing it the booth number clicked
	  FXmessage.source.postMessage(boothNum, sfdcOriginUrl);
	  doLogout();
	FXmessage.source.postMessage("CloseFX", sfdcOriginUrl);
	  return "0";
  }else {
	  return "0";
  }

  
  
}
function salesLogoutCallback() {

console.log('Inside saleslogoutCallback function sendinf CloseFx'); 

  FXmessage.source.postMessage("CloseFX", sfdcOriginUrl)
}
function doLogout() {

console.log('Inside doLogout function and expocadfx value is '+expocadfx);

  if (typeof(expocadfx) != "undefined") {
    if (expocadfx) {

console.log('Inside if when expocadfx is true inside dologout function'); 

      expocadfx.salesLogout();
    }
  }
  else {

   console.log('Inside else condition in doLogout function');
    document.getElementById("exfx").salesLogout();
  }
}

function doZoomBooth() {

  console.log('Inside zoomBooth function and expocadfx value is '+expocadfx);

  if (typeof(expocadfx) != "undefined") {
    if (expocadfx) {

     console.log('Inside if when expocadfx is true and the parameter is '+booth);  
      expocadfx.zoomToBooth("+booth+");
    }
  }
  else {
    document.getElementById("exfx").salesLogout();
  }
}

function aBoothAFavs(boothNum) {
  //Add available booth to favorites code here...
  return "1";
}
function aBoothRFavs(boothNum) {
  //Remove available booth from favorites code here...
  return "1";
}
function aBoothEmail(boothNum, email) {
  //Available booth email code here...
  return "1";
}
function aBoothWeb(boothNum, web) {
  //Available booth web code here...
  return "1";
}
function mBoothClick(boothNum) {
  //Multiple exhibitor booth click code here...
  return "1";
}
function emailFriend(boothNum, webLink, exhName) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', exhName, 'emailFriend', webLink]);
  }
  //Email friend code here...
  return "1";
}
function sendFriendEmail(webLink) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'Send Email', webLink]);
  }
  //Send email to friend (from Preview Link) code here...
  return "1";
}
function openFriendLink(webLink) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'Open Link', webLink]);
  }
  //Open link in new window code here...
  return "1";
}
function toggleUnits(units) {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'Toggle Units', units]);
  }
  //Toggle units code here...
  return "1";
}
function zoomToFavs() {
  //Zoom to favorites code here...
  return "1";
}
function editFavs() {
  //Edit favorites code here...
  return "1";
}
function removeAllFavs() {
  //Remove all favorites code here...
  return "1";
}
function printCurrentList() {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'Print Command', 'List']);
  }
  //Print current list code here...
  return "1";
}
function toggleBuilding() {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'Toggle Building', 'building']);
  }
  //Toggle building ON/OFF code here...
  return "1";
}
function viewHelp() {
  //View help code here...
  return "1";
}
function refreshHall() {
  //Refresh current hall code here...
  return "1";
}
function selectHall() {
  //Select different hall code here...
  return "1";
}
function printFavsList() {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'Print Command', 'Favorites list']);
  }
  //Print favorites list code here...
  return "1";
}
function printFullFloorplan() {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'Print Command', 'Floor plan']);
  }
  //Print full floorplan code here...
  return "1";
}
function printVisibleFloorplan() {
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'Print Command', 'Floor plan window']);
  }
  //Print visible portion of floorplan code here...
  return "1";
}
function openPdf() {
  //Open PDF code here...
  return "1";
}
function mapLoadFinish() {
  //Map load completed code here...
  return "1";
}
function closeAvailBox() {
  //Close available booth popup code here....
  return "1";
}
function closeRentBox() {
  //Close rented booth popup code here....
  return "1";
}
function closeMultiBox() {
  //Close multiple exhibitor booth popup code here....
  return "1";
}
function closeFavsBox() {
  //Close favorites list popup code here....
  return "1";
}
function closeHelpBox() {
  //Close help popup code here....
  return "1";
}
function closeLinkBox() {
  //Close email a friend link box code here....
  return "1";
}
function iAmHere(url) {
  //iAmHere Coordinates chosen code here....
  return "1";
}
function overlayClick(imgName, url) {
  // called from clicks on overlay and Ad Banner images
  if (expocadfx_report_events && typeof( _gaq) != "undefined") {
    _gaq.push(['_trackEvent', 'AdClick', imgName, url]);
  }
  //Overlay click code here....
  return "1";
}
function expired() {
  //Application expired code h
}