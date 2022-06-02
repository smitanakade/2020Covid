/**
 * @Author             : Arun
 * @Description        : Duplicate Check Index - Helper Schedule class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 14/11/2021    Arun               PBI 332958 - Scheduled job for Duplicate Check Index creation/re-build 
 
**/
public class DuplicateCheckIndexScheduler implements Schedulable{

    public string dcSettingName;
  
    /**
     * @description Constructor
     * @param  Settings Developer Name
     *
     */ 
    public DuplicateCheckIndexScheduler(String settingName){
        dcSettingName = settingName;
    }

    /**
     * @description Get the custom metadata value for Dupe check
     * @param  settingName Settings Developer Name
     * @return             CUstom metatadata record
     */ 
    public static Dupe_Check_Index_Setting__mdt getIndexInstance(String settingName){
     
        return Dupe_Check_Index_Setting__mdt.getInstance(settingName);
    }
    /**
     * @description createIndexJob Insert an DC Check index job
     * @param  indexsetting indexsetting Pass the custom metadata settings
     * @return              return  index job created
     */ 
    public static dupcheck__dcJob__c  createIndexJob(Dupe_Check_Index_Setting__mdt indexsetting){
        dupcheck__dcJob__c indexJob = new dupcheck__dcJob__c();
        if(indexsetting!=null){
            try{
                Datetime incrementalDate ;
                if(indexsetting.Increment_Unit__c=='Minutes'){
                    incrementalDate = indexsetting.Increment_Value__c!=null? Datetime.now().addMinutes(Integer.valueOf(indexsetting.Increment_Value__c)) : Datetime.now().addMinutes(-2);
                }
                else if(indexsetting.Increment_Unit__c=='Hours'){
                    incrementalDate = indexsetting.Increment_Value__c!=null? Datetime.now().addHours(Integer.valueOf(indexsetting.Increment_Value__c)) : Datetime.now().addHours(-2);
                }
                else if(indexsetting.Increment_Unit__c=='Days'){
                    incrementalDate = indexsetting.Increment_Value__c!=null? Datetime.now().addDays(Integer.valueOf(indexsetting.Increment_Value__c)) : Datetime.now().addDays(-2);
                }
                else {
                    incrementalDate = indexsetting.Increment_Value__c!=null? Datetime.now().addHours(Integer.valueOf(indexsetting.Increment_Value__c)) : Datetime.now().addHours(-2);
                }
                String filterClause = '(LastModifiedDate >= '+incrementalDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')+')';
                
                indexJob.dupcheck__name__c = indexsetting.Label+ ' - ' + incrementalDate.format();
                indexJob.dupcheck__type__c = indexsetting.Index_Type__c;
                indexJob.dupcheck__sourceObject__c = indexsetting.Source_Object_Prefix__c;
                indexJob.dupcheck__matchObject__c = indexsetting.Match_Object_Prefix__c;
                indexJob.dupcheck__status__c = 'Holding';
                indexJob.dupcheck__filterOn__c = 'filter';
                indexJob.dupcheck__filter__c = filterClause;
                indexJob.dupcheck__filterWith__c = 'all';
                insert indexJob;
            }
            catch(Exception exp){
                ApplicationLogUtility.createlog('DuplicateCheckIndexHelper','Index Creation',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
            }
           
     

        }
        return indexJob;
    }
    /**
     * @description createBatchJob Pass the job ID 
     * @param  indexJob Index job creation
     */ 
    public static void createBatchJob(dupcheck__dcJob__c indexJob){

        // This code is only required when we use index as the option. In Pre prod and prod we are already setup the localindex .
        //THis will be determined the custom metadata.
            
            if(indexJob.dupcheck__type__c=='index'){
                try{
                    Id apexJob = database.executeBatch(new dupcheck.dc3IndexBatch(indexJob.dupcheck__sourceObject__c, indexJob.Id),50);
                    System.debug('AAApex job' + apexJob);
                      // update dupcheck__dcJob__c(Id = indexJob.Id, dupcheck__apex__c=apexJob);
                    indexJob.dupcheck__apex__c=apexJob;
                    update indexJob;
                }

                catch(Exception exp){
                    ApplicationLogUtility.createlog('DuplicateCheckIndexHelper','Job Creation',exp.getStackTraceString(),exp.getMessage(),exp.getTypeName());
                }
               
            }
            
         
        
       
        
        
    }

    /**
     * @description Schedule method. 
     * @param  sc SchedulableContext
     */ 
    public void execute(SchedulableContext sc){
        System.debug('SSSetings Name'+  dcSettingName);
        createBatchJob(createIndexJob(getIndexInstance(dcSettingName)));
    
    }
}
