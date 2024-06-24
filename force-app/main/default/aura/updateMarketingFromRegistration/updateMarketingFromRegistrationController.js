({
	doinit : function(component, event, helper) {
        var action = component.get("c.setMarketingField");
        action.setParams({
            recordId:component.get("v.recordId")
		});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: 'Success!',
                    message: 'Record update successfully.',
                    type: 'success'
                });
                toastEvent.fire();
            }else{
                console.log('Error::::',response.getError());
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: 'Error!',
                    message: 'Something went wrong.',
                    type: 'error'
                });
                toastEvent.fire();
            }
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);

		
	}
})