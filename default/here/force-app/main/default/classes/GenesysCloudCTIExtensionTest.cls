/**
 * @Author             : Darko Jovanovic
 * @Description        : GenesysCloudCTIExtension test class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 13/01/2021     Darko Jovanovic       Feature 245116: Genesys Cloud implementation - Initial version
**/
@isTest
private class GenesysCloudCTIExtensionTest {

    @isTest
    static void testOnSaveLog() {
        // Create a dummy person account
        Account personAcc = TestDataFactory.createAccount(1, 'Active','Person Account')[0];
        // Then create a call against that account using the CTI extension
        Contact con = 
            [SELECT Id
            FROM Contact
            WHERE AccountId = :personAcc.Id
            LIMIT 1];
        String data = '{"callLog":{"whoid":"' + con.Id + '","subject":"Call 13/01/2021, 12:27:45","Date_and_Time__c":"2021-01-13T01:27:39.411Z","calldurationinseconds":2,"Status":"Completed","CallType":"Outbound","CallObject":"51cc97ce-dbb7-4b91-b234-ccb11e5c7309","Type":"Call","ActivityDate":"2021-1-13"},"interaction":{"id":"51cc97ce-dbb7-4b91-b234-ccb11e5c7309","connectedTime":"2021-01-13T01:27:45.475Z","endTime":"2021-01-13T01:27:47.595Z","phone":"tel:+61444444444","name":"Mobile Number, Australia","isConnected":false,"isDisconnected":true,"isDone":true,"state":"DISCONNECTED","isCallback":false,"isDialer":false,"isChat":false,"isEmail":false,"isMessage":false,"isVoicemail":false,"remoteName":"Mobile Number, Australia","recordingState":"none","displayAddress":"+61444444444","ani":"Internal","calledNumber":"+61444444444","interactionDurationSeconds":2,"direction":"Outbound","isInternal":false,"startTime":"2021-01-13T01:27:39.411Z"},"eventName":"interactionDisconnected"}';
        String returnId = (new GenesysCloudCTIExtension()).onSaveLog(data);
        System.assert(!String.isBlank(returnId));
    }

    @isTest
    static void testOnSaveLogRelatedCaseWithContactSpecified() {
        // Create two person accounts
        List<Account> accountList = TestDataFactory.createAccount(2, 'Active','Person Account');
        // Create associated case with the first person account only
        Case caseExp = TestDataFactory.createCases(accountList[0], 1, 'Isolate', 'Exposure Management')[0];
        // Then create a call against associated with the case and the second person account specified as the WhoId (i.e. not the one associated with the case)
        Contact con = 
            [SELECT Id
            FROM Contact
            WHERE AccountId = :accountList[1].Id
            LIMIT 1];
        String data = '{"callLog":{"whoid":"' + con.Id + '","whatId":"' + caseExp.Id + '","subject":"Call 13/01/2021, 12:27:45","Date_and_Time__c":"2021-01-13T01:27:39.411Z","calldurationinseconds":2,"Status":"Completed","CallType":"Outbound","CallObject":"51cc97ce-dbb7-4b91-b234-ccb11e5c7309","Type":"Call","ActivityDate":"2021-1-13"},"interaction":{"id":"51cc97ce-dbb7-4b91-b234-ccb11e5c7309","connectedTime":"2021-01-13T01:27:45.475Z","endTime":"2021-01-13T01:27:47.595Z","phone":"tel:+61444444444","name":"Mobile Number, Australia","isConnected":false,"isDisconnected":true,"isDone":true,"state":"DISCONNECTED","isCallback":false,"isDialer":false,"isChat":false,"isEmail":false,"isMessage":false,"isVoicemail":false,"remoteName":"Mobile Number, Australia","recordingState":"none","displayAddress":"+61444444444","ani":"Internal","calledNumber":"+61444444444","interactionDurationSeconds":2,"direction":"Outbound","isInternal":false,"startTime":"2021-01-13T01:27:39.411Z"},"eventName":"interactionDisconnected"}';
        String returnId = (new GenesysCloudCTIExtension()).onSaveLog(data);
        System.assert(!String.isBlank(returnId));
        // Ensure the selected whoId and whatId weren't overwritten
        Task t = 
            [SELECT WhoId, WhatId
            FROM Task
            WHERE Id = :returnId];
        System.assertEquals(con.Id, t.WhoId);
        System.assertEquals(caseExp.Id, t.WhatId);

    }

