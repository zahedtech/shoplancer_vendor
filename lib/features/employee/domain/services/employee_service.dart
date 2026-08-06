import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_model.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_role_model.dart';
import 'package:shoplancer_vendor/features/employee/domain/repositories/employee_repository_interface.dart';
import 'package:shoplancer_vendor/features/employee/domain/services/employee_service_interface.dart';
import 'package:get/get_connect/http/src/response/response.dart';

class EmployeeService implements EmployeeServiceInterface {
  final EmployeeRepositoryInterface employeeRepositoryInterface;
  EmployeeService({required this.employeeRepositoryInterface});

  @override
  Future<List<EmployeeModel>?> getEmployeeList() async {
    return await employeeRepositoryInterface.getList();
  }

  @override
  Future<List<EmployeeRoleModel>?> getEmployeeRoles() async {
    Response response = await employeeRepositoryInterface.getEmployeeRoles();
    if (response.statusCode == 200 && response.body != null) {
      List<EmployeeRoleModel> roles = [];
      List<dynamic> list = response.body is List ? response.body : (response.body['data'] ?? []);
      for (var item in list) {
        roles.add(EmployeeRoleModel.fromJson(item));
      }
      return roles;
    }
    return null;
  }

  @override
  Future<Response> addEmployee(EmployeeModel employee, String password, XFile? image) async {
    return await employeeRepositoryInterface.addEmployee(employee, password, image);
  }

  @override
  Future<Response> updateEmployee(EmployeeModel employee, String? password, XFile? image) async {
    return await employeeRepositoryInterface.updateEmployee(employee, password, image);
  }

  @override
  Future<Response> updateEmployeeStatus(int employeeId, int status) async {
    return await employeeRepositoryInterface.updateEmployeeStatus(employeeId, status);
  }

  @override
  Future<Response> deleteEmployee(int employeeId) async {
    return await employeeRepositoryInterface.deleteEmployee(employeeId);
  }
}
