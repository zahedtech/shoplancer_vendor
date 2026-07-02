import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/discount_tag_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/chat/widgets/search_field_widget.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class ProductStatusScreen extends StatefulWidget {
  const ProductStatusScreen({super.key});

  @override
  State<ProductStatusScreen> createState() => _ProductStatusScreenState();
}

class _ProductStatusScreenState extends State<ProductStatusScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final StoreController storeController = Get.find<StoreController>();
    // Reset filters to ensure the screen starts in a clean state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      storeController.resetFilters();
      storeController.getStoreCategories();
    });

    // Setup scroll listener for pagination
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
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        return Scaffold(
          appBar: CustomAppBarWidget(
            title: 'product_status_update'.tr,
          ),
          body: storeController.categoryNameList != null
              ? Column(
                  children: [
                    // Sticky Category Header
                    Container(
                      height: 50,
                      color: Theme.of(context).cardColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeExtraSmall,
                      ),
                      child: ListView.builder(
                        controller: _categoryScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                        ),
                        itemCount: storeController.categoryNameList!.length,
                        itemBuilder: (context, index) {
                          bool isSelected = index == storeController.categoryIndex;
                          return InkWell(
                            onTap: () {
                              _searchController.clear();
                              storeController.setCategory(
                                index: index,
                                foodType: 'all',
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: Dimensions.paddingSizeSmall,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                                vertical: Dimensions.paddingSizeExtraSmall,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusExtraLarge,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context)
                                          .disabledColor
                                          .withOpacity(0.3),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                index == 0
                                    ? 'all'.tr
                                    : storeController.categoryNameList![index],
                                style: robotoMedium.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                      ),
                      child: SizedBox(
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
                                if (_searchController.text.trim().isNotEmpty) {
                                  storeController.getItemList(
                                    offset: '1',
                                    type: 'all',
                                    search: _searchController.text.trim(),
                                    categoryId: storeController.categoryId,
                                  );
                                } else {
                                  showCustomSnackBar('write_item_name_for_search'.tr);
                                }
                              } else {
                                _searchController.clear();
                                storeController.getItemList(
                                  offset: '1',
                                  type: 'all',
                                  search: '',
                                  categoryId: storeController.categoryId,
                                );
                              }
                            },
                            onSubmit: (String text) {
                              if (_searchController.text.trim().isNotEmpty) {
                                storeController.getItemList(
                                  offset: '1',
                                  type: 'all',
                                  search: _searchController.text.trim(),
                                  categoryId: storeController.categoryId,
                                );
                              } else {
                                showCustomSnackBar('write_item_name_for_search'.tr);
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    // Product Grid View
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          _searchController.clear();
                          storeController.resetFilters();
                        },
                        child: storeController.itemList != null
                            ? storeController.itemList!.isNotEmpty
                                ? GridView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeDefault,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.72,
                                      crossAxisSpacing:
                                          Dimensions.paddingSizeDefault,
                                      mainAxisSpacing:
                                          Dimensions.paddingSizeDefault,
                                    ),
                                    itemCount: storeController.itemList!.length,
                                    itemBuilder: (context, index) {
                                      Item item = storeController.itemList![index];
                                      return _buildProductCard(
                                        context,
                                        item,
                                        storeController,
                                      );
                                    },
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          Images.emptyBox,
                                          width: 150,
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeDefault,
                                        ),
                                        Text(
                                          'no_item_available'.tr,
                                          style: robotoMedium.copyWith(
                                            color: Theme.of(context)
                                                .disabledColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: Dimensions.paddingSizeDefault,
                                  mainAxisSpacing: Dimensions.paddingSizeDefault,
                                ),
                                itemCount: 10,
                                itemBuilder: (context, index) {
                                  return _buildShimmerCard(context);
                                },
                              ),
                      ),
                    ),

                    if (storeController.isLoading &&
                        storeController.itemList != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeSmall,
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        );
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Item item,
    StoreController storeController,
  ) {
    bool isActive = item.status == 1;
    bool isLoading = storeController.loadingItemsList.contains(item.id);

    return InkWell(
      onTap: isLoading
          ? null
          : () {
              storeController.updateItemStatusForProduct(
                item.id,
                !isActive,
              );
            },
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Dimensions.radiusDefault),
                ),
                child: Stack(
                  children: [
                    CustomImageWidget(
                      image: item.imageFullUrl ?? '',
                      height: double.maxFinite,
                      width: double.maxFinite,
                      fit: BoxFit.cover,
                    ),
                    if (item.discount != null && item.discount! > 0)
                      DiscountTagWidget(
                        discount: item.discount ?? 0,
                        discountType: item.discountType ?? 'percent',
                        freeDelivery: false,
                      ),
                  ],
                ),
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    item.name ?? '',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Text(
                    PriceConverterHelper.convertPrice(item.price),
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  // Toggle Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isActive ? 'active'.tr : 'inactive'.tr,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: isActive
                              ? Colors.green
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                      isLoading
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            )
                          : IgnorePointer(
                              child: Transform.scale(
                                scale: 0.8,
                                child: CupertinoSwitch(
                                  value: isActive,
                                  activeColor: Theme.of(context).primaryColor,
                                  onChanged: (bool value) {},
                                ),
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Shimmer
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Dimensions.radiusDefault),
              ),
              child: Shimmer(
                child: Container(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  width: double.maxFinite,
                  height: double.maxFinite,
                ),
              ),
            ),
          ),

          // Details Padding
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Shimmer(
                  child: Container(
                    height: 15,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Price
                Shimmer(
                  child: Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Switch Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Shimmer(
                      child: Container(
                        height: 12,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                      ),
                    ),
                    Shimmer(
                      child: Container(
                        height: 20,
                        width: 35,
                        decoration: BoxDecoration(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
