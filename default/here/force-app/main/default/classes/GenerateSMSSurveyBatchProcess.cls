public class GenerateSMSSurveyBatchProcess implements Database.Batchable<sObject>{
    public final String query; 

    public GenerateSMSSurveyBatchProcess(){
        System.Debug('*** GenerateSMSSurveyBatchProcess()- 1.0'); 

        Map<String, Schema.RecordTypeInfo> mapCaseRecordTypes = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName();
		String closeContactRecordTypeId = mapCaseRecordTypes.get('Close Contact').getRecordTypeId();
		String confirmedRecordTypeId = mapCaseRecordTypes.get('COVID-19 Case Assessment').getRecordTypeId();
		String secondaryCloseContactRecordTypeId = mapCaseRecordTypes.get('Secondary Close Contact').getRecordTypeId();
		
        if(Test.isRunningTest()){
            query = 'SELECT Id, Status, Record_Age__c,Clearance_eligibility_assessment_date__c, Close_Contact_Record_Age__c,' +
					'Day_0_Exposure_to_primarycc__c, Permit_Type__c FROM Case WHERE '+
                    'Subject = \'Batch Test Case\' '+
                    'AND Account.PersonMobilePhone != null '+
                    'AND Account.PersonHasOptedOutOfSMS__c != true '+
                    'AND (Status = \'Quarantine\' OR  Status = \'Isolate\') '+
                    'AND AccountId != null '+
                    'AND (Record_Age__c != null OR Close_Contact_Record_Age__c != null OR Day_0_Exposure_to_primarycc__c != null) '+
                    'AND (RecordTypeId = \'' + closeContactRecordTypeId + '\' OR RecordTypeId = \'' + confirmedRecordTypeId + '\' OR RecordTypeId = \'' + secondaryCloseContactRecordTypeId + '\') LIMIT 10';

            System.Debug('*** GenerateSMSSurveyBatchProcess()- 2.0: query'+query);
        } 
		else {
            query = 'SELECT Id, Status, Record_Age__c,Clearance_eligibility_assessment_date__c, Close_Contact_Record_Age__c, Day_0_Exposure_to_primarycc__c, Permit_Type__c ' +
                    'FROM Case WHERE '+
                    'Account.PersonMobilePhone != null '+
                    'AND Account.PersonHasOptedOutOfSMS__c != true '+
                    'AND Enable_notification__c  = \'Yes\' '+
                    'AND (Status = \'Quarantine\' OR  Status = \'Isolate\' OR (Status = \'Identify\' AND Permit_Type__c = \'Red\')) '+
                    'AND AccountId != null '+
                    'AND (Record_Age__c != null OR Close_Contact_Record_Age__c != null OR Day_0_Exposure_to_primarycc__c != null) '+
                    'AND (RecordTypeId = \'' + closeContactRecordTypeId + '\' OR RecordTypeId = \'' + confirmedRecordTypeId + '\' OR RecordTypeId = \'' + secondaryCloseContactRecordTypeId + '\')';

                    
            System.Debug('*** GenerateSMSSurveyBatchProcess()- 3.0: query'+query);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator(query); 
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Case> listCaseUpdate = new List<Case>();
        for(sobject s : scope ){
			Case c = (Case)s;
			if(c.Permit_Type__c == 'Red' && c.Close_Contact_Record_Age__c >= 25) {
				c.Status = 'Closed';
				listCaseUpdate.add(c);
			}
			else {
				GenerateSMSSurvey.CreateSurveyInv((Case)s);
			}
        }
		
		if(listCaseUpdate.size() > 0)
			update listCaseUpdate;
    }
    
    //Any post processing steps here
    public void finish(Database.BatchableContext BC){ 
    }
}