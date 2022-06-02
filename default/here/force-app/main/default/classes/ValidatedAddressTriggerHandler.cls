/**
 * @Author             : Darko Jovanovic
 * @Description        : ValidatedAddressTrigger handler
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 12/12/2020     Darko Jovanovic       Feature 237555: ArcGIS integration - Initial version
 * 20/04/2021     Hemant Singh          Bugfix 270578: Consider Tied matching addresses with geocodeStatus "T" as sucessful matching.
**/

public class ValidatedAddressTriggerHandler {

    public enum ADDRTYPE {PrimaryAddress}
    public static final String CONST_STATUS_ADDRESS_MATCH_FOUND         = 'Successful';
    public static final String CONST_STATUS_NO_ADDRESS_MATCH_FOUND      = 'No Match';
    public static final Set<String> CONST_SUCCESS_MATCH_TYPES           = new Set<String>{'M','T'};
    public static final Double CONST_INVALID_ADDR_LATITUDE              = -39.0;
    public static final Double CONST_INVALID_ADDR_LONGITUDE             = 145.0;
    public static final Double CONST_INVALID_ADDR_QUALITY               = -1;
    public static final String CONST_INVALID_ADDR_LGA                   = 'Unknown Victoria';
    public static final String CONST_INVALID_ADDR_REGION                = 'Unknown Victoria';
    public static final String CONST_INVALID_ADDR_LGA_AUS               = 'Unknown';
    public static final String CONST_INVALID_ADDR_REGION_AUS            = 'Unknown';
    public static final String CONST_INVALID_ADDR_DIVISION              = 'West Division';

