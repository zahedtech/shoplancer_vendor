import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/store_section_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class StoreSectionsScreen extends StatefulWidget {
  const StoreSectionsScreen({super.key});

  @override
  State<StoreSectionsScreen> createState() => _StoreSectionsScreenState();
}

class _StoreSectionsScreenState extends State<StoreSectionsScreen> {
  // Keep track of which section's categories are expanded
  final Map<int, bool> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    Get.find<StoreController>().getStoreSections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'إدارة اقسام المتجر'.tr,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: GetBuilder<StoreController>(
          builder: (storeController) {
            return CustomButtonWidget(
              isLoading: storeController.isSectionSaving,
              loadingText: 'جاري حفظ الترتيب...'.tr,
              buttonText: 'حفظ الترتيب والتفعيل'.tr,
              icon: Icons.check_circle_outline_rounded,
              onPressed: () {
                storeController.saveStoreSections();
              },
            );
          },
        ),
      ),
      body: GetBuilder<StoreController>(
        builder: (storeController) {
          if (storeController.isSectionLoading ||
              storeController.storeSectionList == null) {
            return _buildShimmer(context);
          }

          final sections = storeController.storeSectionList ?? [];

          if (sections.isEmpty) {
            return Center(
              child: Text(
                'لا توجد سكاشن متاحة'.tr,
                style: robotoRegular.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
              ),
            );
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusDefault),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Text(
                        'يمكنك سحب وإفلات السكاشن أو الأقسام بداخلها لإعادة ترتيب ظهورها، وتفعيل أو إخفاء أي سكشن وقسم بسهولة.'
                            .tr,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  itemCount: sections.length,
                  onReorder: (oldIndex, newIndex) {
                    storeController.reorderStoreSections(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final StoreSectionModel section = sections[index];
                    final bool isActive = section.isActive == 1;
                    final bool hasCategories = section.categories != null &&
                        section.categories!.isNotEmpty;
                    final bool isExpanded =
                        _expandedSections[section.id ?? index] ?? true;

                    return Card(
                      key: ValueKey(
                        section.id ?? section.sectionKey ?? '$index',
                      ),
                      margin: const EdgeInsets.only(
                        bottom: Dimensions.paddingSizeSmall,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusDefault),
                        side: BorderSide(
                          color: isActive
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : Theme.of(context)
                                  .disabledColor
                                  .withOpacity(0.2),
                        ),
                      ),
                      elevation: isActive ? 1.5 : 0.5,
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeSmall,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Main Section Row
                            Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeSmall,
                                      vertical: Dimensions.paddingSizeSmall,
                                    ),
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      color: Theme.of(context).hintColor,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: Dimensions.paddingSizeExtraSmall,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        section.name ?? '',
                                        style: robotoMedium.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          color: isActive
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color
                                              : Theme.of(context).disabledColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isActive
                                            ? 'مفعل ومتاح في المتجر'.tr
                                            : 'معطل ومخفي من المتجر'.tr,
                                        style: robotoRegular.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          color: isActive
                                              ? Colors.green
                                              : Theme.of(context).disabledColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasCategories)
                                  IconButton(
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    tooltip: isExpanded
                                        ? 'إخفاء الأقسام'.tr
                                        : 'عرض الأقسام'.tr,
                                    onPressed: () {
                                      setState(() {
                                        _expandedSections[
                                                section.id ?? index] =
                                            !isExpanded;
                                      });
                                    },
                                  ),
                                Switch(
                                  value: isActive,
                                  activeColor: Theme.of(context).primaryColor,
                                  onChanged: (bool value) {
                                    storeController.toggleStoreSectionActive(
                                      index,
                                      value,
                                    );
                                  },
                                ),
                              ],
                            ),

                            // Categories Sub-List (Reorderable and Toggleable)
                            if (hasCategories && isExpanded) ...[
                              const Divider(height: 16, thickness: 0.8),
                              _buildCategoriesList(
                                context,
                                storeController,
                                index,
                                section,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoriesList(
    BuildContext context,
    StoreController storeController,
    int sectionIndex,
    StoreSectionModel section,
  ) {
    final List<SectionCategoryModel> categories = section.categories ?? [];
    final int activeCount =
        categories.where((c) => c.isActive == 1).length;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text(
                    'أقسام هذا السكشن'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeCount/${categories.length} ${'مفعل'.tr}',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            onReorder: (oldCatIndex, newCatIndex) {
              storeController.reorderSectionCategories(
                sectionIndex,
                oldCatIndex,
                newCatIndex,
              );
            },
            itemBuilder: (context, catIndex) {
              final cat = categories[catIndex];
              final bool isCatActive = cat.isActive == 1;

              return Container(
                key: ValueKey(cat.id ?? catIndex),
                margin: const EdgeInsets.only(
                  bottom: Dimensions.paddingSizeExtraSmall,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeExtraSmall,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusSmall),
                  border: Border.all(
                    color: isCatActive
                        ? Theme.of(context).primaryColor.withOpacity(0.15)
                        : Theme.of(context).disabledColor.withOpacity(0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: catIndex,
                      child: Padding(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeExtraSmall,
                        ),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          size: 20,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    if (cat.imageFullUrl != null &&
                        cat.imageFullUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSmall),
                        child: CustomImageWidget(
                          image: cat.imageFullUrl ?? '',
                          height: 32,
                          width: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat.name ?? '',
                            style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: isCatActive
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                  : Theme.of(context).disabledColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCatActive ? 'مفعل'.tr : 'معطل'.tr,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: isCatActive
                                  ? Colors.green
                                  : Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: isCatActive,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (bool value) {
                          storeController.toggleSectionCategoryActive(
                            sectionIndex,
                            catIndex,
                            value,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Column(
      children: [
        // Info Banner Shimmer
        Container(
          margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Shimmer(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Theme.of(context).shadowColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer(
                      child: Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).shadowColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Shimmer(
                      child: Container(
                        height: 12,
                        width: 180,
                        decoration: BoxDecoration(
                          color: Theme.of(context).shadowColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Section Cards Shimmer
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
            ),
            itemCount: 5,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(
                  bottom: Dimensions.paddingSizeSmall,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeDefault,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusDefault),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Shimmer(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(context).shadowColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer(
                            child: Container(
                              height: 15,
                              width: 130 + (index % 3) * 30.0,
                              decoration: BoxDecoration(
                                color: Theme.of(context).shadowColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Shimmer(
                            child: Container(
                              height: 10,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).shadowColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Shimmer(
                      child: Container(
                        width: 44,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).shadowColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
