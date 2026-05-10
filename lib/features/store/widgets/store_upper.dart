import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/features/banner/domain/models/store_banner_list_model.dart';
import 'package:sixam_mart_store/features/profile/domain/models/profile_model.dart';
import 'package:sixam_mart_store/features/store/controllers/store_controller.dart';
import 'package:sixam_mart_store/helper/route_helper.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreUpper extends StatefulWidget {
  final List<StoreBannerListModel>? banners;
  final Store? store;
  const StoreUpper({super.key, this.banners, this.store});

  @override
  State<StoreUpper> createState() => _StoreUpperState();
}

class _StoreUpperState extends State<StoreUpper> {
  // ignore: unused_field
  final int _currentBannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /*// Banner Section
        if (widget.banners != null && widget.banners!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Stack(
              children: [
                CarouselSlider.builder(
                  itemCount: widget.banners!.length,
                  itemBuilder: (context, index, realIndex) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      width: MediaQuery.of(context).size.width,
                      child: ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: CustomImageWidget(
                          image: widget.banners![index].imageFullUrl ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 180,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentBannerIndex = index;
                      });
                    },
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.banners!.asMap().entries.map((entry) {
                      return Container(
                        width: 10.0,
                        height: 4.0,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: _currentBannerIndex == entry.key
                              ? Colors.white
                              : Colors.black.withOpacity(0.5),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),*/

        // Store Details Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2C7A46).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: CustomImageWidget(
                        image: widget.store?.logoFullUrl ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.store?.name ?? '',
                          style: robotoBold.copyWith(
                            fontSize: 22,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.store?.address ?? '',
                                style: robotoRegular.copyWith(
                                  fontSize: 12,
                                  color: Theme.of(context).disabledColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Management Actions
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.toNamed(
                            RouteHelper.getStoreEditRoute(widget.store!),
                          );
                        },
                        icon: Icon(
                          Icons.settings_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: () {
                          Get.dialog(
                            AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusExtraLarge,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical:
                                          Dimensions.paddingSizeExtraLarge,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.05),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(
                                          Dimensions.radiusExtraLarge,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            height: 100,
                                            width: 100,
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Image.asset(
                                            Images.whatsapp,
                                            height: 60,
                                            width: 60,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeLarge,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'add_missing_store_item_title'.tr,
                                          textAlign: TextAlign.center,
                                          style: robotoBold.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeExtraLarge,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeSmall,
                                        ),
                                        Text(
                                          'contact_to_add_item'.tr,
                                          textAlign: TextAlign.center,
                                          style: robotoRegular.copyWith(
                                            fontSize: Dimensions.fontSizeLarge,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeDefault,
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomButtonWidget(
                                                buttonText: 'cancel'.tr,
                                                icon: Icons.cancel_outlined,
                                                iconColor: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.2),
                                                textColor: Theme.of(
                                                  context,
                                                ).primaryColor,

                                                onPressed: () => Get.back(),
                                              ),
                                            ),
                                            const SizedBox(
                                              width:
                                                  Dimensions.paddingSizeSmall,
                                            ),
                                            Expanded(
                                              child: CustomButtonWidget(
                                                buttonText: 'whatsapp'.tr,
                                                icon: Icons.chat_bubble_outline,
                                                color: Colors.green,
                                                onPressed: () async {
                                                  var url =
                                                      "https://wa.me/972598765425";
                                                  if (await canLaunchUrl(
                                                    Uri.parse(url),
                                                  )) {
                                                    await launchUrl(
                                                      Uri.parse(url),
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  } else {
                                                    showCustomSnackBar(
                                                      'can_not_launch_url'.tr,
                                                    );
                                                  }
                                                  Get.back();
                                                },
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
                        },
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      if (widget.store?.slug != null) {
                        final String slug = Uri.encodeComponent(
                          widget.store!.slug!.trim(),
                        );
                        String storeUrl =
                            'https://market.shoplanser.com/store/$slug';
                        Share.share(storeUrl);
                      }
                    },
                    child: _buildStatItem(
                      context,
                      Icons.share_outlined,
                      'share'.tr,
                      'store_link'.tr,
                    ),
                  ),
                  _buildStatItem(
                    context,
                    Icons.shopping_bag_outlined,
                    '${widget.store?.totalOrder ?? 0}',
                    'orders'.tr,
                  ),
                  _buildStatItem(
                    context,
                    Icons.inventory_2_outlined,
                    '${widget.store?.totalItems ?? 0}',
                    'items'.tr,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Category Selection
        GetBuilder<StoreController>(
          builder: (storeController) {
            return (storeController.categoryNameList != null &&
                    storeController.categoryNameList!.isNotEmpty)
                ? Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: storeController.categoryNameList!.length,
                      itemBuilder: (context, index) {
                        bool isSelected =
                            storeController.categoryIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              storeController.setCategory(
                                index: index,
                                foodType: storeController.type,
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(
                                          context,
                                        ).disabledColor.withOpacity(0.2),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                storeController.categoryNameList![index].tr,
                                style: robotoMedium.copyWith(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).disabledColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String val,
    String label,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 4),
            Text(
              val,
              style: robotoBold.copyWith(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: robotoRegular.copyWith(
            fontSize: 12,
            color: Theme.of(context).disabledColor,
          ),
        ),
      ],
    );
  }
}
