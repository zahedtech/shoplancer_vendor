import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/common/models/config_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/features/store/widgets/update_stock_bottom_sheet.dart';
import 'package:shoplancer_vendor/features/store/widgets/variation_view_widget.dart';
import 'package:shoplancer_vendor/helper/date_converter_helper.dart';
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';
import 'package:shoplancer_vendor/util/images.dart';
import 'package:shoplancer_vendor/common/widgets/confirmation_dialog_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/features/store/widgets/review_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item product;
  const ItemDetailsScreen({super.key, required this.product});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  Item item = Item();
  bool _hasDiscount = false;
  final TextEditingController _discountController = TextEditingController();
  int _discountTypeIndex = 0;
  bool _isDiscountLoading = false;

  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  List<TextEditingController> _variationStockControllers = [];
  List<TextEditingController> _variationPriceControllers = [];
  bool _isPriceLoading = false;
  bool _isStockLoading = false;

  void _initStockPriceControllers() {
    _stockController.text = (item.stock ?? 0).toString();
    _priceController.text = (item.price ?? 0.0).toString();
    _variationStockControllers = [];
    _variationPriceControllers = [];
    if (item.variations != null) {
      for (var variation in item.variations!) {
        _variationStockControllers.add(TextEditingController(text: (variation.stock ?? 0).toString()));
        _variationPriceControllers.add(TextEditingController(text: (variation.price ?? 0.0).toString()));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    item = widget.product;
    _hasDiscount = item.discount != null && item.discount! > 0;
    _discountController.text = (item.discount ?? 0).toString();
    _discountTypeIndex = item.discountType == 'percent' ? 0 : 1;
    _initStockPriceControllers();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    for (var c in _variationStockControllers) {
      c.dispose();
    }
    for (var c in _variationPriceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateDiscount(
    StoreController storeController,
    double discountValue,
    String discountType,
  ) {
    Map<String, String> data = {};
    data.addAll({"_method": 'post'});
    data.addAll({"id": item.id.toString()});
    data.addAll({"product_id": item.id.toString()});
    data.addAll({"current_stock": (item.stock ?? 0).toString()});
    data.addAll({"manage_stock": "1"});
    data.addAll({
      "store_id":
          Get.find<ProfileController>().profileModel?.stores?[0].id
              ?.toString() ??
          '',
    });
    data.addAll({"category_id": item.categoryId?.toString() ?? ''});
    data.addAll({"price": item.price.toString()});
    data.addAll({"unit_price": item.price.toString()});
    data.addAll({"discount": discountValue.toString()});
    data.addAll({"discount_type": discountType == 'flat' ? 'amount' : discountType});

    if (item.variations != null && item.variations!.isNotEmpty) {
      for (var variation in item.variations!) {
        int index = item.variations!.indexOf(variation);
        data.addAll({
          "price_${index}_${variation.type}": variation.price.toString(),
        });
        data.addAll({
          "stock_${index}_${variation.type}": variation.stock.toString(),
        });
      }
      List<String> types = [];
      for (var variation in item.variations!) {
        types.add(variation.type!);
      }
      data.addAll({"type": jsonEncode(types)});
    }

    setState(() {
      _isDiscountLoading = true;
    });

    storeController.stockUpdate(data, item.id!, shouldBack: false).then((
      isSuccess,
    ) async {
      if (isSuccess) {
        showCustomSnackBar('discount_updated_successfully'.tr, isError: false);
        Item? updatedItem = await storeController.getItemDetails(item.id!);
        if (updatedItem != null) {
          setState(() {
            item = updatedItem;
            _hasDiscount = item.discount != null && item.discount! > 0;
            _discountController.text = (item.discount ?? 0).toString();
            _discountTypeIndex = item.discountType == 'percent' ? 0 : 1;
            _initStockPriceControllers();
          });
        }
      }
      setState(() {
        _isDiscountLoading = false;
      });
    });
  }

  void _updateStockAndPrice(StoreController storeController, {required String updateType}) {
    if (updateType == 'stock') {
      if (_variationStockControllers.isNotEmpty) {
        if (_variationStockControllers.any((element) => element.text.trim().isEmpty || element.text.trim() == '0')) {
          showCustomSnackBar('stock_cannot_be_zero'.tr);
          return;
        }
      } else {
        if (_stockController.text.trim().isEmpty || _stockController.text.trim() == '0') {
          showCustomSnackBar('stock_cannot_be_zero'.tr);
          return;
        }
      }
    }

    if (updateType == 'price') {
      if (_variationPriceControllers.isNotEmpty) {
        if (_variationPriceControllers.any((element) => element.text.trim().isEmpty || double.tryParse(element.text.trim()) == null || double.parse(element.text.trim()) <= 0)) {
          showCustomSnackBar('price_cannot_be_zero_or_less'.tr);
          return;
        }
      } else {
        if (_priceController.text.trim().isEmpty || double.tryParse(_priceController.text.trim()) == null || double.parse(_priceController.text.trim()) <= 0) {
          showCustomSnackBar('price_cannot_be_zero_or_less'.tr);
          return;
        }
      }
    }

    Map<String, String> data = {};
    data.addAll({"_method": 'post'});
    data.addAll({"id": item.id.toString()});
    data.addAll({"product_id": item.id.toString()});
    
    if (_variationStockControllers.isNotEmpty) {
      int totalStock = 0;
      for (var c in _variationStockControllers) {
        totalStock += c.text.trim().isNotEmpty ? int.parse(c.text.trim()) : 0;
      }
      data.addAll({"current_stock": totalStock.toString()});
    } else {
      data.addAll({"current_stock": _stockController.text.trim()});
    }
    
    data.addAll({"manage_stock": "1"});
    data.addAll({
      "store_id":
          Get.find<ProfileController>().profileModel?.stores?[0].id
              ?.toString() ??
          '',
    });
    data.addAll({"category_id": item.categoryId?.toString() ?? ''});
    
    if (item.variations == null || item.variations!.isEmpty) {
      data.addAll({"price": _priceController.text.trim()});
      data.addAll({"unit_price": _priceController.text.trim()});
      data.addAll({"discount": item.discount?.toString() ?? '0'});
      data.addAll({"discount_type": item.discountType == 'flat' ? 'amount' : (item.discountType ?? 'amount')});
    } else {
      for (var variation in item.variations!) {
        int index = item.variations!.indexOf(variation);
        data.addAll({
          "price_${index}_${variation.type}": _variationPriceControllers[index].text.trim(),
        });
      }
    }
    
    List<String> types = [];
    if (item.variations != null && item.variations!.isNotEmpty) {
      for (var variation in item.variations!) {
        types.add(variation.type!);
        int index = item.variations!.indexOf(variation);
        data.addAll({
          "stock_${index}_${variation.type}": _variationStockControllers[index].text.trim(),
        });
      }
    }
    data.addAll({"type": jsonEncode(types)});

    setState(() {
      if (updateType == 'price') {
        _isPriceLoading = true;
      } else {
        _isStockLoading = true;
      }
    });

    storeController.stockUpdate(data, item.id!, shouldBack: false).then((isSuccess) async {
      if (isSuccess) {
        showCustomSnackBar(
          updateType == 'price' ? 'price_updated_successfully'.tr : 'stock_updated_successfully'.tr,
          isError: false,
        );
        Item? updatedItem = await storeController.getItemDetails(item.id!);
        if (updatedItem != null) {
          setState(() {
            item = updatedItem;
            _hasDiscount = item.discount != null && item.discount! > 0;
            _discountController.text = (item.discount ?? 0).toString();
            _discountTypeIndex = item.discountType == 'percent' ? 0 : 1;
            _initStockPriceControllers();
          });
        }
      }
      setState(() {
        if (updateType == 'price') {
          _isPriceLoading = false;
        } else {
          _isStockLoading = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    BoxShadow boxShadow = BoxShadow(
      color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
      blurRadius: 10,
    );
    double cardRadius = Dimensions.radiusDefault;
    bool isGrocery =
        Get.find<ProfileController>()
            .profileModel!
            .stores![0]
            .module!
            .moduleType ==
        'grocery';
    final isPharmacy =
        Get.find<ProfileController>()
            .profileModel!
            .stores![0]
            .module!
            .moduleType ==
        'pharmacy';
    final isFood = Get.find<SplashController>()
        .getStoreModuleConfig()
        .newVariation!;

    Get.find<StoreController>().setAvailability(item.status == 1);
    Get.find<StoreController>().setRecommended(item.recommendedStatus == 1);
    if (isGrocery) {
      Get.find<StoreController>().setOrganic(item.organicStatus == 1);
    }
    if (Get.find<ProfileController>()
        .profileModel!
        .stores![0]
        .reviewsSection!) {
      Get.find<StoreController>().getItemReviewList(item.id);
    }
    Module? module =
        Get.find<SplashController>().configModel!.moduleConfig!.module;

    return Scaffold(
      appBar: CustomAppBarWidget(title: 'item_details'.tr),

      body: SafeArea(
        child: GetBuilder<StoreController>(
          builder: (storeController) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(cardRadius),
                            color: Theme.of(context).cardColor,
                            boxShadow: [boxShadow],
                          ),
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeSmall,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => Get.toNamed(
                                      RouteHelper.getItemImagesRoute(item),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        cardRadius,
                                      ),
                                      child: CustomImageWidget(
                                        image: '${item.imageFullUrl}',
                                        height: 70,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: Dimensions.paddingSizeSmall,
                                  ),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name!,
                                          style: robotoMedium.copyWith(
                                            fontSize: Dimensions.fontSizeLarge,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.description != null && item.description!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description!,
                                            style: robotoRegular.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              color: Theme.of(context).disabledColor,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],

                                        module != null && module.stock != null
                                            ? Row(
                                                children: [
                                                  Text(
                                                    '${'total_stock'.tr}:',
                                                    style: robotoRegular,
                                                  ),
                                                  const SizedBox(
                                                    width: Dimensions
                                                        .paddingSizeExtraSmall,
                                                  ),

                                                  Text(
                                                    item.stock.toString(),
                                                    style: robotoMedium
                                                        .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeSmall,
                                                        ),
                                                  ),
                                                ],
                                              )
                                            : const SizedBox(),

                                        // SizedBox(height: module.stock! ? Dimensions.paddingSizeLarge : 0),
                                        Text(
                                          '${'price'.tr}: ${item.price}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: robotoRegular,
                                        ),

                                        Row(
                                          children: [
                                            if (item.discount != null && item.discount! > 0)
                                              Expanded(
                                                child: Text(
                                                  '${'discount'.tr}: ${item.discount} ${item.discountType == 'percent' ? '%' : Get.find<SplashController>().configModel!.currencySymbol}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: robotoRegular,
                                                ),
                                              )
                                            else
                                              const Expanded(child: SizedBox()),

                                            (module!.unit! ||
                                                    Get.find<SplashController>()
                                                        .configModel!
                                                        .toggleVegNonVeg!)
                                                ? Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: Dimensions
                                                              .paddingSizeExtraSmall,
                                                          horizontal: Dimensions
                                                              .paddingSizeSmall,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            cardRadius,
                                                          ),
                                                      color: Theme.of(context)
                                                          .primaryColor
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      module.unit!
                                                          ? item.unitType ?? ''
                                                          : item.veg == 0
                                                          ? 'non_veg'.tr
                                                          : 'veg'.tr,
                                                      style: robotoMedium.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeExtraSmall,
                                                        color: Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: Dimensions.paddingSizeSmall,
                              ),

                              module.itemAvailableTime!
                                  ? Row(
                                      children: [
                                        Text(
                                          'daily_time'.tr,
                                          style: robotoRegular.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).disabledColor,
                                          ),
                                        ),
                                        const SizedBox(
                                          width:
                                              Dimensions.paddingSizeExtraSmall,
                                        ),

                                        Expanded(
                                          child: Text(
                                            '${DateConverterHelper.convertStringTimeToTime(item.availableTimeStarts!)}'
                                            ' - ${DateConverterHelper.convertStringTimeToTime(item.availableTimeEnds!)}',
                                            maxLines: 1,
                                            style: robotoMedium.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        if (!isFood) ...[
                          // SECTION 1: UPDATE PRICE
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(cardRadius),
                              color: Theme.of(context).cardColor,
                              boxShadow: [boxShadow],
                            ),
                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'update_price'.tr,
                                  style: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                  ),
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                if (_variationPriceControllers.isEmpty) ...[
                                  CustomTextFieldWidget(
                                    hintText: 'enter_price'.tr,
                                    labelText: 'price'.tr,
                                    controller: _priceController,
                                    inputType: TextInputType.number,
                                    isAmount: true,
                                  ),
                                ] else ...[
                                  ListView.builder(
                                    itemCount: _variationPriceControllers.length,
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                item.variations![index].type ?? '',
                                                style: robotoRegular,
                                              ),
                                            ),
                                            const SizedBox(width: Dimensions.paddingSizeSmall),
                                            Expanded(
                                              flex: 5,
                                              child: CustomTextFieldWidget(
                                                hintText: 'enter_price'.tr,
                                                labelText: 'price'.tr,
                                                controller: _variationPriceControllers[index],
                                                inputType: TextInputType.number,
                                                isAmount: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                const SizedBox(height: Dimensions.paddingSizeDefault),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _isPriceLoading
                                        ? const SizedBox(
                                            height: 35,
                                            width: 35,
                                            child: CircularProgressIndicator(),
                                          )
                                        : CustomButtonWidget(
                                            width: 100,
                                            height: 35,
                                            buttonText: 'update'.tr,
                                            onPressed: () {
                                              Get.dialog(
                                                ConfirmationDialogWidget(
                                                  icon: Images.warning,
                                                  description: 'are_you_sure_to_update_price'.tr,
                                                  onYesPressed: () {
                                                    Get.back();
                                                    _updateStockAndPrice(storeController, updateType: 'price');
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),

                          // SECTION 2: UPDATE STOCK
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(cardRadius),
                              color: Theme.of(context).cardColor,
                              boxShadow: [boxShadow],
                            ),
                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'update_stock'.tr,
                                  style: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                  ),
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                if (_variationStockControllers.isEmpty) ...[
                                  CustomTextFieldWidget(
                                    hintText: 'enter_stock'.tr,
                                    labelText: 'total_quantity'.tr,
                                    controller: _stockController,
                                    inputType: TextInputType.number,
                                    isNumber: true,
                                  ),
                                ] else ...[
                                  ListView.builder(
                                    itemCount: _variationStockControllers.length,
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                item.variations![index].type ?? '',
                                                style: robotoRegular,
                                              ),
                                            ),
                                            const SizedBox(width: Dimensions.paddingSizeSmall),
                                            Expanded(
                                              flex: 5,
                                              child: CustomTextFieldWidget(
                                                hintText: 'enter_stock'.tr,
                                                labelText: 'stock'.tr,
                                                controller: _variationStockControllers[index],
                                                inputType: TextInputType.number,
                                                isNumber: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                const SizedBox(height: Dimensions.paddingSizeDefault),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _isStockLoading
                                        ? const SizedBox(
                                            height: 35,
                                            width: 35,
                                            child: CircularProgressIndicator(),
                                          )
                                        : CustomButtonWidget(
                                            width: 100,
                                            height: 35,
                                            buttonText: 'update'.tr,
                                            onPressed: () {
                                              Get.dialog(
                                                ConfirmationDialogWidget(
                                                  icon: Images.warning,
                                                  description: 'are_you_sure_to_update_stock'.tr,
                                                  onYesPressed: () {
                                                    Get.back();
                                                    _updateStockAndPrice(storeController, updateType: 'stock');
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                        ],

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(cardRadius),
                            color: Theme.of(context).cardColor,
                            boxShadow: [boxShadow],
                          ),
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeSmall,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الأكثر مبيعاً',
                                      style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'تحديد وتفعيل ظهور هذا المنتج في قائمة الأكثر مبيعاً',
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeExtraSmall,
                                        color: Theme.of(context).disabledColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              storeController.loadingRecommendedList.contains(
                                    item.id,
                                  )
                                  ? const SizedBox(
                                      width: 60,
                                      height: 30,
                                      child: Center(
                                        child: CupertinoActivityIndicator(),
                                      ),
                                    )
                                  : FlutterSwitch(
                                      width: 60,
                                      height: 30,
                                      valueFontSize:
                                          Dimensions.fontSizeExtraSmall,
                                      showOnOff: true,
                                      activeColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      value: storeController.isRecommended,
                                      onToggle: (bool isActive) {
                                        storeController
                                            .toggleRecommendedProduct(item.id);
                                      },
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(cardRadius),
                            color: Theme.of(context).cardColor,
                            boxShadow: [boxShadow],
                          ),
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeSmall,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'discount'.tr,
                                      style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                      ),
                                    ),
                                  ),

                                  _isDiscountLoading
                                      ? const SizedBox(
                                          width: 60,
                                          height: 30,
                                          child: Center(
                                            child: CupertinoActivityIndicator(),
                                          ),
                                        )
                                      : FlutterSwitch(
                                          width: 60,
                                          height: 30,
                                          valueFontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          showOnOff: true,
                                          activeColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          value: _hasDiscount,
                                          onToggle: (bool isActive) {
                                            if (_isDiscountLoading) return;
                                            setState(() {
                                              _hasDiscount = isActive;
                                              if (!_hasDiscount) {
                                                _updateDiscount(
                                                  storeController,
                                                  0,
                                                  'amount',
                                                );
                                              }
                                            });
                                          },
                                        ),
                                ],
                              ),

                              if (_hasDiscount) ...[
                                const SizedBox(
                                  height: Dimensions.paddingSizeDefault,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: CustomTextFieldWidget(
                                        hintText: 'discount'.tr,
                                        labelText: 'discount'.tr,
                                        controller: _discountController,
                                        inputType: TextInputType.number,
                                        isAmount: _discountTypeIndex == 1,
                                        isNumber: _discountTypeIndex == 0,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: Dimensions.paddingSizeSmall,
                                    ),

                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        height: 50,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.paddingSizeSmall,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(
                                            Dimensions.radiusDefault,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .disabledColor
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            value: _discountTypeIndex,
                                            items: [
                                              DropdownMenuItem<int>(
                                                value: 0,
                                                child: Text('percent'.tr),
                                              ),
                                              DropdownMenuItem<int>(
                                                value: 1,
                                                child: Text('amount'.tr),
                                              ),
                                            ],
                                            onChanged: (int? index) {
                                              if (index != null) {
                                                setState(() {
                                                  _discountTypeIndex = index;
                                                });
                                              }
                                            },
                                            isExpanded: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: Dimensions.paddingSizeDefault,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CustomButtonWidget(
                                      width: 100,
                                      height: 35,
                                      buttonText: 'update'.tr,
                                      onPressed: () {
                                        double discount =
                                            double.tryParse(
                                              _discountController.text,
                                            ) ??
                                            0.0;
                                        if (discount <= 0) {
                                          showCustomSnackBar(
                                            'enter_item_discount'.tr,
                                          );
                                          return;
                                        }
                                        if (_discountTypeIndex == 0 &&
                                            discount > 100) {
                                          showCustomSnackBar(
                                            'discount_cannot_be_more_than_100'
                                                .tr,
                                          );
                                          return;
                                        }
                                        if (_discountTypeIndex == 1 &&
                                            discount > (item.price ?? 0.0)) {
                                          showCustomSnackBar(
                                            'discount_cannot_be_more_than_price'
                                                .tr,
                                          );
                                          return;
                                        }
                                        _updateDiscount(
                                          storeController,
                                          discount,
                                          _discountTypeIndex == 0
                                              ? 'percent'
                                              : 'amount',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        Get.find<SplashController>()
                                .getStoreModuleConfig()
                                .newVariation!
                            ? FoodVariationView(item: item)
                            : VariationView(item: item, stock: module.stock),

                        /*                (isFood || isGrocery) && item.nutrition!.isNotEmpty ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardRadius),
                    color: Theme.of(context).cardColor,
                    boxShadow: [boxShadow],
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    Text('nutrition'.tr, style: robotoMedium),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Text(
                      item.nutrition!.join(', '),
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),

                  ]),
                ) : const SizedBox(),*/

                        /*                (isFood || isGrocery) && item.allergies!.isNotEmpty ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardRadius),
                    color: Theme.of(context).cardColor,
                    boxShadow: [boxShadow],
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    Text('allergic_ingredients'.tr, style: robotoMedium),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Text(
                      item.allergies!.join(', '),
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),

                  ]),
                ) : const SizedBox(),*/

                        /*                isPharmacy && item.genericName!.isNotEmpty ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardRadius),
                    color: Theme.of(context).cardColor,
                    boxShadow: [boxShadow],
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    Text('generic_name'.tr, style: robotoMedium),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Text(item.genericName!.join(', '),
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),
                  ]),
                ) : const SizedBox(),*/
                        (item.addOns!.isNotEmpty && module.addOn!)
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    cardRadius,
                                  ),
                                  color: Theme.of(context).cardColor,
                                  boxShadow: [boxShadow],
                                ),
                                width: double.infinity,
                                padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('addons'.tr, style: robotoMedium),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeExtraSmall,
                                    ),

                                    ListView.builder(
                                      itemCount: item.addOns!.length,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) {
                                        return Row(
                                          children: [
                                            Text(
                                              '${item.addOns![index].name!}:',
                                              style: robotoRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: Dimensions
                                                  .paddingSizeExtraSmall,
                                            ),
                                            Text(
                                              PriceConverterHelper.convertPrice(
                                                item.addOns![index].price,
                                              ),
                                              style: robotoMedium.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(),
                        SizedBox(
                          height: item.addOns!.isNotEmpty
                              ? Dimensions.paddingSizeDefault
                              : 0,
                        ),



                        (item.taxData != null && item.taxData!.isNotEmpty)
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    cardRadius,
                                  ),
                                  color: Theme.of(context).cardColor,
                                  boxShadow: [boxShadow],
                                ),
                                width: double.infinity,
                                padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('vat_tax'.tr, style: robotoMedium),
                                    const SizedBox(
                                      height: Dimensions.paddingSizeExtraSmall,
                                    ),

                                    ListView.builder(
                                      itemCount: item.taxData!.length,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) {
                                        return Row(
                                          children: [
                                            Text(
                                              '${item.taxData?[index].name}:',
                                              style: robotoRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: Dimensions
                                                  .paddingSizeExtraSmall,
                                            ),

                                            Text(
                                              '(${item.taxData![index].taxRate} %)',
                                              style: robotoMedium.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(),
                        SizedBox(
                          height:
                              item.taxData != null && item.taxData!.isNotEmpty
                              ? Dimensions.paddingSizeDefault
                              : 0,
                        ),

                        // Get.find<ProfileController>()
                        //         .profileModel!
                        //         .stores![0]
                        //         .reviewsSection!
                        //     ? Container(
                        //         decoration: BoxDecoration(
                        //           borderRadius: BorderRadius.circular(
                        //             cardRadius,
                        //           ),
                        //           color: Theme.of(context).cardColor,
                        //           boxShadow: [boxShadow],
                        //         ),
                        //         child: Column(
                        //           crossAxisAlignment: CrossAxisAlignment.start,
                        //           children: [
                        //             Padding(
                        //               padding: const EdgeInsets.all(
                        //                 Dimensions.paddingSizeSmall,
                        //               ),
                        //               child: Text(
                        //                 'reviews'.tr,
                        //                 style: robotoMedium,
                        //               ),
                        //             ),
                        //             const SizedBox(
                        //               height: Dimensions.paddingSizeSmall,
                        //             ),

                        //             storeController.itemReviewList != null
                        //                 ? storeController
                        //                           .itemReviewList!
                        //                           .isNotEmpty
                        //                       ? SizedBox(
                        //                           height: 150,
                        //                           child: ListView.builder(
                        //                             itemCount: storeController
                        //                                 .itemReviewList!
                        //                                 .length,
                        //                             scrollDirection:
                        //                                 Axis.horizontal,
                        //                             padding: const EdgeInsets.only(
                        //                               left: Dimensions
                        //                                   .paddingSizeDefault,
                        //                               bottom: Dimensions
                        //                                   .paddingSizeDefault,
                        //                               top: Dimensions
                        //                                   .paddingSizeSmall,
                        //                             ),
                        //                             itemBuilder: (context, index) {
                        //                               return ReviewWidget(
                        //                                 review: storeController
                        //                                     .itemReviewList![index],
                        //                                 fromStore: false,
                        //                                 hasDivider:
                        //                                     index !=
                        //                                     storeController
                        //                                             .itemReviewList!
                        //                                             .length -
                        //                                         1,
                        //                               );
                        //                             },
                        //                           ),
                        //                         )
                        //                       : Padding(
                        //                           padding: const EdgeInsets.only(
                        //                             top: Dimensions
                        //                                 .paddingSizeSmall,
                        //                             bottom: Dimensions
                        //                                 .paddingSizeExtremeLarge,
                        //                           ),
                        //                           child: Center(
                        //                             child: Text(
                        //                               'no_review_found'.tr,
                        //                               style: robotoRegular
                        //                                   .copyWith(
                        //                                     color: Theme.of(
                        //                                       context,
                        //                                     ).disabledColor,
                        //                                   ),
                        //                             ),
                        //                           ),
                        //                         )
                        //                 : const Padding(
                        //                     padding: EdgeInsets.only(
                        //                       top: Dimensions.paddingSizeSmall,
                        //                       bottom: Dimensions
                        //                           .paddingSizeExtremeLarge,
                        //                     ),
                        //                     child: Center(
                        //                       child:
                        //                           CircularProgressIndicator(),
                        //                     ),
                        //                   ),
                        //           ],
                        //         ),
                        //       )
                        //     : const SizedBox(),
                      ],
                    ),
                  ),
                ),

                !isGrocery
                    ? Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [boxShadow],
                        ),
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: CustomButtonWidget(
                          onPressed: () {
                            if (Get.find<ProfileController>()
                                .profileModel!
                                .stores![0]
                                .itemSection!) {
                              Get.toNamed(RouteHelper.getAddItemRoute(item));
                            } else {
                              showCustomSnackBar(
                                'this_feature_is_blocked_by_admin'.tr,
                              );
                            }
                          },
                          radius: Dimensions.radiusDefault,
                          buttonText: 'update_item'.tr,
                        ),
                      )
                    : const SizedBox(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FoodVariationView extends StatelessWidget {
  final Item item;
  const FoodVariationView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return (item.foodVariations != null && item.foodVariations!.isNotEmpty)
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            margin: const EdgeInsets.only(
              bottom: Dimensions.paddingSizeDefault,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('variations'.tr, style: robotoMedium),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                ListView.builder(
                  itemCount: item.foodVariations!.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeExtraSmall,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${item.foodVariations![index].name!} - ',
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                              Text(
                                ' ${item.foodVariations![index].type == 'multi' ? 'multiple_select'.tr : 'single_select'.tr}'
                                ' (${item.foodVariations![index].required == 'on' ? 'required'.tr : 'optional'.tr})',
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).disabledColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall,
                          ),

                          ListView.builder(
                            itemCount: item
                                .foodVariations![index]
                                .variationValues!
                                .length,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 20),
                            shrinkWrap: true,
                            itemBuilder: (context, i) {
                              return Text(
                                '${item.foodVariations![index].variationValues![i].level}'
                                ' - ${PriceConverterHelper.convertPrice(double.parse(item.foodVariations![index].variationValues![i].optionPrice!))}',
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        : const SizedBox();
  }
}
