import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_popup_menu_button.dart';
import 'package:shoplancer_vendor/features/dashboard/screens/dashboard_screen.dart';
import 'package:shoplancer_vendor/features/order/controllers/order_controller.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class BusinessAnalyticsWidget extends StatefulWidget {
  final ProfileController profileController;
  const BusinessAnalyticsWidget({super.key, required this.profileController});

  @override
  State<BusinessAnalyticsWidget> createState() =>
      _BusinessAnalyticsWidgetState();
}

class _BusinessAnalyticsWidgetState extends State<BusinessAnalyticsWidget> {
  int index = 1;

  @override
  Widget build(BuildContext context) {
    final List<MenuItem> items = [
      MenuItem('all'.tr, null, 0, Colors.blue),
      MenuItem('today'.tr, null, 1, Colors.blue),
      MenuItem('this_week'.tr, null, 2, Colors.indigoAccent),
      MenuItem('this_month'.tr, null, 3, Colors.orange),
    ];
    double totalEarning = 0.0;
    int totalOrders = 0;
    int totalProducts = 0;

    if (widget.profileController.profileModel != null) {
      final profile = widget.profileController.profileModel!;
      final storeTotalOrders =
          (profile.stores != null && profile.stores!.isNotEmpty)
              ? profile.stores!.first.totalOrder
              : null;
      final storeTotalProducts =
          (profile.stores != null && profile.stores!.isNotEmpty)
              ? profile.stores!.first.totalItems
              : null;

      totalProducts = storeTotalProducts ??
          (Get.isRegistered<StoreController>()
              ? (Get.find<StoreController>().itemSize ?? 0)
              : 0);

      switch (index) {
        case 0:
          totalEarning = profile.totalEarning ?? 0;
          totalOrders = profile.orderCount ?? storeTotalOrders ?? 0;
          break;
        case 1:
          totalEarning = profile.todaysEarning ?? 0;
          totalOrders = profile.todaysOrderCount ?? 0;
          break;
        case 2:
          totalEarning = profile.thisWeekEarning ?? 0;
          totalOrders = profile.thisWeekOrderCount ?? 0;
          break;
        case 3:
          totalEarning = profile.thisMonthEarning ?? 0;
          totalOrders = profile.thisMonthOrderCount ?? 0;
          break;
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'business_analytics'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
            CustomPopupMenuButton(
              items: items,
              onSelected: (int value) {
                setState(() {
                  index = value;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      items[index].title,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 1: Total Earnings & Total Orders
        Row(
          children: [
            _buildAnalyticsCard(
              context: context,
              title: 'total_earning'.tr,
              value: PriceConverterHelper.convertPrice(totalEarning),
              icon: Icons.account_balance_wallet_outlined,
              iconColor: Colors.green,
              onTap: () => Get.toNamed(RouteHelper.getWalletRoute()),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            _buildAnalyticsCard(
              context: context,
              title: 'total_orders'.tr,
              value: '$totalOrders',
              icon: Icons.shopping_bag_outlined,
              iconColor: Colors.blue,
              onTap: () =>
                  Get.offAll(() => const DashboardScreen(pageIndex: 1)),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Row 2: Ongoing Orders & Total Products
        GetBuilder<OrderController>(
          builder: (orderController) {
            int ongoingOrders = orderController.runningOrderList?.length ?? 0;
            if (ongoingOrders == 0 && orderController.runningOrders != null) {
              for (var r in orderController.runningOrders!) {
                ongoingOrders += r.orderList.length;
              }
            }

            return Row(
              children: [
                _buildAnalyticsCard(
                  context: context,
                  title: 'ongoing_orders'.tr,
                  value: '$ongoingOrders',
                  icon: Icons.pending_actions_outlined,
                  iconColor: Colors.orange,
                  onTap: () =>
                      Get.offAll(() => const DashboardScreen(pageIndex: 1)),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _buildAnalyticsCard(
                  context: context,
                  title: 'total_products'.tr,
                  value: '$totalProducts',
                  icon: Icons.inventory_2_outlined,
                  iconColor: Colors.purple,
                  onTap: () =>
                      Get.toNamed(RouteHelper.getProductManagementRoute()),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, size: 14, color: iconColor),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).disabledColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
