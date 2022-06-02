public class DHHSPrintCaseExtension {
 
    public final CaseService svc{get; private set;}
    
    // The extension constructor initializes the private member
    // variable svc by using the getRecord method from the standard
    // controller and passing the id of the case record to the constructor
    public DHHSPrintCaseExtension (ApexPages.StandardController stdController) {
        this.svc = new CaseService(((Case)stdController.getRecord()).Id);
    }
    
}