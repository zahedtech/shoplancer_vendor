import 'package:get/get_connect/http/src/response/response.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/interface/repository_interface.dart';

abstract class CategoryRepositoryInterface implements RepositoryInterface {
  Future<dynamic> getSubCategoryList(int? parentID);
  Future<ItemModel?> getCategoryItemList({required String offset, required int id, required int isSubCategory});
  Future<Response> requestCategoryAddition({int? categoryId, String? customCategoryName, String? note});
  Future<Response> updateCategoryStatus(int categoryId, int status);
}