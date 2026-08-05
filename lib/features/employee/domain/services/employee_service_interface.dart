import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_model.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_role_model.dart';
import 'package:get/get_connect/http/src/response/response.dart';

abstract class EmployeeServiceInterface {
  Future<List<EmployeeModel>?> getEmployeeList();
  Future<List<EmployeeRoleModel>?> getEmployeeRoles();
  Future<Response> addEmployee(EmployeeModel employee, String password, XFile? image);
  Future<Response> updateEmployee(EmployeeModel employee, String? password, XFile? image);
  Future<Response> updateEmployeeStatus(int employeeId, int status);
  Future<Response> deleteEmployee(int employeeId);
}
