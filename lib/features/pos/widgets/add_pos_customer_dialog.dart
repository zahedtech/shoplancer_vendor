import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/features/pos/controllers/pos_controller.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class AddPosCustomerDialog extends StatefulWidget {
  const AddPosCustomerDialog({super.key});

  @override
  State<AddPosCustomerDialog> createState() => _AddPosCustomerDialogState();
}

class _AddPosCustomerDialogState extends State<AddPosCustomerDialog> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _countryDialCode;

  @override
  void initState() {
    super.initState();
    _countryDialCode = CountryCode.fromCountryCode(
      Get.find<SplashController>().configModel!.country!,
    ).dialCode;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('إضافة عميل جديد'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text('الاسم الكامل *'.tr, style: robotoRegular),
              const SizedBox(height: 4),
              CustomTextFieldWidget(
                controller: _fullNameController,
                hintText: 'أدخل الاسم الكامل'.tr,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text('رقم الهاتف *'.tr, style: robotoRegular),
              const SizedBox(height: 4),
              CustomTextFieldWidget(
                controller: _phoneController,
                inputType: TextInputType.phone,
                hintText: '1000000000'.tr,
                isPhone: true,
                countryDialCode: _countryDialCode,
                onCountryChanged: (countryCode) {
                  _countryDialCode = countryCode.dialCode;
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              GetBuilder<PosController>(
                builder: (controller) {
                  return CustomButtonWidget(
                    isLoading: controller.isCustomerLoading,
                    buttonText: 'حفظ العميل'.tr,
                    onPressed: () async {
                      String fullName = _fullNameController.text.trim();
                      String phone = _phoneController.text.trim();

                      if (fullName.isEmpty || phone.isEmpty) {
                        showCustomSnackBar('يرجى ملء الحقول المطلوبة'.tr, isError: true);
                        return;
                      }

                      List<String> parts = fullName.split(' ');
                      String fName = parts.isNotEmpty ? parts[0] : '';
                      String lName = parts.length > 1 ? parts.sublist(1).join(' ') : ' ';

                      String finalPhone = '$_countryDialCode$phone';

                      bool success = await controller.addCustomer(fName, lName, finalPhone, null);
                      if (success && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
