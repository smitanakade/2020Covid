/**
 * Created by marcelo.cost on 18/2/21.
 */

public interface IQueueProcess {

    void setCase(Case acase);
    void setAllocationRules(List <Queue_Allocation__c> queueAllocations, boolean casequeueprocessvirtualcheck);
    void setdefaultAllocationRules(List <Queue_Allocation__c> defaultqueueAllocations);
	void setBusinessUnits(List <Business_Unit__c> businessunits);
    Queue_Allocation__c checkForMatchOnAllocationRule();
    void assignOwnerForCaseBasedOnRule(Queue_Allocation__c rule);
    Boolean execute();
}