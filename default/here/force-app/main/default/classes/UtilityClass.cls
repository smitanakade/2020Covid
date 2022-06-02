/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : Class to hold commonly-used generic/utility methods. All the method in this class should be static
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 06/02/2021     Darko Jovanovic       Hotfix 258459 (Addition of dcUpsert method): Initial version
 * 11/02/2021     Darko Jovanovic       Hotfix 258342 (Incorporate custom merge rules): Added getAllFields method
**/
public class UtilityClass {

    /**
    * @description Gets all fields for the given SObjectApiName and returns them for use in SOQL queries (comma-delimited).
    * This method was originally created to cater for Duplicate Check merge, since ALL the fields need to be retrieved for the merge to work. 
    * @param SObjectApiName - SObject
    * @return String - string of comma-separated fields for use in a SOQL SELECT statement
    */
    public static string getAllFieldsForQuery(String SObjectApiName) {
        string allstring = string.join(getAllFields(SObjectApiName),',');
        return allstring;
    }
    
    /**
    * @description Gets all fields for the given SObjectApiName and returns them (as a List of Strings) 
    * @param SObjectApiName - SObject
    * @return List<String> - API field names
    */
    public static List<String> getAllFields(String SObjectApiName) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SObjectApiName).getDescribe().fields.getMap();

        List<String>apiNames = new List<String>();

        for(String apiName : fieldMap.keyset())
        {
            apiNames.add(apiName);
        }

        return apiNames;
    }

}