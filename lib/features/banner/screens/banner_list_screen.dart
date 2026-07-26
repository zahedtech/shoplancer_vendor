import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:shoplancer_vendor/features/banner/controllers/banner_controller.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/confirmation_dialog_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BannerListScreen extends StatefulWidget {
  const BannerListScreen({super.key});

  @override
  State<BannerListScreen> createState() => _BannerListScreenState();
}

class _BannerListScreenState extends State<BannerListScreen> {
  final tooltipController = JustTheController();
  bool _isCatalogSelected = true;
  int? _loadingCatalogBannerId;

  @override
  void initState() {
    Get.find<BannerController>().getBannerList(willUpdate: false);
    Get.find<BannerController>().getCatalogBannerList(willUpdate: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'banner_list'.tr,
        menuWidget: Padding(
          padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
          child: JustTheTooltip(
            backgroundColor: Colors.black87,
            controller: tooltipController,
            preferredDirection: AxisDirection.down,
            tailLength: 14,
            tailBaseWidth: 20,
            content: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Image.asset(Images.noteIcon, height: 21, width: 21),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Text(
                        'note'.tr,
                        style: robotoBold.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(
                    'customer_will_see_these_banners_in_your_store_details_page_in_website_and_user_apps'
                        .tr,
                    style: robotoMedium.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
            child: InkWell(
              onTap: () => tooltipController.showTooltip(),
              child: Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
              ),
            ),
            // child: const Icon(Icons.info_outline),
          ),
        ),
      ),

      body: Column(
        children: [
          // Segmented Toggle Tab Bar (My Banners vs Catalog Banners)
          Container(
            height: 45,
            width: double.infinity,
            margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).disabledColor.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isCatalogSelected = true;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(Dimensions.radiusDefault),
                          bottomRight: Radius.circular(
                            Dimensions.radiusDefault,
                          ),
                        ),
                        color: _isCatalogSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          'catalog_banners'.tr,
                          style: robotoMedium.copyWith(
                            color: _isCatalogSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isCatalogSelected = false;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(Dimensions.radiusDefault),
                          bottomLeft: Radius.circular(Dimensions.radiusDefault),
                        ),
                        color: !_isCatalogSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          'my_banners'.tr,
                          style: robotoMedium.copyWith(
                            color: !_isCatalogSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: GetBuilder<BannerController>(
                builder: (bannerController) {
                  bool showCatalog = _isCatalogSelected;
                  var bannerList = showCatalog
                      ? bannerController.catalogBannerList
                      : bannerController.storeBannerList;
                  bool isLoading = showCatalog
                      ? bannerController.isCatalogLoading
                      : bannerController.storeBannerList == null;

                  return !isLoading
                      ? bannerList != null && bannerList.isNotEmpty
                            ? ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: bannerList.length,
                                itemBuilder: (context, index) {
                                  var banner = bannerList[index];
                                  bool isImage =
                                      banner.type == 'image' ||
                                      (banner.imageFullUrl ?? '').isNotEmpty;
                                  bool isAdded = !showCatalog
                                      ? false
                                      : (bannerController.storeBannerList?.any(
                                              (storeBanner) =>
                                                  storeBanner.bannerCatalogId ==
                                                  banner.id,
                                            ) ??
                                            false);

                                  return Container(
                                    height: 180,
                                    width: Get.width,
                                    margin: const EdgeInsets.only(
                                      bottom: Dimensions.paddingSizeSmall,
                                    ),
                                    padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeSmall,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusSmall,
                                      ),
                                      color: Theme.of(context).cardColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).disabledColor
                                              .withValues(alpha: 0.1),
                                          blurRadius: 5,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: isImage
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions.radiusSmall,
                                                      ),
                                                  child: CustomImageWidget(
                                                    image:
                                                        '${banner.imageFullUrl}',
                                                    fit: BoxFit.cover,
                                                    width: Get.width,
                                                  ),
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          Dimensions
                                                              .radiusSmall,
                                                        ),
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        banner.backgroundColor != null && banner.backgroundColor!.isNotEmpty
                                                            ? _colorFromHex(banner.backgroundColor!)
                                                            : Theme.of(context).primaryColor,
                                                        banner.backgroundColor != null && banner.backgroundColor!.isNotEmpty
                                                            ? _colorFromHex(banner.backgroundColor!).withValues(alpha: 0.7)
                                                            : Theme.of(context).primaryColor.withValues(alpha: 0.7),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Positioned(
                                                        top: -20,
                                                        right: -20,
                                                        child: Container(
                                                          width: 80,
                                                          height: 80,
                                                          decoration:
                                                              BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.08,
                                                                    ),
                                                              ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        bottom: -30,
                                                        left: 10,
                                                        child: Container(
                                                          width: 60,
                                                          height: 60,
                                                          decoration:
                                                              BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.05,
                                                                    ),
                                                              ),
                                                        ),
                                                      ),
                                                      Center(
                                                        child: Padding(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: Dimensions
                                                                .paddingSizeLarge,
                                                          ),
                                                          child: FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  banner.title
                                                                      .toString(),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: robotoBold.copyWith(
                                                                    fontSize:
                                                                        20,
                                                                    color: Colors
                                                                        .white,
                                                                    shadows: [
                                                                      Shadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withValues(
                                                                              alpha: 0.25,
                                                                            ),
                                                                        offset:
                                                                            const Offset(
                                                                              0,
                                                                              2,
                                                                            ),
                                                                        blurRadius:
                                                                            4,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                if ((banner.subTitle ??
                                                                        '')
                                                                    .isNotEmpty) ...[
                                                                  const SizedBox(
                                                                    height: 4,
                                                                  ),
                                                                  Text(
                                                                    banner
                                                                        .subTitle!,
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: robotoRegular.copyWith(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .white
                                                                          .withValues(
                                                                            alpha:
                                                                                0.9,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeSmall,
                                        ),
                                        Row(
                                          children: [
                                            const Spacer(),
                                            if (showCatalog) ...[
                                              if (!isAdded)
                                                InkWell(
                                                  onTap:
                                                      bannerController.isLoading
                                                      ? null
                                                      : () async {
                                                          setState(() {
                                                            _loadingCatalogBannerId =
                                                                banner.id;
                                                          });
                                                          try {
                                                            bool success =
                                                                await bannerController
                                                                    .addCatalogBanner(
                                                                      banner.id,
                                                                    );
                                                            if (success) {
                                                              setState(() {
                                                                _isCatalogSelected =
                                                                    false;
                                                              });
                                                            }
                                                          } finally {
                                                            setState(() {
                                                              _loadingCatalogBannerId =
                                                                  null;
                                                            });
                                                          }
                                                        },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: Dimensions
                                                          .paddingSizeDefault,
                                                      vertical: Dimensions
                                                          .paddingSizeExtraSmall,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          bannerController
                                                              .isLoading
                                                          ? Theme.of(
                                                              context,
                                                            ).disabledColor
                                                          : Theme.of(
                                                              context,
                                                            ).primaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            Dimensions
                                                                .radiusSmall,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        _loadingCatalogBannerId ==
                                                                banner.id
                                                            ? const SizedBox(
                                                                height: 15,
                                                                width: 15,
                                                                child: CircularProgressIndicator(
                                                                  color: Colors
                                                                      .white,
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                              )
                                                            : const Icon(
                                                                Icons.add,
                                                                color: Colors
                                                                    .white,
                                                                size: 15,
                                                              ),
                                                        const SizedBox(
                                                          width: Dimensions
                                                              .paddingSizeExtraSmall,
                                                        ),
                                                        Text(
                                                          _loadingCatalogBannerId ==
                                                                  banner.id
                                                              ? 'adding...'.tr
                                                              : 'add_to_my_store'
                                                                    .tr,
                                                          style: robotoMedium.copyWith(
                                                            color: Colors.white,
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ] else ...[
                                              if (banner.bannerCatalogId == null || banner.bannerCatalogId == 0) ...[
                                                InkWell(
                                                  onTap:
                                                      bannerController.isLoading
                                                      ? null
                                                      : () {
                                                          banner.type = isImage
                                                              ? 'image'
                                                              : 'text';
                                                          Get.toNamed(
                                                            RouteHelper.getAddBannerRoute(
                                                              storeBannerListModel:
                                                                  banner,
                                                            ),
                                                          );
                                                        },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(
                                                      Dimensions
                                                          .paddingSizeExtraSmall,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color:
                                                            bannerController
                                                                .isLoading
                                                            ? Theme.of(
                                                                context,
                                                              ).disabledColor
                                                            : Colors.blue,
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.edit,
                                                      color:
                                                          bannerController
                                                              .isLoading
                                                          ? Theme.of(
                                                              context,
                                                            ).disabledColor
                                                          : Colors.blue,
                                                      size: 15,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: Dimensions
                                                      .paddingSizeSmall,
                                                ),
                                              ],
                                              InkWell(
                                                onTap:
                                                    bannerController.isLoading
                                                    ? null
                                                    : () {
                                                        Get.dialog(
                                                          ConfirmationDialogWidget(
                                                            icon:
                                                                Images.support,
                                                            description:
                                                                'are_you_sure_to_delete_this_banner'
                                                                    .tr,
                                                            onYesPressed: () {
                                                              if (banner.id !=
                                                                  null) {
                                                                bannerController
                                                                    .deleteBanner(
                                                                      banner.id,
                                                                      catalogId:
                                                                          banner
                                                                              .bannerCatalogId,
                                                                    );
                                                              }
                                                            },
                                                          ),
                                                          useSafeArea: false,
                                                        );
                                                      },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    Dimensions
                                                        .paddingSizeExtraSmall,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          bannerController
                                                              .isLoading
                                                          ? Theme.of(
                                                              context,
                                                            ).disabledColor
                                                          : Theme.of(
                                                              context,
                                                            ).colorScheme.error,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.delete_outline,
                                                    color:
                                                        bannerController
                                                            .isLoading
                                                        ? Theme.of(
                                                            context,
                                                          ).disabledColor
                                                        : Theme.of(
                                                            context,
                                                          ).colorScheme.error,
                                                    size: 15,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Center(child: Text('no_banner_found'.tr))
                      : const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),

          if (!_isCatalogSelected)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: GetBuilder<BannerController>(
                  builder: (bannerController) {
                    return CustomButtonWidget(
                      onPressed: bannerController.isLoading
                          ? null
                          : () => Get.toNamed(
                              RouteHelper.getAddBannerRoute(
                                storeBannerListModel: null,
                              ),
                            ),
                      buttonText: 'add_new_banner'.tr,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Future<void> _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Color _colorFromHex(String hexColor) {
    final String normalized = hexColor.replaceAll('#', '');
    try {
      return Color(int.parse('FF$normalized', radix: 16));
    } catch (e) {
      return const Color(0xFF00A082);
    }
  }
}
