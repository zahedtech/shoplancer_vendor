class StoreSectionModel {
  int? id;
  String? sectionKey;
  String? defaultName;
  String? customName;
  int? isActive;
  int? sortOrder;

  StoreSectionModel({
    this.id,
    this.sectionKey,
    this.defaultName,
    this.customName,
    this.isActive,
    this.sortOrder,
  });

  StoreSectionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sectionKey = json['section_key'];
    defaultName = json['default_name'];
    customName = json['custom_name'];
    isActive = json['is_active'] != null ? int.tryParse(json['is_active'].toString()) : 1;
    sortOrder = json['sort_order'] != null ? int.tryParse(json['sort_order'].toString()) : 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['section_key'] = sectionKey;
    data['default_name'] = defaultName;
    data['custom_name'] = customName;
    data['is_active'] = isActive;
    data['sort_order'] = sortOrder;
    return data;
  }
}
