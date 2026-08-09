import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/features/category/controllers/category_controller.dart';
import 'package:shoplancer_vendor/features/pos/controllers/pos_controller.dart';
import 'package:shoplancer_vendor/features/pos/domain/models/pos_cart_model.dart';
import 'package:shoplancer_vendor/features/pos/screens/desktop_settings_screen.dart';
import 'package:shoplancer_vendor/features/pos/widgets/add_pos_customer_dialog.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

/// The desktop (Windows/macOS) cashier home screen.
///
/// Layout: an order-creation panel takes the main area, with a fixed-width
/// product browsing sidebar. In the app's RTL (Arabic) locale, the first
/// child of a [Row] renders on the right, so [_ProductsSidebar] being first
/// puts the products panel on the right edge as requested.
class DesktopPosScreen extends StatefulWidget {
  const DesktopPosScreen({super.key});

  @override
  State<DesktopPosScreen> createState() => _DesktopPosScreenState();
}

class _DesktopPosScreenState extends State<DesktopPosScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<StoreController>().getItemList(offset: '1', type: 'all', search: '');
    Get.find<CategoryController>().getCategoryList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 400, child: _ProductsSidebar()),
            const VerticalDivider(width: 1),
            const Expanded(child: _OrderCreationPanel()),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Right sidebar: search / scan / categories / product grid.
// ============================================================================

class _ProductsSidebar extends StatefulWidget {
  const _ProductsSidebar();

  @override
  State<_ProductsSidebar> createState() => _ProductsSidebarState();
}

enum _SidebarTab { categories, products, orders }

