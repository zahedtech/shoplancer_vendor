import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
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
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeScanned(String barcode) async {
    final storeController = Get.find<StoreController>();
    Item? foundItem;

    if (storeController.itemList != null) {
      foundItem = storeController.itemList!.firstWhereOrNull(
        (item) =>
            item.id.toString() == barcode ||
            (item.name != null && item.name!.contains(barcode)),
      );
    }

    if (foundItem == null) {
      ItemModel? itemModel = await storeController.storeServiceInterface
          .getItemList(offset: '1', type: 'all', search: '', barcode: barcode);
      if (itemModel?.items != null && itemModel!.items!.isNotEmpty) {
        foundItem = itemModel.items!.first;
      }
    }

    if (foundItem != null) {
      Get.find<PosController>().addToCart(foundItem);
      showCustomSnackBar(
        '${'added_to_cart'.tr}: ${foundItem.name}',
        isError: false,
      );
      setState(() {
        _showScanner = false;
      });
    } else {
      showCustomSnackBar('لم يتم العثور على منتج بهذا الباركود: $barcode');
    }
  }

  void _openProductSearchModal(
    BuildContext context, {
    String initialQuery = '',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductSearchBottomSheet(
        initialQuery: initialQuery,
        onItemSelected: (item) {
          Get.find<PosController>().addToCart(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Top Search & Scanner Card
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _openProductSearchModal(
                            context,
                            initialQuery: _searchController.text.trim(),
                          );
                        },
                        child: IgnorePointer(
                          child: CustomTextFieldWidget(
                            controller: _searchController,
                            hintText: 'ابحث عن منتج بالاسم...'.tr,
                            prefixIcon: Icons.search,
                          ),
                        ),
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
                              : Theme.of(context).primaryColor.withOpacity(0.1),
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

                // Inline Barcode Scanner view if active
                if (_showScanner) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Container(
                    height: 200,
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
                            top: 10,
                            right: 10,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _showScanner = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
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

          // Main Cart Items Section
          Expanded(
            child: GetBuilder<PosController>(
              builder: (posController) {
                if (posController.cartList.isEmpty) {
                  return Center(
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
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          Text(
                            'السلة فارغة حالياً'.tr,
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall,
                          ),
                          Text(
                            'ابحث عن المنتجات بالاسم أو امسح الباركود لإضافتها إلى السلة'
                                .tr,
                            textAlign: TextAlign.center,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault,
                                ),
                              ),
                            ),
                            onPressed: () => _openProductSearchModal(context),
                            icon: const Icon(Icons.search, size: 20),
                            label: Text(
                              'بحث وإضافة منتج'.tr,
                              style: robotoMedium,
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
                            'محتويات السلة (${posController.cartList.length})'
                                .tr,
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                          InkWell(
                            onTap: () => _openProductSearchModal(context),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle,
                                  color: Theme.of(context).primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'إضافة منتج'.tr,
                                  style: robotoMedium.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                              ],
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
                          90,
                        ),
                        itemCount: posController.cartList.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final cart = posController.cartList[index];
                          final itemTotal = (cart.price * cart.quantity);

                          return Container(
                            padding: const EdgeInsets.all(
                              Dimensions.paddingSizeSmall,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusDefault,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).disabledColor.withOpacity(0.1),
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
                                    height: 56,
                                    width: 56,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(
                                  width: Dimensions.paddingSizeSmall,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            fontSize:
                                                Dimensions.fontSizeExtraSmall,
                                            color: Theme.of(
                                              context,
                                            ).disabledColor,
                                          ),
                                        ),
                                      Text(
                                        PriceConverterHelper.convertPrice(
                                          cart.price,
                                        ),
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
                                            onTap: () => posController
                                                .updateQuantity(index, false),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              child: Icon(
                                                Icons.remove,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              '${cart.quantity}',
                                              style: robotoBold.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => posController
                                                .updateQuantity(index, true),
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
                                    const SizedBox(width: 6),
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
            ),
          ),

          // Bottom Continue Order Floating Bar
          GetBuilder<PosController>(
            builder: (posController) {
              if (posController.cartList.isEmpty) return const SizedBox();
              return Container(
                margin: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeExtraSmall,
                  Dimensions.paddingSizeDefault,
                  75,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
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
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${posController.cartList.length}',
                              style: robotoBold.copyWith(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'متابعة الطلب'.tr,
                            style: robotoBold.copyWith(
                              color: Colors.white,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            PriceConverterHelper.convertPrice(
                              posController.grandTotal,
                            ),
                            style: robotoBold.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
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
}

// ============================================================================
// Product Search Pop-up Bottom Sheet / Dialog
// ============================================================================

class _ProductSearchBottomSheet extends StatefulWidget {
  final String initialQuery;
  final Function(Item) onItemSelected;

  const _ProductSearchBottomSheet({
    required this.initialQuery,
    required this.onItemSelected,
  });

  @override
  State<_ProductSearchBottomSheet> createState() =>
      _ProductSearchBottomSheetState();
}

class _ProductSearchBottomSheetState extends State<_ProductSearchBottomSheet> {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().length >= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<StoreController>().getItemList(
          offset: '1',
          type: 'all',
          search: widget.initialQuery.trim(),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetch(String query) {
    setState(() {});
    if (query.trim().length >= 3) {
      Get.find<StoreController>().getItemList(
        offset: '1',
        type: 'all',
        search: query.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isQueryValid = _searchController.text.trim().length >= 3;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'بحث واختيار المنتجات'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Search Field
          CustomTextFieldWidget(
            controller: _searchController,
            hintText: 'ابحث بالاسم...'.tr,
            prefixIcon: Icons.search,
            onChanged: (val) => _fetch(val),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Results List / Prompt Area
          Expanded(
            child: !isQueryValid
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 56,
                          color: Theme.of(
                            context,
                          ).disabledColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          'اكتب 3 أحرف على الأقل للبحث عن المنتجات'.tr,
                          style: robotoMedium.copyWith(
                            color: Theme.of(context).disabledColor,
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                      ],
                    ),
                  )
                : GetBuilder<StoreController>(
                    builder: (storeController) {
                      if (storeController.itemList == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final items = storeController.itemList!;
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'لا توجد منتجات مطابقة لعملية البحث'.tr,
                            style: robotoMedium.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        );
                      }

                      return GetBuilder<PosController>(
                        builder: (posController) {
                          return ListView.separated(
                            controller: _scrollController,
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final Item item = items[index];
                              final cartEntry = posController.cartList
                                  .firstWhereOrNull(
                                    (c) => c.item.id == item.id,
                                  );
                              final int inCartQty = cartEntry?.quantity ?? 0;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall,
                                  ),
                                  child: CustomImageWidget(
                                    image: item.imageFullUrl ?? '',
                                    width: 50,
                                    height: 50,
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
                                      '${item.price ?? 0} ج.م',
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
                                          color: Colors.green.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$inCartQty بالسلة',
                                          style: robotoMedium.copyWith(
                                            color: Colors.green,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(8),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    widget.onItemSelected(item);
                                  },
                                  child: const Icon(Icons.add, size: 18),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),

          // Bottom Done button
          const SizedBox(height: Dimensions.paddingSizeSmall),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
              ),
              onPressed: () => Get.back(),
              child: Text(
                'تم / العودة للسلة'.tr,
                style: robotoBold.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