    @InvocableMethod
    public static void processValidatedAddresses(List<ValidatedAddress__e> validatedAddressEventList) {
        // -----------------------------------------------
        // Put addresses validation results in temporary maps
        // ----------------------------------------------- 
        // Map definitions
        Map<Id, Account> accountMap             = new Map<Id, Account>();
        Map<Id, Schema.Location> locationMap    = new Map<Id, Schema.Location>();
        // Go through each validation result and populate the maps
        for (ValidatedAddress__e event : validatedAddressEventList) {
            // Init result fields
            Id recordId                     = event.recordId__c;
            String addressType              = event.AddressType__c;
            Boolean matchingAddressesFound  = event.matchesFound__c;
            String requestId                = event.requestId__c;
            String matchingAddressesJSON    = event.matchingAddresses__c;
            String matchingAddressField = 'No matching address found.';
            Double latitude;
            Double longitude;
            String geocodeStatus;
            Double geocodeQuality;
            String matchType;
            String LGA;
            String region;
            String division;
            String addressValidationStatus = CONST_STATUS_NO_ADDRESS_MATCH_FOUND;
            System.debug('>>> recordId: ' + recordId);
            System.debug('>>> addressType: ' + addressType);
            System.debug('>>> matchingAddressesFound: ' + matchingAddressesFound);
            System.debug('>>> requestId: ' + requestId);
            System.debug('>>> matchingAddressesJSON: ' + matchingAddressesJSON);
            // Check if validation found at least one matching address
            if (matchingAddressesFound) {
                // Matching addresses found. Just in case, ensure the top address is a successful match. If not, technically it's not a match
                List<MatchingAddress> addresses = (List<MatchingAddress>) System.JSON.deserialize(matchingAddressesJSON, List<MatchingAddress>.class);
                MatchingAddress topMatch = addresses[0];
                geocodeStatus = topMatch.geocodeStatus;
                matchingAddressField = '';
                for (MatchingAddress adressMatch : addresses)
                {
                    matchingAddressField = matchingAddressField + 
                        (String.isBlank(adressMatch.street) ? '' : adressMatch.street + ', ') + 
                        (String.isBlank(adressMatch.city) ? '' : adressMatch.city + ' ') + 
                        (String.isBlank(adressMatch.state) ? '' : adressMatch.state + ' ') + 
                        (String.isBlank(adressMatch.postalCode) ? '' : adressMatch.postalCode + ' ') + 
                        (String.isBlank(adressMatch.country) ? '' : adressMatch.country) + '\n';
                }
                // If ArcGIS only matches against the country, then clearly it's a No Match
                Boolean countryMatchOnly = false;
                if ((String.isBlank(topMatch.street)) 
                    && (String.isBlank(topMatch.city))
                    && (String.isBlank(topMatch.state))
                    && (String.isBlank(topMatch.postalCode))) {
                    countryMatchOnly = true;
                }
                if (CONST_SUCCESS_MATCH_TYPES.contains(geocodeStatus) && (!countryMatchOnly)) {
                    // Successful address match - get the properties from the top matching address and all matching addresses
                    addressValidationStatus = CONST_STATUS_ADDRESS_MATCH_FOUND;
                    latitude        = topMatch.latitude;
                    longitude       = topMatch.longitude;
                    matchType       = topMatch.matchType;
                    geocodeQuality  = topMatch.geocodeQuality;
                    LGA             = topMatch.LGA;
                    region          = topMatch.region;
                    division        = topMatch.division;
                } else {
                    // Default in values for No Match
                    latitude        = CONST_INVALID_ADDR_LATITUDE;
                    longitude       = CONST_INVALID_ADDR_LONGITUDE;
                    geocodeQuality  = CONST_INVALID_ADDR_QUALITY;
                    division        = CONST_INVALID_ADDR_DIVISION;
                    if (countryMatchOnly) {
                        LGA             = CONST_INVALID_ADDR_LGA_AUS;
                        region          = CONST_INVALID_ADDR_REGION_AUS;
                    } else {
                        LGA             = CONST_INVALID_ADDR_LGA;
                        region          = CONST_INVALID_ADDR_REGION;
                    }
                }
            } else {
                // Default in values for No Match
                latitude        = CONST_INVALID_ADDR_LATITUDE;
                longitude       = CONST_INVALID_ADDR_LONGITUDE;
                geocodeQuality  = CONST_INVALID_ADDR_QUALITY;
                LGA             = CONST_INVALID_ADDR_LGA_AUS;
                region          = CONST_INVALID_ADDR_REGION_AUS;
                division        = CONST_INVALID_ADDR_DIVISION;
            }
            // Now that we've got the results, find out in which object/address fields to store them into and put them in the corresponding map
            Schema.DescribeSObjectResult sObjectType = recordId.getSObjectType().getDescribe();
            if (sObjectType == Schema.SObjectType.Account) {
                // ACCOUNT
                Account acc = new Account();
                acc.Id = recordId;
                acc.MatchingAddresses__c        = matchingAddressField;
                acc.AddressValidationStatus__c  = addressValidationStatus;
                acc.AddressLatitude__c          = latitude;
                acc.AddressLongitude__c         = longitude;
                acc.AddressGeocodeQuality__c    = geocodeQuality;
                acc.AddressMatchType__c         = matchType;
                acc.AddressValidationReqId__c   = requestId;
                acc.County__c                   = LGA;
                acc.VIC_Region__c               = region;
                acc.Official_Place__c           = division;
                accountMap.put(acc.Id, acc);
            } else if (sObjectType == Schema.SObjectType.Location) {
                // LOCATION
                Schema.Location loc = new Schema.Location();
                loc.Id                          = recordId;
                loc.MatchingAddresses__c        = matchingAddressField;
                loc.AddressValidationStatus__c  = addressValidationStatus;
                loc.AddressLatitude__c          = latitude;
                loc.AddressLongitude__c         = longitude;
                loc.AddressGeocodeQuality__c    = geocodeQuality;
                loc.AddressMatchType__c         = matchType;
                loc.AddressValidationReqId__c   = requestId;
                loc.County__c                   = LGA;
                loc.VIC_Region__c               = region;
                loc.Official_Place__c           = division;
                locationMap.put(loc.Id, loc);
            }
        }
        // -----------------------------------------------
        // Now, get the actual objects from the database and ensure the request id matches (to avoid race conditions). 
        // If it does, update it with the address validation results from the map
        // ----------------------------------------------- 
        if (!accountMap.isEmpty()) {
            List<Account> accountUpdateList = 
                [SELECT Id, AddressValidationReqId__c
                FROM Account
                WHERE Id IN :accountMap.keySet()];
            for (Account acc : accountUpdateList)
            {
                Account accFromMap = accountMap.get(acc.Id);
                if (acc.AddressValidationReqId__c == accFromMap.AddressValidationReqId__c) {
                    acc.MatchingAddresses__c        = accFromMap.MatchingAddresses__c;
                    acc.AddressValidationStatus__c  = accFromMap.AddressValidationStatus__c;
                    acc.AddressLatitude__c          = accFromMap.AddressLatitude__c;
                    acc.AddressLongitude__c         = accFromMap.AddressLongitude__c;
                    acc.AddressGeocodeQuality__c    = accFromMap.AddressGeocodeQuality__c;
                    acc.AddressMatchType__c         = accFromMap.AddressMatchType__c;
                    acc.County__c                   = accFromMap.County__c;
                    acc.VIC_Region__c               = accFromMap.VIC_Region__c;
                    acc.Official_Place__c           = accFromMap.Official_Place__c;
                }
            }
            update accountUpdateList;
        }
        if (!locationMap.isEmpty()) {
            List<Schema.Location> locationUpdateList = 
                [SELECT Id, AddressValidationReqId__c
                FROM Location
                WHERE Id IN :locationMap.keySet()];
            for (Schema.Location loc : locationUpdateList)
            {
                Schema.Location locFromMap = locationMap.get(loc.Id);
                if (loc.AddressValidationReqId__c == locFromMap.AddressValidationReqId__c) {
                    loc.MatchingAddresses__c        = locFromMap.MatchingAddresses__c;
                    loc.AddressValidationStatus__c  = locFromMap.AddressValidationStatus__c;
                    loc.AddressLatitude__c          = locFromMap.AddressLatitude__c;
                    loc.AddressLongitude__c         = locFromMap.AddressLongitude__c;
                    loc.AddressGeocodeQuality__c    = locFromMap.AddressGeocodeQuality__c;
                    loc.AddressMatchType__c         = locFromMap.AddressMatchType__c;
                    loc.County__c                   = locFromMap.County__c;
                    loc.VIC_Region__c               = locFromMap.VIC_Region__c;
                    loc.Official_Place__c           = locFromMap.Official_Place__c;
                }
            }
            update locationUpdateList;         
        }
    }

    // Class to match JSON result for matching addresses
    public class MatchingAddress {
		public String street;
		public String city;
		public String postalCode;
		public String state;
		public String country;
		public Double latitude;
		public Double longitude;
		public String geocodeStatus;
		public Double geocodeQuality;
        public String matchType;
        public String LGA;
        public String region;
        public String division;
    }
    
}