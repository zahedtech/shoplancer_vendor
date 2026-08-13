import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/pos_style_barcode_scanner_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/common/widgets/paginated_list_widget.dart';
import 'package:shoplancer_vendor/features/category/controllers/category_controller.dart';
import 'package:shoplancer_vendor/features/category/domain/models/category_model.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/features/store/screens/item_details_screen.dart';
import 'package:shoplancer_vendor/features/store/screens/quick_add_item_screen.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ProductManagementScreen extends StatefulWidget {
  final bool isBackButtonExist;
  const ProductManagementScreen({super.key, this.isBackButtonExist = true});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speechToText = SpeechToText();
  final Map<int, double> _updatedPrices = {};
  final Map<int, Item> _editedItems = {};

  String? _barcodeSearch;
  CategoryModel? _selectedCategory;
  CategoryModel? _selectedSubCategory;
  bool _isViewingProducts = false;

  bool _showScanner = false;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isSaving = false;

  int get _activeCategoryId {
    if (_selectedSubCategory != null) {
      return _selectedSubCategory!.id!;
    }
    if (_selectedCategory != null) {
      return _selectedCategory!.id!;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    final categoryController = Get.find<CategoryController>();
    final storeController = Get.find<StoreController>();

    _selectedCategory = null;
    _selectedSubCategory = null;
    _isViewingProducts = false;

    storeController.resetFilters(reload: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      categoryController.getCategoryList();
    });
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        final bool listening = status == 'listening';
        if (_isListening != listening) {
          setState(() => _isListening = listening);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        showCustomSnackBar('تعذر تشغيل البحث الصوتي'.tr);
      },
    );

    if (!mounted) return;
    setState(() => _speechEnabled = available);
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
    }

    if (!_speechEnabled) {
      showCustomSnackBar('يرجى السماح باستخدام الميكروفون للبحث الصوتي'.tr);
      return;
    }

    setState(() => _isListening = true);
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        localeId: Get.locale?.languageCode == 'ar' ? 'ar' : 'en_US',
        listenMode: ListenMode.search,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final String recognizedWords = result.recognizedWords.trim();
    if (recognizedWords.isEmpty) return;

    _searchController.text = recognizedWords;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );

    if (result.finalResult) {
      setState(() => _isListening = false);
      _submitSearch(recognizedWords);
    } else {
      setState(() {});
    }
  }

  void _onSearchChanged(String query) {
    final String clean = query.trim();

    if (_isBarcodeQuery(clean)) {
      _searchByBarcode(clean);
      return;
    }

    if (_barcodeSearch != null) {
      _barcodeSearch = null;
      setState(() {});
    }

    if (clean.isNotEmpty) {
      _searchByName(clean);
    }
  }

  void _submitSearch([String? query]) {
    final String clean = (query ?? _searchController.text).trim();

    if (_isNumericQuery(clean)) {
      _searchByBarcode(clean);
      return;
    }

    _searchByName(clean);
  }

  bool _isNumericQuery(String query) => RegExp(r'^[0-9]+$').hasMatch(query);

  bool _isBarcodeQuery(String query) =>
      query.length >= 4 && _isNumericQuery(query);

  void _searchByName(String name) {
    _barcodeSearch = null;
    if (!_isViewingProducts) {
      _isViewingProducts = true;
    }
    setState(() {});
    Get.find<StoreController>().getItemList(
      offset: '1',
      type: 'all',
      search: name,
      categoryId: _activeCategoryId,
    );
  }

  Future<void> _searchByBarcode(String barcode) async {
    final String cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return;

    _barcodeSearch = cleanBarcode;
    _searchController.text = cleanBarcode;
    if (!_isViewingProducts) {
      _isViewingProducts = true;
    }
    setState(() {});

    await Get.find<StoreController>().getItemList(
      offset: '1',
      type: 'all',
      search: '',
      barcode: cleanBarcode,
      categoryId: _activeCategoryId,
    );
  }

  void _fetchPage(int? offset) {
    Get.find<StoreController>().getItemList(
      offset: offset?.toString() ?? '1',
      type: 'all',
      search: _barcodeSearch == null ? _searchController.text.trim() : '',
      barcode: _barcodeSearch,
      categoryId: _activeCategoryId,
    );
  }

  Future<void> _onBarcodeScanned(String barcode) async {
    final String cleanBarcode = barcode.trim();
    setState(() {
      _showScanner = false;
    });

    await _searchByBarcode(cleanBarcode);
  }

  void _setUpdatedPrice(Item item, double newPrice) {
    if (newPrice < 0) return;
    setState(() {
      _updatedPrices[item.id!] = newPrice;
      _editedItems[item.id!] = item;
    });
  }

  Future<void> _saveAllChanges(StoreController storeController) async {
    if (_updatedPrices.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    int successCount = 0;
    int failCount = 0;

    for (final entry in _updatedPrices.entries) {
      final int itemId = entry.key;
      final double newPrice = entry.value;
      final Item? originalItem = _editedItems[itemId];

      if (originalItem == null) continue;

      final bool success = await storeController.updateItemPriceOnly(
        itemId,
        newPrice,
        item: originalItem,
      );

      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    setState(() {
      _isSaving = false;
    });

    if (successCount > 0) {
      showCustomSnackBar(
        'تم تحديث أسعار $successCount منتج بنجاح'.tr,
        isError: false,
      );
      setState(() {
        _updatedPrices.clear();
        _editedItems.clear();
      });
      _fetchPage(storeController.offset);
    }

    if (failCount > 0) {
      showCustomSnackBar('فشل تحديث أسعار $failCount منتج'.tr);
    }
  }

  void _onSelectAllProducts() {
    setState(() {
      _selectedCategory = null;
      _selectedSubCategory = null;
      _isViewingProducts = true;
    });
    final storeController = Get.find<StoreController>();
    storeController.getItemList(
      offset: '1',
      type: 'all',
      search: _searchController.text.trim(),
      categoryId: 0,
      barcode: _barcodeSearch,
    );
  }

  void _onSelectCategory(CategoryModel category) {
    setState(() {
      _selectedCategory = category;
      _selectedSubCategory = null;
      _isViewingProducts = false;
    });
    final categoryController = Get.find<CategoryController>();
    categoryController.getSubCategoryList(category.id!);
  }

  void _onSelectAllInCategory() {
    setState(() {
      _selectedSubCategory = null;
      _isViewingProducts = true;
    });
    final storeController = Get.find<StoreController>();
    storeController.getItemList(
      offset: '1',
      type: 'all',
      search: _searchController.text.trim(),
      categoryId: _selectedCategory?.id ?? 0,
      barcode: _barcodeSearch,
    );
  }

  void _onSelectSubCategory(CategoryModel subCategory) {
    setState(() {
      _selectedSubCategory = subCategory;
      _isViewingProducts = true;
    });
    final storeController = Get.find<StoreController>();
    storeController.getItemList(
      offset: '1',
      type: 'all',
      search: _searchController.text.trim(),
      categoryId: subCategory.id ?? 0,
      barcode: _barcodeSearch,
    );
  }

  Widget _buildBreadcrumbHeader() {
    if (_isViewingProducts) {
      String title = 'all_items'.tr;
      if (_selectedSubCategory != null) {
        title =
            '${_selectedCategory?.name ?? ''} > ${_selectedSubCategory?.name ?? ''}';
      } else if (_selectedCategory != null) {
        title = _selectedCategory?.name ?? '';
      }

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        color: Theme.of(context).primaryColor.withOpacity(0.06),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isViewingProducts = false;
                });
              },
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedCategory != null ? 'الفئات الفرعية'.tr : 'تغيير الفئة'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else if (_selectedCategory != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        color: Theme.of(context).primaryColor.withOpacity(0.06),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedSubCategory = null;
                });
              },
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'كل الفئات'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'فئة: ${_selectedCategory?.name ?? ''}',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAllProductsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        onTap: _onSelectAllProducts,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Row(
            children: [
              Container(
                height: 55,
                width: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'all_items'.tr,
                      style: robotoBold.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'عرض كل المنتجات بدون تصفية بفئة معيّنة',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    final bool isActive = (category.status ?? 1) == 1;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).disabledColor.withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Get.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        onTap: () => _onSelectCategory(category),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImageWidget(
                image: '${category.imageFullUrl}',
                height: 55,
                width: 55,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name ?? '',
                    style: robotoBold.copyWith(
                      color: isActive
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).disabledColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusSmall,
                      ),
                    ),
                    child: Text(
                      '${category.productsCount ?? 0} ${'items'.tr}',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Theme.of(context).disabledColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllInCategoryCard(
    BuildContext context,
    CategoryModel category,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        onTap: _onSelectAllInCategory,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Row(
            children: [
              Container(
                height: 50,
                width: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Icon(
                  Icons.layers_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كل منتجات ${category.name ?? ''}',
                      style: robotoBold.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'عرض جميع المنتجات التابعة لهذه الفئة',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryCard(
    BuildContext context,
    CategoryModel subCategory,
  ) {
    final bool isActive = (subCategory.status ?? 1) == 1;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).disabledColor.withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Get.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        onTap: () => _onSelectSubCategory(subCategory),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Icon(
                Icons.subdirectory_arrow_right_rounded,
                color: Theme.of(context).primaryColor,
                size: 26,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subCategory.name ?? '',
                    style: robotoBold.copyWith(
                      color: isActive
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).disabledColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusSmall,
                      ),
                    ),
                    child: Text(
                      '${subCategory.productsCount ?? 0} ${'items'.tr}',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Theme.of(context).disabledColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(CategoryController categoryController) {
    final List<CategoryModel>? categories = categoryController.categoryList;

    if (categories == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Get.find<CategoryController>().getCategoryList();
      },
      child: ListView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        children: [
          _buildAllProductsCard(context),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeLarge,
              ),
              child: Center(
                child: Text('no_category_found'.tr, style: robotoMedium),
              ),
            )
          else
            ...categories.map(
              (category) => _buildCategoryCard(context, category),
            ),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesList(CategoryController categoryController) {
    final List<CategoryModel>? subCategories =
        categoryController.subCategoryList;

    if (subCategories == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedCategory?.id != null) {
          await Get.find<CategoryController>()
              .getSubCategoryList(_selectedCategory!.id!);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        children: [
          if (_selectedCategory != null)
            _buildAllInCategoryCard(context, _selectedCategory!),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          if (subCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeLarge,
              ),
              child: Column(
                children: [
                  Text(
                    'لا توجد فئات فرعية مضافة لهذه الفئة'.tr,
                    style: robotoMedium.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  CustomButtonWidget(
                    buttonText: 'عرض منتجات الفئة مباشرة'.tr,
                    width: 200,
                    onPressed: _onSelectAllInCategory,
                  ),
                ],
              ),
            )
          else
            ...subCategories.map(
              (subCategory) =>
                  _buildSubCategoryCard(context, subCategory),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isViewingProducts && _selectedCategory == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isViewingProducts) {
          setState(() {
            _isViewingProducts = false;
          });
        } else if (_selectedCategory != null) {
          setState(() {
            _selectedCategory = null;
            _selectedSubCategory = null;
          });
        }
      },
      child: GetBuilder<CategoryController>(
        builder: (categoryController) {
          return GetBuilder<StoreController>(
            builder: (storeController) {
              return Scaffold(
                appBar: CustomAppBarWidget(
                  title: 'إدارة المنتجات',
                  isBackButtonExist: widget.isBackButtonExist,
                  onTap: () {
                    if (_isViewingProducts) {
                      setState(() {
                        _isViewingProducts = false;
                      });
                    } else if (_selectedCategory != null) {
                      setState(() {
                        _selectedCategory = null;
                        _selectedSubCategory = null;
                      });
                    } else {
                      Get.back();
                    }
                  },
                  menuWidget: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.white,
                      size: 26,
                    ),
                    tooltip: 'إضافة منتج'.tr,
                    onPressed: () =>
                        Get.to(() => const QuickAddItemScreen()),
                  ),
                ),
                floatingActionButton: _updatedPrices.isNotEmpty
                    ? null
                    : FloatingActionButton(
                        heroTag: 'product_mgmt_add_item_fab',
                        onPressed: () =>
                            Get.to(() => const QuickAddItemScreen()),
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                body: Column(
                  children: [
                    // Search & Scanner Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeSmall,
                        Dimensions.paddingSizeSmall,
                        Dimensions.paddingSizeSmall,
                        Dimensions.paddingSizeExtraSmall,
                      ),
                      color: Theme.of(context).cardColor,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextFieldWidget(
                                  controller: _searchController,
                                  hintText: _isViewingProducts
                                      ? 'ابحث في المنتجات بالاسم أو الباركود...'.tr
                                      : 'ابحث عن أي منتج مباشرة...'.tr,
                                  prefixIcon: Icons.search,
                                  inputAction: TextInputAction.search,
                                  suffixChild: _searchController
                                          .text.isNotEmpty
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: _isListening
                                                  ? 'إيقاف البحث الصوتي'.tr
                                                  : 'البحث بالصوت'.tr,
                                              icon: Icon(
                                                _isListening
                                                    ? Icons.mic
                                                    : Icons.mic_none,
                                                size: 20,
                                                color: _isListening
                                                    ? Colors.red
                                                    : Theme.of(context)
                                                        .primaryColor,
                                              ),
                                              onPressed: _toggleVoiceSearch,
                                            ),
                                            IconButton(
                                              tooltip: 'search'.tr,
                                              icon: Icon(
                                                Icons.search,
                                                size: 20,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                              onPressed: _submitSearch,
                                            ),
                                            IconButton(
                                              tooltip: 'clear'.tr,
                                              icon: const Icon(
                                                Icons.clear,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                _barcodeSearch = null;
                                                storeController.getItemList(
                                                  offset: '1',
                                                  type: 'all',
                                                  search: '',
                                                  categoryId:
                                                      _activeCategoryId,
                                                );
                                              },
                                            ),
                                          ],
                                        )
                                      : IconButton(
                                          tooltip: _isListening
                                              ? 'إيقاف البحث الصوتي'.tr
                                              : 'البحث بالصوت'.tr,
                                          icon: Icon(
                                            _isListening
                                                ? Icons.mic
                                                : Icons.mic_none,
                                            size: 20,
                                            color: _isListening
                                                ? Colors.red
                                                : Theme.of(context)
                                                    .primaryColor,
                                          ),
                                          onPressed: _toggleVoiceSearch,
                                        ),
                                  onChanged: (val) =>
                                      _onSearchChanged(val),
                                  onSubmit: (val) => _submitSearch(val),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _showScanner = !_showScanner;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _showScanner
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusDefault,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.barcode_reader,
                                    color: _showScanner
                                        ? Colors.white
                                        : Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_showScanner) ...[
                            const SizedBox(
                              height: Dimensions.paddingSizeSmall,
                            ),
                            PosStyleBarcodeScannerWidget(
                              onBarcodeScanned: (barcode) {
                                _onBarcodeScanned(barcode);
                              },
                              onClose: () => setState(
                                () => _showScanner = false,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Breadcrumb navigation header
                    _buildBreadcrumbHeader(),

                    const Divider(height: 1),

                    // Main Content Area
                    Expanded(
                      child: _isViewingProducts
                          ? (storeController.itemList == null
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _buildProductsList(
                                  context,
                                  storeController,
                                ))
                          : (_selectedCategory != null
                              ? _buildSubCategoriesList(categoryController)
                              : _buildCategoriesList(categoryController)),
                    ),

                    // Bottom Save Staged Prices Floating Bar
                    if (_updatedPrices.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeDefault,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'تم تعديل أسعار ${_updatedPrices.length} منتج',
                                style: robotoBold.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            CustomButtonWidget(
                              buttonText: 'حفظ التعديلات'.tr,
                              width: 140,
                              height: 44,
                              isLoading: _isSaving,
                              onPressed: () =>
                                  _saveAllChanges(storeController),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    StoreController storeController,
  ) {
    // Only active items (status == 1)
    final activeItems = (storeController.itemList ?? [])
        .where((item) => item.status == 1)
        .toList();

    if (activeItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: Theme.of(context).disabledColor.withOpacity(0.5),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'لا توجد منتجات نشطة مطابقة لعملية البحث'.tr,
              style: robotoMedium.copyWith(
                color: Theme.of(context).disabledColor,
                fontSize: Dimensions.fontSizeDefault,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: PaginatedListWidget(
        scrollController: _scrollController,
        totalSize: storeController.itemSize,
        offset: storeController.offset,
        onPaginate: (int? offset) async {
          _fetchPage(offset);
        },
        productView: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeSmall,
            90,
          ),
          itemCount: activeItems.length,
          separatorBuilder: (context, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final Item item = activeItems[index];
            return _buildProductListCard(context, item, storeController);
          },
        ),
      ),
    );
  }

  Widget _buildProductListCard(
    BuildContext context,
    Item item,
    StoreController storeController,
  ) {
    final bool isLoading = storeController.loadingItemsList.contains(item.id);
    final double currentPrice = _updatedPrices[item.id] ?? item.price ?? 0;
    final double originalPrice = item.price ?? 0;
    final bool isStaged = _updatedPrices.containsKey(item.id);

    return Dismissible(
      key: Key('product_mgmt_item_${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) async {
        _confirmDelete(context, item);
        return false;
      },
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'اسحب للحذف من المتجر'.tr,
              style: robotoBold.copyWith(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_forever, color: Colors.white, size: 26),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isStaged
                ? Colors.green
                : Theme.of(context).disabledColor.withOpacity(0.12),
            width: isStaged ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Product Image with Discount Tag
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: Stack(
                children: [
                  CustomImageWidget(
                    image: item.imageFullUrl ?? '',
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                  ),
                  if ((item.discount ?? 0) > 0)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Text(
                          '${item.discount}%',
                          style: robotoBold.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? '',
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _showBuiltInNumpadBottomSheet(
                      context,
                      item,
                      currentPrice,
                    ),
                    child: Row(
                      children: [
                        Text(
                          PriceConverterHelper.convertPrice(currentPrice),
                          style: robotoBold.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                        if (currentPrice != originalPrice) ...[
                          const SizedBox(width: 6),
                          Text(
                            PriceConverterHelper.convertPrice(originalPrice),
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Theme.of(context).disabledColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_note_rounded,
                          size: 14,
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'المخزون: ${item.stock ?? 0}',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions: Quick Price Stepper (+ / -), Edit, Delete & Switch
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quick + / - Price Stepper
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    border: Border.all(
                      color: Theme.of(context).disabledColor.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _setUpdatedPrice(
                          item,
                          (currentPrice - 1) > 0 ? (currentPrice - 1) : 0,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 14,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showBuiltInNumpadBottomSheet(
                          context,
                          item,
                          currentPrice,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Text(
                            currentPrice % 1 == 0
                                ? currentPrice.toInt().toString()
                                : currentPrice.toStringAsFixed(1),
                            style: robotoBold.copyWith(fontSize: 12),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _setUpdatedPrice(item, currentPrice + 1),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Icon(Icons.add, size: 14, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Edit, Delete & Status Switch
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 18,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () {
                        Get.toNamed(
                          RouteHelper.getItemDetailsRoute(item),
                          arguments: ItemDetailsScreen(product: item),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () => _confirmDelete(context, item),
                    ),
                    const SizedBox(width: 4),
                    isLoading
                        ? const SizedBox(
                            width: 32,
                            height: 20,
                            child: Center(child: CupertinoActivityIndicator()),
                          )
                        : Transform.scale(
                            scale: 0.72,
                            child: CupertinoSwitch(
                              value: item.status == 1,
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
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        title: Text('حذف المنتج'.tr, style: robotoBold),
        content: Text(
          'هل أنت متأكد من حذف المنتج "${item.name}" نهائياً من المتجر؟'.tr,
          style: robotoRegular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'cancel'.tr,
              style: robotoRegular.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Get.find<StoreController>().deleteItemDirectly(item.id);
            },
            child: Text('delete'.tr, style: robotoBold),
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
      builder: (ctx) {
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
                    'تعديل سعر المنتج'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name ?? '',
                    style: robotoMedium.copyWith(
                      color: Theme.of(context).disabledColor,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // Display Price
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault,
                      ),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'السعر الجديد:'.tr,
                          style: robotoMedium.copyWith(fontSize: 14),
                        ),
                        Text(
                          input.isEmpty ? '0.00 ج.م' : '$input ج.م',
                          style: robotoBold.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // Numpad Keys
                  Column(
                    children: [
                      _buildNumpadRow(['1', '2', '3'], onKeyTap, context),
                      const SizedBox(height: 8),
                      _buildNumpadRow(['4', '5', '6'], onKeyTap, context),
                      const SizedBox(height: 8),
                      _buildNumpadRow(['7', '8', '9'], onKeyTap, context),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _numpadButton(
                              '.',
                              () => onKeyTap('.'),
                              context,
                              isSpecial: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _numpadButton(
                              '0',
                              () => onKeyTap('0'),
                              context,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _numpadButton(
                              '⌫',
                              onBackspace,
                              context,
                              isSpecial: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'إلغاء'.tr,
                            style: robotoMedium.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusDefault,
                              ),
                            ),
                          ),
                          onPressed: () {
                            double? newPrice = double.tryParse(input);
                            if (newPrice != null && newPrice >= 0) {
                              _setUpdatedPrice(item, newPrice);
                            }
                            Navigator.of(ctx).pop();
                          },
                          child: Text(
                            'تطبيق السعر'.tr,
                            style: robotoBold.copyWith(color: Colors.white),
                          ),
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

  Widget _buildNumpadRow(
    List<String> keys,
    Function(String) onTap,
    BuildContext context,
  ) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _numpadButton(key, () => onTap(key), context),
          ),
        );
      }).toList(),
    );
  }

  Widget _numpadButton(
    String label,
    VoidCallback onTap,
    BuildContext context, {
    bool isSpecial = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSpecial
              ? Theme.of(context).disabledColor.withOpacity(0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: Theme.of(context).disabledColor.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: robotoBold.copyWith(
            fontSize: 20,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}
