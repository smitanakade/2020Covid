//*************************/
// Created By:  SFDC
// Created Date: 2 Oct 2020
// Story: DHSCT-1158
// Desc:  
// Invocable method called by process builder to set the milestone completion date on case or WorkOrder
/**************************/
public class DHHS_CompleteMilestone {
    
    public class FlowInputs {
        @InvocableVariable (label='Case or WorkOrder' description='Enter either Case or WorkOrder' required=true)
        public string strObject;
        @InvocableVariable (label='recordId' description='recordId of Case or WorkOrder' required=true)
        public string recordId;
        @InvocableVariable (label='milestoneName' description='name of milestone to complete' required=true)
        public string milestoneName;
        @InvocableVariable (label='completionDate' description='completion date' required=true)
        public DateTime completionDate;        
    }
      
    public class MyException extends Exception {}
    
      @InvocableMethod
      public static void DHHS_CompleteMilestone(List<FlowInputs> request) {

          System.debug('***DHHS_CompleteMilestone - START');
          for (FlowInputs input : request) {
              string milestoneEntity = input.strObject;
              string recId = input.recordId;
              string mlstnName = input.milestoneName;
              DateTime cmpDate = input.completionDate;
              System.debug('***DHHS_CompleteMilestone - milestoneEntity:' + milestoneEntity + ' recId:' + recId + ' mlstnName:' + mlstnName + ' cmpDate:' + cmpDate);

              List<CaseMilestone> cmsToUpdate = new List<CaseMilestone>();
              List<EntityMilestone> emsToUpdate = new List<EntityMilestone>();
              Integer caseCounter=0;
              Integer woCounter=0;

              if (milestoneEntity == 'Case') {
                  caseCounter++;
                  cmsToUpdate = [
                          select Id, completionDate
                          from CaseMilestone cm
                          where caseId = :recId and cm.MilestoneType.Name = :mlstnName
                          and completionDate = null
                          limit 1
                  ];

                  if (cmsToUpdate.isEmpty() == false) {
                      for (CaseMilestone cm : cmsToUpdate) {
                          cm.completionDate = cmpDate;
                      }
                      update cmsToUpdate;
                  } else {
                      System.debug('***DHHS_CompleteMilestone - No CaseMilestones found.');
                  }

              } else if (milestoneEntity == 'WorkOrder') {
                  woCounter++;
                  emsToUpdate = [
                          select Id, completionDate
                          from EntityMilestone em
                          where ParentEntityId = :recId and em.Name = :mlstnName
                          and completionDate = null
                          limit 1
                  ];

                  if (emsToUpdate.isEmpty() == false) {
                      for (EntityMilestone em : emsToUpdate) {
                          em.completionDate = cmpDate;
                      }
                      update emsToUpdate;
                  } else {
                      System.debug('***DHHS_CompleteMilestone - No WorkOrderMilestones (EntityMilestone) found.');
                  }

              }

              if (woCounter > 1)
                System.debug('***woCounter:'+woCounter);
              else if (caseCounter > 1)
                System.debug('***woCounter:'+woCounter);

              System.debug('***DHHS_CompleteMilestone - END woCounter:');

          }
      }
  }