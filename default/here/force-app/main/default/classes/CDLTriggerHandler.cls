/* @Author             : Ashwin Kumar
* @Description        : Content note trigger
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 20/09/2021     Ashwin Kumar       Feature 321911: copy workorder notes over to case
* 22/10/2021	Krishna Suram 		330244:Unable to add a note to multiple records at one time
**/


public class CDLTriggerHandler extends TriggerHandler {
    static Boolean woNotecreated = false;
    static Boolean csNotecreated = false;
    public override void afterInsert() {
        
        System.debug('one');
        try{
            Set<Id> setWO = new Set<Id>();
            Set<Id> setC = new Set<Id>();
            
            //Map<Id,Id> mapCsDoc = new Map<Id,Id>();
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            List<ContentDocumentLink> cdlList1 = new List<ContentDocumentLink>();
            for (ContentDocumentLink cdl: (List<ContentDocumentLink>)Trigger.new){
                String id = cdl.LinkedEntityId;
                String id1 = cdl.Id;
                //if notes is on work order
                if (id.substring(0,3) == '0WO' && !csNotecreated) {
                    System.debug('two');
                    setWO.add(cdl.LinkedEntityId);
                    woNotecreated = true;
                    
                } 
                //if notes is on case
                if (id.substring(0,3) == '500' && !woNotecreated) {
                    System.debug('two case');
                    setC.add(cdl.LinkedEntityId);
                    csNotecreated = true;
                    
                } 
                
            }
            if (setWO!=null){
                //copy work order notes to case
                System.debug('inside one');
                List<WorkOrder> lstWO = [select Id,CaseId from WorkOrder where id in: setWO];
                Map<Id,Id> mapCs = new Map<Id,Id>();
                Map<Id,Id> mapCs1 = new Map<Id,Id>();
                Map<Id,Id> mapCs2 = new Map<Id,Id>();
                for (ContentDocumentLink note: (List<ContentDocumentLink>)trigger.new){
                    for (WorkOrder cs: lstWO){
                        mapCs.put(cs.Caseid,note.LinkedEntityId);
                        mapCs1.put(note.LinkedEntityId,cs.CaseId);
                        mapCs2.put(note.LinkedEntityId,note.Id);
                        System.debug('inside gghgghg');
                        
                    }
                }
                for (ContentDocumentLink note: (List<ContentDocumentLink>)trigger.new){
                    System.debug('aghgraoreg');
                    if (note.Id.equals(mapCs2.get(note.LinkedEntityId))){
                        String id1 = note.LinkedEntityId;
                        if (id1.substring(0,3) == '0WO') {
                            System.debug('insdidgegeegeg');
                            ContentDocumentLink newFrCs = new ContentDocumentLink();
                            newFrCs.ContentDocumentId = note.ContentDocumentId;
                            
                            newFrCs.LinkedEntityId = mapCs1.get(note.LinkedEntityId);
                            System.debug('five');
                            cdlList.add(newFrCs);
                        }
                    }
                }
                
                if (!cdlList.isEmpty()){
                    System.debug('three');
                    Database.insert(cdlList);
                }
                
                
            }
            
            
            
            
            if (setC!=null){
                //copy case notes to interview work order
                System.debug('inside one case');
                List<Case> lstCS = [select Id,(select id from Workorders where caseid in: setC and recordtype.developername ='Interview') from Case where id in: setC];
                Map<Id,Id> mapCsa = new Map<Id,Id>();
                Map<Id,Id> mapCsa1 = new Map<Id,Id>();
                Map<Id,Id> mapCsa2 = new Map<Id,Id>();
                for (ContentDocumentLink note: (List<ContentDocumentLink>)trigger.new){
                    for (Case cs: lstCS){
                        for (Workorder wo : cs.Workorders){
                            mapCsa.put(wo.Id,note.LinkedEntityId);
                            mapCsa1.put(note.LinkedEntityId,wo.Id);
                            mapCsa2.put(note.LinkedEntityId,note.Id);
                            System.debug('inside gghgghgaa');
                        }
                        
                    }
                }
                for (ContentDocumentLink note: (List<ContentDocumentLink>)trigger.new){
                    System.debug('aghgraoreg'+note.LinkedEntityId);
                    // System.debug('aghgraoreg'+note.);
                    if (note.Id.equals(mapCsa2.get(note.LinkedEntityId))){
                        String id1 = note.LinkedEntityId;
                        if (id1.substring(0,3) == '500') {
                            System.debug('insdidgegeegeg');
                            ContentDocumentLink newFrCs1 = new ContentDocumentLink();
                            
                            newFrCs1.LinkedEntityId = mapCsa1.get(note.LinkedEntityId);
                            newFrCs1.ContentDocumentId = note.ContentDocumentId;
                            System.debug('@@@@five'+note.ContentDocumentId);
                            cdlList1.add(newFrCs1);
                            System.debug('aggg'+cdlList1[0].linkedentityid);
                        }
                    }
                }
                
                if (!cdlList1.isEmpty()){
                    System.Debug('@@@@'+cdlList1);
                    Database.insert(cdlList1, false);
                    System.Debug('@@@@++++'+cdlList1);
                    
                }
            }
        }
        
        
        catch(Exception ex){
            System.debug(ex.getMessage());
            System.debug(ex.getLineNumber());
            throw ex;
        }
    }
    
    
}