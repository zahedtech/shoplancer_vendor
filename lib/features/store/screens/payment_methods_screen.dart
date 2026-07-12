import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/common/widgets/switch_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/details_custom_card.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart'
    as profile;
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final profile.Store store;
  const PaymentMethodsScreen({super.key, required this.store});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isCashMethodEnabled = true;
  bool _isWalletMethodEnabled = false;
  bool _isInstaPayMethodEnabled = false;

  final TextEditingController _walletPhoneController = TextEditingController();
  final TextEditingController _walletAccountNameController =
      TextEditingController();
  final TextEditingController _instaPayPhoneController =
      TextEditingController();
  final TextEditingController _instaPayAccountNameController =
      TextEditingController();

  profile.StorePaymentMethod? _getPaymentMethod(int methodId) {
    return widget.store.paymentMethods != null
        ? widget.store.paymentMethods![methodId]
        : null;
  }

  @override
  void initState() {
    super.initState();

    profile.StorePaymentMethod? cashMethod = _getPaymentMethod(1);
    profile.StorePaymentMethod? walletMethod = _getPaymentMethod(2);
    profile.StorePaymentMethod? instaPayMethod = _getPaymentMethod(3);

    _isCashMethodEnabled = cashMethod?.isActive ?? true;

    _isWalletMethodEnabled = walletMethod?.isActive ?? false;
    if (_isWalletMethodEnabled && walletMethod?.configData != null) {
      _walletPhoneController.text = walletMethod?.configData!['phone'] ?? '';
      _walletAccountNameController.text =
          walletMethod?.configData!['account_name'] ?? '';
    }

    _isInstaPayMethodEnabled = instaPayMethod?.isActive ?? false;
    if (_isInstaPayMethodEnabled && instaPayMethod?.configData != null) {
      _instaPayPhoneController.text =
          instaPayMethod?.configData!['phone'] ?? '';
      _instaPayAccountNameController.text =
          instaPayMethod?.configData!['account_name'] ?? '';
    }
  }

  @override
  void dispose() {
    _walletPhoneController.dispose();
    _walletAccountNameController.dispose();
    _instaPayPhoneController.dispose();
    _instaPayAccountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'payment_method'.tr),
      body: GetBuilder<StoreController>(
        builder: (storeController) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'payment_method'.tr,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      DetailsCustomCard(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeDefault,
                        ),
                        child: Column(
                          children: [
                            SwitchButtonWidget(
                              title: 'cash'.tr,
                              isButtonActive: _isCashMethodEnabled,
                              onTap: () {
                                setState(() {
                                  _isCashMethodEnabled = !_isCashMethodEnabled;
                                });
                              },
                            ),
                            const SizedBox(
                              height: Dimensions.paddingSizeDefault,
                            ),

                            SwitchButtonWidget(
                              title: 'digital_wallet'.tr,
                              isButtonActive: _isWalletMethodEnabled,
                              onTap: () {
                                setState(() {
                                  _isWalletMethodEnabled =
                                      !_isWalletMethodEnabled;
                                });
                              },
                            ),
                            if (_isWalletMethodEnabled) ...[
                              const SizedBox(
                                height: Dimensions.paddingSizeExtraLarge,
                              ),
                              CustomTextFieldWidget(
                                hintText: 'phone_number'.tr,
                                labelText: 'phone_number'.tr,
                                controller: _walletPhoneController,
                                inputType: TextInputType.phone,
                                isEnabled: _isWalletMethodEnabled,
                                hideEnableText: true,
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeExtraLarge,
                              ),
                              CustomTextFieldWidget(
                                hintText: 'holder_name'.tr,
                                labelText: 'holder_name'.tr,
                                controller: _walletAccountNameController,
                                inputType: TextInputType.text,
                                isEnabled: _isWalletMethodEnabled,
                                hideEnableText: true,
                              ),
                            ],
                            const SizedBox(
                              height: Dimensions.paddingSizeDefault,
                            ),

                            SwitchButtonWidget(
                              title: 'InstaPay',
                              isButtonActive: _isInstaPayMethodEnabled,
                              onTap: () {
                                setState(() {
                                  _isInstaPayMethodEnabled =
                                      !_isInstaPayMethodEnabled;
                                });
                              },
                            ),
                            if (_isInstaPayMethodEnabled) ...[
                              const SizedBox(
                                height: Dimensions.paddingSizeExtraLarge,
                              ),
                              CustomTextFieldWidget(
                                hintText: 'phone_number'.tr,
                                labelText: 'phone_number'.tr,
                                controller: _instaPayPhoneController,
                                inputType: TextInputType.phone,
                                isEnabled: _isInstaPayMethodEnabled,
                                hideEnableText: true,
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeExtraLarge,
                              ),
                              CustomTextFieldWidget(
                                hintText: 'holder_name'.tr,
                                labelText: 'holder_name'.tr,
                                controller: _instaPayAccountNameController,
                                inputType: TextInputType.text,
                                isEnabled: _isInstaPayMethodEnabled,
                                hideEnableText: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: storeController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButtonWidget(
                        onPressed: () {
                          String walletPhone = _walletPhoneController.text
                              .trim();
                          String walletAccountName =
                              _walletAccountNameController.text.trim();
                          String instaPayPhone = _instaPayPhoneController.text
                              .trim();
                          String instaPayAccountName =
                              _instaPayAccountNameController.text.trim();

                          if (_isWalletMethodEnabled &&
                              (walletPhone.isEmpty ||
                                  walletAccountName.isEmpty)) {
                            showCustomSnackBar(
                              'please_enter_wallet_details'.tr,
                            );
                          } else if (_isInstaPayMethodEnabled &&
                              (instaPayPhone.isEmpty ||
                                  instaPayAccountName.isEmpty)) {
                            showCustomSnackBar(
                              'please_enter_instapay_details'.tr,
                            );
                          } else {
                            profile.Store updateStore = widget.store;
                            updateStore.paymentMethods = {
                              1: profile.StorePaymentMethod(
                                isActive: _isCashMethodEnabled,
                                configData: null,
                              ),
                              2: profile.StorePaymentMethod(
                                isActive: _isWalletMethodEnabled,
                                configData: _isWalletMethodEnabled
                                    ? {
                                        'phone': walletPhone,
                                        'account_name': walletAccountName,
                                      }
                                    : null,
                              ),
                              3: profile.StorePaymentMethod(
                                isActive: _isInstaPayMethodEnabled,
                                configData: _isInstaPayMethodEnabled
                                    ? {
                                        'phone': instaPayPhone,
                                        'account_name': instaPayAccountName,
                                      }
                                    : null,
                              ),
                            };

                            storeController.updateStore(
                              updateStore,
                              updateStore.minimumOrder?.toString() ?? '0',
                              updateStore.maximumShippingCharge?.toString() ??
                                  '0',
                            );
                          }
                        },
                        buttonText: 'update'.tr,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
