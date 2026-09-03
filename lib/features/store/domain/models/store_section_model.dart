class StoreSectionModel {
  int? id;
  String? sectionKey;
  String? name;
  int? isActive;
  int? sortOrder;

  StoreSectionModel({
    this.id,
    this.sectionKey,
    this.name,
    this.isActive,
    this.sortOrder,
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
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (id != null) data['section_id'] = id;
    if (sectionKey != null) data['section_key'] = sectionKey;
    if (name != null) data['name'] = name;
    data['is_active'] = isActive ?? 1;
    data['sort_order'] = sortOrder ?? 0;
    return data;
  }
}
