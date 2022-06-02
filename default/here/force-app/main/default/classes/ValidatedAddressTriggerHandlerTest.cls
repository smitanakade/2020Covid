/**
 * @Author             : Darko Jovanovic
 * @Description        : ValidatedAddressTriggerHandler test class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 15/12/2020     Darko Jovanovic       Feature 237555: ArcGIS integration - Initial version
**/
@isTest
private class ValidatedAddressTriggerHandlerTest {

    @testSetup static void testDataSetup() {

        // Create 3 person accounts
        List<Account> personAccList = TestDataFactory.createAccount(3, 'Active','Person Account');
        for (Integer i = 0; i < personAccList.size(); i++)
        {
            Account acc = personAccList[i];
            acc.PersonMailingPostalCode = '3000';
            acc.AddressValidationStatus__c = '';
            acc.AddressValidationReqId__c = 'PERSON_REQUEST_ID' + i;
        }
        update personAccList;
        // Create 3 org accounts
        List<Account> orgAccList = TestDataFactory.createAccount(3, 'Active','Place Or Organisation');
        for (Integer i = 0; i < orgAccList.size(); i++)
        {
            Account acc = orgAccList[i];
            acc.ShippingPostalCode = '3000';
            acc.AddressValidationStatus__c = '';
            acc.AddressValidationReqId__c = 'ORG_REQUEST_ID' + i;
        }
        update orgAccList;
        // Create 3 locations
        List<Schema.Location> locationList = new List<Schema.Location>();
        for (Integer i = 0; i < 3; i++)
        {
            Schema.Location loc = new Schema.Location();
            loc.Name = 'TestLoc' + i;
            loc.Postal_Code__c = '3000';
            loc.AddressValidationStatus__c = '';
            loc.AddressValidationReqId__c = 'LOC_REQUEST_ID' + i;
            locationList.add(loc);
        }
        insert locationList;
        
    }
    
