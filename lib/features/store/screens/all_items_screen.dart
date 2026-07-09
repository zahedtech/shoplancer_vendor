import 'package:flutter/cupertino.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/item_shimmer_widget.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/helper/date_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/store/widgets/item_view_widget.dart';
import 'package:shoplancer_vendor/features/chat/widgets/search_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/filter_popup_widget.dart';

class AllItemsScreen extends StatefulWidget {
  const AllItemsScreen({super.key});

  @override
  State<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends State<AllItemsScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final StoreController storeController = Get.find<StoreController>();
    Get.find<ProfileController>().getProfile();
    int? moduleId =
        Get.find<ProfileController>().profileModel?.stores?[0].module?.id;
    storeController.getItemList(
      offset: '1',
      type: 'all',
      search: '',
      categoryId: 0,
      willUpdate: false,
      moduleId: moduleId,
    );
    storeController.getStoreCategories();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          storeController.itemList != null &&
          !storeController.isLoading) {
        final int totalItems = storeController.itemSize ?? 0;
        if (totalItems == 0) return;
        final int pageSize = (totalItems / 10).ceil();
        if (storeController.offset < pageSize) {
          storeController.setOffset(storeController.offset + 1);
          storeController.showBottomLoader();
          storeController.getItemList(
            offset: storeController.offset.toString(),
            type: storeController.type,
            search: _searchController.text.trim(),
            categoryId: storeController.categoryId,
            moduleId: moduleId,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        return GetBuilder<ProfileController>(
          builder: (profileController) {
            Store? store = profileController.profileModel != null
                ? profileController.profileModel!.stores![0]
                : null;
            bool isShowingTrialContent =
                profileController.profileModel != null &&
                profileController.profileModel!.subscription != null &&
                profileController.profileModel!.subscription!.isTrial == 1 &&
                DateConverterHelper.differenceInDaysIgnoringTime(
                      DateTime.parse(
                        profileController
                            .profileModel!
                            .subscription!
                            .expiryDate!,
                      ),
                      null,
                    ) >
                    0;

            return PopScope(
              canPop: true,
              onPopInvoked: (bool didPop) {
                if (didPop) {
                  // Reset filters when navigating back
                  storeController.resetFilters();
                }
              },
              child: Scaffold(
                appBar: CustomAppBarWidget(
                  title: storeController.isSelectionMode
                      ? '${storeController.selectedItemList.length} ${'selected'.tr}'
                      : 'all_items'.tr,
                  leadingWidget: storeController.isSelectionMode
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => storeController.clearSelection(),
                        )
                      : null,
                  menuWidget: storeController.isSelectionMode
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.select_all),
                              onPressed: () => storeController.selectAllItems(),
                              tooltip: 'select_all'.tr,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note, size: 30),
                              onPressed: () {
                                final List<Item> selectedItems = storeController
                                    .itemList!
                                    .where(
                                      (item) => storeController.selectedItemList
                                          .contains(item.id),
                                    )
                                    .toList();

                                final Map<int, TextEditingController>
                                priceControllers = {};
                                final Map<int, TextEditingController>
                                stockControllers = {};

                                for (var item in selectedItems) {
                                  priceControllers[item.id!] =
                                      TextEditingController(
                                        text: item.price.toString(),
                                      );
                                  stockControllers[item.id!] =
                                      TextEditingController(
                                        text: item.stock.toString(),
                                      );
                                }

                                Get.dialog(
                                  AlertDialog(
                                    title: Text('bulk_update'.tr),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: selectedItems.length,
                                        itemBuilder: (context, index) {
                                          final item = selectedItems[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom:
                                                  Dimensions.paddingSizeDefault,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name ?? '',
                                                  style: robotoMedium,
                                                ),
                                                const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeExtraSmall,
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            priceControllers[item
                                                                .id!],
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        decoration: InputDecoration(
                                                          labelText: 'price'.tr,
                                                          isDense: true,
                                                          border:
                                                              const OutlineInputBorder(),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeSmall,
                                                    ),
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            stockControllers[item
                                                                .id!],
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        decoration: InputDecoration(
                                                          labelText: 'stock'.tr,
                                                          isDense: true,
                                                          border:
                                                              const OutlineInputBorder(),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Get.back(),
                                        child: Text('cancel'.tr),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          List<Map<String, String>> updates =
                                              [];
                                          for (var item in selectedItems) {
                                            double? newPrice = double.tryParse(
                                              priceControllers[item.id!]!.text,
                                            );
                                            int? newStock = int.tryParse(
                                              stockControllers[item.id!]!.text,
                                            );

                                            if (newPrice != null ||
                                                newStock != null) {
                                              updates.add(
                                                storeController
                                                    .buildStockUpdateData(
                                                      item,
                                                      price: newPrice,
                                                      stock: newStock,
                                                    ),
                                              );
                                            }
                                          }
                                          if (updates.isNotEmpty) {
                                            Get.back();
                                            storeController.bulkItemsUpdate(
                                              updates,
                                            );
                                          }
                                        },
                                        child: Text('update'.tr),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              tooltip: 'bulk_update'.tr,
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: Theme.of(context).primaryColor,
                                size: 27,
                              ),
                              onPressed: () => Get.toNamed(
                                RouteHelper.getAddItemRoute(
                                  null,
                                  isSimple: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                body: store != null
                    ? CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Top Header Text
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                Dimensions.paddingSizeDefault,
                                Dimensions.paddingSizeDefault,
                                Dimensions.paddingSizeDefault,
                                0,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    'add_missing_store_item_title'.tr,
                                    textAlign: TextAlign.right,
                                    style: robotoMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Sticky Category Header
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: SliverDelegate(
                              height: 60,
                              child: Container(
                                color: Theme.of(context).cardColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                  vertical: Dimensions.paddingSizeSmall,
                                ),
                                child: _buildCategory(storeController),
                              ),
                            ),
                          ),

                          // Filters, Search and Items
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Spacer(),
                                      (store.module?.moduleType == 'food' &&
                                              Get.find<SplashController>()
                                                  .configModel!
                                                  .toggleVegNonVeg! &&
                                              Get.find<SplashController>()
                                                  .configModel!
                                                  .moduleConfig!
                                                  .module!
                                                  .vegNonVeg!)
                                          ? GestureDetector(
                                              onTapDown: (details) {
                                                showFilterPopup(
                                                  context: context,
                                                  offset:
                                                      details.globalPosition,
                                                  selectedType:
                                                      storeController.type,
                                                  onSelected: (val) {
                                                    storeController.setType(
                                                      val,
                                                    );
                                                    int? moduleId =
                                                        Get.find<
                                                              ProfileController
                                                            >()
                                                            .profileModel
                                                            ?.stores?[0]
                                                            .module
                                                            ?.id;
                                                    storeController.getItemList(
                                                      offset: '1',
                                                      type: val,
                                                      search: '',
                                                      categoryId:
                                                          storeController
                                                              .categoryId,
                                                      moduleId: moduleId,
                                                    );
                                                  },
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  Dimensions
                                                      .paddingSizeExtraSmall,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions.radiusSmall,
                                                      ),
                                                  border: Border.all(
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.filter_list,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  size: 18,
                                                ),
                                              ),
                                            )
                                          : const SizedBox(),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: Dimensions.paddingSizeSmall,
                                  ),

                                  SizedBox(
                                    height: 50,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: SearchFieldWidget(
                                        fromReview: true,
                                        controller: _searchController,
                                        hint: '${'search_by_item_name'.tr}...',
                                        suffixIcon: storeController.isSearching
                                            ? CupertinoIcons.clear_thick
                                            : CupertinoIcons.search,
                                        iconPressed: () {
                                          if (!storeController.isSearching) {
                                            if (_searchController.text
                                                .trim()
                                                .isNotEmpty) {
                                              storeController
                                                  .setCategoryForSearch(
                                                    index: 0,
                                                  );
                                              _categoryScrollController
                                                  .animateTo(
                                                    0,
                                                    duration: const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                    curve: Curves.easeIn,
                                                  );
                                              int? moduleId =
                                                  Get.find<ProfileController>()
                                                      .profileModel
                                                      ?.stores?[0]
                                                      .module
                                                      ?.id;
                                              storeController.getItemList(
                                                offset: '1',
                                                type: 'all',
                                                search: _searchController.text
                                                    .trim(),
                                                categoryId: 0,
                                                moduleId: moduleId,
                                              );
                                            } else {
                                              showCustomSnackBar(
                                                'write_item_name_for_search'.tr,
                                              );
                                            }
                                          } else {
                                            _searchController.clear();
                                            storeController
                                                .setCategoryForSearch(index: 0);
                                            _categoryScrollController.animateTo(
                                              0,
                                              duration: const Duration(
                                                milliseconds: 500,
                                              ),
                                              curve: Curves.easeIn,
                                            );
                                            int? moduleId =
                                                Get.find<ProfileController>()
                                                    .profileModel
                                                    ?.stores?[0]
                                                    .module
                                                    ?.id;
                                            storeController.getItemList(
                                              offset: '1',
                                              type: 'all',
                                              search: '',
                                              categoryId: 0,
                                              moduleId: moduleId,
                                            );
                                          }
                                        },
                                        onSubmit: (String text) {
                                          if (_searchController.text
                                              .trim()
                                              .isNotEmpty) {
                                            storeController
                                                .setCategoryForSearch(index: 0);
                                            _categoryScrollController.animateTo(
                                              0,
                                              duration: const Duration(
                                                milliseconds: 500,
                                              ),
                                              curve: Curves.easeIn,
                                            );
                                            int? moduleId =
                                                Get.find<ProfileController>()
                                                    .profileModel
                                                    ?.stores?[0]
                                                    .module
                                                    ?.id;
                                            storeController.getItemList(
                                              offset: '1',
                                              type: 'all',
                                              search: _searchController.text
                                                  .trim(),
                                              categoryId: 0,
                                              moduleId: moduleId,
                                            );
                                          } else {
                                            showCustomSnackBar(
                                              'write_item_name_for_search'.tr,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: Dimensions.paddingSizeDefault,
                                  ),

                                  Get.find<ProfileController>()
                                          .modulePermission!
                                          .item!
                                      ? storeController.isLoading ||
                                                storeController.itemList != null
                                            ? ItemViewWidget(
                                                scrollController:
                                                    _scrollController,
                                                fromAllItems: true,
                                                type: storeController.type,
                                                search: _searchController.text,
                                              )
                                            : ItemShimmerWidget(
                                                isEnabled: true,
                                                hasDivider: false,
                                              )
                                      : Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 100,
                                            ),
                                            child: Text(
                                              'you_have_no_permission_to_access_this_feature'
                                                  .tr,
                                              style: robotoMedium,
                                            ),
                                          ),
                                        ),

                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategory(StoreController storeController) {
    int? moduleId =
        Get.find<ProfileController>().profileModel?.stores?[0].module?.id;
    if (storeController.categoryNameList != null) {
      return ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: storeController.categoryNameList!.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => storeController.setCategory(
              index: index,
              foodType: 'all',
              moduleId: moduleId,
            ),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    right: Dimensions.paddingSizeSmall,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusExtraLarge,
                    ),
                    color: index == storeController.categoryIndex
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).hintColor.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    index == 0
                        ? storeController.itemSize != null
                              ? '(${storeController.itemSize}) ${'all'.tr}'
                              : 'all'.tr
                        : storeController.categoryNameList![index],
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: index == storeController.categoryIndex
                          ? Theme.of(context).cardColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: index == storeController.categoryIndex
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeExtraSmall,
        ),
        margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall + 2),
          color: Theme.of(context).hintColor.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;
  SliverDelegate({required this.child, this.height = 50});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
