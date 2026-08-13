import 'dart:io';
import 'dart:math';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/common/widgets/custom_drop_down_button.dart.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shoplancer_vendor/features/language/controllers/language_controller.dart';
import 'package:shoplancer_vendor/common/widgets/custom_dropdown_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/common/widgets/label_widget.dart';
import 'package:shoplancer_vendor/features/addon/controllers/addon_controller.dart';
import 'package:shoplancer_vendor/features/ai/controllers/ai_controller.dart';
import 'package:shoplancer_vendor/features/ai/widgets/animated_border_container.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/features/category/controllers/category_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/variant_type_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/variation_body_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/attribute_model.dart';
import 'package:shoplancer_vendor/common/models/config_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_time_picker_widget.dart';
import 'package:shoplancer_vendor/features/store/widgets/attribute_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/features/store/widgets/food_variation_view_widget.dart';

import '../../profile/domain/models/profile_model.dart' hide Module;

class AddItemScreen extends StatefulWidget {
  final Item? item;
  final bool isSimple;
  const AddItemScreen({super.key, required this.item, this.isSimple = false});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _nameControllerList = [];
  final List<TextEditingController> _descriptionControllerList = [];
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _maxOrderQuantityController =
      TextEditingController();
  TextEditingController _c = TextEditingController();
  final TextEditingController _nutritionSuggestionController =
      TextEditingController();
  final TextEditingController _allergicIngredientsSuggestionController =
      TextEditingController();
  final TextEditingController _genericNameSuggestionController =
      TextEditingController();
  final TextEditingController _maxVideoPreviewController =
      TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _priceNode = FocusNode();
  final FocusNode _discountNode = FocusNode();
  final FocusNode _genericNameNode = FocusNode();
  final FocusNode _barcodeNode = FocusNode();
  MobileScannerController? _scannerController;
  bool _showScanner = false;

  final List<FocusNode> _nameFocusList = [];
  final List<FocusNode> _descriptionFocusList = [];

  late bool _update;
  late bool _discountTypeSelected;
  late Item _item;

  final Module? _module =
      Get.find<SplashController>().configModel!.moduleConfig!.module;
  final isPharmacy =
      Get.find<ProfileController>()
          .profileModel!
          .stores![0]
          .module!
          .moduleType ==
      'pharmacy';
  final isEcommerce =
      Get.find<ProfileController>()
          .profileModel!
          .stores![0]
          .module!
          .moduleType ==
      'ecommerce';
  final isGrocery =
      Get.find<ProfileController>()
          .profileModel!
          .stores![0]
          .module!
          .moduleType ==
      'grocery';
  final isFood = Get.find<SplashController>()
      .getStoreModuleConfig()
      .newVariation!;
  final bool storeHalalActive =
      Get.find<ProfileController>().profileModel!.stores![0].isHalalActive!;

  final List<Language>? _languageList =
      Get.find<SplashController>().configModel!.language;

  @override
  void initState() {
    super.initState();
    StoreController storeController = Get.find<StoreController>();
    CategoryController categoryController = Get.find<CategoryController>();

    _update = widget.item != null;
    _discountTypeSelected = true;

    storeController.initItemData(
      item: widget.item,
      isFood: isFood,
      isGrocery: isGrocery,
      isPharmacy: isPharmacy,
    );
    categoryController.initCategoryData(widget.item);
    if (Get.find<SplashController>().configModel!.systemTaxType ==
        'product_wise') {
      storeController.getVatTaxList();
    }
    storeController.clearVatTax();

    _nameControllerList.add(TextEditingController());
    _descriptionControllerList.add(TextEditingController());
    _nameFocusList.add(FocusNode());
    _descriptionFocusList.add(FocusNode());

    if (_update) {
      if (widget.item?.translations != null) {
        for (var translation in widget.item!.translations!) {
          if (translation.locale == 'ar' && translation.key == 'name') {
            _nameControllerList[0].text = translation.value ?? '';
          } else if (translation.locale == 'ar' &&
              translation.key == 'description') {
            _descriptionControllerList[0].text = translation.value ?? '';
          }
        }
      }

      // Fallback if translations are empty or 'ar' not found
      if (_nameControllerList[0].text.isEmpty && widget.item?.name != null) {
        _nameControllerList[0].text = widget.item!.name!;
      }
      if (_descriptionControllerList[0].text.isEmpty &&
          widget.item?.description != null) {
        _descriptionControllerList[0].text = widget.item!.description!;
      }
    }

    if (isEcommerce && _update) {
      storeController.getBrandList(widget.item);
      storeController.initializeMetaData(widget.item?.metaData);

      if (widget.item?.metaData != null) {
        _maxVideoPreviewController.text =
            widget.item!.metaData!.metaMaxVideoPreviewValue?.toString() ?? '';
      }
    }

    if (isPharmacy) {
      storeController.getSuitableTagList(widget.item);
    }
    storeController.getAttributeList(widget.item);
    storeController.setTag('', isClear: true);

    if (_update) {
      _item = Item.fromJson(widget.item!.toJson());
      if (_item.tags != null && _item.tags!.isNotEmpty) {
        for (var tag in _item.tags!) {
          storeController.setTag(tag.tag, isUpdate: false);
        }
      }
      _priceController.text = _item.price.toString();
      _discountController.text = _item.discount.toString();
      _stockController.text = _item.stock.toString();
      _maxOrderQuantityController.text = _item.maxOrderQuantity.toString();
      _barcodeController.text = _item.barcode ?? '';
      _genericNameSuggestionController.text =
          (_item.genericName != null && _item.genericName!.isNotEmpty)
          ? _item.genericName![0]!
          : '';
      storeController.setDiscountTypeIndex(
        _item.discountType == 'percent' ? 0 : 1,
        false,
      );
      storeController.setVeg(_item.veg == 1, false);
      storeController.initSetup();
      storeController.removeImageFromList();
      if (_item.isHalal == 1) {
        storeController.toggleHalal(willUpdate: false);
      }
      if (_item.isBasicMedicine == 1) {
        storeController.toggleBasicMedicine(willUpdate: false);
      }
      if (_item.isPrescriptionRequired == 1) {
        storeController.togglePrescriptionRequired(willUpdate: false);
      }
      if (Get.find<SplashController>().getStoreModuleConfig().newVariation!) {
        storeController.setExistingVariation(_item.foodVariations);
      }
    } else {
      _item = Item(imagesFullUrl: []);
      _discountController.text = '0';
      _stockController.text = '100';
      storeController.setTag('', isUpdate: false, isClear: true);
      storeController.setEmptyVariationList();
      storeController.pickImage(false, true);
      storeController.setVeg(false, false);
      if (storeController.isHalal) {
        storeController.toggleHalal(willUpdate: false);
      }
      if (storeController.isBasicMedicine) {
        storeController.toggleBasicMedicine(willUpdate: false);
      }
    }
  }

  // ignore: unused_element
  void _validateDiscount() {
    double price = double.tryParse(_priceController.text) ?? 0.0;
    double discount = double.tryParse(_discountController.text) ?? 0.0;

    if (Get.find<StoreController>().discountTypeIndex == 0) {
      if (discount > 100) {
        showCustomSnackBar(
          'discount_cannot_be_more_than_100'.tr,
          isError: true,
        );
        _discountController.text = '100';
      }
    } else if (Get.find<StoreController>().discountTypeIndex == 1) {
      if (discount > price) {
        showCustomSnackBar(
          'discount_cannot_be_more_than_price'.tr,
          isError: true,
        );
        _discountController.text = price.toString();
      }
    }
  }

