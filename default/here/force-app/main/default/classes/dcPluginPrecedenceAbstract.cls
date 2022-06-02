/**
 * @Author             : Darko Jovanovic (Contino)
 * @Description        : Base class for applying field precedence rules. 
 *                       It is envisaged that for each field where precedence rules are needed, corresponding class will be created extending this class
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 10/02/2021     Darko Jovanovic   Hotfix 258342 (Custom Merge Rules): Initial version
**/
public abstract class dcPluginPrecedenceAbstract {

    /* Abstract method - this method must be implemented by each class, i.e. these are the actual field precedence rules */
    public abstract Integer getFieldPrecedence(String val);

    /**
    * @description Finds the value with the highest precedence and the corresponding record id
    *              If more than one record with the highest precedence, picks the latest record 
    * @param mergeRecordList - List of records to be merged
    * @param recordByIdMap - Same records above, just keyed by id
    * @param fieldAPIName - API name of the field for which precedence rules are for
    * @param comparisonRecordId - Record id corresponding to the value picked by default merge rules 
    * @return - instance of PrecedenceBaseResult, latest highest precedence value and corresponding record id
    */
    public PrecedenceBaseResult getHighestPrecedence(List<SObject> mergeRecordList,
                                    Map<Id, SObject> recordByIdMap, 
                                    String fieldAPIName,
                                    Id comparisonRecordId) {
        // First, get the precedence of the field value that was selected by the default merge rules
        String comparisonRecordFieldValue;
        if (comparisonRecordId != null) {
            comparisonRecordFieldValue = (String) (recordByIdMap.get(comparisonRecordId)).get(fieldAPIName);
        }
        Integer comparisonRecordValuePrecedence     = getFieldPrecedence(comparisonRecordFieldValue);
        // Now, find the highest precedence by checking the precedence of the field value of each record
        // NOTE: The lower the number, the higher the precedence. Apologies for the confusion
        Map<Id, Integer> topPrecedenceByRecordId    = new Map<Id, Integer>();
        Map<Id, String> valuesByRecordId            = new Map<Id, String>();
        Map<Id, DateTime> createdDateByRecordId     = new Map<Id, DateTime>();
        Integer topPrecedenceValue                  = comparisonRecordValuePrecedence;
        Id recordIdOfMaxPrecedence                  = null;
        String topPrecedenceFieldValue              = null;
        for (Sobject objectData : mergeRecordList) {
            Id recordId = objectData.Id;
            String fieldValue              = (String) objectData.get(fieldAPIName);
            Integer currentPrecedenceValue  = getFieldPrecedence(fieldValue);
            if (currentPrecedenceValue < comparisonRecordValuePrecedence) {
                if (currentPrecedenceValue <= topPrecedenceValue) {
                    topPrecedenceValue = currentPrecedenceValue;
                    topPrecedenceByRecordId.put(recordId, currentPrecedenceValue);
                    valuesByRecordId.put(recordId, fieldValue);
                    createdDateByRecordId.put(recordId, (DateTime) objectData.get('CreatedDate'));
                }
            }
        }
        // If there's more than one record with the highest precedence, pick the latest one
        DateTime maxCreatedDate;
        if (!topPrecedenceByRecordId.isEmpty()) {
            for (Id recordId : topPrecedenceByRecordId.keySet()) 
            {
                DateTime createdDate = createdDateByRecordId.get(recordId);
                if (maxCreatedDate == null || createdDate > maxCreatedDate) {
                    maxCreatedDate          = createdDate;
                    recordIdOfMaxPrecedence = recordId;
                    topPrecedenceFieldValue = valuesByRecordId.get(recordId);
                }
            }
        }
        // If a record with a higher precedence than the default is found, return the value and the corresponding record id
        PrecedenceBaseResult result = new PrecedenceBaseResult();
        if (recordIdOfMaxPrecedence != null) {
            result.recordIdOfMaxPrecedence = recordIdOfMaxPrecedence;
            result.topPrecedenceFieldValue = topPrecedenceFieldValue;
        }
        return result;
    }

    /**
    * @description Finds the record with the highest precedence.
    *              This record id is then stored against the field in the output, so the value will come from that record id. 
    * @param mergeRecordList - List of records to be merged
    * @param recordByIdMap - Same records above, just keyed by id
    * @param fieldAPIName - API name of the field for which precedence rules are for
    * @param output - Merge Set Field output to store the comparison result 
    */
    public void applyPrecedenceRule(List<SObject> mergeRecordList,
                                    Map<Id, SObject> recordByIdMap, 
                                    String fieldAPIName,
                                    dupcheck.dc3PluginModel.MergeSetFieldOutput output) {
        PrecedenceBaseResult result = getHighestPrecedence(mergeRecordList, recordByIdMap, fieldAPIName, output.fieldSourceMap.get(fieldAPIName));
        // If a record with a higher precedence than the default is found, use that record id
        if (result.recordIdOfMaxPrecedence != null) {
            output.fieldSourceMap.put(fieldAPIName, result.recordIdOfMaxPrecedence);
        }
    }

    public class PrecedenceBaseResult {
        public Id recordIdOfMaxPrecedence;
        public String topPrecedenceFieldValue;
    }

}