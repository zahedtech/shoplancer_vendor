import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/features/payment/controllers/payment_controller.dart';
import 'package:shoplancer_vendor/features/payment/widgets/offline_topup_bottom_sheet_widget.dart';
import 'package:shoplancer_vendor/features/payment/widgets/topup_request_history_widget.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class PrepaidWalletScreen extends StatefulWidget {
  const PrepaidWalletScreen({super.key});

  @override
  State<PrepaidWalletScreen> createState() => _PrepaidWalletScreenState();
}

class _PrepaidWalletScreenState extends State<PrepaidWalletScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<PaymentController>().getWalletPaymentList();
    Get.find<PaymentController>().getWalletInfo();
    if (Get.find<ProfileController>().profileModel == null) {
      Get.find<ProfileController>().getProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'المحفظة'.tr, isBackButtonExist: true),
      body: GetBuilder<ProfileController>(
        builder: (profileController) {
          return profileController.modulePermission!.wallet!
              ? GetBuilder<PaymentController>(
                  builder: (paymentController) {
                    return (profileController.profileModel != null)
                        ? RefreshIndicator(
                            onRefresh: () async {
                              await Get.find<ProfileController>().getProfile();
                              await Get.find<PaymentController>().getWalletInfo();
                              await Get.find<PaymentController>().getWalletPaymentList();
                            },
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Prepaid Balance Card
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      gradient: LinearGradient(
                                        colors: [
                                          (profileController.profileModel!.prepaidBalance ?? 0) < 0
                                              ? Colors.orange.shade800
                                              : Theme.of(context).primaryColor,
                                          (profileController.profileModel!.prepaidBalance ?? 0) < 0
                                              ? Colors.deepOrange.shade900
                                              : Theme.of(context).primaryColor.withValues(alpha: 0.85),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.account_balance_wallet,
                                                  color: Theme.of(context).cardColor,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                                Text(
                                                  'prepaid_balance'.tr,
                                                  style: robotoRegular.copyWith(
                                                    fontSize: Dimensions.fontSizeSmall,
                                                    color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if ((profileController.profileModel!.isSuspended ?? false) ||
                                                ((profileController.profileModel!.prepaidBalance ?? 0) < 0))
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                ),
                                                child: Text(
                                                  (profileController.profileModel!.isSuspended ?? false)
                                                      ? 'store_suspended'.tr
                                                      : 'negative_balance'.tr,
                                                  style: robotoBold.copyWith(
                                                    fontSize: Dimensions.fontSizeExtraSmall,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeSmall),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            PriceConverterHelper.convertPrice(
                                              profileController.profileModel!.prepaidBalance ?? 0.0,
                                            ),
                                            style: robotoBold.copyWith(
                                              fontSize: 26,
                                              color: Theme.of(context).cardColor,
                                            ),
                                            textDirection: TextDirection.ltr,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),

                                  // Top-Up Request Button
                                  CustomButtonWidget(
                                    buttonText: 'request_balance_topup'.tr,
                                    icon: Icons.add_circle_outline,
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => const OfflineTopupBottomSheetWidget(),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeLarge),

                                  Text(
                                    'topup_requests_history'.tr,
                                    style: robotoBold.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),

                                  const TopupRequestHistoryWidget(),
                                ],
                              ),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator());
                  },
                )
              : Center(
                  child: Text(
                    'you_have_no_permission_to_access_this_feature'.tr,
                    style: robotoMedium,
                  ),
                );
        },
      ),
    );
  }
}
