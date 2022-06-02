public  class GenerateSMSJourneyApiQueue implements Queueable,Database.AllowsCallouts{
    
    String Case_Id='';
    final string JOURNEY_EVENT_API='/interaction/v1/events';
    final string JOURNEY_AUTH_API='/v2/token';    
    MC_Journey_SMS_Send__c mc_JourneyCustomSetting;
    MC_Journey_SMS_Send__c McJourneyCustomSetting
    {
        get{
            if (mc_JourneyCustomSetting==null)
            {               
                mc_JourneyCustomSetting=MC_Journey_SMS_Send__c.getOrgDefaults();               
            }
            return mc_JourneyCustomSetting;
        }
    }
    
    public GenerateSMSJourneyApiQueue(String caseId) {
        this.Case_Id = caseId;
    }

    public void execute(QueueableContext context) {

        if (String.isBlank(this.Case_Id))
        {
            return;
        }

        invokeMarketingCloudJourneyApi(this.Case_Id);

    }   
   
    
     /**
     * @description Fire MC journey Event
     * @author DHHS | 30/09/2021 
     * @param caseId Id for the select case
     * @param token Bearer Token for api
     * @return void
     **/   
    
    public void invokeMarketingCloudJourneyApi(String caseId) {
        try {           
            
            if (McJourneyCustomSetting!=null)
            {
                Boolean saveToken=false;
                string token=getAccessKeyValue(); 
                if (!string.isNotBlank(token))
                {                    
                    token = getMCJourneyToken();   
                    saveToken=true;                 
                }
                          
                String payLoad=getEventPayLoad(caseId);
            
                HttpResponse response = makeMCCallOut(payLoad,JOURNEY_EVENT_API,token,saveToken);
            }
            else {
                throw new CalloutException('Failed to Invoke Journey Api. No Org default settings found.');
            }
           
            
        } catch (Exception exp) {
            ApplicationLogUtility.createlog('GenerateSMSSurvey','invokeMarketingCloudJourneyApi',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());            
        }
    } 

    /**
    * @description Get the Bearer token from MC instance
    * @author DHHS
    * @return String return the token from MC instance
    * @revision 
    *           Aref Samad | 30/09/2021 Remove hard coded payload values, implement Custom Settings
    **/
    public String getMCJourneyToken() {   
       
        string payload = '{"grant_type":"client_credentials",';
        payload += '"client_id":"' + McJourneyCustomSetting.Client_Id__c  + '",';
        payload += '"client_secret":"' + McJourneyCustomSetting.Client_Secret__c + '",';
        payload += '"account_id":"' + McJourneyCustomSetting.Account_Id__c + '"}';    
    
        HttpResponse response = makeMCCallOut(payload,JOURNEY_AUTH_API,null,false);              
        //System.debug('*** ' +  response.getBody());
        
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        
        String token = (String)results.get('access_token');
        //System.debug('*** ' +  token );         
        return token;
    } 
       
    private void setAccessKeyValue(String accessToken)
    {
        string[] chunks = new string[]{};
        MC_Journey_SMS_Send__c mcJourneyCustomSettings= MC_Journey_SMS_Send__c.getOrgDefaults();
        // Generate an AES key 
        Blob cryptoKey = Crypto.generateAesKey(256);

        // Generate the data to be encrypted.
        Blob data = Blob.valueOf(accessToken);
        
        // Encrypt the data and have Salesforce.com generate the initialization vector
        Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, data);        

        string privateKey=EncodingUtil.base64Encode(encryptedData);
       // string privateKey=accessToken;

        while(privateKey.length()>0) {

            if(privatekey.length()>= (255)) {
                chunks.add(privatekey.substring(0,255));
            }
            else { 
                chunks.add(privatekey);
                break;
            }
            privatekey = privatekey.substring(255);
        }        
        mcJourneyCustomSettings.Key_Part_1__c = chunks.size()>0?chunks[0]:null;
        mcJourneyCustomSettings.Key_Part_2__c = chunks.size()>1?chunks[1]:null;
        mcJourneyCustomSettings.Key_Part_3__c = chunks.size()>2?chunks[2]:null;

        upsert mcJourneyCustomSettings;
        
        MC_Journey_Setting__c mcEncryptionKey=null;
        List<MC_Journey_Setting__c> mcEncryptionKeys=[SELECT Id,Encryption_Key__c FROM MC_Journey_Setting__c];
        if (mcEncryptionKeys.size()>0)
        {
            mcEncryptionKey=mcEncryptionKeys[0];
        }
        else {
            mcEncryptionKey=new MC_Journey_Setting__c();
        }
        mcEncryptionKey.Encryption_Key__c=EncodingUtil.base64Encode(cryptoKey);
        upsert mcEncryptionKey;
        
    }


    private string getAccessKeyValue()
    {   
        MC_Journey_Setting__c mcEncryptionKey=null;
        List<MC_Journey_Setting__c> mcEncryptionKeys=[SELECT Id,Encryption_Key__c FROM MC_Journey_Setting__c];
        if (mcEncryptionKeys.size()>0)
        {
            mcEncryptionKey=mcEncryptionKeys[0];
        }

        if (mcEncryptionKey!=null && string.isNotBlank(mcEncryptionKey.Encryption_Key__c))
        {
            Blob cryptoKey=EncodingUtil.base64Decode(mcEncryptionKey.Encryption_Key__c);

            String encryptedData=(string.isblank(McJourneyCustomSetting.Key_Part_1__c)?'':McJourneyCustomSetting.Key_Part_1__c.trim())
            + (string.isblank(McJourneyCustomSetting.Key_Part_2__c)?'':McJourneyCustomSetting.Key_Part_2__c.trim())
            + (string.isblank(McJourneyCustomSetting.Key_Part_3__c)?'':McJourneyCustomSetting.Key_Part_3__c.trim());   
            
            Blob dataEncryptedBlob = EncodingUtil.base64Decode(encryptedData);         

            Blob decrypted = Crypto.decryptWithManagedIV('AES256', cryptoKey, dataEncryptedBlob);
            String decryptedString = decrypted.toString();
            return  decryptedString;  
        }

        return '';
        
        
    }


    /**
    * @description Construct and return payload for MC Journey event from the select case
    * @author DHHS | 30/09/2021
    * @param caseId select case id
    * @return String returns payload
    **/
    private String getEventPayLoad(String caseId)
    {
        Case currentCase = [SELECT Id, CaseNumber, AccountId, Account.PersonContactId, Status,OwnerId,Day_0_Calculated__c,
                            Day_11_Test__c,Date_of_Test__c,Account.Name, MessagingTemplate__c, SurveyLinkURL__c,RecordTypeId,
                            Account.PersonEmail,Account.PersonMobilePhone
                            FROM Case WHERE id = :caseId];

        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();
        jsonGen.writeStringField('ContactKey', currentCase.AccountId!=null? currentCase.AccountId:'');
        jsonGen.writeStringField('EventDefinitionKey', McJourneyCustomSetting.Event_Definition_Key__c);
        jsonGen.writeFieldName('Data');
        jsonGen.writeStartObject();
        jsonGen.writeStringField('PersonAccountId',currentCase.AccountId!=null? currentCase.AccountId:'');
        jsonGen.writeStringField('RecordNumber', currentCase.CaseNumber);
        jsonGen.writeStringField('AccountName', currentCase.Account!=null?currentCase.Account.Name:'');
        jsonGen.writeStringField('RecordType', currentCase.RecordTypeId);
        jsonGen.writeStringField('CaseOwner', currentCase.OwnerId);
        jsonGen.writeStringField('CaseId', caseId);
        jsonGen.writeStringField('MobilePhone', currentCase.Account!=null?currentCase.Account.PersonMobilePhone:'');
        jsonGen.writeStringField('Locale', 'AU');
        jsonGen.writeStringField('SMSDeveloperApiName', currentCase.MessagingTemplate__c!=null?currentCase.MessagingTemplate__c:'');
        jsonGen.writeStringField('SMSSurveyLink', currentCase.SurveyLinkURL__c!=null?currentCase.SurveyLinkURL__c:'');
        jsonGen.writeStringField('ContactId', currentCase.Account!=null?currentCase.Account.PersonContactId:'');
        if( currentCase.Day_0_Calculated__c!=null){
            jsonGen.writeDateField('Day0Exposure', currentCase.Day_0_Calculated__c);
        }
        if( currentCase.Day_11_Test__c!=null){
                jsonGen.writeDateField('QuarantineEndDate', currentCase.Day_11_Test__c);
        }
        if( currentCase.Date_of_Test__c!=null){
                jsonGen.writeDateField('dateOfFirstPositiveTest', currentCase.Date_of_Test__c);
        }

        jsonGen.writeEndObject();
        jsonGen.writeEndObject();

        string payLoad=jsonGen.getAsString();
        jsonGen.close();

        return payLoad;
    }
   

    /**
    * @description Make api callout for MC journey 
    * @author DHHS | 30/09/2021 
    * @param payLoad payload for api
    * @param apiName api method name
    * @param token Bearer token for request header
    * @return HttpResponse return api response
    **/  
    private HttpResponse makeMCCallOut(String payLoad,string apiName, string token,boolean saveToken)
    {
        try { 
           
            String apiUrl=(string.isNotBlank(token)?McJourneyCustomSetting.Event_Api_Url__c:McJourneyCustomSetting.Auth_Api_Url__c) + apiName;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();                 
            request.setEndpoint(apiUrl);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            if (string.isNotBlank(token))
            {
                request.setHeader('Authorization', 'Bearer ' + token); 
            }
            
            request.setBody(payload);     
            
            HttpResponse response = http.send(request);    
           
            if (string.isNotBlank(token))
            {  
                if(response.getStatusCode() == 401){
                    string newToken=getMCJourneyToken();
                    return makeMCCallOut(payLoad,JOURNEY_EVENT_API,newToken,true);
                }
            }
           
            if (response.getStatusCode()!=200 && response.getStatusCode()!=201 && response.getStatusCode()!=401)
            {              
                // Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());         
                // String error=results.get('error')!=null?' Error: ' + (String)results.get('error'):'';
                String errorDesc=' Status Code: ' + response.getStatusCode() + ' Response Body: ' + response.getBody();    
                throw new CalloutException('Failed to callout api: ' + apiName + '. Error details: ' +  errorDesc);                    
            }    
            
            if (saveToken && String.isNotBlank(token))
            {
                setAccessKeyValue(token);
            }

            return response;  
            
        } catch (Exception exp) {
           
            throw exp;
            
        }

    }


}
