import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/features/pos/controllers/pos_controller.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class AddPosCustomerDialog extends StatefulWidget {
  const AddPosCustomerDialog({super.key});

  @override
  State<AddPosCustomerDialog> createState() => _AddPosCustomerDialogState();
}

class _AddPosCustomerDialogState extends State<AddPosCustomerDialog> {
  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

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

              Text('الاسم الأول *'.tr, style: robotoRegular),
              const SizedBox(height: 4),
              CustomTextFieldWidget(
                controller: _fNameController,
                hintText: 'أدخل الاسم الأول'.tr,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text('الاسم الأخير *'.tr, style: robotoRegular),
              const SizedBox(height: 4),
              CustomTextFieldWidget(
                controller: _lNameController,
                hintText: 'أدخل الاسم الأخير'.tr,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text('رقم الهاتف *'.tr, style: robotoRegular),
              const SizedBox(height: 4),
              CustomTextFieldWidget(
                controller: _phoneController,
                inputType: TextInputType.phone,
                hintText: '+201000000000'.tr,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text('البريد الإلكتروني (اختياري)'.tr, style: robotoRegular),
              const SizedBox(height: 4),
              CustomTextFieldWidget(
                controller: _emailController,
                inputType: TextInputType.emailAddress,
                hintText: 'example@domain.com'.tr,
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              GetBuilder<PosController>(
                builder: (controller) {
                  return CustomButtonWidget(
                    isLoading: controller.isCustomerLoading,
                    buttonText: 'حفظ العميل'.tr,
                    onPressed: () async {
                      String fName = _fNameController.text.trim();
                      String lName = _lNameController.text.trim();
                      String phone = _phoneController.text.trim();
                      String email = _emailController.text.trim();

                      if (fName.isEmpty || lName.isEmpty || phone.isEmpty) {
                        showCustomSnackBar('يرجى ملء الحقول المطلوبة'.tr, isError: true);
                        return;
                      }

                      bool success = await controller.addCustomer(fName, lName, phone, email.isNotEmpty ? email : null);
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
