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
      String? errorMessage;
      if (response.body != null) {
        if (response.body is Map && response.body['message'] != null) {
          errorMessage = response.body['message'].toString();
        } else if (response.body is Map && response.body['errors'] != null) {
          if (response.body['errors'] is List && (response.body['errors'] as List).isNotEmpty) {
            final firstError = (response.body['errors'] as List)[0];
            if (firstError is Map && firstError['message'] != null) {
              errorMessage = firstError['message'].toString();
            } else {
              errorMessage = firstError.toString();
            }
          } else if (response.body['errors'] is String) {
            errorMessage = response.body['errors'].toString();
          }
        }
      }
      showCustomSnackBar(errorMessage ?? response.statusText, isError: true);
    }
  }
}
