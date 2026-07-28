import 'package:shoplancer_vendor/features/auth/controllers/auth_controller.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';

class ApiChecker {
  static bool _isRedirectingToSignIn = false;

  static void checkApi(Response response) {
    if (response.statusCode == 401) {
      if (!_isRedirectingToSignIn && Get.currentRoute != RouteHelper.signIn) {
        _isRedirectingToSignIn = true;
        Get.find<AuthController>().clearSharedData();
        Get.offAllNamed(RouteHelper.getSignInRoute());
        showCustomSnackBar(
          'تم تسجيل الخروج بسبب تسجيل الدخول من جهاز آخر'.tr,
          isError: true,
        );

        Future.delayed(const Duration(seconds: 3), () {
          _isRedirectingToSignIn = false;
        });
      }
    } else {
      showCustomSnackBar(response.statusText);
    }
  }
}
