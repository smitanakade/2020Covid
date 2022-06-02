//*************************/
// Created By:  SFDC
// Created Date: 2 Oct 2020
// Story: DHSCT-1158
// Desc:  
// Invocable method called by process builder to set the milestone completion date
/**************************/
public class DHHS_CompleteCaseMilestone {
    
  public class FlowInputs {
      @InvocableVariable public string caseId;
      @InvocableVariable public string milestoneName;
      @InvocableVariable public DateTime completionDate;        
  }
    
  public class MyException extends Exception {}
  
  @InvocableMethod
  public static void DHHS_CompleteCaseMilestone(List<FlowInputs> request) {
         
      System.debug('***DHHS_CompleteCaseMilestone - START');
      string caseId = request[0].caseId;
      string mlstnName = request[0].milestoneName;
      DateTime cmpDate = request[0].completionDate;
      
       
      List<CaseMilestone> cmsToUpdate = [select Id, completionDate
                                         from CaseMilestone cm
                                         where caseId = :caseId and cm.MilestoneType.Name=:mlstnName 
                                         and completionDate = null limit 1];
      if (cmsToUpdate.isEmpty() == false){
          for (CaseMilestone cm : cmsToUpdate){
              cm.completionDate = cmpDate;
          }
          update cmsToUpdate;
      }
      
      System.debug('***DHHS_CompleteCaseMilestone - START');
      
    
  }

            
}