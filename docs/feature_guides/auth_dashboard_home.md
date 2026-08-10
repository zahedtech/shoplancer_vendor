# شرح Features: Auth, Dashboard, Home

هذا الملف هو أول جزء من شرح المشروع صفحة صفحة. يغطي رحلة البداية: تسجيل الدخول، الدخول إلى الـ dashboard، ثم الصفحة الرئيسية.

## Auth - SignInScreen

**Path**: `lib/features/auth/screens/sign_in_screen.dart`
**Route / Entry Point**: `RouteHelper.signIn` / `/sign-in`
**Controller**: `AuthController`
**Purpose**: تسجيل دخول صاحب المتجر أو الموظف إلى تطبيق البائع.

### ماذا يظهر للمستخدم

- شعار التطبيق.
- عنوان `sign_in`.
- اختيار نوع المستخدم:
  - صاحب المتجر `vendor_owner`.
  - موظف `vendor_employee`.
- حقل رقم الهاتف مع country code picker.
- حقل كلمة المرور.
- رابط/زر `forgot_password` يفتح دعم WhatsApp.
- زر تسجيل الدخول.
- رابط التسجيل كـ vendor إذا كان `toggleStoreRegistration` مفعلًا في config.
- زر تواصل مع الدعم عبر WhatsApp.
- Bottom sheet نجاح تسجيل المتجر إذا كان flag التسجيل محفوظًا في shared preferences.

### ماذا يستطيع المستخدم أن يفعل

- اختيار الدخول كصاحب متجر أو موظف.
- إدخال رقم الهاتف وكلمة المرور.
- تسجيل الدخول.
- فتح صفحة تسجيل متجر جديد إذا كانت مفعلة.
- التواصل مع الدعم.

### البيانات والمنطق

- يقرأ رقم الهاتف وكلمة المرور المحفوظة من `AuthController`.
- يحدد `vendorTypeIndex` حسب المستخدم السابق: owner أو employee.
- عند الضغط على تسجيل الدخول:
  - يتحقق من الحقول.
  - يرسل `phone`, `countryCode`, `password`, و`type` إلى `AuthController.login`.
  - عند النجاح يحفظ بيانات الدخول.
  - يحمل profile من `ProfileController` أو `TaxiProfileController` حسب نوع الموديول.
  - يرجع إلى route البداية `RouteHelper.getInitialRoute()`.

### الحالات

- **Loading**: زر تسجيل الدخول يستخدم `authController.isLoading`.
- **Validation**:
  - رقم الهاتف مطلوب.
  - كلمة المرور مطلوبة.
  - كلمة المرور يجب أن تكون بطول مقبول.
- **Error**: عند فشل login يظهر snackbar برسالة الباك إند.
- **Optional**: تسجيل متجر جديد يظهر فقط إذا config يسمح بذلك.

### الانتقال

- من splash أو أي session منتهية إلى sign in.
- إلى store registration عبر `RouteHelper.getRestaurantRegistrationRoute()`.
- إلى initial route بعد login ناجح.

## Auth - StoreRegistrationScreen

**Path**: `lib/features/auth/screens/store_registration_screen.dart`
**Route / Entry Point**: `RouteHelper.restaurantRegistration` / `/restaurant-registration`
**Controller**: `AuthController`
**Purpose**: تسجيل متجر جديد وتجهيز بياناته الأساسية قبل اعتماد الدخول.

### ماذا يظهر للمستخدم

هذه الصفحة طويلة ومتعددة الأقسام. حسب الكود الحالي تحتوي على حقول وواجهات مرتبطة بـ:

- بيانات المتجر بلغات متعددة.
- العنوان والموقع.
- معلومات صاحب المتجر.
- الهاتف والبريد وكلمة المرور.
- بيانات ضريبية أو TIN عند الحاجة.
- صور المتجر مثل الشعار والغلاف.
- أوقات التحضير أو التوصيل.
- إعدادات module/category حسب config.

### ماذا يستطيع المستخدم أن يفعل

- إدخال بيانات المتجر.
- اختيار صور من الجهاز.
- تعبئة بيانات المالك.
- إدخال بيانات التوثيق الضريبي إن كانت مطلوبة.
- إرسال طلب تسجيل المتجر.

### البيانات والمنطق

- يعتمد على `AuthController` لحفظ حالة النموذج والصور وملفات TIN.
- يعتمد على `SplashController.configModel` لمعرفة إعدادات التسجيل المتاحة.
- يستخدم controllers نصية متعددة لأن الاسم والعنوان قد يكونان متعددين حسب اللغات.

### الحالات

- **Validation**: الحقول المطلوبة يجب تعبئتها قبل الإرسال.
- **Files/Images**: قد يحتاج المستخدم لاختيار ملفات أو صور.
- **Config dependent**: بعض الأقسام تظهر أو تختفي حسب config.
- **Success**: بعد تسجيل ناجح يمكن إظهار bottom sheet نجاح في شاشة الدخول.

### الانتقال

- من شاشة تسجيل الدخول عبر رابط `join_as vendor`.
- بعد النجاح يرجع المستخدم إلى شاشة تسجيل الدخول أو مسار الاعتماد حسب استجابة النظام.

## Dashboard - DashboardScreen

**Path**: `lib/features/dashboard/screens/dashboard_screen.dart`
**Route / Entry Point**: `RouteHelper.initial` أو `RouteHelper.main`
**Controllers**: `AuthController`, `SubscriptionController`, `ProfileController`
**Purpose**: الحاوية الرئيسية للتطبيق بعد الدخول، وتدير التبويبات والتنقل اليومي.

