import 'package:shoplancer_vendor/api/api_checker.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/category/domain/models/category_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/features/category/domain/services/category_service_interface.dart';

class CategoryController extends GetxController implements GetxService {
  final CategoryServiceInterface categoryServiceInterface;
  CategoryController({required this.categoryServiceInterface});

  List<CategoryModel>? _categoryList;
  List<CategoryModel>? get categoryList => _categoryList;

  List<CategoryModel>? _subCategoryList;
  List<CategoryModel>? get subCategoryList => _subCategoryList;

  String? _selectedCategoryID;
  String? get selectedCategoryID => _selectedCategoryID;

  String? _selectedSubCategoryID;
  String? get selectedSubCategoryID => _selectedSubCategoryID;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _pageSize;
  int? get pageSize => _pageSize;

  List<String> _offsetList = [];

  int _offset = 1;
  int get offset => _offset;

  List<Item>? _itemList;
  List<Item>? get itemList => _itemList;

  int? _selectedSubCategoryId;
  int? get selectedSubCategoryId => _selectedSubCategoryId;

  int? _isSubCategory = 0;
  int? get isSubCategory => _isSubCategory;

  int? _selectedSubCategoryIndex = 0;
  int? get selectedSubCategoryIndex => _selectedSubCategoryIndex;

  Future<void> getCategoryList() async {
    _categoryList = null;
    List<CategoryModel>? categoryList = await categoryServiceInterface.getCategoryList();
    if(categoryList != null) {
      _categoryList = [];
      _categoryList = categoryList;
    }
    update();
  }

  Future<bool> toggleCategoryStatus(int categoryId, bool isNextActive) async {
    return await updateCategoryStatus(categoryId, isNextActive ? 1 : 0);
  }

  Future<bool> updateCategoryStatus(int categoryId, int status) async {
    _isLoading = true;
    update();
    Response response = await categoryServiceInterface.updateCategoryStatus(categoryId, status);
    _isLoading = false;
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (_categoryList != null) {
        int index = _categoryList!.indexWhere((element) => element.id == categoryId);
        if (index != -1) {
          _categoryList![index].status = status;
        }
      }
      if (_subCategoryList != null) {
        int subIndex = _subCategoryList!.indexWhere((element) => element.id == categoryId);
        if (subIndex != -1) {
          _subCategoryList![subIndex].status = status;
        }
      }
      String message = response.body != null && response.body['message'] != null
          ? response.body['message']
          : (status == 1 ? 'تم تفعيل الفئة بنجاح' : 'تم إيقاف الفئة بنجاح');

      if (response.body != null &&
          response.body['data'] != null &&
          response.body['data']['affected_products_count'] != null) {
        final count = response.body['data']['affected_products_count'];
        message = '$message ($count منتج)';
      }

      showCustomSnackBar(message, isError: false);
      update();
      return true;
    } else {
      ApiChecker.checkApi(response);
      update();
      return false;
    }
  }

  Future<bool> requestCategoryAddition({int? categoryId, String? customCategoryName, String? note}) async {
    _isLoading = true;
    update();
    try {
      Response response = await categoryServiceInterface.requestCategoryAddition(
        categoryId: categoryId,
        customCategoryName: customCategoryName,
        note: note,
      );
      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh vendor categories because the category is actually added
        getCategoryList();

        String message = 'تم إضافة الفئة بنجاح';
        try {
          if (response.body is Map && response.body['message'] != null) {
            message = response.body['message'].toString();
          }
          if (response.body is Map &&
              response.body['data'] is Map &&
              response.body['data']['products_submitted'] != null) {
            final count = response.body['data']['products_submitted'];
            message = '$message ($count منتج بانتظار الموافقة)';
          }
        } catch (_) {
          // keep default message on parse error
        }

        showCustomSnackBar(message, isError: false);
        update();
        return true;
      } else {
        ApiChecker.checkApi(response);
        update();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      showCustomSnackBar('حدث خطأ غير متوقع، يرجى المحاولة مجدداً', isError: true);
      update();
      return false;
    }
  }

  Future<void> getSubCategoryList(int categoryID) async {
    List<CategoryModel>? subCategoryList = await categoryServiceInterface.getSubCategoryList(categoryID);
    if(subCategoryList != null){
      _subCategoryList = [];
      _subCategoryList = subCategoryList;
    }
    update();
  }

  Future<void> initCategoryData(Item? item) async {
    await getCategoryList();
    if (item != null && item.categoryIds?.isNotEmpty == true) {
      final mainId = item.categoryIds![0].id;
      if (mainId != null) {
        setSelectedCategory(mainId, isUpdate: false);

        if (item.categoryIds!.length > 1) {
          final subId = item.categoryIds![1].id;
          if (subId != null) {
            await getSubCategoryList(int.parse(mainId));
            setSelectedSubCategory(subId, isUpdate: false);
          }
        }
      }
    }
    update();
  }

  void setSelectedCategory(String id, {bool isUpdate = true}) {
    _selectedCategoryID = id;
    getSubCategoryList(int.parse(id));
    if (isUpdate) update();
  }

  void setSelectedSubCategory(String id, {bool isUpdate = true}) {
    _selectedSubCategoryID = id;
    if (isUpdate) update();
  }

  void setSelectedSubCategoryIndex(int? index, bool notify) {
    _selectedSubCategoryIndex = index;
    if (notify) {
      update();
    }
  }

  void setSelectedSubCategoryId(int? subCategoryId) {
    _selectedSubCategoryId = subCategoryId;
    _isSubCategory = 1;
    if( _selectedSubCategoryId != null) {
      getCategoryItemList(offset: '1', id: _selectedSubCategoryId!);
    }
    update();
  }

  void clearSelectedSubCategoryId() {
    _selectedSubCategoryId = null;
    _isSubCategory = 0;
  }

  Future<void> getCategoryItemList({required String offset, required int id, bool willUpdate = true}) async {
    if(offset == '1') {
      _offsetList = [];
      _offset = 1;
      _itemList = null;
      if(willUpdate) {
        update();
      }
    }
    if (!_offsetList.contains(offset)) {
      _offsetList.add(offset);
      ItemModel? itemModel = await categoryServiceInterface.getCategoryItemList(offset: offset, id: id, isSubCategory: _isSubCategory!);
      if (itemModel != null) {
        if (offset == '1') {
          _itemList = [];
        }
        _itemList!.addAll(itemModel.items!);
        _pageSize = itemModel.totalSize;
        _isLoading = false;
        update();
      }
    } else {
      if(isLoading) {
        _isLoading = false;
        update();
      }
    }
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

  void setOffset(int offset) {
    _offset = offset;
  }

  Future<void> setCategoryAndSubCategoryForAiData({String? categoryId, String? subCategoryId}) async {
    if(categoryId != null){
      _selectedCategoryID = categoryId;
      await getSubCategoryList(int.parse(categoryId)).then((value) {
        if(_subCategoryList != null && _subCategoryList!.isNotEmpty){
          if(subCategoryId != null && _subCategoryList!.any((element) => element.id == int.parse(subCategoryId))){
            _selectedSubCategoryID = subCategoryId;
          }
          update();
        }
      });
    }
    update();
  }

}
