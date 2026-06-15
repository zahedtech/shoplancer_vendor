import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/api/api_client.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart' as profile;
import 'package:shoplancer_vendor/util/app_constants.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class SocialMediaScreen extends StatefulWidget {
  const SocialMediaScreen({super.key});

  @override
  State<SocialMediaScreen> createState() => _SocialMediaScreenState();
}

class _SocialMediaScreenState extends State<SocialMediaScreen> {
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();

  @override
  void initState() {
    super.initState();
    profile.Store? store = Get.find<ProfileController>().profileModel?.stores?[0];
    if (store != null) {
      _facebookController.text = store.facebook ?? '';
      _instagramController.text = store.instagram ?? '';
      _tiktokController.text = store.tiktok ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'social_media'.tr),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'add_your_social_media_links'.tr,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            _buildSocialField(
              'Facebook',
              _facebookController,
              Icons.facebook,
              Colors.blue,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            _buildSocialField(
              'Instagram',
              _instagramController,
              Icons.camera_alt,
              Colors.pink,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            _buildSocialField(
              'TikTok',
              _tiktokController,
              Icons.music_note,
              Colors.black,
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            CustomButtonWidget(
              buttonText: 'update'.tr,
              onPressed: () async {
                String facebook = _facebookController.text.trim();
                String instagram = _instagramController.text.trim();
                String tiktok = _tiktokController.text.trim();

                if (facebook.isEmpty) {
                  showCustomSnackBar('enter_facebook_url'.tr);
                  return;
                } else if (!GetUtils.isURL(facebook)) {
                  showCustomSnackBar('enter_a_valid_facebook_url'.tr);
                  return;
                }

                if (instagram.isEmpty) {
                  showCustomSnackBar('enter_instagram_url'.tr);
                  return;
                } else if (!GetUtils.isURL(instagram)) {
                  showCustomSnackBar('enter_a_valid_instagram_url'.tr);
                  return;
                }

                if (tiktok.isEmpty) {
                  showCustomSnackBar('enter_tiktok_url'.tr);
                  return;
                } else if (!GetUtils.isURL(tiktok)) {
                  showCustomSnackBar('enter_a_valid_tiktok_url'.tr);
                  return;
                }

                Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                Response response = await Get.find<ApiClient>().postData(
                  AppConstants.updateSocialMediaUri,
                  {
                    'facebook': facebook,
                    'instagram': instagram,
                    'tiktok': tiktok,
                  },
                );
                Get.back();

                if (response.statusCode == 200) {
                  profile.Store? store = Get.find<ProfileController>().profileModel?.stores?[0];
                  if (store != null) {
                    store.facebook = facebook;
                    store.instagram = instagram;
                    store.tiktok = tiktok;
                  }
                  Get.back();
                  showCustomSnackBar('social_media_links_updated_successfully'.tr, isError: false);
                } else {
                  showCustomSnackBar(response.statusText ?? 'failed_to_update_social_media'.tr, isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialField(
    String title,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              title,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        CustomTextFieldWidget(
          hintText: '${'enter'.tr} $title ${'link'.tr}',
          controller: controller,
          inputType: TextInputType.url,
        ),
      ],
    );
  }
}
