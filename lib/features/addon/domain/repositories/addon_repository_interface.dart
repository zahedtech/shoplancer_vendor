import 'package:shoplancer_vendor/features/addon/models/addon_category_model.dart';
import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';
import 'package:shoplancer_vendor/interface/repository_interface.dart';

abstract class AddonRepositoryInterface<T> extends RepositoryInterface<AddOns> {
  Future<List<AddonCategoryModel>?> getAddonCategory({required int moduleId});
  Future<bool> updateAddon(AddOns addonModel);
}