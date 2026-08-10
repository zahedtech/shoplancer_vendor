# شرح Features: Employees, Delivery Men, Advertisements

هذا الملف يغطي إدارة الموظفين، مندوبي التوصيل، والإعلانات المدفوعة/الترويجية.

## Employee - EmployeeScreen

**Path**: `lib/features/employee/screens/employee_screen.dart`
**Route / Entry Point**: `RouteHelper.employee` / `/employee`
**Controller**: `EmployeeController`
**Purpose**: عرض وإدارة موظفي المتجر.

### ماذا يظهر للمستخدم

- AppBar بعنوان إدارة الموظفين.
- زر إضافة موظف في AppBar.
- زر عائم extended لإضافة موظف.
- قائمة موظفين.
- كل موظف يعرض:
  - أيقونة شخص.
  - الاسم.
  - الدور/role إن وجد.
  - رقم الهاتف.
  - switch للحالة.
  - menu تعديل/حذف.

### ماذا يستطيع المستخدم أن يفعل

- إضافة موظف جديد.
- تعديل موظف.
- تفعيل/تعطيل موظف.
- حذف موظف بعد تأكيد.
- تحديث القائمة بالسحب.

### البيانات والمنطق

- عند الفتح يستدعي `EmployeeController.getEmployeeList`.
- تفعيل/تعطيل يستخدم `toggleEmployeeStatus`.
- الحذف يتم بعد dialog تأكيد.

### الحالات

- **Loading**: CircularProgressIndicator عند التحميل الأول.
- **Empty**: رسالة لا يوجد موظفين مع زر إضافة.
- **Delete confirmation**: AlertDialog.

## Employee - AddEmployeeScreen

**Path**: `lib/features/employee/screens/add_employee_screen.dart`
**Route / Entry Point**: `RouteHelper.addEmployee` / `/add-employee`
**Purpose**: إضافة أو تعديل موظف.

### ماذا يظهر للمستخدم

- نموذج بيانات موظف.
- حقول الاسم والهاتف/البريد وكلمة المرور حسب الحالة.
- اختيار role أو صلاحيات.
- زر حفظ.

### ماذا يستطيع المستخدم أن يفعل

- إنشاء موظف جديد.
- تعديل بيانات موظف موجود.
- تحديد صلاحيات/role الموظف.

## DeliveryMan - DeliveryManScreen

**Path**: `lib/features/deliveryman/screens/delivery_man_screen.dart`
**Route / Entry Point**: `RouteHelper.deliveryMan` / `/delivery-man`
**Controller**: `DeliveryManController`, `ProfileController`
**Purpose**: عرض وإدارة مندوبي التوصيل.

### ماذا يظهر للمستخدم

- AppBar بعنوان `delivery_man`.
- زر عائم لإضافة مندوب إذا صلاحية `deliveryman` مفعلة.
- قائمة مندوبي التوصيل إذا صلاحية `deliverymanList` مفعلة.
- كل مندوب يعرض:
  - الصورة.
  - إطار أخضر/أحمر حسب active.
  - الاسم.
  - زر تعديل.
  - زر حذف.

### ماذا يستطيع المستخدم أن يفعل

- إضافة مندوب.
- فتح تفاصيل مندوب.
- تعديل مندوب.
- حذف مندوب بعد تأكيد.

### البيانات والمنطق

- عند الفتح يستدعي `DeliveryManController.getDeliveryManList`.
- الصلاحيات تأتي من `ProfileController.modulePermission`.
- الضغط على العنصر يفتح `DeliveryManDetailsScreen`.

### الحالات

- **No permission**: رسالة عدم وجود صلاحية.
- **Loading**: CircularProgressIndicator.
- **Empty**: `no_delivery_man_found`.
- **Delete confirmation**: ConfirmationDialogWidget.

## DeliveryMan - AddDeliveryManScreen

**Path**: `lib/features/deliveryman/screens/add_delivery_man_screen.dart`
**Route / Entry Point**: `RouteHelper.addDeliveryMan` / `/add-delivery-man`
**Purpose**: إضافة أو تعديل مندوب توصيل.

