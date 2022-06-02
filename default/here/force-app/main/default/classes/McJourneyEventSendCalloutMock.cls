/**
* @Author             : DHHS
* @Description        : HTTP callout mock for Journey Event API
* @Modification Log   :  
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
* 30/09/2021     Aref Samad         PBI-322220 Remove Live Message dependency, use MC journey API to send SMS
**/

@isTest
global class McJourneyEventSendCalloutMock implements HttpCalloutMock {
   
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"access_token": "UDK8844UXUJJLLDOOAJIUKUUED59984"}');
        response.setStatusCode(200);
        return response; 
    }
}