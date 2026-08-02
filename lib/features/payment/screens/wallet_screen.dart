import 'package:shoplancer_vendor/features/payment/controllers/payment_controller.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/features/payment/widgets/offline_topup_bottom_sheet_widget.dart';
import 'package:shoplancer_vendor/features/payment/widgets/topup_request_history_widget.dart';
import 'package:shoplancer_vendor/features/payment/widgets/wallet_attention_alert_widget.dart';
import 'package:shoplancer_vendor/features/payment/widgets/wallet_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedHistoryTab = 0;

  @override
  void initState() {
    Get.find<PaymentController>().getWithdrawList();
    Get.find<PaymentController>().getWithdrawMethodList();
    Get.find<PaymentController>().getWalletPaymentList();
    Get.find<PaymentController>().getWalletInfo();
    if (Get.find<ProfileController>().profileModel == null) {
      Get.find<ProfileController>().getProfile();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'wallet'.tr, isBackButtonExist: false),

      body: GetBuilder<ProfileController>(
        builder: (profileController) {
          return profileController.modulePermission!.wallet!
              ? GetBuilder<PaymentController>(
                  builder: (bankController) {
                    return (profileController.profileModel != null &&
                            bankController.withdrawList != null)
                        ? RefreshIndicator(
                            onRefresh: () async {
                              await Get.find<ProfileController>().getProfile();
                              await Get.find<PaymentController>()
                                  .getWalletInfo();
                              await Get.find<PaymentController>()
                                  .getWithdrawList();
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeSmall,
                                    ),
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Prepaid Balance Card with Negative Limit Info & Top-Up Action
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(
                                            Dimensions.paddingSizeDefault,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              Dimensions.radiusDefault,
                                            ),
                                            gradient: LinearGradient(
                                              colors: [
                                                (profileController
                                                                .profileModel!
                                                                .prepaidBalance ??
                                                            0) <
                                                        0
                                                    ? Colors.orange.shade800
                                                    : Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                (profileController
                                                                .profileModel!
                                                                .prepaidBalance ??
                                                            0) <
                                                        0
                                                    ? Colors.deepOrange.shade900
                                                    : Theme.of(
                                                        context,
                                                      ).primaryColor.withValues(
                                                        alpha: 0.85,
                                                      ),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .account_balance_wallet,
                                                        color: Theme.of(
                                                          context,
                                                        ).cardColor,
                                                        size: 22,
                                                      ),
                                                      const SizedBox(
                                                        width: Dimensions
                                                            .paddingSizeExtraSmall,
                                                      ),
                                                      Text(
                                                        'prepaid_balance'.tr,
                                                        style: robotoRegular
                                                            .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeSmall,
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .cardColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.9,
                                                                      ),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  if ((profileController
                                                              .profileModel!
                                                              .isSuspended ??
                                                          false) ||
                                                      ((profileController
                                                                  .profileModel!
                                                                  .prepaidBalance ??
                                                              0) <
                                                          0))
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              Dimensions
                                                                  .radiusSmall,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        (profileController
                                                                    .profileModel!
                                                                    .isSuspended ??
                                                                false)
                                                            ? 'store_suspended'
                                                                  .tr
                                                            : 'negative_balance'
                                                                  .tr,
                                                        style: robotoBold.copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeExtraSmall,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  PriceConverterHelper.convertPrice(
                                                    profileController
                                                            .profileModel!
                                                            .prepaidBalance ??
                                                        0.0,
                                                  ),
                                                  style: robotoBold.copyWith(
                                                    fontSize: 26,
                                                    color: Theme.of(
                                                      context,
                                                    ).cardColor,
                                                  ),
                                                  textDirection:
                                                      TextDirection.ltr,
                                                ),
                                              ),
                                              // const SizedBox(
                                              //   height:
                                              //       Dimensions.paddingSizeSmall,
                                              // ),
                                              // const Divider(
                                              //   color: Colors.white24,
                                              //   height: 1,
                                              // ),
                                              // const SizedBox(
                                              //   height:
                                              //       Dimensions.paddingSizeSmall,
                                              // ),
                                              // Row(
                                              //   mainAxisAlignment:
                                              //       MainAxisAlignment.spaceBetween,
                                              //   children: [
                                              //     Column(
                                              //       crossAxisAlignment:
                                              //           CrossAxisAlignment.start,
                                              //       children: [
                                              //         Text(
                                              //           'min_negative_limit'.tr,
                                              //           style: robotoRegular.copyWith(
                                              //             fontSize: Dimensions.fontSizeExtraSmall,
                                              //             color: Theme.of(context)
                                              //                 .cardColor
                                              //                 .withValues(alpha: 0.8),
                                              //           ),
                                              //         ),
                                              //         Text(
                                              //           '-${PriceConverterHelper.convertPrice(profileController.profileModel!.minPrepaidBalanceLimit ?? 0.0)}',
                                              //           style: robotoMedium.copyWith(
                                              //             fontSize: Dimensions.fontSizeSmall,
                                              //             color: Theme.of(context).cardColor,
                                              //           ),
                                              //           textDirection: TextDirection.ltr,
                                              //         ),
                                              //       ],
                                              //     ),
                                              //     Column(
                                              //       crossAxisAlignment:
                                              //           CrossAxisAlignment.end,
                                              //       children: [
                                              //         Text(
                                              //           'allowed_credit_remaining'.tr,
                                              //           style: robotoRegular.copyWith(
                                              //             fontSize: Dimensions.fontSizeExtraSmall,
                                              //             color: Theme.of(context)
                                              //                 .cardColor
                                              //                 .withValues(alpha: 0.8),
                                              //           ),
                                              //         ),
                                              //         Text(
                                              //           PriceConverterHelper.convertPrice(
                                              //             profileController.profileModel!.allowedCreditRemaining ?? 0.0,
                                              //           ),
                                              //           style: robotoMedium.copyWith(
                                              //             fontSize: Dimensions.fontSizeSmall,
                                              //             color: Theme.of(context).cardColor,
                                              //           ),
                                              //           textDirection: TextDirection.ltr,
                                              //         ),
                                              //       ],
                                              //     ),
                                              //   ],
                                              // ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeSmall,
                                        ),

                                        // Top-Up Request Button
                                        CustomButtonWidget(
                                          buttonText:
                                              'request_balance_topup'.tr,
                                          icon: Icons.add_circle_outline,
                                          onPressed: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (_) =>
                                                  const OfflineTopupBottomSheetWidget(),
                                            );
                                          },
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeDefault,
                                        ),

                                        // Balance Cards: Online Payment & COD side-by-side
                                        Row(
                                          children: [
                                            // Online Payment Balance Card (Withdrawable)
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  Dimensions.paddingSizeDefault,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions
                                                            .radiusDefault,
                                                      ),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor.withValues(
                                                        alpha: 0.85,
                                                      ),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Theme.of(context)
                                                          .primaryColor
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Image.asset(
                                                          Images.wallet,
                                                          width: 20,
                                                          height: 20,
                                                          color: Theme.of(
                                                            context,
                                                          ).cardColor,
                                                        ),
                                                        const SizedBox(
                                                          width: Dimensions
                                                              .paddingSizeExtraSmall,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            'online_payment_balance'
                                                                .tr,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: robotoRegular.copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeExtraSmall,
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .cardColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.9,
                                                                      ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      height: Dimensions
                                                          .paddingSizeSmall,
                                                    ),
                                                    FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        PriceConverterHelper.convertPrice(
                                                          profileController
                                                              .profileModel!
                                                              .balance,
                                                        ),
                                                        style: robotoBold
                                                            .copyWith(
                                                              fontSize: 20,
                                                              color: Theme.of(
                                                                context,
                                                              ).cardColor,
                                                            ),
                                                        textDirection:
                                                            TextDirection.ltr,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width:
                                                  Dimensions.paddingSizeSmall,
                                            ),

                                            // Cash on Delivery Balance Card (Cash in Hand)
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  Dimensions.paddingSizeDefault,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions
                                                            .radiusDefault,
                                                      ),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor.withValues(
                                                        alpha: 0.85,
                                                      ),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Theme.of(context)
                                                          .primaryColor
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .monetization_on_outlined,
                                                          size: 20,
                                                          color: Theme.of(
                                                            context,
                                                          ).cardColor,
                                                        ),
                                                        const SizedBox(
                                                          width: Dimensions
                                                              .paddingSizeExtraSmall,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            'cod_balance'.tr,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: robotoRegular.copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeExtraSmall,
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .cardColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.9,
                                                                      ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      height: Dimensions
                                                          .paddingSizeSmall,
                                                    ),
                                                    FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        PriceConverterHelper.convertPrice(
                                                          profileController
                                                              .profileModel!
                                                              .cashInHands,
                                                        ),
                                                        style: robotoBold
                                                            .copyWith(
                                                              fontSize: 20,
                                                              color: Theme.of(
                                                                context,
                                                              ).cardColor,
                                                            ),
                                                        textDirection:
                                                            TextDirection.ltr,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Shoplancer Commission Card
                                        if (profileController
                                                    .profileModel!
                                                    .stores !=
                                                null &&
                                            profileController
                                                .profileModel!
                                                .stores!
                                                .isNotEmpty &&
                                            profileController
                                                    .profileModel!
                                                    .stores![0]
                                                    .storeBusinessModel ==
                                                'commission') ...[
                                          const SizedBox(
                                            height: Dimensions.paddingSizeSmall,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(
                                              Dimensions.paddingSizeLarge,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    Dimensions.radiusDefault,
                                                  ),
                                              color: Theme.of(
                                                context,
                                              ).cardColor,
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.15),
                                              ),
                                              boxShadow: Get.isDarkMode
                                                  ? null
                                                  : [
                                                      BoxShadow(
                                                        color:
                                                            Colors.grey[200]!,
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                          0,
                                                          3,
                                                        ),
                                                      ),
                                                    ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.percent,
                                                      size: 24,
                                                      color: Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                    ),
                                                    const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeSmall,
                                                    ),
                                                    Text(
                                                      'shoplancer_commission'
                                                          .tr,
                                                      style: robotoBold.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                        color: Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(
                                                  height: Dimensions
                                                      .paddingSizeLarge,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'commission_rate'.tr,
                                                      style: robotoRegular
                                                          .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                            color: Theme.of(
                                                              context,
                                                            ).disabledColor,
                                                          ),
                                                    ),
                                                    Text(
                                                      '${profileController.profileModel!.stores![0].comission ?? Get.find<SplashController>().configModel!.adminCommission ?? 0}%',
                                                      style: robotoMedium
                                                          .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeSmall,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'total_commission_taken'
                                                          .tr,
                                                      style: robotoRegular
                                                          .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                            color: Theme.of(
                                                              context,
                                                            ).disabledColor,
                                                          ),
                                                    ),
                                                    Text(
                                                      PriceConverterHelper.convertPrice(
                                                        profileController
                                                                .profileModel!
                                                                .totalCommissionCollected ??
                                                            0.0,
                                                      ),
                                                      style: robotoBold.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color,
                                                      ),
                                                      textDirection:
                                                          TextDirection.ltr,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(
                                          height: Dimensions.paddingSizeSmall,
                                        ),

                                        // Total Earning Detail Card
                                        WalletWidget(
                                          title: 'total_earning'.tr,
                                          value: profileController
                                              .profileModel!
                                              .totalEarning,
                                          isAmountAndTextInRow: true,
                                        ),

                                        const SizedBox(
                                        height: Dimensions.paddingSizeLarge,
                                        ),

                                         Container(
                                           decoration: BoxDecoration(
                                             color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                                             borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                             border: Border.all(
                                               color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                                             ),
                                           ),
                                           padding: const EdgeInsets.all(3),
                                           child: Row(
                                             children: [
                                               Expanded(
                                                 child: InkWell(
                                                   onTap: () => setState(() => _selectedHistoryTab = 0),
                                                   borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                   child: Container(
                                                     padding: const EdgeInsets.symmetric(vertical: 8),
                                                     alignment: Alignment.center,
                                                     decoration: BoxDecoration(
                                                       color: _selectedHistoryTab == 0
                                                           ? Theme.of(context).primaryColor
                                                           : Colors.transparent,
                                                       borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                     ),
                                                     child: Text(
                                                       "transaction_history".tr,
                                                       style: robotoBold.copyWith(
                                                         color: _selectedHistoryTab == 0
                                                             ? Colors.white
                                                             : Theme.of(context).textTheme.bodyLarge?.color,
                                                         fontSize: Dimensions.fontSizeSmall,
                                                       ),
                                                     ),
                                                   ),
                                                 ),
                                               ),
                                               Expanded(
                                                 child: InkWell(
                                                   onTap: () => setState(() => _selectedHistoryTab = 1),
                                                   borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                   child: Container(
                                                     padding: const EdgeInsets.symmetric(vertical: 8),
                                                     alignment: Alignment.center,
                                                     decoration: BoxDecoration(
                                                       color: _selectedHistoryTab == 1
                                                           ? Theme.of(context).primaryColor
                                                           : Colors.transparent,
                                                       borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                     ),
                                                     child: Text(
                                                       "topup_requests_history".tr,
                                                       style: robotoBold.copyWith(
                                                         color: _selectedHistoryTab == 1
                                                             ? Colors.white
                                                             : Theme.of(context).textTheme.bodyLarge?.color,
                                                         fontSize: Dimensions.fontSizeSmall,
                                                       ),
                                                     ),
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
                                         const SizedBox(height: Dimensions.paddingSizeDefault),

                                         _selectedHistoryTab == 0
                                             ? Column(
                                                 crossAxisAlignment: CrossAxisAlignment.start,
                                                 children: [
                                                   if (bankController.transactions != null &&
                                                       bankController.transactions!.isNotEmpty)
                                                     Align(
                                                       alignment: Alignment.centerLeft,
                                                       child: InkWell(
                                                         onTap: () {
                                                           Get.toNamed(
                                                             RouteHelper.getPaymentHistoryRoute(),
                                                           );
                                                         },
                                                         child: Padding(
                                                           padding: const EdgeInsets.only(bottom: 8),
                                                           child: Text(
                                                             'view_all'.tr,
                                                             style: robotoMedium.copyWith(
                                                               fontSize: Dimensions.fontSizeSmall,
                                                               color: Theme.of(context).primaryColor,
                                                             ),
                                                           ),
                                                         ),
                                                       ),
                                                     ),
                                                   bankController.transactions != null
                                                       ? bankController.transactions!.isNotEmpty
                                                           ? ListView.builder(
                                                               itemCount: bankController.transactions!.length > 25
                                                                   ? 25
                                                                   : bankController.transactions!.length,
                                                               shrinkWrap: true,
                                                               padding: const EdgeInsets.only(
                                                                 bottom: Dimensions.paddingSizeDefault,
                                                               ),
                                                               physics: const NeverScrollableScrollPhysics(),
                                                               itemBuilder: (context, index) {
                                                                 return Column(
                                                                   children: [
                                                                     Padding(
                                                                       padding: const EdgeInsets.symmetric(
                                                                         vertical: Dimensions.paddingSizeLarge,
                                                                       ),
                                                                       child: Row(
                                                                         children: [
                                                                           Expanded(
                                                                             child: Column(
                                                                               crossAxisAlignment: CrossAxisAlignment.start,
                                                                               children: [
                                                                                 Text(
                                                                                   PriceConverterHelper.convertPrice(
                                                                                     bankController.transactions![index].amount,
                                                                                   ),
                                                                                   style: robotoMedium.copyWith(
                                                                                     fontSize: Dimensions.fontSizeDefault,
                                                                                   ),
                                                                                 ),
                                                                                 const SizedBox(
                                                                                   height: Dimensions.paddingSizeExtraSmall,
                                                                                 ),
                                                                                 Text(
                                                                                   '${'paid_via'.tr} ${bankController.transactions![index].method?.replaceAll('_', ' ').capitalize ?? ''}',
                                                                                   style: robotoRegular.copyWith(
                                                                                     fontSize: Dimensions.fontSizeExtraSmall,
                                                                                     color: Theme.of(context).disabledColor,
                                                                                   ),
                                                                                 ),
                                                                               ],
                                                                             ),
                                                                           ),
                                                                           Text(
                                                                             bankController.transactions![index].paymentTime.toString(),
                                                                             style: robotoRegular.copyWith(
                                                                               fontSize: Dimensions.fontSizeSmall,
                                                                               color: Theme.of(context).disabledColor,
                                                                             ),
                                                                           ),
                                                                         ],
                                                                       ),
                                                                     ),
                                                                     const Divider(height: 1),
                                                                   ],
                                                                 );
                                                               },
                                                             )
                                                           : Center(
                                                               child: Padding(
                                                                 padding: const EdgeInsets.only(top: 40, bottom: 40),
                                                                 child: Text('no_transaction_found'.tr),
                                                               ),
                                                             )
                                                       : const Center(
                                                           child: Padding(
                                                             padding: EdgeInsets.only(top: 40, bottom: 40),
                                                             child: CircularProgressIndicator(),
                                                           ),
                                                         ),
                                                 ],
                                               )
                                             : const TopupRequestHistoryWidget(),
                                      ],
                                    ),
                                  ),
                                ),

                                (profileController
                                            .profileModel!
                                            .overFlowWarning! ||
                                        profileController
                                            .profileModel!
                                            .overFlowBlockWarning!)
                                    ? WalletAttentionAlertWidget(
                                        isOverFlowBlockWarning:
                                            profileController
                                                .profileModel!
                                                .overFlowBlockWarning!,
                                      )
                                    : const SizedBox(),
                              ],
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
