import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sixam_mart_store/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_store/features/profile/domain/models/profile_model.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class StoreLinkScreen extends StatelessWidget {
  const StoreLinkScreen({super.key});

  String _buildStoreUrl(Store store) {
    final String? rawSlug = (store.slug?.trim().isNotEmpty ?? false)
        ? store.slug
        : store.name;
    if (rawSlug == null || rawSlug.trim().isEmpty) {
      return '';
    }
    final String slug = Uri.encodeComponent(rawSlug.trim());
    return 'https://market.shoplanser.com/store/$slug';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'store_link'.tr),
      body: GetBuilder<ProfileController>(
        builder: (profileController) {
          final Store? store = profileController.profileModel?.stores?[0];
          if (store == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final String storeUrl = _buildStoreUrl(store);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'store_link'.tr,
                    style: robotoBold.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SelectableText(
                          storeUrl.isNotEmpty
                              ? storeUrl
                              : 'not_available_now'.tr,
                          style: robotoRegular.copyWith(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        color: Theme.of(context).primaryColor,
                        onPressed: storeUrl.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(
                                  ClipboardData(text: storeUrl),
                                );
                                showCustomSnackBar(
                                  'store_link_copied'.tr,
                                  isError: false,
                                );
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Center(
                    child: storeUrl.isNotEmpty
                        ? QrImageView(
                            data: storeUrl,
                            size: 180,
                            backgroundColor: Colors.white,
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
