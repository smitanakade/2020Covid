
@istest
private class DLWC_TypeAheadController_Test {
    static testMethod void runSearchSOQL() {
        
        // Test Data
        List<Schema.Location> locations = new List<Schema.Location>();

        Schema.Location location1 = new Schema.Location();
        location1.Name = 'Office';
        location1.Address__c = '55 Collins Street';
        location1.City__c = 'Melbourne';
        location1.Postal_Code__c = '3000';

        locations.add(location1);

        Schema.Location location2 = new Schema.Location();
        location2.Name = 'Office';
        location2.Address__c = '55 Collins Street';
        location2.City__c = 'Melbourne';
        location2.Postal_Code__c = '3000';

        locations.add(location2);

        insert locations;

        // Construct Method Parameters
        Id recordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('TREVI Locations').getRecordTypeId();
        String searchString = 'Office';
        String sObjectAPIName = 'Location';
        String searchField = 'Name,Address__c';
        String displayfield = 'Name';
        String recordCount = '10';
        String recordType = '';
        String recordTypeIds = string.valueOf(recordTypeId);

        // Testing
        Test.startTest();
        
        List<SObject> searchResults = DLWC_TypeAheadController.fetchLookUpValues(searchString, sObjectAPIName, searchField, displayField, recordCount, recordType, recordTypeIds);
        System.assertEquals(2,searchResults.size());

        Test.stopTest();

    }

    static testMethod void runSearchSOSL() {

        // Test Data
        List<Schema.Location> locations = new List<Schema.Location>();

        Schema.Location location1 = new Schema.Location();
        location1.Name = 'Office';
        location1.Address__c = '55 Collins Street';
        location1.City__c = 'Melbourne';
        location1.Postal_Code__c = '3000';

        locations.add(location1);

        insert locations;

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = location1.id;
        Test.setFixedSearchResults(fixedSearchResults);

        // Construct Method Parameters
        String searchString = 'Office';
        String sObjectAPIName = 'Location';
        String searchField;
        String displayfield = 'Name';
        String recordCount = '10';
        String recordType = '';
        String recordTypeIds = null;
        
        // Testing
        Test.startTest();
        
        List<SObject> searchResults = DLWC_TypeAheadController.fetchLookUpValues(searchString, sObjectAPIName, searchField, displayField, recordCount, recordType, recordTypeIds);
        System.assertEquals(1,searchResults.size());

        Test.stopTest();

    }

    static testMethod void recordCountIsNull() {
        
        // Test Data
        List<Schema.Location> locations = new List<Schema.Location>();

        Schema.Location location1 = new Schema.Location();
        location1.Name = 'Office';
        location1.Address__c = '55 Collins Street';
        location1.City__c = 'Melbourne';
        location1.Postal_Code__c = '3000';

        locations.add(location1);

        Schema.Location location2 = new Schema.Location();
        location2.Name = 'Office';
        location2.Address__c = '55 Collins Street';
        location2.City__c = 'Melbourne';
        location2.Postal_Code__c = '3000';

        locations.add(location2);

        insert locations;

        // Construct Method Parameters
        String searchString = 'Office';
        String sObjectAPIName = 'Location';
        String searchField = 'Name';
        String displayfield = 'Name';
        String recordCount;
        String recordType = '';
        String recordTypeIds = null;

        // Testing
        Test.startTest();
        
        List<SObject> searchResults = DLWC_TypeAheadController.fetchLookUpValues(searchString, sObjectAPIName, searchField, displayField, recordCount, recordType, recordTypeIds);
        System.assertEquals(2,searchResults.size());

        Test.stopTest();

    }

    static testMethod void runSearchDisplayFieldSOQL() {
        
        // Test Data
        List<Schema.Location> locations = new List<Schema.Location>();

        Schema.Location location1 = new Schema.Location();
        location1.Name = 'Office';
        location1.Address__c = '55 Collins Street';
        location1.City__c = 'Melbourne';
        location1.Postal_Code__c = '3000';

        locations.add(location1);

        Schema.Location location2 = new Schema.Location();
        location2.Name = 'Office';
        location2.Address__c = '55 Collins Street';
        location2.City__c = 'Melbourne';
        location2.Postal_Code__c = '3000';

        locations.add(location2);

        insert locations;

        // Construct Method Parameters
        String searchString = 'Office';
        String sObjectAPIName = 'Location';
        String searchField = 'Name';
        String displayfield = 'City__c';
        String recordCount = '10';
        String recordType = '';
        String recordTypeIds = null;

        // Testing
        Test.startTest();
        
        List<SObject> searchResults = DLWC_TypeAheadController.fetchLookUpValues(searchString, sObjectAPIName, searchField, displayField, recordCount, recordType, recordTypeIds);
        System.assertEquals(2,searchResults.size());

        Test.stopTest();
    }

    static testMethod void positiveTest(){
        String contactRtDoctor = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Doctor').getRecordTypeId();
        Contact con = new Contact(FirstName = 'XYZ', LastName = 'XYZ', DLWC_Multi_Sel__c ='A; B; C', RecordTypeId = contactRtDoctor);
        insert con;

        Test.startTest();
        DLWC_TypeAheadController.fetchLookUpValues('XY','Contact','Name','Name','5', contactRtDoctor, null);

        Test.stopTest();
    }

    static testMethod void positiveTest2(){
        String contactRtDoctor = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Doctor').getRecordTypeId();
        Contact con = new Contact(FirstName = 'XYZ', LastName = 'XYZ', DLWC_Multi_Sel__c ='A; B; C', RecordTypeId = contactRtDoctor);
        insert con;

        Test.startTest();
        DLWC_TypeAheadController.fetchLookUpValues('XY','Contact',null,'Name','5',contactRtDoctor, null);

        Test.stopTest();
    }

}
