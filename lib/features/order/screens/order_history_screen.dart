import 'package:sixam_mart_store/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_store/features/order/widgets/running_order_body_widget.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:sixam_mart_store/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/order_history_body_widget.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<OrderController>().getPaginatedOrders(1, true);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBarWidget(
          title: 'my_orders'.tr,
          isBackButtonExist: false,
        ),
        body: Column(
          children: [
            _orderTabBar(context),
            Expanded(
              child: TabBarView(
                children: [RunningOrderBodyWidget(), OrderHistoryBodyWidget()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TabBar _orderTabBar(BuildContext context) {
  final theme = Theme.of(context);

  return TabBar(
    indicator: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: Theme.of(context).primaryColor,
    ),
    indicatorSize: TabBarIndicatorSize.tab,
    labelColor: theme.cardColor,
    unselectedLabelColor: theme.textTheme.bodyLarge?.color?.withValues(
      alpha: 0.7,
    ),
    labelStyle: robotoBold.copyWith(fontSize: 14),
    unselectedLabelStyle: robotoMedium.copyWith(fontSize: 14),
    dividerColor: Colors.transparent,
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    padding: const EdgeInsets.symmetric(
      horizontal: Dimensions.paddingSizeDefault,
      vertical: Dimensions.paddingSizeSmall,
    ),
    labelPadding: const EdgeInsets.symmetric(
      horizontal: Dimensions.paddingSizeSmall,
    ),
    tabs: [
      Tab(text: 'running_order'.tr),
      Tab(text: 'order_history'.tr),
    ],
  );
}
