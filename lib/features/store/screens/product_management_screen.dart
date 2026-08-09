import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/common/widgets/paginated_list_widget.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/features/store/screens/item_details_screen.dart';
import 'package:shoplancer_vendor/features/store/screens/quick_add_item_screen.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MobileScannerController _scannerController = MobileScannerController();
  final Map<int, double> _updatedPrices = {};
  final Map<int, Item> _editedItems = {};

  String? _barcodeSearch;
  bool _showScanner = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final String clean = query.trim();
    _barcodeSearch = null;
    setState(() {});

    if (clean.length >= 3) {
      Get.find<StoreController>().getItemList(
        offset: '1',
        type: 'active',
        search: clean,
      );
    }
  }

  void _fetchPage(int? offset) {
    Get.find<StoreController>().getItemList(
      offset: offset?.toString() ?? '1',
      type: 'active',
      search: _searchController.text.trim(),
      barcode: _barcodeSearch,
    );
  }

  Future<void> _onBarcodeScanned(String barcode) async {
    final String cleanBarcode = barcode.trim();
    _barcodeSearch = cleanBarcode;
    _searchController.text = cleanBarcode;
    setState(() {
      _showScanner = false;
    });

    await Get.find<StoreController>().getItemList(
      offset: '1',
      type: 'active',
      search: '',
      barcode: cleanBarcode,
    );
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

    setState(() => _isSaving = true);
    int successCount = 0;

    for (var entry in _updatedPrices.entries) {
      final int itemId = entry.key;
      final double newPrice = entry.value;
      final Item? item = _editedItems[itemId];

      if (item != null) {
        bool ok = await storeController.updateItemPriceOnly(
          itemId,
          newPrice,
          item: item,
        );
        if (ok) successCount++;
      }
    }

    setState(() {
      _isSaving = false;
      _updatedPrices.clear();
      _editedItems.clear();
    });

    showCustomSnackBar(
      'تم حفظ أسعار $successCount منتج بنجاح'.tr,
      isError: false,
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

  @override
  Widget build(BuildContext context) {
    bool isQueryValid =
        _searchController.text.trim().length >= 3 || _barcodeSearch != null;

    return GetBuilder<StoreController>(
      builder: (storeController) {
        return Scaffold(
          appBar: CustomAppBarWidget(
            title: 'إدارة المنتجات',
            menuWidget: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.white, size: 26),
              tooltip: 'إضافة منتج'.tr,
              onPressed: () => Get.to(() => const QuickAddItemScreen()),
            ),
          ),
          floatingActionButton: _updatedPrices.isNotEmpty
              ? null
              : FloatingActionButton(
                  heroTag: 'product_mgmt_add_item_fab',
                  onPressed: () => Get.to(() => const QuickAddItemScreen()),
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
          body: Column(
            children: [
              // Search & Scanner Header
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFieldWidget(
                            controller: _searchController,
                            hintText:
                                'ابحث عن منتج بالاسم (3 أحرف على الأقل)...'.tr,
                            prefixIcon: Icons.search,
                            suffixChild: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _barcodeSearch = null;
                                      setState(() {});
                                    },
                                  )
                                : null,
                            onChanged: (val) => _onSearchChanged(val),
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
                                  : Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusDefault,
                              ),
                            ),
                            child: Icon(
                              Icons.qr_code_scanner,
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
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              MobileScanner(
                                controller: _scannerController,
                                onDetect: (capture) {
                                  for (final barcode in capture.barcodes) {
                                    final raw = barcode.rawValue?.trim();
                                    if (raw != null && raw.isNotEmpty) {
                                      _onBarcodeScanned(raw);
                                      break;
                                    }
                                  }
                                },
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _showScanner = false),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1),

              // Main List View Area with Pagination
              Expanded(
                child: !isQueryValid
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeLarge,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 64,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),
                              Text(
                                'اكتب 3 أحرف على الأقل للبحث عن المنتجات'.tr,
                                textAlign: TextAlign.center,
                                style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeSmall,
                              ),
                              Text(
                                'أو استخدم قارئ الباركود لمسح المنتج وعرضه مباشرة هنا'
                                    .tr,
                                textAlign: TextAlign.center,
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).disabledColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : storeController.itemList == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildProductsList(context, storeController),
              ),

              // Bottom Save Staged Prices Floating Bar
              if (_updatedPrices.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
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
                        onPressed: () => _saveAllChanges(storeController),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
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
                        Icon(Icons.edit_note_rounded, size: 14, color: Theme.of(context).primaryColor.withOpacity(0.6)),
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

            // Actions: Quick Price Modifier, Switch & Edit
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quick + / - Price Adjuster
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

                // Edit & Active Switch
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 18,
                      ),
                      onPressed: () {
                        Get.toNamed(
                          RouteHelper.getItemDetailsRoute(item),
                          arguments: ItemDetailsScreen(product: item),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: () => _confirmDelete(context, item),
                    ),
                    isLoading
                        ? const SizedBox(
                            width: 32,
                            height: 20,
                            child: Center(child: CupertinoActivityIndicator()),
                          )
                        : Transform.scale(
                            scale: 0.72,
                            child: CupertinoSwitch(
                              value: true,
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
}
