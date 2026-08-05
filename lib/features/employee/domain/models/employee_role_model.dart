class EmployeeRoleModel {
  int? id;
  String? title;
  List<String>? modules;

  EmployeeRoleModel({this.id, this.title, this.modules});

  EmployeeRoleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    if (json['modules'] != null) {
      modules = List<String>.from(json['modules']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['modules'] = modules;
    return data;
  }
}
