public with sharing class AuraResponse {

    @AuraEnabled 
    public Boolean isSuccess;

    @AuraEnabled 
    public String message;

    @AuraEnabled
    public String response; 

    public AuraResponse(Boolean isSuccess, String message, String response) {
        this.isSuccess = isSuccess;
        this.message = message;
        this.response = response;
    }
}