public class SendEmailToCaseOwner {
    @testVisible
    private static Boolean EmailSent = false;

    /**
     * #270278
     * 
     * Send an email to each Case's previous owner to inform them that ownership has changed.
     * 
     * The calling code is responsible for making sure only cases with changed owners are
     * passed into this method's input.
     * 
     * @param casePreviousOwnerMap Map of Case ID to Owner ID for each Case's previous owner
     * @param caseNewOwnerMap      Map of Case ID to Owner ID for each Case's previous owner
     */
    public static void sendEmail(Map<Id,Id> casePreviousOwnerMap,Map<Id,Id> caseNewOwnerMap) {
        List<Id> idList = new List<Id>();
        
        // Collect all User/Group IDs together
        idList.addAll(casePreviousOwnerMap.values());
        idList.addAll(caseNewOwnerMap.values());

        // Map from User/Group ID to their Name
        Map<Id, String> idToNameMap = New Map<Id, String>();

        // Map from User/Group ID to their Email address
        Map<Id, String> idToEmailMap = New Map<Id, String>();

        for (User u: [SELECT Id, Name, Email FROM User WHERE (Id IN :idList)]) {
            idToNameMap.put(u.Id, u.Name);
            idToEmailMap.put(u.Id, u.Email);
        }

        //#307893
        for (Group g: [SELECT Id, Name, Email FROM Group WHERE (Id IN :idList) And (Email != null)]) {
            idToNameMap.put(g.Id, g.Name);
            idToEmailMap.put(g.Id, g.Email);
        }
        
        try {
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

            // Go through each case with a changed owner and send an email to notify them
            // that the case they previously owned has been re-allocated to a different user/group
            for (Id caseId : casePreviousOwnerMap.keySet()) {
                String previousOwnerName = idToNameMap.get(casePreviousOwnerMap.get(caseId));
                String newOwnerName      = idToNameMap.get(caseNewOwnerMap.get(caseId));

                //#307893: Fixed by explicitly referencing old email rather than setting TargetId
                String previousOwnerEmail = idToEmailMap.get(casePreviousOwnerMap.get(caseId));

                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setSubject('Your case is Reassigned : ' + caseId);
                message.setPlainTextBody('Dear ' + previousOwnerName + ', this record : ' + caseId +' has been transferred to another LPHU due to a more recent exposure in ' + newOwnerName + ' being identified. Please follow up with the new record owner to outline further handover as required.');
                message.setToAddresses(new String[]{previousOwnerEmail});
                message.WhatId = caseId;
                message.optOutPolicy = 'FILTER';
                message.setSaveAsActivity(false);
                mails.add(message);     
            }
            
            if (!Test.isRunningTest()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
                for(integer i = 0 ; i < results.size() ; i++){
                    if (results[i].success) {
                        System.debug('The email was sent successfully.');
                    } else {
                        System.debug('The email failed to send: ' + results[i].errors[i].message);
                    }
                }
            } else {
                EmailSent = true;
            }
        } catch(Exception e) {
            // TODO: add call to error logging framework once it's ready

            system.Debug('e.Error Message ' + e.getMessage());
            system.Debug('Line Number ' + e.getLineNumber());
        }
    }
}