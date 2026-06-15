import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/features/banner/domain/models/store_banner_list_model.dart';
import 'package:shoplancer_vendor/features/banner/domain/repositories/banner_repository_interface.dart';
import 'package:shoplancer_vendor/features/banner/domain/services/banner_service_interface.dart';

class BannerService implements BannerServiceInterface {
  final BannerRepositoryInterface bannerRepositoryInterface;
  BannerService({required this.bannerRepositoryInterface});

  @override
  Future<bool> addBanner({
    required StoreBannerListModel? banner,
    XFile? image,
  }) async {
    return await bannerRepositoryInterface.addBanner(
      banner: banner,
      image: image,
    );
  }

  @override
  Future<List<StoreBannerListModel>?> getBannerList() async {
    return await bannerRepositoryInterface.getList();
  }

  @override
  Future<bool> deleteBanner(int? bannerID, {int? catalogId}) async {
    return await bannerRepositoryInterface.delete(bannerID, catalogId: catalogId);
  }

  @override
  Future<bool> updateBanner({
    required StoreBannerListModel? banner,
    XFile? image,
  }) async {
    return await bannerRepositoryInterface.updateBanner(
      banner: banner,
      image: image,
    );
  }

  @override
  Future<StoreBannerListModel?> getBannerDetails(int id) async {
    return await bannerRepositoryInterface.get(id);
  }

  @override
  Future<List<StoreBannerListModel>?> getCatalogBannerList() async {
    return await bannerRepositoryInterface.getCatalogBannerList();
  }

  @override
  Future<bool> addCatalogBanner(int? bannerId) async {
    return await bannerRepositoryInterface.addCatalogBanner(bannerId);
  }
}
