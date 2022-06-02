/** Give new Users, Health Cloud Permission sets + role
 * When a new user is created, assign the user:
 * 1. 8 HealthCloud Permission sets (Health Cloud Admin + ... API should only be given to ADMIN and Integration)
 * 2. If the role is blank, then update the role to "CCOM"
 */
trigger UserTrigger on User (after insert,before insert,before update,after update) {
    new UserTriggerHandler().run();
}