/**
 * @description       : Advanced Search Service
 * @author            : CRM Squad 2
 * @group             : CRM Squad 2
 * @last modified on  : 02-10-2021
 * @last modified by  : Phase 3 team1
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   11-17-2020   CRM Squad 2   Initial Version
 * 2.0   02-10-2021   Phase 3 team1   Search utility enhancement - added Search based on Middlename, Email , homephone and recordtype
 * 2.1   29-11-2021   Phase 3 team1   Search utility enhancement - added Search result for EHR observations
**/
public with sharing class AdvancedSearchService {

    public static final String SEARCH_TYPE_INDIVIDUAL = 'Individual';

    /**
    * @description search using payload
    * @author CRM Squad 2 | 12-10-2020 
    * @param payload 
    * @param recLimit 
    * @param searchType 
    * @return list<Object> 
    **/
    @AuraEnabled(Cacheable = true)
    public static list<Object> search(String payload, String recLimit, String searchType) {

        system.debug('payload -->'+payload);
    list<Object> searchResults = new list<Object>();
    
    SearchCriteria criteria = (SearchCriteria) JSON.deserialize(payload, SearchCriteria.class);

    try{

        if(SEARCH_TYPE_INDIVIDUAL.equalsIgnoreCase(searchType)){
            searchResults =  searchIndividualRecords(criteria,recLimit);
        }

    }catch(Exception exp){
        ApplicationLogUtility.createlog('AdvancedSearchService','Search',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
        throw new CustomException('Error occured during search: '+exp.getMessage());
    }

    return searchResults;
    }


    /**
    * @description search Individual Records
    * @author CRM Squad 2 | 12-10-2020 
    * @param criteria 
    * @param recLimit 
    * @return list<Case> 
    **/
    private static list<Case> searchIndividualRecords(SearchCriteria criteria, String recLimit){

        String searchQuery = 'SELECT ID, CaseNumber, RecordType.Name, Status, Event_Date__c, Account.FirstName, AccountId, Account.LastName,Account.MiddleName, Account.PersonMobilePhone, Account.PersonBirthdate, Account.Address_Text__pc,Latest_Test_Date_Time__c,Latest_EHR_Observation__c, Latest_EHR_Observation__r.Name FROM Case';

        Integer limitBy;
        //construct filters
        List<String> filters = new List<String>();
    
        if (String.isNotBlank(criteria.recordNumber)) {
            filters.add('CaseNumber like \'%'+  String.escapeSingleQuotes(criteria.recordNumber)+'%\'');
        }
        if(String.isNotBlank(criteria.firstName)) {
            filters.add('Account.FirstName like \'%'+ String.escapeSingleQuotes(criteria.firstName)+'%\'');
        }
        if(String.isNotBlank(criteria.middleName)) {
            filters.add('Account.middleName like \'%'+ String.escapeSingleQuotes(criteria.middleName)+'%\'');
        }
        if(String.isNotBlank(criteria.lastName)) {
            filters.add('Account.LastName like \'%'+ String.escapeSingleQuotes(criteria.lastName)+'%\'');
        }
        if(String.isNotBlank(criteria.dateOfBirth)) {
            Date dob = Date.valueOf(criteria.dateOfBirth);
            filters.add('Account.PersonBirthdate = :dob');
        }
        //PersonMobilePhone
        if(String.isNotBlank(criteria.mobile)) {
            filters.add('Account.PersonMobilePhone like \'%'+ String.escapeSingleQuotes(criteria.mobile)+'%\'');
        }
        //PersonhomePhone
        if(String.isNotBlank(criteria.homePhone)) {
            filters.add('Account.PersonHomePhone like \'%'+ String.escapeSingleQuotes(criteria.homePhone)+'%\'');
        }
        //Personemail
        if(String.isNotBlank(criteria.email)) {
            filters.add('Account.PersonEmail like \'%'+ String.escapeSingleQuotes(criteria.email)+'%\'');
        }
    
       //Account recordtype
       filters.add('Account.recordtype.Name=\'Person Account\' ' );

        //selectedrecordTypes
        if(criteria.selectedrecordTypes!= null ) {
            List<Object> rList = (List<Object>) JSON.deserializeUntyped(criteria.selectedrecordTypes);
            if(rList.Size()>0){
                String queryFilter = '(';
                for(Object obj :rList){
                    queryfilter = queryfilter +'\''+ String.escapeSingleQuotes((String)obj)+'\' ,';
                }
                queryFilter= queryFilter.left(queryFilter.length()-1)+')';
                filters.add('RecordType.DeveloperName IN '+queryFilter);
            } else {
                filters.add('RecordType.DeveloperName IN (\'Close_Contact\',\'COVID_19_Case_Assessment\',\'Secondary_Close_Contact\',\'Casual_Contact\',\'Acquisition_Contact\',\'Unclassified_Contact\')');
            }
        }
       
        if(filters.size() > 0) {
            searchQuery = searchQuery+' WHERE';
            for(Integer f=0; f<filters.size(); f++) {
                searchQuery = searchQuery + ' ' + filters.get(f);
                if(f != filters.size()-1) {
                    searchQuery = searchQuery + ' AND';
                }
            }
        }
        if(String.isNotBlank(recLimit)){
            //inrease the limit by 1 to understand if more results available. UI should remove last record before display
            limitBy = Integer.valueOf(recLimit)+1;
        }
        searchQuery += ' WITH SECURITY_ENFORCED Order by CreatedDate Desc LIMIT '+limitBy;
        System.debug('Search Query is :'+searchQuery);
        return Database.query(searchQuery);
    }


    public class SearchCriteria {
        @AuraEnabled
        public String recordNumber;
        @AuraEnabled
        public String firstName; 
        @AuraEnabled
        public String lastName;
        @AuraEnabled
        public String middleName;
        @AuraEnabled
        public String dateOfBirth;
        @AuraEnabled
        public String mobile;
        @AuraEnabled
        public String homePhone;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String selectedrecordTypes;
      }

    //Custom Exception class
    public class CustomException extends Exception {
    
    }
}