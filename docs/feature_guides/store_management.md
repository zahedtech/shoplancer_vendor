# شرح Feature: Store Management

هذا الملف يغطي صفحات إدارة المتجر والمنتجات. Feature `store` هو مركز إدارة الكتالوج، الأسعار، المخزون، رابط المتجر، وحالة المنتجات.

## Store - StoreScreen

**Path**: `lib/features/store/screens/store_screen.dart`
**Route / Entry Point**: `RouteHelper.store` / `/store`
**Controller**: `ProfileController`
**Purpose**: عرض متجر البائع كما يظهر للعملاء داخل WebView، مع أزرار مشاركة وفتح الرابط.

### ماذا يظهر للمستخدم

- AppBar باسم المتجر.
- زر تحديث للـ WebView.
- زر مشاركة رابط المتجر.
- زر فتح المتجر في المتصفح الخارجي.
- WebView يعرض رابط المتجر.
- شريط تقدم أعلى الصفحة أثناء تحميل المتجر.
- حالة فارغة إذا لم يتم العثور على رابط المتجر.

### ماذا يستطيع المستخدم أن يفعل

- مشاهدة واجهة متجره العامة.
- تحديث الصفحة.
- مشاركة الرابط.
- فتح الرابط خارج التطبيق.
- الرجوع داخل WebView إذا كان هناك history.

### البيانات والمنطق

- إذا `profile.storeUrl` موجود يستخدم مباشرة.
- إذا غير موجود، يبني الرابط من `store.slug` أو اسم المتجر:
  `https://store.shoplanser.com/{slug-or-name}`
- يحمل profile إذا لم يكن موجودًا.
- يستخدم `flutter_inappwebview` لعرض المتجر.

### الحالات

- **Loading**: CircularProgressIndicator عند تحميل profile، وLinearProgressIndicator أثناء تحميل WebView.
- **Empty**: `store_link_not_found` إذا لا يوجد URL.
- **Retry**: زر إعادة المحاولة يستدعي `_initData`.

### الانتقال

- غالبًا من menu أو روابط إدارة المتجر.
- يفتح المتصفح الخارجي عبر `url_launcher`.

## Store - AllItemsScreen

**Path**: `lib/features/store/screens/all_items_screen.dart`
**Route / Entry Point**: `RouteHelper.allItems` / `/all-items`
**Controller**: `StoreController`, `ProfileController`
**Purpose**: عرض كل منتجات المتجر مع بحث، فلترة، pagination، واختيار متعدد.

### ماذا يظهر للمستخدم

- AppBar بعنوان `all_items`.
- عند selection mode يظهر عدد المنتجات المختارة وأزرار select all وإجراءات جماعية.
- قائمة المنتجات.
- بحث بالاسم.
- بحث بالباركود عبر `BarcodeScannerScreen`.
- فلاتر فئات وسعر/ترتيب حسب widgets المرفقة.
- زر إضافة سريعة أو إضافة منتج حسب مكان الاستخدام.

### ماذا يستطيع المستخدم أن يفعل

- تصفح المنتجات مع pagination.
- البحث باسم المنتج.
- مسح باركود والبحث به.
- اختيار منتجات متعددة.
- تنفيذ إجراءات جماعية على المنتجات المختارة.
- فتح تفاصيل منتج.
- الرجوع مع إعادة الفلاتر للوضع الافتراضي.

### البيانات والمنطق

- يستخدم `StoreController.getItemList`.
- النوع الأساسي `type: all`.
- يستخدم `ProfileController.profileModel.stores[0].module.id` لإرسال `moduleId`.
- يجلب categories عامة عبر HTTP مباشر إلى `AppConstants.globalCategoryUri`.
- يحافظ على `_barcodeSearch` حتى pagination لا يضيع بحث الباركود.

### الحالات

- **Loading**: shimmer أو حالة تحميل من controller.
- **Pagination**: عند الوصول لآخر القائمة يتم جلب الصفحة التالية.
- **Selection mode**: app bar يتغير حسب `storeController.isSelectionMode`.
- **Back**: عند الخروج يستدعي `storeController.resetFilters()`.

