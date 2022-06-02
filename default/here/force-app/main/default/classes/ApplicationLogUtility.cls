/**
* @Author             : Darko Jovanovic (Contino)
* @Description        : Class to hold commonly-used generic/utility methods. All the method in this class should be static
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author      		    Details
* ---------------------------------------------------
* 06/02/2021     Darko Jovanovic       Hotfix 258459 (Addition of dcUpsert method): Initial version
* 11/02/2021     Darko Jovanovic       Hotfix 258342 (Incorporate custom merge rules): Added getAllFields method
* 27/09/2021	 Lija Jawahar		   Updated created logmethod and custom metadta type
**/
public class ApplicationLogUtility {
    
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
    
    /*
     * To Log the errors use this 
     * ApplicationLogUtility.createlog('ClassName','MethodName',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
     */
    public static void createlog(string classname, string methodname, string stacktrace, string message , string type){
        
        // Fetch Application Log interface 
        Map<String, Application_Log_Reference__mdt> Allreferencecodes = Application_Log_Reference__mdt.getAll();
       
        // appLog = newlog 
        Application_Log__c appLog = new Application_Log__c();
        
        appLog.Stack_Trace__c = stacktrace;
        appLog.Transaction_Date__c = system.now();
        appLog.User_Details__c = string.valueof(UserInfo.getUserId());
        appLog.Source_Function__c = methodname;
        appLog.Source__c = classname;
        appLog.Message__c = message;
        if(Allreferencecodes!= null){
            for(Application_Log_Reference__mdt ALR : Allreferencecodes.values()){
                if(type == ALR.masterlabel){
                    appLog.Severity__c = ALR.error_severity__c;
                    appLog.Reference_Id__c = string.valueof(ALR.error_code__c) ;
                    appLog.Reference_Info__c = type; 
                } else {
                    appLog.Severity__c = 'Low';
                    appLog.Reference_Id__c = '000' ;
                    appLog.Reference_Info__c = 'Other'; 
                }
            }
        } 
        
        insert appLog;
        
    }
    
}