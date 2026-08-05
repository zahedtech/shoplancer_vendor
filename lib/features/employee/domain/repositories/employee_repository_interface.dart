import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/interface/repository_interface.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_model.dart';
import 'package:get/get_connect/http/src/response/response.dart';

abstract class EmployeeRepositoryInterface implements RepositoryInterface<EmployeeModel> {
  Future<Response> getEmployeeRoles();
  Future<Response> addEmployee(EmployeeModel employee, String password, XFile? image);
  Future<Response> updateEmployee(EmployeeModel employee, String? password, XFile? image);
  Future<Response> updateEmployeeStatus(int employeeId, int status);
  Future<Response> deleteEmployee(int employeeId);
}
