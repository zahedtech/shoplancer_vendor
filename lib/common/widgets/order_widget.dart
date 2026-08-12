import 'package:shoplancer_vendor/common/widgets/custom_ink_well_widget.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_model.dart';
import 'package:shoplancer_vendor/helper/date_converter_helper.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/common/widgets/confirmation_dialog_widget.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/features/language/controllers/language_controller.dart';

class OrderWidget extends StatelessWidget {
  final OrderModel orderModel;
  final bool hasDivider;
  final bool isRunning;
  final bool showStatus;
  const OrderWidget({
    super.key,
    required this.orderModel,
    required this.hasDivider,
    required this.isRunning,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isStoreSuspended = false;
    if (Get.isRegistered<ProfileController>()) {
      var profile = Get.find<ProfileController>().profileModel;
      if (profile != null) {
        bool suspendedFlag = profile.isSuspended ?? false;
        double prepaid = profile.prepaidBalance ?? 0.0;
        double minLimit = profile.minPrepaidBalanceLimit ?? 0.0;
        bool exceededLimit = minLimit > 0 ? (prepaid < -minLimit) : false;
        isStoreSuspended = suspendedFlag || exceededLimit;
      }
    }

    DateTime? orderCreatedAt;
    if (orderModel.createdAt != null && orderModel.createdAt!.isNotEmpty) {
      orderCreatedAt = DateTime.tryParse(orderModel.createdAt!)?.toLocal();
    }

    final bool isCompletedOrCanceled = orderModel.orderStatus == 'delivered' ||
        orderModel.orderStatus == 'canceled' ||
        orderModel.orderStatus == 'refunded' ||
        orderModel.orderStatus == 'failed';

    final bool isOver4Hours = orderCreatedAt != null &&
        !isCompletedOrCanceled &&
        DateTime.now().difference(orderCreatedAt).inMinutes >= 240;

    Widget childWidget = Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'order'.tr,
                      style: robotoRegular.copyWith(
                        color: isOver4Hours
                            ? Colors.red.shade700
                            : Theme.of(context).hintColor,
                      ),
                    ),
                    Text(
                      ' # ${orderModel.id}',
                      style: robotoBold.copyWith(
                        color: isOver4Hours ? Colors.red.shade700 : null,
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    if (isOver4Hours) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSmall,
                          ),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_filled,
                              size: 11,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'over_4_hours'.tr,
                              style: robotoBold.copyWith(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    ],
                    Text(
                      orderModel.createdAt != null
                          ? DateConverterHelper.orderCardDate(
                              orderModel.createdAt!,
                            )
                          : '',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: isOver4Hours
                            ? Colors.red.shade700
                            : Theme.of(context).hintColor,
                        fontWeight: isOver4Hours
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            //Customer name
            Builder(
              builder: (context) {
                String customerName = '';
                if (orderModel.customer != null) {
                  customerName = '${orderModel.customer?.fName ?? ''} ${orderModel.customer?.lName ?? ''}'.trim();
                }
                if (customerName.isEmpty) {
                  customerName = orderModel.deliveryAddress?.contactPersonName ?? "Unknown";
                }
                if (customerName.isEmpty) {
                  customerName = "Unknown";
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "customer_name".tr,
                            style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Flexible(
                            child: Text(
                              customerName,
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).textTheme.bodyLarge?.color
                                    ?.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall,
                        vertical: Dimensions.paddingSizeExtraSmall,
                      ),
                      decoration: BoxDecoration(
                        color: isOver4Hours
                            ? Colors.red.withValues(alpha: 0.15)
                            : (orderModel.orderStatus == 'pending' ||
                                (orderModel.moduleType == 'grocery' &&
                                    (orderModel.orderStatus == 'confirmed' ||
                                        orderModel.orderStatus == 'processing' ||
                                        orderModel.orderStatus == 'cooking')))
                            ? Colors.blueAccent.withValues(alpha: 0.1)
                            : (orderModel.orderStatus == 'confirmed' ||
                                  orderModel.orderStatus == 'processing' ||
                                  orderModel.orderStatus == 'cooking')
                            ? Colors.teal.withValues(alpha: 0.1)
                            : orderModel.orderStatus == 'delivered'
                            ? Colors.indigo.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        border: isOver4Hours
                            ? Border.all(
                                color: Colors.red.withValues(alpha: 0.4),
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        orderModel.orderStatus == 'picked_up'
                            ? 'item'.tr + ' ' + 'on_the_way'.tr
                            : (orderModel.moduleType == 'grocery' &&
                                  (orderModel.orderStatus == 'confirmed' ||
                                      orderModel.orderStatus == 'processing' ||
                                      orderModel.orderStatus == 'cooking'))
                            ? 'pending'.tr
                            : (orderModel.orderStatus ?? '').tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: isOver4Hours
                              ? Colors.red
                              : (orderModel.orderStatus == 'pending' ||
                                  (orderModel.moduleType == 'grocery' &&
                                      (orderModel.orderStatus == 'confirmed' ||
                                          orderModel.orderStatus == 'processing' ||
                                          orderModel.orderStatus == 'cooking')))
                              ? Colors.blueAccent
                              : (orderModel.orderStatus == 'confirmed' ||
                                    orderModel.orderStatus == 'processing' ||
                                    orderModel.orderStatus == 'cooking')
                              ? Colors.teal
                              : orderModel.orderStatus == 'delivered'
                              ? Colors.indigo
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        Divider(),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'payment_method'.tr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Text(
                    orderModel.paymentMethod == 'cash_on_delivery'
                        ? 'cash_on_delivery'.tr
                        : orderModel.paymentMethod == 'wallet'
                        ? 'wallet_payment'.tr
                        : orderModel.paymentMethod == 'cash'
                        ? 'cash'.tr
                        : orderModel.paymentMethod == 'digital_payment'
                        ? 'digital_payment'.tr
                        : (orderModel.paymentMethod ?? '')
                              .replaceAll('_', ' ')
                              .tr,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: isOver4Hours
                          ? Colors.red.shade700
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'total_amount'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Text(
                  PriceConverterHelper.convertPrice(orderModel.orderAmount),
                  style: robotoBold,
                ),
              ],
            ),
          ],
        ),
        const Divider(height: Dimensions.paddingSizeSmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'view_details'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: isOver4Hours
                    ? Colors.red.shade700
                    : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Icon(
              Get.find<LocalizationController>().isLtr
                  ? Icons.arrow_back_ios
                  : Icons.arrow_forward_ios,
              size: 13,
              color: isOver4Hours
                  ? Colors.red.shade700
                  : Theme.of(context).primaryColor,
            ),
          ],
        ),
      ],
    );

    if (isStoreSuspended) {
      childWidget = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: childWidget,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: isOver4Hours
            ? (Get.isDarkMode
                ? Colors.red.withValues(alpha: 0.08)
                : const Color(0xFFFFF5F5))
            : Theme.of(context).cardColor,
        border: Border.all(
          color: isOver4Hours
              ? Colors.red.shade400
              : Theme.of(context).hintColor.withValues(alpha: 0.3),
          width: isOver4Hours ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isOver4Hours
                ? Colors.red.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomInkWellWidget(
        onTap: () {
          if (isStoreSuspended) {
            Get.dialog(
              ConfirmationDialogWidget(
                icon: Images.attentionWarningIcon,
                title: 'store_suspended'.tr,
                description: 'store_suspended_prepaid_desc'.tr,
                onYesPressed: () {
                  Get.back();
                  Get.toNamed(RouteHelper.getWalletRoute());
                },
                onYesButtonText: 'recharge_now'.tr,
                isOnNoPressedShow: true,
                onNoButtonText: 'cancel'.tr,
              ),
              barrierDismissible: false,
            );
          } else {
            Get.toNamed(RouteHelper.getOrderDetailsRoute(orderModel.id));
          }
        },
        radius: Dimensions.radiusDefault,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Stack(
            alignment: Alignment.center,
            children: [
              childWidget,
              if (isStoreSuspended)
                Icon(
                  Icons.lock_outline,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
