/**
 * @Author             : Xiang Zheng
 * @Description        : Duplicate Check Delta trigger handler
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 15/10/2021     Xiang Zheng       PBI 320275: Merge fix - Priority for non-negatives
**/
public class DuplicateCheckDeltaTriggerHandler extends TriggerHandler{
    public override void beforeInsert() {
        //handlePriority(Trigger.new);
    }

/*
    //update dupcheck__Priority__c field, base on Case or Account DC_queue_priority__c field, if the field is empty, then check the case, if positive set 1, otherwise set 10
    private static void handlePriority(List<dupcheck__dcDelta__c> newDCD) {

        List<ID> caseIdList = new List<ID>();
        List<ID> accountIdList = new List<ID>();
        Map<String,Integer> resultMap = new Map<String,Integer>();

        //get related case and account id list
        for(dupcheck__dcDelta__c dcd: newDCD){
            if(dcd.dupcheck__object__c != null){
                if(dcd.dupcheck__object__c.startsWith('001')){
                    accountIdList.add(dcd.dupcheck__object__c);
                }else if(dcd.dupcheck__object__c.startsWith('500')){
                    caseIdList.add(dcd.dupcheck__object__c);
                }
            }
        }

        //get case, check the DC_queue_priority__c field and record type, if the record type is 'COVID-19 Case Assessment' then it is positive
        if(!caseIdList.isEmpty()){
            List<Case> caseList = [SELECT Id,RecordType.Name,DC_queue_priority__c FROM Case WHERE Id = :caseIdList];

            for(Case ca: caseList){
                Integer thePriority = 10;
                if(ca.DC_queue_priority__c != null){
                    thePriority = Integer.valueOf((Decimal)ca.DC_queue_priority__c);
                }else if(ca.RecordType.Name == 'COVID-19 Case Assessment'){
                    thePriority = 1;
                }

                resultMap.put(ca.Id, thePriority);
            }
        }

        //get account, check the DC_queue_priority__c field
        if(!accountIdList.isEmpty()){
            List<Account> accList = [SELECT Id,DC_queue_priority__c FROM Account WHERE Id = :accountIdList];

            for(Account acc: accList){
                Integer thePriority = 10;
                if(acc.DC_queue_priority__c != null){
                    thePriority = Integer.valueOf((Decimal)acc.DC_queue_priority__c);
                }
                resultMap.put(acc.Id, thePriority);
            }
        }

        for(dupcheck__dcDelta__c dcd: newDCD){
            dcd.dupcheck__Priority__c = resultMap.get(dcd.dupcheck__object__c);
        }
    }
	*/
}