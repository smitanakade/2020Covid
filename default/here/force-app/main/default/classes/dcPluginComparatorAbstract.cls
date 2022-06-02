/**
 * @Author             : Pratyush Chalasani (Contino)
 * @Description        : Base class for record comparison, where simple precedence rules are not enough.
 * @Modification Log   :  
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 25/03/20201    Pratyush Chalasani    Initial Version
 * 07/04/2021     Pratyush Chalasani    Hotfix 275362: Merge records is not taking last created rule into consideration for Country of Birth and Sex field
 * 15/04/2021     Pratyush Chalasani    Hotfix 276135-277235: Fixes for Merge defects
 * 20/04/2021     Pratyush Chalasani    Fix for case record type priority (#266306)
 * 21/04/2021     Pratyush Chalasani    Hotfix 279006: Fixes for case record type priority
 * 20/10/2021     Lija Jawahar          Updated fieldvalues to String conversion (#330519)
**/
public abstract class dcPluginComparatorAbstract {
    // Determines that the master record has the highest precedence
    public static final Integer MASTER  = 1;
    // Both records being compared have the same precedence
    public static final Integer EQUAL   = 0;
    // The current record being compared takes precedence over the master record
    public static final Integer CURRENT = -1;

    public abstract Integer compare(SObject master, SObject current);

    // Marking this virtual as it's not always required
    public virtual Integer getPrecedence(String fieldName, String fieldValue) {
        return 0; // default return value
    }

    public Map<String,Object> customValueMap = new Map<String,Object>();
    
    public void applyPrecedenceRule(SObject masterRecord,
                                    List<SObject> records, 
                                    String fieldAPIName,
                                    dupcheck.dc3PluginModel.MergeSetFieldOutput output) {
        SObject masterRec = masterRecord;

        Boolean customValue = false;

        if (records != null && !records.isEmpty()) {
            for (SObject currentRec: records) {
                if (currentRec.Id == masterRec.Id) continue;

                Integer precedence = compare(masterRec, currentRec);

                if (precedence == EQUAL) {
                    DateTime masterCreated  = (DateTime)masterRec.get('CreatedDate');
                    DateTime currentCreated = (DateTime)currentRec.get('CreatedDate');

                    System.debug('[MERGE] Master created: ' + masterCreated + ', Current created: ' + currentCreated);
					
                    if((Id)masterRec.get('RecordTypeId') == This.CA && (Id)currentRec.get('RecordTypeId') == This.CA){
                        if (currentCreated < masterCreated) masterRec = currentRec;
                    }else{
                        if (currentCreated > masterCreated) masterRec = currentRec;
                    }
                } else if (precedence == CURRENT) {
                    masterRec = currentRec;
                }
            }
        }

        output.fieldSourceMap.put(fieldAPIName, masterRec.Id);

        for (String key: customValueMap.keySet()) {
            // Workaround for problems setting the fieldSourceMap to a custom value when tests are running.
            // This works properly in the UI, but throws an error in a Unit test context.
            if (!Test.isRunningTest()) output.fieldSourceMap.put(key, 'custom');

            output.customValueMap.put(key, customValueMap.get(key));
        }
    }

    /**
    * @description Determine which record has the highest precedence value for the given field
    * @param fieldName
    * @param numCases 
    * @param caseStatus 
    * @param recordTypeName 
    * @return MASTER or CURRENT if one record takes precedence, or EQUAL if both have the same precedence
    **/
    public Integer getHighestPrecedence(String fieldName, SObject masterRecord, SObject currentRecord) {
        Object masterValue = masterRecord.get(fieldName);
        Object currentValue = currentRecord.get(fieldName);

        if (masterValue == currentValue) return EQUAL;

        Integer masterPrecedence = getPrecedence(fieldName, String.valueof(masterValue));
        Integer currentPrecedence = getPrecedence(fieldName, String.valueof(currentValue));

        if (masterPrecedence < currentPrecedence) return MASTER;
        if (currentPrecedence < masterPrecedence) return CURRENT;

        return EQUAL;
    }

    // Case record types
    public String CA, PCC, SCC, CCS, AC, CS, UC;

    public void storeCaseRecordTypes(Map<String, Id> recordTypeMap) {
        this.CA  = recordTypeMap.get('COVID_19_Case_Assessment');
        this.PCC = recordTypeMap.get('Close_Contact');
        this.SCC = recordTypeMap.get('Secondary_Close_Contact');
        this.CCS = recordTypeMap.get('Casual_Contact');
        this.AC  = recordTypeMap.get('Acquisition_Contact');
        this.CS  = recordTypeMap.get('COVID_19_Case_Screening');
        this.UC  = recordTypeMap.get('Unclassified_Contact');
    }

    // Common precedence order for Case record types
    public Integer caseRecordTypePrecedence(String value) {
        Integer precedence;

        if (value == CA) {
            precedence = 0;
        } else if (value == PCC) {
            precedence = 1;
        } else if (value == SCC) {
            precedence = 2;
        } else if (value == CCS) {
            precedence = 3;
        } else if (value == AC) {
            precedence = 4;
        } else if (value == CS) {
            precedence = 5;
        } else if (value == UC) {
            precedence = 6;
        } else {
            precedence = 999;
        }

        return precedence;
    }

    protected Boolean isRecordTypePCCorSCC(Id recordTypeId)
    {
        return (recordTypeId == this.PCC ||
        recordTypeId == this.SCC );
    }

    protected Boolean isRecordTypeOtherThenPCCorSCC(Id recordTypeId)
    {
        return (recordTypeId == this.CCS ||
        recordTypeId == this.CS ||
        recordTypeId == this.AC ||
        recordTypeId == this.UC);
    }
}