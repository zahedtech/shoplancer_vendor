import 'dart:async';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shoplancer_vendor/features/chat/domain/models/conversation_model.dart';
import 'package:shoplancer_vendor/features/notification/domain/models/notification_body_model.dart';
import 'package:shoplancer_vendor/features/order/widgets/invoice_dialog_widget.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shoplancer_vendor/features/language/controllers/language_controller.dart';
import 'package:shoplancer_vendor/features/order/controllers/order_controller.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_details_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/helper/date_converter_helper.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/responsive_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/app_constants.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/confirmation_dialog_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/input_dialog_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/features/order/widgets/amount_input_dialogue_widget.dart';
import 'package:shoplancer_vendor/features/order/widgets/camera_button_sheet_widget.dart';
import 'package:shoplancer_vendor/features/order/widgets/cancellation_dialogue_widget.dart';
import 'package:shoplancer_vendor/features/order/widgets/collect_money_delivery_sheet_widget.dart';
import 'package:shoplancer_vendor/features/order/widgets/order_item_widget.dart';
import 'package:shoplancer_vendor/features/order/widgets/slider_button_widget.dart';
import 'package:shoplancer_vendor/features/order/widgets/verify_delivery_sheet_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final bool isRunningOrder;
  final bool fromNotification;
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.isRunningOrder,
    this.fromNotification = false,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool selfDelivery = false;
  bool _isExpanded = true;
  bool isViewMore = false;

  Future<void> loadData() async {
    if (Get.find<ProfileController>().profileModel == null) {
      Get.find<ProfileController>().getProfile();
    }
    Get.find<OrderController>().pickPrescriptionImage(
      isRemove: true,
      isCamera: false,
    );
    await Get.find<OrderController>().getOrderDetails(widget.orderId);

    ///order

    Get.find<OrderController>().getOrderItemsDetails(widget.orderId);

    ///order details

    if (Get.find<OrderController>().showDeliveryImageField) {
      Get.find<OrderController>().changeDeliveryImageStatus(isUpdate: false);
    }

    _startApiCalling();
  }

  void _startApiCalling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      Get.find<OrderController>().getOrderDetails(widget.orderId);
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    Get.find<OrderController>().clearPreviousData();
    loadData();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startApiCalling();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);

    _timer?.cancel();
  }

  void _shareInvoice(OrderController controller) {
    String invoiceText = "${'order_id'.tr}: ${controller.orderModel!.id}\n";
    invoiceText +=
        "${'order_date'.tr}: ${DateConverterHelper.dateTimeStringToMonthAndTime(controller.orderModel!.createdAt!)}\n";
    invoiceText +=
        "${'customer_name'.tr} ${controller.orderModel!.deliveryAddress?.contactPersonName ?? ''}\n";
    invoiceText +=
        "${'payment_method'.tr}: ${controller.orderModel!.paymentMethod!.tr}\n\n";

    invoiceText += "${'items'.tr}:\n";
    for (OrderDetailsModel detail in controller.orderDetailsModel!) {
      invoiceText +=
          "- ${detail.itemDetails!.name} x ${detail.quantity} = ${PriceConverterHelper.convertPrice(detail.price! * detail.quantity!)}\n";
      if (detail.addOns != null && detail.addOns!.isNotEmpty) {
        invoiceText += "  ${'addons'.tr}: ";
        for (int i = 0; i < detail.addOns!.length; i++) {
          invoiceText +=
              "${detail.addOns![i].name} (${detail.addOns![i].quantity})${i == detail.addOns!.length - 1 ? '' : ', '}";
        }
        invoiceText += "\n";
      }
    }

    invoiceText +=
        "\n${'item_price'.tr}: ${PriceConverterHelper.convertPrice(controller.orderModel!.orderAmount! - controller.orderModel!.deliveryCharge! - controller.orderModel!.totalTaxAmount! + controller.orderModel!.storeDiscountAmount!)}\n";
    invoiceText +=
        "${'delivery_fee'.tr}: ${PriceConverterHelper.convertPrice(controller.orderModel!.deliveryCharge!)}\n";
    invoiceText +=
        "${'vat_tax'.tr}: ${PriceConverterHelper.convertPrice(controller.orderModel!.totalTaxAmount!)}\n";
    invoiceText +=
        "${'total_amount'.tr}: ${PriceConverterHelper.convertPrice(controller.orderModel!.orderAmount!)}";

    Share.share(invoiceText);
  }

  void _shareInvoiceAsImage(OrderController controller) async {
    Get.dialog(
      InvoiceShareDialog(
        order: controller.orderModel,
        orderDetails: controller.orderDetailsModel,
        isPrescriptionOrder: controller.orderModel?.prescriptionOrder,
        dmTips: controller.orderModel!.dmTips!,
      ),
      barrierDismissible: false,
    );
  }

  bool _canStoreCancelOrder(OrderModel order, bool? cancelPermission) {
    final String status = order.orderStatus ?? '';

    // يسمح بالإلغاء فقط في حالتي pending أو confirmed
    if (status != AppConstants.pending && status != AppConstants.confirmed) {
      return false;
    }

    // لا يسمح بالإلغاء إذا كان الطلب قد سُلّم أو ألغي أو استُرد بالفعل
    bool hasStatusDate(String? value) =>
        value != null && value.trim().isNotEmpty;

    if (hasStatusDate(order.delivered) ||
        hasStatusDate(order.canceled) ||
        hasStatusDate(order.refunded) ||
        hasStatusDate(order.refundRequested)) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    bool? cancelPermission =
        Get.find<SplashController>().configModel!.canceledByStore;

    if (Get.find<ProfileController>().profileModel != null) {
      selfDelivery =
          Get.find<ProfileController>()
              .profileModel!
              .stores![0]
              .selfDeliverySystem ==
          1;
    }

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        if (widget.fromNotification && !didPop) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else {
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(
          context,
        ).disabledColor.withValues(alpha: 0.08),
        appBar: CustomAppBarWidget(
          titleWidget: GetBuilder<OrderController>(
            builder: (controller) {
              if (controller.orderModel == null) {
                return const SizedBox(height: 20);
              }
              return Column(
                children: [
                  Text(
                    "${'order'.tr} #${controller.orderModel!.id.toString().tr}",
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  Text(
                    controller.orderModel!.orderStatus! == 'picked_up'
                        ? 'on_the_way'.tr
                        : (controller.orderModel!.moduleType == 'grocery' &&
                              (controller.orderModel!.orderStatus ==
                                      'confirmed' ||
                                  controller.orderModel!.orderStatus ==
                                      'processing' ||
                                  controller.orderModel!.orderStatus ==
                                      'cooking'))
                        ? 'pending'.tr
                        : controller.orderModel!.orderStatus!.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),
          menuWidget: GetBuilder<OrderController>(
            builder: (controller) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      if (controller.orderModel != null &&
                          controller.orderDetailsModel != null) {
                        _shareInvoice(controller);
                      }
                    },
                    icon: Icon(
                      Icons.share,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (controller.orderModel != null &&
                          controller.orderDetailsModel != null) {
                        _shareInvoiceAsImage(controller);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        Images.downloadIcon,
                        height: 30,
                        width: 30,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          onTap: () {
            if (widget.fromNotification) {
              Get.offAllNamed(RouteHelper.getInitialRoute());
            } else {
              Get.back();
            }
          },
        ),
        body: SafeArea(
          child: GetBuilder<OrderController>(
            builder: (orderController) {
              OrderModel? controllerOrderModel = orderController.orderModel;
              bool restConfModel =
                  Get.find<SplashController>()
                      .configModel!
                      .orderConfirmationModel !=
                  'deliveryman';
              bool showSlider = controllerOrderModel != null
                  ? (controllerOrderModel.orderStatus == 'pending' &&
                            (controllerOrderModel.orderType == 'take_away' ||
                                restConfModel ||
                                selfDelivery)) ||
                        controllerOrderModel.orderStatus == 'confirmed' ||
                        controllerOrderModel.orderStatus == 'processing' ||
                        (controllerOrderModel.orderStatus == 'accepted' &&
                            controllerOrderModel.confirmed != null) ||
                        controllerOrderModel.orderStatus == 'handover' ||
                        controllerOrderModel.orderStatus == 'picked_up'
                  : false;
              bool showBottomView = controllerOrderModel != null
                  ? showSlider ||
                        controllerOrderModel.orderStatus == 'picked_up' ||
                        widget.isRunningOrder
                  : false;
              bool showDeliveryConfirmImage =
                  orderController.showDeliveryImageField;
              print(
                'Delivery man number => ${orderController.orderModel?.toJson()}',
              );

              double? deliveryCharge = 0;
              double itemsPrice = 0;
              double? discount = 0;
              double? couponDiscount = 0;
              double? tax = 0;
              double addOns = 0;
              double additionalCharge = 0;
              double extraPackagingAmount = 0;
              double referrerBonusAmount = 0;
              bool? isPrescriptionOrder = false;
              bool? taxIncluded = false;
              OrderModel? order = controllerOrderModel;
              if (order != null && orderController.orderDetailsModel != null) {
                if (order.orderType == 'delivery') {
                  deliveryCharge = order.deliveryCharge;
                  isPrescriptionOrder = order.prescriptionOrder;
                }
                discount =
                    order.storeDiscountAmount! +
                    order.flashAdminDiscountAmount! +
                    order.flashStoreDiscountAmount!;
                tax = order.totalTaxAmount;
                taxIncluded = order.taxStatus;
                additionalCharge = order.additionalCharge!;
                extraPackagingAmount = order.extraPackagingAmount!;
                referrerBonusAmount = order.referrerBonusAmount!;
                couponDiscount = order.couponDiscountAmount;
                if (isPrescriptionOrder!) {
                  double orderAmount = order.orderAmount ?? 0;
                  itemsPrice =
                      (orderAmount + discount) -
                      ((taxIncluded! ? 0 : tax!) +
                          deliveryCharge! +
                          additionalCharge);
                } else {
                  for (OrderDetailsModel orderDetails
                      in orderController.orderDetailsModel!) {
                    for (AddOn addOn in orderDetails.addOns!) {
                      addOns = addOns + (addOn.price! * addOn.quantity!);
                    }
                    itemsPrice =
                        itemsPrice +
                        (orderDetails.price! * orderDetails.quantity!);
                  }
                }
              }
              double subTotal = itemsPrice + addOns;
              double total =
                  itemsPrice +
                  addOns -
                  discount +
                  (taxIncluded! ? 0 : tax!) +
                  deliveryCharge! -
                  couponDiscount! +
                  additionalCharge +
                  extraPackagingAmount -
                  referrerBonusAmount;

              return (orderController.orderDetailsModel != null &&
                      controllerOrderModel != null)
                  ? Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                              bottom: Dimensions.paddingSizeSmall,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 1170,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      height: Dimensions.paddingSizeExtraSmall,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            Dimensions.paddingSizeDefault,
                                        vertical: Dimensions.paddingSizeSmall,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${'order_date'.tr}:',
                                            style: robotoRegular.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).hintColor,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(
                                            Icons.access_time,
                                            size: 18,
                                            color: Theme.of(
                                              context,
                                            ).disabledColor,
                                          ),
                                          Text(
                                            ' ${DateConverterHelper.orderCardDate(order!.createdAt!)}',
                                            style: robotoRegular,
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (order.paymentMethod ==
                                            'cash_on_delivery' ||
                                        order.paymentMethod == 'cash') ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.paddingSizeDefault,
                                          vertical:
                                              Dimensions.paddingSizeExtraSmall,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '${'payment_method'.tr}:',
                                              style: robotoRegular.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).hintColor,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.monetization_on_outlined,
                                              size: 18,
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'cash'.tr,
                                              style: robotoBold.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: Dimensions.paddingSizeSmall,
                                      ),
                                    ],

                                    /// Item info
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            Dimensions.paddingSizeDefault,
                                        vertical: Dimensions.paddingSizeSmall,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.radiusSmall,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: Offset(0, 3),
                                            color:
                                                Colors.grey[Get.isDarkMode
                                                    ? 700
                                                    : 300]!,
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'item_info'.tr,
                                                style: robotoBold,
                                              ),
                                              const SizedBox(
                                                width: Dimensions
                                                    .paddingSizeExtraSmall,
                                              ),
                                              Container(
                                                width: Dimensions
                                                    .paddingSizeExtremeLarge,
                                                height: Dimensions
                                                    .paddingSizeExtremeLarge,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions.radiusLarge,
                                                      ),
                                                  color: Theme.of(
                                                    context,
                                                  ).hintColor.withOpacity(0.2),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    orderController
                                                        .orderDetailsModel!
                                                        .length
                                                        .toString(),
                                                    style: robotoMedium,
                                                  ),
                                                ),
                                              ),
                                              Spacer(),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _isExpanded = !_isExpanded;
                                                  });
                                                },
                                                icon: Icon(
                                                  _isExpanded
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                            .keyboard_arrow_down,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),

                                          //check if ready for delivery
                                          if (orderController
                                              .isOrderChecklistComplete(
                                                order!.id!,
                                              )) ...[
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(
                                                Dimensions.paddingSizeSmall,
                                              ),
                                              margin: const EdgeInsets.only(
                                                bottom:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      Dimensions.radiusSmall,
                                                    ),
                                                border: Border.all(
                                                  color: Colors.green
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(
                                                    width: Dimensions
                                                        .paddingSizeSmall,
                                                  ),
                                                  Text(
                                                    'all_items_prepared_and_ready_for_delivery'
                                                        .tr,
                                                    style: robotoMedium
                                                        .copyWith(
                                                          color: Colors.green,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],

                                          if (_isExpanded)
                                            Column(
                                              children: [
                                                Divider(
                                                  thickness: 1,
                                                  color: Theme.of(
                                                    context,
                                                  ).hintColor.withOpacity(0.1),
                                                ),
                                                ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount: orderController
                                                      .orderDetailsModel!
                                                      .length,
                                                  itemBuilder: (context, index) {
                                                    return Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            if (orderController
                                                                        .orderModel!
                                                                        .orderStatus !=
                                                                    'delivered' &&
                                                                orderController
                                                                        .orderModel!
                                                                        .orderStatus !=
                                                                    'canceled' &&
                                                                orderController
                                                                        .orderModel!
                                                                        .orderStatus !=
                                                                    'failed' &&
                                                                orderController
                                                                        .orderModel!
                                                                        .orderStatus !=
                                                                    'refunded')
                                                              Checkbox(
                                                                value: orderController
                                                                    .isItemChecked(
                                                                      order!
                                                                          .id!,
                                                                      orderController
                                                                          .orderDetailsModel![index]
                                                                          .id!,
                                                                    ),
                                                                activeColor:
                                                                    Theme.of(
                                                                      context,
                                                                    ).primaryColor,
                                                                visualDensity:
                                                                    const VisualDensity(
                                                                      horizontal:
                                                                          -4,
                                                                      vertical:
                                                                          -4,
                                                                    ),
                                                                onChanged: (bool? value) {
                                                                  orderController.toggleItemCheck(
                                                                    order!.id!,
                                                                    orderController
                                                                        .orderDetailsModel![index]
                                                                        .id!,
                                                                  );
                                                                },
                                                              ),
                                                            const SizedBox(
                                                              width: Dimensions
                                                                  .paddingSizeExtraSmall,
                                                            ),
                                                            Expanded(
                                                              child: OrderItemWidget(
                                                                order: order,
                                                                orderDetails:
                                                                    orderController
                                                                        .orderDetailsModel![index],
                                                              ),
                                                            ),
                                                            if ([
                                                              'pending',
                                                              'accepted',
                                                              'confirmed',
                                                              'processing',
                                                              'cooking',
                                                            ].contains(
                                                              orderController
                                                                  .orderModel!
                                                                  .orderStatus,
                                                            ))
                                                              PopupMenuButton<
                                                                String
                                                              >(
                                                                icon: Icon(
                                                                  Icons
                                                                      .more_vert,
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).primaryColor,
                                                                ),
                                                                onSelected: (String result) async {
                                                                  if (result ==
                                                                      'delete') {
                                                                    Get.dialog(
                                                                      ConfirmationDialogWidget(
                                                                        icon: Images
                                                                            .warning,
                                                                        title: 'are_you_sure_to_remove'
                                                                            .tr,
                                                                        description:
                                                                            'you_want_to_remove_this_item'.tr,
                                                                        onYesPressed: () async {
                                                                          Get.back();
                                                                          Map<
                                                                            String,
                                                                            dynamic
                                                                          >
                                                                          body = {
                                                                            'order_id':
                                                                                order.id,
                                                                            'action':
                                                                                'remove',
                                                                            'item_id':
                                                                                orderController.orderDetailsModel![index].itemDetails!.id,
                                                                          };
                                                                          await orderController.updateOrderItems(
                                                                            body,
                                                                          );
                                                                        },
                                                                      ),
                                                                    );
                                                                  } else if (result ==
                                                                      'replace') {
                                                                    var selection =
                                                                        await Get.toNamed(
                                                                          RouteHelper.getAlternativeItemSelectionRoute(
                                                                            order.id!,
                                                                          ),
                                                                        );
                                                                    if (selection !=
                                                                        null) {
                                                                      Item
                                                                      selectedItem =
                                                                          selection['item'];
                                                                      int
                                                                      quantity =
                                                                          selection['quantity'];

                                                                      // Remove old item
                                                                      Map<
                                                                        String,
                                                                        dynamic
                                                                      >
                                                                      removeBody = {
                                                                        'order_id':
                                                                            order.id,
                                                                        'action':
                                                                            'remove',
                                                                        'item_id': orderController
                                                                            .orderDetailsModel![index]
                                                                            .itemDetails!
                                                                            .id,
                                                                      };
                                                                      bool
                                                                      removeSuccess =
                                                                          await orderController.updateOrderItems(
                                                                            removeBody,
                                                                          );

                                                                      if (removeSuccess) {
                                                                        // Add new item
                                                                        Map<
                                                                          String,
                                                                          dynamic
                                                                        >
                                                                        addBody = {
                                                                          'order_id':
                                                                              order.id,
                                                                          'action':
                                                                              'add',
                                                                          'item_id':
                                                                              selectedItem.id,
                                                                          'quantity':
                                                                              quantity,
                                                                          'variation':
                                                                              [],
                                                                          'add_on_ids':
                                                                              [],
                                                                          'add_on_qtys':
                                                                              [],
                                                                        };
                                                                        await orderController.updateOrderItems(
                                                                          addBody,
                                                                        );
                                                                      }
                                                                    }
                                                                  }
                                                                },
                                                                itemBuilder:
                                                                    (
                                                                      BuildContext
                                                                      context,
                                                                    ) =>
                                                                        <
                                                                          PopupMenuEntry<
                                                                            String
                                                                          >
                                                                        >[
                                                                          PopupMenuItem<
                                                                            String
                                                                          >(
                                                                            value:
                                                                                'replace',
                                                                            child: Text(
                                                                              'replace'.tr,
                                                                            ),
                                                                          ),
                                                                          PopupMenuItem<
                                                                            String
                                                                          >(
                                                                            value:
                                                                                'delete',
                                                                            child: Text(
                                                                              'delete'.tr,
                                                                            ),
                                                                          ),
                                                                        ],
                                                              ),
                                                          ],
                                                        ),
                                                        if (orderController
                                                                    .orderDetailsModel!
                                                                    .length >
                                                                1 &&
                                                            index <
                                                                orderController
                                                                        .orderDetailsModel!
                                                                        .length -
                                                                    1)
                                                          Divider(
                                                            thickness: 1,
                                                            height: 30,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    ).hintColor
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                          ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),

                                    /// Instructions / Notes
                                    ((order!.orderNote != null &&
                                                order.orderNote!.isNotEmpty) ||
                                            (order.unavailableItemNote !=
                                                    null &&
                                                order
                                                    .unavailableItemNote!
                                                    .isNotEmpty) ||
                                            (order.deliveryInstruction !=
                                                    null &&
                                                order
                                                    .deliveryInstruction!
                                                    .isNotEmpty))
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeDefault,
                                              ),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  Dimensions.paddingSizeDefault,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).cardColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions.radiusSmall,
                                                      ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                      color:
                                                          Colors.grey[Get
                                                                  .isDarkMode
                                                              ? 700
                                                              : 200]!,
                                                      blurRadius: 8,
                                                      spreadRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'notes'.tr,
                                                      style: robotoBold,
                                                    ),
                                                    Divider(
                                                      thickness: 1,
                                                      color: Theme.of(context)
                                                          .hintColor
                                                          .withOpacity(0.1),
                                                    ),

                                                    if (order.orderNote !=
                                                            null &&
                                                        order
                                                            .orderNote!
                                                            .isNotEmpty) ...[
                                                      Text(
                                                        'additional_note'.tr,
                                                        style: robotoMedium,
                                                      ),
                                                      const SizedBox(
                                                        height: Dimensions
                                                            .paddingSizeExtraSmall,
                                                      ),
                                                      Text(
                                                        order.orderNote!,
                                                        style: robotoRegular
                                                            .copyWith(
                                                              color: Theme.of(
                                                                context,
                                                              ).hintColor,
                                                            ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            (order.unavailableItemNote !=
                                                                        null &&
                                                                    order
                                                                        .unavailableItemNote!
                                                                        .isNotEmpty) ||
                                                                (order.deliveryInstruction !=
                                                                        null &&
                                                                    order
                                                                        .deliveryInstruction!
                                                                        .isNotEmpty)
                                                            ? Dimensions
                                                                  .paddingSizeSmall
                                                            : 0,
                                                      ),
                                                    ],

                                                    if (order.unavailableItemNote !=
                                                            null &&
                                                        order
                                                            .unavailableItemNote!
                                                            .isNotEmpty) ...[
                                                      Text(
                                                        'unavailable_item_note'
                                                            .tr,
                                                        style: robotoMedium,
                                                      ),
                                                      const SizedBox(
                                                        height: Dimensions
                                                            .paddingSizeExtraSmall,
                                                      ),
                                                      Text(
                                                        order
                                                            .unavailableItemNote!,
                                                        style: robotoRegular
                                                            .copyWith(
                                                              color:
                                                                  Colors.orange,
                                                            ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            (order.deliveryInstruction !=
                                                                    null &&
                                                                order
                                                                    .deliveryInstruction!
                                                                    .isNotEmpty)
                                                            ? Dimensions
                                                                  .paddingSizeSmall
                                                            : 0,
                                                      ),
                                                    ],

                                                    if (order.deliveryInstruction !=
                                                            null &&
                                                        order
                                                            .deliveryInstruction!
                                                            .isNotEmpty) ...[
                                                      Text(
                                                        'delivery_instruction'
                                                            .tr,
                                                        style: robotoMedium,
                                                      ),
                                                      const SizedBox(
                                                        height: Dimensions
                                                            .paddingSizeExtraSmall,
                                                      ),
                                                      Text(
                                                        '${order.deliveryInstruction}'
                                                            .tr,
                                                        style: robotoRegular
                                                            .copyWith(
                                                              color: Theme.of(
                                                                context,
                                                              ).hintColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),

                                    /// Delivery & Customer Info
                                    if (order.deliveryAddress != null ||
                                        order.deliveryInstruction != null ||
                                        order.customer != null) ...[
                                      const SizedBox(
                                        height: Dimensions.paddingSizeDefault,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.paddingSizeDefault,
                                          vertical: Dimensions.paddingSizeSmall,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(
                                            Dimensions.radiusSmall,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              offset: const Offset(0, 3),
                                              color:
                                                  Colors.grey[Get.isDarkMode
                                                      ? 700
                                                      : 300]!,
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'تفاصيل العميل والطلب'.tr,
                                                  style: robotoBold,
                                                ),
                                                const Spacer(),
                                                Text(
                                                  order.orderType == 'delivery'
                                                      ? 'home_delivery'.tr
                                                      : (order.orderType ?? '')
                                                            .tr,
                                                  style: robotoMedium.copyWith(
                                                    color: Colors.blueAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Divider(
                                              thickness: 1,
                                              color: Theme.of(
                                                context,
                                              ).hintColor.withOpacity(0.1),
                                            ),

                                            // Customer Info
                                            Builder(
                                              builder: (context) {
                                                String cName = '';
                                                if (order.customer != null) {
                                                  cName =
                                                      '${order.customer!.fName ?? ''} ${order.customer!.lName ?? ''}'
                                                          .trim();
                                                }
                                                if (cName.isEmpty &&
                                                    order
                                                            .deliveryAddress
                                                            ?.contactPersonName !=
                                                        null) {
                                                  cName = order
                                                      .deliveryAddress!
                                                      .contactPersonName!;
                                                }
                                                if (cName.isEmpty) {
                                                  cName = 'عميل زائر';
                                                }

                                                String cPhone =
                                                    order.customer?.phone ??
                                                    order
                                                        .deliveryAddress
                                                        ?.contactPersonNumber ??
                                                    '';

                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Image.asset(
                                                          Images.userIcon,
                                                          width: 14,
                                                          height: 14,
                                                        ),
                                                        const SizedBox(
                                                          width: Dimensions
                                                              .paddingSizeSmall,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            cName,
                                                            style: robotoMedium
                                                                .copyWith(
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeSmall,
                                                                ),
                                                          ),
                                                        ),
                                                        if (cPhone.isNotEmpty)
                                                          IconButton(
                                                            onPressed: () async {
                                                              if (await canLaunchUrlString(
                                                                'tel:$cPhone',
                                                              )) {
                                                                launchUrlString(
                                                                  'tel:$cPhone',
                                                                  mode: LaunchMode
                                                                      .externalApplication,
                                                                );
                                                              } else {
                                                                showCustomSnackBar(
                                                                  '${'can_not_launch'.tr} $cPhone',
                                                                );
                                                              }
                                                            },
                                                            icon: Image.asset(
                                                              Images.callIcon,
                                                              width: 22,
                                                              height: 22,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    if (cPhone.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.phone,
                                                            size: 14,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(
                                                            width: Dimensions
                                                                .paddingSizeSmall,
                                                          ),
                                                          Text(
                                                            cPhone,
                                                            style: robotoMedium
                                                                .copyWith(
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).hintColor,
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeSmall,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                    // Address if available
                                                    if (order
                                                            .deliveryAddress
                                                            ?.address !=
                                                        null) ...[
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Image.asset(
                                                            Images.markerIcon,
                                                            width: 12,
                                                            height: 12,
                                                          ),
                                                          const SizedBox(
                                                            width: Dimensions
                                                                .paddingSizeSmall,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              order
                                                                  .deliveryAddress!
                                                                  .address!,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: robotoMedium.copyWith(
                                                                color: Theme.of(
                                                                  context,
                                                                ).hintColor,
                                                                fontSize: Dimensions
                                                                    .fontSizeSmall,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    /// cutlery
                                    Get.find<SplashController>()
                                            .getModuleConfig(order.moduleType)
                                            .newVariation!
                                        ? Column(
                                            children: [
                                              const Divider(
                                                height:
                                                    Dimensions.paddingSizeLarge,
                                              ),

                                              Row(
                                                children: [
                                                  Text(
                                                    '${'cutlery'.tr}: ',
                                                    style: robotoRegular,
                                                  ),
                                                  const Expanded(
                                                    child: SizedBox(),
                                                  ),

                                                  Text(
                                                    order.cutlery!
                                                        ? 'yes'.tr
                                                        : 'no'.tr,
                                                    style: robotoRegular,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),

                                    // / unavailable_item_note
                                    order.unavailableItemNote != null
                                        ? Column(
                                            children: [
                                              const Divider(
                                                height:
                                                    Dimensions.paddingSizeLarge,
                                              ),

                                              Row(
                                                children: [
                                                  Text(
                                                    '${'unavailable_item_note'.tr}: ',
                                                    style: robotoMedium,
                                                  ),

                                                  Text(
                                                    order.unavailableItemNote!,
                                                    style: robotoRegular,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),

                                    // / delivery_instruction
                                    order.deliveryInstruction != null
                                        ? Column(
                                            children: [
                                              const Divider(
                                                height:
                                                    Dimensions.paddingSizeLarge,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${'delivery_instruction'.tr}: ',
                                                    style: robotoMedium,
                                                  ),
                                                  Text(
                                                    order
                                                            .deliveryInstruction
                                                            ?.tr ??
                                                        '',
                                                    style: robotoRegular,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),
                                    SizedBox(
                                      height: order.deliveryInstruction != null
                                          ? Dimensions.paddingSizeSmall
                                          : 0,
                                    ),

                                    // / in_change_for_the_customer_when_making_the_delivery
                                    order.bringChangeAmount != null &&
                                            order.bringChangeAmount! > 0
                                        ? Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(
                                              Dimensions.paddingSizeSmall,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0XFF009AF1,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    Dimensions.radiusSmall,
                                                  ),
                                            ),
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'please_bring'.tr,
                                                    style: robotoRegular
                                                        .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color,
                                                        ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        ' ${PriceConverterHelper.convertPrice(order.bringChangeAmount)}',
                                                    style: robotoMedium
                                                        .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color,
                                                        ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        ' ${'in_change_for_the_customer_when_making_the_delivery'.tr}',
                                                    style: robotoRegular
                                                        .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : const SizedBox(),

                                    // / Additional Note
                                    (order.orderNote != null &&
                                            order.orderNote!.isNotEmpty)
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'additional_note'.tr,
                                                style: robotoRegular,
                                              ),
                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              Container(
                                                width: 1170,
                                                padding: const EdgeInsets.all(
                                                  Dimensions.paddingSizeSmall,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions.radiusSmall,
                                                      ),
                                                  border: Border.all(
                                                    width: 1,
                                                    color: Theme.of(
                                                      context,
                                                    ).disabledColor,
                                                  ),
                                                ),
                                                child: Text(
                                                  order.orderNote!,
                                                  style: robotoRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                    color: Theme.of(
                                                      context,
                                                    ).disabledColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeLarge,
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),

                                    // / prescription
                                    (Get.find<SplashController>()
                                                .getModuleConfig(
                                                  order.moduleType,
                                                )
                                                .orderAttachment! &&
                                            order.orderAttachmentFullUrl !=
                                                null &&
                                            order
                                                .orderAttachmentFullUrl!
                                                .isNotEmpty)
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'prescription'.tr,
                                                style: robotoRegular,
                                              ),
                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              GridView.builder(
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                      childAspectRatio: 1,
                                                      crossAxisCount:
                                                          ResponsiveHelper.isTab(
                                                            context,
                                                          )
                                                          ? 5
                                                          : 3,
                                                      mainAxisSpacing: 10,
                                                      crossAxisSpacing: 5,
                                                    ),
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount: order
                                                    .orderAttachmentFullUrl!
                                                    .length,
                                                itemBuilder: (BuildContext context, index) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 8,
                                                        ),
                                                    child: InkWell(
                                                      onTap: () => openDialog(
                                                        context,
                                                        order
                                                            .orderAttachmentFullUrl![index],
                                                      ),
                                                      child: Center(
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                Dimensions
                                                                    .radiusSmall,
                                                              ),
                                                          child: CustomImageWidget(
                                                            image: order
                                                                .orderAttachmentFullUrl![index],
                                                            width: 100,
                                                            height: 100,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeLarge,
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),

                                    // / order_proof
                                    (controllerOrderModel.orderStatus ==
                                                'delivered' &&
                                            order.orderProofFullUrl != null &&
                                            order.orderProofFullUrl!.isNotEmpty)
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'order_proof'.tr,
                                                style: robotoRegular,
                                              ),
                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeSmall,
                                              ),

                                              GridView.builder(
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                      childAspectRatio: 1.5,
                                                      crossAxisCount:
                                                          ResponsiveHelper.isTab(
                                                            context,
                                                          )
                                                          ? 5
                                                          : 3,
                                                      mainAxisSpacing: 10,
                                                      crossAxisSpacing: 5,
                                                    ),
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount: order
                                                    .orderProofFullUrl!
                                                    .length,
                                                itemBuilder: (BuildContext context, index) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 8,
                                                        ),
                                                    child: InkWell(
                                                      onTap: () => openDialog(
                                                        context,
                                                        order
                                                            .orderProofFullUrl![index],
                                                      ),
                                                      child: Center(
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                Dimensions
                                                                    .radiusSmall,
                                                              ),
                                                          child: CustomImageWidget(
                                                            image: order
                                                                .orderProofFullUrl![index],
                                                            width: 100,
                                                            height: 100,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),

                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeLarge,
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),

                                    // / Customer details
                                    Text(
                                      'customer_details'.tr,
                                      style: robotoRegular,
                                    ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeExtraSmall,
                                    ),

                                    order.deliveryAddress != null
                                        ? Row(
                                            children: [
                                              SizedBox(
                                                height: 35,
                                                width: 35,
                                                child: ClipOval(
                                                  child: CustomImageWidget(
                                                    image:
                                                        '${order.customer != null ? order.customer!.imageFullUrl : ''}',
                                                    height: 35,
                                                    width: 35,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      order
                                                          .deliveryAddress!
                                                          .contactPersonName!,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: robotoRegular
                                                          .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                          ),
                                                    ),
                                                    Text(
                                                      order
                                                              .deliveryAddress!
                                                              .address ??
                                                          '',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: robotoRegular
                                                          .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                            color: Theme.of(
                                                              context,
                                                            ).disabledColor,
                                                          ),
                                                    ),

                                                    Wrap(
                                                      children: [
                                                        (order.deliveryAddress!.streetNumber !=
                                                                    null &&
                                                                order
                                                                    .deliveryAddress!
                                                                    .streetNumber!
                                                                    .isNotEmpty)
                                                            ? Text(
                                                                '${'street_number'.tr}: ${order.deliveryAddress!.streetNumber!}, ',
                                                                style: robotoRegular.copyWith(
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeExtraSmall,
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).disabledColor,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              )
                                                            : const SizedBox(),

                                                        (order.deliveryAddress!.house !=
                                                                    null &&
                                                                order
                                                                    .deliveryAddress!
                                                                    .house!
                                                                    .isNotEmpty)
                                                            ? Text(
                                                                '${'house'.tr}: ${order.deliveryAddress!.house!}, ',
                                                                style: robotoRegular.copyWith(
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeExtraSmall,
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).disabledColor,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              )
                                                            : const SizedBox(),

                                                        (order.deliveryAddress!.floor !=
                                                                    null &&
                                                                order
                                                                    .deliveryAddress!
                                                                    .floor!
                                                                    .isNotEmpty)
                                                            ? Text(
                                                                '${'floor'.tr}: ${order.deliveryAddress!.floor!}',
                                                                style: robotoRegular.copyWith(
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeExtraSmall,
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).disabledColor,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              )
                                                            : const SizedBox(),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              (order.orderType == 'take_away' &&
                                                      (order.orderStatus ==
                                                              'pending' ||
                                                          order.orderStatus ==
                                                              'confirmed' ||
                                                          order.orderStatus ==
                                                              'processing'))
                                                  ? TextButton.icon(
                                                      onPressed: () async {
                                                        String url =
                                                            'https://www.google.com/maps/dir/?api=1&destination=${order.deliveryAddress!.latitude}'
                                                            ',${order.deliveryAddress!.longitude}&mode=d';
                                                        if (await canLaunchUrlString(
                                                          url,
                                                        )) {
                                                          await launchUrlString(
                                                            url,
                                                            mode: LaunchMode
                                                                .externalApplication,
                                                          );
                                                        } else {
                                                          showCustomSnackBar(
                                                            'unable_to_launch_google_map'
                                                                .tr,
                                                          );
                                                        }
                                                      },
                                                      icon: const Icon(
                                                        Icons.directions,
                                                      ),
                                                      label: Text(
                                                        'direction'.tr,
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                              const SizedBox(
                                                width:
                                                    Dimensions.paddingSizeSmall,
                                              ),

                                              (order.orderStatus !=
                                                          'delivered' &&
                                                      order.orderStatus !=
                                                          'failed' &&
                                                      Get.find<
                                                            ProfileController
                                                          >()
                                                          .modulePermission!
                                                          .chat! &&
                                                      order.orderStatus !=
                                                          'canceled' &&
                                                      order.orderStatus !=
                                                          'refunded')
                                                  ? order.isGuest!
                                                        ? const SizedBox()
                                                        : TextButton.icon(
                                                            onPressed: () async {
                                                              if (Get.find<
                                                                            ProfileController
                                                                          >()
                                                                          .profileModel!
                                                                          .subscription !=
                                                                      null &&
                                                                  Get.find<
                                                                            ProfileController
                                                                          >()
                                                                          .profileModel!
                                                                          .subscription!
                                                                          .chat ==
                                                                      0 &&
                                                                  Get.find<
                                                                            ProfileController
                                                                          >()
                                                                          .profileModel!
                                                                          .stores![0]
                                                                          .storeBusinessModel ==
                                                                      'subscription') {
                                                                showCustomSnackBar(
                                                                  'you_have_no_available_subscription'
                                                                      .tr,
                                                                );
                                                              } else {
                                                                _timer
                                                                    ?.cancel();
                                                                await Get.toNamed(
                                                                  RouteHelper.getChatRoute(
                                                                    notificationBody: NotificationBodyModel(
                                                                      orderId:
                                                                          order
                                                                              .id,
                                                                      customerId: order
                                                                          .customer!
                                                                          .id,
                                                                    ),
                                                                    user: User(
                                                                      id: order
                                                                          .customer!
                                                                          .id,
                                                                      fName: order
                                                                          .customer!
                                                                          .fName,
                                                                      lName: order
                                                                          .customer!
                                                                          .lName,
                                                                      imageFullUrl: order
                                                                          .customer!
                                                                          .imageFullUrl,
                                                                    ),
                                                                  ),
                                                                );
                                                                _startApiCalling();
                                                              }
                                                            },
                                                            icon: Icon(
                                                              Icons.message,
                                                              color: Theme.of(
                                                                context,
                                                              ).primaryColor,
                                                              size: 20,
                                                            ),
                                                            label: Text(
                                                              'chat'.tr,
                                                              style: robotoRegular.copyWith(
                                                                fontSize: Dimensions
                                                                    .fontSizeSmall,
                                                                color: Theme.of(
                                                                  context,
                                                                ).primaryColor,
                                                              ),
                                                            ),
                                                          )
                                                  : const SizedBox(),
                                            ],
                                          )
                                        : const SizedBox(),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeLarge,
                                    ),

                                    // / Delivery man details
                                    order.deliveryMan != null
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'delivery_man'.tr,
                                                style: robotoRegular,
                                              ),
                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeSmall,
                                              ),

                                              Row(
                                                children: [
                                                  ClipOval(
                                                    child: CustomImageWidget(
                                                      image:
                                                          order.deliveryMan !=
                                                              null
                                                          ? '${order.deliveryMan!.imageFullUrl}'
                                                          : '',
                                                      height: 35,
                                                      width: 35,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: Dimensions
                                                        .paddingSizeSmall,
                                                  ),

                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${order.deliveryMan!.fName} ${order.deliveryMan!.lName}',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: robotoRegular
                                                              .copyWith(
                                                                fontSize: Dimensions
                                                                    .fontSizeSmall,
                                                              ),
                                                        ),
                                                        Text(
                                                          order
                                                              .deliveryMan!
                                                              .email!,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: robotoRegular
                                                              .copyWith(
                                                                fontSize: Dimensions
                                                                    .fontSizeSmall,
                                                                color: Theme.of(
                                                                  context,
                                                                ).disabledColor,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  (controllerOrderModel
                                                                  .orderStatus !=
                                                              'delivered' &&
                                                          controllerOrderModel
                                                                  .orderStatus !=
                                                              'failed' &&
                                                          controllerOrderModel
                                                                  .orderStatus !=
                                                              'canceled' &&
                                                          controllerOrderModel
                                                                  .orderStatus !=
                                                              'refunded')
                                                      ? TextButton.icon(
                                                          onPressed: () async {
                                                            if (await canLaunchUrlString(
                                                              'tel:${order.deliveryMan!.phone ?? ''}',
                                                            )) {
                                                              launchUrlString(
                                                                'tel:${order.deliveryMan!.phone ?? ''}',
                                                                mode: LaunchMode
                                                                    .externalApplication,
                                                              );
                                                            } else {
                                                              showCustomSnackBar(
                                                                '${'can_not_launch'.tr} ${order.deliveryMan!.phone ?? ''}',
                                                              );
                                                            }
                                                          },
                                                          icon: Icon(
                                                            Icons.call,
                                                            color: Theme.of(
                                                              context,
                                                            ).primaryColor,
                                                            size: 20,
                                                          ),
                                                          label: Text(
                                                            'call'.tr,
                                                            style: robotoRegular
                                                                .copyWith(
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeSmall,
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).primaryColor,
                                                                ),
                                                          ),
                                                        )
                                                      : const SizedBox(),

                                                  (controllerOrderModel
                                                                  .orderStatus !=
                                                              'delivered' &&
                                                          controllerOrderModel
                                                                  .orderStatus !=
                                                              'failed' &&
                                                          controllerOrderModel
                                                                  .orderStatus !=
                                                              'canceled' &&
                                                          controllerOrderModel
                                                                  .orderStatus !=
                                                              'refunded' &&
                                                          Get.find<
                                                                ProfileController
                                                              >()
                                                              .modulePermission!
                                                              .chat!)
                                                      ? TextButton.icon(
                                                          onPressed: () async {
                                                            if (Get.find<
                                                                          ProfileController
                                                                        >()
                                                                        .profileModel!
                                                                        .subscription !=
                                                                    null &&
                                                                Get.find<
                                                                          ProfileController
                                                                        >()
                                                                        .profileModel!
                                                                        .subscription!
                                                                        .chat ==
                                                                    0 &&
                                                                Get.find<
                                                                          ProfileController
                                                                        >()
                                                                        .profileModel!
                                                                        .stores![0]
                                                                        .storeBusinessModel ==
                                                                    'subscription') {
                                                              showCustomSnackBar(
                                                                'you_have_no_available_subscription'
                                                                    .tr,
                                                              );
                                                            } else {
                                                              _timer?.cancel();
                                                              await Get.toNamed(
                                                                RouteHelper.getChatRoute(
                                                                  notificationBody: NotificationBodyModel(
                                                                    orderId:
                                                                        controllerOrderModel
                                                                            .id,
                                                                    deliveryManId:
                                                                        order
                                                                            .deliveryMan!
                                                                            .id,
                                                                  ),
                                                                  user: User(
                                                                    id: controllerOrderModel
                                                                        .deliveryMan!
                                                                        .id,
                                                                    fName: controllerOrderModel
                                                                        .deliveryMan!
                                                                        .fName,
                                                                    lName: controllerOrderModel
                                                                        .deliveryMan!
                                                                        .lName,
                                                                    imageFullUrl:
                                                                        controllerOrderModel
                                                                            .deliveryMan!
                                                                            .imageFullUrl,
                                                                  ),
                                                                ),
                                                              );
                                                              _startApiCalling();
                                                            }
                                                          },
                                                          icon: Icon(
                                                            Icons
                                                                .chat_bubble_outline,
                                                            color: Theme.of(
                                                              context,
                                                            ).primaryColor,
                                                            size: 20,
                                                          ),
                                                          label: Text(
                                                            'chat'.tr,
                                                            style: robotoRegular
                                                                .copyWith(
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeSmall,
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).primaryColor,
                                                                ),
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                ],
                                              ),

                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),

                                    // Total

                                    /// Payment Details
                                    if (!(order.paymentMethod ==
                                            'cash_on_delivery' ||
                                        order.paymentMethod == 'cash'))
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.paddingSizeDefault,
                                          vertical: Dimensions.paddingSizeSmall,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(
                                            Dimensions.radiusSmall,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              offset: Offset(0, 3),
                                              color:
                                                  Colors.grey[Get.isDarkMode
                                                      ? 700
                                                      : 200]!,
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'payment_details'.tr,
                                                  style: robotoBold,
                                                ),
                                                Spacer(),
                                                Text(
                                                  (order!.paymentStatus !=
                                                              null &&
                                                          order
                                                              .paymentStatus!
                                                              .isNotEmpty)
                                                      ? order.paymentStatus!.tr
                                                      : (((order.paymentMethod ==
                                                                    'partial_payment') &&
                                                                (order
                                                                        .payments?[0]
                                                                        .amount !=
                                                                    null))
                                                            ? 'paid'.tr
                                                            : 'unpaid'.tr),
                                                  style: robotoRegular.copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Divider(
                                              thickness: 1,
                                              color: Theme.of(
                                                context,
                                              ).hintColor.withOpacity(0.1),
                                            ),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Image.asset(
                                                  Images.mdiCashIcon,
                                                  width: 24,
                                                  height: 24,
                                                ),
                                                SizedBox(
                                                  width: Dimensions
                                                      .paddingSizeSmall,
                                                ),
                                                Text(
                                                  (order.paymentMethod ==
                                                          'partial_payment')
                                                      ? 'wallet'.tr
                                                      : (order.paymentMethod ==
                                                                'cash_on_delivery' ||
                                                            order.paymentMethod ==
                                                                'cash')
                                                      ? 'cash'.tr
                                                      : (order.paymentMethod !=
                                                                null &&
                                                            order
                                                                .paymentMethod!
                                                                .isNotEmpty)
                                                      ? order.paymentMethod!
                                                            .replaceAll(
                                                              '_',
                                                              ' ',
                                                            )
                                                            .capitalizeFirst!
                                                            .tr
                                                      : 'cash'.tr,
                                                  style: restConfModel
                                                      ? robotoMedium
                                                      : robotoRegular,
                                                ),
                                                order.paymentMethod ==
                                                        'partial_payment'
                                                    ? Text(
                                                        '(${'partial_payment'.tr})',
                                                        style: robotoRegular
                                                            .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeSmall,
                                                              color: Theme.of(
                                                                context,
                                                              ).hintColor,
                                                            ),
                                                      )
                                                    : SizedBox.shrink(),
                                                Spacer(),
                                                Text(
                                                  (order.paymentMethod ==
                                                          'partial_payment')
                                                      ? PriceConverterHelper.convertPrice(
                                                          order
                                                              .payments![0]
                                                              .amount,
                                                        )
                                                      : PriceConverterHelper.convertPrice(
                                                          total,
                                                        ),
                                                  style: restConfModel
                                                      ? robotoMedium
                                                      : robotoRegular,
                                                ),
                                              ],
                                            ),
                                            if (order.paymentReference !=
                                                    null &&
                                                order
                                                    .paymentReference!
                                                    .isNotEmpty) ...[
                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .confirmation_number_outlined,
                                                    size: 20,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(
                                                    width: Dimensions
                                                        .paddingSizeSmall,
                                                  ),
                                                  Text(
                                                    '${'payment_reference'.tr}: ${order.paymentReference}',
                                                    style: robotoRegular
                                                        .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeSmall,
                                                          color: Theme.of(
                                                            context,
                                                          ).hintColor,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            if (order.paymentReceiptFullUrl !=
                                                    null &&
                                                order
                                                    .paymentReceiptFullUrl!
                                                    .isNotEmpty) ...[
                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              Text(
                                                'payment_receipt'.tr,
                                                style: robotoMedium.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeExtraSmall,
                                              ),
                                              SizedBox(
                                                height: 80,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: order
                                                      .paymentReceiptFullUrl!
                                                      .length,
                                                  itemBuilder: (context, index) {
                                                    final String url = order
                                                        .paymentReceiptFullUrl![index];
                                                    return GestureDetector(
                                                      onTap: () {
                                                        Get.dialog(
                                                          Dialog(
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            insetPadding:
                                                                EdgeInsets.zero,
                                                            child: Stack(
                                                              alignment:
                                                                  Alignment
                                                                      .topRight,
                                                              children: [
                                                                InteractiveViewer(
                                                                  child: Center(
                                                                    child: Image.network(
                                                                      url,
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Positioned(
                                                                  top: 40,
                                                                  right: 20,
                                                                  child: IconButton(
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .close,
                                                                      color: Colors
                                                                          .white,
                                                                      size: 30,
                                                                    ),
                                                                    onPressed: () =>
                                                                        Get.back(),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        margin: const EdgeInsets.only(
                                                          right: Dimensions
                                                              .paddingSizeSmall,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                Dimensions
                                                                    .radiusSmall,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .primaryColor
                                                                    .withOpacity(
                                                                      0.3,
                                                                    ),
                                                          ),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                Dimensions
                                                                    .radiusSmall,
                                                              ),
                                                          child:
                                                              CustomImageWidget(
                                                                image: url,
                                                                height: 80,
                                                                width: 80,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                          ],
                                        ),
                                      ),

                                    if (!(order.paymentMethod ==
                                            'cash_on_delivery' ||
                                        order.paymentMethod == 'cash'))
                                      const SizedBox(
                                        height: Dimensions.paddingSizeSmall,
                                      ),

                                    /// Billing Summary
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            Dimensions.paddingSizeDefault,
                                        vertical: Dimensions.paddingSizeSmall,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.radiusSmall,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: Offset(0, 3),
                                            color:
                                                Colors.grey[Get.isDarkMode
                                                    ? 700
                                                    : 200]!,
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'billing_summary'.tr,
                                            style: robotoBold,
                                          ),
                                          Divider(
                                            thickness: 1,
                                            color: Theme.of(
                                              context,
                                            ).hintColor.withOpacity(0.1),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'item_price'.tr,
                                                style: robotoRegular,
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  order!.prescriptionOrder!
                                                      ? IconButton(
                                                          constraints:
                                                              const BoxConstraints(
                                                                maxHeight: 36,
                                                              ),
                                                          onPressed: () => Get.dialog(
                                                            AmountInputDialogueWidget(
                                                              orderId: widget
                                                                  .orderId,
                                                              isItemPrice: true,
                                                              amount:
                                                                  itemsPrice,
                                                              additionalCharge:
                                                                  additionalCharge,
                                                            ),
                                                            barrierDismissible:
                                                                true,
                                                          ),
                                                          icon: const Icon(
                                                            Icons.edit,
                                                            size: 16,
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                  Text(
                                                    PriceConverterHelper.convertPrice(
                                                      itemsPrice,
                                                    ),
                                                    style: robotoRegular,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: Dimensions.paddingSizeSmall,
                                          ),

                                          Get.find<SplashController>()
                                                  .getModuleConfig(
                                                    order!.moduleType,
                                                  )
                                                  .addOn!
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'addons'.tr,
                                                      style: robotoRegular,
                                                    ),
                                                    Text(
                                                      '(+) ${PriceConverterHelper.convertPrice(addOns)}',
                                                      style: robotoRegular,
                                                    ),
                                                  ],
                                                )
                                              : const SizedBox(),

                                          Get.find<SplashController>()
                                                  .getModuleConfig(
                                                    order!.moduleType,
                                                  )
                                                  .addOn!
                                              ? Divider(
                                                  thickness: 1,
                                                  color: Theme.of(
                                                    context,
                                                  ).hintColor.withOpacity(0.1),
                                                )
                                              : const SizedBox(),

                                          Get.find<SplashController>()
                                                  .getModuleConfig(
                                                    order!.moduleType,
                                                  )
                                                  .addOn!
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'subtotal'.tr,
                                                      style: robotoMedium,
                                                    ),
                                                    Text(
                                                      PriceConverterHelper.convertPrice(
                                                        subTotal,
                                                      ),
                                                      style: robotoMedium,
                                                    ),
                                                  ],
                                                )
                                              : const SizedBox(),
                                          SizedBox(
                                            height:
                                                Get.find<SplashController>()
                                                    .getModuleConfig(
                                                      order!.moduleType,
                                                    )
                                                    .addOn!
                                                ? 10
                                                : 0,
                                          ),

                                          discount > 0
                                              ? Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'discount'.tr,
                                                          style: robotoRegular,
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            order!.prescriptionOrder!
                                                                ? IconButton(
                                                                    constraints:
                                                                        const BoxConstraints(
                                                                          maxHeight:
                                                                              36,
                                                                        ),
                                                                    onPressed: () => Get.dialog(
                                                                      AmountInputDialogueWidget(
                                                                        orderId:
                                                                            widget.orderId,
                                                                        isItemPrice:
                                                                            false,
                                                                        amount:
                                                                            discount,
                                                                      ),
                                                                      barrierDismissible:
                                                                          true,
                                                                    ),
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .edit,
                                                                      size: 16,
                                                                    ),
                                                                  )
                                                                : const SizedBox(),
                                                            Text(
                                                              '(-) ${PriceConverterHelper.convertPrice(discount)}',
                                                              style:
                                                                  robotoRegular,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                  ],
                                                )
                                              : const SizedBox(),

                                          couponDiscount > 0
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'coupon_discount'.tr,
                                                      style: robotoRegular,
                                                    ),
                                                    Text(
                                                      '(-) ${PriceConverterHelper.convertPrice(couponDiscount)}',
                                                      style: robotoRegular,
                                                    ),
                                                  ],
                                                )
                                              : const SizedBox(),
                                          SizedBox(
                                            height: couponDiscount > 0 ? 10 : 0,
                                          ),

                                          (referrerBonusAmount > 0)
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'referral_discount'.tr,
                                                      style: robotoRegular,
                                                    ),
                                                    Text(
                                                      '(-) ${PriceConverterHelper.convertPrice(referrerBonusAmount)}',
                                                      style: robotoRegular,
                                                    ),
                                                  ],
                                                )
                                              : const SizedBox(),
                                          SizedBox(
                                            height: referrerBonusAmount > 0
                                                ? 10
                                                : 0,
                                          ),

                                          taxIncluded || (tax == 0)
                                              ? const SizedBox()
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'vat_tax'.tr,
                                                      style: robotoRegular,
                                                    ),
                                                    Text(
                                                      '(+) ${PriceConverterHelper.convertPrice(tax)}',
                                                      style: robotoRegular,
                                                    ),
                                                  ],
                                                ),
                                          SizedBox(
                                            height: taxIncluded || (tax == 0)
                                                ? 0
                                                : 10,
                                          ),

                                          (extraPackagingAmount > 0)
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'extra_packaging'.tr,
                                                      style: robotoRegular,
                                                    ),
                                                    Text(
                                                      '(+) ${PriceConverterHelper.convertPrice(extraPackagingAmount)}',
                                                      style: robotoRegular,
                                                    ),
                                                  ],
                                                )
                                              : const SizedBox(),
                                          SizedBox(
                                            height: extraPackagingAmount > 0
                                                ? 10
                                                : 0,
                                          ),
                                          (order!.additionalCharge != null &&
                                                  order!.additionalCharge! > 0)
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        Get.find<
                                                              SplashController
                                                            >()
                                                            .configModel!
                                                            .additionalChargeName!,
                                                        style: robotoRegular,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeSmall,
                                                    ),
                                                    Text(
                                                      '(+) ${PriceConverterHelper.convertPrice(order!.additionalCharge)}',
                                                      style: robotoRegular,
                                                      textDirection:
                                                          TextDirection.ltr,
                                                    ),
                                                  ],
                                                )
                                              : const SizedBox(),
                                          (order!.additionalCharge != null &&
                                                  order!.additionalCharge! > 0)
                                              ? const SizedBox(height: 10)
                                              : const SizedBox(),

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'delivery_fee'.tr,
                                                style: robotoRegular,
                                              ),
                                              Text(
                                                '(+) ${PriceConverterHelper.convertPrice(deliveryCharge)}',
                                                style: robotoRegular,
                                              ),
                                            ],
                                          ),

                                          // if(order!.orderStatus != 'pending')
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical:
                                                  Dimensions.paddingSizeSmall,
                                            ),
                                            child: Divider(
                                              thickness: 1,
                                              color: Theme.of(
                                                context,
                                              ).hintColor.withOpacity(0.1),
                                            ),
                                          ),

                                          order!.paymentMethod ==
                                                  'partial_payment'
                                              ? DottedBorder(
                                                  options:
                                                      RoundedRectDottedBorderOptions(
                                                        color: Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                        strokeWidth: 1,
                                                        strokeCap:
                                                            StrokeCap.butt,
                                                        dashPattern: const [
                                                          8,
                                                          5,
                                                        ],
                                                        padding:
                                                            const EdgeInsets.all(
                                                              0,
                                                            ),
                                                        radius:
                                                            const Radius.circular(
                                                              Dimensions
                                                                  .radiusDefault,
                                                            ),
                                                      ),
                                                  child: Ink(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          Dimensions
                                                              .paddingSizeSmall,
                                                        ),
                                                    color: restConfModel
                                                        ? Theme.of(context)
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.05,
                                                              )
                                                        : Colors.transparent,
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'total_amount'.tr,
                                                              style: robotoMedium
                                                                  .copyWith(
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeLarge,
                                                                  ),
                                                            ),
                                                            Text(
                                                              PriceConverterHelper.convertPrice(
                                                                total,
                                                              ),
                                                              style: robotoMedium
                                                                  .copyWith(
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeLarge,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),

                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'paid_by_wallet'
                                                                  .tr,
                                                              style:
                                                                  restConfModel
                                                                  ? robotoMedium
                                                                  : robotoRegular,
                                                            ),
                                                            Text(
                                                              PriceConverterHelper.convertPrice(
                                                                order
                                                                    .payments![0]
                                                                    .amount,
                                                              ),
                                                              style:
                                                                  restConfModel
                                                                  ? robotoMedium
                                                                  : robotoRegular,
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),

                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              '${order.payments?[1].paymentStatus == 'paid' ? 'paid_by'.tr : 'due_amount'.tr} (${order.payments![1].paymentMethod?.tr})',
                                                              style:
                                                                  restConfModel
                                                                  ? robotoMedium
                                                                  : robotoRegular,
                                                            ),
                                                            Text(
                                                              PriceConverterHelper.convertPrice(
                                                                order
                                                                    .payments![1]
                                                                    .amount,
                                                              ),
                                                              style:
                                                                  restConfModel
                                                                  ? robotoMedium
                                                                  : robotoRegular,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox(),

                                          // order.orderStatus != 'pending' &&
                                          if (order.paymentMethod !=
                                              'partial_payment')
                                            Row(
                                              children: [
                                                Text(
                                                  'total_amount'.tr,
                                                  style: robotoMedium.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeLarge,
                                                  ),
                                                ),
                                                taxIncluded || (tax == 0)
                                                    ? SizedBox()
                                                    : const SizedBox(),
                                                const Expanded(
                                                  child: SizedBox(),
                                                ),
                                                Text(
                                                  PriceConverterHelper.convertPrice(
                                                    total,
                                                  ),
                                                  style: robotoMedium.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeLarge,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        showDeliveryConfirmImage &&
                                Get.find<SplashController>()
                                    .configModel!
                                    .dmPictureUploadStatus! &&
                                controllerOrderModel.orderStatus != 'delivered'
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                  vertical: Dimensions.paddingSizeSmall,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      offset: Offset(0, 3),
                                      color: Colors
                                          .grey[Get.isDarkMode ? 700 : 200]!,
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      height: Dimensions.paddingSizeDefault,
                                    ),
                                    Text(
                                      'completed_after_delivery_picture'.tr,
                                      style: robotoRegular,
                                    ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeSmall,
                                    ),

                                    Container(
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.radiusDefault,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeSmall,
                                      ),
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount:
                                            orderController
                                                .pickedPrescriptions
                                                .length +
                                            1,
                                        itemBuilder: (context, index) {
                                          XFile? file =
                                              index ==
                                                  orderController
                                                      .pickedPrescriptions
                                                      .length
                                              ? null
                                              : orderController
                                                    .pickedPrescriptions[index];
                                          if (index < 5 &&
                                              index ==
                                                  orderController
                                                      .pickedPrescriptions
                                                      .length) {
                                            return InkWell(
                                              onTap: () {
                                                if (GetPlatform.isIOS) {
                                                  Get.find<OrderController>()
                                                      .pickPrescriptionImage(
                                                        isRemove: false,
                                                        isCamera: false,
                                                      );
                                                } else {
                                                  Get.bottomSheet(
                                                    const CameraButtonSheetWidget(),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                height: 60,
                                                width: 60,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions
                                                            .radiusDefault,
                                                      ),
                                                  color: Theme.of(context)
                                                      .primaryColor
                                                      .withValues(alpha: 0.1),
                                                ),
                                                child: Icon(
                                                  Icons.camera_alt_sharp,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  size: 32,
                                                ),
                                              ),
                                            );
                                          }
                                          return file != null
                                              ? Container(
                                                  margin: const EdgeInsets.only(
                                                    right: Dimensions
                                                        .paddingSizeSmall,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          Dimensions
                                                              .radiusDefault,
                                                        ),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              Dimensions
                                                                  .radiusDefault,
                                                            ),
                                                        child: GetPlatform.isWeb
                                                            ? Image.network(
                                                                file.path,
                                                                width: 60,
                                                                height: 60,
                                                                fit: BoxFit
                                                                    .cover,
                                                              )
                                                            : Image.file(
                                                                File(file.path),
                                                                width: 60,
                                                                height: 60,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                      ),
                                                      Positioned(
                                                        right: 0,
                                                        top: 0,
                                                        child: InkWell(
                                                          onTap: () =>
                                                              orderController
                                                                  .removePrescriptionImage(
                                                                    index,
                                                                  ),
                                                          child: const Padding(
                                                            padding: EdgeInsets.all(
                                                              Dimensions
                                                                  .paddingSizeSmall,
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .delete_forever,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : const SizedBox();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(),

                        // cancel button moved to below the slider
                        showDeliveryConfirmImage &&
                                controllerOrderModel.orderStatus != 'delivered'
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                  vertical: Dimensions.paddingSizeSmall,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      offset: Offset(0, 3),
                                      color: Colors
                                          .grey[Get.isDarkMode ? 700 : 200]!,
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: CustomButtonWidget(
                                  buttonText: 'complete_delivery'.tr,
                                  onPressed: () {
                                    if (Get.find<SplashController>()
                                        .configModel!
                                        .orderDeliveryVerification!) {
                                      orderController.sendDeliveredNotification(
                                        controllerOrderModel.id,
                                      );

                                      Get.bottomSheet(
                                        VerifyDeliverySheetWidget(
                                          orderID: controllerOrderModel.id,
                                          verify: Get.find<SplashController>()
                                              .configModel!
                                              .orderDeliveryVerification,
                                          orderAmount:
                                              order.paymentMethod ==
                                                  'partial_payment'
                                              ? order.payments![1].amount!
                                                    .toDouble()
                                              : controllerOrderModel
                                                    .orderAmount,
                                          cod:
                                              controllerOrderModel
                                                      .paymentMethod ==
                                                  'cash_on_delivery' ||
                                              (order.paymentMethod ==
                                                      'partial_payment' &&
                                                  order
                                                          .payments![1]
                                                          .paymentMethod ==
                                                      'cash_on_delivery'),
                                        ),
                                        isScrollControlled: true,
                                      ).then((isSuccess) {
                                        if (isSuccess &&
                                                controllerOrderModel
                                                        .paymentMethod ==
                                                    'cash_on_delivery' ||
                                            (order.paymentMethod ==
                                                    'partial_payment' &&
                                                order
                                                        .payments![1]
                                                        .paymentMethod ==
                                                    'cash_on_delivery')) {
                                          Get.bottomSheet(
                                            CollectMoneyDeliverySheetWidget(
                                              orderID: controllerOrderModel.id,
                                              verify:
                                                  Get.find<SplashController>()
                                                      .configModel!
                                                      .orderDeliveryVerification,
                                              orderAmount:
                                                  order.paymentMethod ==
                                                      'partial_payment'
                                                  ? order.payments![1].amount!
                                                        .toDouble()
                                                  : controllerOrderModel
                                                        .orderAmount,
                                              cod:
                                                  controllerOrderModel
                                                          .paymentMethod ==
                                                      'cash_on_delivery' ||
                                                  (order.paymentMethod ==
                                                          'partial_payment' &&
                                                      order
                                                              .payments![1]
                                                              .paymentMethod ==
                                                          'cash_on_delivery'),
                                            ),
                                            isScrollControlled: true,
                                            isDismissible: false,
                                          );
                                        }
                                      });
                                    } else {
                                      Get.bottomSheet(
                                        CollectMoneyDeliverySheetWidget(
                                          orderID: controllerOrderModel.id,
                                          verify: Get.find<SplashController>()
                                              .configModel!
                                              .orderDeliveryVerification,
                                          orderAmount:
                                              order.paymentMethod ==
                                                  'partial_payment'
                                              ? order.payments![1].amount!
                                                    .toDouble()
                                              : controllerOrderModel
                                                    .orderAmount,
                                          cod:
                                              controllerOrderModel
                                                      .paymentMethod ==
                                                  'cash_on_delivery' ||
                                              (order.paymentMethod ==
                                                      'partial_payment' &&
                                                  order
                                                          .payments![1]
                                                          .paymentMethod ==
                                                      'cash_on_delivery'),
                                        ),
                                        isScrollControlled: true,
                                      );
                                    }
                                  },
                                ),
                              )
                            : showBottomView
                            ? false
                                  ? Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            Dimensions.paddingSizeDefault,
                                        vertical: Dimensions.paddingSizeSmall,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.radiusSmall,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: Offset(0, 3),
                                            color:
                                                Colors.grey[Get.isDarkMode
                                                    ? 700
                                                    : 200]!,
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      width: MediaQuery.of(context).size.width,
                                      alignment: Alignment.center,
                                      child: Text(
                                        'item_is_on_the_way'.tr,
                                        style: robotoMedium,
                                      ),
                                    )
                                  : showSlider
                                  ? Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                Dimensions.paddingSizeSmall,
                                          ),
                                          child: SliderButton(
                                            isLoading:
                                                orderController.isLoading,
                                            action: () {
                                              if (controllerOrderModel
                                                          .orderStatus ==
                                                      'pending' &&
                                                  (controllerOrderModel
                                                              .orderType ==
                                                          'take_away' ||
                                                      restConfModel ||
                                                      selfDelivery)) {
                                                if (order!.moduleType ==
                                                    'grocery') {
                                                  orderController
                                                      .updateOrderStatus(
                                                        widget.orderId,
                                                        AppConstants.handover,
                                                      );
                                                } else {
                                                  Get.dialog(
                                                    ConfirmationDialogWidget(
                                                      icon: Images.warning,
                                                      title:
                                                          'are_you_sure_to_confirm'
                                                              .tr,
                                                      description:
                                                          'you_want_to_confirm_this_order'
                                                              .tr,
                                                      onYesPressed: () {
                                                        orderController
                                                            .updateOrderStatus(
                                                              widget.orderId,
                                                              AppConstants
                                                                  .confirmed,
                                                            );
                                                      },
                                                      onNoPressed: () {
                                                        if (cancelPermission!) {
                                                          Get.back();
                                                          orderController
                                                              .setOrderCancelReason(
                                                                '',
                                                              );
                                                          Get.dialog(
                                                            CancellationDialogueWidget(
                                                              orderId: widget
                                                                  .orderId,
                                                            ),
                                                          );
                                                        } else {
                                                          Get.back();
                                                        }
                                                      },
                                                    ),
                                                    barrierDismissible: false,
                                                  );
                                                }
                                              } else if (order!.moduleType ==
                                                      'grocery' &&
                                                  (controllerOrderModel
                                                              .orderStatus ==
                                                          'confirmed' ||
                                                      (controllerOrderModel
                                                                  .orderStatus ==
                                                              'accepted' &&
                                                          controllerOrderModel
                                                                  .confirmed !=
                                                              null) ||
                                                      controllerOrderModel
                                                              .orderStatus ==
                                                          'processing')) {
                                                Get.find<OrderController>()
                                                    .updateOrderStatus(
                                                      widget.orderId,
                                                      AppConstants.handover,
                                                    );
                                              } else if (order!.moduleType !=
                                                      'grocery' &&
                                                  controllerOrderModel
                                                          .orderStatus ==
                                                      'processing') {
                                                Get.find<OrderController>()
                                                    .updateOrderStatus(
                                                      widget.orderId,
                                                      AppConstants.handover,
                                                    );
                                              } else if (order!.moduleType !=
                                                      'grocery' &&
                                                  (controllerOrderModel
                                                              .orderStatus ==
                                                          'confirmed' ||
                                                      (controllerOrderModel
                                                                  .orderStatus ==
                                                              'accepted' &&
                                                          controllerOrderModel
                                                                  .confirmed !=
                                                              null))) {
                                                if (Get.find<SplashController>()
                                                    .getModuleConfig(
                                                      order!.moduleType,
                                                    )
                                                    .newVariation!) {
                                                  Get.dialog(
                                                    InputDialogWidget(
                                                      icon: Images.warning,
                                                      title:
                                                          'are_you_sure_to_confirm'
                                                              .tr,
                                                      description:
                                                          'enter_processing_time_in_minutes'
                                                              .tr,
                                                      onPressed: (String? time) {
                                                        Get.find<
                                                              OrderController
                                                            >()
                                                            .updateOrderStatus(
                                                              controllerOrderModel
                                                                  .id,
                                                              AppConstants
                                                                  .processing,
                                                              processingTime:
                                                                  time,
                                                            )
                                                            .then((success) {
                                                              Get.back();
                                                              if (success) {
                                                                Get.find<
                                                                      ProfileController
                                                                    >()
                                                                    .getProfile();
                                                                Get.find<
                                                                      OrderController
                                                                    >()
                                                                    .getCurrentOrders();
                                                              }
                                                            });
                                                      },
                                                    ),
                                                  );
                                                } else {
                                                  Get.find<OrderController>()
                                                      .updateOrderStatus(
                                                        controllerOrderModel.id,
                                                        AppConstants.processing,
                                                      )
                                                      .then((success) {
                                                        Get.back();
                                                        if (success) {
                                                          Get.find<
                                                                ProfileController
                                                              >()
                                                              .getProfile();
                                                          Get.find<
                                                                OrderController
                                                              >()
                                                              .getCurrentOrders();
                                                        }
                                                      });
                                                }
                                              } else if (controllerOrderModel
                                                      .orderStatus ==
                                                  'handover') {
                                                if (!selfDelivery) {
                                                  Get.dialog(
                                                    DriverNameInputDialogWidget(
                                                      onPressed: (driverName) {
                                                        Get.find<
                                                              OrderController
                                                            >()
                                                            .updateOrderStatus(
                                                              controllerOrderModel
                                                                  .id,
                                                              AppConstants
                                                                  .pickedUp,
                                                              externalDeliveryManName:
                                                                  driverName,
                                                            );
                                                      },
                                                    ),
                                                    barrierDismissible: false,
                                                  );
                                                } else {
                                                  Get.find<OrderController>()
                                                      .updateOrderStatus(
                                                        controllerOrderModel.id,
                                                        AppConstants.pickedUp,
                                                      );
                                                }
                                              } else if (controllerOrderModel
                                                      .orderStatus ==
                                                  'picked_up') {
                                                if (Get.find<SplashController>()
                                                    .configModel!
                                                    .orderDeliveryVerification!) {
                                                  orderController
                                                      .sendDeliveredNotification(
                                                        controllerOrderModel.id,
                                                      );
                                                  Get.bottomSheet(
                                                    VerifyDeliverySheetWidget(
                                                      orderID:
                                                          controllerOrderModel
                                                              .id,
                                                      verify:
                                                          Get.find<
                                                                SplashController
                                                              >()
                                                              .configModel!
                                                              .orderDeliveryVerification,
                                                      orderAmount:
                                                          order!.paymentMethod ==
                                                              'partial_payment'
                                                          ? order
                                                                .payments![1]
                                                                .amount!
                                                                .toDouble()
                                                          : controllerOrderModel
                                                                .orderAmount,
                                                      cod:
                                                          controllerOrderModel
                                                                  .paymentMethod ==
                                                              'cash_on_delivery' ||
                                                          (order.paymentMethod ==
                                                                  'partial_payment' &&
                                                              order
                                                                      .payments![1]
                                                                      .paymentMethod ==
                                                                  'cash_on_delivery'),
                                                    ),
                                                    isScrollControlled: true,
                                                  ).then((isSuccess) {
                                                    if (isSuccess &&
                                                        (controllerOrderModel
                                                                    .paymentMethod ==
                                                                'cash_on_delivery' ||
                                                            (order.paymentMethod ==
                                                                    'partial_payment' &&
                                                                order
                                                                        .payments![1]
                                                                        .paymentMethod ==
                                                                    'cash_on_delivery'))) {
                                                      Get.bottomSheet(
                                                        CollectMoneyDeliverySheetWidget(
                                                          orderID:
                                                              controllerOrderModel
                                                                  .id,
                                                          verify:
                                                              Get.find<
                                                                    SplashController
                                                                  >()
                                                                  .configModel!
                                                                  .orderDeliveryVerification,
                                                          orderAmount:
                                                              order.paymentMethod ==
                                                                  'partial_payment'
                                                              ? order
                                                                    .payments![1]
                                                                    .amount!
                                                                    .toDouble()
                                                              : controllerOrderModel
                                                                    .orderAmount,
                                                          cod:
                                                              controllerOrderModel
                                                                      .paymentMethod ==
                                                                  'cash_on_delivery' ||
                                                              (order.paymentMethod ==
                                                                      'partial_payment' &&
                                                                  order
                                                                          .payments![1]
                                                                          .paymentMethod ==
                                                                      'cash_on_delivery'),
                                                        ),
                                                        isScrollControlled:
                                                            true,
                                                        isDismissible: false,
                                                      );
                                                    }
                                                  });
                                                } else if (controllerOrderModel
                                                            .paymentMethod ==
                                                        'cash_on_delivery' ||
                                                    (order!.paymentMethod ==
                                                            'partial_payment' &&
                                                        order
                                                                .payments![1]
                                                                .paymentMethod ==
                                                            'cash_on_delivery')) {
                                                  Get.bottomSheet(
                                                    CollectMoneyDeliverySheetWidget(
                                                      orderID:
                                                          controllerOrderModel
                                                              .id,
                                                      verify:
                                                          Get.find<
                                                                SplashController
                                                              >()
                                                              .configModel!
                                                              .orderDeliveryVerification,
                                                      orderAmount:
                                                          order.paymentMethod ==
                                                              'partial_payment'
                                                          ? order
                                                                .payments![1]
                                                                .amount!
                                                                .toDouble()
                                                          : controllerOrderModel
                                                                .orderAmount,
                                                      cod:
                                                          controllerOrderModel
                                                                  .paymentMethod ==
                                                              'cash_on_delivery' ||
                                                          (order.paymentMethod ==
                                                                  'partial_payment' &&
                                                              order
                                                                      .payments![1]
                                                                      .paymentMethod ==
                                                                  'cash_on_delivery'),
                                                    ),
                                                    isScrollControlled: true,
                                                  );
                                                } else {
                                                  Get.find<OrderController>()
                                                      .updateOrderStatus(
                                                        controllerOrderModel.id,
                                                        AppConstants.delivered,
                                                      );
                                                }
                                              }
                                            },
                                            label: Text(
                                              (controllerOrderModel
                                                              .orderStatus ==
                                                          'pending' &&
                                                      (controllerOrderModel
                                                                  .orderType ==
                                                              'take_away' ||
                                                          restConfModel ||
                                                          selfDelivery))
                                                  ? (order!.moduleType ==
                                                            'grocery'
                                                        ? 'swipe_if_ready_for_handover'
                                                              .tr
                                                        : 'swipe_to_confirm_order'
                                                              .tr)
                                                  : (order!.moduleType ==
                                                            'grocery' &&
                                                        (controllerOrderModel
                                                                    .orderStatus ==
                                                                'confirmed' ||
                                                            (controllerOrderModel
                                                                        .orderStatus ==
                                                                    'accepted' &&
                                                                controllerOrderModel
                                                                        .confirmed !=
                                                                    null) ||
                                                            controllerOrderModel
                                                                    .orderStatus ==
                                                                'processing'))
                                                  ? 'swipe_if_ready_for_handover'
                                                        .tr
                                                  : (order!.moduleType !=
                                                            'grocery' &&
                                                        (controllerOrderModel
                                                                    .orderStatus ==
                                                                'confirmed' ||
                                                            (controllerOrderModel
                                                                        .orderStatus ==
                                                                    'accepted' &&
                                                                controllerOrderModel
                                                                        .confirmed !=
                                                                    null)))
                                                  ? Get.find<SplashController>()
                                                            .configModel!
                                                            .moduleConfig!
                                                            .module!
                                                            .showRestaurantText!
                                                        ? 'swipe_to_cooking'.tr
                                                        : 'swipe_to_process'.tr
                                                  : (order!.moduleType !=
                                                            'grocery' &&
                                                        (controllerOrderModel
                                                                .orderStatus ==
                                                            'processing'))
                                                  ? 'swipe_if_ready_for_handover'
                                                        .tr
                                                  : (controllerOrderModel
                                                            .orderStatus ==
                                                        'handover')
                                                  ? 'swipe_to_picked_up'.tr
                                                  : (controllerOrderModel
                                                            .orderStatus ==
                                                        'picked_up')
                                                  ? 'swipe_to_deliver_order'.tr
                                                  : '',
                                              style: robotoMedium.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeLarge,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                            ),
                                            dismissThresholds: 0.5,
                                            dismissible: false,
                                            shimmer: true,
                                            width: 1170,
                                            height: 50,
                                            buttonSize: 45,
                                            radius: 10,
                                            icon: Center(
                                              child: Icon(
                                                Get.find<
                                                          LocalizationController
                                                        >()
                                                        .isLtr
                                                    ? Icons.double_arrow_sharp
                                                    : Icons.keyboard_arrow_left,
                                                color: Colors.white,
                                                size: 20.0,
                                              ),
                                            ),
                                            isLtr:
                                                Get.find<
                                                      LocalizationController
                                                    >()
                                                    .isLtr,
                                            boxShadow: const BoxShadow(
                                              blurRadius: 0,
                                            ),
                                            buttonColor: Theme.of(
                                              context,
                                            ).primaryColor,
                                            backgroundColor: const Color(
                                              0xffF4F7FC,
                                            ),
                                            baseColor: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                        ),
                                        // زر إلغاء الطلب أسفل السلايدر
                                        if (_canStoreCancelOrder(
                                          controllerOrderModel,
                                          cancelPermission,
                                        ))
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: Dimensions.paddingSizeSmall,
                                              left: Dimensions.paddingSizeSmall,
                                              right:
                                                  Dimensions.paddingSizeSmall,
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  orderController
                                                      .setOrderCancelReason('');
                                                  Get.dialog(
                                                    CancellationDialogueWidget(
                                                      orderId: order!.id,
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.cancel_outlined,
                                                  color: Colors.red,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  'cancel_order'.tr,
                                                  style: robotoMedium.copyWith(
                                                    color: Colors.red,
                                                    fontSize: Dimensions
                                                        .fontSizeDefault,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: Colors.red,
                                                    width: 1.5,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          Dimensions
                                                              .radiusSmall,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
                                  : const SizedBox()
                            : const SizedBox(),

                        /// Print Invoice
                        // if(Platform.isAndroid)
                        //   Padding(
                        //     padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        //     child: CustomButtonWidget(
                        //       onPressed: () {
                        //         _allowPermission().then((access) {
                        //           Get.dialog(Dialog(
                        //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                        //             child: InVoicePrintScreen(order: order, orderDetails: orderController.orderDetailsModel, isPrescriptionOrder: isPrescriptionOrder, dmTips: dmTips!),
                        //           ));
                        //         });
                        //       },
                        //       icon: Icons.local_print_shop,
                        //       buttonText: 'print_invoice'.tr,
                        //     ),
                        //   ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  void openDialog(BuildContext context, String imageUrl) => showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              child: PhotoView(
                tightMode: true,
                imageProvider: NetworkImage(imageUrl),
                heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
              ),
            ),

            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                splashRadius: 5,
                onPressed: () => Get.back(),
                icon: const Icon(Icons.cancel, color: Colors.red),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<bool> _allowPermission() async {
  if (!await _requestAndCheckPermission(Permission.location)) {
    return false;
  }
  if (!await _requestAndCheckPermission(Permission.bluetooth)) {
    return false;
  }
  if (!await _requestAndCheckPermission(Permission.bluetoothConnect)) {
    return false;
  }
  if (!await _requestAndCheckPermission(Permission.bluetoothScan)) {
    return false;
  }

  return true;
}

Future<bool> _requestAndCheckPermission(Permission permission) async {
  await permission.request();
  var status = await permission.status;
  return !status.isDenied;
}

class DriverNameInputDialogWidget extends StatefulWidget {
  final Function(String driverName) onPressed;
  const DriverNameInputDialogWidget({super.key, required this.onPressed});

  @override
  State<DriverNameInputDialogWidget> createState() =>
      _DriverNameInputDialogWidgetState();
}

class _DriverNameInputDialogWidgetState
    extends State<DriverNameInputDialogWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      insetPadding: const EdgeInsets.all(30),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Image.asset(Images.warning, width: 50, height: 50),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeLarge,
                  ),
                  child: Text(
                    'enter_delivery_driver_name'.tr,
                    textAlign: TextAlign.center,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Text(
                    'please_enter_driver_name'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                CustomTextFieldWidget(
                  maxLines: 1,
                  controller: _controller,
                  hintText: 'delivery_driver_name'.tr,
                  isEnabled: true,
                  inputType: TextInputType.text,
                  inputAction: TextInputAction.done,
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                GetBuilder<OrderController>(
                  builder: (orderController) {
                    return orderController.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                            children: [
                              Expanded(
                                child: CustomButtonWidget(
                                  buttonText: 'submit'.tr,
                                  onPressed: () {
                                    if (_controller.text.trim().isEmpty) {
                                      showCustomSnackBar(
                                        'please_enter_driver_name'.tr,
                                      );
                                    } else {
                                      widget.onPressed(_controller.text.trim());
                                    }
                                  },
                                  height: 40,
                                ),
                              ),
                              const SizedBox(
                                width: Dimensions.paddingSizeLarge,
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Get.back(),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).disabledColor.withValues(alpha: 0.3),
                                    minimumSize: const Size(1170, 40),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusSmall,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'cancel'.tr,
                                    textAlign: TextAlign.center,
                                    style: robotoBold.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.color,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InvoiceShareDialog extends StatefulWidget {
  final OrderModel? order;
  final List<OrderDetailsModel>? orderDetails;
  final bool? isPrescriptionOrder;
  final double dmTips;
  const InvoiceShareDialog({
    super.key,
    required this.order,
    required this.orderDetails,
    this.isPrescriptionOrder = false,
    required this.dmTips,
  });

  @override
  State<InvoiceShareDialog> createState() => _InvoiceShareDialogState();
}

class _InvoiceShareDialogState extends State<InvoiceShareDialog> {
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureAndShare();
    });
  }

  void _captureAndShare() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final String path =
            '${directory.path}/invoice_${widget.order!.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        final File file = await File(path).create();
        await file.writeAsBytes(imageBytes);

        if (mounted) {
          Get.back();
        }
        await Share.shareXFiles([
          XFile(file.path),
        ], text: '${'order_id'.tr}: ${widget.order!.id}');
      } else {
        if (mounted) {
          Get.back();
        }
        showCustomSnackBar('failed_to_save_qr'.tr, isError: true);
      }
    } catch (e) {
      if (mounted) {
        Get.back();
      }
      showCustomSnackBar('failed_to_save_qr'.tr, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Text(
                  'preparing_invoice'.tr.isNotEmpty
                      ? 'preparing_invoice'.tr
                      : 'Preparing Invoice...',
                  style: robotoMedium,
                ),
              ],
            ),
            const Divider(height: Dimensions.paddingSizeLarge),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: SingleChildScrollView(
                child: InvoiceDialogWidget(
                  order: widget.order,
                  orderDetails: widget.orderDetails,
                  isPrescriptionOrder: widget.isPrescriptionOrder,
                  paper80MM: true,
                  dmTips: widget.dmTips,
                  screenshotController: screenshotController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