  void _showPriceNumpadBottomSheet() {
    FocusScope.of(context).unfocus();
    String currentPriceText = _priceController.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void onNumPress(String val) {
              if (val == '.') {
                if (!currentPriceText.contains('.')) {
                  currentPriceText = currentPriceText.isEmpty
                      ? '0.'
                      : '$currentPriceText.';
                }
              } else {
                if (currentPriceText == '0' || currentPriceText.isEmpty) {
                  currentPriceText = val;
                } else {
                  currentPriceText += val;
                }
              }
              setModalState(() {});
            }

            void onBackspace() {
              if (currentPriceText.isNotEmpty) {
                currentPriceText = currentPriceText.substring(
                  0,
                  currentPriceText.length - 1,
                );
                setModalState(() {});
              }
            }

            void onQuickAdd(double amount) {
              final double current = double.tryParse(currentPriceText) ?? 0.0;
              final double updated = current + amount;
              currentPriceText = updated % 1 == 0
                  ? updated.toInt().toString()
                  : updated.toString();
              setModalState(() {});
            }

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Dimensions.radiusExtraLarge),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'إدخال سعر المنتج',
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Display Screen Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault,
                      ),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'السعر المطلوب:',
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        Text(
                          currentPriceText.isEmpty ? '0.00' : currentPriceText,
                          style: robotoBold.copyWith(
                            fontSize: 26,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick amount chips (+5, +10, +20, +50, +100)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [5, 10, 20, 50, 100].map((amt) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: ActionChip(
                            label: Text('+$amt'),
                            onPressed: () => onQuickAdd(amt.toDouble()),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3x4 Numpad Keypad Grid
                  ...[
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ].map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: row.map((key) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).cardColor,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).disabledColor.withOpacity(0.15),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () => onNumPress(key),
                                child: Text(
                                  key,
                                  style: robotoBold.copyWith(fontSize: 20),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),

                  // Bottom Row: Backspace, 0, dot
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.08),
                                foregroundColor: Colors.red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: onBackspace,
                              child: const Icon(Icons.backspace_outlined),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).cardColor,
                                foregroundColor: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).disabledColor.withOpacity(0.15),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => onNumPress('0'),
                              child: Text(
                                '0',
                                style: robotoBold.copyWith(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).cardColor,
                                foregroundColor: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).disabledColor.withOpacity(0.15),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => onNumPress('.'),
                              child: Text(
                                '.',
                                style: robotoBold.copyWith(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Confirm button
                  CustomButtonWidget(
                    buttonText: 'تأكيد السعر',
                    onPressed: () {
                      setState(() {
                        _priceController.text = currentPriceText;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _tagController.dispose();
    _maxOrderQuantityController.dispose();
    _c.dispose();
    _genericNameSuggestionController.dispose();
    _maxVideoPreviewController.dispose();
    _nutritionSuggestionController.dispose();
    _allergicIngredientsSuggestionController.dispose();
    _priceNode.dispose();
    _discountNode.dispose();
    _genericNameNode.dispose();
    _barcodeController.dispose();
    _barcodeNode.dispose();
    _scannerController?.dispose();
    for (var focusNode in _nameFocusList) {
      focusNode.dispose();
    }
    for (var focusNode in _descriptionFocusList) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: _update ? 'update_item'.tr : 'add_item'.tr,
      ),

      floatingActionButton: null,

      body: SafeArea(
        child: GetBuilder<CategoryController>(
          builder: (categoryController) {
            return GetBuilder<AiController>(
              builder: (aiController) {
                return GetBuilder<StoreController>(
                  builder: (storeController) {
                    List<DropdownItem<int>> unitList = [];
                    if (storeController.unitList != null) {
                      for (
                        int i = 0;
                        i < storeController.unitList!.length;
                        i++
                      ) {
                        unitList.add(
                          DropdownItem<int>(
                            value: i,
                            child: SizedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(storeController.unitList![i].unit!),
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    List<DropdownItem<int>> categoryList = [];
                    if (categoryController.categoryList != null) {
                      for (
                        int i = 0;
                        i < categoryController.categoryList!.length;
                        i++
                      ) {
                        categoryList.add(
                          DropdownItem<int>(
                            value: i,
                            child: SizedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  categoryController.categoryList![i].name!,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    List<DropdownItem<int>> subCategoryList = [];
                    if (categoryController.subCategoryList != null) {
                      for (
                        int i = 0;
                        i < categoryController.subCategoryList!.length;
                        i++
                      ) {
                        subCategoryList.add(
                          DropdownItem<int>(
                            value: i,
                            child: SizedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  categoryController.subCategoryList![i].name!,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    List<DropdownItem<int>> suitableTagList = [];
                    if (storeController.suitableTagList != null) {
                      for (
                        int i = 0;
                        i < storeController.suitableTagList!.length;
                        i++
                      ) {
                        suitableTagList.add(
                          DropdownItem<int>(
                            value: i,
                            child: SizedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  storeController.suitableTagList![i].name!,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    List<DropdownItem<int>> brandList = [];
                    if (storeController.brandList != null) {
                      for (
                        int i = 0;
                        i < storeController.brandList!.length;
                        i++
                      ) {
                        brandList.add(
                          DropdownItem<int>(
                            value: storeController.brandList![i].id,
                            child: SizedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  storeController.brandList![i].name!,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    List<DropdownItem<int>> discountTypeList = [];
                    for (
                      int i = 0;
                      i < storeController.discountTypeList.length;
                      i++
                    ) {
                      discountTypeList.add(
                        DropdownItem<int>(
                          value: i,
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                storeController.discountTypeList[i]!.tr,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    if (_module!.stock! &&
                        storeController.variantTypeList!.isNotEmpty) {
                      _stockController.text = storeController.totalStock
                          .toString();
                    }

                    List<int> nutritionSuggestion = [];
                    if (storeController.nutritionSuggestionList != null) {
                      for (
                        int index = 0;
                        index < storeController.nutritionSuggestionList!.length;
                        index++
                      ) {
                        nutritionSuggestion.add(index);
                      }
                    }

                    List<int> allergicIngredientsSuggestion = [];
                    if (storeController.allergicIngredientsSuggestionList !=
                        null) {
                      for (
                        int index = 0;
                        index <
                            storeController
                                .allergicIngredientsSuggestionList!
                                .length;
                        index++
                      ) {
                        allergicIngredientsSuggestion.add(index);
                      }
                    }

                    List<int> genericNameSuggestion = [];
                    if (storeController.genericNameSuggestionList != null) {
                      for (
                        int index = 0;
                        index <
                            storeController.genericNameSuggestionList!.length;
                        index++
                      ) {
                        genericNameSuggestion.add(index);
                      }
                    }

                    if (_update) {
                      if (storeController.vatTaxList != null &&
                          storeController.selectedVatTaxIdList.isEmpty &&
                          widget.item!.taxVatIds != null &&
                          widget.item!.taxVatIds!.isNotEmpty) {
                        storeController.preloadVatTax(
                          vatTaxList: widget.item!.taxVatIds!,
                        );
                      }
                    }

                    return (storeController.attributeList != null &&
                            categoryController.categoryList != null)
                        ? Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeDefault,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'item_info'.tr,
                                            style: robotoBold,
                                          ),
                                          const SizedBox(),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: Dimensions.paddingSizeSmall,
                                      ),

                                      AnimatedBorderContainer(
                                        padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeSmall,
                                        ),
                                        isLoading: aiController.titleLoading,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'insert_language_wise_item_name_and_description'
                                                  .tr,
                                              style: robotoRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                color: Theme.of(
                                                  context,
                                                ).disabledColor,
                                              ),
                                            ),
                                            const SizedBox(
                                              height:
                                                  Dimensions.paddingSizeDefault,
                                            ),

                                            CustomTextFieldWidget(
                                              hintText: 'name'.tr,
                                              labelText: 'name'.tr,
                                              controller:
                                                  _nameControllerList[0],
                                              capitalization:
                                                  TextCapitalization.words,
                                              focusNode: _nameFocusList[0],
                                              nextFocus: widget.isSimple
                                                  ? null
                                                  : _descriptionFocusList[0],
                                              showTitle: false,
                                            ),
                                            if (!widget.isSimple) ...[
                                              const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeExtraLarge,
                                              ),
                                              CustomTextFieldWidget(
                                                hintText: 'description'.tr,
                                                labelText: 'description'.tr,
                                                controller:
                                                    _descriptionControllerList[0],
                                                focusNode:
                                                    _descriptionFocusList[0],
                                                capitalization:
                                                    TextCapitalization
                                                        .sentences,
                                                maxLines: 3,
                                                inputAction:
                                                    TextInputAction.done,
                                                showTitle: false,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: Dimensions.paddingSizeDefault,
                                      ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'item_setup'.tr,
                                            style: robotoMedium,
                                          ),

                                          const SizedBox(),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: Dimensions.paddingSizeSmall,
                                      ),

                                      AnimatedBorderContainer(
                                        padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeSmall,
                                        ),
                                        isLoading:
                                            aiController.otherDataLoading,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            LabelWidget(
                                              labelText: 'category'.tr,
                                              child: CustomDropdownButton(
                                                hintText: 'category'.tr,
                                                dropdownMenuItems: categoryController
                                                    .categoryList
                                                    ?.map(
                                                      (
                                                        item,
                                                      ) => DropdownMenuItem<String>(
                                                        value: item.id
                                                            .toString(),
                                                        child: Text(
                                                          item.name ?? '',
                                                          style: robotoRegular.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: (String? value) {
                                                  categoryController
                                                      .setSelectedCategory(
                                                        value!,
                                                      );
                                                },
                                                selectedValue:
                                                    categoryController
                                                        .selectedCategoryID,
                                              ),
                                            ),
                                            CustomTextFieldWidget(
                                              hintText:
                                                  Get.find<
                                                        LocalizationController
                                                      >()
                                                      .isLtr
                                                  ? 'Barcode'
                                                  : 'الباركود',
                                              labelText:
                                                  Get.find<
                                                        LocalizationController
                                                      >()
                                                      .isLtr
                                                  ? 'Barcode'
                                                  : 'الباركود',
                                              controller: _barcodeController,
                                              focusNode: _barcodeNode,
                                              inputType: TextInputType.text,
                                              inputAction: TextInputAction.next,
                                              showLabelText: true,
                                              showTitle: false,
                                              suffixChild: IconButton(
                                                icon: Icon(
                                                  _showScanner
                                                      ? Icons.close
                                                      : Icons
                                                            .camera_alt_outlined,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  size: 22,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _showScanner =
                                                        !_showScanner;
                                                    if (_showScanner) {
                                                      _scannerController =
                                                          MobileScannerController();
                                                    } else {
                                                      _scannerController
                                                          ?.dispose();
                                                      _scannerController = null;
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            if (_showScanner &&
                                                _scannerController != null) ...[
                                              const SizedBox(
                                                height:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              Container(
                                                height: 200,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: Colors.black,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: MobileScanner(
                                                    controller:
                                                        _scannerController!,
                                                    onDetect: (capture) {
                                                      for (final barcode
                                                          in capture.barcodes) {
                                                        final raw = barcode
                                                            .rawValue
                                                            ?.trim();
                                                        if (raw != null &&
                                                            raw.isNotEmpty) {
                                                          setState(() {
                                                            _barcodeController
                                                                    .text =
                                                                raw;
                                                            _showScanner =
                                                                false;
                                                            _scannerController
                                                                ?.dispose();
                                                            _scannerController =
                                                                null;
                                                          });
                                                          break;
                                                        }
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(
                                              height: Dimensions
                                                  .paddingSizeExtraLarge,
                                            ),

                                            LabelWidget(
                                              labelText: 'category'.tr,
                                              child: CustomDropdownButton(
                                                hintText: 'category'.tr,
                                                dropdownMenuItems: categoryController
                                                    .categoryList
                                                    ?.map(
                                                      (
                                                        item,
                                                      ) => DropdownMenuItem<String>(
                                                        value: item.id
                                                            .toString(),
                                                        child: Text(
                                                          item.name ?? '',
                                                          style: robotoRegular.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: (String? value) {
                                                  categoryController
                                                      .setSelectedCategory(
                                                        value!,
                                                      );
                                                },
                                                selectedValue:
                                                    categoryController
                                                        .selectedCategoryID,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: Dimensions
                                                  .paddingSizeExtraLarge,
                                            ),

                                            LabelWidget(
                                              labelText: 'sub_category'.tr,
                                              child: CustomDropdownButton(
                                                hintText: 'sub_category'.tr,
                                                dropdownMenuItems:
                                                    categoryController
                                                                .subCategoryList !=
                                                            null &&
                                                        categoryController
                                                            .subCategoryList!
                                                            .isNotEmpty
                                                    ? categoryController
                                                          .subCategoryList!
                                                          .map(
                                                            (
                                                              item,
                                                            ) => DropdownMenuItem<String>(
                                                              value: item.id
                                                                  .toString(),
                                                              child: Text(
                                                                item.name ?? '',
                                                                style: robotoRegular
                                                                    .copyWith(
                                                                      fontSize:
                                                                          Dimensions
                                                                              .fontSizeDefault,
                                                                    ),
                                                              ),
                                                            ),
                                                          )
                                                          .toList()
                                                    : [
                                                        DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: null,
                                                          child: Text(
                                                            'no_subcategory_found'
                                                                .tr,
                                                            style: robotoRegular
                                                                .copyWith(
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                onChanged:
                                                    (categoryController
                                                                .subCategoryList !=
                                                            null &&
                                                        categoryController
                                                            .subCategoryList!
                                                            .isNotEmpty)
                                                    ? (String? value) {
                                                        categoryController
                                                            .setSelectedSubCategory(
                                                              value!,
                                                            );
                                                      }
                                                    : null,
                                                selectedValue:
                                                    categoryController
                                                        .selectedSubCategoryID,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: Dimensions
                                                  .paddingSizeExtraLarge,
                                            ),

                                            !widget.isSimple &&
                                                    isPharmacy &&
                                                    (!_update ||
                                                        (widget.item?.conditionId !=
                                                                null &&
                                                            widget
                                                                    .item!
                                                                    .conditionId !=
                                                                0)) &&
                                                    suitableTagList.isNotEmpty
                                                ? LabelWidget(
                                                    labelText:
                                                        'suitable_for'.tr,
                                                    child: CustomDropdownButton(
                                                      hintText:
                                                          'suitable_for'.tr,
                                                      dropdownMenuItems: suitableTagList
                                                          .map(
                                                            (item) =>
                                                                DropdownMenuItem<
                                                                  String
                                                                >(
                                                                  value: item
                                                                      .value
                                                                      .toString(),
                                                                  child: item
                                                                      .child!,
                                                                ),
                                                          )
                                                          .toList(),
                                                      onChanged: (String? value) {
                                                        storeController
                                                            .setSuitableTagIndex(
                                                              int.parse(value!),
                                                              true,
                                                            );
                                                      },
                                                      selectedValue:
                                                          storeController
                                                              .suitableTagIndex
                                                              ?.toString(),
                                                    ),
                                                  )
                                                : const SizedBox(),
                                            SizedBox(
                                              height:
                                                  !widget.isSimple &&
                                                      (isPharmacy &&
                                                              (!_update ||
                                                                  (widget.item?.conditionId !=
                                                                          null &&
                                                                      widget.item!.conditionId !=
                                                                          0)) &&
                                                              suitableTagList
                                                                  .isNotEmpty ||
                                                          brandList.isNotEmpty)
                                                  ? Dimensions
                                                        .paddingSizeExtraLarge
                                                  : 0,
                                            ),

                                            isEcommerce &&
                                                    (!_update ||
                                                        (widget.item?.brandId !=
                                                                null &&
                                                            widget
                                                                    .item!
                                                                    .brandId !=
                                                                0)) &&
                                                    brandList.isNotEmpty
                                                ? LabelWidget(
                                                    labelText: 'brand'.tr,
                                                    child: CustomDropdownButton(
                                                      hintText: 'brand'.tr,
                                                      dropdownMenuItems: brandList
                                                          .map(
                                                            (e) =>
                                                                DropdownMenuItem<
                                                                  String
                                                                >(
                                                                  value: e.value
                                                                      .toString(),
                                                                  child:
                                                                      e.child!,
                                                                ),
                                                          )
                                                          .toList(),
                                                      selectedValue:
                                                          storeController
                                                              .brandIndex
                                                              ?.toString(),
                                                      onChanged: (id) =>
                                                          storeController
                                                              .setBrandIndex(
                                                                int.parse(id!),
                                                                true,
                                                              ),
                                                    ),
                                                  )
                                                : const SizedBox(),
                                            SizedBox(
                                              height:
                                                  isEcommerce &&
                                                      (!_update ||
                                                          (widget.item?.brandId !=
                                                                  null &&
                                                              widget
                                                                      .item!
                                                                      .brandId !=
                                                                  0)) &&
                                                      brandList.isNotEmpty
                                                  ? Dimensions
                                                        .paddingSizeExtraLarge
                                                  : 0,
                                            ),

                                            const SizedBox(),
                                            SizedBox(
                                              height: isPharmacy
                                                  ? Dimensions
                                                        .paddingSizeExtraLarge
                                                  : 0,
                                            ),

                                            const SizedBox(),
                                            SizedBox(
                                              height: isFood || isGrocery
                                                  ? Dimensions
                                                        .paddingSizeDefault
                                                  : 0,
                                            ),

                                            const SizedBox(),
                                            SizedBox(
                                              height: isFood || isGrocery
                                                  ? Dimensions
                                                        .paddingSizeDefault
                                                  : 0,
                                            ),

                                            ((_module.vegNonVeg! &&
                                                        Get.find<
                                                              SplashController
                                                            >()
                                                            .configModel!
                                                            .toggleVegNonVeg!)) &&
                                                    (!_update ||
                                                        (widget.item?.veg !=
                                                            null))
                                                ? LabelWidget(
                                                    labelText: 'food_type'.tr,
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Row(
                                                            children: [
                                                              RadioGroup(
                                                                groupValue:
                                                                    storeController
                                                                        .isVeg
                                                                    ? 'veg'
                                                                    : 'non_veg',
                                                                onChanged:
                                                                    (
                                                                      String?
                                                                      value,
                                                                    ) => storeController
                                                                        .setVeg(
                                                                          value ==
                                                                              'veg',
                                                                          true,
                                                                        ),
                                                                child: Radio(
                                                                  value: 'veg',
                                                                  fillColor: WidgetStateProperty.all<Color>(
                                                                    storeController
                                                                            .isVeg
                                                                        ? Theme.of(
                                                                            context,
                                                                          ).primaryColor
                                                                        : Theme.of(
                                                                            context,
                                                                          ).disabledColor,
                                                                  ),
                                                                ),
                                                              ),

                                                              Text(
                                                                'veg'.tr,
                                                                style: robotoMedium.copyWith(
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeSmall,
                                                                  color:
                                                                      storeController
                                                                          .isVeg
                                                                      ? Theme.of(
                                                                              context,
                                                                            )
                                                                            .textTheme
                                                                            .bodyLarge
                                                                            ?.color
                                                                      : Theme.of(
                                                                          context,
                                                                        ).disabledColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        Expanded(
                                                          child: Row(
                                                            children: [
                                                              RadioGroup(
                                                                groupValue:
                                                                    storeController
                                                                        .isVeg
                                                                    ? 'veg'
                                                                    : 'non_veg',
                                                                onChanged:
                                                                    (
                                                                      String?
                                                                      value,
                                                                    ) => storeController
                                                                        .setVeg(
                                                                          value ==
                                                                              'veg',
                                                                          true,
                                                                        ),
                                                                child: Radio(
                                                                  value:
                                                                      'non_veg',
                                                                  fillColor: WidgetStateProperty.all<Color>(
                                                                    storeController
                                                                            .isVeg
                                                                        ? Theme.of(
                                                                            context,
                                                                          ).disabledColor
                                                                        : Theme.of(
                                                                            context,
                                                                          ).primaryColor,
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(
                                                                'non_veg'.tr,
                                                                style: robotoMedium.copyWith(
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeSmall,
                                                                  color:
                                                                      storeController
                                                                          .isVeg
                                                                      ? Theme.of(
                                                                          context,
                                                                        ).disabledColor
                                                                      : Theme.of(
                                                                              context,
                                                                            )
                                                                            .textTheme
                                                                            .bodyLarge
                                                                            ?.color,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : const SizedBox(),
                                            SizedBox(
                                              height:
                                                  ((_module.vegNonVeg! &&
                                                          Get.find<
                                                                SplashController
                                                              >()
                                                              .configModel!
                                                              .toggleVegNonVeg!) &&
                                                      (!_update ||
                                                          (widget.item?.veg !=
                                                              null)))
                                                  ? Dimensions
                                                        .paddingSizeExtraLarge
                                                  : 0,
                                            ),

                                            const SizedBox(),

                                            const SizedBox(),

                                            Get.find<SplashController>()
                                                        .configModel!
                                                        .systemTaxType ==
                                                    'product_wise'
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      CustomDropdownButton(
                                                        dropdownMenuItems: storeController.vatTaxList?.map((
                                                          e,
                                                        ) {
                                                          bool isInVatTaxList =
                                                              storeController
                                                                  .selectedVatTaxNameList
                                                                  .contains(
                                                                    e.name,
                                                                  );
                                                          return DropdownMenuItem<
                                                            String
                                                          >(
                                                            value: e.name,
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  '${e.name!} (${e.taxRate}%)',
                                                                  style:
                                                                      robotoRegular,
                                                                ),
                                                                const Spacer(),
                                                                if (isInVatTaxList)
                                                                  const Icon(
                                                                    Icons.check,
                                                                    color: Colors
                                                                        .green,
                                                                  ),
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                        showTitle: false,
                                                        hintText:
                                                            'select_vat_tax'.tr,
                                                        onChanged: (String? value) {
                                                          final selectedVatTax =
                                                              storeController
                                                                  .vatTaxList
                                                                  ?.firstWhere(
                                                                    (vatTax) =>
                                                                        vatTax
                                                                            .name ==
                                                                        value,
                                                                  );
                                                          if (selectedVatTax !=
                                                              null) {
                                                            storeController
                                                                .setSelectedVatTax(
                                                                  selectedVatTax
                                                                      .name,
                                                                  selectedVatTax
                                                                      .id,
                                                                  selectedVatTax
                                                                      .taxRate,
                                                                );
                                                          }
                                                        },
                                                        selectedValue: null,
                                                        selectedItemBuilder: (context) {
                                                          return storeController
                                                                  .vatTaxList
                                                                  ?.map((e) {
                                                                    return Text(
                                                                      'select_vat_tax'
                                                                          .tr,
                                                                      style: robotoRegular.copyWith(
                                                                        color: Colors
                                                                            .grey,
                                                                      ),
                                                                    );
                                                                  })
                                                                  .toList() ??
                                                              [];
                                                        },
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            storeController
                                                                .selectedVatTaxNameList
                                                                .isNotEmpty
                                                            ? Dimensions
                                                                  .paddingSizeSmall
                                                            : 0,
                                                      ),

                                                      Wrap(
                                                        children: List.generate(
                                                          storeController
                                                              .selectedVatTaxNameList
                                                              .length,
                                                          (index) {
                                                            final vatTaxName =
                                                                storeController
                                                                    .selectedVatTaxNameList[index];
                                                            final vatTaxId =
                                                                storeController
                                                                    .selectedVatTaxIdList[index];
                                                            final taxRate =
                                                                storeController
                                                                    .selectedTaxRateList[index];
                                                            return Padding(
                                                              padding: const EdgeInsets.only(
                                                                right: Dimensions
                                                                    .paddingSizeSmall,
                                                              ),
                                                              child: Stack(
                                                                clipBehavior:
                                                                    Clip.none,
                                                                children: [
                                                                  FilterChip(
                                                                    label: Text(
                                                                      '$vatTaxName ($taxRate%)',
                                                                    ),
                                                                    selected:
                                                                        false,
                                                                    onSelected:
                                                                        (
                                                                          bool
                                                                          value,
                                                                        ) {},
                                                                  ),

                                                                  Positioned(
                                                                    right: -5,
                                                                    top: 0,
                                                                    child: InkWell(
                                                                      onTap: () {
                                                                        storeController.removeVatTax(
                                                                          vatTaxName,
                                                                          vatTaxId,
                                                                          taxRate,
                                                                        );
                                                                      },
                                                                      child: Container(
                                                                        padding:
                                                                            const EdgeInsets.all(
                                                                              1,
                                                                            ),
                                                                        decoration: BoxDecoration(
                                                                          color: Theme.of(
                                                                            context,
                                                                          ).cardColor,
                                                                          shape:
                                                                              BoxShape.circle,
                                                                          border: Border.all(
                                                                            color:
                                                                                Colors.red,
                                                                            width:
                                                                                1,
                                                                          ),
                                                                        ),
                                                                        child: const Icon(
                                                                          Icons
                                                                              .close,
                                                                          size:
                                                                              15,
                                                                          color:
                                                                              Colors.red,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : const SizedBox(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: Dimensions.paddingSizeDefault,
                                      ),

                                      const SizedBox(),

                                      Text('price_info'.tr, style: robotoBold),
                                      const SizedBox(
                                        height: Dimensions.paddingSizeSmall,
                                      ),

                                      AnimatedBorderContainer(
                                        padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeSmall,
                                        ),
                                        isLoading:
                                            aiController.otherDataLoading,
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: CustomTextFieldWidget(
                                                    hintText: 'price'.tr,
                                                    labelText: 'price'.tr,
                                                    controller:
                                                        _priceController,
                                                    focusNode: _priceNode,
                                                    isAmount: true,
                                                    readOnly: true,
                                                    onTap:
                                                        _showPriceNumpadBottomSheet,
                                                    suffixChild: IconButton(
                                                      icon: Icon(
                                                        Icons.dialpad,
                                                        color: Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                        size: 20,
                                                      ),
                                                      onPressed:
                                                          _showPriceNumpadBottomSheet,
                                                    ),
                                                  ),
                                                ),

                                                if (_module.unit! &&
                                                    unitList.isNotEmpty) ...[
                                                  const SizedBox(
                                                    width: Dimensions
                                                        .paddingSizeSmall,
                                                  ),

                                                  Expanded(
                                                    flex: 1,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              Dimensions
                                                                  .radiusDefault,
                                                            ),
                                                        color: Theme.of(
                                                          context,
                                                        ).cardColor,
                                                        border: Border.all(
                                                          color:
                                                              Theme.of(context)
                                                                  .disabledColor
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                        ),
                                                      ),
                                                      child: CustomDropdown(
                                                        onChange:
                                                            (
                                                              int? value,
                                                              int index,
                                                            ) {
                                                              storeController
                                                                  .setUnitIndex(
                                                                    value!,
                                                                    true,
                                                                  );
                                                            },
                                                        dropdownButtonStyle: DropdownButtonStyle(
                                                          height: 45,
                                                          padding: const EdgeInsets.symmetric(
                                                            vertical: Dimensions
                                                                .paddingSizeExtraSmall,
                                                            horizontal: Dimensions
                                                                .paddingSizeExtraSmall,
                                                          ),
                                                          primaryColor:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge!
                                                                  .color,
                                                        ),
                                                        iconColor: Theme.of(
                                                          context,
                                                        ).disabledColor,
                                                        dropdownStyle: DropdownStyle(
                                                          elevation: 10,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                Dimensions
                                                                    .radiusDefault,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.all(
                                                                Dimensions
                                                                    .paddingSizeExtraSmall,
                                                              ),
                                                        ),
                                                        items: unitList,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 8,
                                                              ),
                                                          child: Text(
                                                            widget.item !=
                                                                        null &&
                                                                    storeController
                                                                            .unitList !=
                                                                        null &&
                                                                    storeController
                                                                        .unitList!
                                                                        .isNotEmpty
                                                                ? storeController
                                                                      .unitList![storeController
                                                                          .unitIndex!]
                                                                      .unit!
                                                                      .tr
                                                                : 'unit'.tr,
                                                            style: robotoRegular.copyWith(
                                                              color: Theme.of(
                                                                context,
                                                              ).disabledColor,
                                                              fontSize: Dimensions
                                                                  .fontSizeLarge,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            SizedBox(
                                              height: !isGrocery
                                                  ? Dimensions
                                                        .paddingSizeExtraLarge
                                                  : ((_module.unit! &&
                                                            unitList.isNotEmpty)
                                                        ? Dimensions
                                                              .paddingSizeExtraLarge
                                                        : 0),
                                            ),

                                            if (!isGrocery) ...[
                                              CustomTextFieldWidget(
                                                hintText:
                                                    'maximum_order_quantity'.tr,
                                                labelText:
                                                    'maximum_order_quantity'.tr,
                                                controller:
                                                    _maxOrderQuantityController,
                                                isNumber: true,
                                              ),
                                              SizedBox(
                                                height:
                                                    (_module.unit! &&
                                                        unitList.isNotEmpty)
                                                    ? Dimensions
                                                          .paddingSizeExtraLarge
                                                    : 0,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height:
                                            (!isGrocery &&
                                                (Get.find<SplashController>()
                                                        .getStoreModuleConfig()
                                                        .newVariation! ||
                                                    (storeController
                                                                .attributeList !=
                                                            null &&
                                                        storeController
                                                            .attributeList!
                                                            .isNotEmpty) ||
                                                    (_update &&
                                                        widget
                                                                .item!
                                                                .attributes !=
                                                            null &&
                                                        widget
                                                            .item!
                                                            .attributes!
                                                            .isNotEmpty)))
                                            ? Dimensions.paddingSizeDefault
                                            : 0,
                                      ),

                                      (!isGrocery &&
                                              (Get.find<SplashController>()
                                                      .getStoreModuleConfig()
                                                      .newVariation! ||
                                                  (storeController
                                                              .attributeList !=
                                                          null &&
                                                      storeController
                                                          .attributeList!
                                                          .isNotEmpty) ||
                                                  (_update &&
                                                      widget.item!.attributes !=
                                                          null &&
                                                      widget
                                                          .item!
                                                          .attributes!
                                                          .isNotEmpty)))
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Get.find<SplashController>()
                                                            .getStoreModuleConfig()
                                                            .newVariation!
                                                        ? Row(
                                                            children: [
                                                              Text(
                                                                'food_variation'
                                                                    .tr,
                                                                style:
                                                                    robotoBold,
                                                              ),
                                                              Text(
                                                                ' (${'optional'.tr})',
                                                                style: robotoRegular.copyWith(
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).disabledColor,
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeSmall,
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        : Text(
                                                            'attribute'.tr,
                                                            style: robotoBold,
                                                          ),

                                                    const SizedBox(),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeSmall,
                                                ),

                                                Get.find<SplashController>()
                                                        .getStoreModuleConfig()
                                                        .newVariation!
                                                    ? FoodVariationViewWidget(
                                                        storeController:
                                                            storeController,
                                                        item: widget.item,
                                                      )
                                                    : AttributeViewWidget(
                                                        storeController:
                                                            storeController,
                                                        product: widget.item,
                                                      ),
                                                const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeDefault,
                                                ),
                                              ],
                                            )
                                          : const SizedBox(),

                                      _module.addOn!
                                          ? Text('addons'.tr, style: robotoBold)
                                          : const SizedBox(),
                                      SizedBox(
                                        height: _module.addOn!
                                            ? Dimensions.paddingSizeSmall
                                            : 0,
                                      ),

                                      _module.addOn!
                                          ? AnimatedBorderContainer(
                                              padding: const EdgeInsets.all(
                                                Dimensions.paddingSizeSmall,
                                              ),
                                              isLoading:
                                                  aiController.otherDataLoading,
                                              child: Column(
                                                children: [
                                                  _module.addOn!
                                                      ? GetBuilder<
                                                          AddonController
                                                        >(
                                                          builder: (addonController) {
                                                            List<int> addons =
                                                                [];
                                                            if (addonController
                                                                    .addonList !=
                                                                null) {
                                                              for (
                                                                int index = 0;
                                                                index <
                                                                    addonController
                                                                        .addonList!
                                                                        .length;
                                                                index++
                                                              ) {
                                                                if (addonController
                                                                            .addonList![index]
                                                                            .status ==
                                                                        1 &&
                                                                    !storeController
                                                                        .selectedAddons!
                                                                        .contains(
                                                                          index,
                                                                        )) {
                                                                  addons.add(
                                                                    index,
                                                                  );
                                                                }
                                                              }
                                                            }
                                                            return Autocomplete<
                                                              int
                                                            >(
                                                              optionsBuilder:
                                                                  (
                                                                    TextEditingValue
                                                                    value,
                                                                  ) {
                                                                    if (value
                                                                        .text
                                                                        .isEmpty) {
                                                                      return const Iterable<
                                                                        int
                                                                      >.empty();
                                                                    } else {
                                                                      return addons.where(
                                                                        (
                                                                          addon,
                                                                        ) => addonController
                                                                            .addonList![addon]
                                                                            .name!
                                                                            .toLowerCase()
                                                                            .contains(
                                                                              value.text.toLowerCase(),
                                                                            ),
                                                                      );
                                                                    }
                                                                  },
                                                              fieldViewBuilder:
                                                                  (
                                                                    context,
                                                                    controller,
                                                                    node,
                                                                    onComplete,
                                                                  ) {
                                                                    _c =
                                                                        controller;
                                                                    return SizedBox(
                                                                      height:
                                                                          50,
                                                                      child: CustomTextFieldWidget(
                                                                        controller:
                                                                            controller,
                                                                        focusNode:
                                                                            node,
                                                                        hintText:
                                                                            'addons'.tr,
                                                                        labelText:
                                                                            'addons'.tr,
                                                                        onEditingComplete: () {
                                                                          onComplete();
                                                                          controller.text =
                                                                              '';
                                                                        },
                                                                      ),
                                                                    );
                                                                  },
                                                              displayStringForOption:
                                                                  (
                                                                    value,
                                                                  ) => addonController
                                                                      .addonList![value]
                                                                      .name!,
                                                              onSelected: (int value) {
                                                                _c.text = '';
                                                                storeController
                                                                    .setSelectedAddonIndex(
                                                                      value,
                                                                      true,
                                                                    );
                                                                //_addons.removeAt(value);
                                                              },
                                                            );
                                                          },
                                                        )
                                                      : const SizedBox(),
                                                  SizedBox(
                                                    height:
                                                        (_module.addOn! &&
                                                            storeController
                                                                .selectedAddons!
                                                                .isNotEmpty)
                                                        ? Dimensions
                                                              .paddingSizeSmall
                                                        : 0,
                                                  ),

                                                  _module.addOn!
                                                      ? SizedBox(
                                                          height:
                                                              storeController
                                                                  .selectedAddons!
                                                                  .isNotEmpty
                                                              ? 40
                                                              : 0,
                                                          child: ListView.builder(
                                                            itemCount:
                                                                storeController
                                                                    .selectedAddons!
                                                                    .length,
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            itemBuilder: (context, index) {
                                                              return Container(
                                                                padding: const EdgeInsets.only(
                                                                  left: Dimensions
                                                                      .paddingSizeExtraSmall,
                                                                ),
                                                                margin: const EdgeInsets.only(
                                                                  right: Dimensions
                                                                      .paddingSizeSmall,
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      Theme.of(
                                                                        context,
                                                                      ).disabledColor.withValues(
                                                                        alpha:
                                                                            0.2,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        Dimensions
                                                                            .radiusSmall,
                                                                      ),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    GetBuilder<
                                                                      AddonController
                                                                    >(
                                                                      builder:
                                                                          (
                                                                            addonController,
                                                                          ) {
                                                                            return Text(
                                                                              addonController.addonList![storeController.selectedAddons![index]].name!,
                                                                              style: robotoRegular.copyWith(
                                                                                color:
                                                                                    Theme.of(
                                                                                      context,
                                                                                    ).disabledColor.withValues(
                                                                                      alpha: 0.7,
                                                                                    ),
                                                                              ),
                                                                            );
                                                                          },
                                                                    ),
                                                                    InkWell(
                                                                      onTap: () =>
                                                                          storeController.removeAddon(
                                                                            index,
                                                                          ),
                                                                      child: Padding(
                                                                        padding: const EdgeInsets.all(
                                                                          Dimensions
                                                                              .paddingSizeExtraSmall,
                                                                        ),
                                                                        child: Icon(
                                                                          Icons
                                                                              .close,
                                                                          size:
                                                                              15,
                                                                          color:
                                                                              Theme.of(
                                                                                context,
                                                                              ).disabledColor.withValues(
                                                                                alpha: 0.7,
                                                                              ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                ],
                                              ),
                                            )
                                          : const SizedBox(),
                                      SizedBox(
                                        height: _module.addOn!
                                            ? Dimensions.paddingSizeDefault
                                            : 0,
                                      ),

                                      if (!isGrocery) ...[
                                        Text('tag'.tr, style: robotoBold),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeSmall,
                                        ),

                                        AnimatedBorderContainer(
                                          padding: const EdgeInsets.all(
                                            Dimensions.paddingSizeSmall,
                                          ),
                                          isLoading:
                                              aiController.otherDataLoading,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    flex: 8,
                                                    child: CustomTextFieldWidget(
                                                      hintText: 'tag'.tr,
                                                      labelText: 'tag'.tr,
                                                      controller:
                                                          _tagController,
                                                      inputAction:
                                                          TextInputAction.done,
                                                      onSubmit: (name) {
                                                        if (name != null &&
                                                            name.isNotEmpty) {
                                                          storeController
                                                              .setTag(name);
                                                          _tagController.text =
                                                              '';
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: Dimensions
                                                        .paddingSizeSmall,
                                                  ),

                                                  Expanded(
                                                    flex: 2,
                                                    child: CustomButtonWidget(
                                                      buttonText: 'add'.tr,
                                                      onPressed: () {
                                                        if (_tagController
                                                                    .text !=
                                                                '' &&
                                                            _tagController
                                                                .text
                                                                .isNotEmpty) {
                                                          storeController
                                                              .setTag(
                                                                _tagController
                                                                    .text
                                                                    .trim(),
                                                              );
                                                          _tagController.text =
                                                              '';
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeDefault,
                                              ),

                                              storeController.tagList.isNotEmpty
                                                  ? SizedBox(
                                                      height: 40,
                                                      child: ListView.builder(
                                                        shrinkWrap: true,
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        itemCount:
                                                            storeController
                                                                .tagList
                                                                .length,
                                                        itemBuilder: (context, index) {
                                                          return Container(
                                                            margin: const EdgeInsets.symmetric(
                                                              horizontal: Dimensions
                                                                  .paddingSizeExtraSmall,
                                                            ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      Dimensions
                                                                          .paddingSizeSmall,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .disabledColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.2,
                                                                      ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    Dimensions
                                                                        .radiusSmall,
                                                                  ),
                                                            ),
                                                            child: Center(
                                                              child: Row(
                                                                children: [
                                                                  Text(
                                                                    storeController
                                                                        .tagList[index]!,
                                                                    style: robotoRegular.copyWith(
                                                                      color: Theme.of(context)
                                                                          .disabledColor
                                                                          .withValues(
                                                                            alpha:
                                                                                0.7,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: Dimensions
                                                                        .paddingSizeExtraSmall,
                                                                  ),

                                                                  InkWell(
                                                                    onTap: () =>
                                                                        storeController.removeTag(
                                                                          index,
                                                                        ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .clear,
                                                                      size: 18,
                                                                      color: Theme.of(context)
                                                                          .disabledColor
                                                                          .withValues(
                                                                            alpha:
                                                                                0.7,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.paddingSizeDefault,
                                        ),
                                      ],

                                      _module.itemAvailableTime!
                                          ? Text(
                                              'availability'.tr,
                                              style: robotoBold,
                                            )
                                          : const SizedBox(),
                                      SizedBox(
                                        height: _module.itemAvailableTime!
                                            ? Dimensions.paddingSizeSmall
                                            : 0,
                                      ),

                                      _module.itemAvailableTime!
                                          ? AnimatedBorderContainer(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: Dimensions
                                                        .paddingSizeSmall,
                                                    vertical: Dimensions
                                                        .paddingSizeLarge,
                                                  ),
                                              isLoading:
                                                  aiController.otherDataLoading,
                                              child: Column(
                                                children: [
                                                  CustomTimePickerWidget(
                                                    title:
                                                        'available_time_starts'
                                                            .tr,
                                                    time: storeController
                                                        .availableTimeStarts,
                                                    onTimeChanged: (time) {
                                                      storeController
                                                          .setAvailableTimeStarts(
                                                            startTime: time,
                                                          );
                                                    },
                                                  ),
                                                  const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeExtraLarge,
                                                  ),

                                                  CustomTimePickerWidget(
                                                    title: 'available_time_ends'
                                                        .tr,
                                                    time: storeController
                                                        .availableTimeEnds,
                                                    onTimeChanged: (time) {
                                                      storeController
                                                          .setAvailableTimeEnds(
                                                            endTime: time,
                                                          );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox(),
                                      SizedBox(
                                        height: _module.itemAvailableTime!
                                            ? Dimensions.paddingSizeDefault
                                            : 0,
                                      ),

                                      const SizedBox(),

                                      // Item Image Section
                                      Row(
                                        children: [
                                          Text(
                                            'item_images'.tr,
                                            style: robotoBold,
                                          ),
                                          const SizedBox(
                                            width: Dimensions.paddingSizeSmall,
                                          ),

                                          Text(
                                            '(${'max_size_2_mb'.tr})',
                                            style: robotoRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeExtraSmall,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: Dimensions.paddingSizeSmall,
                                      ),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.paddingSizeSmall,
                                          vertical: Dimensions.paddingSizeLarge,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(
                                            Dimensions.radiusDefault,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              spreadRadius: 0,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: GridView.builder(
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 3,
                                                childAspectRatio: (1 / 1),
                                                mainAxisSpacing:
                                                    Dimensions.paddingSizeSmall,
                                                crossAxisSpacing:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount:
                                              storeController
                                                  .savedImages
                                                  .length +
                                              storeController.rawImages.length +
                                              1,
                                          itemBuilder: (context, index) {
                                            bool savedImage =
                                                index <
                                                storeController
                                                    .savedImages
                                                    .length;
                                            XFile? file =
                                                (savedImage ||
                                                    index ==
                                                        (storeController
                                                                .rawImages
                                                                .length +
                                                            storeController
                                                                .savedImages
                                                                .length))
                                                ? null
                                                : storeController
                                                      .rawImages[index -
                                                      storeController
                                                          .savedImages
                                                          .length];
                                            if (index ==
                                                (storeController
                                                        .rawImages
                                                        .length +
                                                    storeController
                                                        .savedImages
                                                        .length)) {
                                              return InkWell(
                                                onTap: () {
                                                  if ((storeController
                                                              .savedImages
                                                              .length +
                                                          storeController
                                                              .rawImages
                                                              .length) <
                                                      6) {
                                                    storeController
                                                        .pickImages();
                                                  } else {
                                                    showCustomSnackBar(
                                                      'maximum_image_limit_is_6'
                                                          .tr,
                                                    );
                                                  }
                                                },
                                                child: DottedBorder(
                                                  options:
                                                      RoundedRectDottedBorderOptions(
                                                        radius:
                                                            const Radius.circular(
                                                              Dimensions
                                                                  .radiusDefault,
                                                            ),
                                                        dashPattern: const [
                                                          8,
                                                          4,
                                                        ],
                                                        strokeWidth: 1,
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                      ),
                                                  child: Container(
                                                    width: context.width,
                                                    height: context.width,
                                                    decoration: BoxDecoration(
                                                      color: Get.isDarkMode
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                )
                                                          : const Color(
                                                              0xFFFAFAFA,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            Dimensions
                                                                .radiusDefault,
                                                          ),
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          CupertinoIcons
                                                              .photo_camera_solid,
                                                          color:
                                                              Theme.of(context)
                                                                  .disabledColor
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                          size: 30,
                                                        ),
                                                        const SizedBox(
                                                          height: Dimensions
                                                              .paddingSizeDefault,
                                                        ),
                                                        Text(
                                                          'click_to_upload'.tr,
                                                          style: robotoBold.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                            color: Theme.of(
                                                              context,
                                                            ).disabledColor,
                                                          ),
                                                        ),
                                                        Text(
                                                          'image_format'.tr,
                                                          style: robotoRegular.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeExtraSmall,
                                                            color: Theme.of(
                                                              context,
                                                            ).disabledColor,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            return DottedBorder(
                                              options:
                                                  RoundedRectDottedBorderOptions(
                                                    radius:
                                                        const Radius.circular(
                                                          Dimensions
                                                              .radiusDefault,
                                                        ),
                                                    dashPattern: const [8, 4],
                                                    strokeWidth: 1,
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.5),
                                                  ),
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          Dimensions
                                                              .radiusDefault,
                                                        ),
                                                    child: savedImage
                                                        ? CustomImageWidget(
                                                            image: storeController
                                                                .savedImages[index],
                                                            width:
                                                                context.width,
                                                            height:
                                                                context.width,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : GetPlatform.isWeb
                                                        ? Image.network(
                                                            file!.path,
                                                            width:
                                                                context.width,
                                                            height:
                                                                context.width,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.file(
                                                            File(file!.path),
                                                            width:
                                                                context.width,
                                                            height:
                                                                context.width,
                                                            fit: BoxFit.cover,
                                                          ),
                                                  ),

                                                  Positioned(
                                                    right: 0,
                                                    top: 0,
                                                    child: InkWell(
                                                      onTap: () {
                                                        if (savedImage) {
                                                          storeController
                                                              .removeSavedImage(
                                                                index,
                                                              );
                                                        } else {
                                                          storeController.removeImage(
                                                            index -
                                                                storeController
                                                                    .savedImages
                                                                    .length,
                                                          );
                                                        }
                                                      },
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(
                                                          Dimensions
                                                              .paddingSizeSmall,
                                                        ),
                                                        child: Icon(
                                                          Icons.delete_forever,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(
                                        height: Dimensions.paddingSizeSmall,
                                      ),
                                      const SizedBox(
                                        height: Dimensions.paddingSizeDefault,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: Dimensions.paddingSizeSmall,
                                  horizontal: Dimensions.paddingSizeLarge,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      spreadRadius: 0,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: CustomButtonWidget(
                                  buttonText: _update
                                      ? 'update'.tr
                                      : 'submit'.tr,
                                  isLoading: storeController.isLoading,
                                  onPressed: () {
                                    String price = _priceController.text.trim();
                                    String discount = _discountController.text
                                        .trim();
                                    int maxOrderQuantity =
                                        _maxOrderQuantityController
                                            .text
                                            .isNotEmpty
                                        ? int.parse(
                                            _maxOrderQuantityController.text,
                                          )
                                        : 0;
                                    bool haveBlankVariant = false;
                                    bool blankVariantPrice = false;
                                    bool blankVariantStock = false;

                                    bool variationNameEmpty = false;
                                    bool variationMinMaxEmpty = false;
                                    bool variationOptionNameEmpty = false;
                                    bool variationOptionPriceEmpty = false;
                                    bool variationMinLessThenZero = false;
                                    bool variationMaxSmallThenMin = false;
                                    bool variationMaxBigThenOptions = false;

                                    for (AttributeModel attr
                                        in storeController.attributeList!) {
                                      if (attr.active &&
                                          attr.variants.isEmpty) {
                                        haveBlankVariant = true;
                                        break;
                                      }
                                    }
                                    if (Get.find<SplashController>()
                                        .getStoreModuleConfig()
                                        .newVariation!) {
                                      for (VariationModelBodyModel
                                          variationModel
                                          in storeController.variationList!) {
                                        if (variationModel
                                            .nameController!
                                            .text
                                            .isEmpty) {
                                          variationNameEmpty = true;
                                        } else if (!variationModel.isSingle) {
                                          if (variationModel
                                                  .minController!
                                                  .text
                                                  .isEmpty ||
                                              variationModel
                                                  .maxController!
                                                  .text
                                                  .isEmpty) {
                                            variationMinMaxEmpty = true;
                                          } else if (int.parse(
                                                variationModel
                                                    .minController!
                                                    .text,
                                              ) <
                                              1) {
                                            variationMinLessThenZero = true;
                                          } else if (int.parse(
                                                variationModel
                                                    .maxController!
                                                    .text,
                                              ) <
                                              int.parse(
                                                variationModel
                                                    .minController!
                                                    .text,
                                              )) {
                                            variationMaxSmallThenMin = true;
                                          } else if (int.parse(
                                                variationModel
                                                    .maxController!
                                                    .text,
                                              ) >
                                              variationModel.options!.length) {
                                            variationMaxBigThenOptions = true;
                                          }
                                        } else {
                                          for (Option option
                                              in variationModel.options!) {
                                            if (option
                                                .optionNameController!
                                                .text
                                                .isEmpty) {
                                              variationOptionNameEmpty = true;
                                            } else if (option
                                                .optionPriceController!
                                                .text
                                                .isEmpty) {
                                              variationOptionPriceEmpty = true;
                                            }
                                          }
                                        }
                                      }
                                    } else {
                                      for (VariantTypeModel variantType
                                          in storeController.variantTypeList!) {
                                        if (variantType
                                            .priceController
                                            .text
                                            .isEmpty) {
                                          blankVariantPrice = true;
                                          break;
                                        }
                                        if (_module.stock! &&
                                            variantType
                                                .stockController
                                                .text
                                                .isEmpty) {
                                          blankVariantStock = true;
                                          break;
                                        }
                                      }
                                    }

                                    bool defaultDataNull = false;
                                    if (_nameControllerList[0].text
                                        .trim()
                                        .isEmpty) {
                                      defaultDataNull = true;
                                    }

                                    bool checkDiscountWithVariationPrice =
                                        false;
                                    if (storeController.discountTypeIndex ==
                                            1 &&
                                        storeController
                                            .variantTypeList!
                                            .isNotEmpty) {
                                      for (VariantTypeModel variantType
                                          in storeController.variantTypeList!) {
                                        double variantPrice = double.parse(
                                          variantType.priceController.text,
                                        );
                                        double discountValue = double.parse(
                                          discount,
                                        );
                                        if (variantPrice < discountValue) {
                                          checkDiscountWithVariationPrice =
                                              true;
                                          break;
                                        }
                                      }
                                    }

                                    if (defaultDataNull) {
                                      showCustomSnackBar(
                                        'enter_data_for_default_language'.tr,
                                      );
                                    } else if (categoryController
                                            .selectedCategoryID ==
                                        null) {
                                      showCustomSnackBar(
                                        'select_a_category'.tr,
                                      );
                                    } else if (Get.find<SplashController>()
                                                .configModel!
                                                .systemTaxType ==
                                            'product_wise' &&
                                        storeController
                                            .selectedVatTaxIdList
                                            .isEmpty) {
                                      showCustomSnackBar('select_vat_tax'.tr);
                                    } else if (price.isEmpty) {
                                      showCustomSnackBar('enter_item_price'.tr);
                                    } else if (!_discountTypeSelected) {
                                      showCustomSnackBar(
                                        'enter_discount_type'.tr,
                                      );
                                    } else if (discount.isEmpty) {
                                      showCustomSnackBar(
                                        'enter_item_discount'.tr,
                                      );
                                    } else if (haveBlankVariant) {
                                      showCustomSnackBar(
                                        'add_at_least_one_variant_for_every_attribute'
                                            .tr,
                                      );
                                    } else if (blankVariantPrice) {
                                      showCustomSnackBar(
                                        'enter_price_for_every_variant'.tr,
                                      );
                                    } else if (variationNameEmpty) {
                                      showCustomSnackBar(
                                        'enter_name_for_every_variation'.tr,
                                      );
                                    } else if (variationMinMaxEmpty) {
                                      showCustomSnackBar(
                                        'enter_min_max_for_every_multipart_variation'
                                            .tr,
                                      );
                                    } else if (variationOptionNameEmpty) {
                                      showCustomSnackBar(
                                        'enter_option_name_for_every_variation'
                                            .tr,
                                      );
                                    } else if (variationOptionPriceEmpty) {
                                      showCustomSnackBar(
                                        'enter_option_price_for_every_variation'
                                            .tr,
                                      );
                                    } else if (variationMinLessThenZero) {
                                      showCustomSnackBar(
                                        'minimum_type_cant_be_less_then_1'.tr,
                                      );
                                    } else if (variationMaxSmallThenMin) {
                                      showCustomSnackBar(
                                        'max_type_cant_be_less_then_minimum_type'
                                            .tr,
                                      );
                                    } else if (variationMaxBigThenOptions) {
                                      showCustomSnackBar(
                                        'max_type_length_should_not_be_more_then_options_length'
                                            .tr,
                                      );
                                    } else if (_module.stock! &&
                                        blankVariantStock) {
                                      showCustomSnackBar(
                                        'enter_stock_for_every_variant'.tr,
                                      );
                                    } else if (_module.stock! &&
                                        storeController
                                            .variantTypeList!
                                            .isEmpty &&
                                        _stockController.text.trim().isEmpty) {
                                      showCustomSnackBar('enter_stock'.tr);
                                    } else if (_module.unit! &&
                                        (storeController.unitIndex == null)) {
                                      showCustomSnackBar('add_an_unit'.tr);
                                    } else if (maxOrderQuantity < 0) {
                                      showCustomSnackBar(
                                        'maximum_item_order_quantity_can_not_be_negative'
                                            .tr,
                                      );
                                    } else if (_module.itemAvailableTime! &&
                                        storeController.availableTimeStarts ==
                                            null) {
                                      showCustomSnackBar('pick_start_time'.tr);
                                    } else if (_module.itemAvailableTime! &&
                                        storeController.availableTimeEnds ==
                                            null) {
                                      showCustomSnackBar('pick_end_time'.tr);
                                    } else if (!_update &&
                                        storeController.rawImages.isEmpty &&
                                        _item.imageFullUrl == null) {
                                      showCustomSnackBar(
                                        'upload_item_image'.tr,
                                      );
                                    } else if (!_update &&
                                        (Get.find<SplashController>()
                                                .getStoreModuleConfig()
                                                .newVariation!
                                            ? false
                                            : storeController
                                                  .rawImages
                                                  .isEmpty)) {
                                      showCustomSnackBar(
                                        'upload_item_image'.tr,
                                      );
                                    } else if (checkDiscountWithVariationPrice) {
                                      showCustomSnackBar(
                                        'discount_cant_be_more_then_minimum_variation_price'
                                            .tr,
                                      );
                                    } else {
                                      String randomMetaTitle =
                                          'Meta Title ${Random().nextInt(100)}';
                                      String randomMetaDescription =
                                          'Meta Description ${Random().nextInt(100)}';
                                      MetaSeoData metaSeoData = MetaSeoData(
                                        metaIndex: 'index',
                                        metaNoFollow: '0',
                                        metaNoImageIndex: '0',
                                        metaNoArchive: '0',
                                        metaNoSnippet: '0',
                                        metaMaxSnippet: '0',
                                        metaMaxVideoPreview: '0',
                                        metaMaxImagePreview: '0',
                                        metaMaxSnippetValue: '0',
                                        metaMaxVideoPreviewValue: '0',
                                        metaMaxImagePreviewValue: 'large',
                                      );
                                      _item.metaData = metaSeoData;
                                      _item.metaTitle = randomMetaTitle;
                                      _item.metaDescription =
                                          randomMetaDescription;
                                      _item.veg = storeController.isVeg ? 1 : 0;
                                      _item.isPrescriptionRequired =
                                          storeController.isPrescriptionRequired
                                          ? 1
                                          : 0;
                                      _item.isHalal = storeController.isHalal
                                          ? 1
                                          : 0;
                                      _item.isBasicMedicine =
                                          storeController.isBasicMedicine
                                          ? 1
                                          : 0;
                                      _item.price = double.parse(price);
                                      _item.discount = double.parse(discount);
                                      _item.discountType =
                                          storeController.discountTypeIndex == 0
                                          ? 'percent'
                                          : 'amount';
                                      _item.availableTimeStarts =
                                          storeController.availableTimeStarts;
                                      _item.availableTimeEnds =
                                          storeController.availableTimeEnds;
                                      _item.categoryIds = [];
                                      _item.maxOrderQuantity = maxOrderQuantity;
                                      _item.barcode = _barcodeController.text
                                          .trim();
                                      _item.categoryIds!.add(
                                        CategoryIds(
                                          id: categoryController
                                              .selectedCategoryID,
                                        ),
                                      );
                                      if (categoryController
                                              .selectedSubCategoryID !=
                                          null) {
                                        _item.categoryIds!.add(
                                          CategoryIds(
                                            id: categoryController
                                                .selectedSubCategoryID,
                                          ),
                                        );
                                      } else {
                                        if (_item.categoryIds!.length > 1) {
                                          _item.categoryIds!.removeAt(1);
                                        }
                                      }
                                      _item.addOns = [];
                                      for (var index
                                          in storeController.selectedAddons!) {
                                        _item.addOns!.add(
                                          Get.find<AddonController>()
                                              .addonList![index],
                                        );
                                      }
                                      if (_module.unit! &&
                                          storeController.unitList != null &&
                                          storeController
                                              .unitList!
                                              .isNotEmpty) {
                                        _item.unitId = storeController
                                            .unitList![storeController
                                                .unitIndex!]
                                            .id;
                                        _item.unitType = storeController
                                            .unitList![storeController
                                                .unitIndex!]
                                            .unit;
                                      }
                                      if (_module.stock!) {
                                        _item.stock = 100;
                                      }
                                      if (Get.find<SplashController>()
                                              .configModel!
                                              .systemTaxType ==
                                          'product_wise') {
                                        _item.taxVatIds = [];
                                        _item.taxVatIds = storeController
                                            .selectedVatTaxIdList;
                                      }

                                      List<Translation> translations = [];
                                      for (
                                        int index = 0;
                                        index < _languageList!.length;
                                        index++
                                      ) {
                                        translations.add(
                                          Translation(
                                            locale: _languageList[index].key,
                                            key: 'name',
                                            value: _nameControllerList[0].text
                                                .trim(),
                                          ),
                                        );
                                        translations.add(
                                          Translation(
                                            locale: _languageList[index].key,
                                            key: 'description',
                                            value: _descriptionControllerList[0]
                                                .text
                                                .trim(),
                                          ),
                                        );
                                      }

                                      _item.translations = [];
                                      _item.translations!.addAll(translations);
                                      _item.name = _nameControllerList[0].text
                                          .trim();
                                      _item.description =
                                          _descriptionControllerList[0].text
                                              .trim();

                                      _item.brandId =
                                          storeController.brandList != null &&
                                              storeController
                                                  .brandList!
                                                  .isNotEmpty
                                          ? storeController
                                                .brandList![storeController
                                                    .brandIndex!]
                                                .id
                                          : 0;
                                      _item.conditionId =
                                          storeController.suitableTagList !=
                                                  null &&
                                              storeController
                                                  .suitableTagList!
                                                  .isNotEmpty
                                          ? storeController
                                                .suitableTagList![storeController
                                                    .suitableTagIndex!]
                                                .id
                                          : 0;
                                      bool hasEmptyValue = false;
                                      if (Get.find<SplashController>()
                                          .getStoreModuleConfig()
                                          .newVariation!) {
                                        _item.foodVariations = [];
                                        for (VariationModelBodyModel variation
                                            in storeController.variationList!) {
                                          if (variation.nameController!.text
                                              .trim()
                                              .isEmpty) {
                                            hasEmptyValue = true;
                                            break;
                                          }
                                          List<VariationValue> values = [];
                                          for (Option option
                                              in variation.options!) {
                                            if (option
                                                    .optionNameController!
                                                    .text
                                                    .trim()
                                                    .isEmpty ||
                                                option
                                                    .optionPriceController!
                                                    .text
                                                    .trim()
                                                    .isEmpty) {
                                              hasEmptyValue = true;
                                              break;
                                            }
                                            values.add(
                                              VariationValue(
                                                level: option
                                                    .optionNameController!
                                                    .text
                                                    .trim(),
                                                optionPrice: option
                                                    .optionPriceController!
                                                    .text
                                                    .trim(),
                                              ),
                                            );
                                          }
                                          if (hasEmptyValue) {
                                            break;
                                          }
                                          _item.foodVariations!.add(
                                            FoodVariation(
                                              name: variation
                                                  .nameController!
                                                  .text
                                                  .trim(),
                                              type: variation.isSingle
                                                  ? 'single'
                                                  : 'multi',
                                              min: variation.minController!.text
                                                  .trim(),
                                              max: variation.maxController!.text
                                                  .trim(),
                                              required: variation.required
                                                  ? 'on'
                                                  : 'off',
                                              variationValues: values,
                                            ),
                                          );
                                        }
                                      }
                                      if (hasEmptyValue) {
                                        showCustomSnackBar(
                                          'set_value_for_all_variation'.tr,
                                        );
                                      } else {
                                        if (storeController.rawLogo == null &&
                                            storeController
                                                .rawImages
                                                .isNotEmpty) {
                                          storeController.setRawLogo(
                                            storeController.rawImages[0],
                                          );
                                        }
                                        storeController.addItem(
                                          _item,
                                          widget.item == null,
                                          genericNameData:
                                              _genericNameSuggestionController
                                                  .text
                                                  .trim(),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          )
                        : const Center(child: CircularProgressIndicator());
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
