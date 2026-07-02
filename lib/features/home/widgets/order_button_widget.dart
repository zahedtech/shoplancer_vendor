import 'package:shoplancer_vendor/common/widgets/custom_ink_well_widget.dart';
import 'package:shoplancer_vendor/features/order/controllers/order_controller.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:flutter/material.dart';

class OrderButtonWidget extends StatelessWidget {
  final String title;
  final int index;
  final OrderController orderController;
  final bool fromHistory;
  const OrderButtonWidget({super.key, required this.title, required this.index, required this.orderController, required this.fromHistory});

  Color _getStatusColor(BuildContext context, String status) {
    Color baseColor;
    switch (status) {
      case 'pending':
        baseColor = Colors.orange[800] ?? Colors.orange;
        break;
      case 'confirmed':
        baseColor = Colors.blue[700] ?? Colors.blue;
        break;
      case 'cooking':
      case 'processing':
        baseColor = Colors.teal[600] ?? Colors.teal;
        break;
      case 'ready_for_handover':
        baseColor = Colors.indigo[600] ?? Colors.indigo;
        break;
      case 'food_on_the_way':
        baseColor = Colors.green[700] ?? Colors.green;
        break;
      case 'all':
        baseColor = Theme.of(context).primaryColor;
        break;
      case 'delivered':
        baseColor = Colors.green[800] ?? Colors.green;
        break;
      case 'refunded':
        baseColor = Colors.red[800] ?? Colors.red;
        break;
      default:
        baseColor = Theme.of(context).primaryColor;
    }
    return baseColor;
  }

  @override
  Widget build(BuildContext context) {
    int selectedIndex;
    int length = 0;
    String status = '';
    if(fromHistory) {
      selectedIndex = orderController.historyIndex;
      status = orderController.statusList[index];
    }else {
      selectedIndex = orderController.orderIndex;
      status = orderController.runningOrders![index].status;
      length = orderController.runningOrders![index].orderList.length;
    }
    bool isSelected = selectedIndex == index;
    Color baseColor = _getStatusColor(context, status);

    return Padding(
      padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
      child: CustomInkWellWidget(
        radius: Dimensions.radiusLarge,
        onTap: () => fromHistory ? orderController.setHistoryIndex(index) : orderController.setOrderIndex(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: isSelected ? baseColor : baseColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(color: baseColor.withOpacity(0.4), width: 1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: isSelected ? Colors.white : baseColor,
                ),
              ),
              if (!fromHistory)
                Container(
                  margin: const EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
                  child: Text(
                    '($length)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: isSelected ? Colors.white : baseColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
