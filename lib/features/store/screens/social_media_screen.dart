import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shoplancer_vendor/api/api_client.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart' as profile;
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/util/app_constants.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
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
  final TextEditingController _whatsappController = TextEditingController();
  String? _whatsappDialCode;

  @override
  void initState() {
    super.initState();
    
    String? defaultCountry = Get.find<SplashController>().configModel?.country;
    if (defaultCountry != null && defaultCountry.isNotEmpty) {
      _whatsappDialCode = CountryCode.fromCountryCode(defaultCountry).dialCode;
    } else {
      _whatsappDialCode = '+20'; // Default to Egypt
    }

    profile.Store? store = Get.find<ProfileController>().profileModel?.stores?[0];
    if (store != null) {
      _facebookController.text = store.facebook ?? '';
      _instagramController.text = store.instagram ?? '';
      _tiktokController.text = store.tiktok ?? '';
      _splitWhatsapp(store.whatsapp);
    }
  }

  void _splitWhatsapp(String? whatsappLink) {
    if (whatsappLink != null && whatsappLink.isNotEmpty) {
      try {
        String digits = whatsappLink.replaceAll(RegExp(r'\D'), '');
        if (digits.isNotEmpty) {
          String phoneWithPlus = '+$digits';
          PhoneNumber phoneNumber = PhoneNumber.parse(phoneWithPlus);
          setState(() {
            _whatsappDialCode = '+${phoneNumber.countryCode}';
            _whatsappController.text = phoneNumber.nsn;
          });
        }
      } catch (e) {
        debugPrint('WhatsApp Link Parse Error: $e');
        String val = whatsappLink;
        if (val.contains('wa.me/')) {
          val = val.substring(val.indexOf('wa.me/') + 6);
        }
        String digits = val.replaceAll(RegExp(r'\D'), '');
        setState(() {
          _whatsappController.text = digits;
        });
      }
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
              icon: Icons.facebook,
              color: Colors.blue,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            _buildSocialField(
              'Instagram',
              _instagramController,
              imagePath: Images.instagram,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            _buildSocialField(
              'TikTok',
              _tiktokController,
              imagePath: Images.tiktok,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // WhatsApp field with country code selection and real icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(Images.whatsapp, width: 20, height: 20),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text(
                      'WhatsApp',
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                CustomTextFieldWidget(
                  hintText: 'enter_whatsapp_number'.tr,
                  controller: _whatsappController,
                  inputType: TextInputType.phone,
                  isPhone: true,
                  countryDialCode: _whatsappDialCode,
                  onCountryChanged: (CountryCode countryCode) {
                    setState(() {
                      _whatsappDialCode = countryCode.dialCode;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            CustomButtonWidget(
              buttonText: 'update'.tr,
              onPressed: () async {
                String facebook = _facebookController.text.trim();
                String instagram = _instagramController.text.trim();
                String tiktok = _tiktokController.text.trim();
                String whatsapp = _whatsappController.text.trim();

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

                if (whatsapp.isEmpty) {
                  showCustomSnackBar('enter_whatsapp_number'.tr);
                  return;
                }

                // Normalization: strip leading '0'
                if (whatsapp.startsWith('0')) {
                  whatsapp = whatsapp.substring(1);
                }

                String dialCode = _whatsappDialCode ?? '+20';
                String cleanDialCode = dialCode.replaceAll('+', '');

                // Strip dial code if user entered it again
                if (whatsapp.startsWith(cleanDialCode)) {
                  whatsapp = whatsapp.substring(cleanDialCode.length);
                }

                // Construct standard WhatsApp Link
                String whatsappLink = 'https://wa.me/$cleanDialCode$whatsapp';

                Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                Response response = await Get.find<ApiClient>().postData(
                  AppConstants.updateSocialMediaUri,
                  {
                    'facebook': facebook,
                    'instagram': instagram,
                    'tiktok': tiktok,
                    'whatsapp': whatsappLink,
                  },
                );
                Get.back();

                if (response.statusCode == 200) {
                  profile.Store? store = Get.find<ProfileController>().profileModel?.stores?[0];
                  if (store != null) {
                    store.facebook = facebook;
                    store.instagram = instagram;
                    store.tiktok = tiktok;
                    store.whatsapp = whatsappLink;
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
    TextEditingController controller, {
    IconData? icon,
    String? imagePath,
    Color? color,
  }) {
    Widget iconWidget;
    if (imagePath != null) {
      if (imagePath.endsWith('.svg')) {
        iconWidget = SvgPicture.asset(imagePath, width: 20, height: 20);
      } else {
        iconWidget = Image.asset(imagePath, width: 20, height: 20);
      }
    } else if (icon != null) {
      iconWidget = Icon(icon, color: color, size: 20);
    } else {
      iconWidget = const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            iconWidget,
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
