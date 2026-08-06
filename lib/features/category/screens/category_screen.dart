import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/api/api_client.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/category/controllers/category_controller.dart';
import 'package:shoplancer_vendor/features/category/domain/models/category_model.dart';
import 'package:shoplancer_vendor/features/category/screens/category_product_screen.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/util/app_constants.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<CategoryController>().getCategoryList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'categories'.tr,
        menuWidget: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeExtraSmall,
          ),
          child: TextButton.icon(
            onPressed: () => _showGlobalCategoriesBottomSheet(context),
            icon: Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).primaryColor,
              size: 22,
            ),
            label: Text(
              'add_category'.tr,
              style: robotoMedium.copyWith(
                color: Theme.of(context).primaryColor,
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
        ),
      ),
      body: GetBuilder<CategoryController>(
        builder: (categoryController) {
          List<CategoryModel>? categories;
          if (categoryController.categoryList != null) {
            categories = [];
            categories.addAll(categoryController.categoryList!);
          }

          return categories != null
              ? categories.isNotEmpty
                    ? RefreshIndicator(
                        onRefresh: () async {
                          await Get.find<CategoryController>()
                              .getCategoryList();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeDefault,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories![index];
                            final bool isActive = (category.status ?? 1) == 1;

                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusDefault,
                                ),
                                border: Border.all(
                                  color: isActive
                                      ? Theme.of(
                                          context,
                                        ).disabledColor.withOpacity(0.2)
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
                              padding: const EdgeInsets.all(
                                Dimensions.paddingSizeSmall,
                              ),
                              child: InkWell(
                                onTap: () {
                                  Get.to(
                                    () => CategoryProductScreen(
                                      categoryId: category.id!,
                                      categoryName: category.name ?? '',
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusSmall,
                                      ),
                                      child: CustomImageWidget(
                                        image: '${category.imageFullUrl}',
                                        height: 65,
                                        width: 65,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: Dimensions.paddingSizeSmall,
                                    ),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  category.name ?? '',
                                                  style: robotoBold.copyWith(
                                                    color: isActive
                                                        ? Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.color
                                                        : Theme.of(
                                                            context,
                                                          ).disabledColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!isActive)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          Dimensions
                                                              .radiusSmall,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'متوقفة',
                                                    style: robotoRegular
                                                        .copyWith(
                                                          fontSize: 10,
                                                          color: Colors.red,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraSmall,
                                          ),

                                          Row(
                                            children: [
                                              Text(
                                                '${'id'.tr}: #${category.id}',
                                                style: robotoRegular.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  color: Theme.of(
                                                    context,
                                                  ).disabledColor,
                                                ),
                                              ),
                                              const SizedBox(
                                                width:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 2,
                                                      horizontal: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .disabledColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions.radiusSmall,
                                                      ),
                                                ),
                                                child: Text(
                                                  '${category.productsCount ?? 0} ${'items'.tr}',
                                                  style: robotoRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeExtraSmall,
                                                    color: Theme.of(
                                                      context,
                                                    ).disabledColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Switch for Category Active/Deactive control
                                    Switch(
                                      value: isActive,
                                      activeColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      onChanged: (bool val) {
                                        categoryController.updateCategoryStatus(
                                          category.id!,
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
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('no_category_found'.tr, style: robotoMedium),
                            const SizedBox(
                              height: Dimensions.paddingSizeDefault,
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showGlobalCategoriesBottomSheet(context),
                              icon: const Icon(Icons.add),
                              label: Text('add_category'.tr),
                            ),
                          ],
                        ),
                      )
              : const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _showGlobalCategoriesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GlobalCategorySelectionSheet(),
    );
  }
}

class _GlobalCategorySelectionSheet extends StatefulWidget {
  const _GlobalCategorySelectionSheet();

  @override
  State<_GlobalCategorySelectionSheet> createState() =>
      _GlobalCategorySelectionSheetState();
}

class _GlobalCategorySelectionSheetState
    extends State<_GlobalCategorySelectionSheet> {
  List<CategoryModel>? _globalCategories;
  List<CategoryModel>? _filteredCategories;
  bool _isLoading = true;
  // null = no request, -1 = custom category request, otherwise = category id
  int? _requestingId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGlobalCategories();
  }

  Future<void> _sendRequest({
    int? categoryId,
    String? customCategoryName,
    String? note,
  }) async {
    final requestingId = categoryId ?? -1;
    if (_requestingId != null) return;
    setState(() => _requestingId = requestingId);
    final bool success = await Get.find<CategoryController>()
        .requestCategoryAddition(
          categoryId: categoryId,
          customCategoryName: customCategoryName,
          note: note,
        );
    if (mounted) {
      setState(() => _requestingId = null);
      if (success) Get.back();
    }
  }

  Future<void> _fetchGlobalCategories() async {
    try {
      final profileModel = Get.find<ProfileController>().profileModel;
      final store = profileModel?.stores?[0];
      final int? moduleId = store?.module?.id;
      final int? zoneId = store?.zoneId;

      final Map<String, String> headers = {
        'X-localization': Get.locale?.languageCode ?? 'ar',
        'zoneId': zoneId != null ? '[$zoneId]' : '[1]',
        'moduleId': moduleId != null ? moduleId.toString() : '3',
      };

      final Response response = await Get.find<ApiClient>().getData(
        AppConstants.globalCategoryUri,
        headers: headers,
      );

      if (response.statusCode == 200 && response.body != null) {
        final List<dynamic> body = response.body is List
            ? response.body
            : jsonDecode(response.body);

        final vendorCategories = Get.find<CategoryController>().categoryList;

        final Set<int> existingIds =
            vendorCategories?.map((e) => e.id).whereType<int>().toSet() ?? {};

        final Set<String> existingNames =
            vendorCategories
                ?.map((e) => (e.name ?? '').trim().toLowerCase())
                .where((name) => name.isNotEmpty)
                .toSet() ??
            {};

        final List<CategoryModel> categories = [];
        for (var json in body) {
          final cat = CategoryModel.fromJson(json);
          final String catName = (cat.name ?? '').trim().toLowerCase();

          final bool isExisting =
              (cat.id != null && existingIds.contains(cat.id)) ||
              (catName.isNotEmpty && existingNames.contains(catName));

          if (!isExisting) {
            categories.add(cat);
          }
        }

        setState(() {
          _globalCategories = categories;
          _filteredCategories = categories;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching global categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCategories(String query) {
    if (_globalCategories == null) return;
    if (query.trim().isEmpty) {
      setState(() {
        _filteredCategories = _globalCategories;
      });
    } else {
      final q = query.trim().toLowerCase();
      setState(() {
        _filteredCategories = _globalCategories!.where((cat) {
          final matchesMain = (cat.name ?? '').toLowerCase().contains(q);
          final matchesChild =
              cat.childes?.any(
                (child) => (child.name ?? '').toLowerCase().contains(q),
              ) ??
              false;
          return matchesMain || matchesChild;
        }).toList();
      });
    }
  }

  void _showCustomCategoryRequestDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('طلب إضافة فئة خاصة للأدمن', style: robotoBold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفئة الجديدة *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات للأدمن (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                showCustomSnackBar('يرجى إدخال اسم الفئة المطلوبة');
                return;
              }
              Get.back();
              _sendRequest(
                customCategoryName: nameController.text.trim(),
                note: noteController.text.trim(),
              );
            },
            child: const Text('إرسال الطلب'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'معرض الفئات العامة',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'اختر فئة لإرسال طلب إضافتها إلى الأدمن لمتجرك',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCategories,
              decoration: InputDecoration(
                hintText: 'ابحث عن فئة...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Categories List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCategories != null && _filteredCategories!.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                    ),
                    itemCount: _filteredCategories!.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories![index];
                      final hasChildren =
                          category.childes != null &&
                          category.childes!.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: Dimensions.paddingSizeSmall,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSmall,
                          ),
                        ),
                        child: hasChildren
                            ? ExpansionTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall,
                                  ),
                                  child: CustomImageWidget(
                                    image: '${category.imageFullUrl}',
                                    height: 45,
                                    width: 45,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  category.name ?? '',
                                  style: robotoMedium,
                                ),
                                subtitle: Text(
                                  '#${category.id} • (${category.childes!.length} فئات فرعية)',
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                                trailing: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusSmall,
                                      ),
                                    ),
                                  ),
                                  onPressed: _requestingId != null
                                      ? null
                                      : () => _sendRequest(
                                          categoryId: category.id,
                                        ),
                                  icon: _requestingId == category.id
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.send, size: 14),
                                  label: Text(
                                    _requestingId == category.id
                                        ? 'جاري الإرسال...'
                                        : 'طلب إضافة الفئة',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                children: category.childes!.map((child) {
                                  return Container(
                                    color: Theme.of(
                                      context,
                                    ).disabledColor.withOpacity(0.04),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.only(
                                        right: 60,
                                        left: 16,
                                      ),
                                      title: Text(
                                        child.name ?? '',
                                        style: robotoRegular.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '#${child.id}',
                                        style: robotoRegular.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          color: Theme.of(
                                            context,
                                          ).disabledColor,
                                        ),
                                      ),
                                      trailing: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              Dimensions.radiusSmall,
                                            ),
                                          ),
                                        ),
                                        onPressed: _requestingId != null
                                            ? null
                                            : () => _sendRequest(
                                                categoryId: child.id,
                                              ),
                                        icon: _requestingId == child.id
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.subdirectory_arrow_right,
                                                size: 14,
                                              ),
                                        label: Text(
                                          _requestingId == child.id
                                              ? 'جاري...'
                                              : 'طلب الفرعية',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            : ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall,
                                  ),
                                  child: CustomImageWidget(
                                    image: '${category.imageFullUrl}',
                                    height: 45,
                                    width: 45,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  category.name ?? '',
                                  style: robotoMedium,
                                ),
                                subtitle: Text(
                                  '#${category.id}',
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                                trailing: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusSmall,
                                      ),
                                    ),
                                  ),
                                  onPressed: _requestingId != null
                                      ? null
                                      : () => _sendRequest(
                                          categoryId: category.id,
                                        ),
                                  icon: _requestingId == category.id
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.send, size: 14),
                                  label: Text(
                                    _requestingId == category.id
                                        ? 'جاري الإرسال...'
                                        : 'طلب إضافة',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'لم يتم العثور على فئات عامة',
                      style: robotoRegular.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
          ),

          // Bottom Bar for Custom Category Request
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCustomCategoryRequestDialog();
                },
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('طلب إضافة فئة جديدة'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
