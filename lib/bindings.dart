import 'package:get/get.dart';
import 'controllers/controllers.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() async {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<OnboardingController>(OnboardingController(), permanent: true);
    Get.put<UserController>(UserController(), permanent: true);
  }
}