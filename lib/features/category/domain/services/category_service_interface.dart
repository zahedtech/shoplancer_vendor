import 'package:get/get_connect/http/src/response/response.dart';
import 'package:shoplancer_vendor/features/category/domain/models/category_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';

abstract class CategoryServiceInterface {
  Future<List<CategoryModel>?> getCategoryList();
  Future<List<CategoryModel>?> getSubCategoryList(int? parentID);
  Future<ItemModel?> getCategoryItemList({required String offset, required int id, required int isSubCategory});
  Future<Response> requestCategoryAddition({int? categoryId, String? customCategoryName, String? note});
  Future<Response> updateCategoryStatus(int categoryId, int status);
}