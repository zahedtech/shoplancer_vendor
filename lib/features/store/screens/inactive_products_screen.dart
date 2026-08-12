import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shoplancer_vendor/common/widgets/pos_style_barcode_scanner_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/common/widgets/paginated_list_widget.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/features/store/screens/item_details_screen.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class InactiveProductsScreen extends StatefulWidget {
  const InactiveProductsScreen({super.key});

  @override
  State<InactiveProductsScreen> createState() => _InactiveProductsScreenState();
}

class _InactiveProductsScreenState extends State<InactiveProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<StoreController>().getItemList(
        offset: '1',
        type: 'inactive',
        search: '',
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    Get.find<StoreController>().getItemList(
      offset: '1',
      type: 'inactive',
      search: query.trim(),
    );
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
      ItemModel? model = await storeController.storeServiceInterface
          .getItemList(offset: '1', type: 'inactive', search: '', barcode: barcode);
      if (model?.items != null && model!.items!.isNotEmpty) {
        foundItem = model.items!.first;
      }
    }

    if (foundItem != null) {
      _searchController.text = foundItem.name ?? '';
      _onSearch(foundItem.name ?? '');
      setState(() {
        _showScanner = false;
      });
    } else {
      showCustomSnackBar('لم يتم العثور على منتج بهذا الباركود: $barcode');
    }
  }

  void _confirmDelete(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
        title: Text('حذف المنتج'.tr, style: robotoBold),
        content: Text(
          'هل أنت متأكد من حذف المنتج "${item.name}" نهائياً من المتجر؟'.tr,
          style: robotoRegular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'المنتجات غير النشطة'.tr),
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
                        hintText: 'ابحث في المنتجات غير النشطة...'.tr,
                        prefixIcon: Icons.search,
                        onChanged: (val) => _onSearch(val),
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
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        child: Icon(
                          Icons.barcode_reader,
                          color: _showScanner ? Colors.white : Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showScanner) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  PosStyleBarcodeScannerWidget(
                    onBarcodeScanned: (barcode) {
                      _onBarcodeScanned(barcode);
                    },
                    onClose: () => setState(() => _showScanner = false),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Inactive Products ListView
          Expanded(
            child: GetBuilder<StoreController>(
              builder: (storeController) {
                if (storeController.itemList == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter inactive products
                final inactiveItems = storeController.itemList!
                    .where((item) => item.status == 0)
                    .toList();

                if (inactiveItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green.withOpacity(0.5),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        Text(
                          'لا توجد منتجات غير نشطة / معطلة'.tr,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).disabledColor,
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
                      Get.find<StoreController>().getItemList(
                        offset: offset?.toString() ?? '1',
                        type: 'inactive',
                        search: _searchController.text.trim(),
                      );
                    },
                    productView: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      itemCount: inactiveItems.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final Item item = inactiveItems[index];
                        final bool isLoading = storeController.loadingItemsList.contains(item.id);

                    return Dismissible(
                      key: Key('inactive_product_${item.id}'),
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
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              child: Stack(
                                children: [
                                  CustomImageWidget(
                                    image: item.imageFullUrl ?? '',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.black38,
                                    alignment: Alignment.center,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'معطل',
                                        style: robotoBold.copyWith(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name ?? '',
                                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    PriceConverterHelper.convertPrice(item.price),
                                    style: robotoBold.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: Dimensions.fontSizeSmall,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'المخزون: ${item.stock ?? 0}',
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Actions: Switch to activate, Edit button, Delete button
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () {
                                        Get.toNamed(
                                          RouteHelper.getItemDetailsRoute(item),
                                          arguments: ItemDetailsScreen(product: item),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _confirmDelete(context, item),
                                    ),
                                  ],
                                ),
                                isLoading
                                    ? const SizedBox(
                                        width: 36,
                                        height: 24,
                                        child: Center(child: CupertinoActivityIndicator()),
                                      )
                                    : Row(
                                        children: [
                                          Text(
                                            'تفعيل'.tr,
                                            style: robotoMedium.copyWith(
                                              fontSize: Dimensions.fontSizeExtraSmall,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Transform.scale(
                                            scale: 0.75,
                                            child: CupertinoSwitch(
                                              value: false,
                                              activeColor: Colors.green,
                                              onChanged: (val) {
                                                storeController.updateItemStatusForProduct(item.id, val);
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
                  },
                ),
              ),
            );
          },
        ),
      ),
        ],
      ),
    );
  }
}
