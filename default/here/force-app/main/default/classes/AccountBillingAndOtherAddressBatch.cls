/**
 * @Author             : Touseef Ahmed Mohammed
 * @Description        : Batch to Copy details from Accounts with Address fields (Billing Address & Other Address) 
 *                       to CPA Object & next clear the same fields onto the Account once migrated. Tem Job to support Business Need.
 *                          REF# PBI 334693
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author              Details
 * ---------------------------------------------------
 * 24/11/2021     Touseef Ahmed Mohammed       Initial version
**/

global with sharing class AccountBillingAndOtherAddressBatch implements Database.Batchable <sObject>     
    {

        global Database.QueryLocator start(Database.BatchableContext bc){
            string personAccount='Person Account';
            return Database.getQueryLocator( [SELECT Id,  BillingStreet,  BillingGeocodeAccuracy,
            BillingCity, BillingPostalCode, BillingState, BillingCountry,Createddate, BillingLatitude, BillingLongitude,
            PersonOtherStreet, PersonOtherPhone, Other_County__c, Other_VIC_Region__c, Other_VIC_Region_Group__c, 
            Other_Service_Area__c, Other_DHHS_Service_Area__c, Other_Validation_Status__c, 
            Other_Validation_Diffs__c, Other_Mobile_Phone__c, Other_Work_Phone__c, Other_Fax__c, Other_Pager__c, 
            Other_Email__c , Other_Geocode_Status__c, Other_Official_Place__c, PersonOtherCity, PersonOtherPostalCode,
            PersonOtherState, PersonOtherCountry, PersonOtherLatitude, PersonOtherLongitude, PersonOtherGeocodeAccuracy,
            Alternative_Contact_Number__c,
            Account.ownerId
            FROM Account
            WHERE RecordType.name =: personAccount  
            AND 
            (
                (BillingStreet != NULL OR BillingCity  !=Null OR  Alternative_Contact_Number__c != NULL OR PersonOtherStreet != NULL OR
                 PersonOtherCity != NULL)
            )
            ]);
            
        }

        global void execute(Database.BatchableContext bc, List<sObject> scope){
                
            List<Account> lstPersonAccounts=(List<Account>)scope;
            System.debug('Starting the Migration on this list of Person Accounts'+lstPersonAccounts);
            List<ContactPointAddress> lstCPA=new List<ContactPointAddress>();
            List<Account> lstClearAccount=new List<Account>();
            for (Account acc : lstPersonAccounts) {
                ContactPointAddress objCPA=new ContactPointAddress();
                objCPA.UsageType='Temp';
                objCPA.ActiveToDate=null;
                objCPA.ActiveFromDate= Date.valueOf(acc.CreatedDate);
                objCPA.Save_with_blank_Active_To_Date__c=true;
                objCPA.OwnerId=acc.ownerId;
                objCPA.ParentId=acc.id;
                objCPA.IsDefault=False;	
                objCPA.IsPrimary=False;
                
                if(acc.BillingStreet!=Null || acc.BillingCity  !=Null ||  acc.Alternative_Contact_Number__c != NULL)
                {
                    ContactPointAddress objBillCPA=new ContactPointAddress();
                    //Migrating the Billing Address Fields
                    objBillCPA.Name='Isolation/Quarantine Address (Migrated)';
                    objBillCPA.AddressType='Isolation/Quarantine Address';
                    objBillCPA.Home_Phone__c=acc.Alternative_Contact_Number__c;
                    objBillCPA.Street =acc.BillingStreet;                
                    objBillCPA.City=acc.BillingCity;
                    objBillCPA.PostalCode=acc.BillingPostalCode;
                    objBillCPA.State=acc.BillingState;
                    objBillCPA.Country=acc.BillingCountry;
                    objBillCPA.Latitude=acc.BillingLatitude;
                    objBillCPA.Longitude=acc.BillingLongitude;
                    objBillCPA.GeocodeAccuracy=acc.BillingGeocodeAccuracy;

                   
                    objBillCPA.UsageType='Temp';
                    objBillCPA.ActiveToDate=null;
                    objBillCPA.ActiveFromDate= Date.valueOf(acc.CreatedDate);
                    objBillCPA.Save_with_blank_Active_To_Date__c=true;
                    objBillCPA.OwnerId=acc.ownerId;
                    objBillCPA.ParentId=acc.id;
                    objBillCPA.IsDefault=False;	
                    objBillCPA.IsPrimary=False;

                    //Clearing the Account fields
                    acc.Alternative_Contact_Number__c='';
                    acc.BillingStreet='';                
                    acc.BillingCity='';
                    acc.BillingPostalCode='';
                    acc.BillingState='';
                    acc.BillingCountry='';
                    acc.BillingLatitude=null;
                    acc.BillingLongitude=null;
                    acc.BillingGeocodeAccuracy='';
                    lstCPA.add(objBillCPA);
                }
                if( acc.PersonOtherStreet != NULL || acc.PersonOtherCity != NULL)
                {
                    ContactPointAddress objOtherCPA=new ContactPointAddress();
                    //Migrating the Other Address Fields
                    objOtherCPA.AddressType='Discharge';
                    objOtherCPA.Name='Discharge (Migrated)';
                    objOtherCPA.Street=acc.PersonOtherStreet;	
                    objOtherCPA.Home_Phone__c=acc.PersonOtherPhone;	
                    objOtherCPA.County__c=acc.Other_County__c;	
                    objOtherCPA.VIC_Region__c=acc.Other_VIC_Region__c;	
                    objOtherCPA.VIC_Region_Group__c=acc.Other_VIC_Region_Group__c;	
                    objOtherCPA.Service_Area__c=acc.Other_Service_Area__c;	
                    objOtherCPA.DHHS_Service_Area__c=acc.Other_DHHS_Service_Area__c;	
                    objOtherCPA.Validation_Status__c=acc.Other_Validation_Status__c;	
                    objOtherCPA.Validation_Diffs__c=acc.Other_Validation_Diffs__c;	
                    objOtherCPA.Mobile_Phone__c=acc.Other_Mobile_Phone__c;	
                    objOtherCPA.Work_Phone__c=acc.Other_Work_Phone__c;	
                    objOtherCPA.Fax__c=acc.Other_Fax__c;	
                    objOtherCPA.Pager__c=acc.Other_Pager__c;	
                    objOtherCPA.Email__c=acc.Other_Email__c;	
                    objOtherCPA.Geocode_Status__c=acc.Other_Geocode_Status__c;	
                    objOtherCPA.Official_Place__c=acc.Other_Official_Place__c;	
                    objOtherCPA.City=acc.PersonOtherCity;	
                    objOtherCPA.PostalCode=acc.PersonOtherPostalCode;	
                    objOtherCPA.State=acc.PersonOtherState;	
                    objOtherCPA.Country=acc.PersonOtherCountry;	
                    objOtherCPA.Latitude=acc.PersonOtherLatitude;	
                    objOtherCPA.Longitude=acc.PersonOtherLongitude;	
                    objOtherCPA.GeocodeAccuracy=acc.PersonOtherGeocodeAccuracy;	

                    objOtherCPA.UsageType='Temp';
                    objOtherCPA.ActiveToDate=null;
                    objOtherCPA.ActiveFromDate= Date.valueOf(acc.CreatedDate);
                    objOtherCPA.Save_with_blank_Active_To_Date__c=true;
                    objOtherCPA.OwnerId=acc.ownerId;
                    objOtherCPA.ParentId=acc.id;
                    objOtherCPA.IsDefault=False;	
                    objOtherCPA.IsPrimary=False;

                    //Clearing Account Fields
                    acc.PersonOtherStreet='';	
                    acc.PersonOtherPhone='';	
                    acc.Other_County__c	='';
                    acc.Other_VIC_Region__c='';	
                    acc.Other_VIC_Region_Group__c='';	
                    acc.Other_Service_Area__c='';	
                    acc.Other_DHHS_Service_Area__c='';	
                    acc.Other_Validation_Status__c='';	
                    acc.Other_Validation_Diffs__c='';	
                    acc.Other_Mobile_Phone__c='';	
                    acc.Other_Work_Phone__c='';	
                    acc.Other_Fax__c='';	
                    acc.Other_Pager__c='';	
                    acc.Other_Email__c='';	
                    acc.Other_Geocode_Status__c='';	
                    acc.Other_Official_Place__c='';	
                    acc.PersonOtherCity='';	
                    acc.PersonOtherPostalCode='';	
                    acc.PersonOtherState='';	
                    acc.PersonOtherCountry='';	                   	
                    acc.PersonOtherLatitude=null;	
                    acc.PersonOtherLongitude=null;	
                    acc.PersonOtherGeocodeAccuracy='';	
                    acc.Alternative_Contact_Number__c='';                    
                    lstCPA.add(objOtherCPA);
                }               
               
                lstClearAccount.add(acc);               
            }
            System.debug('List of CPA records to be created'+lstCPA);
            System.debug('List Of Account records to be updated'+lstClearAccount);
            if(lstCPA.size()>0)
            {
                try {
                    Database.SaveResult[] srList =Database.insert(lstCPA);
                    for (Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {
                            // Operation was successful, so get the ID of the record that was processed
                            System.debug('Contact Point Address fields Inserted CPA ID: ' + sr.getId());
                            if (lstClearAccount.size()>0) 
                            {
                                Database.SaveResult[] srAccList =Database.update(lstClearAccount); 
                                                            
                            }
                        }
                        else 
                        {
                            // Operation failed, so get all errors                
                            for(Database.Error err : sr.getErrors()) 
                            {
                                System.debug('The following error has occurred.');                    
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                System.debug('Contact Point Address fields that affected this error: ' + err.getFields());
                            }
                        }
                    }
                } catch(Exception ex) {
                    System.Debug('The following exception has occurred: ' + ex.getMessage());
               } 
            }
               
        }

        global void finish(Database.BatchableContext bc){
            //post processing
        }
    }