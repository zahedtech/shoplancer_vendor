import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_store/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_text_field_widget.dart';
import 'package:sixam_mart_store/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/styles.dart';

class SocialMediaScreen extends StatefulWidget {
  const SocialMediaScreen({super.key});

  @override
  State<SocialMediaScreen> createState() => _SocialMediaScreenState();
}

class _SocialMediaScreenState extends State<SocialMediaScreen> {
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'social_media'.tr),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'add_your_social_media_links'.tr,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          _buildSocialField('Facebook', _facebookController, Icons.facebook, Colors.blue),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          _buildSocialField('Instagram', _instagramController, Icons.camera_alt, Colors.pink),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          _buildSocialField('Twitter', _twitterController, Icons.alternate_email, Colors.lightBlue),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          _buildSocialField('YouTube', _youtubeController, Icons.play_arrow, Colors.red),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          _buildSocialField('LinkedIn', _linkedinController, Icons.work, Colors.blueAccent),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          CustomButtonWidget(
            buttonText: 'update'.tr,
            onPressed: () {
              // Logic will be added later
              Get.back();
              showCustomSnackBar('social_media_links_updated_successfully'.tr, isError: false);
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildSocialField(String title, TextEditingController controller, IconData icon, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text(title, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
      ]),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      CustomTextFieldWidget(
        hintText: '${'enter'.tr} $title ${'link'.tr}',
        controller: controller,
        inputType: TextInputType.url,
      ),
    ]);
  }
}
