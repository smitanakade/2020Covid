/*
Created by: Rahul Ankireddypalli

@Modification Log   :
---------------------------------------------------
Date           Author      		    Details
08/06/2021     Rahul Ankireddypalli Feature 270261: added getEmailFromGroup method
---------------------------------------------------
*/
public class BusinessUnitHelper {
 
    /**
     * Pass Error Message to the Business Unit Record whenever there is no corresponding emailId to the Queue Name
     * @param Business_Unit__c
     */
    Public static List<Group> grpEmail = new List<Group>([select id,name,email from Group where Type='Queue' and email = Null]);
    Public static List<Group> allQueues = new List<Group>([select id,name,email from Group where Type='Queue']);
    /**
     * getEmailFromGroup Method is used to check if the queue name or Reroute Queue Name has corresponding Email id in Group object if not this method 
     * will throw an error message
     */
    public static void getEmailFromGroup(List<Business_Unit__c> BusinessUnits) 
    {

        boolean validRec = true;
        boolean validQueue = false;
        boolean validRerouteQueue = false;
        if (BusinessUnits != Null) {
            //List<String> queueNames = new List<String>();
            for(Business_Unit__c businessUnitRec : BusinessUnits)
            {
                for(Group grpRec : allQueues)
                {

                    if(allQueues != Null)
                    {
                        if(BusinessUnitRec.Queue_Name__c.contains(grpRec.Name))
                        {
                           // BusinessUnitRec.Queue_Name__c.addError('Please Enter a Valid Queue Name');
                            validQueue = true;
                        }
                        if(BusinessUnitRec.Reroute_Queue_Name__c.contains(grpRec.Name))
                        {
                           // BusinessUnitRec.Reroute_Queue_Name__c.addError('Please Enter a valid Reroute Queue Name');
                            validRerouteQueue = true;
                        }       
                    }
                }
                if(validQueue || validRerouteQueue)
                {
                    if(!validQueue)
                    {
                        BusinessUnitRec.Queue_Name__c.addError('Please Enter a Valid Queue Name');   
                        validRec = false;
                    }
                    if(!validRerouteQueue)
                    {
                        BusinessUnitRec.Reroute_Queue_Name__c.addError('Please Enter a valid Reroute Queue Name');
                        validRec = false;
                    }

                    if(!validQueue && !validRerouteQueue)
                    {
                        
                        BusinessUnitRec.Queue_Name__c.addError('Please Enter a Valid Queue Name'); 
                        BusinessUnitRec.Reroute_Queue_Name__c.addError('Please Enter a valid Reroute Queue Name');
                        validRec = false;
                    }
                }
                for(Group grpEmailRec : grpEmail)
                {
                    if(grpEmail != Null && validRec)
                    {
                        if(BusinessUnitRec.Queue_Name__c.contains(grpEmailRec.Name))
                        {
                            BusinessUnitRec.Queue_Name__c.addError('Queue Name doesnot have a corresponding Email id in Group object');
                        }
                        if(BusinessUnitRec.Reroute_Queue_Name__c.contains(grpEmailRec.Name))
                        {
                            BusinessUnitRec.Reroute_Queue_Name__c.addError('Reroute Queue Name doesnot have a corresponding Email id in Group Object');
                        }
                    }
                }
            }
        }
    }
}