class _ProductsSidebarState extends State<_ProductsSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  int? _selectedCategoryId;
  bool _showScanner = false;
  _SidebarTab _tab = _SidebarTab.products;

  @override
  void dispose() {
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _fetchItems() {
    Get.find<StoreController>().getItemList(
      offset: '1',
      type: 'all',
      search: _searchController.text.trim(),
      categoryId: _selectedCategoryId,
    );
  }

  void _onBarcodeScanned(String barcode) {
    final bool added = _addByBarcode(barcode);
    if (added) setState(() => _showScanner = false);
  }

  /// Shared by the camera scanner (auto-add on detect) and by typing a
  /// barcode into the search box and pressing Enter (manual barcode guns
  /// that emit keystrokes + Enter behave exactly like this too).
  bool _addByBarcode(String barcode) {
    final String code = barcode.trim();
    if (code.isEmpty) return false;
    final storeController = Get.find<StoreController>();
    final Item? found = storeController.itemList?.firstWhereOrNull(
      (item) => item.id.toString() == code || (item.name != null && item.name!.contains(code)),
    );
    if (found != null) {
      Get.find<PosController>().addToCart(found);
      _searchController.clear();
      _fetchItems();
      return true;
    } else {
      showCustomSnackBar('لم يتم العثور على منتج بهذا الباركود: $code'.tr);
      return false;
    }
  }

  void _openQuickPriceEdit(Item item) {
    final TextEditingController priceController = TextEditingController(
      text: (item.price ?? 0) % 1 == 0 ? (item.price ?? 0).toInt().toString() : (item.price ?? 0).toString(),
    );
    Get.dialog(
      AlertDialog(
        title: Text('تعديل سعر ${item.name ?? ''}'.tr, style: robotoBold),
        content: TextField(
          controller: priceController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'السعر الجديد'.tr),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('إلغاء'.tr)),
          ElevatedButton(
            onPressed: () async {
              final double? newPrice = double.tryParse(priceController.text.trim());
              if (newPrice == null || newPrice < 0) {
                showCustomSnackBar('أدخل سعرًا صحيحًا'.tr);
                return;
              }
              Get.back();
              final storeController = Get.find<StoreController>();
              await storeController.bulkItemsUpdate([
                storeController.buildStockUpdateData(item, price: newPrice),
              ]);
            },
            child: Text('حفظ'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // Barcode / search — kept at the very top, always visible, with
          // the camera scanner toggle right next to it.
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: CustomTextFieldWidget(
              controller: _searchController,
              hintText: 'امسح الباركود أو اكتبه ثم Enter، أو ابحث...'.tr,
              prefixIcon: Icons.qr_code_scanner,
              suffixChild: IconButton(
                icon: Icon(
                  _showScanner ? Icons.close : Icons.camera_alt_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: 'مسح بالكاميرا'.tr,
                onPressed: () => setState(() => _showScanner = !_showScanner),
              ),
              onChanged: (_) => _fetchItems(),
              // Barcode-gun / manual entry: typing a code then pressing
              // Enter adds the matching product directly to the cart.
              onSubmit: (text) => _addByBarcode(text),
            ),
          ),

          if (_showScanner)
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MobileScanner(
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
              ),
            ),
          if (_showScanner) const SizedBox(height: Dimensions.paddingSizeSmall),

          // Sidebar sections: categories / products / (held) orders.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                Expanded(
                  child: _SidebarTabButton(
                    label: 'الأصناف'.tr,
                    icon: Icons.category_outlined,
                    selected: _tab == _SidebarTab.categories,
                    onTap: () => setState(() => _tab = _SidebarTab.categories),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _SidebarTabButton(
                    label: 'المنتجات'.tr,
                    icon: Icons.grid_view_rounded,
                    selected: _tab == _SidebarTab.products,
                    onTap: () => setState(() => _tab = _SidebarTab.products),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GetBuilder<PosController>(
                    builder: (posController) => _SidebarTabButton(
                      label: 'الطلبات'.tr,
                      icon: Icons.receipt_long_outlined,
                      selected: _tab == _SidebarTab.orders,
                      badgeCount: posController.heldOrders.length,
                      onTap: () => setState(() => _tab = _SidebarTab.orders),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Expanded(child: _buildTabContent(context)),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (_tab) {
      case _SidebarTab.categories:
        return _CategoriesList(
          selectedCategoryId: _selectedCategoryId,
          onSelected: (id) {
            setState(() {
              _selectedCategoryId = id;
              _tab = _SidebarTab.products; // jump straight to the filtered products
            });
            _fetchItems();
          },
        );
      case _SidebarTab.products:
        return GetBuilder<StoreController>(
          builder: (storeController) {
            if (storeController.itemList == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = storeController.itemList!;
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد منتجات مطابقة'.tr,
                  style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final Item item = items[index];
                return _ProductCard(
                  item: item,
                  onTap: () => Get.find<PosController>().addToCart(item),
                  onEditPrice: () => _openQuickPriceEdit(item),
                );
              },
            );
          },
        );
      case _SidebarTab.orders:
        return const _HeldOrdersList();
    }
  }
}

class _SidebarTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;
  const _SidebarTabButton({required this.label, required this.icon, required this.selected, required this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 20, color: selected ? Colors.white : primary),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: robotoMedium.copyWith(fontSize: 11, color: selected ? Colors.white : primary)),
          ],
        ),
      ),
    );
  }
}

/// Vertical list of categories (replaces the old horizontal chip strip —
/// this is its own sidebar section now).
class _CategoriesList extends StatelessWidget {
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;
  const _CategoriesList({required this.selectedCategoryId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        if (categoryController.categoryList == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = categoryController.categoryList!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            final bool isAll = index == 0;
            final category = isAll ? null : categories[index - 1];
            final bool isSelected = isAll ? (selectedCategoryId == null) : (selectedCategoryId == category?.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.label_outline, size: 18, color: isSelected ? Colors.white : Theme.of(context).primaryColor),
                title: Text(
                  isAll ? 'كل الأصناف'.tr : (category?.name ?? ''),
                  style: robotoMedium.copyWith(fontSize: 13, color: isSelected ? Colors.white : null),
                ),
                onTap: () => onSelected(isAll ? null : category?.id),
              ),
            );
          },
        );
      },
    );
  }
}

