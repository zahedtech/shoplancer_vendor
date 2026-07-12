import 'package:shoplancer_vendor/features/store/domain/models/item_model.dart';

class StoreBannerListModel {
  int? id;
  String? title;
  String? subTitle;
  String? type;
  String? imageFullUrl;
  bool? status;
  int? data;
  String? createdAt;
  String? updatedAt;
  int? zoneId;
  int? moduleId;
  bool? featured;
  String? defaultLink;
  String? createdBy;
  String? backgroundColor;
  List<Translation>? translations;
  int? bannerCatalogId;

  StoreBannerListModel({
    this.id,
    this.title,
    this.subTitle,
    this.type,
    this.imageFullUrl,
    this.status,
    this.data,
    this.createdAt,
    this.updatedAt,
    this.zoneId,
    this.moduleId,
    this.featured,
    this.defaultLink,
    this.createdBy,
    this.backgroundColor,
    this.translations,
    this.bannerCatalogId,
  });

  StoreBannerListModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    subTitle = json['sub_title'];
    type = json['type'];
    imageFullUrl = json['image_full_url'];
    status = json['status'] is int ? json['status'] == 1 : json['status'];
    data = json['data'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    zoneId = json['zone_id'];
    moduleId = json['module_id'];
    featured = json['featured'] is int
        ? json['featured'] == 1
        : json['featured'];
    defaultLink = json['default_link'];
    createdBy = json['created_by'];
    backgroundColor = json['background_color'];
    bannerCatalogId = json['banner_catalog_id'];
    if (json['translations'] != null) {
      translations = [];
      json['translations'].forEach((v) {
        final translation = Translation.fromJson(v);
        translations!.add(translation);
        if (translation.key == 'title' && (title == null || title!.isEmpty)) {
          title = translation.value;
        }
        if (translation.key == 'subtitle' &&
            (subTitle == null || subTitle!.isEmpty)) {
          subTitle = translation.value;
        }
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['sub_title'] = subTitle;
    data['type'] = type;
    data['image_full_url'] = imageFullUrl;
    data['status'] = status;
    data['data'] = this.data;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['zone_id'] = zoneId;
    data['module_id'] = moduleId;
    data['featured'] = featured;
    data['default_link'] = defaultLink;
    data['created_by'] = createdBy;
    data['background_color'] = backgroundColor;
    data['banner_catalog_id'] = bannerCatalogId;
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
