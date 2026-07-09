import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/discount_tag_widget.dart';
import 'package:shoplancer_vendor/common/widgets/item_shimmer_widget.dart';
import 'package:shoplancer_vendor/common/widgets/not_available_widget.dart';
import 'package:shoplancer_vendor/features/chat/widgets/search_field_widget.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/helper/date_converter_helper.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';

import '../../store/widgets/filter_popup_widget.dart';

class AlternativeItemSelectionScreen extends StatefulWidget {
  final int orderId;
  const AlternativeItemSelectionScreen({super.key, required this.orderId});

  @override
  State<AlternativeItemSelectionScreen> createState() =>
      _AlternativeItemSelectionScreenState();
}

class _AlternativeItemSelectionScreenState
    extends State<AlternativeItemSelectionScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final StoreController storeController = Get.find<StoreController>();
    Get.find<ProfileController>().getProfile();

    storeController.getItemList(
      offset: '1',
      type: 'all',
      search: '',
      categoryId: 0,
      willUpdate: false,
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

            return PopScope(
              canPop: true,
              onPopInvoked: (bool didPop) {
                if (didPop) {
                  // Reset filters when navigating back
                  storeController.resetFilters();
                }
              },
              child: Scaffold(
                appBar: CustomAppBarWidget(title: 'select_alternative_item'.tr),
                body: store != null
                    ? CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
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
                                                    storeController.getItemList(
                                                      offset: '1',
                                                      type: val,
                                                      search: '',
                                                      categoryId:
                                                          storeController
                                                              .categoryId,
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
                                              storeController.getItemList(
                                                offset: '1',
                                                type: 'all',
                                                search: _searchController.text
                                                    .trim(),
                                                categoryId: 0,
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
                                            storeController.getItemList(
                                              offset: '1',
                                              type: 'all',
                                              search: '',
                                              categoryId: 0,
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
                                            storeController.getItemList(
                                              offset: '1',
                                              type: 'all',
                                              search: _searchController.text
                                                  .trim(),
                                              categoryId: 0,
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
                                      ? _buildItemListView(storeController)
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
    if (storeController.categoryNameList != null) {
      return ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: storeController.categoryNameList!.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () =>
                storeController.setCategory(index: index, foodType: 'all'),
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

  Widget _buildItemListView(StoreController storeController) {
    return Column(
      children: [
        storeController.itemList != null
            ? storeController.itemList!.isNotEmpty
                  ? GridView.builder(
                      key: UniqueKey(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisSpacing: Dimensions.paddingSizeLarge,
                            mainAxisSpacing: 0.01,
                            crossAxisCount: 1,
                            mainAxisExtent: 104,
                          ),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: storeController.itemList!.length,
                      padding: const EdgeInsets.all(0),
                      itemBuilder: (context, index) {
                        Item item = storeController.itemList![index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: Dimensions.paddingSizeSmall,
                          ),
                          child: _buildSelectableItemWidget(
                            context,
                            item,
                            index,
                            storeController,
                          ),
                        );
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 200),
                      child: Center(child: Text('no_item_available'.tr)),
                    )
            : GridView.builder(
                key: UniqueKey(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: Dimensions.paddingSizeLarge,
                  mainAxisSpacing: 0.01,
                  crossAxisCount: 1,
                  mainAxisExtent: 120,
                ),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: 20,
                padding: const EdgeInsets.all(0),
                itemBuilder: (context, index) {
                  return ItemShimmerWidget(
                    isEnabled: storeController.itemList == null,
                    hasDivider: index != 19,
                  );
                },
              ),
        storeController.isLoading
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )
            : const SizedBox(),
      ],
    );
  }

  Widget _buildSelectableItemWidget(
    BuildContext context,
    Item item,
    int index,
    StoreController storeController,
  ) {
    double discount;
    String discountType;
    bool isAvailable;
    final double resolvedStoreDiscount = item.storeDiscount ?? 0;
    discount = resolvedStoreDiscount == 0
        ? (item.discount ?? 0)
        : resolvedStoreDiscount;
    discountType = resolvedStoreDiscount == 0
        ? (item.discountType ?? 'percent')
        : 'percent';
    isAvailable = DateConverterHelper.isAvailable(
      item.availableTimeStarts,
      item.availableTimeEnds,
    );

    double width = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: () {
        _showQuantityDialog(context, item);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
        ),
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 3),
              color: Colors.grey[Get.isDarkMode ? 700 : 200]!,
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            /// Image section
            item.imageFullUrl != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusDefault,
                        ),
                        child: CustomImageWidget(
                          image: '${item.imageFullUrl}',
                          height: 60,
                          width: 69,
                          fit: BoxFit.cover,
                        ),
                      ),
                      DiscountTagWidget(
                        discount: discount,
                        discountType: discountType,
                        freeDelivery: false,
                      ),
                      isAvailable
                          ? const SizedBox()
                          : const NotAvailableWidget(isStore: false),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                    child: CustomImageWidget(
                      image: Images.image,
                      height: 60,
                      width: 69,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            /// Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Name
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.name ?? '',
                        textAlign: TextAlign.start,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      SizedBox(
                        width: item.imageFullUrl == null
                            ? Dimensions.paddingSizeExtraSmall
                            : 0,
                      ),
                      item.imageFullUrl == null
                          ? discount > 0
                                ? Text(
                                    '(${discount > 0 ? '$discount${discountType == 'percent' ? '%' : Get.find<SplashController>().configModel!.currencySymbol} ${'off'.tr}' : 'free_delivery'.tr})',
                                    style: robotoMedium.copyWith(
                                      color: Colors.green,
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                    ),
                                  )
                                : const SizedBox()
                          : const SizedBox(),
                    ],
                  ),
                  SizedBox(
                    height: item.imageFullUrl != null
                        ? Dimensions.paddingSizeExtraSmall
                        : 0,
                  ),

                  /// Rating bar
                  Row(
                    children: [
                      if (item.avgRating != null && item.avgRating != 0.0)
                        Row(
                          children: [
                            Image.asset(Images.starIcon, width: 10),
                            Text(
                              ' ${item.avgRating!.toStringAsFixed(2)} ',
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                            Text(
                              ' (${item.ratingCount})',
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                color: Theme.of(context).hintColor,
                                decoration: TextDecoration.underline,
                                decorationColor: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      item.imageFullUrl == null && !isAvailable
                          ? Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                '(${'not_available_now'.tr})',
                                textAlign: TextAlign.center,
                                style: robotoRegular.copyWith(
                                  color: Colors.red,
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ],
                  ),
                  const SizedBox(height: 2),

                  /// Price
                  Row(
                    children: [
                      discount > 0
                          ? Text(
                              PriceConverterHelper.convertPrice(item.price),
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                color: Theme.of(context).disabledColor,
                                decoration: TextDecoration.lineThrough,
                              ),
                            )
                          : const SizedBox(),
                      SizedBox(
                        width: discount > 0
                            ? Dimensions.paddingSizeExtraSmall
                            : 0,
                      ),
                      Text(
                        PriceConverterHelper.convertPrice(
                          item.price,
                          discount: discount,
                          discountType: discountType,
                        ),
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            width > 320
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _showQuantityDialog(context, item),
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusSmall,
                            ),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 25,
                          ),
                        ),
                        tooltip: 'select'.tr,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: Dimensions.paddingSizeSmall,
                          bottom: Dimensions.paddingSizeSmall,
                        ),
                        child: item.stock != 0 && item.stock != null
                            ? Text(
                                'Stock : ${item.stock}',
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).disabledColor,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => _showQuantityDialog(context, item),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 25,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, Item item) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('select_quantity'.tr),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (quantity > 1) {
                        setState(() {
                          quantity--;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    quantity.toString(),
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        quantity++;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('cancel'.tr),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.back(result: {'item': item, 'quantity': quantity});
                  },
                  child: Text('confirm'.tr),
                ),
              ],
            );
          },
        );
      },
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
