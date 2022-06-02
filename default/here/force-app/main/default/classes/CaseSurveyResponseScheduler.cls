/**
 * @Author             : Subbiah Kumaravel
 * @Description        : Set In care pathway or Self care pathway, 
 * @Modification Log   : 
 * ---------------------------------------------------
 * Date           Author      		    Details
 * ---------------------------------------------------
 * 21/10/2021     Subbiah Kumaravel        Initial version
 * 
**/

public class CaseSurveyResponseScheduler implements Schedulable {

	public void execute(SchedulableContext sc){
	
		Database.executeBatch(new CaseCareStatusUpdateBatch(), 200);
		
	}
}