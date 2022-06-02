public with sharing class RelatedListController {
    public static final String FIELDS_PARAM = 'fields';
    public static final String NUMBER_OF_RECORDS_PARAM = 'numberOfRecords';
    public static final String RECORD_ID_PARAM = 'recordId';
    public static final String SOBJECT_API_NAME_PARAM = 'sobjectApiName';
    public static final String SOBJECT_LABEL_PARAM = 'sobjectLabel';
    public static final String SOBJECT_LABEL_PLURAL_PARAM = 'sobjectLabelPlural';
    public static final String PARENT_RELATIONSHIP_API_NAME_PARAM = 'parentRelationshipApiName';
    public static final String RELATED_FIELD_API_NAME_PARAM = 'relatedFieldApiName';
    public static final String SORTED_DIRECTION_PARAM = 'sortedDirection';
    public static final String SORTED_BY_PARAM = 'sortedBy';
    public static final String RECORDS_PARAM = 'records';
    public static final String ICON_NAME_PARAM = 'iconName';

    @AuraEnabled
    public static String initData(String jsonData){
        system.debug(jsonData);
        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(RECORDS_PARAM, getRecords(jsonData));
        
        String sobjectApiName = (String)requestMap.get(SOBJECT_API_NAME_PARAM);
        responseMap.put(ICON_NAME_PARAM, getIconName(sobjectApiName));
        String recordId = (String)requestMap.get(RECORD_ID_PARAM);
        String relatedFieldApiName = (String)requestMap.get(RELATED_FIELD_API_NAME_PARAM);
        responseMap.put(PARENT_RELATIONSHIP_API_NAME_PARAM, getParentRelationshipName(recordId, sobjectApiName, relatedFieldApiName));
        
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(sobjectApiName);
        Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe();
        responseMap.put(SOBJECT_LABEL_PARAM, sobjectDescribe.getLabel());
        responseMap.put(SOBJECT_LABEL_PLURAL_PARAM, sobjectDescribe.getLabelPlural());
        
        return JSON.serialize(responseMap);
    }
    
	@AuraEnabled
    public static List<Sobject> getRecords(String jsonData){
		Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
        String fields = (String)root.get(FIELDS_PARAM);
		Integer numberOfRecords = (Integer)root.get(NUMBER_OF_RECORDS_PARAM);
        String recordId = (String)root.get(RECORD_ID_PARAM);
		String relatedFieldApiName = (String)root.get(RELATED_FIELD_API_NAME_PARAM);
		String sobjectApiName = (String)root.get(SOBJECT_API_NAME_PARAM);        
		String orderBy = (String)root.get(SORTED_BY_PARAM) + ' ' + (String)root.get(SORTED_DIRECTION_PARAM);        
        String rectypeNm = 'Movement';
        String rectypeTH = 'Travel_History'; //334338
        String rectypeNmWSC = 'Work_Study_Care';
        String query = '';
        
        if(sobjectApiName == 'HealthCloudGA__EhrImmunization__c')
        {
            
            List<WorkOrder> wo = [SELECT Id, Case.AccountId,AccountId FROM WorkOrder WHERE Id = :recordId];

            if(wo.size() > 0)
            {
                String accountId = wo[0].Case.AccountId;
                Id theAccountId = wo[0].AccountId==null?wo[0].Case.AccountId:wo[0].AccountId;
                List<Contact> theContact = [SELECT Id FROM Contact WHERE AccountId = :theAccountId LIMIT 1];
                if(theContact.size() > 0){
                    query = 'SELECT ' + fields + ' FROM HealthCloudGA__EhrImmunization__c WHERE Contact__c  =\''+ theContact[0].Id +'\' ORDER BY ' +orderBy+' Limit '+numberOfRecords; 
                }
                
            }

        }
        
        else if(sobjectApiName == 'HealthCloudGA__Clinical_Assessment_Response__c')
        {
            
            List<WorkOrder> wo = [SELECT Id, CaseId FROM WorkOrder WHERE Id = :recordId];

            if(wo.size() > 0)
            {
                String caseId = wo[0].CaseId;
                //Id theAccountId = wo[0].AccountId==null?wo[0].Case.AccountId:wo[0].AccountId;
                //List<Contact> theContact = [SELECT Id FROM Contact WHERE AccountId = :theAccountId LIMIT 1];
                //if(theContact.size() > 0){
                    query = 'SELECT ' + fields + ' FROM HealthCloudGA__Clinical_Assessment_Response__c WHERE Record__c  =\''+ caseId +'\' ORDER BY ' +orderBy+' Limit '+numberOfRecords; 
                //}
                
            }

        }

        else if(sobjectApiName == 'ContactEncounter' && fields.contains('CalculatedDay__c'))
        {
            System.debug('inside condition');
            List<WorkOrder> wo = [SELECT Id, CaseId FROM WorkOrder WHERE Id = :recordId];

            if(wo.size() > 0)
            {
                String CaseId = wo[0].CaseId;
                System.debug('casedid '+CaseId+'record type name'+rectypeNm);
                query = 'SELECT ' + fields + ' FROM ContactEncounter WHERE Record__c =\''+CaseId +'\' AND recordtype.DeveloperName = \''+rectypeNm+'\' ORDER BY ' +orderBy+' Limit ' +numberOfRecords; 
                System.debug(query);
            }
        }

            else if(sobjectApiName == 'ContactEncounter' && fields.contains('Employment_Status__c'))
        {
            
            List<WorkOrder> wo = [SELECT Id, CaseId FROM WorkOrder WHERE Id = :recordId];

            if(wo.size() > 0)
            {
                String CaseId = wo[0].CaseId;
                System.debug('case id'+CaseId);
                query = 'SELECT ' + fields + ' FROM ContactEncounter WHERE Record__c =\''+CaseId +'\' AND recordtype.DeveloperName = \''+rectypeNmWSC+'\' ORDER BY ' +orderBy+' Limit ' +numberOfRecords; 
            }

        }

        else if(sobjectApiName == 'ContactEncounter' && fields.contains('Recent_Travel_Overseas__c')) //334338
        {
            
            List<WorkOrder> wo = [SELECT Id, CaseId FROM WorkOrder WHERE Id = :recordId];

            if(wo.size() > 0)
            {
                String CaseId = wo[0].CaseId;
                System.debug('case id'+CaseId);
                query = 'SELECT ' + fields + ' FROM ContactEncounter WHERE Record__c =\''+CaseId +'\' AND recordtype.DeveloperName = \''+rectypeTH+'\' ORDER BY ' +orderBy+' Limit ' +numberOfRecords; 
            }

        }

        else if(sobjectApiName == 'HealthCloudGA__EhrEncounter__c')
        {
            
            List<WorkOrder> wo = [SELECT Id, Case.Id FROM WorkOrder WHERE Id = :recordId];

            if(wo.size() > 0)
            {
                String CaseId = wo[0].CaseId;
                query = 'SELECT ' + fields + ' FROM HealthCloudGA__EhrEncounter__c WHERE Record__c = \''+ CaseId +'\'  ORDER BY ' +orderBy+' Limit '+numberOfRecords; 
            }

        }
        
        List<Sobject> resultlist = new List<Sobject>();
        
        system.debug('query-------------------'+query);
        if(!String.isEmpty(query)){
            resultlist = Database.query(query);
        }
        
        return resultlist;
	}
        
    private static String getParentRelationshipName(Id recordId, String childSobjectApiName, String relatedFieldApiName){
        Schema.DescribeSObjectResult descrRes = recordId.getSObjectType().getDescribe();
        String name;
        for (Schema.ChildRelationship cr: descrRes.getChildRelationships()){ 
            if(cr.getChildSObject().getDescribe().getName() == childSobjectApiName
            && cr.getField().getDescribe().getName() == relatedFieldApiName){
          	 	name = cr.getRelationshipName();
                break;
            }
        }     
        return name;
    }      
    
    @AuraEnabled
    public static String getIconName(String sobjectApiName){
        String iconName;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.DescribeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { 
            tabDesc.addAll(tsr.getTabs()); 
        }

        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sobjectApiName == tr.getSobjectName() ) {
                if( tr.isCustom() ) {
                    iconDesc.addAll(tr.getIcons());
                }else if (sobjectApiName == 'ContactEncounter'){
                    iconName = 'standard:address';
                } 
                else {
                    iconName = 'standard:' + sobjectApiName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                iconName = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
        return iconName;
    }    
    
}