import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/api/api_client.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_model.dart';
import 'package:shoplancer_vendor/features/employee/domain/repositories/employee_repository_interface.dart';
import 'package:shoplancer_vendor/util/app_constants.dart';
import 'package:get/get.dart';

class EmployeeRepository implements EmployeeRepositoryInterface {
  final ApiClient apiClient;
  EmployeeRepository({required this.apiClient});

  @override
  Future<List<EmployeeModel>?> getList({int? offset}) async {
    Response response = await apiClient.getData(AppConstants.employeeListUri);
    if (response.statusCode == 200 && response.body != null) {
      List<EmployeeModel> employeeList = [];
      List<dynamic> list = response.body is List ? response.body : (response.body['data'] ?? []);
      for (var item in list) {
        employeeList.add(EmployeeModel.fromJson(item));
      }
      return employeeList;
    }
    return null;
  }

  @override
  Future<Response> getEmployeeRoles() async {
    return await apiClient.getData(AppConstants.employeeRolesUri);
  }

  @override
  Future<Response> addEmployee(EmployeeModel employee, String password, XFile? image) async {
    Map<String, String> fields = {
      'f_name': employee.fName ?? '',
      'l_name': employee.lName ?? '',
      'phone': employee.phone ?? '',
      'email': employee.email ?? '',
      'password': password,
      'role_id': employee.roleId.toString(),
    };
    List<MultipartBody> multiParts = [];
    if (image != null) {
      multiParts.add(MultipartBody('image', image));
    }
    return await apiClient.postMultipartData(AppConstants.addEmployeeUri, fields, multiParts);
  }

  @override
  Future<Response> updateEmployee(EmployeeModel employee, String? password, XFile? image) async {
    Map<String, String> fields = {
      'f_name': employee.fName ?? '',
      'l_name': employee.lName ?? '',
      'phone': employee.phone ?? '',
      'email': employee.email ?? '',
      'role_id': employee.roleId.toString(),
    };
    if (password != null && password.isNotEmpty) {
      fields['password'] = password;
    }
    List<MultipartBody> multiParts = [];
    if (image != null) {
      multiParts.add(MultipartBody('image', image));
    }
    return await apiClient.postMultipartData('${AppConstants.updateEmployeeUri}/${employee.id}', fields, multiParts);
  }

  @override
  Future<Response> updateEmployeeStatus(int employeeId, int status) async {
    return await apiClient.postData(AppConstants.updateEmployeeStatusUri, {
      'employee_id': employeeId,
      'status': status,
    });
  }

  @override
  Future<Response> deleteEmployee(int employeeId) async {
    return await apiClient.postData(AppConstants.deleteEmployeeUri, {
      '_method': 'delete',
      'employee_id': employeeId,
    });
  }

  @override
  Future add(EmployeeModel value) => throw UnimplementedError();

  @override
  Future delete(int? id) => deleteEmployee(id!);

  @override
  Future get(int? id) => throw UnimplementedError();

  @override
  Future update(Map<String, dynamic> body, {int? id}) => throw UnimplementedError();
}
