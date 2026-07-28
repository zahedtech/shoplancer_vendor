import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:shoplancer_vendor/common/widgets/barcode_scanner_screen.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/discount_tag_widget.dart';
import 'package:shoplancer_vendor/features/chat/widgets/search_field_widget.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<int, double> _updatedPrices = {};
  final Map<int, Item> _editedItems = {};
  String? _barcodeSearch;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final StoreController storeController = Get.find<StoreController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      storeController.resetFilters();
      storeController.getStoreCategories();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          storeController.itemList != null &&
          !storeController.isLoading) {
        final int totalItems = storeController.itemSize ?? 0;
        if (totalItems == 0) {
          return;
        }
        final int pageSize = (totalItems / 10).ceil();
        if (storeController.offset < pageSize) {
          storeController.setOffset(storeController.offset + 1);
          storeController.showBottomLoader();
          storeController.getItemList(
            offset: storeController.offset.toString(),
            type: storeController.type,
            search: _searchController.text.trim(),
            categoryId: storeController.categoryId,
            barcode: _barcodeSearch,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        return Scaffold(
          appBar: const CustomAppBarWidget(title: 'إدارة المنتجات'),
          body: storeController.categoryNameList != null
              ? Column(
                  children: [
                    Container(
                      height: 50,
                      color: Theme.of(context).cardColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeExtraSmall,
                      ),
                      child: ListView.builder(
                        controller: _categoryScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                        ),
                        itemCount: storeController.categoryNameList!.length,
                        itemBuilder: (context, index) {
                          final bool isSelected =
                              index == storeController.categoryIndex;
                          return InkWell(
                            onTap: () {
                              _searchController.clear();
                              _barcodeSearch = null;
                              storeController.setCategory(
                                index: index,
                                foodType: 'all',
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: Dimensions.paddingSizeSmall,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                                vertical: Dimensions.paddingSizeExtraSmall,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusExtraLarge,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(
                                          context,
                                        ).disabledColor.withOpacity(0.3),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                index == 0
                                    ? 'all'.tr
                                    : storeController.categoryNameList![index],
                                style: robotoMedium.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                      ),
                      child: SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: SearchFieldWidget(
                                  fromReview: true,
                                  controller: _searchController,
                                  hint: '${'search_by_item_name'.tr}...',
                                  suffixIcon: storeController.isSearching
                                      ? CupertinoIcons.clear_thick
                                      : CupertinoIcons.search,
                                  iconPressed: () {
                                    if (!storeController.isSearching) {
                                      _searchProducts(
                                        storeController,
                                        search: _searchController.text.trim(),
                                      );
                                    } else {
                                      _clearProductSearch(storeController);
                                    }
                                  },
                                  onSubmit: (String text) {
                                    _searchProducts(
                                      storeController,
                                      search: text.trim(),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            _scanButton(context, storeController),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          _searchController.clear();
                          _barcodeSearch = null;
                          setState(() {
                            _updatedPrices.clear();
                            _editedItems.clear();
                          });
                          storeController.resetFilters();
                        },
                        child: storeController.itemList != null
                            ? storeController.itemList!.isNotEmpty
                                  ? GridView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            Dimensions.paddingSizeDefault,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            childAspectRatio: 0.62,
                                            crossAxisSpacing:
                                                Dimensions.paddingSizeDefault,
                                            mainAxisSpacing:
                                                Dimensions.paddingSizeDefault,
                                          ),
                                      itemCount:
                                          storeController.itemList!.length,
                                      itemBuilder: (context, index) {
                                        final Item item =
                                            storeController.itemList![index];
                                        return _buildProductCard(
                                          context,
                                          item,
                                          storeController,
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            Images.emptyBox,
                                            width: 150,
                                          ),
                                          const SizedBox(
                                            height:
                                                Dimensions.paddingSizeDefault,
                                          ),
                                          Text(
                                            'no_item_available'.tr,
                                            style: robotoMedium.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).disabledColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.62,
                                      crossAxisSpacing:
                                          Dimensions.paddingSizeDefault,
                                      mainAxisSpacing:
                                          Dimensions.paddingSizeDefault,
                                    ),
                                itemCount: 10,
                                itemBuilder: (context, index) {
                                  return _buildShimmerCard(context);
                                },
                              ),
                      ),
                    ),
                    if (storeController.isLoading &&
                        storeController.itemList != null)
                      Padding(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeSmall,
                        ),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    if (_updatedPrices.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeDefault,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
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
                                    '${'total_items_selected'.tr}: ${_updatedPrices.length}',
                                    style: robotoMedium,
                                  ),
                                  const SizedBox(
                                    height: Dimensions.paddingSizeExtraSmall,
                                  ),
                                  SizedBox(
                                    height: 54,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _editedItems.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(
                                            width: Dimensions.paddingSizeSmall,
                                          ),
                                      itemBuilder: (context, index) {
                                        final Item editedItem = _editedItems
                                            .values
                                            .elementAt(index);
                                        final double newPrice =
                                            _updatedPrices[editedItem.id] ??
                                            (editedItem.price ?? 0);
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
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      Dimensions.radiusDefault,
                                                    ),
                                                child: CustomImageWidget(
                                                  image:
                                                      '${editedItem.imageFullUrl}',
                                                  height: 40,
                                                  width: 40,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: Dimensions
                                                    .paddingSizeExtraSmall,
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 110,
                                                    child: Text(
                                                      editedItem.name ?? '',
                                                      style: robotoMedium.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeExtraSmall,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${PriceConverterHelper.convertPrice(editedItem.price)} → ${PriceConverterHelper.convertPrice(newPrice)}',
                                                    style: robotoBold.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeExtraSmall,
                                                      color: Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              IconButton(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxWidth: 30,
                                                      maxHeight: 30,
                                                    ),
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () =>
                                                    _removeUpdatedPrice(
                                                      editedItem.id,
                                                    ),
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
                            const SizedBox(
                              width: Dimensions.paddingSizeDefault,
                            ),
                            _isSaving
                                ? SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(context).primaryColor,
                                            ),
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    width: 160,
                                    child: CustomButtonWidget(
                                      buttonText: 'save_changes'.tr,
                                      onPressed: () =>
                                          _saveAllChanges(storeController),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _searchProducts(
    StoreController storeController, {
    required String search,
    String? barcode,
  }) {
    if (search.isEmpty) {
      showCustomSnackBar('write_item_name_for_search'.tr);
      return;
    }

    _barcodeSearch = barcode;
    storeController.getItemList(
      offset: '1',
      type: 'all',
      search: search,
      categoryId: storeController.categoryId,
      barcode: barcode,
    );
  }

  void _clearProductSearch(StoreController storeController) {
    _searchController.clear();
    _barcodeSearch = null;
    storeController.getItemList(
      offset: '1',
      type: 'all',
      search: '',
      categoryId: storeController.categoryId,
    );
  }

  Future<void> _scanAndSearch(StoreController storeController) async {
    final String? code = await Get.to<String>(
      () => const BarcodeScannerScreen(),
    );
    if (code == null || code.trim().isEmpty) {
      return;
    }

    final String barcode = code.trim();
    _searchController.text = barcode;
    _searchProducts(storeController, search: barcode, barcode: barcode);
  }

  Widget _scanButton(BuildContext context, StoreController storeController) {
    return InkWell(
      onTap: () => _scanAndSearch(storeController),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        height: 50,
        width: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          Icons.barcode_reader,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Item item,
    StoreController storeController,
  ) {
    final bool isActive = item.status == 1;
    final bool isLoading = storeController.loadingItemsList.contains(item.id);
    final double currentPrice = _updatedPrices[item.id] ?? item.price ?? 0;
    final double originalPrice = item.price ?? 0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(
          color: Theme.of(context).disabledColor.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomImageWidget(
                  image: item.imageFullUrl ?? '',
                  height: double.maxFinite,
                  width: double.maxFinite,
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.02),
                          Colors.black.withOpacity(0.10),
                        ],
                      ),
                    ),
                  ),
                ),
                if ((item.discount ?? 0) > 0)
                  DiscountTagWidget(
                    discount: item.discount ?? 0,
                    discountType: item.discountType ?? 'percent',
                    freeDelivery: false,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeExtraSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? '',
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                InkWell(
                  onTap: () =>
                      _showEditPriceDialog(context, item, currentPrice),
                  child: Text(
                    PriceConverterHelper.convertPrice(currentPrice),
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (currentPrice != originalPrice) ...[
                  const SizedBox(height: 2),
                  Text(
                    PriceConverterHelper.convertPrice(originalPrice),
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).disabledColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeExtraSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    border: Border.all(
                      color: Theme.of(context).disabledColor.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _counterButton(Icons.remove, Colors.red, () {
                        _setUpdatedPrice(
                          item,
                          (currentPrice - 1) > 0 ? (currentPrice - 1) : 0,
                        );
                      }),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _showEditPriceDialog(context, item, currentPrice),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSmall,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              currentPrice % 1 == 0
                                  ? currentPrice.toInt().toString()
                                  : currentPrice.toStringAsFixed(2),
                              textAlign: TextAlign.center,
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      _counterButton(Icons.add, Colors.green, () {
                        _setUpdatedPrice(item, currentPrice + 1);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Row(
                  children: [
                    Expanded(child: _statusBadge(context, isActive)),
                    isLoading
                        ? const SizedBox(
                            width: 38,
                            height: 34,
                            child: Center(child: CupertinoActivityIndicator()),
                          )
                        : Transform.scale(
                            scale: 0.76,
                            child: CupertinoSwitch(
                              value: isActive,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (bool value) {
                                storeController.updateItemStatusForProduct(
                                  item.id,
                                  value,
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, bool isActive) {
    final Color color = isActive
        ? Colors.green
        : Theme.of(context).disabledColor;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Flexible(
              child: Text(
                isActive ? 'active'.tr : 'inactive'.tr,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(
          color: Theme.of(context).disabledColor.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Shimmer(
              child: Container(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                width: double.maxFinite,
                height: double.maxFinite,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeExtraSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(
                  child: Container(
                    height: 15,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusSmall,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Shimmer(
                  child: Container(
                    height: 18,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusSmall,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Shimmer(
                  child: Container(
                    height: 36,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusLarge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Row(
                  children: [
                    Expanded(
                      child: Shimmer(
                        child: Container(
                          height: 24,
                          width: 74,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).shadowColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Shimmer(
                      child: Container(
                        height: 22,
                        width: 38,
                        decoration: BoxDecoration(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusLarge,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setUpdatedPrice(Item item, double price) {
    if (item.id == null) {
      return;
    }

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
    if (itemId == null) {
      return;
    }

    setState(() {
      _updatedPrices.remove(itemId);
      _editedItems.remove(itemId);
    });
  }

  void _showEditPriceDialog(
    BuildContext context,
    Item item,
    double currentPrice,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentPrice > 0
          ? (currentPrice % 1 == 0
                ? currentPrice.toInt().toString()
                : currentPrice.toString())
          : '',
    );

    Get.dialog(
      AlertDialog(
        title: Text('edit_price'.tr, style: robotoMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name ?? '',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'price'.tr,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              final String val = controller.text.trim();
              final double? newPrice = double.tryParse(val);
              if (newPrice != null && newPrice >= 0) {
                _setUpdatedPrice(item, newPrice);
                Get.back();
              } else {
                showCustomSnackBar('enter_price'.tr);
              }
            },
            child: Text('update'.tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Widget _counterButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        height: 28,
        width: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Future<void> _saveAllChanges(StoreController storeController) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final List<Map<String, String>> updates = [];
      for (final entry in _updatedPrices.entries) {
        final int itemId = entry.key;
        final double newPrice = entry.value;

        final Item? item = storeController.itemList?.firstWhereOrNull(
          (element) => element.id == itemId,
        );
        if (item != null) {
          updates.add(
            storeController.buildStockUpdateData(item, price: newPrice),
          );
        }
      }

      if (updates.isNotEmpty) {
        await storeController.bulkItemsUpdate(updates);
        if (!mounted) {
          return;
        }
        setState(() {
          _updatedPrices.clear();
          _editedItems.clear();
        });
      }
    } catch (e) {
      debugPrint('Error saving prices: $e');
      showCustomSnackBar('failed_to_update_price'.tr);
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
    }
  }
}