### ماذا يظهر للمستخدم

على الموبايل:

- Bottom navigation فيه:
  - Home.
  - Orders أو Trips حسب نوع الموديول.
  - زر عائم في الوسط لإنشاء طلب POS.
  - Wallet.
  - Menu.
- PageView داخلي يعرض الشاشة المختارة.
- Showcase تعليمي لأول استخدام.

على الديسكتوب:

- التطبيق لا يعتمد على نفس bottom navigation.
- route البداية يذهب مباشرة إلى `DesktopPosScreen` حسب `RouteHelper`.

### ماذا يستطيع المستخدم أن يفعل

- الانتقال إلى الصفحة الرئيسية.
- فتح الطلبات.
- فتح شاشة إنشاء طلب POS.
- فتح المحفظة.
- فتح القائمة.
- الرجوع بزر back إلى Home قبل الخروج من التطبيق.

### البيانات والمنطق

- `_screens` تتغير حسب `AuthController.getModuleType()`:
  - إذا `rental`: home/trips/provider/menu مختلفة.
  - غير ذلك: `HomeScreen`, `OrderHistoryScreen`, `PosScreen`, `WalletScreen`.
- يستخدم `SubscriptionController` لإظهار trial end bottom sheet ومنع الانتقال إذا انتهت التجربة.
- يستخدم `ProfileController` لإظهار تحذير المنتجات قليلة المخزون.

### الحالات

- **Showcase**: يظهر مرة واحدة ويحفظ `showcase_shown` في shared preferences.
- **Trial end**: قد يعترض التنقل ويظهر bottom sheet.
- **Low stock**: يظهر تحذير إذا profile يحتوي `outOfStockCount`.
- **Back button**: إذا المستخدم ليس في Home يرجعه إلى Home، وإذا هو في Home يحتاج ضغطتين للخروج.

### الانتقال

- بعد login ناجح أو splash.
- إلى menu عبر `Get.to`.
- إلى صفحات داخلية عبر PageView وليس routes منفصلة دائمًا.

## Home - HomeScreen

**Path**: `lib/features/home/screens/home_screen.dart`
**Entry Point**: التبويب الأول داخل `DashboardScreen`
**Controllers**: `ProfileController`, `OrderController`, `PaymentController`, `NotificationController`, `AuthController`
**Purpose**: عرض ملخص تشغيل المتجر والطلبات الجارية والتنبيهات المهمة.

### ماذا يظهر للمستخدم

- AppBar باسم المتجر.
- زر إشعارات مع indicator عند وجود إشعارات.
- Pull to refresh.
- QR أو بطاقة المتجر عبر `StoreQrWidget`.
- تحليلات الأعمال عبر `BusinessAnalyticsWidget` إذا صلاحية wallet مفعلة.
- قسم الطلبات الجارية.
- أزرار فلترة الطلبات حسب الحالة.
- قائمة الطلبات الحالية أو shimmer أثناء التحميل.

### ماذا يستطيع المستخدم أن يفعل

- فتح الإشعارات.
- سحب الشاشة لتحديث profile والطلبات والمحفظة والإشعارات.
- تبديل حالة الطلبات المعروضة من أزرار الحالات.
- فتح تفاصيل الطلب من عنصر الطلب.
- التعامل مع صلاحيات notification وbattery optimization عند تفعيل التحذيرات.

### البيانات والمنطق

- عند `initState` تنفذ `_loadData`:
  - تحميل profile إذا غير موجود أو عند refresh.
  - تحميل wallet info.
  - تحميل current orders.
  - تحميل notifications.
- `checkPermission` يراجع صلاحية الإشعارات وbattery optimization.
- `OrderController.runningOrders` يحتوي مجموعات الطلبات حسب الحالة.
- يتم اختيار القائمة المعروضة حسب `orderController.orderIndex`.

### الحالات

- **Loading**: يظهر `OrderShimmerWidget` عند عدم تحميل الطلبات.
- **Empty**: يظهر `no_order_found` إذا لا توجد طلبات في الحالة المختارة.
- **No permission**: إذا module permission للطلبات غير مفعلة، تظهر رسالة عدم وجود صلاحية.
- **Notification permission**: يتم تحديث حالة الإشعارات في `AuthController`.
- **Battery optimization**: يتم تحديث background notification state في `ProfileController`.

### الانتقال

- من Dashboard tab الأول.
- إلى `NotificationScreen` عند الضغط على زر الإشعارات.
- إلى تفاصيل الطلب عبر عناصر `OrderWidget`.

## رحلة البداية المختصرة

1. يفتح المستخدم التطبيق.
2. splash يقرر هل هناك جلسة محفوظة.
3. إذا لا توجد جلسة، تظهر `SignInScreen`.
4. المستخدم يختار owner أو employee ويدخل الهاتف وكلمة المرور.
5. عند النجاح، يتم تحميل profile.
6. التطبيق يفتح `DashboardScreen`.
7. أول تبويب هو `HomeScreen`.
8. Home تعرض QR، التحليلات، الطلبات الجارية، والإشعارات.

## ملاحظات متابعة

- يجب لاحقًا توثيق `SplashScreen` بشكل مستقل لأنه يقرر مسار الدخول الأول.
- يجب توثيق `MenuScreen` لأنه نقطة دخول لمعظم features.
- يجب توثيق رحلة POS في ملف مستقل لأنها رحلة P1 كبيرة.