### الانتقال

- من menu أو dashboard حسب route.
- إلى تفاصيل المنتج أو شاشة الإضافة السريعة.
- إلى شاشة scanner عند بحث الباركود.

## Store - ProductManagementScreen

**Path**: `lib/features/store/screens/product_management_screen.dart`
**Route / Entry Point**: `RouteHelper.productManagement` / `/product-management`
**Controller**: `StoreController`
**Purpose**: إدارة المنتجات النشطة بسرعة: بحث، باركود، تعديل أسعار، حفظ جماعي، حذف، وتغيير حالة المنتج.

### ماذا يظهر للمستخدم

- AppBar بعنوان إدارة المنتجات.
- زر إضافة منتج.
- هيدر ثابت أعلى القائمة يحتوي:
  - حقل بحث بالاسم أو رقم الباركود.
  - زر بحث داخل الحقل.
  - زر مسح النص.
  - زر فتح/إغلاق كاميرا الباركود.
  - كاميرا barcode scanner عند تفعيلها.
- رسالة إرشادية قبل البحث.
- قائمة المنتجات النشطة المطابقة.
- بطاقات منتجات تحتوي الصورة، الاسم، السعر، المخزون، وأزرار تعديل/حذف/تفعيل.
- شريط حفظ أسفل الشاشة عند وجود أسعار معدلة.

### ماذا يستطيع المستخدم أن يفعل

- البحث باسم المنتج بعد 3 أحرف.
- إدخال رقم باركود يدويًا والبحث به.
- مسح باركود بالكاميرا.
- تعديل سعر المنتج عبر أزرار + و- أو numpad داخلي.
- حفظ كل الأسعار المعدلة دفعة واحدة.
- حذف منتج بعد تأكيد.
- فتح تفاصيل المنتج للتعديل الكامل.
- تغيير حالة المنتج.

### البيانات والمنطق

- البحث النصي يرسل `search`.
- البحث الرقمي/الباركود يرسل `barcode` ويترك `search` فارغًا.
- `_barcodeSearch` يحفظ حالة بحث الباركود أثناء pagination.
- `_updatedPrices` يحفظ الأسعار المرحلية.
- `_editedItems` يحفظ المنتجات التي تغير سعرها.
- الحفظ يستخدم `storeController.updateItemPriceOnly`.
- القائمة تعرض فقط المنتجات ذات `status == 1`.

### الحالات

- **No query**: تظهر رسالة تطلب 3 أحرف أو رقم باركود.
- **Loading**: CircularProgressIndicator عند تحميل النتائج.
- **Empty**: رسالة لا توجد منتجات نشطة مطابقة.
- **Scanner**: تظهر الكاميرا داخل الهيدر وتغلق بعد scan.
- **Unsaved changes**: يظهر شريط حفظ أسفل الشاشة.

### الانتقال

- من route إدارة المنتجات.
- إلى `QuickAddItemScreen` عند زر الإضافة.
- إلى `ItemDetailsScreen` عند تعديل المنتج.

## Store - QuickAddItemScreen

**Path**: `lib/features/store/screens/quick_add_item_screen.dart`
**Entry Point**: من صفحات إدارة المنتجات أو زر إضافة سريع
**Controllers**: `StoreController`, `CategoryController`, `ProfileController`, `SplashController`
**Purpose**: إضافة عدة منتجات بسيطة بسرعة بدون الدخول إلى شاشة المنتج الكاملة.

### ماذا يظهر للمستخدم

- AppBar.
- نموذج إدخال سريع:
  - اسم المنتج.
  - السعر.
  - المخزون.
  - الفئة.
  - صورة اختيارية.
- Numpad داخلي للسعر.
- قائمة منتجات staged لم ترسل بعد.
- زر حفظ الكل.

### ماذا يستطيع المستخدم أن يفعل

- تعبئة منتج سريع.
- اختيار فئة.
- اختيار صورة.
- إضافة المنتج إلى قائمة محلية.
- تكرار العملية لعدة منتجات.
- حذف منتج staged قبل الإرسال.
- إرسال كل المنتجات دفعة واحدة.

