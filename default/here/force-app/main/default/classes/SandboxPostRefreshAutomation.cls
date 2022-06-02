/**
* @Author             : Krishna Suram
* @Description        : PBI : 307906 SandboxPostRefreshAutomation used to automate some of the manual tasks to be done after sandbox refresh
						
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author      		    Details
* ---------------------------------------------------
*/

global class SandboxPostRefreshAutomation implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {
        System.debug('Org ID: ' + context.organizationId());
        System.debug('Sandbox ID: ' + context.sandboxId());
        System.debug('Sandbox Name: ' + context.sandboxName());
        SandboxPostRefreshAutomation.createQAllocationForCaseRecordType();
        SandboxPostRefreshAutomation.createBusinessAccount();
        SandboxPostRefreshAutomation.deActivateusers();
        SandboxPostRefreshAutomation.inValidateQueueEmails();
        SandboxPostRefreshAutomation.deleteQueueMembers();
        SandboxPostRefreshAutomation.insertCaseEntitlement();
        SandboxPostRefreshAutomation.insertWorkOrderEntitlement();
        
    }
    
    // To Create Queue Allocation records
    Public static List<Queue_Allocation__c> createQAllocationForCaseRecordType(){
        
        //Set Data Queue Allocation - due to change from assignment rule to flow - US 240609
        Schema.DescribeSObjectResult caseSobjectDesc = Case.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> caseRecTypeInfoList = caseSobjectDesc.getRecordTypeInfos();
        
        List<Queue_Allocation__c> qaList  = new List<Queue_Allocation__c>();
        for(Integer i=0;i<caseRecTypeInfoList.size(); i++){
            Queue_Allocation__c qaRec = new Queue_Allocation__c(Record_Type__c = caseRecTypeInfoList.get(i).getName(), Sequence__c = i, Queue_Name__c='Team Six');
            qaList.add(qaRec);
        }
        
        insert qaList;
        return qaList;
    }
    
    /**
* @description create Account object Victorian Health Workers and DHHS Contact Tracing  record's
* 
* @return List<Account> 
**/
    public static List<Account> createBusinessAccount() {
        List<Account> accList = new List<Account>();
        try{ 
            
            Id brecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Place Or Organisation').getRecordTypeId();
            Id precordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
            Account account = new Account();
            
            account.RecordTypeId=brecordTypeId;
            
            account.Name  = 'Victorian Health Workers';
            
            account.Type ='Victorian Health Workers';
            
            accList.add(account);
            
            Account paccount = new Account();
            
            paccount.RecordTypeId= precordTypeId;
            
            paccount.FirstName  = 'DHHS Contact Tracing';
            paccount.LastName = 'DO NOT DELETE';
            paccount.PersonMailingPostalCode='12345'; 
            paccount.PersonMailingCity='SFO'; 
            paccount.PersonEmail='test@yahoo.com'; 
            paccount.PersonHomePhone='';
            paccount.PersonMobilePhone='+611234';
            accList.add(paccount);
            
            
            insert accList;
            
            return accList;
        }catch(Exception e){
     ApplicationLogUtility.createlog('SandboxPostRefreshAutomation','createBusinessAccount',e.getStackTraceString(),e.getMessage(),e.getTypeName());
            System.debug('exception '+e.getLineNumber());
            return accList;
        }
        
    }
    /* method used to de-activate all Non admin users after refresh
* 
*/ 
    @future
    public static void deActivateusers(){
        
        list<user> users = [SELECT Id, UserName, IsActive,ProfileId from User
                            WHERE Profile.Name = 'Health worker'
                            AND IsActive=true];
        
        system.debug('SIZE: '+users.size());
        for(User u:users){
            u.isActive=false;
            system.debug(u);
        }
        update users;
        
        
    }
       /* method used to  invalidate emails in queue to prevent notifications after refresh
		* 
		*/ 
    @future
    public static void inValidateQueueEmails(){
        List<group> AllQueue = [select id,name,email from group where type = 'Queue' and email != null];
        for(Group Q : AllQueue){
            if(Q.email != ''){
                Q.email = Q.email + '.invalid';
            }
        }
        update AllQueue;
    }
     /* method used to  delete queue memebers after refresh
		* 
		*/ 
    @future
    public static void deleteQueueMembers(){
        List<GroupMember> Allmembersincludingsubgroups = [select id, Group.name,Group.id,UserOrGroupId from GroupMember];
        List<GroupMember> memberstoberemoved = new List<GroupMember>();
        
        For(GroupMember GM : Allmembersincludingsubgroups){
            if(string.valueOf(GM.UserOrGroupId).startsWith('005')){
                memberstoberemoved.add(GM);
            }
        }
        Delete memberstoberemoved;
    }
    /* method used to  insert Case Entitlement's after refresh
		* 
		*/ 
    @future
    public static void insertCaseEntitlement(){
        try{
            
            
            List<Entitlement> caseEntList = [SELECT Id, Name, AccountId, StartDate, SlaProcessId, BusinessHoursId, Status FROM Entitlement where Name='Exposure Management' order by createddate desc];
            
            //get latest entitlement procees
            SlaProcess  caseslaproc = [SELECT Id, Name, IsActive, VersionNumber, IsVersionDefault, CreatedDate FROM SlaProcess where Name ='Exposure Management SLAs' and isActive=true and isVersionDefault = true order by createddate desc LIMIT 1];
            
            if(caseEntList.size()>0){
                Entitlement entitlement = caseEntList.get(0);
                entitlement.SlaProcessId = caseslaproc.Id;
                update entitlement;
            }else{
                //get business Hours
                BusinessHours  defaultHrs = [SELECT Id, Name FROM BusinessHours where Name='Default' order by createddate desc LIMIT 1];
                //Get common Acc
                Account dhhsAcc= [select Id, Name from Account where Name ='DHHS Contact Tracing DO NOT DELETE' order by createddate desc limit 1];
                
                Entitlement entitlement = New Entitlement(Name='Exposure Management',BusinessHoursId=defaultHrs.Id, SlaProcessId=caseslaproc.Id,AccountId=dhhsAcc.Id, StartDate=System.today());
                insert entitlement;
            }
        }catch(Exception e){
            System.debug('Exception'+e.getMessage());
            
        }
    }
    /* method used to  insert WorkOrder Entitlement's after refresh
		* 
		*/ 
    @future
    public static void insertWorkOrderEntitlement(){
        try{
            List<Entitlement> woentList = [SELECT Id, Name, AccountId, StartDate, SlaProcessId, BusinessHoursId, Status FROM Entitlement where Name='Exposure Management Referral' order by createddate desc];
            
            //get latest entitlement procees
            SlaProcess  woslaproc = [SELECT Id, Name, IsActive, VersionNumber, IsVersionDefault, CreatedDate FROM SlaProcess where Name ='Exposure Management Referral' and isActive=true and isVersionDefault = true order by createddate desc LIMIT 1];
            
            if(woentList .size()>0){
                Entitlement entitlement = woentList.get(0);
                entitlement.SlaProcessId = woslaproc.Id;
                update entitlement;
            }else{
                //get business Hours
                BusinessHours  defaultHrs = [SELECT Id, Name FROM BusinessHours where Name='Default' order by createddate desc LIMIT 1];
                //Get common Acc
                Account dhhsAcc= [select Id, Name from Account where Name ='DHHS Contact Tracing DO NOT DELETE' order by createddate desc limit 1];
                
                Entitlement entitlement = New Entitlement(Name='Exposure Management Referral',BusinessHoursId=defaultHrs.Id, SlaProcessId=woslaproc.Id,AccountId=dhhsAcc.Id, StartDate=System.today());
                insert entitlement;
            }    
            
            
            
        }catch(Exception exp){
        ApplicationLogUtility.createlog('SandboxPostRefreshAutomation','insertWorkOrderEntitlement',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            System.debug('Exception'+exp.getMessage());
            
        }
    }
    
}