    @isTest
    static void testOnSaveLogRelatedCaseWithContactNotSpecified() {
        // Create a dummy person account
        Account personAcc = TestDataFactory.createAccount(1, 'Active','Person Account')[0];
        // Create associated case
        Case caseExp = TestDataFactory.createCases(personAcc, 1, 'Isolate', 'Exposure Management')[0];
        // Then create a call against that account and case using the CTI extension (no WhoId specified)
        Contact con = 
            [SELECT Id
            FROM Contact
            WHERE AccountId = :personAcc.Id
            LIMIT 1];
        String data = '{"callLog":{"whatId":"' + caseExp.Id + '","subject":"Call 13/01/2021, 12:27:45","Date_and_Time__c":"2021-01-13T01:27:39.411Z","calldurationinseconds":2,"Status":"Completed","CallType":"Outbound","CallObject":"51cc97ce-dbb7-4b91-b234-ccb11e5c7309","Type":"Call","ActivityDate":"2021-1-13"},"interaction":{"id":"51cc97ce-dbb7-4b91-b234-ccb11e5c7309","connectedTime":"2021-01-13T01:27:45.475Z","endTime":"2021-01-13T01:27:47.595Z","phone":"tel:+61444444444","name":"Mobile Number, Australia","isConnected":false,"isDisconnected":true,"isDone":true,"state":"DISCONNECTED","isCallback":false,"isDialer":false,"isChat":false,"isEmail":false,"isMessage":false,"isVoicemail":false,"remoteName":"Mobile Number, Australia","recordingState":"none","displayAddress":"+61444444444","ani":"Internal","calledNumber":"+61444444444","interactionDurationSeconds":2,"direction":"Outbound","isInternal":false,"startTime":"2021-01-13T01:27:39.411Z"},"eventName":"interactionDisconnected"}';
        String returnId = (new GenesysCloudCTIExtension()).onSaveLog(data);
        System.assert(!String.isBlank(returnId));
        // Ensure whoId was defaulted to the Person Account contact
        Task t = 
            [SELECT WhoId
            FROM Task
            WHERE Id = :returnId];
        System.assertEquals(con.Id, t.WhoId);    
    }

    @isTest
    static void testOnSaveLogDefaultCase() {
        // Create a dummy person account
        Account personAcc = TestDataFactory.createAccount(1, 'Active','Person Account')[0];
        // Create associated case
        Case caseExp = TestDataFactory.createCases(personAcc, 1, 'Isolate', 'Exposure Management')[0];
        // Then create a call against that account and case using the CTI extension (no WhatId specified)
        Contact con = 
            [SELECT Id
            FROM Contact
            WHERE AccountId = :personAcc.Id
            LIMIT 1];
        String data = '{"callLog":{"whoid":"' + con.Id + '","subject":"Call 13/01/2021, 12:27:45","Date_and_Time__c":"2021-01-13T01:27:39.411Z","calldurationinseconds":2,"Status":"Completed","CallType":"Outbound","CallObject":"51cc97ce-dbb7-4b91-b234-ccb11e5c7309","Type":"Call","ActivityDate":"2021-1-13"},"interaction":{"id":"51cc97ce-dbb7-4b91-b234-ccb11e5c7309","connectedTime":"2021-01-13T01:27:45.475Z","endTime":"2021-01-13T01:27:47.595Z","phone":"tel:+61444444444","name":"Mobile Number, Australia","isConnected":false,"isDisconnected":true,"isDone":true,"state":"DISCONNECTED","isCallback":false,"isDialer":false,"isChat":false,"isEmail":false,"isMessage":false,"isVoicemail":false,"remoteName":"Mobile Number, Australia","recordingState":"none","displayAddress":"+61444444444","ani":"Internal","calledNumber":"+61444444444","interactionDurationSeconds":2,"direction":"Outbound","isInternal":false,"startTime":"2021-01-13T01:27:39.411Z"},"eventName":"interactionDisconnected"}';
        String returnId = (new GenesysCloudCTIExtension()).onSaveLog(data);
        System.assert(!String.isBlank(returnId));
        // Ensure whatId was defaulted to the newly-created case
        Task t = 
            [SELECT WhatId
            FROM Task
            WHERE Id = :returnId];
        System.assertEquals(caseExp.Id, t.WhatId);    
    }

}
