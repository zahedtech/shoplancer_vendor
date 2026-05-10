import 'package:sixam_mart_store/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart_store/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_store/features/store/controllers/store_controller.dart';
import 'package:sixam_mart_store/features/profile/domain/models/profile_model.dart';
import 'package:sixam_mart_store/features/store/widgets/mobile_product_grid.dart';
import 'package:sixam_mart_store/features/store/widgets/store_upper.dart';
import 'package:sixam_mart_store/helper/route_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          Get.find<StoreController>().itemList != null &&
          !Get.find<StoreController>().isLoading) {
        int pageSize = (Get.find<StoreController>().itemSize! / 10).ceil();
        if (Get.find<StoreController>().offset < pageSize) {
          Get.find<StoreController>().setOffset(
            Get.find<StoreController>().offset + 1,
          );
          debugPrint('end of the page');
          Get.find<StoreController>().showBottomLoader();
          Get.find<StoreController>().getItemList(
            offset: Get.find<StoreController>().offset.toString(),
            type: Get.find<StoreController>().type,
            search: '',
            categoryId: Get.find<StoreController>().categoryId,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    if (Get.find<ProfileController>().profileModel == null) {
      await Get.find<ProfileController>().getProfile();
    }
    Store? store = Get.find<ProfileController>().profileModel?.stores?[0];
    if (store != null) {
      Get.find<StoreController>().getItemList(
        offset: '1',
        type: 'all',
        search: '',
        categoryId: 0,
        willUpdate: true,
      );
      Get.find<StoreController>().getStoreCategories();
      Get.find<BannerController>().getBannerList(willUpdate: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GetBuilder<ProfileController>(
        builder: (profileController) {
          Store? store = profileController.profileModel?.stores?[0];

          return GetBuilder<StoreController>(
            builder: (storeController) {
              return GetBuilder<BannerController>(
                builder: (bannerController) {
                  if (store == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await _initData();
                    },
                    color: Theme.of(context).primaryColor,
                    child: SafeArea(
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Modern Header with Banners and Store Info
                          SliverToBoxAdapter(
                            child: StoreUpper(
                              banners: bannerController.storeBannerList,
                              store: store,
                            ),
                          ),

                          // Section Title
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    storeController.isSearching
                                        ? 'search_results'.tr
                                        : (storeController.categoryIndex != 0 &&
                                                  storeController.categoryNameList != null
                                              ? storeController.categoryNameList![
                                                      storeController.categoryIndex!]
                                                  .tr
                                              : 'all_products'.tr),
                                    style: robotoBold.copyWith(
                                      fontSize: 18,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  if (storeController.itemList != null)
                                    Text(
                                      '${store.totalItems ?? 0} ${'items'.tr}',
                                      style: robotoRegular.copyWith(
                                        fontSize: 14,
                                        color: Theme.of(context).disabledColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Product Grid
                          const SliverToBoxAdapter(child: MobileProductGrid()),

                          // Bottom Loader
                          if (storeController.isLoading &&
                              storeController.itemList != null)
                            SliverToBoxAdapter(
                              child: Center(
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
                            ),

                          // Bottom Spacing
                          const SliverToBoxAdapter(child: SizedBox(height: 80)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
