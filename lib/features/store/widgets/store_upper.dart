import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/banner/domain/models/store_banner_list_model.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

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
                      if (widget.store != null) {
                        String storeUrl = _buildStoreUrl(widget.store!);
                        if (storeUrl.isNotEmpty) {
                          _showShareBottomSheet(context, storeUrl, widget.store!.name ?? '');
                        }
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

  String _buildStoreUrl(Store store) {
    final String? rawSlug = (store.slug?.trim().isNotEmpty ?? false)
        ? store.slug
        : store.name;
    if (rawSlug == null || rawSlug.trim().isEmpty) {
      return '';
    }
    final String slug = Uri.encodeComponent(rawSlug.trim());
    return 'https://store.shoplanser.com/$slug';
  }

  void _showShareBottomSheet(BuildContext context, String storeUrl, String storeName) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4, width: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            
            Text(
              'share_store'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            ListTile(
              leading: Icon(Icons.link, color: Theme.of(context).primaryColor),
              title: Text('share_link'.tr, style: robotoMedium),
              subtitle: Text(storeUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Get.back();
                Share.share(storeUrl);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.qr_code, color: Theme.of(context).primaryColor),
              title: Text('share_as_qr'.tr, style: robotoMedium),
              onTap: () {
                Get.back();
                _showQrDialog(context, storeUrl, storeName);
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context, String storeUrl, String storeName) {
    ScreenshotController screenshotController = ScreenshotController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                storeName,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Screenshot(
                controller: screenshotController,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: storeUrl,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Text(
                        'store.shoplanser.com',
                        style: robotoMedium.copyWith(color: Colors.black, fontSize: Dimensions.fontSizeSmall),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr, style: robotoMedium.copyWith(color: Theme.of(context).disabledColor)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                      try {
                        final Uint8List? imageBytes = await screenshotController.capture();
                        Get.back(); // close progress loader
                        if (imageBytes != null) {
                          final directory = await getTemporaryDirectory();
                          final String path = '${directory.path}/store_qr_${DateTime.now().millisecondsSinceEpoch}.png';
                          final File file = await File(path).create();
                          await file.writeAsBytes(imageBytes);
                          
                          Get.back(); // close QR dialog
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text: '${'share_store'.tr}: $storeName',
                          );
                        }
                      } catch (e) {
                        Get.back(); // close progress loader if open
                        showCustomSnackBar('failed_to_save_qr'.tr, isError: true);
                      }
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: Text('share'.tr, style: robotoBold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
