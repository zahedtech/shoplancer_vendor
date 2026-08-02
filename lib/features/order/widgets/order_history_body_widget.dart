import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../helper/date_converter_helper.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/order_controller.dart';
import 'count_widget.dart';
import 'order_view_widget.dart';

class OrderHistoryBodyWidget extends StatelessWidget {
  const OrderHistoryBodyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(
      builder: (orderController) {
        return Get.find<ProfileController>().modulePermission!.order!
            ? Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Column(
                  children: [
                    GetBuilder<ProfileController>(
                      builder: (profileController) {
                        return profileController.profileModel != null
                            ? Container(
                                margin: EdgeInsets.only(
                                  top: Dimensions.paddingSizeSmall,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      offset: Offset(0, 1),
                                      color: Theme.of(
                                        context,
                                      ).disabledColor.withValues(alpha: 0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CountWidget(
                                      title: 'today'.tr,
                                      count: profileController
                                          .profileModel!
                                          .todaysOrderCount,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 30,
                                      color: Theme.of(
                                        context,
                                      ).hintColor.withValues(alpha: 0.2),
                                    ),
                                    CountWidget(
                                      title: 'this_week'.tr,
                                      count: profileController
                                          .profileModel!
                                          .thisWeekOrderCount,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 30,
                                      color: Theme.of(
                                        context,
                                      ).hintColor.withValues(alpha: 0.2),
                                    ),
                                    CountWidget(
                                      title: 'this_month'.tr,
                                      count: profileController
                                          .profileModel!
                                          .thisMonthOrderCount,
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox();
                      },
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).disabledColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusLarge,
                        ),
                      ),
                      child: Row(
                        children: List.generate(
                          orderController.statusList.length,
                          (index) {
                            bool isSelected =
                                orderController.historyIndex == index;
                            String status = orderController.statusList[index];
                            return Expanded(
                              child: InkWell(
                                onTap: () =>
                                    orderController.setHistoryIndex(index),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusLarge,
                                    ),
                                  ),
                                  child: Text(
                                    status.tr,
                                    style: isSelected
                                        ? robotoBold.copyWith(
                                            color: Colors.white,
                                            fontSize: Dimensions.fontSizeSmall,
                                          )
                                        : robotoMedium.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).disabledColor,
                                            fontSize: Dimensions.fontSizeSmall,
                                          ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildDateFilterChip(
                            context,
                            title: 'all_dates'.tr,
                            isSelected: orderController.selectedDateIndex == 0,
                            onTap: () {
                              orderController.setDateFilter(null, null, 0);
                            },
                          ),
                          _buildDateFilterChip(
                            context,
                            title: 'today'.tr,
                            isSelected: orderController.selectedDateIndex == 1,
                            onTap: () {
                              String today =
                                  DateConverterHelper.dateTimeForCoupon(
                                    DateTime.now(),
                                  );
                              orderController.setDateFilter(today, today, 1);
                            },
                          ),
                          _buildDateFilterChip(
                            context,
                            title: 'yesterday'.tr,
                            isSelected: orderController.selectedDateIndex == 2,
                            onTap: () {
                              String yesterday =
                                  DateConverterHelper.dateTimeForCoupon(
                                    DateTime.now().subtract(
                                      const Duration(days: 1),
                                    ),
                                  );
                              orderController.setDateFilter(
                                yesterday,
                                yesterday,
                                2,
                              );
                            },
                          ),
                          _buildDateFilterChip(
                            context,
                            title: orderController.selectedDateIndex == 3
                                ? '${DateConverterHelper.convertDateToDate(orderController.fromDate!)} - ${DateConverterHelper.convertDateToDate(orderController.toDate!)}'
                                : 'custom_date'.tr,
                            isSelected: orderController.selectedDateIndex == 3,
                            onTap: () async {
                              final DateTimeRange? result =
                                  await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now(),
                                    currentDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Theme.of(
                                              context,
                                            ).primaryColor,
                                            onPrimary: Colors.white,
                                            onSurface: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge!.color!,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                              if (result != null) {
                                String from =
                                    DateConverterHelper.dateTimeForCoupon(
                                      result.start,
                                    );
                                String to =
                                    DateConverterHelper.dateTimeForCoupon(
                                      result.end,
                                    );
                                orderController.setDateFilter(from, to, 3);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: orderController.historyOrderList != null
                          ? Dimensions.paddingSizeSmall
                          : 0,
                    ),

                    Expanded(
                      child: orderController.historyOrderList != null
                          ? orderController.historyOrderList!.isNotEmpty
                                ? const OrderViewWidget()
                                : Center(child: Text('no_order_found'.tr))
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
              )
            : Center(
                child: Text(
                  'you_have_no_permission_to_access_this_feature'.tr,
                  style: robotoMedium,
                ),
              );
      },
    );
  }

  Widget _buildDateFilterChip(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeExtraSmall,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: isSelected
                ? robotoBold.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeSmall,
                  )
                : robotoRegular.copyWith(
                    color: Theme.of(context).disabledColor,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
          ),
        ),
      ),
    );
  }
}
