/**
 * @Author             : YPerera
 * @Description        : Utils class for common utility methods in TREVI
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 11/10/2021     YPerera		        Created
**/
public class SystemUtils {
    
    private static Schema.DescribeFieldResult getFieldSchema(String objectAPIName, String fieldAPIName) {
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectAPIName);
        Schema.DescribeSObjectResult r = s.getDescribe();
        Map<String,Schema.SObjectField> fields = r.fields.getMap();
        return fields.get(fieldAPIName).getDescribe();
    }

    public static List<Schema.PicklistEntry> getPickListValuesInObject(String objectAPIName, String fieldAPIName) {
        return getFieldSchema(objectAPIName, fieldAPIName).getPicklistValues();  
    }
    
    @AuraEnabled
    public static String getPickListValuesInObjectAsJSON(String objectAPIName, String fieldAPIName) {
        return JSON.serialize(SystemUtils.getPickListValuesInObject(objectAPIName, fieldAPIName));
    }
    
    @AuraEnabled
    public static Map<String, String> getPickListValuesInObjectAsMap(String objectAPIName, String fieldAPIName) {
        Map<String, String> results = new Map<String, String>();
        List<Schema.PicklistEntry> entries = SystemUtils.getPickListValuesInObject(objectAPIName, fieldAPIName);
        for (Schema.PicklistEntry entry : entries) {
            results.put(entry.getLabel(), entry.getValue());
        }
        return results;
    }
    
    @AuraEnabled
    public static String getFieldLabelInObject(String objectAPIName, String fieldAPIName) {
        return getFieldSchema(objectAPIName, fieldAPIName).getLabel();  
    }
    
    @AuraEnabled
    public static String getSobjectRecordFieldValue(String objectAPIName, String fieldAPIName, String recordid) {
        String result;
        try {
            if (objectAPIName != null && fieldAPIName != null && recordid != null) {
                String q = 'SELECT ' + fieldAPIName + ' FROM ' + objectAPIName + ' WHERE Id = \'' + recordid + '\'';
                result = (String)Database.query(q).get(0).get(fieldAPIName);
            }
        } catch (Exception e) {  }
        return result;
        
    }
    
    @AuraEnabled
    public static String getSobjectRecordFieldValueFromRelatedObject(String childObjectAPIName, String parentObjectAPIName, String relationshipfieldAPIName, String fieldAPIName, String recordid) {
        String result;
        try {
            String q1 = getSobjectRecordFieldValue(childObjectAPIName, relationshipfieldAPIName, recordid);
            result = getSobjectRecordFieldValue(parentObjectAPIName, fieldAPIName, q1);

        } catch (Exception e) {  }
        return result;
        
    }

}