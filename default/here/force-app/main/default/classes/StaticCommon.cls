public with sharing class StaticCommon {
    public static Boolean runPermissionTrigger = true;

    public static void disablePermissionTrigger(){
        runPermissionTrigger = false;
    }

    public static void enablePermissionTrigger() {
        runPermissionTrigger = true;
    }
}