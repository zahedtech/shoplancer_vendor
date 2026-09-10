class SectionCategoryModel {
  int? id;
  String? name;
  String? imageFullUrl;
  int? isActive;
  int? sortOrder;

  SectionCategoryModel({
    this.id,
    this.name,
    this.imageFullUrl,
    this.isActive = 1,
    this.sortOrder = 0,
  });

  SectionCategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name']?.toString();
    imageFullUrl = json['image_full_url']?.toString() ??
        json['image']?.toString();
    isActive = json['is_active'] != null
        ? int.tryParse(json['is_active'].toString())
        : (json['status'] != null
            ? int.tryParse(json['status'].toString())
            : 1);
    sortOrder = json['sort_order'] != null
        ? int.tryParse(json['sort_order'].toString())
        : (json['priority'] != null
            ? int.tryParse(json['priority'].toString())
            : 0);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (name != null) data['name'] = name;
    if (imageFullUrl != null) data['image_full_url'] = imageFullUrl;
    data['is_active'] = isActive ?? 1;
    data['status'] = isActive ?? 1;
    data['sort_order'] = sortOrder ?? 0;
    return data;
  }
}

class StoreSectionModel {
  int? id;
  String? sectionKey;
  String? name;
  int? isActive;
  int? sortOrder;
  List<SectionCategoryModel>? categories;

  StoreSectionModel({
    this.id,
    this.sectionKey,
    this.name,
    this.isActive,
    this.sortOrder,
    this.categories,
  });

  StoreSectionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null
        ? int.tryParse(json['id'].toString())
        : (json['section_id'] != null
            ? int.tryParse(json['section_id'].toString())
            : null);
    sectionKey = json['section_key']?.toString();
    name = json['name']?.toString() ??
        json['custom_name']?.toString() ??
        json['default_name']?.toString();
    isActive = json['is_active'] != null
        ? int.tryParse(json['is_active'].toString())
        : 1;
    sortOrder = json['sort_order'] != null
        ? int.tryParse(json['sort_order'].toString())
        : 0;
    if (json['categories'] != null && json['categories'] is List) {
      categories = [];
      for (var v in json['categories']) {
        if (v is Map<String, dynamic>) {
          categories!.add(SectionCategoryModel.fromJson(v));
        } else if (v is SectionCategoryModel) {
          categories!.add(v);
        } else if (v is num || v is String) {
          categories!.add(
            SectionCategoryModel(id: int.tryParse(v.toString())),
          );
        }
      }
      categories!.sort(
        (a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0),
      );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (id != null) data['section_id'] = id;
    if (sectionKey != null) data['section_key'] = sectionKey;
    if (name != null) data['name'] = name;
    data['is_active'] = isActive ?? 1;
    data['sort_order'] = sortOrder ?? 0;
    if (categories != null) {
      data['categories'] = categories!.map((c) => c.toJson()).toList();
      data['category_ids'] = categories!
          .where((c) => c.isActive == 1)
          .map((v) => v.id)
          .whereType<int>()
          .toList();
    }
    return data;
  }
}
