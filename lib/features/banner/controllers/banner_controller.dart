import 'package:shoplancer_vendor/features/banner/domain/models/store_banner_list_model.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/features/banner/domain/services/banner_service_interface.dart';

class BannerController extends GetxController implements GetxService {
  final BannerServiceInterface bannerServiceInterface;
  BannerController({required this.bannerServiceInterface});

  List<StoreBannerListModel>? _storeBannerList;
  List<StoreBannerListModel>? get storeBannerList => _storeBannerList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StoreBannerListModel? _storeBannerDetails;
  StoreBannerListModel? get storeBannerDetails => _storeBannerDetails;

  Future<void> addBanner({
    required StoreBannerListModel? banner,
    XFile? image,
  }) async {
    _isLoading = true;
    update();
    bool isSuccess = await bannerServiceInterface.addBanner(
      banner: banner,
      image: image,
    );
    if (isSuccess) {
      getBannerList(willUpdate: false);
      Get.back();
      showCustomSnackBar('banner_added_successfully'.tr, isError: false);
    }
    _isLoading = false;
    update();
  }

  Future<void> getBannerList({bool willUpdate = true}) async {
    _isLoading = true;
    if (willUpdate) {
      Future.microtask(() => update());
    }
    List<StoreBannerListModel>? storeBannerList = await bannerServiceInterface
        .getBannerList();
    if (storeBannerList != null) {
      _storeBannerList = [];
      _storeBannerList!.addAll(storeBannerList);
    }
    _isLoading = false;
    update();
  }

  Future<void> deleteBanner(int? bannerID, {int? catalogId}) async {
    _isLoading = true;
    update();
    bool isSuccess = await bannerServiceInterface.deleteBanner(bannerID, catalogId: catalogId);
    if (isSuccess) {
      await getBannerList(willUpdate: false);
      Get.back();
      showCustomSnackBar('banner_deleted_successfully'.tr, isError: false);
    }
    _isLoading = false;
    update();
  }

  Future<void> updateBanner({
    required StoreBannerListModel? banner,
    required XFile? image,
  }) async {
    _isLoading = true;
    update();
    bool isSuccess = await bannerServiceInterface.updateBanner(
      banner: banner,
      image: image,
    );
    if (isSuccess) {
      await getBannerList(willUpdate: false);
      Get.back();
      showCustomSnackBar('banner_updated_successfully'.tr, isError: false);
    }
    _isLoading = false;
    update();
  }

  Future<StoreBannerListModel?> getBannerDetails(int id) async {
    _storeBannerDetails = null;
    StoreBannerListModel? storeBannerDetails = await bannerServiceInterface
        .getBannerDetails(id);
    if (storeBannerDetails != null) {
      _storeBannerDetails = storeBannerDetails;
    }
    update();
    return _storeBannerDetails;
  }

  List<StoreBannerListModel>? _catalogBannerList;
  List<StoreBannerListModel>? get catalogBannerList => _catalogBannerList;

  bool _isCatalogLoading = false;
  bool get isCatalogLoading => _isCatalogLoading;

  Future<void> getCatalogBannerList({bool willUpdate = true}) async {
    _isCatalogLoading = true;
    if (willUpdate) {
      Future.microtask(() => update());
    }
    List<StoreBannerListModel>? catalogList = await bannerServiceInterface.getCatalogBannerList();
    if (catalogList != null) {
      _catalogBannerList = [];
      _catalogBannerList!.addAll(catalogList);
    }
    _isCatalogLoading = false;
    update();
  }

  Future<bool> addCatalogBanner(int? bannerId) async {
    _isLoading = true;
    update();
    bool isSuccess = await bannerServiceInterface.addCatalogBanner(bannerId);
    if (isSuccess) {
      await getBannerList(willUpdate: false);
      showCustomSnackBar('banner_added_successfully'.tr, isError: false);
    }
    _isLoading = false;
    update();
    return isSuccess;
  }
}
