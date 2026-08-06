import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/common/widgets/custom_app_bar_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_image_widget.dart';
import 'package:shoplancer_vendor/common/widgets/custom_snackbar_widget.dart';
import 'package:shoplancer_vendor/features/employee/controllers/employee_controller.dart';
import 'package:shoplancer_vendor/features/employee/domain/models/employee_model.dart';
import 'package:shoplancer_vendor/helper/route_helper.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<EmployeeController>().getEmployeeList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'إدارة الموظفين'.tr,
        menuWidget: IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 26),
          color: Theme.of(context).primaryColor,
          onPressed: () {
            Get.toNamed(RouteHelper.getAddEmployeeRoute());
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          Get.toNamed(RouteHelper.getAddEmployeeRoute());
        },
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text('إضافة موظف'.tr, style: robotoBold.copyWith(color: Colors.white)),
      ),
      body: GetBuilder<EmployeeController>(
        builder: (controller) {
          if (controller.isLoading && (controller.employeeList == null)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.employeeList == null || controller.employeeList!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Theme.of(context).disabledColor),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text(
                    'لا يوجد موظفين مضافين حالياً',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed(RouteHelper.getAddEmployeeRoute()),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة موظف جديد'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.getEmployeeList();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              itemCount: controller.employeeList!.length,
              itemBuilder: (context, index) {
                final EmployeeModel employee = controller.employeeList![index];
                final bool isActive = employee.status == 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                      child: CustomImageWidget(
                        image: employee.imageFullUrl ?? '',
                        height: 55,
                        width: 55,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      '${employee.fName ?? ''} ${employee.lName ?? ''}'.trim(),
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (employee.role?.title != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              employee.role!.title!,
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${employee.phone ?? ''} ${employee.email != null ? '• ${employee.email}' : ''}',
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isActive,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (bool value) {
                            controller.toggleEmployeeStatus(employee.id!, employee.status ?? 0);
                          },
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Get.toNamed(
                                RouteHelper.getAddEmployeeRoute(),
                                arguments: employee,
                              );
                            } else if (value == 'delete') {
                              _showDeleteConfirmationDialog(context, controller, employee);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Text('تعديل'.tr),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Text('حذف'.tr),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    EmployeeController controller,
    EmployeeModel employee,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('تأكيد الحذف'.tr, style: robotoBold),
        content: Text('هل أنت تأكد من رغبتك في حذف الموظف "${employee.fName ?? ''}"؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.deleteEmployee(employee.id!);
            },
            child: Text('حذف'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
