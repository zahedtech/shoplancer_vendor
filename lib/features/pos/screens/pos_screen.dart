import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/pos/controllers/pos_controller.dart';
import 'package:shoplancer_vendor/features/pos/widgets/pos_cart_bottom_sheet.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  Timer? _debounceTimer;
  DateTime? _lastScanTime;
  bool _isTorchOn = false;
  bool _isProcessingScan = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<StoreController>().getItemList(
        offset: '1',
        type: 'all',
        search: '',
      );
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim();
        });
        Get.find<StoreController>().getItemList(
          offset: '1',
          type: 'all',
          search: _searchQuery,
        );
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    Get.find<StoreController>().getItemList(
      offset: '1',
      type: 'all',
      search: '',
    );
  }

  Future<void> _onBarcodeScanned(String barcode) async {
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1500) {
      return;
    }
    if (_isProcessingScan) return;

    _lastScanTime = now;
    _isProcessingScan = true;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    final storeController = Get.find<StoreController>();
    Item? foundItem;

    if (storeController.itemList != null) {
      foundItem = storeController.itemList!.firstWhereOrNull(
        (item) =>
            item.barcode == barcode ||
            item.id.toString() == barcode ||
            (item.name != null && item.name!.contains(barcode)),
      );
    }

    if (foundItem == null) {
      try {
        ItemModel? itemModel = await storeController.storeServiceInterface
            .getItemList(
              offset: '1',
              type: 'all',
              search: '',
              barcode: barcode,
            );
        if (itemModel?.items != null && itemModel!.items!.isNotEmpty) {
          foundItem = itemModel.items!.first;
        }
      } catch (_) {}
    }

    _isProcessingScan = false;

    if (foundItem != null) {
      Get.find<PosController>().addToCart(foundItem);
      showCustomSnackBar(
        '${'added_to_cart'.tr}: ${foundItem.name}',
        isError: false,
      );
    } else {
      showCustomSnackBar('لم يتم العثور على منتج بهذا الباركود: $barcode');
    }
  }

  void _showManualBarcodeDialog() {
    final TextEditingController barcodeInput = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.barcode_reader, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'مسح أو إدخال باركود'.tr,
              style: robotoBold.copyWith(fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وجه الكاميرا بالأعلى نحو الباركود، أو اكتب رقم الباركود هنا:'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: barcodeInput,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'رقم الباركود...'.tr,
                prefixIcon: const Icon(Icons.barcode_reader),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.of(ctx).pop();
                  _onBarcodeScanned(val.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (barcodeInput.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop();
                _onBarcodeScanned(barcodeInput.text.trim());
              }
            },
            child: Text(
              'بحث وإضافة'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _openCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PosCartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'إنشاء طلب جديد (POS)'.tr,
        isBackButtonExist: false,
        menuWidget: GetBuilder<PosController>(
          builder: (posController) {
            if (posController.cartList.isEmpty) return const SizedBox();
            return IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.red,
                size: 24,
              ),
              tooltip: 'مسح السلة'.tr,
              onPressed: () {
                posController.clearCart();
                showCustomSnackBar('تم تفريغ السلة'.tr, isError: false);
              },
            );
          },
        ),
      ),
      body: Column(
        children: [
          // 1. Permanent Barcode Scanner at the Top with Animated Laser Line
          Container(
            height: 185,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeExtraSmall,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Camera Stream
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

                  // Laser Animation & Viewfinder Overlay
                  const _ScannerLaserOverlay(),

                  // Top Scanner Header / Flash Control
                  Positioned(
                    top: 8,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.barcode_reader,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'الماسح الضوئي نشط'.tr,
                                style: robotoMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                _scannerController.toggleTorch();
                                setState(() {
                                  _isTorchOn = !_isTorchOn;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                                  color: _isTorchOn
                                      ? Colors.amber
                                      : Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _scannerController.switchCamera(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.flip_camera_android,
                                  color: Colors.white,
                                  size: 18,
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
            ),
          ),

          // 2. Direct In-Page Search Field (No Bottom Sheet)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: 6,
            ),
            color: Theme.of(context).cardColor,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSearching
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو رمز المنتج مباشرة...'.tr,
                  hintStyle: robotoRegular.copyWith(
                    color: Theme.of(context).disabledColor,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isSearching
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).disabledColor,
                  ),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // 3. Main Content: Search Results List OR Cart Items List
          Expanded(
            child: isSearching
                ? _buildSearchResultsView()
                : _buildCartItemsView(),
          ),

          // 4. Bottom Action Bar with Scan Button & Checkout Button
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ==========================================================================
  // In-Page Search Results View
  // ==========================================================================
  Widget _buildSearchResultsView() {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        if (storeController.itemList == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = storeController.itemList!;
        if (items.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: Theme.of(context).disabledColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text(
                    'لا توجد منتجات مطابقة للبحث: "$_searchQuery"'.tr,
                    textAlign: TextAlign.center,
                    style: robotoMedium.copyWith(
                      color: Theme.of(context).disabledColor,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  TextButton.icon(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text('العودة للسلة'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeExtraSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'نتائج البحث (${items.length})'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  InkWell(
                    onTap: _clearSearch,
                    child: Text(
                      'إلغاء البحث'.tr,
                      style: robotoMedium.copyWith(
                        color: Colors.red,
                        fontSize: Dimensions.fontSizeExtraSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GetBuilder<PosController>(
                builder: (posController) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeSmall,
                      Dimensions.paddingSizeExtraSmall,
                      Dimensions.paddingSizeSmall,
                      Dimensions.paddingSizeSmall,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final Item item = items[index];
                      final cartEntry = posController.cartList.firstWhereOrNull(
                        (c) => c.item.id == item.id,
                      );
                      final int inCartQty = cartEntry?.quantity ?? 0;

                      return Container(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeSmall,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                          border: Border.all(
                            color: inCartQty > 0
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.3)
                                : Theme.of(
                                    context,
                                  ).disabledColor.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusSmall,
                              ),
                              child: CustomImageWidget(
                                image: item.imageFullUrl ?? '',
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
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
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        PriceConverterHelper.convertPrice(
                                          item.price ?? 0,
                                        ),
                                        style: robotoBold.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                      if (inCartQty > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '$inCartQty بالسلة',
                                            style: robotoMedium.copyWith(
                                              color: Colors.green,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(8),
                                elevation: 0,
                              ),
                              onPressed: () {
                                posController.addToCart(item);
                                showCustomSnackBar(
                                  'تمت الإضافة: ${item.name}',
                                  isError: false,
                                );
                              },
                              child: const Icon(Icons.add, size: 18),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // Cart Items View
  // ==========================================================================
  Widget _buildCartItemsView() {
    return GetBuilder<PosController>(
      builder: (posController) {
        if (posController.cartList.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 54,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text(
                    'السلة فارغة حالياً'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    'امسح الباركود بالكاميرا في الأعلى أو اكتب اسم المنتج في البحث لإضافته'
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
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeExtraSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'محتويات السلة (${posController.cartList.length})'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                  Text(
                    'الإجمالي: ${PriceConverterHelper.convertPrice(posController.grandTotal)}',
                    style: robotoBold.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeSmall,
                  Dimensions.paddingSizeExtraSmall,
                  Dimensions.paddingSizeSmall,
                  Dimensions.paddingSizeSmall,
                ),
                itemCount: posController.cartList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cart = posController.cartList[index];

                  return Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context).disabledColor.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSmall,
                          ),
                          child: CustomImageWidget(
                            image: cart.item.imageFullUrl ?? '',
                            height: 52,
                            width: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cart.item.name ?? '',
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              if (cart.selectedVariant != null &&
                                  cart.selectedVariant!.isNotEmpty)
                                Text(
                                  'النوع: ${cart.selectedVariant}',
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                              Text(
                                PriceConverterHelper.convertPrice(cart.price),
                                style: robotoBold.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSmall,
                                ),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).disabledColor.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => posController.updateQuantity(
                                      index,
                                      false,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Icon(Icons.remove, size: 16),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '${cart.quantity}',
                                      style: robotoBold.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => posController.updateQuantity(
                                      index,
                                      true,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Icon(Icons.add, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () =>
                                  posController.removeFromCart(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // Bottom Action Bar: Scan Button & Checkout
  // ==========================================================================
  Widget _buildBottomBar() {
    return GetBuilder<PosController>(
      builder: (posController) {
        final hasCartItems = posController.cartList.isNotEmpty;

        return Container(
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeExtraOverLarge,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Scan Button at the bottom
                Expanded(
                  flex: hasCartItems ? 2 : 1,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasCartItems
                          ? Theme.of(context).cardColor
                          : Theme.of(context).primaryColor,
                      foregroundColor: hasCartItems
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusDefault,
                        ),
                      ),
                    ),
                    onPressed: _showManualBarcodeDialog,
                    icon: const Icon(Icons.barcode_reader, size: 20),
                    label: Text(
                      'مسح باركود'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                  ),
                ),

                if (hasCartItems) ...[
                  const SizedBox(width: 8),
                  // Order / Cart Checkout Button
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                        ),
                      ),
                      onPressed: () => _openCartSheet(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${posController.cartList.length}',
                                  style: robotoBold.copyWith(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'متابعة الطلب'.tr,
                                style: robotoBold.copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            PriceConverterHelper.convertPrice(
                              posController.grandTotal,
                            ),
                            style: robotoBold.copyWith(
                              color: Colors.white,
                              fontSize: 14,
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
        );
      },
    );
  }
}

// ============================================================================
// Animated Laser & Viewfinder Overlay
// ============================================================================

class _ScannerLaserOverlay extends StatefulWidget {
  const _ScannerLaserOverlay();

  @override
  State<_ScannerLaserOverlay> createState() => _ScannerLaserOverlayState();
}

class _ScannerLaserOverlayState extends State<_ScannerLaserOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.12, end: 0.88).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boxWidth = constraints.maxWidth * 0.86;
        final double boxHeight = constraints.maxHeight * 0.76;

        return Stack(
          children: [
            // Center Viewfinder Target Area with Corner Accents
            Center(
              child: SizedBox(
                width: boxWidth,
                height: boxHeight,
                child: CustomPaint(
                  painter: _ScannerCornerPainter(
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 3.5,
                    cornerLength: 22,
                  ),
                ),
              ),
            ),

            // Moving Scan Line (Laser)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  top: constraints.maxHeight * _animation.value,
                  left: constraints.maxWidth * 0.08,
                  right: constraints.maxWidth * 0.08,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Theme.of(context).primaryColor.withOpacity(0.7),
                              Colors.redAccent,
                              Theme.of(context).primaryColor.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.75),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.redAccent.withOpacity(0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  _ScannerCornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double r = 10.0;

    // Top-Left Corner
    final pathTL = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right Corner
    final pathTR = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left Corner
    final pathBL = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - r)
      ..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right Corner
    final pathBR = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - r, size.height)
      ..arcToPoint(
        Offset(size.width, size.height - r),
        radius: const Radius.circular(r),
      )
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
