import 'package:image_picker/image_picker.dart';
import 'package:shoplancer_vendor/api/api_checker.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_model.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_role_model.dart';
import 'package:shoplancer_vendor/features/employee/domain/services/employee_service_interface.dart';
import 'package:get/get.dart';

class EmployeeController extends GetxController implements GetxService {
  final EmployeeServiceInterface employeeServiceInterface;
  EmployeeController({required this.employeeServiceInterface});

  List<EmployeeModel>? _employeeList;
  List<EmployeeModel>? get employeeList => _employeeList;

  List<EmployeeRoleModel>? _rolesList;
  List<EmployeeRoleModel>? get rolesList => _rolesList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  XFile? _pickedImage;
  XFile? get pickedImage => _pickedImage;

  EmployeeRoleModel? _selectedRole;
  EmployeeRoleModel? get selectedRole => _selectedRole;

  void setSelectedRole(EmployeeRoleModel? role) {
    _selectedRole = role;
    update();
  }

  void pickImage() async {
    _pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    update();
  }

  void clearImage() {
    _pickedImage = null;
    update();
  }

  Future<void> getEmployeeList() async {
    _isLoading = true;
    update();
    _employeeList = await employeeServiceInterface.getEmployeeList();
    _isLoading = false;
    update();
  }

  Future<void> getEmployeeRoles() async {
    _rolesList = await employeeServiceInterface.getEmployeeRoles();
    update();
  }

  Future<bool> addEmployee(EmployeeModel employee, String password) async {
    _isLoading = true;
    update();
    Response response = await employeeServiceInterface.addEmployee(employee, password, _pickedImage);
    _isLoading = false;
    if (response.statusCode == 200 || response.statusCode == 201) {
      showCustomSnackBar('تم إضافة الموظف بنجاح'.tr, isError: false);
      clearImage();
      getEmployeeList();
      update();
      return true;
    } else {
      ApiChecker.checkApi(response);
      update();
      return false;
    }
  }

  Future<bool> updateEmployee(EmployeeModel employee, String? password) async {
    _isLoading = true;
    update();
    Response response = await employeeServiceInterface.updateEmployee(employee, password, _pickedImage);
    _isLoading = false;
    if (response.statusCode == 200 || response.statusCode == 201) {
      showCustomSnackBar('تم تحديث بيانات الموظف بنجاح'.tr, isError: false);
      clearImage();
      getEmployeeList();
      update();
      return true;
    } else {
      ApiChecker.checkApi(response);
      update();
      return false;
    }
  }

  Future<bool> toggleEmployeeStatus(int employeeId, int currentStatus) async {
    int nextStatus = currentStatus == 1 ? 0 : 1;
    Response response = await employeeServiceInterface.updateEmployeeStatus(employeeId, nextStatus);
    if (response.statusCode == 200 || response.statusCode == 201) {
      showCustomSnackBar('تم تغيير حالة الموظف بنجاح'.tr, isError: false);
      if (_employeeList != null) {
        int index = _employeeList!.indexWhere((e) => e.id == employeeId);
        if (index != -1) {
          _employeeList![index].status = nextStatus;
        }
      }
      update();
      return true;
    } else {
      ApiChecker.checkApi(response);
      return false;
    }
  }

  Future<bool> deleteEmployee(int employeeId) async {
    _isLoading = true;
    update();
    Response response = await employeeServiceInterface.deleteEmployee(employeeId);
    _isLoading = false;
    if (response.statusCode == 200 || response.statusCode == 201) {
      showCustomSnackBar('تم حذف الموظف بنجاح'.tr, isError: false);
      getEmployeeList();
      update();
      return true;
    } else {
      ApiChecker.checkApi(response);
      update();
      return false;
    }
  }
}
