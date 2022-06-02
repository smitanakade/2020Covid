/**
 * @Author             : Krishna Suram
 * @Description        : Set Account field on ContactEncounterParticipant 
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author              Details
 * ---------------------------------------------------
 * 31/10/2021     Krishna Suram        Initial version
 * 
**/

global class CEP_AccountFieldScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
		List < ContactEncounterParticipant > listCEP = [select id, Account__c, Record__r.accountid from ContactEncounterParticipant where Parent_Record__c != null and Record__c != null and record__r.accountid != null and account__c = null and createddate >= LAST_N_DAYS: 2 order by createddate];

		if (listCEP.size() > 0) {
			for (ContactEncounterParticipant cep: listCEP) {

				cep.Account__c = cep.Record__r.AccountId;

			}

			system.debug(listCEP.size());

			update listCEP;
		}
    }
}