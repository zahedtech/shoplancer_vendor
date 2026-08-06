import 'package:shoplancer_vendor/features/employee/domain/models/employee_role_model.dart';

class EmployeeModel {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? imageFullUrl;
  int? roleId;
  EmployeeRoleModel? role;
  int? status;
  String? createdAt;

  EmployeeModel({
    this.id,
    this.fName,
    this.lName,
    this.phone,
    this.email,
    this.imageFullUrl,
    this.roleId,
    this.role,
    this.status,
    this.createdAt,
  });

  EmployeeModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
    imageFullUrl = json['image_full_url'] ?? json['image'];
    roleId = json['role_id'] != null ? int.tryParse(json['role_id'].toString()) : null;
    role = json['role'] != null ? EmployeeRoleModel.fromJson(json['role']) : null;
    status = json['status'] != null ? int.tryParse(json['status'].toString()) : 1;
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['email'] = email;
    data['image_full_url'] = imageFullUrl;
    data['role_id'] = roleId;
    if (role != null) {
      data['role'] = role!.toJson();
    }
    data['status'] = status;
    data['created_at'] = createdAt;
    return data;
  }
}
