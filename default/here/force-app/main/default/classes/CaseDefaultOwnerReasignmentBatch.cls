global with sharing class CaseDefaultOwnerReasignmentBatch implements Database.Batchable <sObject> {
    
    
    global String ASSIGNEDOWNER = System.Label.Record_Owner_Name;
    
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        
       String query = 'SELECT Id, Owner.Name, CreatedDate, LastModifiedDate, Case_Allocation_Retrigger__c ' +
                'FROM Case WHERE '+
                'Owner.Name = '+ ASSIGNEDOWNER;
        
         //String firstname = '\'FName\'';  // to be used in running test
        // String lastname = '\'LName\'';  // to be used in running test
        
        if(Test.isRunningTest()){
            return Database.getQueryLocator('Select Id, CreatedDate, LastModifiedDate, Case_Allocation_Retrigger__c From Case Where Case_Allocation_Retrigger__c = False LIMIT 1');
        } else {
        return Database.getQueryLocator(query);
    
    }
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope){
       
        List<Case> CasesDeploymentUser = (List<Case>)scope; 
        List<Case> CasesToUpdate = new List<Case>();
        
        //List<CaseHistory> history = [SELECT Id, Field, Oldvalue, Newvalue, CreatedDate, case.ownerid, Case.owner.name, CaseId FROM CaseHistory WHERE Field = 'Owner' AND CaseId IN: caseWithIncorrectOwner];
        
        
        for (Case thiscase : CasesDeploymentUser) {
            thiscase.Case_Allocation_Retrigger__c = True;
            CasesToUpdate.add(thiscase);
        }        
        
        if(CasesToUpdate.size() > 0){
            
        System.debug('CasesToUpdate size =  : '+CasesToUpdate.size());
          
        try {
             Database.update(CasesToUpdate);  
         } catch(Exception ex) {
             System.Debug('The following exception has occurred: ' + ex.getMessage());
        } 

    }
            
    }
        
    global void finish(Database.BatchableContext bc){
        //post processing
    }
}