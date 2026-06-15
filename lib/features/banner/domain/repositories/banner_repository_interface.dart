import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/features/banner/domain/models/store_banner_list_model.dart';
import 'package:shoplancer_vendor/interface/repository_interface.dart';

abstract class BannerRepositoryInterface extends RepositoryInterface {
  Future<bool> addBanner({required StoreBannerListModel? banner, XFile? image});
  Future<bool> updateBanner({
    required StoreBannerListModel? banner,
    XFile? image,
  });
  Future<List<StoreBannerListModel>?> getCatalogBannerList();
  Future<bool> addCatalogBanner(int? bannerId);
  @override
  Future<bool> delete(int? id, {int? catalogId});
}
