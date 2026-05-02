import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/features/business/domain/models/package_model.dart';
import 'package:sixam_mart_store/features/business/widgets/curve_clipper_widget.dart';
import 'package:sixam_mart_store/features/business/widgets/package_widget.dart';
import 'package:sixam_mart_store/helper/price_converter_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class PackageCardWidget extends StatelessWidget {
  final int? currentIndex;
  final Packages package;
  final bool fromChangePlan;
  final bool isRental;
  const PackageCardWidget({
    super.key,
    this.currentIndex,
    required this.package,
    this.fromChangePlan = false,
    this.isRental = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isCommission = package.id == -1;
    bool isSelected = currentIndex != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor.withValues(alpha: 0.2),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 5),
          ],
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    package.packageName ?? '',
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: isSelected
                          ? Theme.of(context).cardColor
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: Theme.of(context).cardColor),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isCommission
                      ? '${package.price}%'
                      : PriceConverterHelper.convertPrice(package.price),
                  style: robotoBold.copyWith(
                    fontSize: 24,
                    color: isSelected
                        ? Theme.of(context).cardColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                if (!isCommission)
                  Text(
                    '/ ${package.validity} ${'days'.tr}',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: isSelected
                          ? Theme.of(context).cardColor.withValues(alpha: 0.8)
                          : Theme.of(context).disabledColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            if (isCommission)
              Text(
                package.description ?? '',
                style: robotoRegular.copyWith(
                  color: isSelected
                      ? Theme.of(context).cardColor.withValues(alpha: 0.8)
                      : Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                  fontSize: Dimensions.fontSizeSmall,
                ),
              )
            else
              Column(
                children: [
                  _buildFeatureItem(
                    context,
                    '${isRental ? 'max_trip'.tr : 'max_order'.tr} (${package.maxOrder?.tr})',
                    isSelected,
                  ),
                  _buildFeatureItem(
                    context,
                    '${isRental ? 'max_vehicle'.tr : 'max_product'.tr} (${package.maxProduct?.tr})',
                    isSelected,
                  ),
                  if (package.pos != 0)
                    _buildFeatureItem(context, 'pos'.tr, isSelected),
                  if (package.mobileApp != 0)
                    _buildFeatureItem(context, 'mobile_app'.tr, isSelected),
                  if (package.chat != 0)
                    _buildFeatureItem(context, 'chat'.tr, isSelected),
                  if (package.review != 0)
                    _buildFeatureItem(context, 'review'.tr, isSelected),
                  if (package.selfDelivery != 0)
                    _buildFeatureItem(context, 'self_delivery'.tr, isSelected),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String title,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 14,
            color: isSelected
                ? Theme.of(context).cardColor
                : Theme.of(context).primaryColor,
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Expanded(
            child: Text(
              title.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: isSelected
                    ? Theme.of(context).cardColor.withValues(alpha: 0.9)
                    : Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
