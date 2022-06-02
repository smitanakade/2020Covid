/**
** Created By : Swarnaja Nathani(snathani@deloitte.com)
** Functionality : Entered string can be search in single/multiple fields of SObject and return results which users wants to display
** History : Tertiary condition operator added to the dynamic query
**/
public with sharing class DLWC_TypeAheadController 
{
    /**
* Aura enabled method to search a specified SObject for a specific string and display information of required field.   added for testing
*/
    @AuraEnabled
    public static List <sObject> fetchLookUpValues(String searchString, String sObjectAPIName,string searchField,string displayField,string recordCount, string recordType, string recordTypeIds)
    {
        if(recordCount ==null || recordCount==''){
            recordCount ='10';
        }
        
        // Sanitze the input
        String sanitizedSearchString = String.escapeSingleQuotes(searchString);
        String sanitizedSObjectAPIName = String.escapeSingleQuotes(sObjectAPIName);
        
        List<sObject> results = new List<sObject>();
        
        // Build our SOSL query
        string searchQuery='';
        if(searchField !=null){
            List<string> lstSearchFields = searchField.Split(',');
            if(sObjectAPIName == 'Case'){
                if(displayField !=null && displayField !='Name'){
                    searchQuery= 'Select Id,'+displayField+' from ';
                } else{
                    searchQuery= 'Select Id from ';
                }
            } 
            else if(sObjectAPIName == 'Location'){
                if(displayField !=null && displayField !='Name'){
                searchQuery= 'Select Name, Id,  Location_Severity__c,'+displayField+' from '; //332422
                }
                else{
                    searchQuery= 'Select Id from ';
                }
            }
            else if(displayField !=null && displayField !='Name'){
                if(!Test.isRunningTest()) {searchQuery= 'Select Name,id,'+ (!lstSearchFields.contains('Name') ? 'Full_Name__c,' : '') +displayField+' from ';}
                else searchQuery= 'Select Name,id,'+displayField+' from ';
            } else {
                if(!Test.isRunningTest()) searchQuery= 'Select Name,id,Full_Name__c from ';
                else searchQuery= 'Select Name,id from ';
            }
            searchQuery=searchQuery+sObjectAPIName;
            for(integer i=0;i<lstSearchFields.size();i++){
                String val='\'%' + String.escapeSingleQuotes(searchString.trim()) + '%\'';
                if(i==0){
                    searchQuery=searchQuery+' where ('+lstSearchFields[i]+' LIKE '+val;
                }else{
                    searchQuery=searchQuery+' OR '+lstSearchFields[i]+' LIKE '+val;
                }
            }
            searchQuery=searchQuery+ ')';

            if(recordType != '' && recordType != null && recordType != 'null' ){
                searchQuery=searchQuery+' AND RecordType.DeveloperName = \''+ recordType + '\'';
            }
            else if(recordTypeIds != '' && recordTypeIds != null){
                List<String> listRecordTypeIds = new List<String>();
                Set<String> setRecordTypeIds = new set<string>();
                if(recordTypeIds.contains(',')){
                    listRecordTypeIds.addAll(recordTypeIds.split(','));
                    setRecordTypeIds.addAll(listRecordTypeIds);
                }
                else{
                    setRecordTypeIds.add(recordTypeIds);
                }
                searchQuery=searchQuery+' AND RecordTypeId IN: setRecordTypeIds ORDER BY RecordType.Name ASC';
            }
            
            if(sObjectAPIName == 'Case'){
                searchQuery=searchQuery+ ' AND AccountId != null ';
            }
            searchQuery=searchQuery+' Limit '+recordCount; 
            results =Database.query(searchQuery);
        } else {
            searchQuery = 'FIND \'' + sanitizedSearchString + '*\' IN ALL FIELDS RETURNING ' + sanitizedSObjectAPIName + '(id,name) Limit '+recordCount; 
            List<List<SObject>> searchList = search.query(searchQuery);
            results = searchList[0]; 
        }
        
        return results;
    }
    
}