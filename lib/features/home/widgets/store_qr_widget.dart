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

  void _showQrPreviewDialog(
    BuildContext context,
    String storeUrl,
    String storeName,
  ) {
    final ScreenshotController modalScreenshotController =
        ScreenshotController();
    bool isSaving = false;
    bool isSharingModal = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top header: Title and Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'store_qr_code'.tr,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).disabledColor,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // QR Code Screenshot container
                    Screenshot(
                      controller: modalScreenshotController,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
                              data: storeUrl,
                              size: 220,
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
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            Text(
                              storeName,
                              textAlign: TextAlign.center,
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              storeUrl,
                              textAlign: TextAlign.center,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // Action buttons: Save to Device and Share
                    Row(
                      children: [
                        // Save button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSmall,
                                ),
                              ),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setModalState(() {
                                      isSaving = true;
                                    });
                                    try {
                                      final Uint8List? imageBytes =
                                          await modalScreenshotController
                                              .capture();
                                      if (imageBytes != null) {
                                        Directory? directory;
                                        if (Platform.isAndroid) {
                                          final downloadsDir = Directory(
                                            '/storage/emulated/0/Download',
                                          );
                                          if (await downloadsDir.exists()) {
                                            directory = downloadsDir;
                                          } else {
                                            final picturesDir = Directory(
                                              '/storage/emulated/0/Pictures',
                                            );
                                            if (await picturesDir.exists()) {
                                              directory = picturesDir;
                                            } else {
                                              directory =
                                                  await getExternalStorageDirectory();
                                            }
                                          }
                                        } else if (Platform.isIOS) {
                                          directory =
                                              await getApplicationDocumentsDirectory();
                                        } else {
                                          directory =
                                              await getDownloadsDirectory() ??
                                              await getApplicationDocumentsDirectory();
                                        }

                                        if (directory != null) {
                                          final String filePath =
                                              '${directory.path}/store_qr_${DateTime.now().millisecondsSinceEpoch}.png';
                                          final File file = File(filePath);
                                          await file.writeAsBytes(imageBytes);
                                          showCustomSnackBar(
                                            'qr_code_saved'.tr,
                                            isError: false,
                                          );
                                        } else {
                                          showCustomSnackBar(
                                            'failed_to_save_qr'.tr,
                                            isError: true,
                                          );
                                        }
                                      } else {
                                        showCustomSnackBar(
                                          'failed_to_save_qr'.tr,
                                          isError: true,
                                        );
                                      }
                                    } catch (e) {
                                      showCustomSnackBar(
                                        'failed_to_save_qr'.tr,
                                        isError: true,
                                      );
                                    } finally {
                                      setModalState(() {
                                        isSaving = false;
                                      });
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download_rounded, size: 18),
                            label: Text(
                              'download_qr'.tr,
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        // Share button
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                              foregroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSmall,
                                ),
                              ),
                            ),
                            onPressed: isSharingModal
                                ? null
                                : () async {
                                    setModalState(() {
                                      isSharingModal = true;
                                    });
                                    try {
                                      final Uint8List? imageBytes =
                                          await modalScreenshotController
                                              .capture();
                                      if (imageBytes != null) {
                                        final directory =
                                            await getTemporaryDirectory();
                                        final String path =
                                            '${directory.path}/store_qr_${DateTime.now().millisecondsSinceEpoch}.png';
                                        final File file = await File(
                                          path,
                                        ).create();
                                        await file.writeAsBytes(imageBytes);

                                        await Share.shareXFiles(
                                          [XFile(file.path)],
                                          text:
                                              '${'share_store'.tr}: $storeName\n$storeUrl',
                                        );
                                      }
                                    } catch (e) {
                                      showCustomSnackBar(
                                        'failed_to_save_qr'.tr,
                                        isError: true,
                                      );
                                    } finally {
                                      setModalState(() {
                                        isSharingModal = false;
                                      });
                                    }
                                  },
                            icon: isSharingModal
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  )
                                : const Icon(Icons.share, size: 18),
                            label: Text(
                              'share'.tr,
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
          // Left side: QR code image with Screenshot capture container (Clickable to enlarge)
          InkWell(
            onTap: () =>
                _showQrPreviewDialog(context, storeUrl, store.name ?? ''),
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
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
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
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
                    const String dashboardUrl =
                        'https://dashboard.shoplanser.com/login/vendor';
                    if (await canLaunchUrl(Uri.parse(dashboardUrl))) {
                      await launchUrl(
                        Uri.parse(dashboardUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'go_to_control_panel'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
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
