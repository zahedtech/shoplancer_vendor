import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/common/widgets/paginated_list_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/category/controllers/category_controller.dart';
import 'package:shoplancer_vendor/features/pos/controllers/pos_controller.dart';
import 'package:shoplancer_vendor/features/pos/widgets/pos_cart_bottom_sheet.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MobileScannerController _scannerController = MobileScannerController();
  int? _selectedCategoryId;
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
    Get.find<StoreController>().getItemList(
      offset: '1',
      type: 'all',
      search: '',
    );
    Get.find<CategoryController>().getCategoryList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcodeScanned(String barcode) {
    final storeController = Get.find<StoreController>();
    if (storeController.itemList == null) return;

    Item? foundItem = storeController.itemList!.firstWhereOrNull(
      (item) =>
          item.id.toString() == barcode ||
          (item.name != null && item.name!.contains(barcode)),
    );

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

  void _fetchItems({String? offset}) {
    Get.find<StoreController>().getItemList(
      offset: offset ?? '1',
      type: 'all',
      search: _searchController.text.trim(),
      categoryId: _selectedCategoryId,
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
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 26),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    _openCartSheet(context);
                  },
                ),
                if (posController.cartList.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${posController.cartList.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: CustomTextFieldWidget(
              controller: _searchController,
              hintText: 'ابحث عن منتج بالاسم...'.tr,
              prefixIcon: Icons.search,
              suffixChild: IconButton(
                icon: Icon(
                  Icons.qr_code_scanner,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _showScanner = !_showScanner;
                  });
                },
              ),
              onChanged: (val) {
                _fetchItems(offset: '1');
              },
            ),
          ),

          // Barcode Scanner inline view
          if (_showScanner)
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
              ),
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
          if (_showScanner) const SizedBox(height: Dimensions.paddingSizeSmall),

          // Categories Horizontal Scroll
          GetBuilder<CategoryController>(
            builder: (categoryController) {
              if (categoryController.categoryList == null)
                return const SizedBox();
              return SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                  ),
                  itemCount: categoryController.categoryList!.length + 1,
                  itemBuilder: (context, index) {
                    bool isAll = index == 0;
                    final category = isAll
                        ? null
                        : categoryController.categoryList![index - 1];
                    bool isSelected = isAll
                        ? (_selectedCategoryId == null)
                        : (_selectedCategoryId == category?.id);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          isAll ? 'الكل'.tr : (category?.name ?? ''),
                          style: robotoMedium.copyWith(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Theme.of(context).primaryColor,
                        onSelected: (val) {
                          setState(() {
                            _selectedCategoryId = isAll ? null : category?.id;
                          });
                          _fetchItems(offset: '1');
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Items Grid List with Pagination
          Expanded(
            child: GetBuilder<StoreController>(
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
                return SingleChildScrollView(
                  controller: _scrollController,
                  child: PaginatedListWidget(
                    scrollController: _scrollController,
                    totalSize: storeController.itemSize,
                    offset: storeController.offset,
                    onPaginate: (int? offset) async {
                      _fetchItems(offset: offset?.toString());
                    },
                    productView: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall,
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final Item item = items[index];

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusSmall,
                              ),
                            ),
                            elevation: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(
                                        Dimensions.radiusSmall,
                                      ),
                                    ),
                                    child: CustomImageWidget(
                                      image: item.imageFullUrl ?? '',
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name ?? '',
                                        style: robotoMedium.copyWith(
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${item.price ?? 0} ج.م',
                                            style: robotoBold.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                          GetBuilder<PosController>(
                                            builder: (posController) {
                                              return InkWell(
                                                onTap: () {
                                                  posController.addToCart(item);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom Cart summary inside Column
          GetBuilder<PosController>(
            builder: (posController) {
              if (posController.cartList.isEmpty) return const SizedBox();
              return Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
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
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusSmall,
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
                            'عرض السلة والمتابعة'.tr,
                            style: robotoBold.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      Text(
                        '${posController.grandTotal.toStringAsFixed(2)} ج.م',
                        style: robotoBold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
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
