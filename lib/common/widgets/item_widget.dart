import 'package:shoplancer_vendor/features/category/controllers/category_controller.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/helper/date_converter_helper.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/discount_tag_widget.dart';
import 'package:shoplancer_vendor/common/widgets/not_available_widget.dart';
import 'package:shoplancer_vendor/features/store/screens/item_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ItemWidget extends StatelessWidget {
  final Item item;
  final int index;
  final int length;
  final bool inStore;
  final bool isCampaign;
  final bool editOpensDetails;
  const ItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.length,
    this.inStore = false,
    this.isCampaign = false,
    this.editOpensDetails = false,
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
                        onPressed: () {
                          if (editOpensDetails) {
                            Get.toNamed(
                              RouteHelper.getItemDetailsRoute(item),
                              arguments: ItemDetailsScreen(product: item),
                            );
                          } else {
                            _showQuickUpdateDialog(context);
                          }
                        },
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
                            inStore
                                ? Icons.edit_outlined
                                : Icons.add_circle_outline_rounded,
                            color: Theme.of(context).primaryColor,
                            size: inStore ? 22 : 25,
                          ),
                        ),
                        tooltip: inStore ? 'edit'.tr : 'add'.tr,
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
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      if (editOpensDetails) {
                        Get.toNamed(
                          RouteHelper.getItemDetailsRoute(item),
                          arguments: ItemDetailsScreen(product: item),
                        );
                      } else {
                        _showQuickUpdateDialog(context);
                      }
                    },
                    child: Icon(
                      inStore
                          ? Icons.edit_outlined
                          : Icons.add_circle_outline_rounded,
                      color: Theme.of(context).primaryColor,
                      size: inStore ? 22 : 25,
                    ),
                  ),
          ],
        ),
      ),
    );
  });
}

  void _showQuickUpdateDialog(BuildContext context) {
    final double currentPrice = item.price ?? 0;
    final int currentStock = item.stock ?? 0;

    String priceStr = currentPrice > 0
        ? (currentPrice % 1 == 0
            ? currentPrice.toInt().toString()
            : currentPrice.toString())
        : '';
    String stockStr = currentStock > 0 ? currentStock.toString() : '100';
    bool enableStock = currentStock > 0;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: StatefulBuilder(
          builder: (context, setState) {
            void onNumPress(String val) {
              if (val == '.') {
                if (!priceStr.contains('.')) {
                  priceStr = priceStr.isEmpty ? '0.' : '$priceStr.';
                }
              } else {
                if (priceStr == '0' || priceStr.isEmpty) {
                  priceStr = val;
                } else {
                  priceStr += val;
                }
              }
              setState(() {});
            }

            void onBackspace() {
              if (priceStr.isNotEmpty) {
                priceStr = priceStr.substring(0, priceStr.length - 1);
                setState(() {});
              }
            }

            void onQuickAdd(double amount) {
              final double current = double.tryParse(priceStr) ?? 0.0;
              final double updated = current + amount;
              priceStr = updated % 1 == 0
                  ? updated.toInt().toString()
                  : updated.toString();
              setState(() {});
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: Product Info
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSmall),
                        child: CustomImageWidget(
                          image: item.imageFullUrl ?? '',
                          height: 48,
                          width: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inStore ? 'تعديل سعر ومخزون المنتج' : 'إضافة المنتج للمتجر',
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.name ?? '',
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Price Display Box
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.06),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سعر البيع:',
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        Text(
                          priceStr.isEmpty
                              ? '0.00'
                              : '$priceStr ${Get.find<SplashController>().configModel?.currencySymbol ?? 'ج.م'}',
                          style: robotoBold.copyWith(
                            fontSize: 22,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [5, 10, 20, 50, 100].map((amt) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: ActionChip(
                            label: Text('+$amt'),
                            onPressed: () => onQuickAdd(amt.toDouble()),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3x4 Numpad Keypad Grid
                  ...[
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ].map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: row.map((key) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).cardColor,
                                  foregroundColor: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .disabledColor
                                          .withOpacity(0.15),
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () => onNumPress(key),
                                child: Text(
                                  key,
                                  style: robotoBold.copyWith(fontSize: 18),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),

                  // Bottom Row: Backspace, 0, dot
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.08),
                                foregroundColor: Colors.red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: onBackspace,
                              child: const Icon(Icons.backspace_outlined, size: 20),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).cardColor,
                                foregroundColor: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .disabledColor
                                        .withOpacity(0.15),
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => onNumPress('0'),
                              child: Text('0',
                                  style: robotoBold.copyWith(fontSize: 18)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).cardColor,
                                foregroundColor: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .disabledColor
                                        .withOpacity(0.15),
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => onNumPress('.'),
                              child: Text('.',
                                  style: robotoBold.copyWith(fontSize: 20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stock Management Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withOpacity(0.05),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('manage_stock'.tr, style: robotoRegular),
                        Switch(
                          value: enableStock,
                          onChanged: (val) {
                            setState(() {
                              enableStock = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (enableStock) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('المخزون:', style: robotoRegular),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: stockStr,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (v) => stockStr = v,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Get.back(),
                          child: Text('cancel'.tr),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GetBuilder<StoreController>(
                          builder: (storeController) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: storeController.isLoading
                                  ? null
                                  : () {
                                      final double? price =
                                          double.tryParse(priceStr.trim());
                                      final int? stock = enableStock
                                          ? int.tryParse(stockStr.trim())
                                          : null;

                                      if (price == null || price <= 0) {
                                        showCustomSnackBar('enter_price'.tr);
                                        return;
                                      }
                                      if (enableStock) {
                                        if (stock == null || stock <= 0) {
                                          showCustomSnackBar(
                                              'stock_cannot_be_zero'.tr);
                                          return;
                                        }
                                      }

                                      if (!inStore) {
                                        final Map<String, dynamic>
                                            productData = {
                                          'product_id': item.id,
                                          'price': price,
                                          if (enableStock &&
                                              stock != null &&
                                              stock > 0)
                                            'stock': stock,
                                          'manage_stock': enableStock,
                                          if (item.discount != null &&
                                              item.discount! > 0)
                                            'discount': item.discount,
                                          if (item.discountType != null &&
                                              item.discountType!.isNotEmpty)
                                            'discount_type':
                                                item.discountType == 'amount'
                                                    ? 'flat'
                                                    : item.discountType,
                                          'status': true,
                                        };

                                        storeController
                                            .bulkAssignProducts([productData])
                                            .then((isSuccess) {
                                          if (isSuccess) {
                                            if (Get.isDialogOpen ?? false) {
                                              Get.back();
                                            }
                                            item.price = price;
                                            item.stock =
                                                enableStock ? stock : 0;
                                            if (Get.isRegistered<
                                                CategoryController>()) {
                                              final catController = Get.find<
                                                  CategoryController>();
                                              if (catController.itemList !=
                                                  null) {
                                                int idx = catController
                                                    .itemList!
                                                    .indexWhere((element) =>
                                                        element.id == item.id);
                                                if (idx != -1) {
                                                  catController
                                                      .itemList![idx]
                                                      .price = price;
                                                  catController
                                                      .itemList![idx]
                                                      .stock = enableStock
                                                      ? stock
                                                      : 0;
                                                }
                                              }
                                              catController.update();
                                            }
                                          }
                                        });
                                      } else {
                                        final Map<String, String> data = {
                                          '_method': 'post',
                                          'id': item.id.toString(),
                                          'product_id': item.id.toString(),
                                          if (enableStock)
                                            'current_stock': stockStr,
                                          'price': priceStr,
                                          'unit_price': priceStr,
                                          'discount':
                                              item.discount?.toString() ?? '0',
                                          'discount_type':
                                              item.discountType == 'flat'
                                                  ? 'amount'
                                                  : (item.discountType ??
                                                      'amount'),
                                          'store_id': Get.find<
                                                      ProfileController>()
                                                  .profileModel
                                                  ?.stores?[0]
                                                  .id
                                                  .toString() ??
                                              '',
                                          'category_id':
                                              item.categoryId?.toString() ?? '',
                                        };

                                        storeController
                                            .stockUpdate(data, item.id!)
                                            .then((isSuccess) {
                                          if (isSuccess) {
                                            if (Get.isDialogOpen ?? false) {
                                              Get.back();
                                            }
                                            item.price = price;
                                            item.stock =
                                                enableStock ? stock : 0;
                                            if (Get.isRegistered<
                                                CategoryController>()) {
                                              final catController = Get.find<
                                                  CategoryController>();
                                              if (catController.itemList !=
                                                  null) {
                                                int idx = catController
                                                    .itemList!
                                                    .indexWhere((element) =>
                                                        element.id == item.id);
                                                if (idx != -1) {
                                                  catController
                                                      .itemList![idx]
                                                      .price = price;
                                                  catController
                                                      .itemList![idx]
                                                      .stock = enableStock
                                                      ? stock
                                                      : 0;
                                                }
                                              }
                                              catController.update();
                                            }
                                          }
                                        });
                                      }
                                    },
                              child: storeController.isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(inStore ? 'update'.tr : 'add'.tr),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      barrierDismissible: false,
    );
  }
}
