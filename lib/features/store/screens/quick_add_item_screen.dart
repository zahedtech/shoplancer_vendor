import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/common/widgets/label_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_drop_down_button.dart.dart';
import 'package:shoplancer_vendor/features/category/controllers/category_controller.dart';
import 'package:shoplancer_vendor/features/category/domain/models/category_model.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';
import 'package:shoplancer_vendor/features/splash/controllers/splash_controller.dart';
import 'package:shoplancer_vendor/features/store/controllers/store_controller.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

/// Single product fast entry screen connected directly to the API.
class QuickAddItemScreen extends StatefulWidget {
  const QuickAddItemScreen({super.key});

  @override
  State<QuickAddItemScreen> createState() => _QuickAddItemScreenState();
}

class _QuickAddItemScreenState extends State<QuickAddItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  MobileScannerController? _scannerController;

  int? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedSubCategoryId;
  String? _selectedSubCategoryName;
  XFile? _pickedImage;
  bool _showNumpad = false;
  bool _showScanner = false;
  bool _isSubmitting = false;
  String _activeField = 'price'; // 'price' or 'stock'

  bool get _isEcommerce {
    final store = Get.find<ProfileController>().profileModel?.stores?[0];
    return store?.module?.moduleType == 'ecommerce';
  }

  bool get _isUnitRequired =>
      Get.find<SplashController>().configModel?.moduleConfig?.module?.unit ??
      false;

  bool get _isProductWiseTax =>
      Get.find<SplashController>().configModel?.systemTaxType == 'product_wise';

  @override
  void initState() {
    super.initState();
    final storeController = Get.find<StoreController>();
    final categoryController = Get.find<CategoryController>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await categoryController.getCategoryList();
      storeController.getAttributeList(null);
      if (_isUnitRequired) {
        await storeController.getUnitList(null);
      }
      if (_isEcommerce) {
        await storeController.getBrandList('1', null);
      }
      if (_isProductWiseTax) {
        await storeController.getVatTaxList();
        final list = storeController.vatTaxList;
        if (list != null && list.isNotEmpty) {
          storeController.setSelectedVatTax(
            list.first.name,
            list.first.id,
            list.first.taxRate,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  void _onNumpadPress(String value) {
    final TextEditingController targetController =
        _activeField == 'price' ? _priceController : _stockController;
    String text = targetController.text;

    if (value == '.') {
      if (_activeField == 'stock') return; // Stock is integer only
      if (!text.contains('.')) {
        text = text.isEmpty ? '0.' : '$text.';
      }
    } else {
      text = (text == '0' || text.isEmpty) ? value : text + value;
    }

    setState(() => targetController.text = text);
  }

  void _onNumpadBackspace() {
    final TextEditingController targetController =
        _activeField == 'price' ? _priceController : _stockController;
    final String text = targetController.text;

    if (text.isNotEmpty) {
      setState(
        () => targetController.text = text.substring(0, text.length - 1),
      );
    }
  }

  Future<void> _submitProduct() async {
    final String name = _nameController.text.trim();
    final double? price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty) {
      showCustomSnackBar('ادخل اسم المنتج أولاً');
      return;
    }
    if (_selectedCategoryId == null) {
      showCustomSnackBar('اختر فئة المنتج');
      return;
    }
    if (price == null || price <= 0) {
      showCustomSnackBar('ادخل سعر صحيح للمنتج');
      return;
    }

    final int stock = int.tryParse(_stockController.text.trim()) ??
        (_stockController.text.trim().isEmpty ? 100 : 0);

    final storeController = Get.find<StoreController>();
    setState(() => _isSubmitting = true);

    storeController.setTag('', isUpdate: false, isClear: true);
    storeController.setRawLogo(_pickedImage);

    final Item item = Item(imagesFullUrl: []);
    item.name = name;
    item.description = '';
    item.price = price;
    item.discount = 0;
    item.discountType = 'amount';
    item.maxOrderQuantity = 0;
    item.addOns = [];
    item.stock = stock;
    item.veg = 0;
    item.isHalal = 0;
    item.isBasicMedicine = 0;
    item.isPrescriptionRequired = 0;
    item.barcode = _barcodeController.text.trim().isEmpty
        ? null
        : _barcodeController.text.trim();
    item.categoryIds = [CategoryIds(id: _selectedCategoryId.toString())];
    if (_selectedSubCategoryId != null) {
      item.categoryIds!.add(CategoryIds(id: _selectedSubCategoryId.toString()));
    }

    if (_isEcommerce) {
      item.brandId = (storeController.brandList != null &&
              storeController.brandList!.isNotEmpty)
          ? storeController.brandList![storeController.brandIndex ?? 0].id
          : 0;
      item.tax = 0;
    }
    if (_isProductWiseTax) {
      item.taxVatIds = storeController.selectedVatTaxIdList;
    }

    final bool isSuccess = await storeController.addItem(
      item,
      true,
      willRedirect: false,
    );

    storeController.setRawLogo(null);
    setState(() => _isSubmitting = false);

    if (isSuccess) {
      showCustomSnackBar('تم إضافة المنتج بنجاح', isError: false);
      storeController.getItemList(
        offset: '1',
        type: storeController.type,
        search: '',
        categoryId: storeController.categoryId ?? 0,
        willUpdate: false,
      );
      Get.back();
    } else {
      showCustomSnackBar('فشلت إضافة المنتج، يرجى المحاولة مرة أخرى', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        return GetBuilder<StoreController>(
          builder: (storeController) {
            final List<CategoryModel>? categories =
                categoryController.categoryList;

            return Scaffold(
              appBar: const CustomAppBarWidget(
                title: 'إضافة منتج',
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Container(
                  padding: const EdgeInsets.all(
                    Dimensions.paddingSizeDefault,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusDefault,
                    ),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).disabledColor.withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image and name row
                      Row(
                        children: [
                          _buildImagePicker(context),
                          const SizedBox(
                            width: Dimensions.paddingSizeDefault,
                          ),
                          Expanded(
                            child: CustomTextFieldWidget(
                              hintText: 'اسم المنتج',
                              labelText: 'اسم المنتج',
                              controller: _nameController,
                              showTitle: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Barcode field with scanner camera toggle
                      CustomTextFieldWidget(
                        hintText: 'الباركود (اختياري)',
                        labelText: 'الباركود',
                        controller: _barcodeController,
                        inputType: TextInputType.text,
                        showTitle: false,
                        suffixChild: IconButton(
                          icon: Icon(
                            _showScanner
                                ? Icons.close
                                : Icons.camera_alt_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _showScanner = !_showScanner;
                              if (_showScanner) {
                                _scannerController =
                                    MobileScannerController();
                              } else {
                                _scannerController?.dispose();
                                _scannerController = null;
                              }
                            });
                          },
                        ),
                      ),
                      if (_showScanner && _scannerController != null) ...[
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: MobileScanner(
                              controller: _scannerController!,
                              onDetect: (capture) {
                                for (final barcode in capture.barcodes) {
                                  final raw = barcode.rawValue?.trim();
                                  if (raw != null && raw.isNotEmpty) {
                                    setState(() {
                                      _barcodeController.text = raw;
                                      _showScanner = false;
                                      _scannerController?.dispose();
                                      _scannerController = null;
                                    });
                                    break;
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Main category selector
                      LabelWidget(
                        labelText: 'الفئة',
                        child: CustomDropdownButton(
                          hintText: 'اختر الفئة',
                          dropdownMenuItems: categories
                              ?.map(
                                (c) => DropdownMenuItem<String>(
                                  value: c.id.toString(),
                                  child: Text(
                                    c.name ?? '',
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          selectedValue: _selectedCategoryId?.toString(),
                          onChanged: (String? value) {
                            if (value == null) return;
                            final CategoryModel? match = categories
                                ?.firstWhereOrNull(
                                  (c) => c.id.toString() == value,
                                );
                            setState(() {
                              _selectedCategoryId = int.tryParse(value);
                              _selectedCategoryName = match?.name;
                              _selectedSubCategoryId = null;
                              _selectedSubCategoryName = null;
                            });
                            categoryController.getSubCategoryList(
                              int.parse(value),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Sub category selector
                      LabelWidget(
                        labelText: 'الفئة الفرعية',
                        child: CustomDropdownButton(
                          hintText: 'اختر الفئة الفرعية',
                          dropdownMenuItems:
                              categoryController.subCategoryList != null &&
                                  categoryController
                                      .subCategoryList!
                                      .isNotEmpty
                              ? categoryController.subCategoryList!
                                    .map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c.id.toString(),
                                        child: Text(
                                          c.name ?? '',
                                          style: robotoRegular.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeDefault,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList()
                              : [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text(
                                      'no_subcategory_found'.tr,
                                      style: robotoRegular.copyWith(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                          selectedValue: _selectedSubCategoryId?.toString(),
                          onChanged:
                              (categoryController.subCategoryList != null &&
                                  categoryController
                                      .subCategoryList!
                                      .isNotEmpty)
                              ? (String? value) {
                                  if (value == null) return;
                                  final CategoryModel? match =
                                      categoryController.subCategoryList
                                          ?.firstWhereOrNull(
                                            (c) => c.id.toString() == value,
                                          );
                                  setState(() {
                                    _selectedSubCategoryId = int.tryParse(
                                      value,
                                    );
                                    _selectedSubCategoryName = match?.name;
                                  });
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Price and Stock fields
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPriceField(context)),
                          const SizedBox(
                            width: Dimensions.paddingSizeDefault,
                          ),
                          Expanded(child: _buildStockField(context)),
                        ],
                      ),
                      if (_showNumpad) _buildNumpad(context),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      // Direct Submit API button
                      CustomButtonWidget(
                        buttonText: 'إضافة المنتج',
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submitProduct,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              border: Border.all(
                color: Theme.of(context).disabledColor.withOpacity(0.2),
              ),
            ),
            child: _pickedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: Image.file(
                      File(_pickedImage!.path),
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                    ),
                  )
                : Icon(
                    Icons.add_a_photo_outlined,
                    color: Theme.of(context).disabledColor,
                    size: 22,
                  ),
          ),
        ),
        if (_pickedImage != null)
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: () => setState(() => _pickedImage = null),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceField(BuildContext context) {
    final bool isActive = _showNumpad && _activeField == 'price';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'السعر',
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            setState(() {
              if (isActive) {
                _showNumpad = false;
              } else {
                _activeField = 'price';
                _showNumpad = true;
              }
            });
          },
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).primaryColor.withOpacity(0.06)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor.withOpacity(0.4),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Text(
              _priceController.text.isEmpty ? '0.00' : _priceController.text,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockField(BuildContext context) {
    final bool isActive = _showNumpad && _activeField == 'stock';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المخزون',
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            setState(() {
              if (isActive) {
                _showNumpad = false;
              } else {
                _activeField = 'stock';
                _showNumpad = true;
              }
            });
          },
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).primaryColor.withOpacity(0.06)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor.withOpacity(0.4),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Text(
              _stockController.text.isEmpty
                  ? '100 (افتراضي)'
                  : _stockController.text,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: _stockController.text.isEmpty
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumpad(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).disabledColor.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _numKey(context, '1'),
              _numKey(context, '2'),
              _numKey(context, '3'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _numKey(context, '4'),
              _numKey(context, '5'),
              _numKey(context, '6'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _numKey(context, '7'),
              _numKey(context, '8'),
              _numKey(context, '9'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _backspaceKey(context),
              _numKey(context, '.'),
              _numKey(context, '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numKey(BuildContext context, String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: () => _onNumpadPress(text),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.15),
              ),
            ),
            child: Text(
              text,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backspaceKey(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: _onNumpadBackspace,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: const Icon(
              Icons.backspace_outlined,
              color: Colors.red,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