/// Vertical list of parked/held orders (the "الطلبات" sidebar section). Tap
/// a row to resume it — the active order, if any, is held automatically
/// first so nothing gets lost — or delete it with the trash icon.
class _HeldOrdersList extends StatelessWidget {
  const _HeldOrdersList();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PosController>(
      builder: (posController) {
        if (posController.heldOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Theme.of(context).disabledColor),
                const SizedBox(height: 8),
                Text('لا توجد طلبات معلّقة'.tr, style: robotoMedium.copyWith(color: Theme.of(context).disabledColor)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          itemCount: posController.heldOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final held = posController.heldOrders[index];
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => posController.resumeHeldOrder(held.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pause_circle_outline, color: Colors.orange, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(held.label ?? 'طلب معلّق'.tr, style: robotoBold.copyWith(fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            '${held.cartList.length} صنف · ${held.total.toStringAsFixed(2)}',
                            style: robotoRegular.copyWith(fontSize: 12, color: Theme.of(context).disabledColor),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => posController.deleteHeldOrder(held.id),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback onEditPrice;

  const _ProductCard({required this.item, required this.onTap, required this.onEditPrice});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomImageWidget(image: item.imageFullUrl ?? '', width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name ?? '', style: robotoMedium.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: onEditPrice,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.price ?? 0}',
                              style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: 13),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.edit, size: 12, color: Theme.of(context).primaryColor.withValues(alpha: 0.6)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Main area: cart list with big +/- controls, order options, place-order.
// ============================================================================

class _OrderCreationPanel extends StatelessWidget {
  const _OrderCreationPanel();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PosController>(
      builder: (posController) {
        return Column(
          children: [
            _Header(posController: posController),
            const Divider(height: 1),
            Expanded(
              child: posController.cartList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.point_of_sale, size: 64, color: Theme.of(context).disabledColor),
                          const SizedBox(height: 12),
                          Text('اختر منتجات من القائمة لبدء طلب جديد'.tr, style: robotoMedium.copyWith(color: Theme.of(context).disabledColor)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      itemCount: posController.cartList.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) => _CartRow(index: index, cart: posController.cartList[index]),
                    ),
            ),
            const Divider(height: 1),
            _OrderOptionsAndTotals(posController: posController),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final PosController posController;
  const _Header({required this.posController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          Icon(Icons.storefront, color: Theme.of(context).primaryColor, size: 26),
          const SizedBox(width: 8),
          Text('إنشاء طلب جديد'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
          const Spacer(),
          if (posController.cartList.isNotEmpty)
            // Big, unmistakable: park the current order and start a fresh
            // one, instead of losing it if it's not finished yet.
            ElevatedButton.icon(
              onPressed: () => posController.holdCurrentOrderAndStartNew(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.pause_circle_outline, color: Colors.white),
              label: Text('تعليق وطلب جديد'.tr, style: const TextStyle(color: Colors.white)),
            ),
          const SizedBox(width: 8),
          if (posController.cartList.isNotEmpty)
            TextButton.icon(
              onPressed: () => posController.clearCart(),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text('تفريغ السلة'.tr, style: const TextStyle(color: Colors.red)),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات'.tr,
            onPressed: () => Get.to(() => const DesktopSettingsScreen()),
          ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final int index;
  final PosCartModel cart;
  const _CartRow({required this.index, required this.cart});

  @override
  Widget build(BuildContext context) {
    final posController = Get.find<PosController>();
    final double lineTotal = cart.price * cart.quantity;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomImageWidget(image: cart.item.imageFullUrl ?? '', width: 56, height: 56, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cart.item.name ?? '', style: robotoBold.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${cart.price} × ${cart.quantity} = ${lineTotal.toStringAsFixed(2)}', style: robotoMedium.copyWith(fontSize: 13, color: Theme.of(context).disabledColor)),
            ],
          ),
        ),
        // Large, unmistakable +/- quantity controls.
        _QtyButton(icon: Icons.remove, onTap: () => posController.updateQuantity(index, false)),
        Container(
          width: 48,
          alignment: Alignment.center,
          child: Text('${cart.quantity}', style: robotoBold.copyWith(fontSize: 22)),
        ),
        _QtyButton(icon: Icons.add, filled: true, onTap: () => posController.updateQuantity(index, true)),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => posController.removeFromCart(index),
        ),
      ],
    );
  }
}

/// Deliberately large (52px) tap targets — this is the control cashiers hit
/// dozens of times per order, so it needs to be impossible to miss/mistap.
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _QtyButton({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? primary : primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: filled ? Colors.white : primary, size: 26),
      ),
    );
  }
}

class _OrderOptionsAndTotals extends StatelessWidget {
  final PosController posController;
  const _OrderOptionsAndTotals({required this.posController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Theme.of(context).disabledColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        posController.selectedCustomer != null
                            ? '${posController.selectedCustomer!.fullName}${posController.selectedCustomer!.phone != null ? ' (${posController.selectedCustomer!.phone})' : ''}'
                            : 'بدون عميل محدد'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoMedium.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Get.dialog(const AddPosCustomerDialog()),
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: Text('عميل'.tr),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _OrderTypeChip(label: 'استلام'.tr, value: 'take_away', posController: posController),
              _OrderTypeChip(label: 'توصيل'.tr, value: 'delivery', posController: posController),
            ],
          ),
          if (posController.orderType == 'delivery') ...[
            const SizedBox(height: 10),
            _DeliveryChargeField(posController: posController),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي'.tr, style: robotoMedium.copyWith(fontSize: 15)),
              Text('${posController.subTotal.toStringAsFixed(2)}', style: robotoMedium.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي الكلي'.tr, style: robotoBold.copyWith(fontSize: 20)),
              Text(
                posController.grandTotal.toStringAsFixed(2),
                style: robotoBold.copyWith(fontSize: 22, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
              onPressed: posController.isLoading || posController.cartList.isEmpty
                  ? null
                  : () => posController.placeOrder(),
              child: posController.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('إنشاء الطلب'.tr, style: robotoBold.copyWith(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Delivery-charge input shown at the bottom when the order type is
/// "delivery". The value is kept in [PosController] and, deliberately,
/// isn't reset when a new order starts — the same delivery fee usually
/// applies to the next order too, so the cashier only changes it when it's
/// actually different.
class _DeliveryChargeField extends StatefulWidget {
  final PosController posController;
  const _DeliveryChargeField({required this.posController});

  @override
  State<_DeliveryChargeField> createState() => _DeliveryChargeFieldState();
}

class _DeliveryChargeFieldState extends State<_DeliveryChargeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final double charge = widget.posController.deliveryCharge;
    _controller = TextEditingController(text: charge == 0 ? '' : (charge % 1 == 0 ? charge.toInt().toString() : charge.toString()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.delivery_dining, size: 18, color: Theme.of(context).disabledColor),
        const SizedBox(width: 6),
        Text('سعر التوصيل'.tr, style: robotoMedium.copyWith(fontSize: 13)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) {
              widget.posController.setDeliveryCharge(double.tryParse(value.trim()) ?? 0);
            },
          ),
        ),
      ],
    );
  }
}

class _OrderTypeChip extends StatelessWidget {
  final String label;
  final String value;
  final PosController posController;
  const _OrderTypeChip({required this.label, required this.value, required this.posController});

  @override
  Widget build(BuildContext context) {
    final bool selected = posController.orderType == value;
    return ChoiceChip(
      label: Text(label, style: robotoMedium.copyWith(fontSize: 13, color: selected ? Colors.white : null)),
      selected: selected,
      selectedColor: Theme.of(context).primaryColor,
      onSelected: (_) => posController.setOrderType(value),
    );
  }
}
