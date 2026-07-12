import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/api/api_client.dart';
import 'package:shoplancer_vendor/features/banner/domain/models/store_banner_list_model.dart';
import 'package:shoplancer_vendor/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/features/banner/domain/repositories/banner_repository_interface.dart';
import 'package:shoplancer_vendor/features/profile/controllers/profile_controller.dart';

class BannerRepository implements BannerRepositoryInterface {
  final ApiClient apiClient;
  BannerRepository({required this.apiClient});

  @override
  Future<bool> addBanner({
    required StoreBannerListModel? banner,
    XFile? image,
  }) async {
    Map<String, String> body = {};
    body.addAll({
      'translations': jsonEncode(banner?.translations),
      'default_link': banner?.defaultLink ?? '',
      'type': banner?.type ?? 'image',
      'background_color': banner?.backgroundColor ?? '',
    });
    List<MultipartBody> multipart = [];
    if (image != null) {
      multipart.add(MultipartBody('image', image));
    }
    Response response = await apiClient.postMultipartData(
      AppConstants.addStoreBannerUri,
      body,
      multipart,
    );
    return (response.statusCode == 200);
  }

  @override
  Future<List<StoreBannerListModel>?> getList() async {
    List<StoreBannerListModel>? storeBannerList;
    Response response = await apiClient.getData(AppConstants.storeBannerUri);
    if (response.statusCode == 200) {
      storeBannerList = [];
      Map<int, StoreBannerListModel> uniqueBanners = {};
      if (response.body is Map) {
        if (response.body['banners'] != null) {
          response.body['banners'].forEach((item) {
            StoreBannerListModel banner = StoreBannerListModel.fromJson(item);
            if (banner.id != null) {
              uniqueBanners[banner.id!] = banner;
            } else {
              storeBannerList!.add(banner);
            }
          });
        }
        if (response.body['catalog_banners'] != null) {
          response.body['catalog_banners'].forEach((item) {
            StoreBannerListModel banner = StoreBannerListModel.fromJson(item);
            banner.bannerCatalogId = banner.bannerCatalogId ?? banner.id;
            if (banner.id != null) {
              uniqueBanners[banner.id!] = banner;
            } else {
              storeBannerList!.add(banner);
            }
          });
        }
      } else if (response.body is List) {
        response.body.forEach((item) {
          StoreBannerListModel banner = StoreBannerListModel.fromJson(item);
          if (banner.id != null) {
            uniqueBanners[banner.id!] = banner;
          } else {
            storeBannerList!.add(banner);
          }
        });
      }
      storeBannerList.addAll(uniqueBanners.values);
    }
    return storeBannerList;
  }

  @override
  Future<bool> delete(int? id, {int? catalogId}) async {
    Response response;
    if (catalogId != null) {
      int? storeId = Get.find<ProfileController>().profileModel?.stores?[0].id;
      response = await apiClient.deleteData(
        '/api/v1/stores/$storeId/banner-catalog/unassign',
        body: {'banner_catalog_id': catalogId},
      );
    } else {
      response = await apiClient.deleteData(
        '${AppConstants.deleteStoreBannerUri}?id=$id',
      );
    }
    return (response.statusCode == 200);
  }

  @override
  Future<bool> updateBanner({
    required StoreBannerListModel? banner,
    XFile? image,
  }) async {
    Map<String, String> body = {};
    body.addAll({
      'translations': jsonEncode(banner?.translations),
      'default_link': banner?.defaultLink ?? '',
      'id': banner!.id!.toString(),
      '_method': 'put',
      'type': banner.type ?? 'image',
      'background_color': banner.backgroundColor ?? '',
    });
    Response response = await apiClient.postMultipartData(
      AppConstants.updateStoreBannerUri,
      body,
      [MultipartBody('image', image)],
    );
    return (response.statusCode == 200);
  }

  @override
  Future<StoreBannerListModel?> get(int? id) async {
    StoreBannerListModel? bannersDetails;
    Response response = await apiClient.getData(
      '${AppConstants.storeBannerDetailsUri}/$id',
    );
    if (response.statusCode == 200) {
      bannersDetails = StoreBannerListModel.fromJson(response.body);
    }
    return bannersDetails;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body) {
    throw UnimplementedError();
  }

  @override
  Future<List<StoreBannerListModel>?> getCatalogBannerList() async {
    List<StoreBannerListModel>? catalogBannerList;
    Response response = await apiClient.getData(AppConstants.catalogBannerUri);
    if (response.statusCode == 200) {
      catalogBannerList = [];
      if (response.body is Map && response.body['catalog_banners'] != null) {
        response.body['catalog_banners'].forEach(
          (item) => catalogBannerList!.add(StoreBannerListModel.fromJson(item)),
        );
      } else if (response.body is Map && response.body['banners'] != null) {
        response.body['banners'].forEach(
          (item) => catalogBannerList!.add(StoreBannerListModel.fromJson(item)),
        );
      } else if (response.body is List) {
        response.body.forEach(
          (item) => catalogBannerList!.add(StoreBannerListModel.fromJson(item)),
        );
      }
    }
    return catalogBannerList;
  }

  @override
  Future<bool> addCatalogBanner(int? bannerId) async {
    int? storeId = Get.find<ProfileController>().profileModel?.stores?[0].id;
    Response response = await apiClient.postData(
      '/api/v1/stores/$storeId/banner-catalog/assign',
      {'banner_catalog_id': bannerId},
    );
    return (response.statusCode == 200);
  }
}
