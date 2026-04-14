import 'package:sixam_mart_store/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_store/features/auth/widgets/store_registartion_success_bottom_sheet.dart';
import 'package:sixam_mart_store/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_store/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_store/features/rental_module/profile/controllers/taxi_profile_controller.dart';
import 'package:sixam_mart_store/helper/route_helper.dart';
import 'package:sixam_mart_store/helper/validate_check.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {

  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  GlobalKey<FormState>? _formKeyLogin;
  String? _countryDialCode;

  @override
  void initState() {
    super.initState();
    _formKeyLogin = GlobalKey<FormState>();
    _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
    _phoneController.text = Get.find<AuthController>().getUserNumber();
    _passwordController.text = Get.find<AuthController>().getUserPassword();
    if(Get.find<AuthController>().getUserType() == 'employee'){
      Get.find<AuthController>().changeVendorType(1, isUpdate: false);
    }else{
      Get.find<AuthController>().changeVendorType(0, isUpdate: false);
    }

    _showRegistrationSuccessBottomSheet();
  }

  void _showRegistrationSuccessBottomSheet() {
    bool canShowBottomSheet = Get.find<AuthController>().getIsStoreRegistrationSharedPref();
    if(canShowBottomSheet){
      Future.delayed(const Duration(seconds: 1), () {
        showModalBottomSheet(
          context: Get.context!, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (con) => const StoreRegistrationSuccessBottomSheet(),
        ).then((value) {
          Get.find<AuthController>().saveIsStoreRegistrationSharedPref(false);
          setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: GetBuilder<AuthController>(builder: (authController) {
            return Column(children: [
              Image.asset(Images.logo, width: 200),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              Text('sign_in'.tr.toUpperCase(), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge)),
              const SizedBox(height: 50),

              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Row(children: [

                  Expanded(
                    child: InkWell(
                      onTap: () => authController.changeVendorType(0),
                      child: Column(children: [

                        Expanded(
                          child: Center(child: Text(
                            'vendor_owner'.tr,
                            style: robotoMedium.copyWith(color: authController.vendorTypeIndex == 0
                                ? Theme.of(context).textTheme.bodyLarge!.color : Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.3)),
                          )),
                        ),

                        Container(
                          height: 2,
                          color: authController.vendorTypeIndex == 0 ? Theme.of(context).primaryColor : Colors.transparent,
                        ),

                      ]),
                    ),
                  ),

                  Expanded(
                    child: InkWell(
                      onTap: () => authController.changeVendorType(1),
                      child: Column(children: [

                        Expanded(
                          child: Center(child: Text(
                            'vendor_employee'.tr,
                            style: robotoMedium.copyWith(color: authController.vendorTypeIndex == 1
                                ? Theme.of(context).textTheme.bodyLarge!.color : Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.3)),
                          )),
                        ),

                        Container(
                          height: 2,
                          color: authController.vendorTypeIndex == 1 ? Theme.of(context).primaryColor : Colors.transparent,
                        ),

                      ]),
                    ),
                  ),

                ]),
              ),
              const SizedBox(height: 50),

              Form(
                key: _formKeyLogin,
                child: Column(children: [

                  CustomTextFieldWidget(
                    labelText: 'phone'.tr,
                    hintText: 'enter_phone_number'.tr,
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    nextFocus: _passwordFocus,
                    inputType: TextInputType.phone,
                    isPhone: true,
                    countryDialCode: _countryDialCode,
                    onCountryChanged: (CountryCode countryCode) => _countryDialCode = countryCode.dialCode,
                    required: true,
                    validator: (value) => ValidateCheck.validateEmptyText(value, 'enter_phone_number'.tr),
                  ),
                  const SizedBox(height: 20),

                  CustomTextFieldWidget(
                    labelText: 'password'.tr,
                    hintText: 'minimum_8_characters'.tr,
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    inputAction: TextInputAction.done,
                    inputType: TextInputType.visiblePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    iconSize: 24,
                    isPassword: true,
                    required: true,
                    onSubmit: (text) => GetPlatform.isWeb ? _login(authController) : null,
                    validator: (value) => ValidateCheck.validatePassword(value, null),
                  ),

                ]),
              ),
              const SizedBox(height: 10),

              Row(children: [

                Expanded(
                  child: ListTile(
                    onTap: () => authController.toggleRememberMe(),
                    leading: Checkbox(
                      activeColor: Theme.of(context).primaryColor,
                      value: authController.isActiveRememberMe,
                      onChanged: (bool? isChecked) => authController.toggleRememberMe(),
                    ),
                    title: Text('remember_me'.tr),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    horizontalTitleGap: 0,
                  ),
                ),

                authController.vendorTypeIndex == 1 ? const SizedBox() : TextButton(
                  onPressed: () => Get.toNamed(RouteHelper.getForgotPassRoute()),
                  child: Text('${'forgot_password'.tr}?'),
                ),

              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              CustomButtonWidget(
                isLoading: authController.isLoading,
                buttonText: 'sign_in'.tr,
                onPressed: () => _login(authController),
              ),
              SizedBox(height: Get.find<SplashController>().configModel != null && Get.find<SplashController>().configModel!.toggleStoreRegistration! ? Dimensions.paddingSizeSmall : 0),

              Get.find<SplashController>().configModel != null && Get.find<SplashController>().configModel!.toggleStoreRegistration! ? TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(1, 40),
                ),
                onPressed: () async {
                  Get.toNamed(RouteHelper.getRestaurantRegistrationRoute());
                },
                child: RichText(text: TextSpan(children: [
                  TextSpan(text: '${'join_as'.tr} ', style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                  TextSpan(
                    text: 'vendor'.tr,
                    style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                  ),
                ])),
              ) : const SizedBox(),
            ]);
          }),
        ),
      )),
    );
  }

  void _login(AuthController authController) async {
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String type = authController.vendorTypeIndex == 0 ? 'owner' : 'employee';

    if(_formKeyLogin!.currentState!.validate()) {
      if (phone.isEmpty) {
        showCustomSnackBar('enter_phone_number'.tr);
      }else if (password.isEmpty) {
        showCustomSnackBar('enter_password'.tr);
      }else if (password.length < 6) {
        showCustomSnackBar('password_should_be'.tr);
      }else {
        authController.login(_countryDialCode! + phone, password, type).then((status) async {
          if(status != null){
            if (status.isSuccess) {
              if (authController.isActiveRememberMe) {
                authController.saveUserNumberAndPassword(phone, password, type);
              } else {
                authController.clearUserNumberAndPassword();
              }
              authController.getModuleType() == 'rental' ? await Get.find<TaxiProfileController>().getProfile() : await Get.find<ProfileController>().getProfile();
              Get.find<ProfileController>().initTrialWidgetNotShow();
              Get.offAllNamed(RouteHelper.getInitialRoute());
            }else {
              showCustomSnackBar(status.message);
            }
          }
        });
      }
    }
  }
}
