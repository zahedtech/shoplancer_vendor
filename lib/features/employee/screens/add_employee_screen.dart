import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_button_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_text_field_widget.dart';
import 'package:shoplancer_vendor/features/employee/controllers/employee_controller.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_model.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_role_model.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class AddEmployeeScreen extends StatefulWidget {
  final EmployeeModel? employee;
  const AddEmployeeScreen({super.key, this.employee});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _fNameNode = FocusNode();
  final FocusNode _lNameNode = FocusNode();
  final FocusNode _phoneNode = FocusNode();
  final FocusNode _emailNode = FocusNode();
  final FocusNode _passwordNode = FocusNode();

  EmployeeRoleModel? _selectedRole;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<EmployeeController>();
    controller.getEmployeeRoles();

    if (widget.employee != null) {
      _fNameController.text = widget.employee!.fName ?? '';
      _lNameController.text = widget.employee!.lName ?? '';
      _phoneController.text = widget.employee!.phone ?? '';
      _emailController.text = widget.employee!.email ?? '';
      _selectedRole = widget.employee!.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isUpdate = widget.employee != null;

    return Scaffold(
      appBar: CustomAppBarWidget(
        title: isUpdate ? 'تعديل بيانات الموظف'.tr : 'إضافة موظف جديد'.tr,
      ),
      body: GetBuilder<EmployeeController>(
        builder: (controller) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture Picker
                      Center(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: controller.pickedImage != null
                                  ? Image.file(
                                      File(controller.pickedImage!.path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : CustomImageWidget(
                                      image: widget.employee?.imageFullUrl ?? '',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () => controller.pickImage(),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      // First Name
                      Text('الاسم الأول *'.tr, style: robotoRegular),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      CustomTextFieldWidget(
                        controller: _fNameController,
                        focusNode: _fNameNode,
                        nextFocus: _lNameNode,
                        hintText: 'أدخل الاسم الأول'.tr,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Last Name
                      Text('الاسم الأخير *'.tr, style: robotoRegular),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      CustomTextFieldWidget(
                        controller: _lNameController,
                        focusNode: _lNameNode,
                        nextFocus: _phoneNode,
                        hintText: 'أدخل الاسم الأخير'.tr,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Phone
                      Text('رقم الهاتف *'.tr, style: robotoRegular),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      CustomTextFieldWidget(
                        controller: _phoneController,
                        focusNode: _phoneNode,
                        nextFocus: _emailNode,
                        inputType: TextInputType.phone,
                        hintText: 'مثال: +201000000000'.tr,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Email
                      Text('البريد الإلكتروني *'.tr, style: robotoRegular),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      CustomTextFieldWidget(
                        controller: _emailController,
                        focusNode: _emailNode,
                        nextFocus: _passwordNode,
                        inputType: TextInputType.emailAddress,
                        hintText: 'example@domain.com'.tr,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Role Dropdown
                      Text('دور الموظف (الصلاحية) *'.tr, style: robotoRegular),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          border: Border.all(color: Theme.of(context).disabledColor.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<EmployeeRoleModel>(
                            isExpanded: true,
                            hint: Text('اختر دور الموظف'.tr, style: robotoRegular),
                            value: controller.rolesList?.firstWhereOrNull((r) => r.id == _selectedRole?.id),
                            items: (controller.rolesList ?? []).map((role) {
                              return DropdownMenuItem<EmployeeRoleModel>(
                                value: role,
                                child: Text(role.title ?? '', style: robotoRegular),
                              );
                            }).toList(),
                            onChanged: (role) {
                              setState(() {
                                _selectedRole = role;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Password
                      Text(
                        isUpdate ? 'كلمة المرور (اتركها فارغة لإبقائها كما هي)'.tr : 'كلمة المرور *'.tr,
                        style: robotoRegular,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      CustomTextFieldWidget(
                        controller: _passwordController,
                        focusNode: _passwordNode,
                        isPassword: true,
                        hintText: '******'.tr,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: CustomButtonWidget(
                  isLoading: controller.isLoading,
                  buttonText: isUpdate ? 'تحديث البيانات'.tr : 'إضافة الموظف'.tr,
                  onPressed: () {
                    _saveEmployee(controller, isUpdate);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveEmployee(EmployeeController controller, bool isUpdate) async {
    String fName = _fNameController.text.trim();
    String lName = _lNameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (fName.isEmpty) {
      showCustomSnackBar('يرجى إدخال الاسم الأول'.tr);
      return;
    }
    if (lName.isEmpty) {
      showCustomSnackBar('يرجى إدخال الاسم الأخير'.tr);
      return;
    }
    if (phone.isEmpty) {
      showCustomSnackBar('يرجى إدخال رقم الهاتف'.tr);
      return;
    }
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      showCustomSnackBar('يرجى إدخال بريد إلكتروني صحيح'.tr);
      return;
    }
    if (_selectedRole == null) {
      showCustomSnackBar('يرجى اختيار دور الموظف'.tr);
      return;
    }
    if (!isUpdate && (password.isEmpty || password.length < 6)) {
      showCustomSnackBar('يرجى إدخال كلمة مرور من 6 أحرف على الأقل'.tr);
      return;
    }

    EmployeeModel model = EmployeeModel(
      id: widget.employee?.id,
      fName: fName,
      lName: lName,
      phone: phone,
      email: email,
      roleId: _selectedRole!.id,
    );

    bool success;
    if (isUpdate) {
      success = await controller.updateEmployee(model, password.isNotEmpty ? password : null);
    } else {
      success = await controller.addEmployee(model, password);
    }

    if (success) {
      Get.back();
    }
  }
}
