import 'package:sixam_mart_store/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_store/features/store/controllers/store_controller.dart';
import 'package:sixam_mart_store/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/helper/date_converter_helper.dart';
import 'package:sixam_mart_store/helper/price_converter_helper.dart';
import 'package:sixam_mart_store/helper/route_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/common/widgets/discount_tag_widget.dart';
import 'package:sixam_mart_store/common/widgets/not_available_widget.dart';
import 'package:sixam_mart_store/features/store/screens/item_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ItemWidget extends StatelessWidget {
  final Item item;
  final int index;
  final int length;
  final bool inStore;
  final bool isCampaign;
  const ItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.length,
    this.inStore = false,
    this.isCampaign = false,
  });

  @override
  Widget build(BuildContext context) {
    double discount;
    String discountType;
    bool isAvailable;
    final double resolvedStoreDiscount = item.storeDiscount ?? 0;
    discount = (resolvedStoreDiscount == 0 || isCampaign)
        ? (item.discount ?? 0)
        : resolvedStoreDiscount;
    discountType = (resolvedStoreDiscount == 0 || isCampaign)
        ? (item.discountType ?? 'percent')
        : 'percent';
    isAvailable = DateConverterHelper.isAvailable(
      item.availableTimeStarts,
      item.availableTimeEnds,
    );

    double width = MediaQuery.of(context).size.width;

    return GetBuilder<StoreController>(builder: (storeController) {
      bool isSelected = storeController.selectedItemList.contains(item.id);

      return InkWell(
        onTap: () {
          if (storeController.isSelectionMode) {
            storeController.toggleSelection(item.id!);
          } else {
            Get.toNamed(
              RouteHelper.getItemDetailsRoute(item),
              arguments: ItemDetailsScreen(product: item),
            );
          }
        },
        onLongPress: () {
          if (!storeController.isSelectionMode) {
            storeController.enableSelectionMode(item.id!);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
          ),
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : Theme.of(context).cardColor,
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 3),
                color: Colors.grey[Get.isDarkMode ? 700 : 200]!,
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              if (storeController.isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (val) => storeController.toggleSelection(item.id!),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
            /// Image section
            item.imageFullUrl != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusDefault,
                        ),
                        child: CustomImageWidget(
                          image: '${item.imageFullUrl}',
                          height: 60,
                          width: 69,
                          fit: BoxFit.cover,
                        ),
                      ),
                      DiscountTagWidget(
                        discount: discount,
                        discountType: discountType,
                        freeDelivery: false,
                      ),
                      isAvailable
                          ? const SizedBox()
                          : const NotAvailableWidget(isStore: false),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                    child: CustomImageWidget(
                      image: Images.image,
                      height: 60,
                      width: 69,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            /// Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  /// Name
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.name ?? '',
                        textAlign: TextAlign.start,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: Dimensions.paddingSizeExtraSmall),

                      SizedBox(
                        width: item.imageFullUrl == null
                            ? Dimensions.paddingSizeExtraSmall
                            : 0,
                      ),

                      item.imageFullUrl == null
                          ? discount > 0
                                ? Text(
                                    '(${discount > 0 ? '$discount${discountType == 'percent' ? '%' : Get.find<SplashController>().configModel!.currencySymbol} ${'off'.tr}' : 'free_delivery'.tr})',
                                    style: robotoMedium.copyWith(
                                      color: Colors.green,
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                    ),
                                  )
                                : const SizedBox()
                          : const SizedBox(),
                    ],
                  ),
                  SizedBox(
                    height: item.imageFullUrl != null
                        ? Dimensions.paddingSizeExtraSmall
                        : 0,
                  ),

                  /// Rating bar
                  Row(
                    children: [
                      // RatingBarWidget(
                      //   rating: item.avgRating, size: 12,
                      //   ratingCount: item.ratingCount,
                      // ),
                      if (item.avgRating != null && item.avgRating != 0.0)
                        Row(
                          children: [
                            Image.asset(Images.starIcon, width: 10),
                            Text(
                              ' ${item.avgRating!.toStringAsFixed(2)} ',
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                            Text(
                              ' (${item.ratingCount})',
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                color: Theme.of(context).hintColor,
                                decoration: TextDecoration.underline,
                                decorationColor: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),

                      item.imageFullUrl == null && !isAvailable
                          ? Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                '(${'not_available_now'.tr})',
                                textAlign: TextAlign.center,
                                style: robotoRegular.copyWith(
                                  color: Colors.red,
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ],
                  ),
                  const SizedBox(height: 2),

                  /// Price and Stock
                  Row(
                    children: [
                      discount > 0
                          ? Text(
                              PriceConverterHelper.convertPrice(item.price),
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                color: Theme.of(context).disabledColor,
                                decoration: TextDecoration.lineThrough,
                              ),
                            )
                          : const SizedBox(),

                      SizedBox(
                        width: discount > 0
                            ? Dimensions.paddingSizeExtraSmall
                            : 0,
                      ),

                      Text(
                        PriceConverterHelper.convertPrice(
                          item.price,
                          discount: discount,
                          discountType: discountType,
                        ),
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                ],
              ),
            ),

            width > 320
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _showQuickUpdateDialog(context),
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusSmall,
                            ),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 25,
                          ),
                        ),
                        tooltip: 'add'.tr,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: Dimensions.paddingSizeSmall,
                          bottom: Dimensions.paddingSizeSmall,
                        ),
                        child: item.stock != 0 && item.stock != null
                            ? Text(
                                'Stock : ${item.stock}',
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).disabledColor,
                                ),
                              )
                            : SizedBox.shrink(),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => _showQuickUpdateDialog(context),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 25,
                    ),
                  ),
          ],
        ),
      ),
    );
  });
}

  void _showQuickUpdateDialog(BuildContext context) {
    final TextEditingController priceController = TextEditingController(
      text: (item.price ?? 0).toString(),
    );
    final TextEditingController stockController = TextEditingController(
      text: (item.stock ?? 0).toString(),
    );

    Get.dialog(
      AlertDialog(
        title: Text('add'.tr, style: robotoMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'price'.tr),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'stock'.tr),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          GetBuilder<StoreController>(
            builder: (storeController) {
              return storeController.isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall,
                      ),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: () {
                        final String priceText = priceController.text.trim();
                        final String stockText = stockController.text.trim();

                        final double? price = double.tryParse(priceText);
                        final int? stock = int.tryParse(stockText);

                        if (price == null || price <= 0) {
                          showCustomSnackBar('enter_price'.tr);
                          return;
                        }
                        if (stock == null || stock <= 0) {
                          showCustomSnackBar('stock_cannot_be_zero'.tr);
                          return;
                        }

                        final Map<String, String> data = {
                          '_method': 'post',
                          'id': item.id.toString(),
                          'product_id': item.id.toString(),
                          'current_stock': stockText,
                          'price': priceText,
                          'unit_price': priceText,
                          'discount': item.discount?.toString() ?? '0',
                          'discount_type': item.discountType ?? 'amount',
                          'store_id':
                              Get.find<ProfileController>()
                                  .profileModel
                                  ?.stores?[0]
                                  .id
                                  .toString() ??
                              '',
                          'category_id': item.categoryId?.toString() ?? '',
                        };

                        storeController.stockUpdate(data, item.id!);
                      },
                      child: Text('update'.tr),
                    );
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
