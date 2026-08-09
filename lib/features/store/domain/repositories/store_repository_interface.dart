import 'package:get/get_connect/http/src/response/response.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/common/models/vat_tax_model.dart';
import 'package:shoplancer_vendor/features/profile/domain/models/profile_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/band_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/review_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/suitable_tag_model.dart';
import 'package:shoplancer_vendor/interface/repository_interface.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';

abstract class StoreRepositoryInterface<T>
    extends RepositoryInterface<Schedules> {
  Future<ItemModel?> getItemList({
    required String offset,
    required String type,
    required String search,
    int? categoryId,
    int? moduleId,
    String? barcode,
    String? minPrice,
    String? maxPrice,
    String? sort,
  });
  Future<dynamic> getStockItemList(String offset);
  Future<dynamic> getPendingItemList(String offset, String type);
  Future<dynamic> getPendingItemDetails(int itemId);
  Future<dynamic> getAttributeList(Item? item);
  Future<bool> updateStoreBasicInfo(
    Store store,
    XFile? logo,
    XFile? cover,
    List<Translation> translation,
    XFile? metaImage,
  );
  Future<dynamic> updateStore(Store store, String min, String max, String type);
  Future<dynamic> addItem(
    Item item,
    XFile? metaImage,
    XFile? image,
    List<XFile> images,
    List<String> savedImages,
    Map<String, String> attributes,
    bool isAdd,
    String tags,
    String nutrition,
    String allergicIngredients,
    String genericName,
  );
  Future<dynamic> deleteItem(int? itemID, bool pendingItem);
  Future<List<ReviewModel>?> getStoreReviewList(
    int? storeID,
    String? searchText,
  );
  Future<dynamic> getItemReviewList(int? itemID);
  Future<dynamic> updateItemStatus(int? itemID, int status);
  Future<dynamic> getUnitList();
  Future<dynamic> updateRecommendedProductStatus(int? productID, int status);
  Future<dynamic> updateBestSellerProductStatus(int? productID, int status);
  Future<dynamic> updateOrganicProductStatus(int? productID, int status);
  Future<dynamic> updateAnnouncement(int status, String announcement);
  Future<List<BrandModel>?> getBrandList();
  Future<Response> updateBrandStatus(int brandId, int status);
  Future<ItemModel?> getBrandItemList({required String offset, required int brandId});
  Future<bool> updateReply(int reviewID, String reply);
  Future<List<String?>?> getNutritionSuggestionList();
  Future<List<String?>?> getAllergicIngredientsSuggestionList();
  Future<List<String?>?> getGenericNameSuggestionList();
  Future<Response> stockUpdate(Map<String, dynamic> data);
  Future<Response> bulkStockUpdate(Map<String, dynamic> body);
  Future<Response> bulkAssignProducts(List<Map<String, dynamic>> products);
  Future<List<SuitableTagModel>?> getSuitableTagList();
  Future<List<VatTaxModel>?> getVatTaxList();
  Future<Response> getStoreSections();
  Future<Response> updateStoreSections(List<Map<String, dynamic>> sections);
}
