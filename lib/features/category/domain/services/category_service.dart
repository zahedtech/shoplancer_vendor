import 'package:get/get_connect/http/src/response/response.dart';
import 'package:shoplancer_vendor/features/category/domain/models/category_model.dart';
import 'package:shoplancer_vendor/features/category/domain/repositories/category_repository_interface.dart';
import 'package:shoplancer_vendor/features/category/domain/services/category_service_interface.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';

class CategoryService implements CategoryServiceInterface {
  final CategoryRepositoryInterface categoryRepositoryInterface;
  CategoryService({required this.categoryRepositoryInterface});

  @override
  Future<List<CategoryModel>?> getCategoryList() async {
    return await categoryRepositoryInterface.getList();
  }

  @override
  Future<List<CategoryModel>?> getSubCategoryList(int? parentID) async {
    return await categoryRepositoryInterface.getSubCategoryList(parentID);
  }

  @override
  Future<ItemModel?> getCategoryItemList({required String offset, required int id, required int isSubCategory}) async {
    return await categoryRepositoryInterface.getCategoryItemList(offset: offset, id: id, isSubCategory: isSubCategory);
  }

  @override
  Future<Response> requestCategoryAddition({int? categoryId, String? customCategoryName, String? note}) async {
    return await categoryRepositoryInterface.requestCategoryAddition(
      categoryId: categoryId,
      customCategoryName: customCategoryName,
      note: note,
    );
  }

  @override
  Future<Response> updateCategoryStatus(int categoryId, int status) async {
    return await categoryRepositoryInterface.updateCategoryStatus(categoryId, status);
  }

}