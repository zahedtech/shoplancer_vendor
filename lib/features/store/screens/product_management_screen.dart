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
import 'package:shoplancer_vendor/features/store/screens/item_details_screen.dart';
import 'package:shoplancer_vendor/features/store/screens/quick_add_item_screen.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
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

  // Price Filter variables
  String _priceSortType = 'none'; // 'none', 'low_to_high', 'high_to_low'
  double? _minPriceFilter;
  double? _maxPriceFilter;

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
            minPrice: _minPriceFilter?.toString(),
            maxPrice: _maxPriceFilter?.toString(),
            sort: _priceSortType,
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

  List<Item> _getProcessedItems(List<Item> originalItems) {
    List<Item> list = List.from(originalItems);

    if (_minPriceFilter != null) {
      list = list.where((item) {
        final double price = _updatedPrices[item.id] ?? item.price ?? 0;
        return price >= _minPriceFilter!;
      }).toList();
    }

    if (_maxPriceFilter != null) {
      list = list.where((item) {
        final double price = _updatedPrices[item.id] ?? item.price ?? 0;
        return price <= _maxPriceFilter!;
      }).toList();
    }

    if (_priceSortType == 'low_to_high') {
      list.sort((a, b) {
        final double priceA = _updatedPrices[a.id] ?? a.price ?? 0;
        final double priceB = _updatedPrices[b.id] ?? b.price ?? 0;
        return priceA.compareTo(priceB);
      });
    } else if (_priceSortType == 'high_to_low') {
      list.sort((a, b) {
        final double priceA = _updatedPrices[a.id] ?? a.price ?? 0;
        final double priceB = _updatedPrices[b.id] ?? b.price ?? 0;
        return priceB.compareTo(priceA);
      });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        return Scaffold(
          appBar: const CustomAppBarWidget(title: 'إدارة المنتجات'),
          floatingActionButton: FloatingActionButton(
            heroTag: 'product_mgmt_add_item_fab',
            onPressed: () => Get.to(() => const QuickAddItemScreen()),
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          body: storeController.categoryNameList != null
              ? Column(
                  children: [
                    // Main Categories Horizontal Bar
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

                    // Search, Barcode & Price Filter Bar
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
                            _priceFilterButton(context),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            _scanButton(context, storeController),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    // Product Grid View
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          _searchController.clear();
                          _barcodeSearch = null;
                          setState(() {
                            _updatedPrices.clear();
                            _editedItems.clear();
                            _priceSortType = 'none';
                            _minPriceFilter = null;
                            _maxPriceFilter = null;
                          });
                          storeController.resetFilters();
                        },
                        child: storeController.itemList != null
                            ? () {
                                final processedList = _getProcessedItems(
                                  storeController.itemList!,
                                );
                                return processedList.isNotEmpty
                                    ? GridView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.paddingSizeDefault,
                                        ),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              childAspectRatio: 0.60,
                                              crossAxisSpacing:
                                                  Dimensions.paddingSizeDefault,
                                              mainAxisSpacing:
                                                  Dimensions.paddingSizeDefault,
                                            ),
                                        itemCount: processedList.length,
                                        itemBuilder: (context, index) {
                                          final Item item =
                                              processedList[index];
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
                                              width: 130,
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
                                      );
                              }()
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.60,
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
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
          bottomNavigationBar: _updatedPrices.isNotEmpty
              ? SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(
                      Dimensions.paddingSizeDefault,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تم تعديل ${_updatedPrices.length} منتج',
                                style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: _updatedPrices.entries.map((entry) {
                                    final Item? editedItem =
                                        _editedItems[entry.key] ??
                                        storeController.itemList
                                            ?.firstWhereOrNull(
                                              (e) => e.id == entry.key,
                                            );
                                    if (editedItem == null) {
                                      return const SizedBox.shrink();
                                    }
                                    final double newPrice = entry.value;
                                    return Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.radiusSmall,
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
                                              image:
                                                  '${editedItem.imageFullUrl}',
                                              height: 32,
                                              width: 32,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 80,
                                                child: Text(
                                                  editedItem.name ?? '',
                                                  style: robotoMedium.copyWith(
                                                    fontSize: 10,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                '${PriceConverterHelper.convertPrice(editedItem.price)} → ${PriceConverterHelper.convertPrice(newPrice)}',
                                                style: robotoBold.copyWith(
                                                  fontSize: 10,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            constraints: const BoxConstraints(
                                              maxWidth: 26,
                                              maxHeight: 26,
                                            ),
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                              Icons.close,
                                              size: 14,
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
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeDefault),
                        _isSaving
                            ? const SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : SizedBox(
                                width: 140,
                                child: CustomButtonWidget(
                                  buttonText: 'save_changes'.tr,
                                  onPressed: () =>
                                      _saveAllChanges(storeController),
                                ),
                              ),
                      ],
                    ),
                  ),
                )
              : null,
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
          color: Theme.of(context).primaryColor.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
        child: Icon(
          Icons.barcode_reader,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _priceFilterButton(BuildContext context) {
    final bool hasActiveFilter =
        _priceSortType != 'none' ||
        _minPriceFilter != null ||
        _maxPriceFilter != null;

    return InkWell(
      onTap: () => _showPriceFilterBottomSheet(context),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        height: 50,
        width: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasActiveFilter
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
        child: Icon(
          Icons.filter_list_rounded,
          color: hasActiveFilter
              ? Colors.white
              : Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showPriceFilterBottomSheet(BuildContext context) {
    final StoreController storeController = Get.find<StoreController>();
    String selectedSort = _priceSortType;
    final TextEditingController minController = TextEditingController(
      text: _minPriceFilter != null ? _minPriceFilter.toString() : '',
    );
    final TextEditingController maxController = TextEditingController(
      text: _maxPriceFilter != null ? _maxPriceFilter.toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Dimensions.radiusExtraLarge),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).disabledColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تصفية وترتيب حسب السعر',
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _priceSortType = 'none';
                            _minPriceFilter = null;
                            _maxPriceFilter = null;
                          });
                          storeController.setOffset(1);
                          storeController.getItemList(
                            offset: '1',
                            type: 'all',
                            search: _searchController.text.trim(),
                            categoryId: storeController.categoryId,
                            barcode: _barcodeSearch,
                          );
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'إعادة ضبط',
                          style: robotoRegular.copyWith(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text('ترتيب الأسعار:', style: robotoMedium),
                  RadioListTile<String>(
                    title: const Text('بدون ترتيب (الافتراضي)'),
                    value: 'none',
                    groupValue: selectedSort,
                    onChanged: (val) =>
                        setModalState(() => selectedSort = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('من الأقل إلى الأعلى سعرًا'),
                    value: 'low_to_high',
                    groupValue: selectedSort,
                    onChanged: (val) =>
                        setModalState(() => selectedSort = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('من الأعلى إلى الأقل سعرًا'),
                    value: 'high_to_low',
                    groupValue: selectedSort,
                    onChanged: (val) =>
                        setModalState(() => selectedSort = val!),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text('نطاق السعر:', style: robotoMedium),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'الحد الأدنى',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'الحد الأقصى',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  CustomButtonWidget(
                    buttonText: 'تطبيق الفلتر',
                    onPressed: () {
                      final double? minP = double.tryParse(
                        minController.text.trim(),
                      );
                      final double? maxP = double.tryParse(
                        maxController.text.trim(),
                      );
                      setState(() {
                        _priceSortType = selectedSort;
                        _minPriceFilter = minP;
                        _maxPriceFilter = maxP;
                      });
                      storeController.setOffset(1);
                      storeController.getItemList(
                        offset: '1',
                        type: 'all',
                        search: _searchController.text.trim(),
                        categoryId: storeController.categoryId,
                        barcode: _barcodeSearch,
                        minPrice: minP?.toString(),
                        maxPrice: maxP?.toString(),
                        sort: selectedSort,
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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
    final bool isStaged = _updatedPrices.containsKey(item.id);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(
          color: isStaged
              ? Colors.green
              : Theme.of(context).disabledColor.withOpacity(0.12),
          width: isStaged ? 2 : 1,
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
          // Image Stack with Discount Tag & Edit Item Details Button
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

                // Edit Product Details Button on Top-Right Corner
                Positioned(
                  top: 8,
                  left: 8,
                  child: InkWell(
                    onTap: () {
                      Get.toNamed(
                        RouteHelper.getItemDetailsRoute(item),
                        arguments: ItemDetailsScreen(product: item),
                      );
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card Content Body
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name ?? '',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                // Price Text Clickable for Built-in Numpad Keypad
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

                // Quick Increment/Decrement Buttons & Direct Price Numpad Trigger
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
                          onTap: () => _showBuiltInNumpadBottomSheet(
                            context,
                            item,
                            currentPrice,
                          ),
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

                // Card Footer: Status Badge, Switch & Edit Product Details Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statusBadge(context, isActive),
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

  void _showBuiltInNumpadBottomSheet(
    BuildContext context,
    Item item,
    double currentPrice,
  ) {
    String input = currentPrice > 0
        ? (currentPrice % 1 == 0
              ? currentPrice.toInt().toString()
              : currentPrice.toString())
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void onKeyTap(String val) {
              setModalState(() {
                if (val == '.') {
                  if (!input.contains('.')) {
                    input = input.isEmpty ? '0.' : input + '.';
                  }
                } else {
                  if (input == '0') {
                    input = val;
                  } else {
                    input += val;
                  }
                }
              });
            }

            void onBackspace() {
              setModalState(() {
                if (input.isNotEmpty) {
                  input = input.substring(0, input.length - 1);
                }
              });
            }

            void onClear() {
              setModalState(() {
                input = '';
              });
            }

            return Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Dimensions.radiusExtraLarge),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(
                    'تعديل سعر المنتج (الكيبورد المدمج)',
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name ?? '',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // Typed Price Display Box
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault,
                      ),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      input.isEmpty ? '0' : input,
                      style: robotoBold.copyWith(
                        fontSize: 26,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // 3x4 Numpad Keypad Grid
                  Column(
                    children: [
                      Row(
                        children: [
                          _numpadKey('1', onKeyTap, context),
                          _numpadKey('2', onKeyTap, context),
                          _numpadKey('3', onKeyTap, context),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _numpadKey('4', onKeyTap, context),
                          _numpadKey('5', onKeyTap, context),
                          _numpadKey('6', onKeyTap, context),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _numpadKey('7', onKeyTap, context),
                          _numpadKey('8', onKeyTap, context),
                          _numpadKey('9', onKeyTap, context),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _numpadKey('.', onKeyTap, context),
                          _numpadKey('0', onKeyTap, context),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: InkWell(
                                onTap: onBackspace,
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault,
                                ),
                                child: Container(
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.backspace_outlined,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onClear,
                          child: const Text('تفريغ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CustomButtonWidget(
                          buttonText: 'حفظ السعر',
                          onPressed: () {
                            final double? newPrice = double.tryParse(
                              input.trim(),
                            );
                            if (newPrice != null && newPrice >= 0) {
                              _setUpdatedPrice(item, newPrice);
                              Navigator.of(context).pop();
                            } else {
                              showCustomSnackBar('أدخل سعر صحيح');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _numpadKey(String text, Function(String) onTap, BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => onTap(text),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.15),
              ),
            ),
            child: Text(
              text,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeExtraLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ),
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
      final List<Map<String, dynamic>> updates = [];
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