    @isTest
    static void testProcessValidatedAddresses() {
        // --------------------------------------------
        // Get data
        // --------------------------------------------
        List<Account> personAccList = 
            [SELECT Id, AddressValidationReqId__c
            FROM Account
            WHERE RecordType.Name = 'Person Account'
            ORDER BY AddressValidationReqId__c
            LIMIT 3];
        List<Account> orgAccList = 
            [SELECT Id, AddressValidationReqId__c
            FROM Account
            WHERE RecordType.Name = 'Business'
            ORDER BY AddressValidationReqId__c
            LIMIT 3];
        List<Schema.Location> locationList = 
            [SELECT Id, AddressValidationReqId__c
            FROM Location
            ORDER BY AddressValidationReqId__c
            LIMIT 3];
        String matchingAddressesJSON = '['+
		'        {'+
		'            \"street\": \"314-336 BOURKE STREET\",'+
		'            \"city\": \"MELBOURNE\",'+
		'            \"postalCode\": \"3000\",'+
		'            \"state\": \"VIC\",'+
		'            \"country\": \"Australia\",'+
		'            \"latitude\": -37.813791999999999,'+
		'            \"longitude\": 144.96400800000001,'+
		'            \"geocodeStatus\": \"M\",'+
		'            \"geocodeQuality\": 100,'+
		'            \"matchType\": \"PointAddress\",'+
        '            \"LGA\": \"Melbourne (C)\",'+
        '            \"region\": \"Sample region\",'+
        '            \"division\": \"Sample division\"'+
        '        },'+
        '        {'+
		'            \"street\": \"314 BOURKE STREET\",'+
		'            \"city\": \"MELBOURNE\",'+
		'            \"postalCode\": \"3000\",'+
		'            \"state\": \"VIC\",'+
		'            \"country\": \"Australia\",'+
		'            \"latitude\": -37.813791999999999,'+
		'            \"longitude\": 144.96400800000001,'+
		'            \"geocodeStatus\": \"M\",'+
		'            \"geocodeQuality\": 98,'+
		'            \"matchType\": \"PointAddress\"'+
        '        },'+
        '        {'+
		'            \"street\": \"336 BOURKE STREET\",'+
		'            \"city\": \"MELBOURNE\",'+
		'            \"postalCode\": \"3000\",'+
		'            \"state\": \"VIC\",'+
		'            \"country\": \"Australia\",'+
		'            \"latitude\": -37.813791999999999,'+
		'            \"longitude\": 144.96400800000001,'+
		'            \"geocodeStatus\": \"M\",'+
		'            \"geocodeQuality\": 97,'+
		'            \"matchType\": \"PointAddress\"'+
		'        }'+
        '    ]';
        String unmatchesAddressJSON = '['+
		'        {'+
		'            \"street\": \"314-336 BOURKE STREET\",'+
		'            \"city\": \"MELBOURNE\",'+
		'            \"postalCode\": \"3000\",'+
		'            \"state\": \"VIC\",'+
		'            \"country\": \"Australia\",'+
		'            \"latitude\": 144.96400800000001,'+
		'            \"longitude\": -37.813791999999999,'+
		'            \"geocodeStatus\": \"U\",'+
		'            \"geocodeQuality\": 0,'+
		'            \"matchType\": \"NoMatch\"'+
        '        }'+
        '    ]';
        // --------------------------------------------
        // Raise a Platform Event with 9 results to test the different scenarios (technically 9 event records)
        // --------------------------------------------
        List<ValidatedAddress__e> validatedAddressResponseList = new List<ValidatedAddress__e>();
        // 1. Person residential address - successful validation 
        ValidatedAddress__e validationResponse = new ValidatedAddress__e();
        validationResponse.recordId__c          = personAccList[0].Id;
        validationResponse.AddressType__c       = ValidatedAddressTriggerHandler.ADDRTYPE.PrimaryAddress.name();
        validationResponse.matchesFound__c      = true;
        validationResponse.requestId__c         = personAccList[0].AddressValidationReqId__c;
        validationResponse.matchingAddresses__c = matchingAddressesJSON;
        validatedAddressResponseList.add(validationResponse);
        // 2. Person residential address - no match
        validationResponse = new ValidatedAddress__e();
        validationResponse.recordId__c          = personAccList[1].Id;
        validationResponse.AddressType__c       = ValidatedAddressTriggerHandler.ADDRTYPE.PrimaryAddress.name();
        validationResponse.matchesFound__c      = true;
        validationResponse.requestId__c         = personAccList[1].AddressValidationReqId__c;
        validationResponse.matchingAddresses__c = unmatchesAddressJSON;
        validatedAddressResponseList.add(validationResponse);
        // 3. Person residential address - request id doesn't match
        validationResponse = new ValidatedAddress__e();
        validationResponse.recordId__c          = personAccList[2].Id;
        validationResponse.AddressType__c       = ValidatedAddressTriggerHandler.ADDRTYPE.PrimaryAddress.name();
        validationResponse.matchesFound__c      = true;
        validationResponse.requestId__c         = 'WRONG_REQUEST_ID';
        validationResponse.matchingAddresses__c = matchingAddressesJSON;
        validatedAddressResponseList.add(validationResponse);
        // 4. Org address - successful validation
        validationResponse = new ValidatedAddress__e();
        validationResponse.recordId__c          = orgAccList[0].Id;
        validationResponse.AddressType__c       = ValidatedAddressTriggerHandler.ADDRTYPE.PrimaryAddress.name();
        validationResponse.matchesFound__c      = true;
        validationResponse.requestId__c         = orgAccList[0].AddressValidationReqId__c;
        validationResponse.matchingAddresses__c = matchingAddressesJSON;
        validatedAddressResponseList.add(validationResponse); 
        // 5. Org address - no match
        validationResponse = new ValidatedAddress__e();
        validationResponse.recordId__c          = orgAccList[1].Id;
        validationResponse.AddressType__c       = ValidatedAddressTriggerHandler.ADDRTYPE.PrimaryAddress.name();
        validationResponse.matchesFound__c      = true;
        validationResponse.requestId__c         = orgAccList[1].AddressValidationReqId__c;
        validationResponse.matchingAddresses__c = unmatchesAddressJSON;
        validatedAddressResponseList.add(validationResponse); 
        // 6. Org address - request id doesn't match
        validationResponse = new ValidatedAddress__e();
        validationResponse.recordId__c          = orgAccList[2].Id;
        validationResponse.AddressType__c       = ValidatedAddressTriggerHandler.ADDRTYPE.PrimaryAddress.name();
        validationResponse.matchesFound__c      = true;
        validationResponse.requestId__c         = 'WRONG_REQUEST_ID';
        validationResponse.matchingAddresses__c = matchingAddressesJSON;
        validatedAddressResponseList.add(validationResponse);
        // 7. Location address - successful validation
        validationResponse = new ValidatedAddress__e();
        validationResponse.recordId__c          = locationList[0].Id;
        validationResponse.AddressType__c       = ValidatedAddressTriggerHandler.ADDRTYPE.PrimaryAddress.name();
        validationResponse.matchesFound__c      = true;
        validationResponse.requestId__c         = locationList[0].AddressValidationReqId__c;
        validationResponse.matchingAddresses__c = matchingAddressesJSON;
        validatedAddressResponseList.add(validationResponse);  
        // 8. Location address - no match
        validationResponse = new ValidatedAddress__e();
        validationResponse.recordId__c          = locationList[1].Id;
        validationResponse.AddressType__c       = ValidatedAddressTriggerHandler.ADDRTYPE.PrimaryAddress.name();
        validationResponse.matchesFound__c      = false;
        validationResponse.requestId__c         = locationList[1].AddressValidationReqId__c;
        validatedAddressResponseList.add(validationResponse); 
        // 9. Location address - request id doesn't match
        validationResponse = new ValidatedAddress__e();
        validationResponse.recordId__c          = locationList[2].Id;
        validationResponse.AddressType__c       = ValidatedAddressTriggerHandler.ADDRTYPE.PrimaryAddress.name();
        validationResponse.matchesFound__c      = true;
        validationResponse.requestId__c         = 'WRONG_REQUEST_ID';
        validationResponse.matchingAddresses__c = matchingAddressesJSON;
        validatedAddressResponseList.add(validationResponse);
        // Publish event
        Test.startTest();
        EventBus.publish(validatedAddressResponseList);
        Test.stopTest();
        // --------------------------------------------
        // Verify results
        // --------------------------------------------
        personAccList = 
            [SELECT Id, AddressValidationStatus__c
            FROM Account
            WHERE Id IN :personAccList
            ORDER BY AddressValidationReqId__c];
        // 1. Person residential address - successful validation 
        System.assertEquals(ValidatedAddressTriggerHandler.CONST_STATUS_ADDRESS_MATCH_FOUND, personAccList[0].AddressValidationStatus__c);
        // 2. Person residential address - no match
        System.assertEquals(ValidatedAddressTriggerHandler.CONST_STATUS_NO_ADDRESS_MATCH_FOUND, personAccList[1].AddressValidationStatus__c);
        // 3. Person residential address - no updates as request id didn't match
        System.assertNotEquals(ValidatedAddressTriggerHandler.CONST_STATUS_ADDRESS_MATCH_FOUND, personAccList[2].AddressValidationStatus__c);
        System.assertNotEquals(ValidatedAddressTriggerHandler.CONST_STATUS_NO_ADDRESS_MATCH_FOUND, personAccList[2].AddressValidationStatus__c);
        orgAccList = 
            [SELECT Id, AddressValidationStatus__c
            FROM Account
            WHERE Id IN :orgAccList
            ORDER BY AddressValidationReqId__c];
        // 4. Org address - successful validation
        System.assertEquals(ValidatedAddressTriggerHandler.CONST_STATUS_ADDRESS_MATCH_FOUND, orgAccList[0].AddressValidationStatus__c);
        // 5. Org address - no match
        System.assertEquals(ValidatedAddressTriggerHandler.CONST_STATUS_NO_ADDRESS_MATCH_FOUND, orgAccList[1].AddressValidationStatus__c);
        // 6. Org address - no updates as request id didn't match
        System.assertNotEquals(ValidatedAddressTriggerHandler.CONST_STATUS_ADDRESS_MATCH_FOUND, orgAccList[2].AddressValidationStatus__c);
        System.assertNotEquals(ValidatedAddressTriggerHandler.CONST_STATUS_NO_ADDRESS_MATCH_FOUND, orgAccList[2].AddressValidationStatus__c);
        locationList = 
            [SELECT Id, AddressValidationStatus__c
            FROM Location
            WHERE Id IN :locationList
            ORDER BY AddressValidationReqId__c];
        // 7. Location address - successful validation    
        System.assertEquals(ValidatedAddressTriggerHandler.CONST_STATUS_ADDRESS_MATCH_FOUND, locationList[0].AddressValidationStatus__c);
        // 8. Location address - no match
        System.assertEquals(ValidatedAddressTriggerHandler.CONST_STATUS_NO_ADDRESS_MATCH_FOUND, locationList[1].AddressValidationStatus__c);
        // 9. Location address - no updates as request id didn't match
        System.assertNotEquals(ValidatedAddressTriggerHandler.CONST_STATUS_ADDRESS_MATCH_FOUND, locationList[2].AddressValidationStatus__c);
        System.assertNotEquals(ValidatedAddressTriggerHandler.CONST_STATUS_NO_ADDRESS_MATCH_FOUND, locationList[2].AddressValidationStatus__c);
    }
}