import 'dart:convert';
import 'dart:async';
import 'package:shoplancer_vendor/common/models/response_model.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/confirmation_dialog_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_tool_tip_widget.dart';
import 'package:shoplancer_vendor/features/auth/controllers/auth_controller.dart';
import 'package:shoplancer_vendor/features/address/controllers/address_controller.dart';
import 'package:shoplancer_vendor/features/business/domain/models/package_model.dart';
import 'package:shoplancer_vendor/features/language/controllers/language_controller.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/store_body_model.dart';
import 'package:shoplancer_vendor/common/models/config_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/helper/validate_check.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/features/auth/widgets/custom_time_picker_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_time_picker_widget.dart'
    as common_time;
import 'package:shoplancer_vendor/features/address/widgets/select_location_module_view_widget.dart';

class StoreRegistrationScreen extends StatefulWidget {
  const StoreRegistrationScreen({super.key});

  @override
  State<StoreRegistrationScreen> createState() =>
      _StoreRegistrationScreenState();
}

class _StoreRegistrationScreenState extends State<StoreRegistrationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _nameController = [];
  final List<TextEditingController> _addressController = [];
  final TextEditingController tinNumberController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final List<FocusNode> _nameFocus = [];
  final List<FocusNode> _addressFocus = [];
  //final FocusNode _vatFocus = FocusNode();
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final TextEditingController _deliveryPriceController = TextEditingController(
    text: '20',
  );
  final FocusNode _deliveryPriceFocus = FocusNode();
  final TextEditingController _slugController = TextEditingController();
  final FocusNode _slugFocus = FocusNode();
  final TextEditingController _websiteColorController = TextEditingController(
    text: '#1E88E5',
  );
  final FocusNode _websiteColorFocus = FocusNode();
  Color? _selectedColor = const Color(0xFF1E88E5);
  String? _openingTime;
  String? _closingTime;
  bool _isOpen24Hours = false;
  final Map<int, int> _categoryProductLevels = {};
  Timer? _slugDebounce;
  final List<Language>? _languageList =
      Get.find<SplashController>().configModel!.language;

  final ScrollController _scrollController = ScrollController();
  String? _countryDialCode;
  bool firstTime = true;
  // ignore: unused_field
  TabController? _tabController;
  final List<Tab> _tabs = [];

  GlobalKey<FormState>? _formKeyLogin;
  GlobalKey<FormState>? _formKeySecond;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, initialIndex: 0, vsync: this);
    _countryDialCode = CountryCode.fromCountryCode(
      Get.find<SplashController>().configModel!.country!,
    ).dialCode;
    for (var language in _languageList!) {
      if (kDebugMode) {
        print(language);
      }
      _nameController.add(TextEditingController());
      _addressController.add(TextEditingController());
      _nameFocus.add(FocusNode());
      _addressFocus.add(FocusNode());
    }
    Get.find<AuthController>().resetData();
    Get.find<AuthController>().storeStatusChange(0.2, isUpdate: false);
    Get.find<AddressController>().getZoneList();
    Get.find<AuthController>().setDeliveryTimeTypeIndex(
      Get.find<AuthController>().deliveryTimeTypeList[0],
      false,
    );
    if (Get.find<AuthController>().showPassView) {
      Get.find<AuthController>().showHidePass(isUpdate: false);
    }
    Get.find<AuthController>().pickImageForReg(false, true);
    Get.find<AuthController>().resetBusiness();
    Get.find<AddressController>().clearPickupZone();

    _tabs.add(const Tab(text: 'Ø§ÙØªØ±Ø§Ø¶ÙŠ'));
    _formKeyLogin = GlobalKey<FormState>();
    _formKeySecond = GlobalKey<FormState>();
  }

  void openColorPicker() {
    final List<Color> presetColors = [
      const Color(0xFFE53935), // Red
      const Color(0xFFD81B60), // Pink
      const Color(0xFF8E24AA), // Purple
      const Color(0xFF5E35B1), // Deep Purple
      const Color(0xFF3949AB), // Indigo
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF039BE5), // Light Blue
      const Color(0xFF00ACC1), // Cyan
      const Color(0xFF00897B), // Teal
      const Color(0xFF43A047), // Green
      const Color(0xFF7CB342), // Light Green
      const Color(0xFFFDD835), // Yellow
      const Color(0xFFFFB300), // Amber
      const Color(0xFFF4511E), // Orange
      const Color(0xFF6D4C41), // Brown
      const Color(0xFF757575), // Grey
      const Color(0xFF000000), // Black
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusExtraLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'website_color'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: presetColors.length,
                itemBuilder: (context, index) {
                  final color = presetColors[index];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                        String hexString =
                            '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                        _websiteColorController.text = hexString;
                      });
                      Get.back();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
        ),
      ),
    );
  }

  void _openCustomColorPicker() {
    HSVColor hsvColor = HSVColor.fromColor(
      _selectedColor ?? const Color(0xFF1E88E5),
    );
    double hue = hsvColor.hue;
    double saturation = hsvColor.saturation;
    double value = hsvColor.value;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('select_color'.tr, style: robotoBold),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              Color previewColor = HSVColor.fromAHSV(
                1.0,
                hue,
                saturation,
                value,
              ).toColor();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: previewColor,
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault,
                      ),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Center(
                      child: Text(
                        '#${previewColor.value.toRadixString(16).substring(2).toUpperCase()}',
                        style: robotoBold.copyWith(
                          color: previewColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Hue Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hue (Ø§Ù„Ø¯Ø±Ø¬Ø©)',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      Container(
                        height: 12,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              for (var h = 0; h <= 360; h += 60)
                                HSVColor.fromAHSV(
                                  1.0,
                                  h.toDouble(),
                                  1.0,
                                  1.0,
                                ).toColor(),
                            ],
                          ),
                        ),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 12,
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: hue,
                            min: 0.0,
                            max: 360.0,
                            onChanged: (val) {
                              setStateDialog(() {
                                hue = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Saturation Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saturation (Ø§Ù„ØªØ´Ø¨Ø¹)',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      Container(
                        height: 12,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
                            ],
                          ),
                        ),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 12,
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: saturation,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) {
                              setStateDialog(() {
                                saturation = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Value Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Brightness (Ø§Ù„Ø³Ø·ÙˆØ¹)',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      Container(
                        height: 12,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black,
                              HSVColor.fromAHSV(
                                1.0,
                                hue,
                                saturation,
                                1.0,
                              ).toColor(),
                            ],
                          ),
                        ),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 12,
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: value,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) {
                              setStateDialog(() {
                                value = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'cancel'.tr,
                style: robotoRegular.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Color finalColor = HSVColor.fromAHSV(
                  1.0,
                  hue,
                  saturation,
                  value,
                ).toColor();
                setState(() {
                  _selectedColor = finalColor;
                  _websiteColorController.text =
                      '#${finalColor.value.toRadixString(16).substring(2).toUpperCase()}';
                });
                Navigator.pop(context);
              },
              child: Text(
                'ok'.tr,
                style: robotoBold.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkSlugAndProceed(AuthController authController) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    ResponseModel responseModel = await authController.checkSlug(
      _slugController.text.trim(),
    );
    Get.back();

    if (responseModel.isSuccess) {
      // Slug is available, proceed
    } else {
      showCustomSnackBar(
        (responseModel.message != null && responseModel.message!.isNotEmpty)
            ? responseModel.message!.tr
            : 'slug_already_exists'.tr,
      );
      return;
    }

    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    authController.storeStatusChange(0.6);
    firstTime = true;
  }

  void _onSlugChanged(String text) {
    if (_slugDebounce?.isActive ?? false) _slugDebounce!.cancel();

    setState(() {});

    _slugDebounce = Timer(const Duration(milliseconds: 500), () async {
      await Get.find<AuthController>().checkSlug(text.trim());
    });
  }

  @override
  void dispose() {
    _slugDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        return GetBuilder<AddressController>(
          builder: (addressController) {
            if (addressController.storeAddress != null &&
                _languageList!.isNotEmpty) {
              _addressController[0].text = addressController.storeAddress
                  .toString();
            }

            bool isSubscriptionAvailable =
                Get.find<SplashController>()
                        .configModel
                        ?.subscriptionBusinessModel !=
                    0 &&
                !GetPlatform.isIOS &&
                authController.packageModel?.packages != null &&
                authController.packageModel!.packages!.isNotEmpty;
            bool isCommissionAvailable =
                Get.find<SplashController>()
                    .configModel
                    ?.commissionBusinessModel !=
                0;
            bool showToggle = isSubscriptionAvailable && isCommissionAvailable;

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (authController.storeStatus == 0.4) {
                  authController.storeStatusChange(0.2);
                } else if (authController.storeStatus == 0.6) {
                  authController.storeStatusChange(0.4);
                } else if (authController.storeStatus == 0.8) {
                  authController.storeStatusChange(0.6);
                } else if (authController.storeStatus == 0.9) {
                  authController.storeStatusChange(0.8);
                } else {
                  await _showBackPressedDialogue(
                    'your_registration_not_setup_yet'.tr,
                  );
                }
              },
              child: Scaffold(
                appBar: CustomAppBarWidget(
                  title: 'vendor_registration'.tr,
                  onTap: () async {
                    if (authController.storeStatus == 0.4) {
                      authController.storeStatusChange(0.2);
                    } else if (authController.storeStatus == 0.6) {
                      authController.storeStatusChange(0.4);
                    } else if (authController.storeStatus == 0.8) {
                      authController.storeStatusChange(0.6);
                    } else if (authController.storeStatus == 0.9) {
                      authController.storeStatusChange(0.8);
                    } else {
                      await _showBackPressedDialogue(
                        'your_registration_not_setup_yet'.tr,
                      );
                    }
                  },
                ),

                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                        vertical: Dimensions.paddingSizeSmall,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authController.storeStatus == 0.2
                                ? 'provide_vendor_information_to_proceed_next'
                                      .tr
                                : authController.storeStatus == 0.4
                                ? 'vendor_preference'.tr
                                : authController.storeStatus == 0.6
                                ? 'provide_owner_information_to_confirm'.tr
                                : authController.storeStatus == 0.8
                                ? 'select_categories'.tr
                                : 'you_are_one_step_away_choose_your_business_plan'
                                      .tr,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          LinearProgressIndicator(
                            backgroundColor: Theme.of(context).disabledColor,
                            minHeight: 2,
                            value: authController.storeStatus,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeSmall,
                          horizontal: Dimensions.paddingSizeDefault,
                        ),
                        child: Column(
                          children: [
                            Visibility(
                              visible: authController.storeStatus == 0.2,
                              maintainState: true,
                              child: Form(
                                key: _formKeyLogin,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'vendor_info'.tr,
                                      style: robotoBold.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeDefault,
                                    ),

                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.radiusDefault,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeSmall,
                                      ),
                                      child: CustomTextFieldWidget(
                                        hintText: 'write_vendor_name'.tr,
                                        labelText: 'vendor_name'.tr,
                                        controller: _nameController[0],
                                        focusNode: _nameFocus[0],
                                        nextFocus: _addressFocus[0],
                                        inputType: TextInputType.name,
                                        prefixImage: Images.shopIcon,
                                        capitalization:
                                            TextCapitalization.words,
                                        required: true,
                                        validator: (value) =>
                                            ValidateCheck.validateEmptyText(
                                              value,
                                              "vendor_name_field_is_required"
                                                  .tr,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeDefault,
                                    ),

                                    Text(
                                      'location_info'.tr,
                                      style: robotoBold.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeDefault,
                                    ),

                                    addressController.zoneList != null
                                        ? SelectLocationAndModuleViewWidget(
                                            fromView: true,
                                            addressController:
                                                _addressController[0],
                                            addressFocus: _addressFocus[0],
                                          )
                                        : const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                  ],
                                ),
                              ),
                            ),

                            Visibility(
                              visible: authController.storeStatus == 0.4,
                              maintainState: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'vendor_preference'.tr,
                                    style: robotoBold.copyWith(
                                      fontSize: Dimensions.fontSizeLarge,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: Dimensions.paddingSizeDefault,
                                  ),

                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusDefault,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeSmall,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          height: Dimensions.paddingSizeSmall,
                                        ),
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: CustomTextFieldWidget(
                                            hintText: 'enter_slug'.tr,
                                            labelText: 'slug'.tr,
                                            controller: _slugController,
                                            focusNode: _slugFocus,
                                            inputType: TextInputType.text,
                                            required: true,
                                            prefixText:
                                                'https://store.shoplanser.com/',
                                            onChanged: (text) =>
                                                _onSlugChanged(text),
                                            validator: (value) =>
                                                ValidateCheck.validateEmptyText(
                                                  value,
                                                  "enter_slug".tr,
                                                ),
                                          ),
                                        ),
                                        if (authController.isSlugAvailable !=
                                                null &&
                                            _slugController.text
                                                .trim()
                                                .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: Dimensions
                                                  .paddingSizeExtraSmall,
                                              left: Dimensions.paddingSizeSmall,
                                              right:
                                                  Dimensions.paddingSizeSmall,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  authController
                                                          .isSlugAvailable!
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color:
                                                      authController
                                                          .isSlugAvailable!
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    authController
                                                        .slugValidationMessage
                                                        .tr,
                                                    style: robotoRegular.copyWith(
                                                      color:
                                                          authController
                                                              .isSlugAvailable!
                                                          ? Colors.green
                                                          : Colors.red,
                                                      fontSize: Dimensions
                                                          .fontSizeSmall,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeLarge,
                                        ),

                                        CustomTextFieldWidget(
                                          hintText: 'enter_website_color'.tr,
                                          labelText: 'website_color'.tr,
                                          controller: _websiteColorController,
                                          focusNode: _websiteColorFocus,
                                          inputType: TextInputType.text,
                                          required: true,
                                          validator: (value) =>
                                              ValidateCheck.validateEmptyText(
                                                value,
                                                "enter_website_color".tr,
                                              ),
                                          suffixChild: InkWell(
                                            onTap: _openCustomColorPicker,
                                            child: Container(
                                              width: 30,
                                              height: 30,
                                              margin: const EdgeInsets.only(
                                                right: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    _selectedColor ??
                                                    Colors.blue,
                                                border: Border.all(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeSmall,
                                        ),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              ...[
                                                const Color(0xFFE53935),
                                                const Color(0xFFD81B60),
                                                const Color(0xFF8E24AA),
                                                const Color(0xFF5E35B1),
                                                const Color(0xFF3949AB),
                                                const Color(0xFF1E88E5),
                                                const Color(0xFF039BE5),
                                                const Color(0xFF00ACC1),
                                                const Color(0xFF00897B),
                                                const Color(0xFF43A047),
                                                const Color(0xFF7CB342),
                                                const Color(0xFFFDD835),
                                                const Color(0xFFFFB300),
                                                const Color(0xFFF4511E),
                                                const Color(0xFF6D4C41),
                                                const Color(0xFF757575),
                                                const Color(0xFF000000),
                                              ].map((color) {
                                                bool isSelected =
                                                    _selectedColor?.value ==
                                                    color.value;
                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedColor = color;
                                                      _websiteColorController
                                                              .text =
                                                          '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                                                    });
                                                  },
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                          vertical: 4,
                                                        ),
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? Theme.of(
                                                                context,
                                                              ).primaryColor
                                                            : Colors.grey
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                        width: isSelected
                                                            ? 3
                                                            : 1,
                                                      ),
                                                      boxShadow: isSelected
                                                          ? [
                                                              BoxShadow(
                                                                color: color
                                                                    .withOpacity(
                                                                      0.4,
                                                                    ),
                                                                blurRadius: 4,
                                                                spreadRadius: 1,
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              }),
                                              GestureDetector(
                                                onTap: _openCustomColorPicker,
                                                child: Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 4,
                                                      ),
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient:
                                                        const SweepGradient(
                                                          colors: [
                                                            Colors.red,
                                                            Colors.yellow,
                                                            Colors.green,
                                                            Colors.cyan,
                                                            Colors.blue,
                                                            Colors.purple,
                                                            Colors.red,
                                                          ],
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.grey,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.colorize,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeLarge,
                                        ),

                                        CustomTextFieldWidget(
                                          hintText: 'enter_delivery_fee'.tr,
                                          labelText: 'delivery_fee'.tr,
                                          controller: _deliveryPriceController,
                                          focusNode: _deliveryPriceFocus,
                                          inputType: TextInputType.number,
                                          prefixImage: Images.money,
                                          required: true,
                                          validator: (value) =>
                                              ValidateCheck.validateEmptyText(
                                                value,
                                                "enter_delivery_fee".tr,
                                              ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeLarge,
                                        ),

                                        InkWell(
                                          onTap: () {
                                            Get.dialog(
                                              const CustomTimePickerWidget(),
                                            );
                                          },
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).cardColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions
                                                            .radiusDefault,
                                                      ),
                                                  border: Border.all(
                                                    color: Theme.of(
                                                      context,
                                                    ).disabledColor,
                                                    width: 0.5,
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: Dimensions
                                                          .paddingSizeLarge,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '${authController.storeMinTime} : ${authController.storeMaxTime} ${authController.storeTimeUnit.tr}',
                                                        style: robotoMedium,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.access_time_filled,
                                                      color: Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              Positioned(
                                                left: 10,
                                                top: -15,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(
                                                      context,
                                                    ).cardColor,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    5,
                                                  ),
                                                  child: RichText(
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'select_time'.tr,
                                                          style: robotoRegular.copyWith(
                                                            color: Theme.of(
                                                              context,
                                                            ).disabledColor,
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text: ' *'.tr,
                                                          style: robotoRegular.copyWith(
                                                            color: Colors.red,
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeDefault,
                                        ),
                                        CheckboxListTile(
                                          title: Text(
                                            'open_24_hours'.tr,
                                            style: robotoRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                          value: _isOpen24Hours,
                                          activeColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          onChanged: (bool? val) {
                                            setState(() {
                                              _isOpen24Hours = val ?? false;
                                            });
                                          },
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeDefault,
                                        ),
                                        Visibility(
                                          visible: !_isOpen24Hours,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child:
                                                    common_time.CustomTimePickerWidget(
                                                      title: 'open_time'.tr,
                                                      time: _openingTime,
                                                      onTimeChanged: (time) {
                                                        setState(() {
                                                          _openingTime = time;
                                                        });
                                                      },
                                                    ),
                                              ),
                                              const SizedBox(
                                                width: Dimensions
                                                    .paddingSizeDefault,
                                              ),
                                              Expanded(
                                                child:
                                                    common_time.CustomTimePickerWidget(
                                                      title: 'close_time'.tr,
                                                      time: _closingTime,
                                                      onTimeChanged: (time) {
                                                        setState(() {
                                                          _closingTime = time;
                                                        });
                                                      },
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Visibility(
                              visible: authController.storeStatus == 0.6,
                              maintainState: true,
                              child: Form(
                                key: _formKeySecond,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'owner_info'.tr,
                                          style: robotoBold.copyWith(
                                            fontSize: Dimensions.fontSizeLarge,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: Dimensions.paddingSizeSmall,
                                        ),

                                        CustomToolTip(
                                          message:
                                              'this_info_will_need_for_vendor_app_and_panel_login'
                                                  .tr,
                                          preferredDirection:
                                              AxisDirection.down,
                                          iconColor: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color
                                              ?.withValues(alpha: 0.7),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeDefault,
                                    ),

                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.radiusDefault,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withValues(
                                              alpha: 0.1,
                                            ),
                                            spreadRadius: 1,
                                            blurRadius: 10,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Dimensions.paddingSizeSmall,
                                        vertical: Dimensions.paddingSizeDefault,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CustomTextFieldWidget(
                                            hintText: 'enter_your_full_name'.tr,
                                            controller: _fullNameController,
                                            focusNode: _fullNameFocus,
                                            nextFocus: _phoneFocus,
                                            inputType: TextInputType.name,
                                            capitalization:
                                                TextCapitalization.words,
                                            prefixIcon: CupertinoIcons
                                                .person_crop_circle_fill,
                                            iconSize: 25,
                                            required: true,
                                            labelText: 'full_name'.tr,
                                            validator: (value) =>
                                                ValidateCheck.validateEmptyText(
                                                  value,
                                                  "full_name_field_is_required"
                                                      .tr,
                                                ),
                                          ),
                                          const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtremeLarge,
                                          ),

                                          CustomTextFieldWidget(
                                            hintText: 'enter_phone_number'.tr,
                                            controller: _phoneController,
                                            focusNode: _phoneFocus,
                                            nextFocus: _emailFocus,
                                            inputType: TextInputType.phone,
                                            isPhone: true,
                                            onCountryChanged:
                                                (CountryCode countryCode) {
                                                  _countryDialCode =
                                                      countryCode.dialCode;
                                                },
                                            countryDialCode:
                                                _countryDialCode != null
                                                ? CountryCode.fromCountryCode(
                                                    Get.find<SplashController>()
                                                        .configModel!
                                                        .country!,
                                                  ).code
                                                : Get.find<
                                                        LocalizationController
                                                      >()
                                                      .locale
                                                      .countryCode,
                                            required: true,
                                            labelText: 'phone'.tr,
                                            validator: (value) =>
                                                ValidateCheck.validateEmptyText(
                                                  value,
                                                  null,
                                                ),
                                          ),
                                          const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtremeLarge,
                                          ),

                                          CustomTextFieldWidget(
                                            hintText: 'write_email'.tr,
                                            controller: _emailController,
                                            focusNode: _emailFocus,
                                            nextFocus: _passwordFocus,
                                            inputType:
                                                TextInputType.emailAddress,
                                            prefixIcon: Icons.email,
                                            iconSize: 25,
                                            required: false,
                                            labelText: 'email'.tr,
                                            validator: (value) =>
                                                (value != null &&
                                                    value.isNotEmpty)
                                                ? ValidateCheck.validateEmail(
                                                    value,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtremeLarge,
                                          ),

                                          Column(
                                            children: [
                                              CustomTextFieldWidget(
                                                hintText: 'password'.tr,
                                                controller: _passwordController,
                                                focusNode: _passwordFocus,
                                                nextFocus:
                                                    _confirmPasswordFocus,
                                                inputType: TextInputType
                                                    .visiblePassword,
                                                prefixIcon: Icons.lock,
                                                iconSize: 25,
                                                isPassword: true,
                                                required: true,
                                                labelText: 'password'.tr,
                                                validator: (value) =>
                                                    ValidateCheck.validateEmptyText(
                                                      value,
                                                      "password_field_is_required"
                                                          .tr,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtremeLarge,
                                          ),

                                          CustomTextFieldWidget(
                                            hintText: 'confirm_password'.tr,
                                            controller:
                                                _confirmPasswordController,
                                            focusNode: _confirmPasswordFocus,
                                            inputType:
                                                TextInputType.visiblePassword,
                                            inputAction: TextInputAction.done,
                                            prefixIcon: Icons.lock,
                                            iconSize: 25,
                                            isPassword: true,
                                            required: true,
                                            labelText: 'confirm_password'.tr,
                                            validator: (value) =>
                                                ValidateCheck.validateConfirmPassword(
                                                  value,
                                                  _passwordController.text,
                                                ),
                                          ),
                                          // const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Visibility(
                              visible: authController.storeStatus == 0.8,
                              child: Column(
                                children: [
                                  // Categories Selection Section
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeLarge,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          height: Dimensions.paddingSizeLarge,
                                        ),
                                        Text(
                                          'select_categories'.tr,
                                          style: robotoBold,
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeSmall,
                                        ),

                                        authController.categoriesLoading
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(
                                                    Dimensions.paddingSizeLarge,
                                                  ),
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              )
                                            : (authController
                                                          .registrationCategories ==
                                                      null ||
                                                  authController
                                                      .registrationCategories!
                                                      .isEmpty)
                                            ? Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    Dimensions.paddingSizeLarge,
                                                  ),
                                                  child: Text(
                                                    'no_categories_found'.tr,
                                                    style: robotoMedium
                                                        .copyWith(
                                                          color: Theme.of(
                                                            context,
                                                          ).disabledColor,
                                                        ),
                                                  ),
                                                ),
                                              )
                                            : GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                gridDelegate:
                                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2,
                                                      crossAxisSpacing: 10,
                                                      mainAxisSpacing: 10,
                                                      childAspectRatio: 2.8,
                                                    ),
                                                itemCount: authController
                                                    .registrationCategories!
                                                    .length,
                                                itemBuilder: (context, index) {
                                                  final category = authController
                                                      .registrationCategories![index];
                                                  bool isSelected =
                                                      authController
                                                          .selectedCategoryIds
                                                          .contains(
                                                            category.id,
                                                          );
                                                  return InkWell(
                                                    onTap: () => authController
                                                        .toggleCategorySelection(
                                                          category.id!,
                                                        ),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(
                                                          context,
                                                        ).cardColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              Dimensions
                                                                  .radiusDefault,
                                                            ),
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? Theme.of(
                                                                  context,
                                                                ).primaryColor
                                                              : Theme.of(
                                                                      context,
                                                                    )
                                                                    .disabledColor
                                                                    .withOpacity(
                                                                      0.15,
                                                                    ),
                                                          width: isSelected
                                                              ? 2
                                                              : 1,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                  0.03,
                                                                ),
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: Dimensions
                                                            .paddingSizeSmall,
                                                        vertical: Dimensions
                                                            .paddingSizeExtraSmall,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          category.name ?? '',
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: robotoBold.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                            color: isSelected
                                                                ? Theme.of(
                                                                    context,
                                                                  ).primaryColor
                                                                : Theme.of(
                                                                        context,
                                                                      )
                                                                      .textTheme
                                                                      .bodyLarge
                                                                      ?.color,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),

                                        if (authController
                                            .selectedCategoryIds
                                            .isNotEmpty) ...[
                                          const SizedBox(
                                            height: Dimensions.paddingSizeLarge,
                                          ),
                                          Text(
                                            'product_addition_options'.tr,
                                            style: robotoBold,
                                          ),
                                          const SizedBox(
                                            height: Dimensions.paddingSizeSmall,
                                          ),

                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: authController
                                                .selectedCategoryIds
                                                .length,
                                            itemBuilder: (context, catIdx) {
                                              int catId = authController
                                                  .selectedCategoryIds[catIdx];
                                              String catName = '';
                                              if (authController
                                                      .registrationCategories !=
                                                  null) {
                                                for (var cat
                                                    in authController
                                                        .registrationCategories!) {
                                                  if (cat.id == catId) {
                                                    catName = cat.name ?? '';
                                                    break;
                                                  }
                                                }
                                              }

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: Dimensions
                                                              .paddingSizeSmall,
                                                        ),
                                                    child: Text(
                                                      catName,
                                                      style: robotoBold.copyWith(
                                                        color: Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                      ),
                                                    ),
                                                  ),

                                                  _buildProductLevelOption(
                                                    categoryId: catId,
                                                    level: 1,
                                                    title:
                                                        'add_basic_products'.tr,
                                                    subtitle:
                                                        'add_basic_products_desc'
                                                            .tr,
                                                    icon: Icons.star_border,
                                                  ),
                                                  const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeSmall,
                                                  ),

                                                  _buildProductLevelOption(
                                                    categoryId: catId,
                                                    level: 2,
                                                    title:
                                                        'add_additional_products'
                                                            .tr,
                                                    subtitle:
                                                        'add_additional_products_desc'
                                                            .tr,
                                                    icon: Icons
                                                        .add_circle_outline,
                                                  ),
                                                  const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeSmall,
                                                  ),

                                                  _buildProductLevelOption(
                                                    categoryId: catId,
                                                    level: 3,
                                                    title:
                                                        'no_products_added'.tr,
                                                    subtitle:
                                                        'no_products_added_desc'
                                                            .tr,
                                                    icon: Icons.block,
                                                  ),
                                                  const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeDefault,
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Visibility(
                              visible: authController.storeStatus == 0.9,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: Dimensions.paddingSizeLarge,
                                      bottom: Dimensions.paddingSizeLarge,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'choose_your_business_plan'.tr,
                                        style: robotoBold,
                                      ),
                                    ),
                                  ),

                                  Builder(
                                    builder: (context) {
                                      List<Packages> allPackages = [];
                                      bool isCommissionAvailable =
                                          Get.find<SplashController>()
                                              .configModel!
                                              .commissionBusinessModel !=
                                          0;
                                      bool isSubscriptionAvailable =
                                          Get.find<SplashController>()
                                                  .configModel!
                                                  .subscriptionBusinessModel !=
                                              0 &&
                                          !GetPlatform.isIOS;

                                      if (isCommissionAvailable) {
                                        allPackages.add(
                                          Packages(
                                            id: -1,
                                            packageName: 'commission_base'.tr,
                                            price:
                                                Get.find<SplashController>()
                                                    .configModel!
                                                    .adminCommission
                                                    ?.toDouble() ??
                                                0,
                                            description:
                                                "${'vendor_will_pay'.tr} ${Get.find<SplashController>().configModel!.adminCommission}% ${'commission_on_sales'.tr}",
                                          ),
                                        );
                                      }

                                      if (isSubscriptionAvailable &&
                                          authController.packageModel != null &&
                                          authController
                                                  .packageModel!
                                                  .packages !=
                                              null) {
                                        allPackages.addAll(
                                          authController
                                              .packageModel!
                                              .packages!,
                                        );
                                      }

                                      if (authController.packageModel == null &&
                                          isSubscriptionAvailable) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                              Dimensions
                                                  .paddingSizeExtremeLarge,
                                            ),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      if (allPackages.isEmpty) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(
                                              Dimensions
                                                  .paddingSizeExtremeLarge,
                                            ),
                                            child: Text(
                                              'no_package_available'.tr,
                                              style: robotoMedium,
                                            ),
                                          ),
                                        );
                                      }

                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 10,
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            children: List.generate(allPackages.length, (
                                              index,
                                            ) {
                                              final package =
                                                  allPackages[index];
                                              bool isCommission =
                                                  package.id == -1;

                                              bool isHighlighted = false;
                                              if (allPackages.length > 1) {
                                                isHighlighted = index == 1;
                                              } else {
                                                isHighlighted = index == 0;
                                              }

                                              bool isSelected = false;
                                              int originalIndex = -1;
                                              if (isCommission) {
                                                isSelected =
                                                    authController
                                                        .businessIndex ==
                                                    0;
                                              } else {
                                                originalIndex = authController
                                                    .packageModel!
                                                    .packages!
                                                    .indexOf(package);
                                                isSelected =
                                                    authController
                                                            .businessIndex ==
                                                        1 &&
                                                    authController
                                                            .activeSubscriptionIndex ==
                                                        originalIndex;
                                              }

                                              final Color cardBgColor =
                                                  isHighlighted
                                                  ? const Color(0xFF0F255C)
                                                  : Colors.white;
                                              final Color textColor =
                                                  isHighlighted
                                                  ? Colors.white
                                                  : const Color(0xFF0F255C);
                                              final Color featureTextColor =
                                                  isHighlighted
                                                  ? Colors.white.withOpacity(
                                                      0.9,
                                                    )
                                                  : Colors.black87;
                                              final Color subtitleColor =
                                                  isHighlighted
                                                  ? Colors.white70
                                                  : Colors.grey;

                                              final decoration = isHighlighted
                                                  ? BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(0xFF0F255C),
                                                              Color(0xFF0A142F),
                                                            ],
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      border: isSelected
                                                          ? Border.all(
                                                              color:
                                                                  const Color(
                                                                    0xFFFF8A00,
                                                                  ),
                                                              width: 3,
                                                            )
                                                          : null,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                            0xFF0F255C,
                                                          ).withOpacity(0.3),
                                                          blurRadius: 10,
                                                          spreadRadius: 2,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? const Color(
                                                                0xFFFF8A00,
                                                              )
                                                            : Colors.grey
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                        width: isSelected
                                                            ? 3
                                                            : 1,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.04,
                                                              ),
                                                          blurRadius: 8,
                                                          spreadRadius: 1,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    );

                                              String subBadgeText = '';
                                              if (isCommission) {
                                                subBadgeText =
                                                    '${(package.price ?? 0).toInt()}% ${'commission_on_sales'.tr}';
                                              } else {
                                                subBadgeText =
                                                    (package.text != null &&
                                                        package
                                                            .text!
                                                            .isNotEmpty)
                                                    ? package.text!
                                                    : '${'subscribe_now'.tr} ${'free_month_promo'.tr}';
                                              }

                                              List<String> featureItems = [
                                                'online_store_ready_for_launch'
                                                    .tr,
                                                'all_products_and_categories_prebuilt'
                                                    .tr,
                                                'instant_price_and_product_update'
                                                    .tr,
                                                'professional_merchant_app'.tr,
                                                'marketing_consultations'.tr,
                                                'technical_support_24_7'.tr,
                                                isCommission
                                                    ? '${'commission_on_sales'.tr} (${(package.price ?? 0).toInt()}%)'
                                                    : 'no_commission_on_sales'
                                                          .tr,
                                              ];

                                              return Container(
                                                width: 290,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                decoration: decoration,
                                                padding: const EdgeInsets.all(
                                                  20,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      package.packageName ?? '',
                                                      style: robotoBold.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeExtraLarge,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),

                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .baseline,
                                                      textBaseline: TextBaseline
                                                          .alphabetic,
                                                      children: [
                                                        Text(
                                                          isCommission
                                                              ? 'free'.tr
                                                              : '${(package.price ?? 0).toInt()}',
                                                          style: robotoBold
                                                              .copyWith(
                                                                fontSize: 32,
                                                                color:
                                                                    const Color(
                                                                      0xFFFF8A00,
                                                                    ),
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          Get.find<
                                                                    SplashController
                                                                  >()
                                                                  .configModel!
                                                                  .currencySymbol ??
                                                              'EGP',
                                                          style: robotoRegular
                                                              .copyWith(
                                                                fontSize: 14,
                                                                color:
                                                                    subtitleColor,
                                                              ),
                                                        ),
                                                        if (!isCommission) ...[
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            '/ ${'month'.tr}',
                                                            style: robotoRegular
                                                                .copyWith(
                                                                  fontSize: 14,
                                                                  color:
                                                                      subtitleColor,
                                                                ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 15),

                                                    Container(
                                                      width: double.infinity,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isHighlighted
                                                            ? Colors.white
                                                                  .withOpacity(
                                                                    0.08,
                                                                  )
                                                            : Colors.grey
                                                                  .withOpacity(
                                                                    0.05,
                                                                  ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: isHighlighted
                                                            ? Border.all(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.12,
                                                                    ),
                                                                width: 1,
                                                              )
                                                            : Border.all(
                                                                color: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                width: 1,
                                                              ),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.verified_user,
                                                            size: 14,
                                                            color: isHighlighted
                                                                ? const Color(
                                                                    0xFFFF8A00,
                                                                  )
                                                                : const Color(
                                                                    0xFF0F255C,
                                                                  ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              subBadgeText,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: robotoMedium.copyWith(
                                                                fontSize: 11,
                                                                color:
                                                                    isHighlighted
                                                                    ? Colors
                                                                          .white
                                                                    : const Color(
                                                                        0xFF0F255C,
                                                                      ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),

                                                    Expanded(
                                                      child: Column(
                                                        children: featureItems.map((
                                                          feature,
                                                        ) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 4,
                                                                ),
                                                            child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                const Icon(
                                                                  Icons.check,
                                                                  size: 16,
                                                                  color: Color(
                                                                    0xFFFF8A00,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    feature,
                                                                    style: robotoRegular.copyWith(
                                                                      fontSize:
                                                                          Dimensions
                                                                              .fontSizeSmall,
                                                                      color:
                                                                          featureTextColor,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),

                                                    SizedBox(
                                                      width: double.infinity,
                                                      height: 45,
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              isHighlighted
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF0F255C,
                                                                ),
                                                          foregroundColor:
                                                              isHighlighted
                                                              ? const Color(
                                                                  0xFF0F255C,
                                                                )
                                                              : Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          elevation: 0,
                                                        ),
                                                        onPressed: () {
                                                          if (isCommission) {
                                                            authController
                                                                .setBusiness(0);
                                                          } else {
                                                            authController
                                                                .setBusiness(1);
                                                            authController
                                                                .selectSubscriptionCard(
                                                                  originalIndex,
                                                                );
                                                          }
                                                        },
                                                        child: Text(
                                                          isSelected
                                                              ? 'selected'.tr
                                                              : 'subscribe_now'
                                                                    .tr,
                                                          style: robotoBold.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CustomButtonWidget(
                          buttonText: authController.storeStatus == 0.9
                              ? 'submit'.tr
                              : 'next'.tr,
                          isLoading: authController.isLoading,
                          margin: const EdgeInsets.all(
                            Dimensions.paddingSizeSmall,
                          ),
                          onPressed: () {
                            bool defaultNameNull = false;
                            // ignore: unused_local_variable
                            bool defaultAddressNull = false;

                            if (_nameController[0].text.trim().isEmpty) {
                              defaultNameNull = true;
                            }
                            if (_addressController[0].text.trim().isEmpty) {
                              defaultAddressNull = true;
                            }
                            String tin = "123456789";
                            String minTime = authController.storeMinTime;
                            String maxTime = authController.storeMaxTime;
                            String fullName = _fullNameController.text.trim();
                            String fName = '';
                            String lName = '';
                            List<String> nameParts = fullName.split(' ');
                            if (nameParts.isNotEmpty) {
                              fName = nameParts[0];
                              if (nameParts.length > 1) {
                                lName = nameParts.sublist(1).join(' ');
                              } else {
                                lName = '-';
                              }
                            }
                            String phone = _phoneController.text.trim();
                            if (phone.startsWith('0')) {
                              phone = phone.substring(1);
                            }
                            String password = _passwordController.text.trim();
                            // ignore: unused_local_variable
                            String confirmPassword = _confirmPasswordController
                                .text
                                .trim();
                            String phoneWithCountryCode =
                                _countryDialCode! + phone;
                            String email = _emailController.text.trim();
                            if (email.isEmpty) {
                              email = '$phoneWithCountryCode@gmail.com';
                            }
                            bool valid = false;
                            bool isRentalModule =
                                addressController.moduleList != null &&
                                addressController.selectedModuleIndex != -1 &&
                                addressController
                                        .moduleList![addressController
                                            .selectedModuleIndex!]
                                        .moduleType ==
                                    'rental';

                            try {
                              double.parse(maxTime);
                              double.parse(minTime);
                              valid = true;
                            } on FormatException {
                              valid = false;
                            }

                            if (authController.storeStatus == 0.2 ||
                                authController.storeStatus == 0.4 ||
                                authController.storeStatus == 0.6 ||
                                authController.storeStatus == 0.8) {
                              if (authController.storeStatus == 0.2) {
                                if (_formKeyLogin!.currentState!.validate()) {
                                  if (defaultNameNull) {
                                    showCustomSnackBar('enter_vendor_name'.tr);
                                  } else if (addressController
                                          .selectedZoneIndex ==
                                      -1) {
                                    showCustomSnackBar('please_select_zone'.tr);
                                  } else if (addressController
                                          .selectedModuleIndex ==
                                      -1) {
                                    showCustomSnackBar(
                                      'please_select_module_first'.tr,
                                    );
                                  } else if (isRentalModule &&
                                      addressController
                                          .pickupZoneIdList
                                          .isEmpty) {
                                    showCustomSnackBar(
                                      'please_select_pickup_zone'.tr,
                                    );
                                  } else if (addressController
                                          .restaurantLocation ==
                                      null) {
                                    showCustomSnackBar(
                                      'set_vendor_location'.tr,
                                    );
                                  } else {
                                    _scrollController.jumpTo(
                                      _scrollController
                                          .position
                                          .minScrollExtent,
                                    );
                                    authController.storeStatusChange(0.4);
                                  }
                                }
                              } else if (authController.storeStatus == 0.4) {
                                if (_slugController.text.trim().isEmpty) {
                                  showCustomSnackBar('enter_slug'.tr);
                                } else if (_websiteColorController.text
                                    .trim()
                                    .isEmpty) {
                                  showCustomSnackBar('enter_website_color'.tr);
                                } else if (_deliveryPriceController.text
                                    .trim()
                                    .isEmpty) {
                                  showCustomSnackBar('enter_delivery_fee'.tr);
                                } else if (!_isOpen24Hours &&
                                    _openingTime == null) {
                                  showCustomSnackBar('pick_start_time'.tr);
                                } else if (!_isOpen24Hours &&
                                    _closingTime == null) {
                                  showCustomSnackBar('pick_end_time'.tr);
                                } else if (minTime.isEmpty) {
                                  showCustomSnackBar(
                                    'enter_minimum_delivery_time'.tr,
                                  );
                                } else if (maxTime.isEmpty) {
                                  showCustomSnackBar(
                                    'enter_maximum_delivery_time'.tr,
                                  );
                                } else if (!valid) {
                                  showCustomSnackBar(
                                    'please_enter_the_max_min_delivery_time'.tr,
                                  );
                                } else if (valid &&
                                    double.parse(minTime) >
                                        double.parse(maxTime)) {
                                  showCustomSnackBar(
                                    'maximum_delivery_time_can_not_be_smaller_then_minimum_delivery_time'
                                        .tr,
                                  );
                                } else {
                                  _checkSlugAndProceed(authController);
                                }
                              } else if (authController.storeStatus == 0.6) {
                                if (_formKeySecond!.currentState!.validate()) {
                                  _scrollController.jumpTo(
                                    _scrollController.position.minScrollExtent,
                                  );
                                  authController.getRegistrationCategories(
                                    zoneId: addressController
                                        .zoneList![addressController
                                            .selectedZoneIndex!]
                                        .id
                                        .toString(),
                                    moduleId: addressController
                                        .moduleList![addressController
                                            .selectedModuleIndex!]
                                        .id
                                        .toString(),
                                    latitude: addressController
                                        .restaurantLocation!
                                        .latitude
                                        .toString(),
                                    longitude: addressController
                                        .restaurantLocation!
                                        .longitude
                                        .toString(),
                                  );
                                  authController.storeStatusChange(0.8);
                                }
                              } else if (authController.storeStatus == 0.8) {
                                if (authController.registrationCategories !=
                                        null &&
                                    authController
                                        .registrationCategories!
                                        .isNotEmpty &&
                                    authController
                                        .selectedCategoryIds
                                        .isEmpty) {
                                  showCustomSnackBar(
                                    'select_at_least_one_category'.tr,
                                  );
                                  return;
                                }
                                _scrollController.jumpTo(
                                  _scrollController.position.minScrollExtent,
                                );
                                authController.storeStatusChange(0.9);
                              }
                            } else {
                              List<Translation> translation = [];
                              for (
                                int index = 0;
                                index < _languageList!.length;
                                index++
                              ) {
                                translation.add(
                                  Translation(
                                    locale: _languageList[index].key,
                                    key: 'name',
                                    value:
                                        _nameController[index].text
                                            .trim()
                                            .isNotEmpty
                                        ? _nameController[index].text.trim()
                                        : _nameController[0].text.trim(),
                                  ),
                                );
                                translation.add(
                                  Translation(
                                    locale: _languageList[index].key,
                                    key: 'address',
                                    value:
                                        _addressController[index].text
                                            .trim()
                                            .isNotEmpty
                                        ? _addressController[index].text.trim()
                                        : _addressController[0].text.trim(),
                                  ),
                                );
                              }

                              Map<String, String> data = {};

                              data.addAll(
                                StoreBodyModel(
                                  translation: jsonEncode(translation),
                                  minDeliveryTime: minTime,
                                  maxDeliveryTime: maxTime,
                                  lat: addressController
                                      .restaurantLocation!
                                      .latitude
                                      .toString(),
                                  email: email,
                                  lng: addressController
                                      .restaurantLocation!
                                      .longitude
                                      .toString(),
                                  fName: fName,
                                  lName: lName,
                                  phone: _phoneController.text.trim(),
                                  countryCode: _countryDialCode,
                                  password: password,
                                  zoneId: addressController
                                      .zoneList![addressController
                                          .selectedZoneIndex!]
                                      .id
                                      .toString(),
                                  moduleId: addressController
                                      .moduleList![addressController
                                          .selectedModuleIndex!]
                                      .id
                                      .toString(),
                                  deliveryTimeType:
                                      authController
                                          .deliveryTimeTypeList[authController
                                          .deliveryTimeTypeIndex],
                                  businessPlan:
                                      authController.businessIndex == 0
                                      ? 'commission'
                                      : 'subscription',
                                  packageId:
                                      authController.packageModel!.packages !=
                                              null &&
                                          authController
                                              .packageModel!
                                              .packages!
                                              .isNotEmpty
                                      ? authController
                                            .packageModel!
                                            .packages![authController
                                                .activeSubscriptionIndex]
                                            .id!
                                            .toString()
                                      : '',
                                  pickUpZoneIds: addressController
                                      .pickupZoneIdList
                                      .map((e) => e.toString())
                                      .toList(),
                                  tin: tin,
                                  tinExpireDate: DateTime.now()
                                      .add(const Duration(days: 365))
                                      .toString()
                                      .substring(0, 10),
                                  deliveryPrice: _deliveryPriceController.text
                                      .trim(),
                                  openingTime: _isOpen24Hours
                                      ? ''
                                      : (_openingTime ?? ''),
                                  closingTime: _isOpen24Hours
                                      ? ''
                                      : (_closingTime ?? ''),
                                  isOpen24Hours: _isOpen24Hours ? '1' : '0',
                                  slug: _slugController.text.trim(),
                                  websiteColor: _websiteColorController.text
                                      .trim(),
                                ).toJson(),
                              );

                              if (authController.registrationCategories !=
                                      null &&
                                  authController
                                      .registrationCategories!
                                      .isNotEmpty &&
                                  authController.selectedCategoryIds.isEmpty) {
                                showCustomSnackBar(
                                  'select_at_least_one_category'.tr,
                                );
                                return;
                              }

                              for (
                                int i = 0;
                                i < authController.selectedCategoryIds.length;
                                i++
                              ) {
                                data['category_id[$i]'] = authController
                                    .selectedCategoryIds[i]
                                    .toString();
                              }

                              Map<String, Map<String, bool>> categoryLevelsMap =
                                  {};
                              for (int catId
                                  in authController.selectedCategoryIds) {
                                int chosenLevel =
                                    _categoryProductLevels[catId] ?? 1;
                                categoryLevelsMap[catId.toString()] = {
                                  "additional": chosenLevel == 1,
                                  "optional": chosenLevel == 2,
                                  "dontAdd": chosenLevel == 3,
                                };
                              }
                              data['category_levels'] = jsonEncode(
                                categoryLevelsMap,
                              );

                              authController.registerStore(data);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _subscriptionTypeButton(
    AuthController authController,
    int index,
    String text,
  ) {
    bool isSelected = authController.subscriptionTypeIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => authController.setSubscriptionTypeIndex(index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault - 2),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).disabledColor,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductLevelOption({
    required int categoryId,
    required int level,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    if (!_categoryProductLevels.containsKey(categoryId)) {
      _categoryProductLevels[categoryId] = 1;
    }
    bool isSelected = _categoryProductLevels[categoryId] == level;
    return InkWell(
      onTap: () {
        setState(() {
          _categoryProductLevels[categoryId] = level;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Theme.of(context).disabledColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor,
                size: 20,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBackPressedDialogue(String title) async {
    Get.dialog(
      ConfirmationDialogWidget(
        icon: Images.support,
        title: title,
        description: 'are_you_sure_to_go_back'.tr,
        isLogOut: true,
        onYesPressed: () => Get.offAllNamed(RouteHelper.getSignInRoute()),
      ),
      useSafeArea: false,
    );
  }
}
