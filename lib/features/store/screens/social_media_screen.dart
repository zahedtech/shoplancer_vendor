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
      _facebookController.text = _extractUsername(store.facebook, 'facebook');
      _instagramController.text = _extractUsername(store.instagram, 'instagram');
      _tiktokController.text = _extractUsername(store.tiktok, 'tiktok');
      _splitWhatsapp(store.whatsapp);
    }
  }

  String _extractUsername(String? url, String platform) {
    if (url == null || url.trim().isEmpty) return '';
    String val = url.trim();

    while (val.endsWith('/')) {
      val = val.substring(0, val.length - 1);
    }

    try {
      if (platform == 'facebook') {
        if (val.contains('facebook.com/')) {
          val = val.substring(val.indexOf('facebook.com/') + 13);
        }
      } else if (platform == 'instagram') {
        if (val.contains('instagram.com/')) {
          val = val.substring(val.indexOf('instagram.com/') + 14);
        }
      } else if (platform == 'tiktok') {
        if (val.contains('tiktok.com/@')) {
          val = val.substring(val.indexOf('tiktok.com/@') + 12);
        } else if (val.contains('tiktok.com/')) {
          val = val.substring(val.indexOf('tiktok.com/') + 11);
        }
      }
      if (val.startsWith('@')) {
        val = val.substring(1);
      }
      return val;
    } catch (_) {
      return url;
    }
  }

  String _formatUrl(String input, String platform) {
    String val = input.trim();
    if (val.isEmpty) return '';

    while (val.endsWith('/')) {
      val = val.substring(0, val.length - 1);
    }

    if (platform == 'facebook') {
      if (val.startsWith('http://') || val.startsWith('https://')) {
        return val;
      }
      if (val.startsWith('facebook.com/') || val.startsWith('www.facebook.com/')) {
        return 'https://$val';
      }
      if (val.startsWith('@')) val = val.substring(1);
      return 'https://facebook.com/$val';
    } else if (platform == 'instagram') {
      if (val.startsWith('http://') || val.startsWith('https://')) {
        return val;
      }
      if (val.startsWith('instagram.com/') || val.startsWith('www.instagram.com/')) {
        return 'https://$val';
      }
      if (val.startsWith('@')) val = val.substring(1);
      return 'https://instagram.com/$val';
    } else if (platform == 'tiktok') {
      if (val.startsWith('http://') || val.startsWith('https://')) {
        return val;
      }
      if (val.startsWith('tiktok.com/') || val.startsWith('www.tiktok.com/')) {
        return 'https://$val';
      }
      if (val.startsWith('@')) val = val.substring(1);
      return 'https://tiktok.com/@$val';
    }
    return val;
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
              prefixText: 'facebook.com/',
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            _buildSocialField(
              'Instagram',
              _instagramController,
              imagePath: Images.instagram,
              prefixText: 'instagram.com/',
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            _buildSocialField(
              'TikTok',
              _tiktokController,
              imagePath: Images.tiktok,
              prefixText: 'tiktok.com/@',
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
                String facebookInput = _facebookController.text.trim();
                String instagramInput = _instagramController.text.trim();
                String tiktokInput = _tiktokController.text.trim();
                String whatsappInput = _whatsappController.text.trim();

                if (facebookInput.isEmpty &&
                    instagramInput.isEmpty &&
                    tiktokInput.isEmpty &&
                    whatsappInput.isEmpty) {
                  showCustomSnackBar('يرجى إدخال اسم مستخدم أو رابط لوسيلة تواصل واحدة على الأقل');
                  return;
                }

                String facebookUrl = facebookInput.isNotEmpty ? _formatUrl(facebookInput, 'facebook') : '';
                String instagramUrl = instagramInput.isNotEmpty ? _formatUrl(instagramInput, 'instagram') : '';
                String tiktokUrl = tiktokInput.isNotEmpty ? _formatUrl(tiktokInput, 'tiktok') : '';

                String whatsappUrl = '';
                if (whatsappInput.isNotEmpty) {
                  if (whatsappInput.startsWith('0')) {
                    whatsappInput = whatsappInput.substring(1);
                  }
                  String dialCode = _whatsappDialCode ?? '+20';
                  String cleanDialCode = dialCode.replaceAll('+', '');
                  if (whatsappInput.startsWith(cleanDialCode)) {
                    whatsappInput = whatsappInput.substring(cleanDialCode.length);
                  }
                  whatsappUrl = 'https://wa.me/$cleanDialCode$whatsappInput';
                }

                Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                Response response = await Get.find<ApiClient>().postData(
                  AppConstants.updateSocialMediaUri,
                  {
                    'facebook': facebookUrl,
                    'instagram': instagramUrl,
                    'tiktok': tiktokUrl,
                    'whatsapp': whatsappUrl,
                  },
                );
                Get.back();

                if (response.statusCode == 200) {
                  profile.Store? store = Get.find<ProfileController>().profileModel?.stores?[0];
                  if (store != null) {
                    store.facebook = facebookUrl;
                    store.instagram = instagramUrl;
                    store.tiktok = tiktokUrl;
                    store.whatsapp = whatsappUrl;
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
    String? prefixText,
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
          hintText: Get.locale?.languageCode == 'ar' ? 'اسم المستخدم' : 'Username',
          controller: controller,
          inputType: TextInputType.text,
          prefixText: prefixText,
        ),
      ],
    );
  }
}
