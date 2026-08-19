import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/paginated_list_widget.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/band_model.dart';
import 'package:shoplancer_vendor/features/store/screens/brand_product_screen.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<StoreController>().getBrandList('1', null);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'الماركات / البراندات'.tr),
      body: GetBuilder<StoreController>(
        builder: (storeController) {
          final List<BrandModel>? brands = storeController.brandList;

          if (brands == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (brands.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.branding_watermark_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(
                    'لا توجد ماركات متاحة حالياً'.tr,
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
              await storeController.getBrandList('1', null);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: PaginatedListWidget(
                scrollController: _scrollController,
                totalSize: storeController.brandSize,
                offset: storeController.brandOffset,
                onPaginate: (int? offset) async {
                  await storeController.getBrandList(offset?.toString() ?? '1', null);
                },
                productView: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final BrandModel brand = brands[index];
                    final bool isActive = (brand.status ?? 1) == 1;

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(
                          color: isActive
                              ? Theme.of(context).disabledColor.withOpacity(0.2)
                              : Colors.red.withOpacity(0.3),
                          width: isActive ? 0.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Get.isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: InkWell(
                        onTap: () {
                          Get.to(
                            () => BrandProductScreen(
                              brandId: brand.id!,
                              brandName: brand.name ?? '',
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              child: CustomImageWidget(
                                image: '${brand.imageFullUrl}',
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          brand.name ?? '',
                                          style: robotoBold.copyWith(
                                            color: isActive
                                                ? Theme.of(context).textTheme.bodyLarge?.color
                                                : Theme.of(context).disabledColor,
                                            fontSize: Dimensions.fontSizeDefault,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              Dimensions.radiusSmall,
                                            ),
                                          ),
                                          child: Text(
                                            'متوقفة',
                                            style: robotoRegular.copyWith(
                                              fontSize: 10,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                                  Row(
                                    children: [
                                      Text(
                                        '${'id'.tr}: #${brand.id}',
                                        style: robotoRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context).disabledColor,
                                        ),
                                      ),
                                      if (brand.itemsCount != null && brand.itemsCount! > 0) ...[
                                        const SizedBox(width: Dimensions.paddingSizeSmall),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).disabledColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                          ),
                                          child: Text(
                                            '${brand.itemsCount} ${'items'.tr}',
                                            style: robotoRegular.copyWith(
                                              fontSize: Dimensions.fontSizeExtraSmall,
                                              color: Theme.of(context).disabledColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Switch for Brand Active/Inactive toggle
                            Switch(
                              value: isActive,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (bool val) {
                                storeController.updateBrandStatus(
                                  brand.id!,
                                  val ? 1 : 0,
                                );
                              },
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
