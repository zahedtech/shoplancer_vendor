import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplancer_vendor/common/widgets/barcode_scanner_screen.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/category/controllers/category_controller.dart';
import 'package:shoplancer_vendor/features/category/domain/models/category_model.dart';
import 'package:shoplancer_vendor/features/chat/widgets/search_field_widget.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class ProductPriceManagementScreen extends StatefulWidget {
  const ProductPriceManagementScreen({super.key});

  @override
  State<ProductPriceManagementScreen> createState() =>
      _ProductPriceManagementScreenState();
}

class _ProductPriceManagementScreenState
    extends State<ProductPriceManagementScreen> {
  static const String _draftKey = 'express_price_editor_draft';

  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _subCategoryScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final Map<int, double> _stagedPrices = {};
  final Map<int, Item> _stagedItems = {};
  final Map<int, TextEditingController> _priceInputControllers = {};

  int _currentIndex = 0;
  bool _showNumpad = true;
  String? _barcodeSearch;
  int? _selectedSubCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final storeController = Get.find<StoreController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocalDraft();
      storeController.getStoreCategories();
      storeController.getItemList(
        offset: '1',
        type: 'all',
        search: '',
        categoryId: 0,
        willUpdate: true,
      );
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          storeController.itemList != null &&
          !storeController.isLoading) {
        final int totalItems = storeController.itemSize ?? 0;
        if (totalItems == 0) return;

        final int pageSize = (totalItems / 10).ceil();
        if (storeController.offset < pageSize) {
          storeController.setOffset(storeController.offset + 1);
          storeController.showBottomLoader();
          storeController.getItemList(
            offset: storeController.offset.toString(),
            type: storeController.type,
            search: _searchController.text.trim(),
            categoryId: _selectedSubCategoryId ?? storeController.categoryId,
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
    _subCategoryScrollController.dispose();
    _searchController.dispose();
    for (var controller in _priceInputControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveLocalDraft() {
    try {
      final prefs = Get.find<SharedPreferences>();
      if (_stagedPrices.isEmpty) {
        prefs.remove(_draftKey);
        return;
      }
      final Map<String, dynamic> data = {
        'prices': _stagedPrices.map(
          (key, val) => MapEntry(key.toString(), val),
        ),
        'items': _stagedItems.map(
          (key, item) => MapEntry(key.toString(), item.toJson()),
        ),
      };
      prefs.setString(_draftKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving local draft: $e');
    }
  }

  void _loadLocalDraft() {
    try {
      final prefs = Get.find<SharedPreferences>();
      final String? rawJson = prefs.getString(_draftKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(rawJson);
        if (decoded.containsKey('prices') && decoded.containsKey('items')) {
          final Map<String, dynamic> rawPrices = decoded['prices'];
          final Map<String, dynamic> rawItems = decoded['items'];

          setState(() {
            _stagedPrices.clear();
            _stagedItems.clear();

            rawPrices.forEach((key, val) {
              final int? id = int.tryParse(key);
              final double? price = double.tryParse(val.toString());
              if (id != null && price != null) {
                _stagedPrices[id] = price;
              }
            });

            rawItems.forEach((key, itemJson) {
              final int? id = int.tryParse(key);
              if (id != null && itemJson is Map<String, dynamic>) {
                _stagedItems[id] = Item.fromJson(itemJson);
              }
            });
          });

          if (_stagedPrices.isNotEmpty) {
            showCustomSnackBar(
              'تم استعادة ${_stagedPrices.length} منتج مُعدّل من مسودة التعديل المحفوظة',
              isError: false,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading local draft: $e');
    }
  }

  void _clearLocalDraft() {
    try {
      final prefs = Get.find<SharedPreferences>();
      prefs.remove(_draftKey);
    } catch (e) {
      debugPrint('Error clearing local draft: $e');
    }
  }

  TextEditingController _getControllerForItem(Item item) {
    if (!_priceInputControllers.containsKey(item.id)) {
      final double price = _stagedPrices[item.id] ?? (item.price ?? 0);
      final String initialText = price % 1 == 0
          ? price.toInt().toString()
          : price.toString();
      _priceInputControllers[item.id!] = TextEditingController(
        text: initialText,
      );
    }
    return _priceInputControllers[item.id!]!;
  }

  void _onItemPriceChanged(Item item, String value) {
    final double? newPrice = double.tryParse(value.trim());
    if (newPrice != null && newPrice >= 0 && newPrice != item.price) {
      setState(() {
        _stagedPrices[item.id!] = newPrice;
        _stagedItems[item.id!] = item;
      });
      _saveLocalDraft();
    } else if (newPrice == item.price || value.trim().isEmpty) {
      setState(() {
        _stagedPrices.remove(item.id);
        _stagedItems.remove(item.id);
      });
      _saveLocalDraft();
    }
  }

  void _resetItemPrice(Item item) {
    setState(() {
      _stagedPrices.remove(item.id);
      _stagedItems.remove(item.id);
      final double originalPrice = item.price ?? 0;
      final String text = originalPrice % 1 == 0
          ? originalPrice.toInt().toString()
          : originalPrice.toString();
      _getControllerForItem(item).text = text;
    });
    _saveLocalDraft();
  }

  void _onNumpadPress(String val, List<Item> items) {
    if (items.isEmpty || _currentIndex >= items.length) return;
    final Item currentItem = items[_currentIndex];
    final TextEditingController controller = _getControllerForItem(currentItem);

    String text = controller.text;
    if (val == '.') {
      if (!text.contains('.')) {
        text = text.isEmpty ? '0.' : text + '.';
      }
    } else {
      if (text == '0') {
        text = val;
      } else {
        text += val;
      }
    }
    controller.text = text;
    _onItemPriceChanged(currentItem, text);
  }

  void _onBackspace(List<Item> items) {
    if (items.isEmpty || _currentIndex >= items.length) return;
    final Item currentItem = items[_currentIndex];
    final TextEditingController controller = _getControllerForItem(currentItem);

    String text = controller.text;
    if (text.isNotEmpty) {
      text = text.substring(0, text.length - 1);
      controller.text = text;
      _onItemPriceChanged(currentItem, text);
    }
  }

  void _onClearCurrent(List<Item> items) {
    if (items.isEmpty || _currentIndex >= items.length) return;
    final Item currentItem = items[_currentIndex];
    _resetItemPrice(currentItem);
  }

  void _goToIndex(int index, List<Item> items) {
    if (index < 0 || index >= items.length) return;
    setState(() {
      _currentIndex = index;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        (index * 85.0).clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _searchProducts(
    StoreController storeController, {
    String? search,
    String? barcode,
  }) {
    _currentIndex = 0;
    storeController.setOffset(1);
    storeController.getItemList(
      offset: '1',
      type: 'all',
      search: search ?? '',
      categoryId: _selectedSubCategoryId ?? storeController.categoryId,
      barcode: barcode,
    );
  }

  void _clearSearch(StoreController storeController) {
    _currentIndex = 0;
    _searchController.clear();
    _barcodeSearch = null;
    storeController.setOffset(1);
    storeController.getItemList(
      offset: '1',
      type: 'all',
      search: '',
      categoryId: _selectedSubCategoryId ?? storeController.categoryId,
    );
  }

  void _showReviewBottomSheet(StoreController storeController) {
    if (_stagedPrices.isEmpty) {
      showCustomSnackBar('لا يوجد أي تعديلات مراجعة للحفظ');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Dimensions.radiusExtraLarge),
                ),
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(
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
                        'مراجعة الأسعار المٌعدّلة (${_stagedPrices.length})',
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _stagedPrices.clear();
                            _stagedItems.clear();
                            for (var item in _stagedItems.values) {
                              _resetItemPrice(item);
                            }
                          });
                          _clearLocalDraft();
                          Get.back();
                        },
                        child: Text(
                          'تفريغ الكل',
                          style: robotoRegular.copyWith(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _stagedItems.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final Item item = _stagedItems.values.elementAt(index);
                        final double newPrice =
                            _stagedPrices[item.id] ?? (item.price ?? 0);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusSmall,
                            ),
                            child: CustomImageWidget(
                              image: '${item.imageFullUrl}',
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            item.name ?? '',
                            style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                PriceConverterHelper.convertPrice(item.price),
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).disabledColor,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                PriceConverterHelper.convertPrice(newPrice),
                                style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _stagedPrices.remove(item.id);
                                _stagedItems.remove(item.id);
                              });
                              _resetItemPrice(item);
                              _saveLocalDraft();
                              if (_stagedPrices.isEmpty) {
                                Get.back();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  CustomButtonWidget(
                    buttonText: 'تأكيد وحفظ التغييرات',
                    isLoading: _isSaving || storeController.isLoading,
                    onPressed: (_isSaving || storeController.isLoading)
                        ? null
                        : () => _saveAllChanges(storeController, setModalState),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveAllChanges(
    StoreController storeController,
    StateSetter setModalState,
  ) async {
    if (_stagedPrices.isEmpty) return;

    setModalState(() {
      _isSaving = true;
    });
    setState(() {
      _isSaving = true;
    });

    try {
      final List<Map<String, dynamic>> updates = [];
      for (final entry in _stagedPrices.entries) {
        final int itemId = entry.key;
        final double newPrice = entry.value;

        final Item? item =
            _stagedItems[itemId] ??
            storeController.itemList?.firstWhereOrNull(
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
        if (mounted) {
          setState(() {
            _stagedPrices.clear();
            _stagedItems.clear();
          });
          _clearLocalDraft();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving bulk prices: $e');
      showCustomSnackBar('فشل حفظ الأسعار، حاول لاحقاً');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _scanButton(BuildContext context, StoreController storeController) {
    return InkWell(
      onTap: () async {
        final String? barcode = await Get.to(
          () => const BarcodeScannerScreen(),
        );
        if (barcode != null && barcode.isNotEmpty) {
          _barcodeSearch = barcode;
          _searchController.text = barcode;
          _searchProducts(storeController, barcode: barcode);
        }
      },
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: const Icon(Icons.barcode_reader, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildBuiltInNumpad(BuildContext context, List<Item> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    if (_currentIndex >= items.length) {
      _currentIndex = items.length - 1;
    }

    final bool isLast = _currentIndex == items.length - 1;
    final bool isFirst = _currentIndex == 0;
    final Item currentItem = items[_currentIndex];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active Item Header & Navigation Bar
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showNumpad = !_showNumpad;
                  });
                },
                icon: Icon(
                  _showNumpad
                      ? Icons.keyboard_hide_outlined
                      : Icons.keyboard_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: 'إخفاء / إظهار لوحة الأرقام',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المنتج المحدد (${_currentIndex + 1}/${items.length}):',
                      style: robotoRegular.copyWith(
                        fontSize: 11,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    Text(
                      currentItem.name ?? '',
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: !isFirst
                    ? () => _goToIndex(_currentIndex - 1, items)
                    : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('السابق'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: !isLast
                    ? () => _goToIndex(_currentIndex + 1, items)
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('التالي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),

          if (_showNumpad) ...[
            const SizedBox(height: 8),

            // 3x4 Numpad Keypad Grid
            Column(
              children: [
                Row(
                  children: [
                    _numKey('1', items),
                    _numKey('2', items),
                    _numKey('3', items),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _numKey('4', items),
                    _numKey('5', items),
                    _numKey('6', items),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _numKey('7', items),
                    _numKey('8', items),
                    _numKey('9', items),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _numKey('.', items),
                    _numKey('0', items),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () => _onBackspace(items),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                          child: Container(
                            height: 42,
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
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _numKey(String text, List<Item> items) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: () => _onNumpadPress(text, items),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Container(
            height: 42,
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
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        final List<Item>? items = storeController.itemList;

        return Scaffold(
          appBar: CustomAppBarWidget(
            title: 'محرر أسعار المنتجات',
            menuWidget: _stagedPrices.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextButton.icon(
                      onPressed: () => _showReviewBottomSheet(storeController),
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        'مراجعة (${_stagedPrices.length})',
                        style: robotoBold.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          body: Column(
            children: [
              // Search & Barcode Search Bar
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: SearchFieldWidget(
                            fromReview: true,
                            controller: _searchController,
                            hint: '${'search_by_item_name'.tr}...',
                            suffixIcon:
                                storeController.isSearching ||
                                    _searchController.text.isNotEmpty
                                ? CupertinoIcons.clear_thick
                                : CupertinoIcons.search,
                            iconPressed: () {
                              if (storeController.isSearching ||
                                  _searchController.text.isNotEmpty) {
                                _clearSearch(storeController);
                              } else {
                                _searchProducts(
                                  storeController,
                                  search: _searchController.text.trim(),
                                );
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

              // Main Category Selector Bar
              if (storeController.categoryNameList != null)
                Container(
                  height: 44,
                  color: Theme.of(context).cardColor,
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
                          _currentIndex = 0;
                          _selectedSubCategoryId = null;
                          _searchController.clear();
                          _barcodeSearch = null;
                          storeController.setCategory(
                            index: index,
                            foodType: 'all',
                          );
                          final int selectedCatId =
                              (storeController.categoryIdList != null &&
                                  index <
                                      storeController.categoryIdList!.length)
                              ? storeController.categoryIdList![index]
                              : 0;
                          if (selectedCatId != 0) {
                            Get.find<CategoryController>().getSubCategoryList(
                              selectedCatId,
                            );
                          } else {
                            Get.find<CategoryController>().update();
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                            right: Dimensions.paddingSizeSmall,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault,
                            vertical: 6,
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

              // Subcategories Bar (shown under main category)
              GetBuilder<CategoryController>(
                builder: (categoryController) {
                  final List<CategoryModel>? subCatList =
                      categoryController.subCategoryList;
                  if (storeController.categoryIndex != 0 &&
                      subCatList != null &&
                      subCatList.isNotEmpty) {
                    return Container(
                      height: 40,
                      color: Theme.of(context).cardColor.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: ListView.builder(
                        controller: _subCategoryScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                        ),
                        itemCount: subCatList.length + 1,
                        itemBuilder: (context, index) {
                          final bool isAll = index == 0;
                          final CategoryModel? subCat = !isAll
                              ? subCatList[index - 1]
                              : null;
                          final bool isSelected = isAll
                              ? _selectedSubCategoryId == null
                              : _selectedSubCategoryId == subCat?.id;

                          return InkWell(
                            onTap: () {
                              _currentIndex = 0;
                              setState(() {
                                _selectedSubCategoryId = isAll
                                    ? null
                                    : subCat?.id;
                              });
                              storeController.setOffset(1);
                              storeController.getItemList(
                                offset: '1',
                                type: 'all',
                                search: _searchController.text.trim(),
                                categoryId: isAll
                                    ? storeController.categoryId
                                    : subCat?.id,
                                barcode: _barcodeSearch,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: Dimensions.paddingSizeSmall,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.15)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(
                                          context,
                                        ).disabledColor.withOpacity(0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isAll ? 'all'.tr : (subCat?.name ?? ''),
                                style: robotoMedium.copyWith(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const Divider(height: 1),

              // Product List view with Pagination & Selection support
              Expanded(
                child: items == null
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(Images.emptyBox, width: 100),
                            const SizedBox(
                              height: Dimensions.paddingSizeDefault,
                            ),
                            Text(
                              'no_item_available'.tr,
                              style: robotoMedium.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeSmall,
                        ),
                        itemCount:
                            items.length + (storeController.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(
                                Dimensions.paddingSizeDefault,
                              ),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final Item item = items[index];
                          final bool isActive = index == _currentIndex;
                          final bool isStaged = _stagedPrices.containsKey(
                            item.id,
                          );
                          final TextEditingController controller =
                              _getControllerForItem(item);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(
                                bottom: Dimensions.paddingSizeSmall,
                              ),
                              padding: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.04)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault,
                                ),
                                border: Border.all(
                                  color: isActive
                                      ? Theme.of(context).primaryColor
                                      : isStaged
                                      ? Colors.green
                                      : Theme.of(
                                          context,
                                        ).disabledColor.withOpacity(0.15),
                                  width: isActive ? 2 : (isStaged ? 1.5 : 1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Item Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusSmall,
                                    ),
                                    child: CustomImageWidget(
                                      image: '${item.imageFullUrl}',
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: Dimensions.paddingSizeSmall,
                                  ),

                                  // Item Name & Original Price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.name ?? '',
                                                style: robotoBold.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  color: isActive
                                                      ? Theme.of(
                                                          context,
                                                        ).primaryColor
                                                      : null,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isStaged)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.green,
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  'مُعدّل',
                                                  style: robotoBold.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeExtraSmall,
                                                    color: Colors.green[700],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'السعر الحالي: ',
                                              style: robotoRegular.copyWith(
                                                fontSize: Dimensions
                                                    .fontSizeExtraSmall,
                                                color: Theme.of(
                                                  context,
                                                ).disabledColor,
                                              ),
                                            ),
                                            Text(
                                              PriceConverterHelper.convertPrice(
                                                item.price,
                                              ),
                                              style: robotoMedium.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                color: Theme.of(
                                                  context,
                                                ).disabledColor,
                                                decoration: isStaged
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(
                                    width: Dimensions.paddingSizeSmall,
                                  ),

                                  // Price Input Box
                                  SizedBox(
                                    width: 105,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isStaged
                                                ? Theme.of(context).primaryColor
                                                      .withOpacity(0.08)
                                                : Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(
                                              Dimensions.radiusSmall,
                                            ),
                                            border: Border.all(
                                              color: isActive
                                                  ? Theme.of(
                                                      context,
                                                    ).primaryColor
                                                  : isStaged
                                                  ? Colors.green
                                                  : Theme.of(context)
                                                        .disabledColor
                                                        .withOpacity(0.4),
                                              width: isActive ? 2 : 1,
                                            ),
                                          ),
                                          child: TextField(
                                            controller: controller,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            textAlign: TextAlign.center,
                                            style: robotoBold.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              color: isStaged
                                                  ? Theme.of(
                                                      context,
                                                    ).primaryColor
                                                  : Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 4,
                                                  ),
                                            ),
                                            onTap: () {
                                              setState(() {
                                                _currentIndex = index;
                                              });
                                            },
                                            onChanged: (val) =>
                                                _onItemPriceChanged(item, val),
                                          ),
                                        ),
                                        if (isStaged)
                                          InkWell(
                                            onTap: () => _resetItemPrice(item),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Text(
                                                'إلغاء التعديل',
                                                style: robotoRegular.copyWith(
                                                  fontSize: 10,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Built-in Custom Numpad Keyboard Panel
              if (items != null && items.isNotEmpty)
                _buildBuiltInNumpad(context, items),
            ],
          ),

          // Bottom Action Bar when there are staged modifications
          bottomNavigationBar: _stagedPrices.isNotEmpty
              ? SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall,
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
                                'تم تعديل ${_stagedPrices.length} منتج',
                                style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                              Text(
                                'محفوظة كمسودة لغاية الاعتماد',
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: Theme.of(context).disabledColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomButtonWidget(
                          width: 140,
                          height: 42,
                          buttonText: 'مراجعة وحفظ',
                          onPressed: () =>
                              _showReviewBottomSheet(storeController),
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
}
