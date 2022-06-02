/**
* @Author             : Santosh
* @Description        : recordAddressHandler
* @Modification Log   : 
* ---------------------------------------------------
* Date           Author                Details
* ---------------------------------------------------
*30/08/2021		 Santosh			  Feature 307648 : New LWC Component to show current address on record
*17/09/2021		 Sai Kallu			  Bugfix  322015 : From and To Date is not displayed on LWC for HMIP
*27/09/2021      Sukumar Salla        Bugfix  323079 : Updated Order by conditions in queries to get HMIP and CPA address 
*8/10/2021       Sukumar Salla        Bugfix  323051 : Updated queries to get HMIP and CPA address
*13/10/2021      Sukumar Salla        Bugfix  328595 : Updated recent addresses logic
*14/10/2021      Sukumar Salla        Feature 327997 : Address Management - Update to LWC title
*20/10/2021      Sukumar Salla        Feature 329365 : Address Management - Add geocoding/look up to LWC CPA
*27/10/2021      Mayukhman Pathak     Feature 332060 : Address Management - Pull Home Isolation details from Primary/Residential address
*27/10/2021       Sai Kallu           Feature 332014   : Address Management - Add primary address to list of available addresses
*10/11/2021      Sukumar Salla        Bugfix  331444 : UAT - Sprint 11 - PBI 307648 - New Primary/Residential Address and Discharge Addresses are not shown as the Current Address
**/
public with sharing class recordAddressHandler {

/*************************************************
 * addresswrapper - wrapper class to hold all address parameters including the possible values on a record 
 * 
 * **********************************************/
public class addresswrapper{
    @AuraEnabled
    public string street {get;set;}
    @AuraEnabled
    public string city {get;set;}
    @AuraEnabled
    public string country {get;set;}
    @AuraEnabled
    public string province {get;set;}
    @AuraEnabled
    public string postcode {get;set;}
    @AuraEnabled
    public string type {get;set;}
    @AuraEnabled
    public string addressType {get;set;}
    @AuraEnabled
    public string relatedAccountName {get;set;}
    @AuraEnabled
    public string id {get;set;}
    @AuraEnabled
    public List<possibleaddresswrapper> addressoptions {get;set;}

    addresswrapper(string street, string city, string country, string province, string postcode,string type,string addressType,string relatedAccountName,string id){
        this.street = street;
        this.city = city;
        this.country = country;
        this.province = province;
        this.postcode = postcode;
        this.type = type;
        this.addressType = addressType;
        this.relatedAccountName = relatedAccountName;
        this.id = id;
        this.addressoptions = new List<possibleaddresswrapper>();
        }
    addresswrapper(){
         this.addressoptions = new List<possibleaddresswrapper>();   
    }


}

/*************************************************
 * possibleaddresswrapper - wrapper class to hold List of possible address values on a case 
 * **********************************************/
public class possibleaddresswrapper{
    @AuraEnabled
    public string displayvalue {get;set;}
    @AuraEnabled
    public string type {get;set;}
    @AuraEnabled
    public string Id {get;set;}

    possibleaddresswrapper(string displayvalue, string type,string Id){
        this.displayvalue = displayvalue;
        this.type = type;
        this.Id = Id;
        }


}
/*************************************************
 * fetchaddress - Method to designed to generate the addresswrapper to be returned to the recordAddress LWC component. 
 * **********************************************/
@AuraEnabled
public static addresswrapper fetchaddress(string caseid){
    addresswrapper returnaddress ;
    string currentid;
    string currenttype;
    string accountid;
	// Query the incoming case
    case incomingcase = [select id,CurrentAddressId__c,accountid,CurrentAddressType__c from case where id = :caseid LIMIT 1];
	// if not null, get the account id, current address id and the current address type 
    if(incomingcase != null){
        currentid = incomingcase.CurrentAddressId__c;
        currenttype = incomingcase.CurrentAddressType__c;
        accountid = incomingcase.accountid ;
    }

    try {
    if(currentid != null && currentid != '' && currenttype != null && currenttype != ''){
        // If current type and current id on case is not empty, fetch the relevant address and populate the returnaddress(addresswrapper)
        switch on currenttype{
            when 'CPA'{
                ContactPointAddress currentCPA = [select id,address,ActiveFromDate,ActiveToDate,AddressType,Parent.Name from ContactPointAddress where id = :currentid LIMIT 1];
                if(currentCPA != null){
                    Address currentCPAaddress = currentCPA.address; 
                    if(currentCPAaddress != null) returnaddress = new addresswrapper(currentCPAaddress.street,currentCPAaddress.city,currentCPAaddress.country,currentCPAaddress.state,currentCPAaddress.postalcode,'CPA',currentCPA.AddressType,currentCPA.Parent.Name,currentCPA.Id);
                }
            }
            when 'HMIP'{
                HealthCloudGA__EhrEncounter__c currentHMIP = [select id,HealthCloudGA__Account__r.ShippingAddress,Date_admitted__c,Date_discharged__c,Presented_to__c,HealthCloudGA__Account__r.Name from HealthCloudGA__EhrEncounter__c where id = :currentid LIMIT 1];
                //PBI - 332060 - Address Management - Pull Home Isolation details from Primary/Residential address
                if(currentHMIP != null){
                    Address currentHMIPaddress = currentHMIP.HealthCloudGA__Account__r.ShippingAddress; 
                    if(currentHMIP.HealthCloudGA__Account__c != null && currentHMIPaddress != null){
                        returnaddress = new addresswrapper(currentHMIPaddress.street,currentHMIPaddress.city,currentHMIPaddress.country,currentHMIPaddress.state,currentHMIPaddress.postalcode,'HMIP',currentHMIP.Presented_to__c,currentHMIP.HealthCloudGA__Account__r.Name,currentHMIP.Id);
                    }
                    else if(currentHMIP.HealthCloudGA__Account__c == null && !String.isBlank(accountid) ){
                        Account currentPRA = [select id,PersonMailingAddress from Account where id = :accountid LIMIT 1];
                        if(currentPRA != null){
                            Address currentPRAaddress = currentPRA.PersonMailingAddress; 
                            if(currentPRAaddress != null)returnaddress = new addresswrapper(currentPRAaddress.street,currentPRAaddress.city,currentPRAaddress.country,currentPRAaddress.state,currentPRAaddress.postalcode,'PRA',null,null,currentPRA.Id);
                        } 
                    }
                }
            }
            when 'PRA'{
               Account currentPRA = [select id,PersonMailingAddress	 from Account where id = :currentid LIMIT 1];
                if(currentPRA != null){
                    Address currentPRAaddress = currentPRA.PersonMailingAddress; 
                    if(currentPRAaddress != null)returnaddress = new addresswrapper(currentPRAaddress.street,currentPRAaddress.city,currentPRAaddress.country,currentPRAaddress.state,currentPRAaddress.postalcode,'PRA',null,null,currentPRA.Id);
                } 

            }
        }

    } 
    else if(caseid != null && caseid != ''){
        // if current id and current type is empty, fetch values as per below criteria 
        // If there's an active HMIP (eg. no end date OR the end date is in the future) record then display HMIP address
        //Else if there is an active CPA then display CPA address
        //Else if there is an active Discharge Address then display Discharge Address
        //Else display the "Primary/Residential Address"
        date todysdate = Date.today();
         List<HealthCloudGA__EhrEncounter__c> currentHMIP = [select id,HealthCloudGA__Account__r.ShippingAddress,Date_admitted__c,Date_discharged__c,Record__c,  End_Date__c,StartDate__c,Presented_to__c,HealthCloudGA__Account__r.Name from HealthCloudGA__EhrEncounter__c where Record__c = :caseid AND StartDate__c <= :todysdate AND ( End_Date__c = null OR End_Date__c >= :todysdate) Order by End_Date__c desc NULLS First, StartDate__c desc  LIMIT 1];
         if(currentHMIP != null && currentHMIP.size()>0){
            //PBI - 332060 - Address Management - Pull Home Isolation details from Primary/Residential address
            Address currentHMIPaddress = currentHMIP[0].HealthCloudGA__Account__r.ShippingAddress; 
            if(currentHMIP[0].HealthCloudGA__Account__c != null && currentHMIPaddress != null){
                returnaddress = new addresswrapper(currentHMIPaddress.street,currentHMIPaddress.city,currentHMIPaddress.country,currentHMIPaddress.state,currentHMIPaddress.postalcode,'HMIP',currentHMIP[0].Presented_to__c,currentHMIP[0].HealthCloudGA__Account__r.Name,currentHMIP[0].Id);
            }
            else if(currentHMIP[0].HealthCloudGA__Account__c == null && !String.isBlank(accountid) ){
                Account currentPRA = [select id,PersonMailingAddress from Account where id = :accountid LIMIT 1];
                if(currentPRA != null){
                    Address currentPRAaddress = currentPRA.PersonMailingAddress; 
                    if(currentPRAaddress != null)returnaddress = new addresswrapper(currentPRAaddress.street,currentPRAaddress.city,currentPRAaddress.country,currentPRAaddress.state,currentPRAaddress.postalcode,'PRA',null,null,currentPRA.Id);
                } 
            }
        }else if(accountid != null && accountid != ''){

            List<ContactPointAddress> currentCPA = [select id,address,ActiveFromDate,ActiveToDate,AddressType,Parent.Name from ContactPointAddress where ParentId = :accountid AND  Addresstype != 'Discharge'  AND  ActiveFromDate <= :todysdate AND ( ActiveToDate = null OR ActiveToDate >= :todysdate) Order by ActiveToDate desc NULLS First ,ActiveFromDate desc  LIMIT 1];
            if(currentCPA != null && currentCPA.size()>0){
                Address currentCPAaddress = currentCPA[0].address; 
                if(currentCPAaddress != null) returnaddress = new addresswrapper(currentCPAaddress.street,currentCPAaddress.city,currentCPAaddress.country,currentCPAaddress.state,currentCPAaddress.postalcode,'CPA',currentCPA[0].AddressType,currentCPA[0].Parent.Name,currentCPA[0].Id);
            }else{
                 // fetch the discharge addres 
                 List<ContactPointAddress> DischargedCPA = [select id,address,ActiveFromDate,ActiveToDate,AddressType,Parent.Name from ContactPointAddress where ParentId = :accountid AND  Addresstype = 'Discharge' AND   ActiveFromDate <= :todysdate AND ( ActiveToDate = null OR ActiveToDate >= :todysdate)  Order by ActiveToDate desc NULLS First ,ActiveFromDate desc LIMIT 1];
            
                
                if(DischargedCPA != null && DischargedCPA.size()>0){
                    // Check for discharge address here 
                    Address currentdischargeaddress = DischargedCPA[0].address; 
                     if(currentdischargeaddress != null) returnaddress = new addresswrapper(currentdischargeaddress.street,currentdischargeaddress.city,currentdischargeaddress.country,currentdischargeaddress.state,currentdischargeaddress.postalcode,'CPA',DischargedCPA[0].AddressType,DischargedCPA[0].Parent.Name,DischargedCPA[0].Id);
          
                }else{
                    Account currentPRA = [select id,PersonMailingAddress from Account where id = :accountid LIMIT 1];
                    if(currentPRA != null){
                        Address currentPRAaddress = currentPRA.PersonMailingAddress; 
                        if(currentPRAaddress != null)returnaddress = new addresswrapper(currentPRAaddress.street,currentPRAaddress.city,currentPRAaddress.country,currentPRAaddress.state,currentPRAaddress.postalcode,'PRA',null,null,currentPRA.Id);
                    } 
                }
            }

        }
        
    }
	// Fetch possible address value for a record, can be contact point address or HMIPs
	
    List<possibleaddresswrapper> fetchaddressoptions = new List<possibleaddresswrapper>();
    fetchaddressoptions = fetchpossibleaddress(caseid,accountid);
    
    if(fetchaddressoptions.size()>0){
        if(returnaddress != null ){
            returnaddress.addressoptions = fetchaddressoptions;
        }else{
            returnaddress = new addresswrapper();
            returnaddress.addressoptions = fetchaddressoptions;
        }
    }
    

        
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
    return returnaddress;
}
/*************************************************
 * fetchpossibleaddress - Method to create a list of possibleaddresswrapper values each holding a displayvalue, type and recordid 
 * **********************************************/

public static List<possibleaddresswrapper> fetchpossibleaddress(string caseid, string accountid){
   List<possibleaddresswrapper> returnaddress = new List<possibleaddresswrapper>();
    try {
        date todysdate = Date.today();
        // Fetch HMIPs
        List<HealthCloudGA__EhrEncounter__c> sortedHMIPs = new List<HealthCloudGA__EhrEncounter__c>();
        List<HealthCloudGA__EhrEncounter__c> PossibleHMIPs = [select id,Presented_to__c,HealthCloudGA__Account__r.Name,Date_admitted__c,Date_discharged__c,Record__c, End_Date__c,StartDate__c from HealthCloudGA__EhrEncounter__c where Record__c = :caseid Order by End_Date__c desc NULLS First ,StartDate__c desc LIMIT 3];
        if(PossibleHMIPs.size() >= 2){
            if(PossibleHMIPs[0].End_Date__c == null && PossibleHMIPs.size() == 3){
                if(PossibleHMIPs[0].StartDate__c <= todysdate){
                    sortedHMIPs.add(PossibleHMIPs[0]);
                    sortedHMIPs.add(PossibleHMIPs[1]);
                }
                else{
                    sortedHMIPs.add(PossibleHMIPs[1]);
                    sortedHMIPs.add(PossibleHMIPs[2]);
                }
            }
            else if(PossibleHMIPs[0].End_Date__c == null && PossibleHMIPs.size() == 2){
                sortedHMIPs.add(PossibleHMIPs[1]);
                sortedHMIPs.add(PossibleHMIPs[0]);
            }
            else{
                sortedHMIPs.addAll(PossibleHMIPs);
            } 
        }
        else{
           sortedHMIPs.addAll(PossibleHMIPs);
        }
        if(sortedHMIPs != null ){
            for(HealthCloudGA__EhrEncounter__c HMIP : sortedHMIPs){
                
                //Bugfix  322015
                //To display Start Date  and End Date on LWC for HMIP
                //PBI - 332060 - Address Management - Pull Home Isolation details from Primary/Residential address
                String displayvalue = '';
                if(HMIP.HealthCloudGA__Account__r.Name != null){
                    displayvalue = HMIP.HealthCloudGA__Account__r.Name;
                }
                else{
                    Account acc = [SELECT Id, ShippingAddress, PersonMailingAddress , ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, PersonMailingCity, PersonMailingStreet, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry FROM Account WHERE Id =: accountid];
                    if(acc.PersonMailingAddress != NULL){
                        Address praAddress = acc.PersonMailingAddress; 
                        if(praAddress != null){
                            displayvalue = (praAddress.street != null ? praAddress.street : '') + ' '+ (praAddress.postalcode != null ? praAddress.postalcode : '');
                        }
                    }
                }
                displayvalue += ' | Type: ' + (HMIP.Presented_to__c != null ? HMIP.Presented_to__c : '')+
                    ' | From: ' + ( HMIP.StartDate__c != null ? HMIP.StartDate__c.format() : '') +
                    ' | To: ' + ( HMIP.End_Date__c != null ? HMIP.End_Date__c.format() : ''); 
                
                returnaddress.add(new possibleaddresswrapper(displayvalue,'HMIP',HMIP.Id));
           
               
            }
        }
        // Fetch CPAs
        List<ContactPointAddress> sortedCPAs = new List<ContactPointAddress>();
        List<ContactPointAddress> PossibleCPAs = [select id,address,AddressType,ActiveFromDate,ActiveToDate	 from ContactPointAddress where ParentId = :accountid and AddressType != 'ELR' Order by ActiveToDate desc NULLS First ,ActiveFromDate desc LIMIT 3];
        if(PossibleCPAs.size() >= 2){
            if(PossibleCPAs[0].ActiveToDate == null && PossibleCPAs.size() == 3){
                if(PossibleCPAs[0].ActiveFromDate <= todysdate){
                    sortedCPAs.add(PossibleCPAs[0]);
                    sortedCPAs.add(PossibleCPAs[1]);
                }
                else{
                     sortedCPAs.add(PossibleCPAs[1]);
                     sortedCPAs.add(PossibleCPAs[2]);
                }
            }
            else if(PossibleCPAs[0].ActiveToDate == null && PossibleCPAs.size() == 2){
                sortedCPAs.add(PossibleCPAs[1]);
                sortedCPAs.add(PossibleCPAs[0]);
            }
            else{
                sortedCPAs.addAll(PossibleCPAs);
            }
        }
        else{
             sortedCPAs.addAll(PossibleCPAs);
        }
            if(sortedCPAs != null){
                for(ContactPointAddress CPA : sortedCPAs){
                    Address currentCPAaddress = CPA.address; 
                    String displayvalue = '';
                    if(currentCPAaddress != null){
                        displayvalue = (currentCPAaddress.street != null ? currentCPAaddress.street : '') + ' '+ (currentCPAaddress.postalcode != null ? currentCPAaddress.postalcode : '');
                    }
                    displayvalue += ' | Type: ' + (CPA.AddressType != null ? CPA.AddressType : '') +
                    				' | From: ' + (CPA.ActiveFromDate != null ? CPA.ActiveFromDate.format() : '') + 
                        			' | To: ' + (CPA.ActiveToDate != null ? CPA.ActiveToDate.format() : ''); 
                    returnaddress.add(new possibleaddresswrapper(displayvalue,'CPA',CPA.Id));
                }
            }
        
        	//For PBI #332014 - Address Management - Add primary address to list of available addresses
            Account acc = [SELECT Id, ShippingAddress, PersonMailingAddress , ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, PersonMailingCity, PersonMailingStreet, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry FROM Account WHERE Id =: accountid];
            if(acc.PersonMailingAddress != NULL){
                Address praAddress = acc.PersonMailingAddress; 
                String displayvalue = '';
                if(praAddress != null){
                    displayvalue = (praAddress.street != null ? praAddress.street : '') + ' '+ (praAddress.postalcode != null ? praAddress.postalcode : '');
                }
                displayvalue += ' | Type: ' + (acc.PersonMailingAddress != null ?  'Primary/Residential' : ''); 
                returnaddress.add(new possibleaddresswrapper(displayvalue,'PRA',accountid));
            }  
        
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }

    return returnaddress;
}
/*************************************************
 * updatecurrentid - Method to be called from LWC, updates the currentid and type on the record. 
 * **********************************************/

@AuraEnabled
public static boolean updatecurrentid(string caseid, string currentid,string currenttype){

    boolean recordupdated = false;
    try{

        case casetoupdate = new case();
    casetoupdate.id = caseid;
    casetoupdate.CurrentAddressId__c = currentid;
    casetoupdate.CurrentAddressType__c = currenttype;

    update casetoupdate; 
    recordupdated = true;

    }catch(exception e){
       // Handle exception
    }
    
    return recordupdated;

}
/*************************************************
 * updatecurrentid - Method to be called from LWC, takes a back up of current account's address as a new CPA during new PRA process and updates the account address
 * **********************************************/
@AuraEnabled
public static boolean updateprimaryresidentialaddress(string accountid,string street, string city, string country, string province, string postalcode,boolean isupdate){

    boolean updateoperation = false;
    boolean cpainserted = false;
    Account operatingaccount = [select id,PersonMailingAddress,PersonMailingstreet,PersonMailingcity,PersonMailingpostalcode,PersonMailingcountry,PersonMailingstate,createddate from account where id = :accountid];

    ContactPointAddress newCPA = new ContactPointAddress();
    // take a backup of address into new CPA only when the user selects to create new primary residential address
    if(!isupdate){
        newCPA.AddressType = 'Historical Primary/Residential Address';
        newCPA.name = 'Primary/Residential Previous';
        date activeFromDate =  Date.newInstance(operatingaccount.createddate.year(), operatingaccount.createddate.month(), operatingaccount.createddate.day()) ;
        newCPA.ActiveFromDate = activeFromDate;
        date activeToDt = (activeFromDate == system.today()) ? system.today() : system.today().addDays(-1);  // bugfix-331444
        newCPA.ActiveToDate = activeToDt;  // bugfix-331444
        newCPA.street = operatingaccount.PersonMailingstreet;
        newCPA.city = operatingaccount.PersonMailingcity;
        newCPA.country = operatingaccount.PersonMailingcountry;
        newCPA.state = operatingaccount.PersonMailingstate;
        newCPA.postalcode = operatingaccount.PersonMailingpostalcode;
        newCPA.ParentId = accountid;
        newCPA.Save_with_blank_Active_To_Date__c = true;
    
    
        Database.SaveResult cpainsert = Database.insert(newCPA);
        cpainserted = cpainsert.isSuccess();
    }
   
    if(cpainserted || isupdate){
        
        operatingaccount.PersonMailingstreet = street;
        operatingaccount.PersonMailingcity = city;
        operatingaccount.PersonMailingcountry = country;
        operatingaccount.PersonMailingstate = province;
        operatingaccount.PersonMailingpostalcode = postalcode;

        Database.SaveResult accountupdate = Database.update(operatingaccount);
        if(accountupdate.isSuccess()){
            updateoperation = true;
        }
    }

    return updateoperation;

}

/*************************************************
 * fetchCPAAddress - Method to be called from LWC, to get CPA address details
 * **********************************************/
@AuraEnabled
public static ContactPointAddress fetchCPAAddress(string cpaId){
   return [SELECT Id, Name, Street, City, Country, State, PostalCode, ParentId FROM ContactPointAddress WHERE Id =: cpaId];
}
    
     /*************************************************
* fetchPRAAddress - Method to be called from LWC, to get PRA address details // For PBI #332014 
* **********************************************/
    @AuraEnabled
    public static Account fetchPRAAddress(string accountid){
        return [SELECT Id, ShippingAddress, PersonMailingAddress , ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, PersonMailingCity, PersonMailingStreet, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry FROM Account WHERE Id =: accountid];
    }

}