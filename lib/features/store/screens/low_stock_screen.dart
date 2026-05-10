import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/common/widgets/discount_tag_widget.dart';
import 'package:sixam_mart_store/common/widgets/not_available_widget.dart';
import 'package:sixam_mart_store/common/widgets/rating_bar_widget.dart';
import 'package:sixam_mart_store/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_store/features/store/controllers/store_controller.dart';
import 'package:sixam_mart_store/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/features/store/widgets/update_stock_bottom_sheet.dart';
import 'package:sixam_mart_store/helper/date_converter_helper.dart';
import 'package:sixam_mart_store/helper/price_converter_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  final ScrollController scrollController = ScrollController();
  final Map<int, int> _updatedStocks = {};
  final Map<int, Item> _editedItems = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    Get.find<StoreController>().setOffset(1);

    Get.find<StoreController>().getLimitedStockItemList(
      Get.find<StoreController>().offset.toString(),
      willUpdate: false,
    );
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          Get.find<StoreController>().itemList != null &&
          !Get.find<StoreController>().isLoading) {
        int pageSize = (Get.find<StoreController>().pageSize! / 10).ceil();
        if (Get.find<StoreController>().offset < pageSize) {
          Get.find<StoreController>().setOffset(
            Get.find<StoreController>().offset + 1,
          );
          debugPrint('end of the page');
          Get.find<StoreController>().showBottomLoader();
          Get.find<StoreController>().getLimitedStockItemList(
            Get.find<StoreController>().offset.toString(),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'low_stock_products'.tr),
      body: RefreshIndicator(
        onRefresh: () => Get.find<StoreController>().getLimitedStockItemList(
          '1',
          willUpdate: false,
        ),
        child: GetBuilder<StoreController>(
          builder: (storeController) {
            return Column(
              children: [
                Expanded(
                  child: storeController.stockItemList != null
                      ? storeController.stockItemList!.isNotEmpty
                            ? ListView.builder(
                                controller: scrollController,
                                itemCount:
                                    storeController.stockItemList!.length,
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall,
                                ),
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: Dimensions.paddingSizeSmall,
                                    ),
                                    child: itemCard(
                                      storeController.stockItemList![index],
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomAssetImageWidget(
                                      Images.pendingItemIcon,
                                      height: 100,
                                      width: 100,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                    Text(
                                      'no_item_found'.tr,
                                      style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                      : const Center(child: CircularProgressIndicator()),
                ),

                storeController.isLoading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeSmall,
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),

                if (_updatedStocks.isNotEmpty) _bulkUpdateBar(storeController),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget itemCard(Item item) {
    double? discount = (item.storeDiscount == 0)
        ? item.discount
        : item.storeDiscount;
    String? discountType = (item.storeDiscount == 0)
        ? item.discountType
        : 'percent';
    bool isAvailable = DateConverterHelper.isAvailable(
      item.availableTimeStarts,
      item.availableTimeEnds,
    );
    int currentStock = _updatedStocks[item.id] ?? item.stock ?? 0;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: CustomImageWidget(
                    image: '${item.imageFullUrl}',
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                if (discount! > 0)
                  DiscountTagWidget(
                    discount: discount,
                    discountType: discountType,
                    freeDelivery: false,
                  ),
                if (!isAvailable) const NotAvailableWidget(isStore: false),
              ],
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            // Details Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? '',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Row(
                    children: [
                      Text(
                        PriceConverterHelper.convertPrice(
                          item.price,
                          discount: discount,
                          discountType: discountType,
                        ),
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Text(
                          PriceConverterHelper.convertPrice(item.price),
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).disabledColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const Spacer(),

                  // Stock Control Section
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeExtraSmall,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusSmall,
                      ),
                    ),
                    child: Text(
                      '${'stock'.tr}: $currentStock',
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions Section
            const VerticalDivider(width: 24, thickness: 1),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _counterButton(
                  Icons.add,
                  Colors.green,
                  () => _setUpdatedStock(item, currentStock + 1),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                _counterButton(
                  Icons.remove,
                  Colors.red,
                  () => _setUpdatedStock(item, currentStock - 1),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                InkWell(
                  onTap: () => Get.bottomSheet(
                    UpdateStockBottomSheet(
                      item: item,
                      onSuccess: (bool isSuccess) {},
                    ),
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _bulkUpdateBar(StoreController storeController) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${'total_items_selected'.tr}: ${_updatedStocks.length}',
                  style: robotoMedium,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _editedItems.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                    itemBuilder: (context, index) {
                      Item item = _editedItems.values.elementAt(index);
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusLarge,
                          ),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusDefault,
                              ),
                              child: CustomImageWidget(
                                image: '${item.imageFullUrl}',
                                height: 40,
                                width: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(
                              width: Dimensions.paddingSizeExtraSmall,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.name ?? '',
                                  style: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                  ),
                                  maxLines: 1,
                                ),
                                Text(
                                  '${item.stock ?? 0} → ${_updatedStocks[item.id]}',
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              constraints: const BoxConstraints(
                                maxWidth: 30,
                                maxHeight: 30,
                              ),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeUpdatedStock(item.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          _isSaving
              ? const CircularProgressIndicator()
              : Expanded(
                  child: CustomButtonWidget(
                    buttonText: 'save_changes'.tr,
                    onPressed: () => _saveAllStockChanges(storeController),
                  ),
                ),
        ],
      ),
    );
  }

  void _setUpdatedStock(Item item, int stock) {
    if (item.id == null || stock < 0) return;
    setState(() {
      if (stock == (item.stock ?? 0)) {
        _updatedStocks.remove(item.id);
        _editedItems.remove(item.id);
      } else {
        _updatedStocks[item.id!] = stock;
        _editedItems[item.id!] = item;
      }
    });
  }

  void _removeUpdatedStock(int? itemId) {
    if (itemId == null) return;
    setState(() {
      _updatedStocks.remove(itemId);
      _editedItems.remove(itemId);
    });
  }

  Future<void> _saveAllStockChanges(StoreController storeController) async {
    setState(() {
      _isSaving = true;
    });

    try {
      List<Map<String, String>> updates = [];
      for (var entry in _updatedStocks.entries) {
        Item? item = storeController.stockItemList?.firstWhereOrNull(
          (element) => element.id == entry.key,
        );
        if (item == null) {
          item = _editedItems[entry.key];
        }
        if (item != null) {
          updates.add(
            storeController.buildStockUpdateData(item, stock: entry.value),
          );
        }
      }

      if (updates.isNotEmpty) {
        await storeController.bulkItemsUpdate(updates);
        _updatedStocks.clear();
        _editedItems.clear();
      }
    } catch (e) {
      debugPrint('Error saving stocks: $e');
      showCustomSnackBar('failed'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
