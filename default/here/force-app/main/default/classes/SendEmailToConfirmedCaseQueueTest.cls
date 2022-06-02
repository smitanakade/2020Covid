/**
 * @Author             : DHHS
 * @Description        : SendEmailToConfirmedCaseQueue test class
 * @Modification Log   :  
 * ---------------------------------------------------
 * Date           Author      		    Details 
 * ---------------------------------------------------
*09/11/2021		  Aref S			     PBI 309115 : Email Notification To LPHUs/Queue when a Confirmed Case is Auto-allocated from Informatics Queue 
**/

@isTest
private class SendEmailToConfirmedCaseQueueTest {
   
    @testSetup
    static void setupTestData() {
       
        // Create Person Account
        Account personAc1 = TestDataFactory.createAccount(1, 'Active','Person Account').get(0);
        // Create case for the person 
        TestDataFactory.createCases(personAc1, 3, 'Isolate', 'Close Contact');
       
    }

    
    @isTest
    static void testSentEmailQueue() {

        //Given
        List<Case> casesToUpdate = [SELECT Id, OwnerId FROM Case];

        List<User> users=[SELECT Id FROM User];
        Group queueGroup1 = [SELECT Id,Email FROM Group WHERE Type='Queue' AND Id=:casesToUpdate[0].OwnerId];
        if (String.isBlank(queueGroup1.Email))
        {
            queueGroup1.Email='testemail1@test.com';
            update queueGroup1;
        }
        

        // Group queueGroup1 = new Group(Name='queue group1', DeveloperName='queue_group1', Type='Queue',Email='TestEmail1@test.com');
        // insert queueGroup1;      

        // Group queueGroup2 = new Group(Name='queue group2', DeveloperName='queue_group2', Type='Queue',Email='TestEmail2@test.com');
        // insert queueGroup2;    

        // System.runAs(new User(Id=UserInfo.getUserId()))
        // {
            
            // List<QueuesObject> newQueueObjects=new List<QueuesObject>();
            // QueuesObject testQueue1 = new QueueSObject(QueueID = queueGroup1.id, SObjectType = 'Case');
            // insert testQueue1;            

            // QueuesObject testQueue2 = new QueueSObject(QueueID = queueGroup2.id, SObjectType = 'Case');       
            // insert testQueue2; 

            //When    
            for (Case cs:casesToUpdate) 
            {
                cs.Case_Classification__c='Confirmed';
            }
           
            // casesToUpdate[0].Case_Classification__c='Confirmed';

            // casesToUpdate[1].Case_Classification__c='Confirmed';

            // casesToUpdate[2].Case_Classification__c='Confirmed';
            // casesToUpdate[2].OwnerId=queueGroup1.Id;

        
            Test.startTest();
                
             update casesToUpdate;

            Test.stopTest();

        // }      
       
        //Then
        System.assertEquals(true, SendEmailToConfirmedCaseQueue.EmailSent,'Email not successful!');
    }


    // @isTest
    // static void testSentEmailQueueGroupss() {

    //     //Given
    //     List<Case> casesToUpdate = [SELECT Id, OwnerId FROM Case];

    //     List<User> users=[SELECT Id FROM User];

    //     Group queueGroup = new Group(Name='queue group', DeveloperName='queue_group', Type='Queue');
    //     insert queueGroup;

    //     Group testGroup1 = new Group(Name='test group', DeveloperName='test_group', Type='Regular');
    //     insert testGroup1;

    //     Group testGroup2 = new Group(Name='test 2 group', DeveloperName='test2_group', Type='Regular');
    //     insert testGroup2;

    //     System.runAs(new User(Id=UserInfo.getUserId()))
    //     {
    //         QueuesObject testQueue = new QueueSObject(QueueID = queueGroup.id, SObjectType = 'Case');
    //         insert testQueue;

    //         List<GroupMember> newGroupMembers=new List<GroupMember>();
    //         GroupMember testGroupMember1=new GroupMember(GroupId=testGroup1.id,UserOrGroupId=users[0].Id);
    //         newGroupMembers.add(testGroupMember1);

    //         GroupMember testGroupMember2=new GroupMember(GroupId=testGroup2.id,UserOrGroupId=users[1].Id);
    //         newGroupMembers.add(testGroupMember2);

    //         GroupMember queueMember1=new GroupMember(GroupId=queueGroup.id,UserOrGroupId=testGroup1.Id);
    //         newGroupMembers.add(queueMember1);           
            
    //         GroupMember queueMember2=new GroupMember(GroupId=queueGroup.id,UserOrGroupId=testGroup2.Id);
    //         newGroupMembers.add(queueMember2);    

    //         insert newGroupMembers; 
    //     }

    //     //When
    //     for(Case caseToUpdate:casesToUpdate)
    //     {
    //         caseToUpdate.Case_Classification__c='Confirmed';
    //         caseToUpdate.OwnerId=queueGroup.Id;
    //     }
    //     Test.startTest();
            
    //      update casesToUpdate;

    //     Test.stopTest();

    //     //Then
    //     System.assertEquals(true, SendEmailToConfirmedCaseQueue.EmailSent,'Email not successful!');
    // }

}
