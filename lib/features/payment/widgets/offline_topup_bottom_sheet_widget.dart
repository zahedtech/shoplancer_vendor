import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/features/payment/controllers/payment_controller.dart';
import 'package:shoplancer_vendor/features/payment/domain/models/offline_payment_method_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class OfflineTopupBottomSheetWidget extends StatefulWidget {
  const OfflineTopupBottomSheetWidget({super.key});

  @override
  State<OfflineTopupBottomSheetWidget> createState() =>
      _OfflineTopupBottomSheetWidgetState();
}

class _OfflineTopupBottomSheetWidgetState
    extends State<OfflineTopupBottomSheetWidget> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  OfflinePaymentMethodModel? _selectedMethod;

  @override
  void initState() {
    super.initState();
    Get.find<PaymentController>().getOfflinePaymentMethods().then((_) {
      var methods = Get.find<PaymentController>().offlinePaymentMethods;
      if (methods != null && methods.isNotEmpty) {
        setState(() {
          _selectedMethod = methods.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: Dimensions.paddingSizeDefault,
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Text(
              'request_balance_topup'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              'select_payment_method_instruction'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            GetBuilder<PaymentController>(
              builder: (paymentController) {
                if (paymentController.offlinePaymentMethods == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (paymentController.offlinePaymentMethods!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'no_offline_payment_methods_available'.tr,
                        style: robotoRegular,
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method Selector
                    DropdownButtonFormField<OfflinePaymentMethodModel>(
                      value:
                          _selectedMethod ??
                          paymentController.offlinePaymentMethods!.first,
                      decoration: InputDecoration(
                        labelText: 'payment_method'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeSmall,
                        ),
                      ),
                      items: paymentController.offlinePaymentMethods!.map((
                        method,
                      ) {
                        return DropdownMenuItem<OfflinePaymentMethodModel>(
                          value: method,
                          child: Text(
                            method.methodName ?? '',
                            style: robotoMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedMethod = val;
                        });
                      },
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    // Payment Method Details Card (Transfer Number + Copy)
                    if (_selectedMethod != null) ...[
                      Container(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeDefault,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'account_name'.tr,
                                        style: robotoRegular.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          color: Theme.of(
                                            context,
                                          ).disabledColor,
                                        ),
                                      ),
                                      Text(
                                        _selectedMethod!.accountName ?? '',
                                        style: robotoBold.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'transfer_number'.tr,
                                        style: robotoRegular.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          color: Theme.of(
                                            context,
                                          ).disabledColor,
                                        ),
                                      ),
                                      SelectableText(
                                        _selectedMethod!.accountNumber ?? '',
                                        style: robotoBold.copyWith(
                                          fontSize: Dimensions.fontSizeLarge,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.copy,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () {
                                    if (_selectedMethod!.accountNumber !=
                                        null) {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: _selectedMethod!.accountNumber!,
                                        ),
                                      );
                                      showCustomSnackBar(
                                        'copied_to_clipboard'.tr,
                                        isError: false,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (_selectedMethod!.instructions != null &&
                                _selectedMethod!.instructions!.isNotEmpty) ...[
                              const SizedBox(
                                height: Dimensions.paddingSizeExtraSmall,
                              ),
                              Text(
                                _selectedMethod!.instructions!,
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: Theme.of(context).disabledColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                    ],

                    // Amount Field
                    CustomTextFieldWidget(
                      controller: _amountController,
                      hintText: 'enter_transfer_amount'.tr,
                      labelText: 'amount'.tr,
                      inputType: TextInputType.number,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    // Notes / Reference Field
                    CustomTextFieldWidget(
                      controller: _notesController,
                      hintText: 'transaction_ref_or_notes'.tr,
                      labelText: 'notes'.tr,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    // Receipt Upload Box
                    Text(
                      'transfer_receipt'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    InkWell(
                      onTap: () {
                        _showImageSourceDialog(context, paymentController);
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                          border: Border.all(
                            color: paymentController.rawReceiptImage != null
                                ? Theme.of(context).primaryColor
                                : Theme.of(
                                    context,
                                  ).disabledColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: paymentController.rawReceiptImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault,
                                    ),
                                    child: Image.file(
                                      File(
                                        paymentController.rawReceiptImage!.path,
                                      ),
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: InkWell(
                                      onTap: () {
                                        paymentController.clearReceiptImage();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 32,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(
                                    height: Dimensions.paddingSizeExtraSmall,
                                  ),
                                  Text(
                                    'click_to_upload_receipt'.tr,
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // Submit Button
                    CustomButtonWidget(
                      buttonText: 'submit_topup_request'.tr,
                      isLoading: paymentController.isTopupSubmitting,
                      onPressed: () async {
                        if (_selectedMethod == null) {
                          showCustomSnackBar('please_select_payment_method'.tr);
                          return;
                        }
                        double? amount = double.tryParse(
                          _amountController.text.trim(),
                        );
                        if (amount == null || amount <= 0) {
                          showCustomSnackBar('enter_valid_amount'.tr);
                          return;
                        }

                        bool success = await paymentController
                            .submitTopupRequest(
                              offlineMethodId: _selectedMethod!.id!,
                              amount: amount,
                              notes: _notesController.text.trim(),
                            );

                        if (success) {
                          Get.back();
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog(
    BuildContext context,
    PaymentController paymentController,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('gallery'.tr),
              onTap: () {
                Navigator.of(ctx).pop();
                paymentController.pickReceiptImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text('camera'.tr),
              onTap: () {
                Navigator.of(ctx).pop();
                paymentController.pickReceiptImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}
