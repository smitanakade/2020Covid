({
    invoke : function(component, event, helper) {
        var record = component.get("v.recId");
        helper.openTab(component, event, helper, record);
    }
})