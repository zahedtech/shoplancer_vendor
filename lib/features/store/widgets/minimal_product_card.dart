import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class MinimalProductCard extends StatelessWidget {
  final Item item;
  final bool inStore;

  const MinimalProductCard({
    super.key,
    required this.item,
    this.inStore = true,
  });

  @override
  Widget build(BuildContext context) {
    final double originalPrice = item.price ?? 0;
    final double discount = item.discount ?? 0;
    final bool hasDiscount = discount > 0;
    final String discountType = item.discountType ?? 'percent';
    final double discountedPrice =
        PriceConverterHelper.convertWithDiscount(
          originalPrice,
          discount,
          discountType,
        ) ??
        originalPrice;

    return InkWell(
      onTap: () {
        Get.toNamed(RouteHelper.getItemDetailsRoute(item));
      },
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04,
              ),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).disabledColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            SizedBox(
              height: 100,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(
                    height: 100,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault,
                      ),
                    ),
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: CustomImageWidget(
                          image: item.imageFullUrl ?? '',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE63946),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSmall,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE63946).withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          discountType == 'percent'
                              ? '${discount.toStringAsFixed(0)}% OFF'
                              : '${PriceConverterHelper.convertPrice(discount)} OFF',
                          style: robotoBold.copyWith(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name ?? '',
                          style: robotoMedium.copyWith(
                            fontSize: 14,
                            height: 1.2,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.description != null &&
                            item.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.description!.trim(),
                            style: robotoRegular.copyWith(
                              fontSize: 12,
                              color: Theme.of(context).disabledColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: PopupMenuButton<double>(
                            onSelected: (double newPrice) async {
                              Map<String, dynamic> data =
                                  Get.find<StoreController>()
                                      .buildStockUpdateData(
                                        item,
                                        price: newPrice,
                                      );
                              await Get.find<StoreController>().bulkItemsUpdate(
                                [data],
                              );
                            },
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasDiscount)
                                  Text(
                                    PriceConverterHelper.convertPrice(
                                      originalPrice,
                                    ),
                                    style: robotoRegular.copyWith(
                                      fontSize: 11,
                                      color: Theme.of(context).disabledColor,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        PriceConverterHelper.convertPrice(
                                          hasDiscount
                                              ? discountedPrice
                                              : originalPrice,
                                        ),
                                        style: robotoBold.copyWith(
                                          fontSize: 17,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 20,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            itemBuilder: (BuildContext context) {
                              final double basePrice = item.price ?? 0;
                              int start = (basePrice - 10).round();
                              if (start < 1) start = 1;
                              int end = (basePrice + 20).round();
                              if (end < start + 5) end = start + 30;

                              List<PopupMenuEntry<double>> options = [];
                              for (int p = start; p <= end; p++) {
                                final double val = p.toDouble();
                                final bool isCurrent = (basePrice.round() == p);
                                options.add(
                                  PopupMenuItem<double>(
                                    value: val,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          PriceConverterHelper.convertPrice(
                                            val,
                                          ),
                                          style: isCurrent
                                              ? robotoBold.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                )
                                              : robotoRegular,
                                        ),
                                        if (isCurrent)
                                          Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return options;
                            },
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Get.toNamed(RouteHelper.getItemDetailsRoute(item));
                          },
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
