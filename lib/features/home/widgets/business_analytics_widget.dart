import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_popup_menu_button.dart';
import 'package:shoplancer_vendor/features/dashboard/screens/dashboard_screen.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
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
    if (widget.profileController.profileModel != null) {
      switch (index) {
        case 0:
          totalEarning =
              widget.profileController.profileModel!.totalEarning ?? 0;
          totalOrders = widget.profileController.profileModel!.orderCount ?? 0;
          break;
        case 1:
          totalEarning =
              widget.profileController.profileModel!.todaysEarning ?? 0;
          totalOrders =
              widget.profileController.profileModel!.todaysOrderCount ?? 0;
          break;
        case 2:
          totalEarning =
              widget.profileController.profileModel!.thisWeekEarning ?? 0;
          totalOrders =
              widget.profileController.profileModel!.thisWeekOrderCount ?? 0;
          break;
        case 3:
          totalEarning =
              widget.profileController.profileModel!.thisMonthEarning ?? 0;
          totalOrders =
              widget.profileController.profileModel!.thisMonthOrderCount ?? 0;
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
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
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
                    color: Theme.of(context).textTheme.bodyLarge!.color!,
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: 2,
                ),
                child: Row(
                  children: [
                    Text(
                      items[index].title,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  onTap: () =>
                      Get.offAll(() => const DashboardScreen(pageIndex: 3)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault,
                      ),
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.15),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'total_earning'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          PriceConverterHelper.convertPrice(totalEarning),
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  onTap: () =>
                      Get.offAll(() => const DashboardScreen(pageIndex: 1)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault,
                      ),
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.15),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'total_orders'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalOrders',
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
