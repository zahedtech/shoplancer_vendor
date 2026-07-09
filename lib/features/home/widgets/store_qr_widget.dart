import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class StoreQrWidget extends StatefulWidget {
  final ProfileController profileController;
  const StoreQrWidget({super.key, required this.profileController});

  @override
  State<StoreQrWidget> createState() => _StoreQrWidgetState();
}

class _StoreQrWidgetState extends State<StoreQrWidget> {
  final ScreenshotController screenshotController = ScreenshotController();
  bool _isSharing = false;

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

  @override
  Widget build(BuildContext context) {
    final Store? store =
        (widget.profileController.profileModel?.stores != null &&
            widget.profileController.profileModel!.stores!.isNotEmpty)
        ? widget.profileController.profileModel!.stores![0]
        : null;

    if (store == null) {
      return const SizedBox();
    }

    final String storeUrl = _buildStoreUrl(store);
    if (storeUrl.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: QR code image with Screenshot capture container
          Screenshot(
            controller: screenshotController,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: QrImageView(
                data: storeUrl,
                size: 80,
                backgroundColor: Colors.white,
                padding: EdgeInsets.zero,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          // Right side: Info and Action Buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  store.name ?? '',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    if (await canLaunchUrl(Uri.parse(storeUrl))) {
                      await launchUrl(
                        Uri.parse(storeUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Text(
                    storeUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Row(
                  children: [
                    // Copy Link Button
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: storeUrl));
                        showCustomSnackBar(
                          'store_link_copied'.tr,
                          isError: false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSmall,
                          ),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy,
                              size: 14,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'copy'.tr,
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    // Share Button
                    _isSharing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : InkWell(
                            onTap: () async {
                              setState(() {
                                _isSharing = true;
                              });
                              try {
                                final Uint8List? imageBytes =
                                    await screenshotController.capture();
                                if (imageBytes != null) {
                                  final directory =
                                      await getTemporaryDirectory();
                                  final String path =
                                      '${directory.path}/store_qr_${DateTime.now().millisecondsSinceEpoch}.png';
                                  final File file = await File(path).create();
                                  await file.writeAsBytes(imageBytes);

                                  await Share.shareXFiles(
                                    [XFile(file.path)],
                                    text:
                                        '${'share_store'.tr}: ${store.name ?? ""}\n$storeUrl',
                                  );
                                }
                              } catch (e) {
                                showCustomSnackBar(
                                  'failed_to_save_qr'.tr,
                                  isError: true,
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSharing = false;
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSmall,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.share,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'share'.tr,
                                    style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
