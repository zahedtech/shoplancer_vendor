import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/features/category/controllers/category_controller.dart';
import 'package:shoplancer_vendor/features/category/domain/models/category_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class SubCategoryScreen extends StatefulWidget {
  final CategoryModel parentCategory;

  const SubCategoryScreen({super.key, required this.parentCategory});

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<CategoryController>().clearSubCategoryList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.parentCategory.id != null) {
        Get.find<CategoryController>().getSubCategoryList(
          widget.parentCategory.id!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: '${widget.parentCategory.name ?? 'الفئات الفرعية'}',
      ),
      body: GetBuilder<CategoryController>(
        builder: (categoryController) {
          if (categoryController.subCategoryList == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<CategoryModel> subCategories =
              categoryController.subCategoryList!;

          if (subCategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(
                    'لا توجد فئات فرعية لهذه الفئة'.tr,
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
              if (widget.parentCategory.id != null) {
                await categoryController.getSubCategoryList(
                  widget.parentCategory.id!,
                );
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              itemCount: subCategories.length,
              itemBuilder: (context, index) {
                final subCategory = subCategories[index];
                final bool isActive = (subCategory.status ?? 1) == 1;

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
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
                  margin: const EdgeInsets.only(
                    bottom: Dimensions.paddingSizeSmall,
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Row(
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSmall,
                          ),
                        ),
                        child: Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 24,
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
                                    subCategory.name ?? '',
                                    style: robotoBold.copyWith(
                                      color: isActive
                                          ? Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color
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
                            const SizedBox(
                              height: Dimensions.paddingSizeExtraSmall,
                            ),

                            Row(
                              children: [
                                Text(
                                  '${'id'.tr}: #${subCategory.id}',
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                                if (subCategory.productsCount != null &&
                                    subCategory.productsCount! > 0) ...[
                                  const SizedBox(
                                    width: Dimensions.paddingSizeSmall,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).disabledColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusSmall,
                                      ),
                                    ),
                                    child: Text(
                                      '${subCategory.productsCount} ${'items'.tr}',
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

                      // Switch for SubCategory Active/Inactive toggle
                      Switch(
                        value: isActive,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (bool val) {
                          categoryController.updateCategoryStatus(
                            subCategory.id!,
                            val ? 1 : 0,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
