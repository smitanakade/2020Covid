/*
 * @Author             : Jiten Joysar
 * @Description        : DHHS Custom List view controller fetch records
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 18/11/2020     Jiten Joysar          Initial version
*/
public without sharing class DHHS_CustomListViewDataTableController {
    
    /********************************************************************/
    /* Function to query records from Database based on parrameters 
        passed in String seperated by '-' */
    /********************************************************************/
    @AuraEnabled( cacheable = true )  
    public static List <sObject> fetchRecs(String listValues) {  
        
        List < String > strList = listValues.split( '-' ); 
        String strObject = strList.get(0);
        String strFields = strList.get(1);
        String strRelatedField = strList.get(2);
        String strRecordId;
        String orderBy, recordLimit, additionalFilter ;
        DateTime additionalFilterValue;
       
        if (strList.size() == 8){
            strRecordId = strList.get(3);
            orderBy = strList.get(4);
            recordLimit = strList.get(5);
            additionalFilter =  strList.get(6);
            if(strList.get(7) != null && strList.get(7) != 'undefined')
                additionalFilterValue =  DateTime.newInstance(long.valueOf(strList.get(7)));
        }   
        
        List < sObject > listRecs = new List < sObject >();
        String strSOQL = 'SELECT Id, ' + strFields + ' FROM ' + strObject;

        if (String.isNotBlank(strRecordId)){
            strSOQL  += ' WHERE ' + strRelatedField+ ' = \'' + strRecordId + '\'';
            
            if (String.isNotBlank(additionalFilter) && additionalFilter != 'undefined' && additionalFilter == 'StartTime' && additionalFilterValue != null){
                DateTime startDateTime = additionalFilterValue;
                DateTime endDateTime = additionalFilterValue.addDays(1);
                String additionalFilterValueDate = string.valueof(additionalFilterValue).subString(0,10);
                // String additionalFilterValueDate = additionalFilterValue.format('yyy-MM-dd'); //strSOQL  += ' AND DAY_ONLY(StartTime)' + ' = ' + additionalFilterValueDate;
                strSOQL  += ' AND (StartTime >='+ startDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')+') AND (StartTime < ' + endDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')+')'; 
            }
        }  
        
        // Additional Record type filter
        String movementRecordTypeId = Schema.SObjectType.ContactEncounter.getRecordTypeInfosByName().get('Movement').getRecordTypeId();
        if(strObject == 'ContactEncounter')
            strSOQL += ' AND RecordTypeId = '+ '\'' + movementRecordTypeId + '\'';
        
        if (String.isNotBlank(orderBy) && orderBy != 'undefined')
            strSOQL  += ' ORDER BY '+orderBy+' DESC NULLS LAST ';

        if (String.isNotBlank(recordLimit) && recordLimit != 'undefined')
            strSOQL += ' LIMIT '+recordLimit;
        else    
            strSOQL += ' LIMIT 25';
        
        system.debug( 'SOQL is ' + strSOQL );
        listRecs = Database.query( strSOQL );
        return listRecs;
    } 
}