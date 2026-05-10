import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_store/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_store/features/store/controllers/store_controller.dart';
import 'package:sixam_mart_store/features/store/domain/models/item_model.dart';
import 'package:sixam_mart_store/helper/price_converter_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class ProductPriceManagementScreen extends StatefulWidget {
  const ProductPriceManagementScreen({super.key});

  @override
  State<ProductPriceManagementScreen> createState() => _ProductPriceManagementScreenState();
}

class _ProductPriceManagementScreenState extends State<ProductPriceManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<int, double> _updatedPrices = {};
  final Map<int, Item> _editedItems = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Get.find<StoreController>().getItemList(offset: '1', type: 'all', search: '', categoryId: 0, willUpdate: false);
    Get.find<StoreController>().getStoreCategories();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent
          && Get.find<StoreController>().itemList != null
          && !Get.find<StoreController>().isLoading) {
        int pageSize = (Get.find<StoreController>().itemSize! / 10).ceil();
        if (Get.find<StoreController>().offset < pageSize) {
          Get.find<StoreController>().setOffset(Get.find<StoreController>().offset + 1);
          debugPrint('End of the page');
          Get.find<StoreController>().showBottomLoader();
          Get.find<StoreController>().getItemList(
            offset: Get.find<StoreController>().offset.toString(),
            type: Get.find<StoreController>().type,
            search: _searchController.text.trim(),
            categoryId: Get.find<StoreController>().categoryId,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      return Scaffold(
        appBar: CustomAppBarWidget(title: 'product_basket'.tr),
        body: Column(children: [
          
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 200]!, spreadRadius: 1, blurRadius: 5)],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'search_by_item_name'.tr,
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          storeController.getItemList(offset: '1', type: 'all', search: '', categoryId: storeController.categoryId);
                        },
                      ) : null,
                    ),
                    onSubmitted: (value) {
                      storeController.getItemList(offset: '1', type: 'all', search: value.trim(), categoryId: storeController.categoryId);
                    },
                  ),
                ),
              ),
            ]),
          ),

          SizedBox(
            height: 40,
            child: storeController.categoryNameList != null ? ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              itemCount: storeController.categoryNameList!.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    storeController.setCategory(index: index, foodType: 'all');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: index == storeController.categoryIndex ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                      border: Border.all(color: index == storeController.categoryIndex ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      index == 0 ? 'all'.tr : storeController.categoryNameList![index],
                      style: robotoMedium.copyWith(
                        color: index == storeController.categoryIndex ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                  ),
                );
              },
            ) : const SizedBox(),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Expanded(
            child: storeController.itemList != null ? ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              itemCount: storeController.itemList!.length,
              itemBuilder: (context, index) {
                Item item = storeController.itemList![index];
                double currentPrice = _updatedPrices[item.id] ?? item.price ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10)],
                  ),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      child: CustomImageWidget(
                        image: '${item.imageFullUrl}',
                        height: 70, width: 70, fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name ?? '', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        
                        Row(children: [
                          Text(
                            PriceConverterHelper.convertPrice(currentPrice),
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Text(
                            PriceConverterHelper.convertPrice(item.price),
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall, 
                              color: Theme.of(context).disabledColor, 
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ]),
                      ]),
                    ),

                    Row(children: [
                      _counterButton(Icons.remove, Colors.red, () {
                        _setUpdatedPrice(item, (currentPrice - 1) > 0 ? (currentPrice - 1) : 0);
                      }),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                        child: Text(
                          currentPrice.toStringAsFixed(2),
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                        ),
                      ),
                      _counterButton(Icons.add, Colors.green, () {
                        _setUpdatedPrice(item, currentPrice + 1);
                      }),
                    ]),
                  ]),
                );
              },
            ) : const Center(child: CircularProgressIndicator()),
          ),

          if (_updatedPrices.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      '${'total_items_selected'.tr}: ${_updatedPrices.length}',
                      style: robotoMedium,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _editedItems.length,
                        separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
                        itemBuilder: (context, index) {
                          Item item = _editedItems.values.elementAt(index);
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
                            ),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                child: CustomImageWidget(
                                  image: '${item.imageFullUrl}',
                                  height: 40, width: 40, fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(item.name ?? '', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall), maxLines: 1),
                                Text(
                                  '${PriceConverterHelper.convertPrice(item.price)} → ${PriceConverterHelper.convertPrice(_updatedPrices[item.id])}',
                                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor),
                                ),
                              ]),
                              IconButton(
                                constraints: const BoxConstraints(maxWidth: 30, maxHeight: 30),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                onPressed: () => _removeUpdatedPrice(item.id),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                _isSaving ? const CircularProgressIndicator() : Expanded(
                  child: CustomButtonWidget(
                    buttonText: 'save_changes'.tr,
                    onPressed: () => _saveAllChanges(storeController),
                  ),
                ),
              ]),
            ),
        ]),
      );
    });
  }

  void _setUpdatedPrice(Item item, double price) {
    if (item.id == null) return;
    setState(() {
      if (price == (item.price ?? 0)) {
        _updatedPrices.remove(item.id);
        _editedItems.remove(item.id);
      } else {
        _updatedPrices[item.id!] = price;
        _editedItems[item.id!] = item;
      }
    });
  }

  void _removeUpdatedPrice(int? itemId) {
    if (itemId == null) return;
    setState(() {
      _updatedPrices.remove(itemId);
      _editedItems.remove(itemId);
    });
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

  Future<void> _saveAllChanges(StoreController storeController) async {
    setState(() {
      _isSaving = true;
    });

    try {
      List<Map<String, String>> updates = [];
      for (var entry in _updatedPrices.entries) {
        int itemId = entry.key;
        double newPrice = entry.value;

        Item? item = storeController.itemList?.firstWhereOrNull((element) => element.id == itemId);
        if (item != null) {
          updates.add(storeController.buildStockUpdateData(item, price: newPrice));
        }
      }

      if (updates.isNotEmpty) {
        await storeController.bulkItemsUpdate(updates);
        _updatedPrices.clear();
        _editedItems.clear();
      }
    } catch (e) {
      debugPrint('Error saving prices: $e');
      showCustomSnackBar('failed_to_update_price'.tr);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
