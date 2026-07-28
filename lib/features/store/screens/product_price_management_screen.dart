import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
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
  final Map<int, double> _stagedPrices = {};
  final Map<int, Item> _stagedItems = {};
  int _currentIndex = 0;
  int _lastSyncedItemId = -1;
  String _currentInput = '';
  bool _isEditingActive = false;
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
  }

  void _saveLocalDraft() {
    try {
      final prefs = Get.find<SharedPreferences>();
      if (_stagedPrices.isEmpty) {
        prefs.remove(_draftKey);
        return;
      }
      final Map<String, dynamic> data = {
        'prices': _stagedPrices.map((key, val) => MapEntry(key.toString(), val)),
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

  void _syncInputForCurrentItem(Item currentItem) {
    if (_lastSyncedItemId != currentItem.id || !_isEditingActive) {
      _lastSyncedItemId = currentItem.id ?? -1;
      final double price = _stagedPrices[currentItem.id] ?? (currentItem.price ?? 0);
      _currentInput = price % 1 == 0 ? price.toInt().toString() : price.toString();
    }
  }

  void _onNumpadPress(String val, List<Item> items) {
    if (items.isEmpty || _currentIndex >= items.length) return;
    setState(() {
      if (!_isEditingActive) {
        _isEditingActive = true;
        if (val == '.') {
          _currentInput = '0.';
        } else {
          _currentInput = val;
        }
      } else {
        if (val == '.') {
          if (!_currentInput.contains('.')) {
            _currentInput = _currentInput.isEmpty ? '0.' : _currentInput + '.';
          }
        } else {
          if (_currentInput == '0') {
            _currentInput = val;
          } else {
            _currentInput += val;
          }
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _isEditingActive = true;
      if (_currentInput.isNotEmpty) {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      }
    });
  }

  void _onClearCurrent(Item currentItem) {
    setState(() {
      _stagedPrices.remove(currentItem.id);
      _stagedItems.remove(currentItem.id);
      final double price = currentItem.price ?? 0;
      _currentInput = price % 1 == 0 ? price.toInt().toString() : price.toString();
      _isEditingActive = false;
      _lastSyncedItemId = currentItem.id ?? -1;
    });
    _saveLocalDraft();
  }

  void _stageAndNext(List<Item> items) {
    if (items.isEmpty || _currentIndex >= items.length) return;
    final Item item = items[_currentIndex];

    if (_currentInput.isNotEmpty) {
      final double? newPrice = double.tryParse(_currentInput.trim());
      if (newPrice != null && newPrice >= 0) {
        setState(() {
          _stagedPrices[item.id!] = newPrice;
          _stagedItems[item.id!] = item;
          _isEditingActive = false;
        });
        _saveLocalDraft();
      }
    }

    if (_currentIndex < items.length - 1) {
      _goToIndex(_currentIndex + 1, items);
    }
  }

  void _goToIndex(int index, List<Item> items) {
    if (index < 0 || index >= items.length) return;
    setState(() {
      _currentIndex = index;
      _isEditingActive = false;
      final Item nextItem = items[index];
      _lastSyncedItemId = nextItem.id ?? -1;
      final double price = _stagedPrices[nextItem.id] ?? (nextItem.price ?? 0);
      _currentInput = price % 1 == 0 ? price.toInt().toString() : price.toString();
    });
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
                            _isEditingActive = false;
                            _currentInput = '';
                            _lastSyncedItemId = -1;
                          });
                          _clearLocalDraft();
                          Get.back();
                        },
                        child: const Text(
                          'تفريغ الكل',
                          style: TextStyle(color: Colors.red),
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
                        final double newPrice = _stagedPrices[item.id] ?? (item.price ?? 0);
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
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setModalState(() {
                                _stagedPrices.remove(item.id);
                                _stagedItems.remove(item.id);
                              });
                              setState(() {
                                _isEditingActive = false;
                                _lastSyncedItemId = -1;
                              });
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
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButtonWidget(
                          buttonText: 'تأكيد وحفظ التغييرات',
                          onPressed: () => _saveAllChanges(storeController),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveAllChanges(StoreController storeController) async {
    if (_stagedPrices.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final List<Map<String, String>> updates = [];
      for (final entry in _stagedPrices.entries) {
        final int itemId = entry.key;
        final double newPrice = entry.value;

        final Item? item = _stagedItems[itemId] ??
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
            _isEditingActive = false;
            _currentInput = '';
            _lastSyncedItemId = -1;
          });
          _clearLocalDraft();
          if (Get.isBottomSheetOpen ?? false) {
            Get.back();
          }
          showCustomSnackBar('تم حفظ وتحديث جميع الأسعار بنجاح', isError: false);
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

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        final List<Item> items = storeController.itemList ?? [];

        if (items.isNotEmpty && _currentIndex >= items.length) {
          _currentIndex = 0;
        }

        final Item? currentItem = items.isNotEmpty ? items[_currentIndex] : null;
        if (currentItem != null) {
          _syncInputForCurrentItem(currentItem);
        }

        return Scaffold(
          appBar: CustomAppBarWidget(
            title: 'محرر الأسعار السريع',
            menuWidget: _stagedPrices.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextButton.icon(
                      onPressed: () => _showReviewBottomSheet(storeController),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      label: Text(
                        'مراجعة (${_stagedPrices.length})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : null,
          ),
          body: storeController.itemList == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Category Selector Bar
                    if (storeController.categoryNameList != null)
                      Container(
                        height: 50,
                        color: Theme.of(context).cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ListView.builder(
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
                                _isEditingActive = false;
                                _lastSyncedItemId = -1;
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
                                        : Theme.of(context)
                                            .disabledColor
                                            .withOpacity(0.3),
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
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Main Product Card
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(Images.emptyBox, width: 120),
                                  const SizedBox(height: Dimensions.paddingSizeDefault),
                                  Text(
                                    'no_item_available'.tr,
                                    style: robotoMedium.copyWith(
                                      color: Theme.of(context).disabledColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                // Progress Indicator
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'المنتج ${_currentIndex + 1} من ${items.length}',
                                        style: robotoRegular.copyWith(
                                          color: Theme.of(context).disabledColor,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                      if (_stagedPrices.containsKey(currentItem!.id))
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.green),
                                          ),
                                          child: Text(
                                            'مٌعدّل مقدماً',
                                            style: robotoBold.copyWith(
                                              fontSize: Dimensions.fontSizeExtraSmall,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Active Focused Item Card
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault,
                                  ),
                                  padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeDefault,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusLarge,
                                    ),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.radiusDefault,
                                        ),
                                        child: CustomImageWidget(
                                          image: '${currentItem.imageFullUrl}',
                                          height: 75,
                                          width: 75,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: Dimensions.paddingSizeDefault,
                                      ),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currentItem.name ?? '',
                                              style: robotoBold.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeDefault,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  'السعر الأصلي: ',
                                                  style: robotoRegular.copyWith(
                                                    fontSize:
                                                        Dimensions.fontSizeSmall,
                                                    color: Theme.of(context)
                                                        .disabledColor,
                                                  ),
                                                ),
                                                Text(
                                                  PriceConverterHelper.convertPrice(
                                                    currentItem.price,
                                                  ),
                                                  style: robotoMedium.copyWith(
                                                    fontSize:
                                                        Dimensions.fontSizeSmall,
                                                    decoration:
                                                        TextDecoration.lineThrough,
                                                    color: Theme.of(context)
                                                        .disabledColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),

                                            // Display Area for New Input Price
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  Dimensions.radiusDefault,
                                                ),
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    _stagedPrices.containsKey(currentItem.id)
                                                        ? 'السعر المٌعدّل:'
                                                        : 'السعر الجديد:',
                                                    style: robotoMedium.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeSmall,
                                                    ),
                                                  ),
                                                  Text(
                                                    _currentInput.isEmpty
                                                        ? '0.0'
                                                        : PriceConverterHelper.convertPrice(
                                                            double.tryParse(_currentInput) ?? 0,
                                                          ),
                                                    style: robotoBold.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeLarge,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                // Built-in Custom Numpad Keyboard
                                _buildBuiltInNumpad(context, items, currentItem),
                              ],
                            ),
                    ),
                  ],
                ),
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
                                'تم تعديل ${_stagedPrices.length} منتج (محفوظة كمسودة)',
                                style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                              Text(
                                'انقر لمراجعة التغييرات وحفظها على السيرفر',
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
                          onPressed: () => _showReviewBottomSheet(storeController),
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

  Widget _buildBuiltInNumpad(
    BuildContext context,
    List<Item> items,
    Item currentItem,
  ) {
    final bool isLast = _currentIndex == items.length - 1;
    final bool isFirst = _currentIndex == 0;

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clean Action Navigation Row (Single Arrow Icons)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !isFirst ? () => _goToIndex(_currentIndex - 1, items) : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('السابق'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _onClearCurrent(currentItem),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('تفريغ'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _stageAndNext(items),
                  icon: Icon(
                    isLast ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(isLast ? 'اعتماد' : 'التالي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

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
              const SizedBox(height: 8),
              Row(
                children: [
                  _numKey('4', items),
                  _numKey('5', items),
                  _numKey('6', items),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _numKey('7', items),
                  _numKey('8', items),
                  _numKey('9', items),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _numKey('.', items),
                  _numKey('0', items),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: _onBackspace,
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusDefault,
                        ),
                        child: Container(
                          height: 48,
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
                            size: 22,
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
      ),
    );
  }

  Widget _numKey(String text, List<Item> items) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => _onNumpadPress(text, items),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Container(
            height: 48,
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
}
