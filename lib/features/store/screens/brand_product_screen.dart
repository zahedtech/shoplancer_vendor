import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/paginated_list_widget.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/features/store/screens/item_details_screen.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class BrandProductScreen extends StatefulWidget {
  final int brandId;
  final String brandName;

  const BrandProductScreen({
    super.key,
    required this.brandId,
    required this.brandName,
  });

  @override
  State<BrandProductScreen> createState() => _BrandProductScreenState();
}

class _BrandProductScreenState extends State<BrandProductScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<StoreController>().getBrandItemList(
        offset: '1',
        brandId: widget.brandId,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: widget.brandName),
      body: GetBuilder<StoreController>(
        builder: (storeController) {
          if (storeController.brandItemList == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Item> items = storeController.brandItemList!;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(
                    'لا توجد منتجات لهذه الماركة حالياً'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await storeController.getBrandItemList(
                offset: '1',
                brandId: widget.brandId,
              );
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: PaginatedListWidget(
                scrollController: _scrollController,
                totalSize: storeController.itemSize,
                offset: storeController.offset,
                onPaginate: (int? offset) async {
                  await storeController.getBrandItemList(
                    offset: offset?.toString() ?? '1',
                    brandId: widget.brandId,
                    willUpdate: false,
                  );
                },
                productView: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  itemCount: items.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final Item item = items[index];
                    final bool isActive = (item.status ?? 1) == 1;
                    final bool isLoading = storeController.loadingItemsList.contains(item.id);

                    return Dismissible(
                      key: Key('brand_product_${item.id}'),
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
                            color: isActive
                                ? Theme.of(context).disabledColor.withOpacity(0.12)
                                : Colors.red.withOpacity(0.3),
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
                                    width: 65,
                                    height: 65,
                                    fit: BoxFit.cover,
                                  ),
                                  if ((item.discount ?? 0) > 0)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.only(bottomRight: Radius.circular(6)),
                                        ),
                                        child: Text(
                                          '${item.discount}%',
                                          style: robotoBold.copyWith(color: Colors.white, fontSize: 9),
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

                            // Actions: Edit button & Switch
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                      onPressed: () {
                                        Get.toNamed(
                                          RouteHelper.getItemDetailsRoute(item),
                                          arguments: ItemDetailsScreen(product: item),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                      onPressed: () => _confirmDelete(context, item),
                                    ),
                                  ],
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
                                          value: isActive,
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
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