### البيانات والمنطق

- `_StagedQuickItem` يمثل منتجًا محليًا قبل الإرسال.
- لا يتم إرسال المنتج عند الضغط على إضافة للقائمة.
- الإرسال يحدث عند `حفظ الكل`.
- المخزون الافتراضي 100 إذا ترك فارغًا.
- يتم تحميل categories عند فتح الصفحة.
- إذا الموديول يحتاج unit/brand/tax يتم تجهيز القوائم من controllers.

### الحالات

- **Validation**:
  - اسم المنتج مطلوب.
  - الفئة مطلوبة.
  - السعر يجب أن يكون أكبر من صفر.
- **Submitting**: كل عنصر staged له status: pending/submitting/success/failed.
- **Image optional**: الصورة اختيارية.

### الانتقال

- من ProductManagement أو AllItems.
- تبقى داخل نفس الشاشة حتى حفظ كل المنتجات أو الرجوع.

## Store - InactiveProductsScreen

**Path**: `lib/features/store/screens/inactive_products_screen.dart`
**Route / Entry Point**: `RouteHelper.inactiveProducts` / `/inactive-products`
**Controller**: `StoreController`
**Purpose**: عرض وإدارة المنتجات غير النشطة.

### ماذا يظهر للمستخدم

- AppBar بعنوان المنتجات غير النشطة.
- حقل بحث.
- زر فتح كاميرا الباركود.
- كاميرا scanner داخل الهيدر عند تفعيلها.
- قائمة المنتجات غير النشطة.
- حالة فارغة إذا لا توجد منتجات غير نشطة.

### ماذا يستطيع المستخدم أن يفعل

- البحث في المنتجات غير النشطة.
- مسح باركود للعثور على منتج.
- فتح تفاصيل المنتج.
- حذف المنتج.
- تغيير حالة المنتج حسب أزرار القائمة.

### البيانات والمنطق

- عند فتح الصفحة يستدعي `getItemList` مع `type: inactive`.
- بعد scan يبحث أولًا في القائمة الحالية.
- إذا لم يجد المنتج، يستدعي service مباشرة مع `barcode`.
- يعرض فقط العناصر ذات `status == 0`.

### الحالات

- **Loading**: انتظار `itemList`.
- **Empty**: رسالة لا توجد منتجات غير نشطة.
- **Scanner**: تغلق الكاميرا بعد العثور على المنتج.
- **Not found**: snackbar إذا لم يتم العثور على باركود.

### الانتقال

- من قائمة إدارة المنتجات أو menu.
- إلى تفاصيل المنتج.

## StoreController - دور عام

**Path**: `lib/features/store/controllers/store_controller.dart`

`StoreController` هو controller المركزي لميزات المتجر. يحتوي على:

- `itemList`, `itemSize`, `offset` لقوائم المنتجات.
- حالات loading للمنتجات، المنتجات الموصى بها، best seller، وغيرها.
- قوائم attributes, units, brands, variations.
- حالة الفلاتر: النوع، الفئة، البحث.
- صور المنتج والمتجر.
- جداول عمل المتجر.
- اختيار addons وVAT tax.
- عمليات تحميل وتحديث وحذف المنتجات.

عند توثيق أي صفحة داخل `store` يجب الرجوع لهذا controller لمعرفة:

- ما القائمة التي تعرضها الصفحة.
- ما نوع `type` المستخدم في `getItemList`.
- هل الصفحة تستخدم pagination.
- هل الصفحة تغير حالة المنتج أو سعره أو بياناته.

## ملاحظات متابعة

- يجب توثيق `add_item_screen.dart` بملف مستقل لأنه شاشة كبيرة ومعقدة.
- يجب توثيق `store_settings_screen.dart` و`store_edit_screen.dart` كجزء إعدادات المتجر.
- يجب توثيق إدارة الأسعار `product_price_management_screen.dart` بشكل مستقل لأنها رحلة تشغيلية منفصلة.
