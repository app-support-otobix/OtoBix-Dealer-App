import 'package:get/get.dart';
import 'package:otobix/Controllers/account_controller.dart';
import 'package:otobix/Controllers/bottom_navigation_controller.dart';
import 'package:otobix/Controllers/car_details_controller.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Controllers/login_controller.dart';
import 'package:otobix/Controllers/login_pin_code_controller.dart';
import 'package:otobix/Controllers/my_cars_controller.dart';
import 'package:otobix/Controllers/register_controller.dart';
import 'package:otobix/Controllers/register_pin_code_controller.dart';
import 'package:otobix/Controllers/registration_form_controller.dart';
import 'package:otobix/Controllers/splash_controller.dart';
import 'package:otobix/Controllers/tab_bar_buttons_controller.dart';
import 'package:otobix/Controllers/user_preferences_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Get.put(FirstController());
    Get.lazyPut(() => AccountController());
    Get.lazyPut(() => BottomNavigationController());
    Get.lazyPut(() => CarDetailsController(''));
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => LoginController());
    Get.lazyPut(() => LoginPinCodeController());
    Get.lazyPut(() => MyCarsController());
    Get.lazyPut(() => RegisterController());
    Get.lazyPut(() => RegisterPinCodeController());
    Get.lazyPut(() => RegistrationFormController());
    Get.lazyPut(() => SplashController());
    Get.lazyPut(() => TabBarButtonsController());
    // Get.lazyPut(() => TabBarWidgetController());
    Get.lazyPut(() => UserPreferencesController());
  }
}
