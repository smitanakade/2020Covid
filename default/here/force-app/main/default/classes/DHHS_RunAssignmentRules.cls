//*************************/
// Created By:  SFDC
// Created Date: 2 Oct 2020
// Story: DHSCT-1872
// Desc: Run the deaulft assignmet rules for case from a process builder.
/**************************/
public class DHHS_RunAssignmentRules {
    
  public class FlowInputs {
      @InvocableVariable public string caseId;
  }
    
  public class MyException extends Exception {}
  
  @InvocableMethod
  public static void DHHS_RunAssignmentRules(List<FlowInputs> request) {
         
      System.debug('***DHHS_RunAssignmentRules - START');
      string caseId = request[0].caseId;
      
      Database.DMLOptions dmo = new Database.DMLOptions();
      dmo.assignmentRuleHeader.useDefaultRule= true;          
      Case cse = [SELECT id,Subject from CASE where Id = :caseId];
      cse.setOptions(dmo);
      UPDATE cse;
      System.debug('***DHHS_RunAssignmentRules - END');
            
  }

            
}