import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/pos/controllers/pos_controller.dart';
import 'package:shoplancer_vendor/features/pos/widgets/pos_cart_bottom_sheet.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class PosBarcodeScannerScreen extends StatefulWidget {
  const PosBarcodeScannerScreen({super.key});

  @override
  State<PosBarcodeScannerScreen> createState() => _PosBarcodeScannerScreenState();
}

class _PosBarcodeScannerScreenState extends State<PosBarcodeScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  Item? _scannedItem;
  int _scannedQuantity = 1;
  bool _isScanning = true;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcodeScanned(String barcode) {
    final storeController = Get.find<StoreController>();
    if (storeController.itemList == null) return;

    Item? foundItem = storeController.itemList!.firstWhereOrNull(
      (item) => item.id.toString() == barcode || (item.name != null && item.name!.contains(barcode)),
    );

    if (foundItem != null) {
      setState(() {
        _scannedItem = foundItem;
        _scannedQuantity = 1;
        _isScanning = false;
      });
      showCustomSnackBar('تم العثور على المنتج: ${foundItem.name}', isError: false);
    } else {
      showCustomSnackBar('لم يتم العثور على منتج بهذا الباركود: $barcode');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'امسح باركود'.tr),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          children: [
            // 1. Box 1: Scanner Viewfinder Box ("امسح باركود")
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black12,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _isScanning
                    ? MobileScanner(
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
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                            const SizedBox(height: 8),
                            Text('تم قراءة الباركود', style: robotoBold),
                            TextButton.icon(
                              onPressed: () => setState(() => _isScanning = true),
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('مسح باركود آخر'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // 2. Box 2: Product Card ("المنتج" + +/- quantity)
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المنتج:', style: robotoBold.copyWith(fontSize: 16)),
                      if (_scannedItem != null)
                        Text('${_scannedItem!.price} ج.م', style: robotoBold.copyWith(color: Theme.of(context).primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scannedItem != null ? (_scannedItem!.name ?? '') : 'قم بمسح الباركود لعرض المنتج هنا',
                    style: robotoMedium.copyWith(
                      color: _scannedItem != null ? Colors.black : Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  // Quantity Controls (- عدد +)
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _scannedItem == null || _scannedQuantity <= 1
                                  ? null
                                  : () {
                                      setState(() => _scannedQuantity--);
                                    },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('عدد: $_scannedQuantity', style: robotoBold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: _scannedItem == null
                                  ? null
                                  : () {
                                      setState(() => _scannedQuantity++);
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // 3. Buttons: إضافة & إلغاء
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        _scannedItem = null;
                        _scannedQuantity = 1;
                        _isScanning = true;
                      });
                    },
                    child: Text('إلغاء'.tr, style: robotoBold.copyWith(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _scannedItem == null
                        ? null
                        : () {
                            Get.find<PosController>().addToCart(_scannedItem!, quantity: _scannedQuantity);
                            setState(() {
                              _scannedItem = null;
                              _scannedQuantity = 1;
                              _isScanning = true;
                            });
                          },
                    child: Text('إضافة'.tr, style: robotoBold.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // 4. Box 3: Added Products List ("قائمة المنتجات المضافة")
            GetBuilder<PosController>(
              builder: (posController) {
                return Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('قائمة المنتجات المضافة', style: robotoBold.copyWith(fontSize: 16)),
                      const SizedBox(height: 12),

                      // Header: المنتج - عدده - حذف
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(flex: 3, child: Text('المنتج', style: robotoBold)),
                            Expanded(flex: 2, child: Text('عدده', style: robotoBold, textAlign: TextAlign.center)),
                            Expanded(flex: 1, child: Text('حذف', style: robotoBold, textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (posController.cartList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('لا توجد منتجات مضافة بعد', style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: posController.cartList.length,
                          separatorBuilder: (context, i) => const Divider(),
                          itemBuilder: (context, index) {
                            final cart = posController.cartList[index];
                            return Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(cart.item.name ?? '', style: robotoMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('${cart.quantity}', style: robotoBold, textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => posController.removeFromCart(index),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // 5. Main Action Buttons: إلغاء الكل & إنشاء طلب
            GetBuilder<PosController>(
              builder: (posController) {
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: posController.cartList.isEmpty
                            ? null
                            : () {
                                posController.clearCart();
                              },
                        child: Text('إلغاء الكل'.tr, style: robotoBold.copyWith(color: Colors.red)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: posController.cartList.isEmpty
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const PosCartBottomSheet(),
                                );
                              },
                        child: Text('إنشاء طلب'.tr, style: robotoBold.copyWith(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
