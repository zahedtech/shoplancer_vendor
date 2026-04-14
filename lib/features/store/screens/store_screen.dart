import 'package:sixam_mart_store/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart_store/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_store/features/store/controllers/store_controller.dart';
import 'package:sixam_mart_store/features/profile/domain/models/profile_model.dart';
import 'package:sixam_mart_store/features/store/widgets/mobile_product_grid.dart';
import 'package:sixam_mart_store/features/store/widgets/store_upper.dart';
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
      Get.find<BannerController>().getBannerList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
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
                    color: const Color(0xFF2C7A46),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  storeController.isSearching
                                      ? 'search_results'.tr
                                      : (storeController.categoryIndex != 0
                                            ? storeController
                                                  .categoryNameList![storeController
                                                      .categoryIndex!]
                                                  .tr
                                            : 'all_products'.tr),
                                  style: robotoBold.copyWith(
                                    fontSize: 18,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                if (storeController.itemList != null)
                                  Text(
                                    '${storeController.itemList!.length} items',
                                    style: robotoRegular.copyWith(
                                      fontSize: 14,
                                      color: const Color(0xFF7D7D7D),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Product Grid
                        const SliverToBoxAdapter(child: MobileProductGrid()),

                        // Bottom Spacing
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
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