### ماذا يظهر للمستخدم

- نموذج بيانات المندوب.
- صورة/ملف شخصي.
- بيانات الاتصال.
- بيانات الهوية أو المركبة حسب التطبيق.

## DeliveryMan - DeliveryManDetailsScreen

**Path**: `lib/features/deliveryman/screens/delivery_man_details_screen.dart`
**Route / Entry Point**: `RouteHelper.deliveryManDetails` / `/delivery-man-details`
**Purpose**: عرض تفاصيل مندوب التوصيل وأدائه/بياناته.

### ماذا يظهر للمستخدم

- بيانات المندوب.
- حالة النشاط.
- معلومات مرتبطة بالطلبات أو الأرباح حسب الموديل.

## Advertisement - AdvertisementListScreen

**Path**: `lib/features/advertisement/screens/advertisement_list_screen.dart`
**Route / Entry Point**: `RouteHelper.advertisementList` / `/advertisement-list`
**Controller**: `AdvertisementController`
**Purpose**: عرض وإدارة إعلانات المتجر.

### ماذا يظهر للمستخدم

- AppBar بعنوان `advertisement_list`.
- Tabs أفقية للحالات إذا توجد بيانات:
  - all.
  - pending.
  - running.
  - approved.
  - expired.
  - denied.
  - paused.
- قائمة إعلانات.
- كل إعلان يعرض:
  - ads id.
  - الحالة.
  - نوع الإعلان.
  - menu إجراءات حسب الحالة.
- زر عائم لإنشاء إعلان إذا القائمة غير فارغة.
- EmptyAdsView إذا لا توجد إعلانات.

### ماذا يستطيع المستخدم أن يفعل

- فلترة الإعلانات حسب الحالة.
- فتح تفاصيل الإعلان.
- إنشاء إعلان جديد.
- تنفيذ إجراءات حسب الحالة، مثل pause/resume/delete أو غيرها حسب `getPopupMenuList`.
- تحميل صفحات إضافية بالتمرير.

### البيانات والمنطق

- عند الفتح:
  - `setStatusIndex(0)`.
  - `getAdvertisementList('1', 'all')`.
- pagination عبر scroll controller.
- `status` النهائي للعرض قد يتحول:
  - approved + active = running.
  - approved + inactive = expired.

### الحالات

- **Loading**: CircularProgressIndicator.
- **Empty**: EmptyAdsView.
- **Pagination**: عند الوصول لآخر القائمة.
- **Action loading**: CustomLoaderWidget لبعض الإجراءات.

## Advertisement - CreateAdvertisementScreen

**Path**: `lib/features/advertisement/screens/create_advertisement_screen.dart`
**Route / Entry Point**: `RouteHelper.createAdvertisement` / `/create-advertisement`
**Purpose**: إنشاء إعلان جديد.

### ماذا يظهر للمستخدم

- نموذج اختيار نوع الإعلان.
- حقول ومرفقات حسب نوع الإعلان.
- معاينة أو اختيار فيديو/صورة حسب widgets.
- أزرار إرسال.

### حالات مهمة

- تحميل/معاينة الفيديو.
- تأكيد الإرسال.
- success bottom sheet بعد الإنشاء.

## Advertisement - AdvertisementDetailsScreen

**Path**: `lib/features/advertisement/screens/advertisement_details_screen.dart`
**Route / Entry Point**: `RouteHelper.advertisementDetails` / `/advertisement-details`
**Purpose**: عرض تفاصيل إعلان وحالته.

### ماذا يظهر للمستخدم

- بيانات الإعلان.
- الحالة.
- المرفقات أو المعاينة.
- سبب الرفض إن وجد.
- إجراءات متاحة حسب الحالة.

## ملاحظات متابعة

- شاشات add/edit للموظفين والمندوبين تحتاج توثيق field-by-field لاحقًا.
- الإعلانات فيها حالات كثيرة، لذلك يجب مراجعة `AdvertisementController.getPopupMenuList` عند توثيق الإجراءات بدقة.
