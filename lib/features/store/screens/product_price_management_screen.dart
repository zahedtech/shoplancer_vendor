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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Get.find<StoreController>().getItemList(offset: '1', type: 'all', search: '', categoryId: 0, willUpdate: false);
    Get.find<StoreController>().getStoreCategories(isUpdate: false);
    
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
                    boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 200]!, spreadRadius: 1, blurRadius: 5)],
                  ),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      child: CustomImageWidget(
                        image: '${item.imageFullUrl}',
                        height: 60, width: 60, fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name ?? '', style: robotoMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        Text(
                          PriceConverterHelper.convertPrice(item.price),
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor, decoration: TextDecoration.lineThrough),
                        ),
                        Text(
                          PriceConverterHelper.convertPrice(currentPrice),
                          style: robotoBold.copyWith(color: Theme.of(context).primaryColor),
                        ),
                      ]),
                    ),
                    Row(children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _updatedPrices[item.id!] = (currentPrice - 1) > 0 ? (currentPrice - 1) : 0;
                          });
                        },
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                        child: Text(
                          currentPrice.toStringAsFixed(2),
                          style: robotoMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _updatedPrices[item.id!] = currentPrice + 1;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      ),
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

  Future<void> _saveAllChanges(StoreController storeController) async {
    setState(() {
      _isSaving = true;
    });

    try {
      for (var entry in _updatedPrices.entries) {
        int itemId = entry.key;
        double newPrice = entry.value;

        // Fetch full item details to ensure we have all required data for update
        Item listItem = storeController.itemList!.firstWhere((element) => element.id == itemId);
        Item? fullItem = await storeController.getItemDetails(itemId);
        if (fullItem != null) {
          fullItem.price = newPrice;
          
          // Preserve unit info if it's missing in fullItem but present in listItem
          fullItem.unitType ??= listItem.unitType;
          fullItem.unitId ??= listItem.unitId;
          
          await storeController.addItem(fullItem, false, willRedirect: false);
        }
      }
      
      showCustomSnackBar('product_updated_successfully'.tr, isError: false);
      _updatedPrices.clear();
      storeController.getItemList(offset: '1', type: 'all', search: _searchController.text.trim(), categoryId: storeController.categoryId);
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
