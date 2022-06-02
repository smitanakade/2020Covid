@IsTest(SeeAllData = true)
public with sharing class LightningForgotPasswordControllerTest {

 /* Verifies that ForgotPasswordController handles invalid usernames appropriately */
 @IsTest
 static void testLightningForgotPasswordControllerInvalidUserName() {
  System.assertEquals(LightningForgotPasswordController.forgotPassowrd('fakeUser', 'http://a.com'), Label.Site.invalid_email);
  System.assertEquals(LightningForgotPasswordController.forgotPassowrd(null, 'http://a.com'), Label.Site.invalid_email);
  System.assertEquals(LightningForgotPasswordController.forgotPassowrd('a', '/home/home.jsp'), Label.Site.invalid_email);
 }

 /* Verifies that null checkEmailRef url throws proper exception. */
 @IsTest
 static void testLightningForgotPasswordControllerWithNullCheckEmailRef() {
  System.assertEquals(LightningForgotPasswordController.forgotPassowrd('a', null), 'Argument 1 cannot be null');
  System.assertEquals(LightningForgotPasswordController.forgotPassowrd('a@salesforce.com', null), 'Argument 1 cannot be null');
 }

 /* Verifies that LightningForgotPasswordController object is instantiated correctly. */
 @IsTest
 static void LightningForgotPasswordControllerInstantiation() {
  LightningForgotPasswordController controller = new LightningForgotPasswordController();
  System.assertNotEquals(controller, null);
 }
}