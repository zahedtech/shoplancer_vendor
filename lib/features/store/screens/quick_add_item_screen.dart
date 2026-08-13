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
import 'package:shoplancer_vendor/helper/price_converter_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

enum _StagedStatus { pending, submitting, success, failed }

/// A product queued locally on this screen — nothing is sent to the server
/// until "حفظ الكل" is pressed.
class _StagedQuickItem {
  final String localId;
  String name;
  double price;
  int stock;
  int categoryId;
  String categoryName;
  int? subCategoryId;
  String? subCategoryName;
  String? barcode;
  XFile? imageFile;
  _StagedStatus status = _StagedStatus.pending;

  _StagedQuickItem({
    required this.localId,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    this.subCategoryId,
    this.subCategoryName,
    this.barcode,
    this.imageFile,
  });
}

/// Fast multi-product entry: fill a short form, tap "إضافة للقائمة" to queue
/// the product locally (no request, no page reload), repeat, then submit the
/// whole batch at once with "حفظ الكل". Complex products (variations,
/// attributes, multiple images...) should still use the full Add Product
/// screen — this one intentionally covers only the common/simple case.
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

  final List<_StagedQuickItem> _stagedItems = [];

  int? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedSubCategoryId;
  String? _selectedSubCategoryName;
  XFile? _pickedImage;
  bool _showNumpad = false;
  bool _showScanner = false;
  bool _isSubmittingAll = false;

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
      // Clears any leftover variation/attribute/image state from a previous
      // visit to the full Add Product screen so it can't leak into the
      // simple items created here.
      storeController.getAttributeList(null);
      if (_isUnitRequired) {
        await storeController.getUnitList(null);
      }
      if (_isEcommerce) {
        await storeController.getBrandList(null);
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
    String text = _priceController.text;
    if (value == '.') {
      if (!text.contains('.')) {
        text = text.isEmpty ? '0.' : '$text.';
      }
    } else {
      text = (text == '0' || text.isEmpty) ? value : text + value;
    }
    setState(() => _priceController.text = text);
  }

  void _onNumpadBackspace() {
    final String text = _priceController.text;
    if (text.isNotEmpty) {
      setState(
        () => _priceController.text = text.substring(0, text.length - 1),
      );
    }
  }

  void _addToStagedList() {
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

    // Stock defaults to 100 automatically when left empty.
    final int stock =
        int.tryParse(_stockController.text.trim()) ??
        (_stockController.text.trim().isEmpty ? 100 : 0);

    setState(() {
      _stagedItems.insert(
        0,
        _StagedQuickItem(
          localId: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          price: price,
          stock: stock,
          categoryId: _selectedCategoryId!,
          categoryName: _selectedCategoryName ?? '',
          subCategoryId: _selectedSubCategoryId,
          subCategoryName: _selectedSubCategoryName,
          barcode: _barcodeController.text.trim().isEmpty
              ? null
              : _barcodeController.text.trim(),
          imageFile: _pickedImage,
        ),
      );

      // Reset the quick-entry fields for the next product, but keep the
      // category selected — usually a run of products share the category.
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      _barcodeController.clear();
      _pickedImage = null;
      _showNumpad = false;
    });
  }

  void _removeStaged(String localId) {
    setState(() => _stagedItems.removeWhere((e) => e.localId == localId));
  }

  Item _buildSubmissionItem(
    _StagedQuickItem staged,
    StoreController storeController,
  ) {
    final Item item = Item(imagesFullUrl: []);
    item.name = staged.name;
    item.description = '';
    item.price = staged.price;
    item.discount = 0;
    item.discountType = 'amount';
    item.maxOrderQuantity = 0;
    item.addOns = [];
    item.stock = staged.stock;
    item.veg = 0;
    item.isHalal = 0;
    item.isBasicMedicine = 0;
    item.isPrescriptionRequired = 0;
    item.barcode = staged.barcode;
    item.categoryIds = [CategoryIds(id: staged.categoryId.toString())];
    if (staged.subCategoryId != null) {
      item.categoryIds!.add(CategoryIds(id: staged.subCategoryId.toString()));
    }

    if (_isEcommerce) {
      item.brandId =
          (storeController.brandList != null &&
              storeController.brandList!.isNotEmpty)
          ? storeController.brandList![storeController.brandIndex ?? 0].id
          : 0;
      item.tax = 0;
    }
    if (_isProductWiseTax) {
      item.taxVatIds = storeController.selectedVatTaxIdList;
    }
    return item;
  }

  Future<void> _submitAll() async {
    if (_stagedItems.isEmpty || _isSubmittingAll) return;
    final storeController = Get.find<StoreController>();

    setState(() => _isSubmittingAll = true);

    final List<_StagedQuickItem> toSubmit = _stagedItems
        .where((e) => e.status != _StagedStatus.success)
        .toList();
    int successCount = 0;

    for (final staged in toSubmit) {
      setState(() => staged.status = _StagedStatus.submitting);

      // Isolate every submission from anything staged before it.
      storeController.setTag('', isUpdate: false, isClear: true);
      storeController.setRawLogo(staged.imageFile);

      final Item item = _buildSubmissionItem(staged, storeController);
      final bool isSuccess = await storeController.addItem(
        item,
        true,
        willRedirect: false,
      );

      setState(() {
        staged.status = isSuccess
            ? _StagedStatus.success
            : _StagedStatus.failed;
      });
      if (isSuccess) successCount++;
    }

    storeController.setRawLogo(null);

    setState(() {
      _isSubmittingAll = false;
      _stagedItems.removeWhere((e) => e.status == _StagedStatus.success);
    });

    final int failedCount = _stagedItems.length;
    showCustomSnackBar(
      failedCount == 0
          ? 'تم رفع $successCount منتج بنجاح للمتجر'
          : 'تم رفع $successCount منتج، وفشل $failedCount — تقدر تعيد المحاولة من القائمة',
      isError: failedCount > 0,
    );

    // Reload the parent list (AllItemsScreen) with the active category filter,
    // so the user sees the updated products when they go back.
    if (successCount > 0) {
      storeController.getItemList(
        offset: '1',
        type: storeController.type,
        search: '',
        categoryId: storeController.categoryId ?? 0,
        willUpdate: false,
      );
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
              appBar: CustomAppBarWidget(
                title: 'إضافة منتجات سريعة',
                menuWidget: _stagedItems.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: TextButton.icon(
                          onPressed: _isSubmittingAll ? null : _submitAll,
                          icon: _isSubmittingAll
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                          label: Text(
                            'حفظ الكل (${_stagedItems.length})',
                            style: robotoBold.copyWith(color: Colors.white),
                          ),
                        ),
                      )
                    : null,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- Quick entry form ----------------
                    Container(
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
                          CustomTextFieldWidget(
                            hintText: 'الباركود',
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPriceField(context)),
                              const SizedBox(
                                width: Dimensions.paddingSizeDefault,
                              ),
                              Expanded(
                                child: CustomTextFieldWidget(
                                  hintText: '100 (افتراضي)',
                                  labelText: 'المخزون',
                                  controller: _stockController,
                                  inputType: TextInputType.number,
                                  isNumber: true,
                                  showTitle: false,
                                ),
                              ),
                            ],
                          ),
                          if (_showNumpad) _buildNumpad(context),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          CustomButtonWidget(
                            buttonText: 'إضافة للقائمة',
                            onPressed: _addToStagedList,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // ---------------- Staged list ----------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المنتجات المضافة للقائمة (${_stagedItems.length})',
                          style: robotoBold,
                        ),
                        if (_stagedItems.isNotEmpty && !_isSubmittingAll)
                          TextButton(
                            onPressed: () =>
                                setState(() => _stagedItems.clear()),
                            child: Text(
                              'تفريغ الكل',
                              style: robotoRegular.copyWith(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    if (_stagedItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeLarge,
                        ),
                        child: Center(
                          child: Text(
                            'لسا ما ضفت أي منتج للقائمة',
                            style: robotoRegular.copyWith(
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._stagedItems.map(
                        (staged) => _buildStagedRow(context, staged),
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

  Widget _buildImagePicker(BuildContext context) {
    return InkWell(
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
    );
  }

  Widget _buildPriceField(BuildContext context) {
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
          onTap: () => setState(() => _showNumpad = !_showNumpad),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _showNumpad
                  ? Theme.of(context).primaryColor.withOpacity(0.06)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              border: Border.all(
                color: _showNumpad
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor.withOpacity(0.4),
                width: _showNumpad ? 2 : 1,
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
              // Placed first so it renders on the right in the app's RTL
              // (Arabic) layout — same convention as the price editor.
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

  Widget _buildStagedRow(BuildContext context, _StagedQuickItem staged) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: staged.status == _StagedStatus.failed
              ? Colors.red
              : Theme.of(context).disabledColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: staged.imageFile != null
                ? Image.file(
                    File(staged.imageFile!.path),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Theme.of(context).disabledColor.withOpacity(0.08),
                    child: Icon(
                      Icons.image_outlined,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staged.name,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${staged.categoryName}${staged.subCategoryName != null && staged.subCategoryName!.isNotEmpty ? ' (${staged.subCategoryName})' : ''} • ${PriceConverterHelper.convertPrice(staged.price)} • مخزون ${staged.stock}${staged.barcode != null ? ' • ${staged.barcode}' : ''}',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context).disabledColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (staged.status == _StagedStatus.failed)
                  Text(
                    'فشلت الإضافة — حاول مرة ثانية',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          _buildStagedStatusIcon(context, staged),
        ],
      ),
    );
  }

  Widget _buildStagedStatusIcon(BuildContext context, _StagedQuickItem staged) {
    switch (staged.status) {
      case _StagedStatus.submitting:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _StagedStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case _StagedStatus.failed:
        return IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _removeStaged(staged.localId),
        );
      case _StagedStatus.pending:
        return IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).disabledColor,
          ),
          onPressed: _isSubmittingAll
              ? null
              : () => _removeStaged(staged.localId),
        );
    }
  }
}
