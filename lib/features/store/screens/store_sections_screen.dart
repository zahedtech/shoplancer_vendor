import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
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
  @override
  void initState() {
    super.initState();
    Get.find<StoreController>().getStoreSections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'ترتيب سكاشن المتجر على الويب'.tr,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: GetBuilder<StoreController>(
          builder: (storeController) {
            return CustomButtonWidget(
              isLoading: storeController.isLoading,
              buttonText: 'حفظ الترتيب والإعدادات'.tr,
              onPressed: () {
                storeController.saveStoreSections();
              },
            );
          },
        ),
      ),
      body: GetBuilder<StoreController>(
        builder: (storeController) {
          if (storeController.isLoading && storeController.storeSectionList == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final sections = storeController.storeSectionList ?? [];

          if (sections.isEmpty) {
            return Center(
              child: Text('لا توجد سكاشن متاحة للترتيب'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يمكنك سحب وإفلات السكاشن لإعادة ترتيبها، وتفعيلها أو إخفائها وتعديل مسمياتها للعملاء.',
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  itemCount: sections.length,
                  onReorder: (oldIndex, newIndex) {
                    storeController.reorderStoreSections(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final StoreSectionModel section = sections[index];
                    final bool isActive = section.isActive == 1;

                    return Card(
                      key: ValueKey(section.sectionKey ?? '$index'),
                      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                      elevation: 2,
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: Icon(Icons.drag_handle, color: Theme.of(context).disabledColor),
                        ),
                        title: Text(
                          section.customName ?? section.defaultName ?? '',
                          style: robotoBold.copyWith(
                            color: isActive ? null : Theme.of(context).disabledColor,
                          ),
                        ),
                        subtitle: Text(
                          'السكشن الافتراضي: ${section.defaultName ?? ''}',
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              onPressed: () {
                                _showEditTitleDialog(context, storeController, index, section);
                              },
                            ),
                            Switch(
                              value: isActive,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (bool value) {
                                storeController.toggleStoreSectionActive(index, value);
                              },
                            ),
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

  void _showEditTitleDialog(
    BuildContext context,
    StoreController storeController,
    int index,
    StoreSectionModel section,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: section.customName ?? section.defaultName ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: Text('تعديل مسمى السكشن'.tr, style: robotoBold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الاسم الظاهر للعملاء:'.tr, style: robotoRegular),
            const SizedBox(height: 6),
            CustomTextFieldWidget(
              controller: nameController,
              hintText: 'أدخل اسم السكشن'.tr,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                storeController.updateStoreSectionCustomName(index, nameController.text.trim());
              }
              Get.back();
            },
            child: Text('حفظ'.tr),
          ),
        ],
      ),
    );
  }
}
