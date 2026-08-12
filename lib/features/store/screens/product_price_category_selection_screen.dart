import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/features/category/controllers/category_controller.dart';
import 'package:shoplancer_vendor/features/category/domain/models/category_model.dart';
import 'package:shoplancer_vendor/features/store/screens/product_price_management_screen.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

/// Shown before entering the price editor so the vendor can pick which
/// category's items they want to edit prices for (or edit all products).
class ProductPriceCategorySelectionScreen extends StatefulWidget {
  const ProductPriceCategorySelectionScreen({super.key});

  @override
  State<ProductPriceCategorySelectionScreen> createState() =>
      _ProductPriceCategorySelectionScreenState();
}

class _ProductPriceCategorySelectionScreenState
    extends State<ProductPriceCategorySelectionScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<CategoryController>().getCategoryList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'اختر الفئة لتعديل أسعارها'),
      body: GetBuilder<CategoryController>(
        builder: (categoryController) {
          final List<CategoryModel>? categories =
              categoryController.categoryList;

          if (categories == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Get.find<CategoryController>().getCategoryList();
            },
            child: ListView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              children: [
                _buildAllProductsCard(context),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSizeLarge,
                    ),
                    child: Center(
                      child: Text('no_category_found'.tr, style: robotoMedium),
                    ),
                  )
                else
                  ...categories.map(
                    (category) => _buildCategoryCard(context, category),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllProductsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        onTap: () => Get.to(() => const ProductPriceManagementScreen()),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Row(
            children: [
              Container(
                height: 55,
                width: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'all_items'.tr,
                      style: robotoBold.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'عرض كل المنتجات بدون تصفية بفئة معيّنة',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    final bool isActive = (category.status ?? 1) == 1;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).disabledColor.withOpacity(0.2),
          width: 0.5,
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
            () => ProductPriceManagementScreen(
              initialCategoryId: category.id,
              initialCategoryName: category.name,
            ),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImageWidget(
                image: '${category.imageFullUrl}',
                height: 55,
                width: 55,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name ?? '',
                    style: robotoBold.copyWith(
                      color: isActive
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).disabledColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusSmall,
                      ),
                    ),
                    child: Text(
                      '${category.productsCount ?? 0} ${'items'.tr}',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Theme.of(context).disabledColor,
            ),
          ],
        ),
      ),
    );
  }
}
