import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_details_model.dart';
import 'package:shoplancer_vendor/features/order/domain/models/order_model.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderItemWidget extends StatelessWidget {
  final OrderModel? order;
  final OrderDetailsModel orderDetails;
  const OrderItemWidget({
    super.key,
    required this.order,
    required this.orderDetails,
  });

  @override
  Widget build(BuildContext context) {
    String addOnText = '';
    for (var addOn in orderDetails.addOns!) {
      addOnText =
          '$addOnText${(addOnText.isEmpty) ? '' : ',  '}${addOn.name} (${addOn.quantity})';
    }

    String variationText = '';
    if (orderDetails.variation!.isNotEmpty) {
      if (orderDetails.variation!.isNotEmpty) {
        List<String> variationTypes = orderDetails.variation![0].type!.split(
          '-',
        );
        if (variationTypes.length ==
            orderDetails.itemDetails!.choiceOptions!.length) {
          int index = 0;
          for (var choice in orderDetails.itemDetails!.choiceOptions!) {
            variationText =
                '$variationText${(index == 0) ? '' : ',  '}${choice.title} - ${variationTypes[index]}';
            index = index + 1;
          }
        } else {
          variationText = orderDetails.itemDetails!.variations![0].type!;
        }
      }
    } else if (orderDetails.foodVariation!.isNotEmpty) {
      for (FoodVariation variation in orderDetails.foodVariation!) {
        variationText +=
            '${variationText.isNotEmpty ? ', ' : ''}${variation.name} (';
        for (VariationValue value in variation.variationValues!) {
          variationText +=
              '${variationText.endsWith('(') ? '' : ', '}${value.level}';
        }
        variationText += ')';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            orderDetails.itemDetails!.imageFullUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: CustomImageWidget(
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                      image: '${orderDetails.itemDetails!.imageFullUrl}',
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: CustomImageWidget(
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                      image: Images.image,
                    ),
                  ),
            SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          orderDetails.itemDetails!.name!,
                          style: robotoBold.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Text(
                        '${'quantity'.tr}: ',
                        style: robotoRegular.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      // 1.0 => 1 1.5 => 1.5 2.0 => 2
                      if (Get.find<SplashController>()
                              .configModel!
                              .moduleConfig!
                              .module!
                              .unit! &&
                          orderDetails.itemDetails != null)
                        Text(
                          _getFormattedQuantityString(
                            orderDetails.quantity ?? 1.0,
                            orderDetails.itemDetails!.quantityUnit,
                            orderDetails.itemDetails!.unitType,
                          ),
                          style: robotoMedium,
                        )
                      else ...[
                        Text(
                          '${orderDetails.quantity! % 1 == 0 ? orderDetails.quantity!.toInt() : orderDetails.quantity}',
                          style: robotoMedium,
                        ),
                        const SizedBox(width: Dimensions.fontSizeExtraSmall),
                        Text(
                          orderDetails.itemDetails!.veg == 0
                              ? 'non_veg'.tr
                              : 'veg'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Text(
                    PriceConverterHelper.convertPrice(orderDetails.price),
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        variationText.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(
                  top: Dimensions.paddingSizeExtraSmall,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${'variations'.tr} ',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                    Text(': '),
                    Expanded(
                      flex: 4,
                      child: Text(
                        " $variationText",
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(),

        addOnText.isNotEmpty
            ? Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${'addons'.tr} ',
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                  Text(': '),
                  Expanded(
                    flex: 4,
                    child: Text(
                      " $addOnText",
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox(),
      ],
    );
  }

  String _getFormattedQuantityString(double quantity, double? quantityUnit, String? unitType) {
    String qtyStr = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
    if (quantityUnit == null || quantityUnit <= 0) {
      return '$qtyStr ${unitType ?? ''}';
    }
    String unitValStr = quantityUnit % 1 == 0 ? quantityUnit.toInt().toString() : quantityUnit.toString();
    String unit = (unitType ?? '').trim();
    if (quantityUnit == 1) {
      return '$qtyStr $unit';
    }
    double totalValue = quantity * quantityUnit;
    String totalValStr = totalValue % 1 == 0 ? totalValue.toInt().toString() : totalValue.toStringAsFixed(2);
    if (totalValStr.contains('.')) {
      totalValStr = totalValStr.replaceAll(RegExp(r'\.?0+$'), '');
    }
    bool isGram = ['gr', 'g', 'gm', 'gram', 'grams', 'جرام', 'غرام', 'جم', 'غ'].contains(unit.toLowerCase());
    bool isMl = ['ml', 'milliliter', 'milliliters', 'مل', 'ملل', 'ملي'].contains(unit.toLowerCase());
    if (isGram && totalValue >= 1000) {
      double kgValue = totalValue / 1000;
      String kgValStr = kgValue % 1 == 0 ? kgValue.toInt().toString() : kgValue.toStringAsFixed(2);
      if (kgValStr.contains('.')) {
        kgValStr = kgValStr.replaceAll(RegExp(r'\.?0+$'), '');
      }
      String targetUnit = _isArabic(unit) ? 'كغم' : 'kg';
      return '$qtyStr * $unitValStr $unit = $kgValStr $targetUnit';
    } else if (isMl && totalValue >= 1000) {
      double lValue = totalValue / 1000;
      String lValStr = lValue % 1 == 0 ? lValue.toInt().toString() : lValue.toStringAsFixed(2);
      if (lValStr.contains('.')) {
        lValStr = lValStr.replaceAll(RegExp(r'\.?0+$'), '');
      }
      String targetUnit = _isArabic(unit) ? 'لتر' : 'L';
      return '$qtyStr * $unitValStr $unit = $lValStr $targetUnit';
    } else {
      return '$qtyStr * $unitValStr $unit = $totalValStr $unit';
    }
  }

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}
