/**
 * @Author             : Darko Jovanovic
 * @Description        : UserTriggerHandler 
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author                Details
 * ---------------------------------------------------
 * 12/12/2020     Darko Jovanovic       Initial version
 * 25/06/2021     Hemant Singh          Bugfix 293522: replacing the Process builder "Provision Marketing User"
 * 24/08/2021     Hemant Singh          Bugfix 293522: method to run only on before insert
**/

public with sharing class UserTriggerHandler {
    public static Boolean mutePSGAsssignment;
    private static Id healthWorkerProf;
         
    //Events
    public void run() {
        healthWorkerProf = 
            [SELECT Id 
            FROM Profile 
            WHERE Name = 'Health Worker' LIMIT 1].Id;
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
            BeforeInsert(trigger.new);
        }
        if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
            AfterInsert(trigger.new);
        }
    }

    //Extension of the Events which contain the methods
    //Before insert
    private void BeforeInsert(List<User> userList) {
        addDefaultRole(userList);
        addDefaultCallCenter(userList); // Genesys Cloud implementation
        if(trigger.isInsert){
        addMarketingUser(userList); // Provision Marketing user //Bugfix 293522
        }
    }

    //After insert
    private void AfterInsert(List<User> userList) {
        if(StaticCommon.runPermissionTrigger)
        {
            addHCPermissionSets(userList);
            addDHHSEPIAccessPermSet(userList); //242230 - to add DHHS EPI Access PS
        }
        StaticCommon.enablePermissionTrigger();
    }

    // 242230,244511 -  This method adds/removes "DHHS EPI Access" permission set to users with Role "Clinical" OR "Epidemiologist"
    private static void addDHHSEPIAccessPermSet(List<User> userList) {
        // get the right roles
        Map<Id, UserRole> rolesMap = new Map<Id, UserRole>([SELECT Id, Name FROM UserRole WHERE Name ='Clinical' OR Name='Epidemiologist']);
        // get the right perm set
        List<PermissionSet> DHHSEPIAccessPS = [SELECT Id FROM PermissionSet WHERE Name = 'DHHS_EPI_Access' LIMIT 1];

        if(DHHSEPIAccessPS.isEmpty()) return;       // if perm set is not found, no point proceeding further

        // this is to check who all this perm set is already assigned
        List<PermissionSetAssignment> DHHSEpiAccessAssignments = [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment 
                                                                    WHERE PermissionSetId =: DHHSEPIAccessPS[0].Id AND AssigneeId IN: userList];
        Set<Id> currentPSAssignees = new Set<Id>();
        for (PermissionSetAssignment psAssignment : DHHSEpiAccessAssignments) {
            currentPSAssignees.add(psAssignment.AssigneeId);
        }
                
        Map<Id, PermissionSetAssignment> assigneeVsPSMap = new Map<Id, PermissionSetAssignment>();
        for(PermissionSetAssignment psa : DHHSEpiAccessAssignments) {
            assigneeVsPSMap.put(psa.AssigneeId, psa);
        }

        List<PermissionSetAssignment> newPSAssignments = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> invalidPSAssignments = new List<PermissionSetAssignment>();
        //loop through the users list
        for(User currentUser: userList) {
            if(null != currentUser.UserRoleId && rolesMap.containsKey(currentUser.UserRoleId) &&        //do they have the right role?
                currentUser.isActive &&                                                                 //are they active?
                !currentPSAssignees.contains(currentUser.Id)) {                                         //is the PS not assigned already?
                    // generated the assignment
                    PermissionSetAssignment DHHSEPIAccessAssignment = new PermissionSetAssignment(
                                                                            PermissionSetId = DHHSEPIAccessPS[0].Id,
                                                                            AssigneeId = currentUser.Id);
                newPSAssignments.add(DHHSEPIAccessAssignment);

            } else if(!rolesMap.containsKey(currentUser.UserRoleId) && null != assigneeVsPSMap.get(currentUser.Id)) {                                  // the role is not right but still have that PS?
                invalidPSAssignments.add(assigneeVsPSMap.get(currentUser.Id));                          // then that is invalid assignment, mark for removal
            }
        }
        // insert the assignement
        if(!newPSAssignments.isEmpty()) {
            insert newPSAssignments;
        }

        // delete invalid assignement
        if(!invalidPSAssignments.isEmpty()) {
            delete invalidPSAssignments;
        }
    }
    
    /**Add Health Cloud Permissions:
     * 1. Adding Permission set licenses needed (HealthCloud, HealthCloud Platform and Messaging User)
     * 2. Add the permission sets (In this case its the Permission Set Group + 2 Permission sets)
     *  a. LiveMessaging Permission Set
     *  b. Messaging User Permission Set
     */
    //after trigger
    public static void addHCPermissionSets(List<User> userList)
    {

        // Set of user Ids. This is needed so we only retrieve Permission Sets for the users affected rather than everyone. If we don't, we could hit governor limits.  
        Set<Id> userIds = new Set<Id>();
        for (User u : userList)
        {
            userIds.add(u.Id);
        }

        //List to add the assignments.
        List<PermissionSetAssignment> newPR = new List<PermissionSetAssignment>();
        List<PermissionSetLicenseAssign> newPRL = new List<PermissionSetLicenseAssign>();

        //PermissionSets + PermissionSet Group
        Id hcpermissionGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Health_worker_group' LIMIT 1].Id;
       /* commenting liveMessagingPermissionSet , messagingUserPermissionSet as a part of BUG295340
        Id liveMessagingPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'LiveMessage' LIMIT 1].Id;
        Id messagingUserPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Messaging_User' LIMIT 1].Id;*/
        Id hcContactTracerPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'HealthCloud_ContactTracer' LIMIT 1].Id; //TODO
        Id hcFoundationPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'HealthCloudFoundation' LIMIT 1].Id; //TODO
        Id hcPermissionSetLicensePermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'HealthCloudPermissionSetLicense' LIMIT 1].Id; //TODO
        Id hcStandardPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'HealthCloudStandard' LIMIT 1].Id; //TODO

        //Permission Set Licenses
        Id healthCloudPlatformPslId = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'HealthCloudPlatformPsl' LIMIT 1].Id;
        Id healthCloudGAHealthCloudPslId = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'HealthCloudGA_HealthCloudPsl' LIMIT 1].Id;
       /* commenting liveMessagingPermissionSet , messagingUserPermissionSet as a part of BUG295340
        Id liveMessageUserPslId = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'LiveMessageUserPsl' LIMIT 1].Id;*/



        //Get all the PermissionSetAssignments for all active Health Workers
        List<PermissionsetAssignment> existingPSAsHealthCloudGroupPs = [SELECT AssigneeId FROM PermissionSetAssignment WHERE 
                                                                         Assignee.Profile.Name = 'Health Worker' AND Assignee.isActive = true
                                                                         AND PermissionSetGroupId = :hcpermissionGroup
                                                                         AND AssigneeId IN :userIds];
        /* commenting liveMessagingPermissionSet , messagingUserPermissionSet as a part of BUG295340
        List<PermissionsetAssignment> existingPSAsLiveMessagingPs = [SELECT AssigneeId FROM PermissionSetAssignment WHERE 
                                                                         Assignee.Profile.Name = 'Health Worker' AND Assignee.isActive = true
                                                                         AND PermissionSetId = :liveMessagingPermissionSet
                                                                         AND AssigneeId IN :userIds];
                                                            
        List<PermissionsetAssignment> existingPSAsMessagingUserPs = [SELECT AssigneeId FROM PermissionSetAssignment WHERE 
                                                                         Assignee.Profile.Name = 'Health Worker' AND Assignee.isActive = true
                                                                         AND PermissionSetId = :messagingUserPermissionSet
                                                                         AND AssigneeId IN :userIds];*/

        List<PermissionsetAssignment> existingPSAsHcContactTracerPs = [SELECT AssigneeId FROM PermissionSetAssignment WHERE 
                                                                         Assignee.Profile.Name = 'Health Worker' AND Assignee.isActive = true
                                                                         AND PermissionSetId = :hcContactTracerPermissionSet
                                                                         AND AssigneeId IN :userIds];                                                                 
        
        List<PermissionsetAssignment> existingPSAsHcFoundationPs = [SELECT AssigneeId FROM PermissionSetAssignment WHERE 
                                                                         Assignee.Profile.Name = 'Health Worker' AND Assignee.isActive = true
                                                                         AND PermissionSetId = :hcFoundationPermissionSet
                                                                         AND AssigneeId IN :userIds]; 

        List<PermissionsetAssignment> existingPSAsHcPermissionSetLicensePs = [SELECT AssigneeId FROM PermissionSetAssignment WHERE 
                                                                         Assignee.Profile.Name = 'Health Worker' AND Assignee.isActive = true
                                                                         AND PermissionSetId = :hcPermissionSetLicensePermissionSet
                                                                         AND AssigneeId IN :userIds]; 

        List<PermissionsetAssignment> existingPSAsHcStandardPs = [SELECT AssigneeId FROM PermissionSetAssignment WHERE 
                                                                         Assignee.Profile.Name = 'Health Worker' AND Assignee.isActive = true
                                                                         AND PermissionSetId = :hcStandardPermissionSet
                                                                         AND AssigneeId IN :userIds]; 

        //Get all PermissionSetLicenseAssign for all active Health Workers
        List<PermissionSetLicenseAssign> existingPSLAsHealthCloudPlatformPsl = [SELECT AssigneeId FROM PermissionSetLicenseAssign WHERE 
                                                                                Assignee.Profile.Name = 'Health Worker' AND Assignee.isActive = true
                                                                                AND PermissionSetLicenseId = :healthCloudPlatformPslId
                                                                                AND AssigneeId IN :userIds];

        List<PermissionSetLicenseAssign> existingPSLAsHealthCloudGAHealthCloudPsl = [SELECT AssigneeId FROM PermissionSetLicenseAssign WHERE 
                                                                                     Assignee.Profile.Name = 'Health Worker' AND Assignee.isActive = true
                                                                                     AND PermissionSetLicenseId = :healthCloudGAHealthCloudPslId
                                                                                     AND AssigneeId IN :userIds];
        /* commenting liveMessagingPermissionSet , messagingUserPermissionSet as a part of BUG295340
        List<PermissionSetLicenseAssign> existingPSLAsLiveMessageUserPsl = [SELECT AssigneeId FROM PermissionSetLicenseAssign WHERE 
                                                                            Assignee.Profile.Name = 'Health Worker' AND Assignee.isActive = true
                                                                            AND PermissionSetLicenseId = :liveMessageUserPslId
                                                                            AND AssigneeId IN :userIds];*/

        
        //Get all Assignee Ids from PermissionSetAssignments
        Set<Id> existingAssigneeIdsHealthCloudGroupPs = new Set<Id>();
        for (PermissionsetAssignment psa: existingPSAsHealthCloudGroupPs) {
            existingAssigneeIdsHealthCloudGroupPs.add(psa.AssigneeId);
        }
        /* commenting liveMessagingPermissionSet , messagingUserPermissionSet as a part of BUG295340
        Set<Id> existingAssigneeIdsLiveMessagingPs = new Set<Id>();
        for (PermissionsetAssignment psa: existingPSAsLiveMessagingPs) {
            existingAssigneeIdsLiveMessagingPs.add(psa.AssigneeId);
        }
        Set<Id> existingAssigneeIdsMessagingUserPs = new Set<Id>();
        for (PermissionsetAssignment psa: existingPSAsMessagingUserPs) {
            existingAssigneeIdsMessagingUserPs.add(psa.AssigneeId);
        }   */
        Set<Id> existingAssigneeIdsHcContactTracerPs = new Set<Id>();
        for (PermissionsetAssignment psa: existingPSAsHcContactTracerPs) {
            existingAssigneeIdsHcContactTracerPs.add(psa.AssigneeId);
        }  
        Set<Id> existingAssigneeIdsHcFoundationPs = new Set<Id>();
        for (PermissionsetAssignment psa: existingPSAsHcFoundationPs) {
            existingAssigneeIdsHcFoundationPs.add(psa.AssigneeId);
        }  
        Set<Id> existingAssigneeIdsHcPermissionSetLicensePs = new Set<Id>();
        for (PermissionsetAssignment psa: existingPSAsHcPermissionSetLicensePs) {
            existingAssigneeIdsHcPermissionSetLicensePs.add(psa.AssigneeId);
        }  
        Set<Id> existingAssigneeIdsHcStandardPs = new Set<Id>();
        for (PermissionsetAssignment psa: existingPSAsHcStandardPs) {
            existingAssigneeIdsHcStandardPs.add(psa.AssigneeId);
        }       
        
        
        //Get all Assignee Ids from PermissionSetLicenseAssigns
        Set<Id> existingAssigneeIdsHealthCloudPlatformPsl = new Set<Id>();
        for (PermissionSetLicenseAssign psla: existingPSLAsHealthCloudPlatformPsl) {
            existingAssigneeIdsHealthCloudPlatformPsl.add(psla.AssigneeId);
        }
        Set<Id> existingAssigneeIdsHealthCloudGAHealthCloudPsl = new Set<Id>();
        for (PermissionSetLicenseAssign psla: existingPSLAsHealthCloudGAHealthCloudPsl) {
            existingAssigneeIdsHealthCloudGAHealthCloudPsl.add(psla.AssigneeId);
        }
        /* commenting liveMessagingPermissionSet , messagingUserPermissionSet as a part of BUG295340
        Set<Id> existingAssigneeIdsLiveMessageUserPsl = new Set<Id>();
        for (PermissionSetLicenseAssign psla: existingPSLAsLiveMessageUserPsl) {
            existingAssigneeIdsLiveMessageUserPsl.add(psla.AssigneeId);
        }
*/

        
        
       
        ////System.debug('Permissionse userL:' + usersNoPermission.Size());

        for(User currentUser: userList)
        {
            if(currentUser.ProfileId == healthWorkerProf && currentUser.isActive)
            {
                
                //PF 16 Oct 2020 added to do a licence check
                PermissionSetLicense LMpsl = [select Id, DeveloperName, UsedLicenses, TotalLicenses from PermissionSetLicense where DeveloperName = 'LiveMessageUserPsl' LIMIT 1];
                Integer T = LMpsl.TotalLicenses;
                Integer U = LMpsl.UsedLicenses;
                               
                /**
                 *  Adding PermissionSetLicenseAssignments (total 3) to the List to then push
                 */

                //Check and assign HealthCloudGAHealthCloudPsl
                if (!existingAssigneeIdsHealthCloudGAHealthCloudPsl.contains(currentUser.Id))
                {
                    //System.debug('Assigning PSL ' + healthCloudGAHealthCloudPslId + ' for user ' + currentUser.Id);
                    newPRL.add(new PermissionSetLicenseAssign
                    (
                        PermissionSetLicenseId = healthCloudGAHealthCloudPslId,
                        AssigneeId = currentUser.Id
                    ));
                }

                //Check and assign healthCloudPlatformPsl
                if (!existingAssigneeIdsHealthCloudPlatformPsl.contains(currentUser.Id))
                {
                    //System.debug('Assigning PSL ' + healthCloudPlatformPslId + ' for user ' + currentUser.Id);
                    newPRL.add(new PermissionSetLicenseAssign
                    (
                        PermissionSetLicenseId = healthCloudPlatformPslId,
                        AssigneeId = currentUser.Id
                    ));
                }
                /* commenting liveMessagingPermissionSet , messagingUserPermissionSet as a part of BUG295340
                //Check and assign liveMessageUserPslId
                if (!existingAssigneeIdsLiveMessageUserPsl.contains(currentUser.Id) && (U < T))
                {
                    //System.debug('Assigning PSL ' + liveMessageUserPslId + ' for user ' + currentUser.Id);
                    newPRL.add(new PermissionSetLicenseAssign
                    (
                        PermissionSetLicenseId = liveMessageUserPslId,
                        AssigneeId = currentUser.Id
                    ));
                }*/

                /**
                 * Adding PermissionsetAssignments to the List to then push
                 */
                //Add Permission set GROUP
                //System.debug('Permissionset group: '+ hcpermissionGroup);
                if (!existingAssigneeIdsHealthCloudGroupPs.contains(currentUser.Id) && mutePSGAsssignment != true)  //mute due to SF bug with PSG deployment and not changing status to Updated before the end of the unit test start.
                {
                    PermissionSetAssignment psga = new PermissionSetAssignment
                    (
                        PermissionSetGroupId = hCpermissionGroup,
                        AssigneeId = currentUser.Id
                    );
                    newPR.add(psga);
                }
                /* commenting liveMessagingPermissionSet , messagingUserPermissionSet as a part of BUG295340
                //Check and assign Live Messaging PSA
                if (!existingAssigneeIdsLiveMessagingPs.contains(currentUser.Id) && (U < T))
                {
                    PermissionSetAssignment psLiveMessagingAssignment = new PermissionSetAssignment
                    (
                        PermissionSetId = liveMessagingPermissionSet,
                        AssigneeId = currentUser.Id
                    );
                    newPR.add(psLiveMessagingAssignment);
                }

                //Check and assign Messaging User PSA
                if (!existingAssigneeIdsMessagingUserPs.contains(currentUser.Id) && (U < T))
                { 
                    PermissionSetAssignment psMessagingUserAssignment = new PermissionSetAssignment
                    (
                        PermissionSetId = messagingUserPermissionSet,
                        AssigneeId = currentUser.Id
                    );
                    newPR.add(psMessagingUserAssignment);
                }
*/
                //Check and assign Health Cloud Contact Tracer PSA
                if (!existingAssigneeIdsHcContactTracerPs.contains(currentUser.Id))
                {
                    //System.debug('Assigning PS ' + hcContactTracerPermissionSet + ' for user ' + currentUser.Id);
                    newPR.add(new PermissionSetAssignment
                    (
                        PermissionSetId = hcContactTracerPermissionSet,
                        AssigneeId = currentUser.Id
                    ));
                }

                //Check and assign Health Cloud Foundation PSA
                if (!existingAssigneeIdsHcFoundationPs.contains(currentUser.Id))
                {
                    //System.debug('Assigning PS ' + hcFoundationPermissionSet + ' for user ' + currentUser.Id);
                    newPR.add(new PermissionSetAssignment
                    (
                        PermissionSetId = hcFoundationPermissionSet,
                        AssigneeId = currentUser.Id
                    ));
                }

                //TODO 
                //Check and assign Health Cloud Permission Set License PSA
                if (!existingAssigneeIdsHcPermissionSetLicensePs.contains(currentUser.Id))
                {
                    //System.debug('Assigning PS ' + hcPermissionSetLicensePermissionSet + ' for user ' + currentUser.Id);
                    newPR.add(new PermissionSetAssignment
                    (
                        PermissionSetId = hcPermissionSetLicensePermissionSet,
                        AssigneeId = currentUser.Id
                    ));
                }

                //TODO
                //Check and assign Health Cloud Standard
                if (!existingAssigneeIdsHcStandardPs.contains(currentUser.Id))
                {
                    //System.debug('Assigning PS ' + hcStandardPermissionSet + ' for user ' + currentUser.Id);
                    newPR.add(new PermissionSetAssignment
                    (
                        PermissionSetId = hcStandardPermissionSet,
                        AssigneeId = currentUser.Id
                    ));
                }


            /**
             * If the user is inactive remove the permission set group (LATER)
             */
            }else if (!currentUser.isActive)
            {
                //TODO
                //+live messaging
                //for later
            }
        }
        //System.debug('newPR: '+ newPR + '\n new PRL: '+ newPRL);
        /** Order of addinng:
         * 1. Permission Set license
         * 2. Permission Sets
         */
        insert newPRL;
        insert newPR;

        //System.debug('Successful PR');
    }

    //before trigger
    public static void addDefaultRole(List<User> userList)
    {
         //Variable Declaration
         Id URoleId = [SELECT ID,Name,DeveloperName from UserRole WHERE DeveloperName = 'CCOM_Officer' LIMIT 1].Id;


         //List<User> newUpdates = new List<User>();


        for(User currentUser: userList)
        {
            //System.debug('About to test if: '+ currentUser.ProfileId + ' | '+ healthWorkerProf);
            if(currentUser.ProfileId == healthWorkerProf && currentUser.isActive)
            {
                //System.debug('Role ID1: ' + currentUser.UserRoleId);
                if(currentUser.UserRoleId == null)
                {
                    currentUser.UserRoleId = URoleId;
                    //System.debug('Role ID2: ' + currentUser.UserRoleId);
                    //newUpdates.add(currentUser);
                }
            }
        }
    }

    // Genesys Cloud implementation - begin
    // Default in Genesys Lightning Call Center for every Health Worker user created
    public static void addDefaultCallCenter(List<User> userList)
    {
        List<CallCenter> callCenterList = 
            [SELECT Id 
            FROM CallCenter 
            WHERE InternalName = 'PureCloudForSalesforceLightning' LIMIT 1];
        Id callCenterId;
        if (!callCenterList.isEmpty()) {
            callCenterId = callCenterList[0].Id;
        }
        for(User currentUser: userList)
        {
            if(currentUser.ProfileId == healthWorkerProf && currentUser.isActive)
            {
                if(currentUser.CallCenterId == null)
                {
                    currentUser.CallCenterId = callCenterId;
                }
            }
        }
    }
    // Genesys Cloud implementation - end

    // Provision Marketing User 
    // This method is replacing the Process builder "Provision Marketing User" as part of PBI 293522
    public static void addMarketingUser(List<User> userList)
    {
         
         //Get the right roles: CCOM or below
        Map<Id, UserRole> MarketingUserRolesMap = new Map<Id, UserRole>([SELECT Id, Name FROM UserRole WHERE DeveloperName ='CCOM' OR DeveloperName='Agent' OR DeveloperName='CCOM_Lead' OR DeveloperName='Health_Direct_Lead' OR DeveloperName='CCOM_Officer' OR DeveloperName='Health_Direct_Officer' OR DeveloperName='Aspen' OR DeveloperName='Fullerton']);

        for(User currentUser: userList)
        {
            if(currentUser.isActive) 
            {
                if(MarketingUserRolesMap.containsKey(currentUser.UserRoleId))
                {
                    currentUser.UserPermissionsMarketingUser = true;
                }
            }
        }
    }

}