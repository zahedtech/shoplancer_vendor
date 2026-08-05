import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:shoplancer_vendor/common/widgets/custom_asset_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_card.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_tool_tip_widget.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/common/models/config_model.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart'
    as profile;
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/helper/custom_validator_helper.dart';
import 'package:shoplancer_vendor/helper/validate_check.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/switch_button_widget.dart';
import 'package:shoplancer_vendor/features/store/widgets/daily_time_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/features/store/widgets/pickup_time_input.dart';

import '../../../common/widgets/confirmation_dialog_widget.dart';
import '../../../util/images.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class StoreSettingsScreen extends StatefulWidget {
  final profile.Store store;
  const StoreSettingsScreen({super.key, required this.store});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  // Basic Store Info Controllers (from StoreEditScreen)
  final List<TextEditingController> _nameController = [];
  final List<TextEditingController> _addressController = [];
  final TextEditingController _contactController = TextEditingController();
  final List<FocusNode> _nameNode = [];
  final List<FocusNode> _addressNode = [];
  final FocusNode _contactNode = FocusNode();

  String? _countryDialCode;
  String? _countryCode;

  final List<Language>? _languageList =
      Get.find<SplashController>().configModel!.language;
  final List<Translation>? translation =
      Get.find<ProfileController>().profileModel!.translations;

  final TextEditingController _orderAmountController = TextEditingController();
  final TextEditingController _minimumDeliveryFeeController =
      TextEditingController();
  final TextEditingController _maximumDeliveryFeeController =
      TextEditingController();
  final TextEditingController _processingTimeController =
      TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _minimumController = TextEditingController();
  final TextEditingController _maximumController = TextEditingController();
  final TextEditingController _deliveryChargePerKmController =
      TextEditingController();
  final TextEditingController _deliveryPriceController =
      TextEditingController();
  final TextEditingController _extraPackagingController =
      TextEditingController();
  final TextEditingController _minimumStockController = TextEditingController();
  final TextEditingController _walletPhoneController = TextEditingController();
  final TextEditingController _walletAccountNameController =
      TextEditingController();
  final TextEditingController _instaPayPhoneController =
      TextEditingController();
  final TextEditingController _instaPayAccountNameController =
      TextEditingController();

  final FocusNode _orderAmountNode = FocusNode();
  final FocusNode _minimumDeliveryFeeNode = FocusNode();
  final FocusNode _maximumDeliveryFeeNode = FocusNode();
  final FocusNode _minimumNode = FocusNode();
  // ignore: unused_field
  final FocusNode _minimumProcessingTimeNode = FocusNode();
  final FocusNode _deliveryChargePerKmNode = FocusNode();
  final FocusNode _deliveryPriceFocusNode = FocusNode();
  final FocusNode _minimumStockNode = FocusNode();
  late profile.Store _store;
  final Module? _module =
      Get.find<SplashController>().configModel!.moduleConfig!.module;

  bool _isCashMethodEnabled = true;
  bool _isWalletMethodEnabled = false;
  bool _isInstaPayMethodEnabled = false;

  // Initial values for reset functionality
  late String _initialMinimumOrder;
  late String _initialMinDeliveryFee;
  late String _initialMaxDeliveryFee;
  late String _initialPerKmCharge;
  late String _initialGstCode;
  late String _initialProcessingTime;
  late String _initialExtraPackaging;
  late String _initialMinimumStock;
  late String _initialMinTime;
  late String _initialMaxTime;
  late String _initialDeliveryPrice;
  late String? _initialDurationType;
  late bool _initialIsGstEnabled;
  late bool _initialIsStoreVeg;
  late bool _initialIsStoreNonVeg;
  late bool _initialIsExtraPackagingEnabled;
  late bool _initialIsScheduleOrderEnabled;
  late bool _initialIsDeliveryEnabled;
  late bool _initialIsCutleryEnabled;
  late bool _initialIsFreeDeliveryEnabled;
  late bool _initialIsTakeAwayEnabled;
  late bool _initialIsPrescriptionStatusEnable;
  late bool _initialIsHalalEnabled;
  late bool _initialIsOpen24Hours;
  late bool _initialIsCashMethodEnabled;
  late bool _initialIsWalletMethodEnabled;
  late bool _initialIsInstaPayMethodEnabled;
  late String _initialWalletPhone;
  late String _initialWalletAccountName;
  late String _initialInstaPayPhone;
  late String _initialInstaPayAccountName;

  @override
  void initState() {
    super.initState();

    StoreController storeController = Get.find<StoreController>();
    storeController.initStoreData(widget.store);
    storeController.initStoreBasicData();

    _countryDialCode = CountryCode.fromCountryCode(
      Get.find<SplashController>().configModel!.country!,
    ).dialCode;
    _countryCode = CountryCode.fromCountryCode(
      Get.find<SplashController>().configModel!.country!,
    ).code;
    _splitPhone(widget.store.phone);

    if (_languageList != null) {
      for (int index = 0; index < _languageList!.length; index++) {
        _nameController.add(TextEditingController());
        _addressController.add(TextEditingController());
        _nameNode.add(FocusNode());
        _addressNode.add(FocusNode());

        if (translation != null) {
          for (var trans in translation!) {
            if (_languageList![index].key == trans.locale &&
                trans.key == 'name') {
              _nameController[index].text = trans.value ?? '';
            }
            if (_languageList![index].key == trans.locale &&
                trans.key == 'address') {
              _addressController[index].text = trans.value ?? '';
            }
          }
        }

        if (_nameController[index].text.isEmpty) {
          _nameController[index].text = widget.store.name ?? '';
        }
        if (_addressController[index].text.isEmpty) {
          _addressController[index].text = widget.store.address ?? '';
        }
      }
    }

    _orderAmountController.text = widget.store.minimumOrder.toString();
    _minimumDeliveryFeeController.text = widget.store.minimumShippingCharge
        .toString();
    _maximumDeliveryFeeController.text =
        widget.store.maximumShippingCharge != null
        ? widget.store.maximumShippingCharge.toString()
        : '';
    _deliveryChargePerKmController.text = widget.store.perKmShippingCharge
        .toString();
    _deliveryPriceController.text = widget.store.deliveryPrice != null
        ? widget.store.deliveryPrice.toString()
        : '';
    _gstController.text = widget.store.gstCode!;
    _processingTimeController.text = widget.store.orderPlaceToScheduleInterval
        .toString();
    _extraPackagingController.text = widget.store.extraPackagingAmount
        .toString();
    _minimumStockController.text = widget.store.minimumStockForWarning
        .toString();
    if (widget.store.deliveryTime != null &&
        widget.store.deliveryTime!.isNotEmpty) {
      try {
        _minimumController.text = getDeliveryData(
          widget.store.deliveryTime!,
          'min',
        );
        _maximumController.text = getDeliveryData(
          widget.store.deliveryTime!,
          'max',
        );
        storeController.setSelectedDurationInitData(
          getDeliveryData(widget.store.deliveryTime!, 'type'),
        );
      } catch (_) {
        _minimumController.text = '';
        _maximumController.text = '';
      }
    }
    _store = widget.store;
    profile.StorePaymentMethod? cashMethod = _getPaymentMethod(1);
    profile.StorePaymentMethod? walletMethod = _getPaymentMethod(2);
    profile.StorePaymentMethod? instaPayMethod = _getPaymentMethod(3);

    _isCashMethodEnabled = cashMethod?.isActive ?? true;
    _isWalletMethodEnabled = walletMethod?.isActive ?? false;
    _isInstaPayMethodEnabled = instaPayMethod?.isActive ?? false;
    _walletPhoneController.text = (walletMethod?.configData?['phone'] ?? '')
        .toString();
    _walletAccountNameController.text =
        (walletMethod?.configData?['account_name'] ?? '').toString();
    _instaPayPhoneController.text = (instaPayMethod?.configData?['phone'] ?? '')
        .toString();
    _instaPayAccountNameController.text =
        (instaPayMethod?.configData?['account_name'] ?? '').toString();
    print("hala tag :: ${_store.isHalalActive}");

    // Store initial values for reset functionality
    _initialMinimumOrder = _orderAmountController.text;
    _initialMinDeliveryFee = _minimumDeliveryFeeController.text;
    _initialMaxDeliveryFee = _maximumDeliveryFeeController.text;
    _initialPerKmCharge = _deliveryChargePerKmController.text;
    _initialDeliveryPrice = _deliveryPriceController.text;
    _initialGstCode = _gstController.text;
    _initialProcessingTime = _processingTimeController.text;
    _initialExtraPackaging = _extraPackagingController.text;
    _initialMinimumStock = _minimumStockController.text;
    _initialMinTime = _minimumController.text;
    _initialMaxTime = _maximumController.text;
    _initialDurationType = storeController.selectedDuration;
    _initialIsGstEnabled = storeController.isGstEnabled!;
    _initialIsStoreVeg = storeController.isStoreVeg!;
    _initialIsStoreNonVeg = storeController.isStoreNonVeg!;
    _initialIsExtraPackagingEnabled = storeController.isExtraPackagingEnabled!;
    _initialIsScheduleOrderEnabled = storeController.isScheduleOrderEnabled!;
    _initialIsDeliveryEnabled = storeController.isDeliveryEnabled!;
    _initialIsCutleryEnabled = storeController.isCutleryEnabled!;
    _initialIsFreeDeliveryEnabled = storeController.isFreeDeliveryEnabled!;
    _initialIsTakeAwayEnabled = storeController.isTakeAwayEnabled!;
    _initialIsPrescriptionStatusEnable =
        storeController.isPrescriptionStatusEnable!;
    _initialIsHalalEnabled = storeController.isHalalEnabled!;
    _initialIsOpen24Hours = storeController.isOpen24Hours;
    _initialIsCashMethodEnabled = _isCashMethodEnabled;
    _initialIsWalletMethodEnabled = _isWalletMethodEnabled;
    _initialIsInstaPayMethodEnabled = _isInstaPayMethodEnabled;
    _initialWalletPhone = _walletPhoneController.text;
    _initialWalletAccountName = _walletAccountNameController.text;
    _initialInstaPayPhone = _instaPayPhoneController.text;
    _initialInstaPayAccountName = _instaPayAccountNameController.text;
  }

  profile.StorePaymentMethod? _getPaymentMethod(int methodId) {
    return widget.store.paymentMethods != null
        ? widget.store.paymentMethods![methodId]
        : null;
  }

  void resetToInitialData() {
    StoreController storeController = Get.find<StoreController>();

    // Reset text controllers
    _orderAmountController.text = _initialMinimumOrder;
    _minimumDeliveryFeeController.text = _initialMinDeliveryFee;
    _maximumDeliveryFeeController.text = _initialMaxDeliveryFee;
    _deliveryChargePerKmController.text = _initialPerKmCharge;
    _deliveryPriceController.text = _initialDeliveryPrice;
    _gstController.text = _initialGstCode;
    _processingTimeController.text = _initialProcessingTime;
    _extraPackagingController.text = _initialExtraPackaging;
    _minimumStockController.text = _initialMinimumStock;
    _minimumController.text = _initialMinTime;
    _maximumController.text = _initialMaxTime;
    _walletPhoneController.text = _initialWalletPhone;
    _walletAccountNameController.text = _initialWalletAccountName;
    _instaPayPhoneController.text = _initialInstaPayPhone;
    _instaPayAccountNameController.text = _initialInstaPayAccountName;

    // Reset controller toggle states
    storeController.setGstEnabled(_initialIsGstEnabled);
    storeController.setStoreVeg(_initialIsStoreVeg, true);
    storeController.setStoreNonVeg(_initialIsStoreNonVeg, true);
    storeController.setExtraPackagingEnabled(_initialIsExtraPackagingEnabled);
    storeController.setScheduleOrderEnabled(_initialIsScheduleOrderEnabled);
    storeController.setDeliveryEnabled(_initialIsDeliveryEnabled);
    storeController.setCutleryEnabled(_initialIsCutleryEnabled);
    storeController.setFreeDeliveryEnabled(_initialIsFreeDeliveryEnabled);
    storeController.setTakeAwayEnabled(_initialIsTakeAwayEnabled);
    storeController.setPrescriptionStatusEnable(
      _initialIsPrescriptionStatusEnable,
    );
    storeController.setHalalEnabled(_initialIsHalalEnabled);
    storeController.setSelectedDuration(_initialDurationType);
    storeController.setOpen24Hours(_initialIsOpen24Hours);

    setState(() {
      _isCashMethodEnabled = _initialIsCashMethodEnabled;
      _isWalletMethodEnabled = _initialIsWalletMethodEnabled;
      _isInstaPayMethodEnabled = _initialIsInstaPayMethodEnabled;
    });

    showCustomSnackBar('reset_successful'.tr, isError: false);
  }

  void _splitPhone(String? phone) async {
    String? code = widget.store.countryCode;
    if (code == null || code.isEmpty) {
      code = Get.find<ProfileController>().profileModel?.countryCode;
    }

    if (code != null && code.isNotEmpty) {
      _countryDialCode = code;
      try {
        _countryCode = CountryCode.fromDialCode(code).code;
      } catch (_) {}
      _contactController.text = phone ?? '';
      if (mounted) setState(() {});
      return;
    }

    try {
      if (phone != null && phone.isNotEmpty) {
        PhoneNumber phoneNumber = PhoneNumber.parse(phone);
        _countryDialCode = '+${phoneNumber.countryCode}';
        _countryCode = phoneNumber.isoCode.name;
        _contactController.text = phoneNumber.international
            .substring(_countryDialCode!.length)
            .trim();
      }
    } catch (e) {
      debugPrint('Phone Number Parse Error: $e');
      if (phone != null && phone.isNotEmpty) {
        _contactController.text = phone;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: _module!.showRestaurantText!
            ? 'restaurant_configure'.tr
            : 'store_configure'.tr,
      ),

      body: GetBuilder<StoreController>(
        builder: (storeController) {
          return GetBuilder<ProfileController>(
            builder: (profileController) {
              return GetBuilder<SplashController>(
                builder: (splashController) {
                  bool isEnableTemporarilyClosed = false;
                  ConfigModel? configModel = splashController.configModel;
                  // ignore: unused_local_variable
                  bool isFood = widget.store.module!.moduleType! == 'food';
                  // ignore: unused_local_variable
                  bool isPharmacy =
                      widget.store.module!.moduleType! == 'pharmacy';
                  // ignore: unused_local_variable
                  bool isGrocery =
                      widget.store.module!.moduleType! == 'grocery';

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeDefault,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Basic Info
                              CustomCard(
                                padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('basic_info'.tr, style: robotoBold),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeSmall,
                                    ),
                                    CustomTextFieldWidget(
                                      hintText: _module!.showRestaurantText!
                                          ? 'restaurant_name'.tr
                                          : 'store_name'.tr,
                                      labelText: _module!.showRestaurantText!
                                          ? 'restaurant_name'.tr
                                          : 'store_name'.tr,
                                      controller: _nameController.isNotEmpty
                                          ? _nameController[0]
                                          : TextEditingController(
                                              text: widget.store.name,
                                            ),
                                      capitalization: TextCapitalization.words,
                                      focusNode: _nameNode.isNotEmpty
                                          ? _nameNode[0]
                                          : null,
                                      nextFocus: _addressNode.isNotEmpty
                                          ? _addressNode[0]
                                          : null,
                                      required: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),
                              CustomCard(
                                padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall,
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.view_stream, color: Theme.of(context).primaryColor),
                                  ),
                                  title: Text('ترتيب سكاشن المتجر على الويب'.tr, style: robotoBold),
                                  subtitle: Text('التحكم في ترتيب، إظهار أو إخفاء وتسمية السكاشن على الصفحة الرئيسية'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    Get.toNamed(RouteHelper.getStoreSectionsRoute());
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),

                              /// Address
                              CustomCard(
                                padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('address'.tr, style: robotoBold),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeSmall,
                                    ),
                                    CustomTextFieldWidget(
                                      hintText: 'enter_store_address'.tr,
                                      labelText: 'address'.tr,
                                      controller: _addressController.isNotEmpty
                                          ? _addressController[0]
                                          : TextEditingController(
                                              text: widget.store.address,
                                            ),
                                      focusNode: _addressNode.isNotEmpty
                                          ? _addressNode[0]
                                          : null,
                                      capitalization:
                                          TextCapitalization.sentences,
                                      maxLines: 3,
                                      prefixIcon: Icons.location_on_outlined,
                                      nextFocus: _contactNode,
                                      required: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),

                              /// Phone Number
                              CustomCard(
                                padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('phone_number'.tr, style: robotoBold),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeSmall,
                                    ),
                                    CustomTextFieldWidget(
                                      hintText: 'xxx-xxxxxxx',
                                      labelText: 'phone_number'.tr,
                                      controller: _contactController,
                                      focusNode: _contactNode,
                                      required: true,
                                      inputType: TextInputType.phone,
                                      isPhone: true,
                                      onCountryChanged:
                                          (CountryCode countryCode) {
                                            _countryDialCode =
                                                countryCode.dialCode;
                                          },
                                      countryDialCode:
                                          _countryDialCode ??
                                          CountryCode.fromCountryCode(
                                            Get.find<SplashController>()
                                                .configModel!
                                                .country!,
                                          ).dialCode,
                                      validator: (value) =>
                                          ValidateCheck.validateEmptyText(
                                            value,
                                            null,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),

                              /// Business Logo
                              CustomCard(
                                width: context.width,
                                padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeDefault,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'business_logo'.tr,
                                            style: robotoBold.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge!.color,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '*',
                                            style: robotoRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeLarge,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'image_format_and_ratio_for_business_logo'
                                          .tr,
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeDefault,
                                    ),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(2),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    Dimensions.radiusDefault,
                                                  ),
                                              child:
                                                  storeController.rawLogo !=
                                                      null
                                                  ? GetPlatform.isWeb
                                                        ? Image.network(
                                                            storeController
                                                                .rawLogo!
                                                                .path,
                                                            width: 120,
                                                            height: 120,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.file(
                                                            File(
                                                              storeController
                                                                  .rawLogo!
                                                                  .path,
                                                            ),
                                                            width: 120,
                                                            height: 120,
                                                            fit: BoxFit.cover,
                                                          )
                                                  : widget.store.logoFullUrl !=
                                                        null
                                                  ? CustomImageWidget(
                                                      image:
                                                          widget
                                                              .store
                                                              .logoFullUrl ??
                                                          '',
                                                      height: 120,
                                                      width: 120,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : SizedBox(
                                                      width: 120,
                                                      height: 120,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          CustomAssetImageWidget(
                                                            Images.uploadIcon,
                                                            height: 30,
                                                            width: 30,
                                                            color: Theme.of(
                                                              context,
                                                            ).hintColor,
                                                          ),
                                                          const SizedBox(
                                                            height: Dimensions
                                                                .paddingSizeSmall,
                                                          ),
                                                          Text(
                                                            'click_to_upload'
                                                                .tr,
                                                            style: robotoMedium
                                                                .copyWith(
                                                                  color: Colors
                                                                      .blue,
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeSmall,
                                                                ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            top: 0,
                                            left: 0,
                                            child: InkWell(
                                              onTap: () => storeController
                                                  .pickImage(true, false),
                                              child: DottedBorder(
                                                options:
                                                    RoundedRectDottedBorderOptions(
                                                      color: Theme.of(
                                                        context,
                                                      ).hintColor,
                                                      strokeWidth: 1,
                                                      strokeCap: StrokeCap.butt,
                                                      dashPattern: const [5, 5],
                                                      padding:
                                                          const EdgeInsets.all(
                                                            0,
                                                          ),
                                                      radius:
                                                          const Radius.circular(
                                                            Dimensions
                                                                .radiusDefault,
                                                          ),
                                                    ),
                                                child: const SizedBox(
                                                  width: 120,
                                                  height: 120,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeLarge,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),

                              /// Restaurant Availability
                              Container(
                                padding: EdgeInsets.all(
                                  Dimensions.paddingSizeDefault,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusDefault,
                                  ),
                                  color: Theme.of(context).cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      offset: Offset(0, 3),
                                      color: Colors
                                          .grey[Get.isDarkMode ? 700 : 200]!,
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'store_availability'.tr,
                                      style: robotoMedium,
                                    ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeExtraSmall,
                                    ),
                                    // Text(
                                    //   'store_will_close_temporary'
                                    //       .tr,
                                    //   style: robotoRegular.copyWith(
                                    //     color: Theme.of(context).hintColor,
                                    //   ),
                                    // ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeExtraSmall,
                                    ),

                                    profileController.modulePermission !=
                                                null &&
                                            profileController
                                                .modulePermission!
                                                .storeSetup!
                                        ? Container(
                                            padding: const EdgeInsets.all(
                                              Dimensions.paddingSizeSmall - 3,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    Dimensions.radiusDefault,
                                                  ),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .disabledColor
                                                    .withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          'status'.tr,
                                                          style: robotoMedium,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                          width: Dimensions
                                                              .paddingSizeSmall,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                !profileController
                                                                    .isStoreActive
                                                                ? Colors.green
                                                                      .withOpacity(
                                                                        0.12,
                                                                      )
                                                                : Colors.red
                                                                      .withOpacity(
                                                                        0.12,
                                                                      ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  Dimensions
                                                                      .radiusExtraLarge,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  !profileController
                                                                      .isStoreActive
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            !profileController
                                                                    .isStoreActive
                                                                ? 'active'.tr
                                                                : 'inactive'.tr,
                                                            style: robotoBold.copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeExtraSmall,
                                                              color:
                                                                  !profileController
                                                                      .isStoreActive
                                                                  ? Colors
                                                                        .green[700]
                                                                  : Colors
                                                                        .red[700],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  profileController
                                                              .profileModel !=
                                                          null
                                                      ? GetBuilder<
                                                          AuthController
                                                        >(
                                                          builder: (authController) {
                                                            return authController
                                                                    .storeClosedStatusLoading
                                                                ? const SizedBox(
                                                                    width: 40,
                                                                    height: 40,
                                                                    child: Center(
                                                                      child:
                                                                          CupertinoActivityIndicator(),
                                                                    ),
                                                                  )
                                                                : Transform.scale(
                                                                    scale: 0.8,
                                                                    child: CupertinoSwitch(
                                                                      value: !profileController
                                                                          .isStoreActive,
                                                                      activeColor:
                                                                          Colors
                                                                              .green,
                                                                      trackColor:
                                                                          Colors
                                                                              .grey[300],
                                                                      onChanged:
                                                                          (
                                                                            bool
                                                                            isActive,
                                                                          ) {
                                                                            bool?
                                                                            showRestaurantText =
                                                                                Get.find<
                                                                                      SplashController
                                                                                    >()
                                                                                    .configModel!
                                                                                    .moduleConfig!
                                                                                    .module!
                                                                                    .showRestaurantText;
                                                                            isEnableTemporarilyClosed
                                                                                // ignore: dead_code
                                                                                ? Get.dialog(
                                                                                    ConfirmationDialogWidget(
                                                                                      icon: Images.warning,
                                                                                      isOnNoPressedShow: false,
                                                                                      onYesButtonText: 'ok'.tr,
                                                                                      description: showRestaurantText!
                                                                                          ? 'you_can_not_close_the_store_because_you_already_have_running_orders'.tr
                                                                                          : 'you_can_not_close_the_store_because_you_already_have_running_orders'.tr,
                                                                                      onYesPressed: () {
                                                                                        Get.back();
                                                                                      },
                                                                                    ),
                                                                                  )
                                                                                : Get.dialog(
                                                                                    ConfirmationDialogWidget(
                                                                                      icon: Images.warning,
                                                                                      description: isActive
                                                                                          ? showRestaurantText!
                                                                                                ? 'are_you_sure_to_close_restaurant'.tr
                                                                                                : 'are_you_sure_to_close_store'.tr
                                                                                          : showRestaurantText!
                                                                                          ? 'are_you_sure_to_open_restaurant'.tr
                                                                                          : 'are_you_sure_to_open_store'.tr,
                                                                                      onYesPressed: () {
                                                                                        Get.back();
                                                                                        profileController.setStoreStatus(
                                                                                          !isActive,
                                                                                        );
                                                                                        Get.find<
                                                                                              AuthController
                                                                                            >()
                                                                                            .toggleStoreClosedStatus();
                                                                                      },
                                                                                    ),
                                                                                  );
                                                                          },
                                                                    ),
                                                                  );
                                                          },
                                                        )
                                                      : Shimmer(
                                                          duration:
                                                              const Duration(
                                                                seconds: 2,
                                                              ),
                                                          child: Container(
                                                            height: 30,
                                                            width: 50,
                                                            color: Colors
                                                                .grey[300],
                                                          ),
                                                        ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : const SizedBox(),

                                    // SizedBox(
                                    //   height:
                                    //       profileController.modulePermission !=
                                    //               null &&
                                    //           profileController
                                    //               .modulePermission!
                                    //               .storeSetup!
                                    //       ? Dimensions.paddingSizeDefault
                                    //       : 0,
                                    // ),
                                    // SwitchButtonWidget(
                                    //   title: 'default_banner'.tr,
                                    //   isButtonActive: _store.defaultBanner == 1,
                                    //   onTap: () {
                                    //     _store.defaultBanner =
                                    //         (_store.defaultBanner == 1) ? 0 : 1;
                                    //     setState(() {});
                                    //   },
                                    // ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),

                              /// Order Options
                              Text('order_options'.tr, style: robotoBold),
                              const SizedBox(
                                height: Dimensions.paddingSizeSmall,
                              ),
                              CustomCard(
                                padding: EdgeInsets.all(
                                  Dimensions.paddingSizeDefault,
                                ),
                                child: Column(
                                  children: [
                                    configModel!.scheduleOrder!
                                        ? SwitchButtonWidget(
                                            title: 'schedule_order'.tr,
                                            description:
                                                'schedule_order_description'.tr,
                                            isButtonActive: storeController
                                                .isScheduleOrderEnabled,
                                            onTap: () {
                                              storeController
                                                  .toggleScheduleOrder();
                                            },
                                          )
                                        : const SizedBox(),
                                    SizedBox(
                                      height: configModel.scheduleOrder!
                                          ? Dimensions.paddingSizeDefault
                                          : 0,
                                    ),

                                    SwitchButtonWidget(
                                      title: 'home_delivery'.tr,
                                      description:
                                          'home_delivery_description'.tr,
                                      isButtonActive:
                                          storeController.isDeliveryEnabled,
                                      onTap: () {
                                        storeController.toggleDelivery();
                                      },
                                    ),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeDefault,
                                    ),

                                    SwitchButtonWidget(
                                      title: 'take_away'.tr,
                                      description: 'take_away_description'.tr,
                                      isButtonActive:
                                          storeController.isTakeAwayEnabled,
                                      onTap: () {
                                        storeController.toggleTakeAway();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),
                              /*
                    /// Product labels & Preference
                    //isFood || isGrocery ? Text('product_labels_preferences'.tr, style: robotoBold) : SizedBox.shrink(),
                    //isFood || isGrocery ? const SizedBox(height: Dimensions.paddingSizeSmall) :SizedBox.shrink(),
                    isFood || isGrocery ?CustomCard(
                      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Column(children: [
                        /*isFood || isGrocery ? SwitchButtonWidget(
                          title: 'halal_tag_status'.tr,
                          description: 'halal_tag_description'.tr,
                          isButtonActive: storeController.isHalalEnabled,
                          onTap: () {
                            print('Halal Tag: ${storeController.isHalalEnabled}');
                            storeController.toggleHalalTag();
                          },
                        ) : const SizedBox(),*/
                        SizedBox(height: isFood || isGrocery ? Dimensions.paddingSizeDefault : 0),

                        _module.vegNonVeg! && configModel.toggleVegNonVeg! ? SwitchButtonWidget(
                          title: 'veg'.tr,
                          description: 'veg_description'.tr,
                          isButtonActive: storeController.isStoreVeg,
                          onTap: () {
                            storeController.toggleStoreVeg();
                          },
                        ) : const SizedBox(),
                        SizedBox(height: _module.vegNonVeg! && configModel.toggleVegNonVeg! ? Dimensions.paddingSizeDefault : 0),

                        _module.vegNonVeg! && configModel.toggleVegNonVeg! ? SwitchButtonWidget(
                          title: 'non_veg'.tr,
                          description: 'non_veg_description'.tr,
                          isButtonActive: storeController.isStoreNonVeg,
                          onTap: () {
                            storeController.toggleStoreNonVeg();
                          },
                        ) : const SizedBox(),
                        SizedBox(height: _module.vegNonVeg! && configModel.toggleVegNonVeg! ? Dimensions.paddingSizeDefault : 0),

                        isFood ? SwitchButtonWidget(
                          title: 'cutlery'.tr,
                          description: 'cutlery_description'.tr,
                          isButtonActive: storeController.isCutleryEnabled,
                          onTap: () {
                            storeController.toggleCutlery();
                          },
                        ) : const SizedBox(),
                        SizedBox(height: isFood ? Dimensions.paddingSizeSmall : 0),

                        _store.selfDeliverySystem == 1 ? SwitchButtonWidget(
                          title: 'free_delivery'.tr,
                          isButtonActive: storeController.isFreeDeliveryEnabled,
                          onTap: () {
                            storeController.toggleFreeDelivery();
                          },
                        ) : const SizedBox(),
                        SizedBox(height: _store.selfDeliverySystem == 1 ? Dimensions.paddingSizeDefault : 0),

                        isPharmacy && configModel.prescriptionOrderStatus! ? SwitchButtonWidget(
                          title: 'prescription_order'.tr,
                          isButtonActive: storeController.isPrescriptionStatusEnable,
                          onTap: () {
                            storeController.togglePrescription();
                          },
                        ) : const SizedBox(),
                      ]),
                    ) : SizedBox.shrink(),
                    isFood || isGrocery ? const SizedBox(height: Dimensions.paddingSizeDefault) :SizedBox.shrink(),
*/
                              /// Pricing & Charges
                              Text('pricing_and_charges'.tr, style: robotoBold),
                              const SizedBox(
                                height: Dimensions.paddingSizeSmall,
                              ),

                              CustomCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    PickupTimeInput(
                                      minTimeController: _minimumController,
                                      maxTimeController: _maximumController,
                                    ),
                                    SizedBox(
                                      height: _store.selfDeliverySystem == 1
                                          ? Dimensions.paddingSizeExtraLarge
                                          : 0,
                                    ),

                                    _store.selfDeliverySystem == 1
                                        ? Column(
                                            children: [
                                              CustomTextFieldWidget(
                                                hintText:
                                                    'delivery_charge_per_km'.tr,
                                                labelText:
                                                    '${'delivery_charge_per_km'.tr} (${Get.find<SplashController>().configModel!.currencySymbol})',
                                                controller:
                                                    _deliveryChargePerKmController,
                                                focusNode:
                                                    _deliveryChargePerKmNode,
                                                nextFocus:
                                                    _minimumDeliveryFeeNode,
                                                inputType: TextInputType.number,
                                                isAmount: true,
                                              ),
                                              const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeExtraLarge,
                                              ),

                                              CustomTextFieldWidget(
                                                hintText:
                                                    'minimum_delivery_charge'
                                                        .tr,
                                                labelText:
                                                    '${'minimum_delivery_charge'.tr} (${Get.find<SplashController>().configModel!.currencySymbol})',
                                                controller:
                                                    _minimumDeliveryFeeController,
                                                focusNode:
                                                    _minimumDeliveryFeeNode,
                                                nextFocus:
                                                    _maximumDeliveryFeeNode,
                                                inputType: TextInputType.number,
                                                isAmount: true,
                                              ),
                                              const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeExtraLarge,
                                              ),

                                              CustomTextFieldWidget(
                                                hintText:
                                                    'maximum_delivery_charge'
                                                        .tr,
                                                labelText:
                                                    '${'maximum_delivery_charge'.tr} (${Get.find<SplashController>().configModel!.currencySymbol})',
                                                controller:
                                                    _maximumDeliveryFeeController,
                                                focusNode:
                                                    _maximumDeliveryFeeNode,
                                                inputAction:
                                                    TextInputAction.done,
                                                inputType: TextInputType.number,
                                                nextFocus:
                                                    _deliveryPriceFocusNode,
                                                isAmount: true,
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeExtraLarge,
                                    ),
                                    CustomTextFieldWidget(
                                      hintText: 'enter_delivery_fee'.tr,
                                      labelText:
                                          '${'delivery_fee'.tr} (${Get.find<SplashController>().configModel!.currencySymbol})',
                                      controller: _deliveryPriceController,
                                      focusNode: _deliveryPriceFocusNode,
                                      inputAction: TextInputAction.done,
                                      inputType: TextInputType.number,
                                      nextFocus: _minimumNode,
                                      isAmount: true,
                                    ),
                                    SizedBox(
                                      height:
                                          _module.orderPlaceToScheduleInterval!
                                          ? Dimensions.paddingSizeExtraLarge
                                          : 0,
                                    ),

                                    !_module.showRestaurantText!
                                        ? Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'minimum_stock_for_warning'
                                                        .tr,
                                                    style: robotoRegular
                                                        .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeSmall,
                                                          color: Theme.of(
                                                            context,
                                                          ).disabledColor,
                                                        ),
                                                  ),
                                                  const SizedBox(
                                                    width: Dimensions
                                                        .paddingSizeExtraSmall,
                                                  ),

                                                  CustomToolTip(
                                                    preferredDirection:
                                                        AxisDirection.up,
                                                    message:
                                                        'minimum_stock_for_warning_tooltip'
                                                            .tr,
                                                  ),
                                                ],
                                              ),

                                              CustomTextFieldWidget(
                                                hintText:
                                                    'minimum_stock_for_warning'
                                                        .tr,
                                                controller:
                                                    _minimumStockController,
                                                focusNode: _minimumStockNode,
                                                inputAction:
                                                    TextInputAction.done,
                                                inputType: TextInputType.number,
                                                isAmount: true,
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeExtraLarge,
                                    ),
                                    CustomTextFieldWidget(
                                      hintText: 'minimum_order_amount'.tr,
                                      labelText:
                                          '${'minimum_order_amount'.tr} (${Get.find<SplashController>().configModel!.currencySymbol})',
                                      controller: _orderAmountController,
                                      focusNode: _orderAmountNode,
                                      nextFocus: _store.selfDeliverySystem == 1
                                          ? _deliveryChargePerKmNode
                                          : _deliveryPriceFocusNode,
                                      inputType: TextInputType.number,
                                      isAmount: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),

                              /*CustomCard(
                      child: Column(children: [

                        Row(children: [

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('gst'.tr, style: robotoRegular),

                                Text('gst_description'.tr, style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                                )),
                              ]),
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeDefault),

                          Transform.scale(
                            scale: 0.7,
                            child: CupertinoSwitch(
                              value: storeController.isGstEnabled!,
                              activeTrackColor: Theme.of(context).primaryColor,
                              inactiveTrackColor: Theme.of(context).hintColor.withValues(alpha: 0.5),
                              onChanged: (bool isActive) => storeController.toggleGst(),
                            ),
                          ),

                        ]),

                        Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          child: CustomTextFieldWidget(
                            hintText: 'XXX XXXX XXXX'.tr,
                            labelText: 'gst_number'.tr,
                            controller: _gstController,
                            inputAction: TextInputAction.done,
                            showTitle: false,
                            isEnabled: storeController.isGstEnabled!,
                            hideEnableText: true,
                            isAmount: true,
                          ),
                        ),

                      ]),
                    ),*/
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),

                              /*CustomCard(
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('extra_packaging_charge'.tr, style: robotoRegular),
                                Text('extra_packaging_charge_description'.tr, style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor,
                                )),
                              ]),
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeDefault),

                          Transform.scale(
                            scale: 0.7,
                            child: CupertinoSwitch(
                              value: storeController.isExtraPackagingEnabled!,
                              activeTrackColor: Theme.of(context).primaryColor,
                              inactiveTrackColor: Theme.of(context).hintColor.withValues(alpha: 0.5),
                              onChanged: (bool isActive) => storeController.toggleExtraPackaging(),
                            ),
                          ),

                        ]),

                        Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          child: CustomTextFieldWidget(
                            hintText: 'eg_18'.tr,
                            labelText: '${'charge_amount'.tr} (${configModel.currencySymbol})',
                            controller: _extraPackagingController,
                            inputAction: TextInputAction.done,
                            isEnabled: storeController.isExtraPackagingEnabled!,
                            hideEnableText: true,
                            isAmount: true,
                          ),
                        ),

                      ]),
                    ),*/
                              const SizedBox(
                                height: Dimensions.paddingSizeDefault,
                              ),

                              _module.alwaysOpen!
                                  ? const SizedBox()
                                  : Text(
                                      'operating_hours'.tr,
                                      style: robotoBold,
                                    ),
                              SizedBox(
                                height: _module.alwaysOpen!
                                    ? 0
                                    : Dimensions.paddingSizeSmall,
                              ),

                              _module.alwaysOpen!
                                  ? const SizedBox()
                                  : CustomCard(
                                      padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeDefault,
                                      ),
                                      child: Column(
                                        children: [
                                          SwitchButtonWidget(
                                            title: 'open_24_hours'.tr,
                                            description:
                                                'open_24_hours_description'.tr,
                                            isButtonActive:
                                                storeController.isOpen24Hours,
                                            onTap: () {
                                              storeController.setOpen24Hours(
                                                !storeController.isOpen24Hours,
                                              );
                                            },
                                          ),
                                          SizedBox(
                                            height:
                                                Dimensions.paddingSizeDefault,
                                          ),
                                          storeController.isOpen24Hours
                                              ? Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    'open_24_hours'.tr,
                                                    style: robotoRegular
                                                        .copyWith(
                                                          color: Theme.of(
                                                            context,
                                                          ).hintColor,
                                                        ),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  shrinkWrap: true,
                                                  itemCount: 7,
                                                  itemBuilder: (context, index) {
                                                    return Column(
                                                      children: [
                                                        DailyTimeWidget(
                                                          weekDay: index,
                                                        ),

                                                        index != 6
                                                            ? const Divider()
                                                            : const SizedBox(),
                                                      ],
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

                      Container(
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeDefault,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Reset Button
                            Expanded(
                              child: CustomButtonWidget(
                                buttonText: 'reset'.tr,
                                color: Theme.of(
                                  context,
                                ).disabledColor.withValues(alpha: 0.3),
                                textColor: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                onPressed: () {
                                  resetToInitialData();
                                },
                              ),
                            ),
                            const SizedBox(
                              width: Dimensions.paddingSizeDefault,
                            ),

                            // Update Button
                            Expanded(
                              child: CustomButtonWidget(
                                isLoading: storeController.isLoading,
                                onPressed: () {
                                  String minimumOrder = _orderAmountController
                                      .text
                                      .trim();
                                  String deliveryFee =
                                      _minimumDeliveryFeeController.text.trim();
                                  String deliveryPrice =
                                      _deliveryPriceController.text.trim();
                                  String minimum = _minimumController.text
                                      .trim();
                                  String maximum = _maximumController.text
                                      .trim();
                                  String processingTime =
                                      _processingTimeController.text.trim();
                                  String deliveryChargePerKm =
                                      _deliveryChargePerKmController.text
                                          .trim();
                                  String gstCode = _gstController.text.trim();
                                  String extraPackagingAmount =
                                      _extraPackagingController.text.trim();
                                  String maximumFee =
                                      _maximumDeliveryFeeController.text.trim();
                                  String minimumStockForWarning =
                                      _minimumStockController.text.trim();
                                  String walletPhone = _walletPhoneController
                                      .text
                                      .trim();
                                  String walletAccountName =
                                      _walletAccountNameController.text.trim();
                                  String instaPayPhone =
                                      _instaPayPhoneController.text.trim();
                                  String instaPayAccountName =
                                      _instaPayAccountNameController.text
                                          .trim();

                                  if (minimumOrder.isEmpty) {
                                    showCustomSnackBar(
                                      'enter_minimum_order_amount'.tr,
                                    );
                                  } else if (minimum.isEmpty) {
                                    showCustomSnackBar(
                                      'enter_minimum_delivery_time'.tr,
                                    );
                                  } else if (maximum.isEmpty) {
                                    showCustomSnackBar(
                                      'enter_maximum_delivery_time'.tr,
                                    );
                                  } else if (storeController.selectedDuration ==
                                      null) {
                                    showCustomSnackBar(
                                      'select_delivery_time_type'.tr,
                                    );
                                  } else if (_store.selfDeliverySystem == 1 &&
                                      deliveryChargePerKm.isEmpty) {
                                    showCustomSnackBar(
                                      'enter_delivery_charge_per_km'.tr,
                                    );
                                  } else if (deliveryPrice.isEmpty) {
                                    showCustomSnackBar('enter_delivery_fee'.tr);
                                  } else if (_store.selfDeliverySystem == 1 &&
                                      deliveryFee.isEmpty) {
                                    showCustomSnackBar(
                                      'enter_minimum_delivery_charge'.tr,
                                    );
                                  } else if (_store.selfDeliverySystem == 1 &&
                                      deliveryFee.isEmpty &&
                                      maximumFee.isNotEmpty) {
                                    showCustomSnackBar(
                                      'enter_minimum_delivery_charge'.tr,
                                    );
                                  } else if (_store.selfDeliverySystem == 1 &&
                                      maximumFee.isNotEmpty &&
                                      double.parse(maximumFee) == 0) {
                                    showCustomSnackBar(
                                      'enter_maximum_delivery_charge_more_than_0'
                                          .tr,
                                    );
                                  } else if (_store.selfDeliverySystem == 1 &&
                                      deliveryFee.isNotEmpty &&
                                      maximumFee.isNotEmpty &&
                                      double.parse(maximumFee) != 0 &&
                                      (double.parse(deliveryFee) >=
                                          double.parse(maximumFee))) {
                                    showCustomSnackBar(
                                      'minimum_charge_can_not_be_more_then_maximum_charge'
                                          .tr,
                                    );
                                  } else if (_module
                                          .orderPlaceToScheduleInterval! &&
                                      processingTime.isEmpty) {
                                    showCustomSnackBar(
                                      'enter_minimum_processing_time'.tr,
                                    );
                                  } else if ((_module.vegNonVeg! &&
                                          Get.find<SplashController>()
                                              .configModel!
                                              .toggleVegNonVeg!) &&
                                      !storeController.isStoreVeg! &&
                                      !storeController.isStoreNonVeg!) {
                                    showCustomSnackBar(
                                      'select_at_least_one_item_type'.tr,
                                    );
                                  } else if (_module
                                          .orderPlaceToScheduleInterval! &&
                                      processingTime.isEmpty) {
                                    showCustomSnackBar(
                                      'enter_minimum_processing_time'.tr,
                                    );
                                  } else if (storeController.isGstEnabled! &&
                                      gstCode.isEmpty) {
                                    showCustomSnackBar('enter_gst_code'.tr);
                                  } else if (storeController
                                          .isExtraPackagingEnabled! &&
                                      extraPackagingAmount.isEmpty) {
                                    showCustomSnackBar(
                                      'enter_extra_packaging_amount_more_than_0'
                                          .tr,
                                    );
                                  } else if (storeController
                                          .isExtraPackagingEnabled! &&
                                      extraPackagingAmount.isNotEmpty &&
                                      double.parse(extraPackagingAmount) == 0) {
                                    showCustomSnackBar(
                                      'enter_extra_packaging_amount_more_than_0'
                                          .tr,
                                    );
                                  } else {
                                    _store.minimumOrder =
                                        minimumOrder.isNotEmpty
                                        ? double.parse(minimumOrder)
                                        : 0;
                                    _store.gstStatus =
                                        storeController.isGstEnabled;
                                    _store.gstCode = gstCode;
                                    _store.orderPlaceToScheduleInterval =
                                        _module.orderPlaceToScheduleInterval!
                                        ? double.parse(
                                            _processingTimeController.text,
                                          ).toInt()
                                        : 0;
                                    _store.minimumShippingCharge =
                                        deliveryFee.isNotEmpty
                                        ? double.parse(deliveryFee)
                                        : null;
                                    _store.maximumShippingCharge =
                                        maximumFee.isNotEmpty
                                        ? double.parse(maximumFee)
                                        : null;
                                    _store.perKmShippingCharge =
                                        deliveryChargePerKm.isNotEmpty
                                        ? double.parse(deliveryChargePerKm)
                                        : 0;
                                    _store.deliveryPrice =
                                        deliveryPrice.isNotEmpty
                                        ? double.parse(deliveryPrice)
                                        : 0;
                                    _store.veg =
                                        (_module.vegNonVeg! &&
                                            storeController.isStoreVeg!)
                                        ? 1
                                        : 0;
                                    _store.nonVeg =
                                        (!_module.vegNonVeg! ||
                                            storeController.isStoreNonVeg!)
                                        ? 1
                                        : 0;
                                    _store.isHalalActive =
                                        storeController.isHalalEnabled;
                                    _store.extraPackagingStatus =
                                        storeController.isExtraPackagingEnabled;
                                    _store.extraPackagingAmount =
                                        extraPackagingAmount.isNotEmpty
                                        ? double.parse(extraPackagingAmount)
                                        : 0;
                                    _store.scheduleOrder =
                                        storeController.isScheduleOrderEnabled;
                                    _store.delivery =
                                        storeController.isDeliveryEnabled;
                                    _store.cutlery =
                                        storeController.isCutleryEnabled;
                                    _store.freeDelivery =
                                        storeController.isFreeDeliveryEnabled;
                                    _store.takeAway =
                                        storeController.isTakeAwayEnabled;
                                    _store.prescriptionStatus = storeController
                                        .isPrescriptionStatusEnable;
                                    _store.minimumStockForWarning =
                                        minimumStockForWarning.isNotEmpty
                                        ? double.parse(minimumStockForWarning)
                                        : 0;
                                    _store.paymentMethods = {
                                      1: profile.StorePaymentMethod(
                                        isActive: _isCashMethodEnabled,
                                        configData: null,
                                      ),
                                      2: profile.StorePaymentMethod(
                                        isActive: _isWalletMethodEnabled,
                                        configData: _isWalletMethodEnabled
                                            ? {
                                                'phone': walletPhone,
                                                'account_name':
                                                    walletAccountName,
                                              }
                                            : null,
                                      ),
                                      3: profile.StorePaymentMethod(
                                        isActive: _isInstaPayMethodEnabled,
                                        configData: _isInstaPayMethodEnabled
                                            ? {
                                                'phone': instaPayPhone,
                                                'account_name':
                                                    instaPayAccountName,
                                              }
                                            : null,
                                      ),
                                    };

                                    String name = _nameController.isNotEmpty
                                        ? _nameController[0].text.trim()
                                        : widget.store.name ?? '';
                                    String address =
                                        _addressController.isNotEmpty
                                        ? _addressController[0].text.trim()
                                        : widget.store.address ?? '';
                                    String contact = _contactController.text
                                        .trim();

                                    String numberWithCountryCode = contact;
                                    if (contact.isNotEmpty) {
                                      if (contact.startsWith('+') ||
                                          contact.startsWith(
                                            (_countryDialCode ?? '').replaceAll(
                                              '+',
                                              '',
                                            ),
                                          )) {
                                        numberWithCountryCode =
                                            contact.startsWith('+')
                                            ? contact
                                            : '+$contact';
                                      } else {
                                        numberWithCountryCode =
                                            (_countryDialCode ?? '') + contact;
                                      }
                                    }

                                    List<Translation> translationsList = [];
                                    if (_languageList != null) {
                                      for (
                                        int index = 0;
                                        index < _languageList!.length;
                                        index++
                                      ) {
                                        translationsList.add(
                                          Translation(
                                            locale: _languageList![index].key,
                                            key: 'name',
                                            value: name,
                                          ),
                                        );
                                        translationsList.add(
                                          Translation(
                                            locale: _languageList![index].key,
                                            key: 'address',
                                            value: address,
                                          ),
                                        );
                                      }
                                    }

                                    _store.name = name;
                                    _store.address = address;
                                    _store.phone = numberWithCountryCode;
                                    _store.countryCode = _countryDialCode;

                                    print('Halal Tag: ${_store.isHalalActive}');
                                    storeController
                                        .updateStoreBasicInfoAndSettings(
                                          store: _store,
                                          translations: translationsList,
                                          minimum: minimum,
                                          maximum: maximum,
                                        );
                                  }
                                },
                                buttonText: 'update'.tr,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  dynamic getDeliveryData(String deliveryTime, String type) {
    RegExp regExp = RegExp(r'(\d+)-(\d+) (hours|days|min)');
    RegExpMatch? match = regExp.firstMatch(deliveryTime);

    if (match != null) {
      switch (type) {
        case 'min':
          return match.group(1)!;
        case 'max':
          return match.group(2)!;
        case 'type':
          return match.group(3)!;
        default:
          throw ArgumentError('Invalid type requested');
      }
    } else {
      throw const FormatException('Invalid delivery time format');
    }
  }
}
