/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Controller class for VaccinationDetailsLWC
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         ABN
* @version        1.0 
* @created        2021-06-28
*/
public with sharing class VaccinationDetailsController 
{
    static List<HealthCloudGA__EhrImmunization__c> lsthealthCloudRecords;
    static List<EHRResponseWrapper> wrapperList ;
    static JSONGenerator gen;

        /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * Creates the EHR Immunisation Record
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    contactId                          Id of the related contact
    * @return   AuraResponse        Returns AuraResponse object
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @AuraEnabled
    public static AuraResponse createhealthCloudRecordOnSubmit(String contactId,HealthCloudGA__EhrImmunization__c healthCloudObj) 
    {
        try{
          
            HealthCloudGA__EhrImmunization__c newHealthCloudObj = new HealthCloudGA__EhrImmunization__c();
            
            newHealthCloudObj.Contact__c =contactId;
            newHealthCloudObj.Country__c = healthCloudObj.Country__c;
            newHealthCloudObj.Vaccine__c = healthCloudObj.Vaccine__c;
            newHealthCloudObj.Have_you_had_a_COVID_19_vaccine__c = healthCloudObj.Have_you_had_a_COVID_19_vaccine__c;
            newHealthCloudObj.Date_administered__c = healthCloudObj.Date_administered__c;
            newHealthCloudObj.Validation_Status__c = healthCloudObj.Validation_Status__c;
            newHealthCloudObj.Dose_Received__c = healthCloudObj.Dose_Received__c;
            newHealthCloudObj.Notes__c = healthCloudObj.Notes__c;
            insert newHealthCloudObj;
           
            getEhrImmunizationDetails(contactId);
			setJSON();
           
        }
        catch (Exception ex)
        {
			return new AuraResponse(false, ex.getMessage(), null);
		}
      
		return new AuraResponse(true, 'SUCCESS', gen.getAsString());       
        
    }

       /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * Gets the list of  EHR Immunisation Records for the contact 
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    contactId                          Id of the related contact
    * @return   AuraResponse        Returns AuraResponse object
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @AuraEnabled(cacheable=true)
	public static AuraResponse getInitialData(String contactId)
    {
        
		try{
			getEhrImmunizationDetails(contactId);
			setJSON();
		} 
        catch (Exception ex)
        {
			return new AuraResponse(false, ex.getMessage(), null);
		}
      
		return new AuraResponse(true, 'SUCCESS', gen.getAsString());
	}

     /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * Private method to get the list of  EHR Immunisation Records for the contact 
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    contactId                          Id of the related contact
    *
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    private static void getEhrImmunizationDetails(String contactId){
		lsthealthCloudRecords = [SELECT  Name,Contact__c, toLabel(Country__c), Date_administered__c,Dose_Received__c,Have_you_had_a_COVID_19_vaccine__c,Notes__c,Vaccine__c,Vaccine__r.Name,toLabel(Validation_Status__c)
                                FROM HealthCloudGA__EhrImmunization__c
                                WHERE Contact__c = :contactId order by Date_administered__c DESC];
       
        List<EHRResponseWrapper> wrapperListTemp=new List<EHRResponseWrapper>();
        for(HealthCloudGA__EhrImmunization__c ehr : lsthealthCloudRecords){
            EHRResponseWrapper wrapper = new EHRResponseWrapper(ehr,ehr.Vaccine__r.Name);
            wrapperListTemp.add(wrapper);
           
        }
        wrapperList=wrapperListTemp;
        system.debug('wrapperlist' + wrapperListTemp);
	}

 
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * Private method to set the Output JSON
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    null                         NA
    *
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    private static void setJSON()
    {
		gen = JSON.createGenerator(true);
		gen.writeStartObject();
        if (wrapperList != null)
        {
			gen.writeObjectField('lsthealthCloudRecords', wrapperList);
		}

		gen.writeEndObject();
    }
    public class EHRResponseWrapper{    
        @AuraEnabled
        public HealthCloudGA__EhrImmunization__c ehrRecord{get;set;}
        @AuraEnabled
        public String vaccineName{get;set;}
        public EHRResponseWrapper(HealthCloudGA__EhrImmunization__c ehrRecord,String vaccineName){
           
            this.vaccineName=vaccineName;
            this.ehrRecord=ehrRecord;
        }
       
    }
}
