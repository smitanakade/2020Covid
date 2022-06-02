/**
* @Author             : DHHS
* @Description        : contactPointAddressValidation 
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 29/08/2021     RAhul Ankireddypalli Feature 304103 : Pass Warning Message if ActiveToDate is not provided 
**/

public class ContactPointAddressValidation 
{
            @AuraEnabled
            public static String getMessage(string CPArecordId) 
            {

                string warningMsg;
                List<ContactPointAddress> CPArec = [select Id, parentId, ActiveToDate from ContactPointAddress where Id = :CPArecordId];
                List<ContactPointAddress> CPArecs = [select Id, ActiveToDate from ContactPointAddress where ParentId = : CPArec[0].parentId and ActiveToDate = Null];
            
                if (CPArecs.size() > 1 || (CPArecs.size() == 1 && CPArec[0].ActiveToDate != null))
                {
                    warningMsg = 'Please populate "Active To Date" in previous Contact Point Address entries if required';
                }
                else if(CPArecs.size() == 1 && CPArec[0].ActiveToDate == null)
                {
                    warningMsg = 'By not setting "Active To date", this address may be taken as current address'; 
                }
                 return warningMsg; 
            }
}