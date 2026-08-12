# دليل صفحات القائمة وموديول التأجير

هذا الملف يغطي الصفحات التي لم تكن داخلة في الجرد الأول: القائمة العامة `menu` وموديول التأجير `rental_module`.

## MenuScreen

المسار: `lib/features/menu/screens/menu_screen.dart`

### ماذا تفعل الصفحة؟

صفحة القائمة الرئيسية لكل الاختصارات التشغيلية خارج التبويبات الأساسية. تجمع روابط إدارة المنتجات، الأسعار، المخزون، الفئات، البراندات، البنرات، روابط التواصل، مندوبي التوصيل، الموظفين، إعدادات المتجر، المحفظة، الاشتراك، الملف الشخصي، والإعدادات.

### الاعتماديات

- `ProfileController`: لجلب المتجر الحالي والصلاحيات.
- `AuthController`: لمعرفة نوع المستخدم وحالة تسجيل الدخول.
- `SubscriptionController`: للتحقق من trial/end modal عند فتح الاشتراك.
- `SplashController`: لقراءة إعدادات الموديول والميزات المفعلة.
- `RouteHelper`: لتوليد routes لكل عنصر.
- `MenuButtonWidget`: لتنفيذ التنقل أو إجراءات خاصة مثل logout/language.

### السلوك المتوقع

- بناء قائمة عناصر حسب صلاحيات المستخدم والموديول.
- إخفاء العناصر غير المسموحة للموظف.
- تمرير كائن `Store` للصفحات التي تحتاجه مثل إعدادات المتجر وطرق الدفع.
- فتح الاشتراك مع مراعاة modal انتهاء الفترة التجريبية.
- دعم تسجيل الخروج وتغيير اللغة من عناصر القائمة.

### فحص مهم

- حساب owner يشاهد كل عناصر الإدارة المسموحة.
- حساب employee يرى فقط العناصر الموجودة في `modulePermission`.
- متجر بدون بيانات profile لا يكسر عناصر تحتاج `store`.
- الضغط على كل عنصر يفتح route صحيح.
- عناصر معلقة أو commented في الكود لا تظهر في الواجهة.

## عناصر القائمة الفعلية

هذه هي العناصر التي يبنيها `MenuScreen` حالياً داخل `menuList`، مع شروط ظهورها والصفحة التي تقود إليها.

### إدارة المنتجات

العنوان في القائمة: `إدارة المنتجات`

المسار البرمجي:

- route: `RouteHelper.getProductManagementRoute()`
- الشاشة: `lib/features/store/screens/product_management_screen.dart`

شرط الظهور:

- `modulePermission.item == true`

شرط الحجب:

- يكون العنصر blocked إذا `store.itemSection == false`.

ماذا تفعل؟

تفتح صفحة إدارة المنتجات السريعة التي تركّز على البحث، الفلاتر، الأسعار، المخزون، والباركود المثبت أعلى الشاشة.

فحص مهم:

- تظهر فقط لمن لديه صلاحية item.
- إذا عطّل الأدمن item section تظهر رسالة `this_feature_is_blocked_by_admin`.
- البحث النصي والبحث بالباركود يعملان من نفس الصفحة.

### تعديل الأسعار السريع

العنوان في القائمة: `تعديل الأسعار السريع`

المسار البرمجي:

- route: `RouteHelper.getProductPriceUpdateCategoriesRoute()`
- الشاشة الأولى: `lib/features/store/screens/product_price_category_selection_screen.dart`
- الشاشة التالية: `lib/features/store/screens/product_price_management_screen.dart`

شرط الظهور:

- `modulePermission.item == true`

شرط الحجب:

- blocked إذا `store.itemSection == false`.

ماذا تفعل؟

تبدأ باختيار فئة، ثم تعرض منتجات تلك الفئة لتعديل السعر مباشرة بدون الدخول إلى شاشة تعديل المنتج الكاملة.

فحص مهم:

- اختيار فئة ثم تعديل سعر منتج.
- السعر يتحدث محلياً بعد نجاح API.
- فشل API لا يغير السعر في الواجهة.

### المنتجات غير النشطة

العنوان في القائمة: `المنتجات غير النشطة`

المسار البرمجي:

- route: `RouteHelper.getInactiveProductsRoute()`
- الشاشة: `lib/features/store/screens/inactive_products_screen.dart`

شرط الظهور:

- `modulePermission.item == true`

شرط الحجب:

- blocked إذا `store.itemSection == false`.

ماذا تفعل؟

تعرض المنتجات المعطلة أو غير النشطة حتى يستطيع صاحب المتجر مراجعتها أو إعادة تفعيلها.

فحص مهم:

- تعطيل منتج ثم ظهوره هنا.
- إعادة التفعيل ثم اختفاؤه من القائمة.

### كل المنتجات

العنوان في القائمة: `all_items`

المسار البرمجي:

- route: `RouteHelper.getAllItemsRoute()`
- الشاشة: `lib/features/store/screens/all_items_screen.dart`

شرط الظهور:

- `modulePermission.item == true`
- لا يظهر إذا كان `store.module.moduleType == 'ecommerce'`.

شرط الحجب:

- blocked إذا `store.itemSection == false`.

ماذا تفعل؟

تعرض قائمة المنتجات العامة، وهي أوسع من شاشة إدارة المنتجات السريعة في بعض الموديولات.

فحص مهم:

- لا تظهر في ecommerce.
- تظهر في food أو الموديولات الأخرى غير ecommerce.
- فتح تفاصيل منتج من القائمة.

### الفئات

العنوان في القائمة: `categories`

المسار البرمجي:

- route: `RouteHelper.getCategoriesRoute()`
- الشاشة: `lib/features/category/screens/category_screen.dart`
- صفحات مرتبطة:
  - `lib/features/category/screens/sub_category_screen.dart`
  - `lib/features/category/screens/category_product_screen.dart`

شرط الظهور:

- `modulePermission.category == true`

ماذا تفعل؟

تفتح إدارة الفئات. من خلالها يستطيع المستخدم رؤية الفئات الرئيسية، الدخول إلى الفئات الفرعية، ثم رؤية المنتجات المرتبطة بفئة معينة.

شرح الرحلة:

```text
MenuScreen
  -> CategoryScreen
  -> SubCategoryScreen
  -> CategoryProductScreen
  -> ItemDetailsScreen أو Add/Edit Item حسب الإجراء
```

فحص مهم:

- ظهور الفئات لصاحب صلاحية category فقط.
- فتح فئة فيها sub categories.
- فتح فئة بدون sub categories.
- عرض منتجات الفئة.
- الرجوع من منتجات الفئة يحافظ على مكان المستخدم في القائمة.

### الماركات / البراند

العنوان في القائمة: `الماركات`

المسار البرمجي:

- route: `RouteHelper.getBrandsRoute()`
- الشاشة: `lib/features/store/screens/brand_screen.dart`
- صفحة مرتبطة: `lib/features/store/screens/brand_product_screen.dart`

شرط الظهور:

- `modulePermission.category == true`

ماذا تفعل؟

تعرض قائمة البراندات، ثم تسمح بفتح المنتجات التابعة لبراند محدد.

شرح الرحلة:

```text
MenuScreen
  -> BrandScreen
  -> BrandProductScreen
  -> ItemDetailsScreen
```

فحص مهم:

- البراندات تظهر مع صلاحية category.
- فتح براند فيه منتجات.
- فتح براند بدون منتجات.
- منتجات البراند تتوافق مع المنتج المعروض في تفاصيله.

### المنتجات قليلة المخزون

العنوان في القائمة: `low_stock`

المسار البرمجي:

- route: `RouteHelper.getLowStockRoute()`
- الشاشة: `lib/features/store/screens/low_stock_screen.dart`

شرط الظهور:

- يظهر إذا `store.module.moduleType != 'food'`.

ماذا تفعل؟

تعرض المنتجات التي وصلت إلى حد مخزون منخفض. هذا مفيد خصوصاً للمتاجر غير الغذائية أو ecommerce.

فحص مهم:

- لا يظهر في food.
- يظهر في ecommerce أو الموديولات الأخرى.
- تحديث مخزون منتج يزيله من القائمة إذا صار فوق الحد.

### المنتجات المعلقة

العنوان في القائمة: `pending_item`

المسار البرمجي:

- route: `RouteHelper.getPendingItemRoute()`
- الشاشة: `lib/features/store/screens/pending_item_screen.dart`
- صفحة مرتبطة: `lib/features/store/screens/pending_item_details_screen.dart`

شرط الظهور:

- `modulePermission.item == true`
- لا يظهر إذا كان `store.module.moduleType == 'ecommerce'`.

ماذا تفعل؟

تعرض منتجات بانتظار الموافقة أو المراجعة حسب سياسات النظام.

فحص مهم:

- تظهر المنتجات pending.
- فتح تفاصيل منتج معلق.
- ظهور سبب الرفض أو حالة الاعتماد عند توفرها.

### الإضافات

العنوان في القائمة: `addons`

المسار البرمجي:

- route: `RouteHelper.getAddonsRoute()`
- الشاشة: `lib/features/addon/screens/addon_screen.dart`
- صفحة مرتبطة: `lib/features/addon/screens/add_addon_screen.dart`

شرط الظهور:

- `store.module.moduleType == 'food'`
- `modulePermission.addon == true`

ماذا تفعل؟

إدارة إضافات الطعام مثل الصوصات أو الخيارات التي يمكن ربطها بالمنتجات.

فحص مهم:

- تظهر فقط في food.
- إضافة addon جديد.
- تعديل addon موجود.
- حذف addon مرتبط بمنتج يجب التعامل معه بوضوح من API.

### البنرات

العنوان في القائمة: `banner`

المسار البرمجي:

- route: `RouteHelper.getBannerListRoute()`
- الشاشة: `lib/features/banner/screens/banner_list_screen.dart`
- صفحة مرتبطة: `lib/features/banner/screens/add_banner_screen.dart`

شرط الظهور:

- `modulePermission.banner == true`

ماذا تفعل؟

إدارة البنرات التسويقية التي تظهر للعملاء.

فحص مهم:

- إضافة بنر بصورة.
- تعديل بنر.
- تغيير حالة بنر.
- ربط بنر بمنتج أو فئة إذا كانت الشاشة تدعم ذلك.

### السوشيال ميديا

العنوان في القائمة: `social_media`

المسار البرمجي:

- route: `RouteHelper.getSocialMediaRoute()`
- الشاشة: `lib/features/store/screens/social_media_screen.dart`

شرط الظهور:

- يظهر دائماً تقريباً بعد بناء بيانات القائمة، ولا يعتمد على صلاحية واضحة في الكود الحالي.

ماذا تفعل؟

إدارة روابط حسابات التواصل الاجتماعي الخاصة بالمتجر.

فحص مهم:

- حفظ رابط صحيح.
- رابط فارغ أو غير صالح.
- ظهور الروابط بعد الرجوع للصفحة.

### مندوبي التوصيل

العنوان في القائمة: `delivery_man`

المسار البرمجي:

- route: `RouteHelper.getDeliveryManRoute()`
- الشاشة: `lib/features/deliveryman/screens/delivery_man_screen.dart`
- صفحات مرتبطة:
  - `lib/features/deliveryman/screens/add_delivery_man_screen.dart`
  - `lib/features/deliveryman/screens/delivery_man_details_screen.dart`

شرط الظهور:

- `modulePermission.deliveryman == true` أو `modulePermission.deliverymanList == true`
- `store.selfDeliverySystem == 1`

شروط الاشتراك:

- إذا `store.storeBusinessModel != 'subscription'` يظهر مباشرة.
- إذا `store.storeBusinessModel == 'subscription'` يحتاج `profile.subscription.selfDelivery == 1`.
- إذا الاشتراك لا يدعم self delivery يمكن أن يظهر كـ not subscribed حسب الحالة.

ماذا تفعل؟

إدارة مندوبي التوصيل المحليين للمتجر.

فحص مهم:

- متجر self delivery مفعّل.
- متجر self delivery غير مفعّل.
- اشتراك يدعم self delivery.
- اشتراك لا يدعم self delivery ويعرض رسالة `you_have_no_available_subscription`.

### إدارة الموظفين

العنوان في القائمة: `إدارة الموظفين`

المسار البرمجي:

- route: `RouteHelper.getEmployeeRoute()`
- الشاشة: `lib/features/employee/screens/employee_screen.dart`
- صفحة مرتبطة: `lib/features/employee/screens/add_employee_screen.dart`

شرط الظهور:

- `modulePermission.storeSetup == true`

ماذا تفعل؟

إدارة موظفي المتجر وصلاحياتهم.

فحص مهم:

- إضافة موظف.
- تعديل صلاحيات موظف.
- موظف بصلاحيات محدودة يرى قائمة مختصرة.

### إعدادات المتجر

العنوان في القائمة:

- `restaurant_config` إذا `showRestaurantText == true`
- `store_config` إذا `showRestaurantText == false`

المسار البرمجي:

- route: `RouteHelper.getStoreSettingsRoute(store)`
- الشاشة: `lib/features/store/screens/store_settings_screen.dart`

شرط الظهور:

- `modulePermission.storeSetup == true`

ماذا تفعل؟

تدير إعدادات تشغيل المتجر مثل التوصيل، الاستلام، الطلب المجدول، والوصفات أو الخيارات الخاصة بالموديول.

فحص مهم:

- تمرير `store` غير null.
- حفظ toggles.
- اختلاف النص بين restaurant/store حسب config.

### طرق الدفع

العنوان في القائمة: `payment_method`

المسار البرمجي:

- route داخل `MenuModel` فارغ.
- `isPaymentMethods == true`
- يفتح مباشرة: `PaymentMethodsScreen(store: store)`
- الشاشة: `lib/features/store/screens/payment_methods_screen.dart`

شرط الظهور:

- داخل block `modulePermission.storeSetup == true`

ماذا تفعل؟

تدير طرق الدفع المتاحة للمتجر.

فحص مهم:

- إذا `store == null` تظهر رسالة `store_data_not_loaded`.
- فتح الصفحة مباشرة عبر `Get.to`.
- حفظ تفعيل/تعطيل طرق الدفع.

### المحفظة

العنوان في القائمة: `المحفظة`

المسار البرمجي:

- route: `RouteHelper.getPrepaidWalletRoute()`
- الشاشة: `lib/features/payment/screens/prepaid_wallet_screen.dart`

شرط الظهور:

- `modulePermission.wallet == true`

ماذا تفعل؟

تفتح محفظة المتجر المسبقة أو صفحة الرصيد المرتبطة بالدفع.

فحص مهم:

- تظهر لصاحب صلاحية wallet.
- عرض الرصيد.
- فتح سجل المدفوعات أو السحوبات عند توفر أزرار داخل الصفحة.

### خطة العمل / الاشتراك

العنوان في القائمة: `my_business_plan`

المسار البرمجي:

- route: `RouteHelper.getMySubscriptionRoute()`
- الشاشة: `lib/features/subscription/screens/my_subscription_screen.dart`

شرط الظهور:

- `modulePermission.businessPlan == true`
- لا تظهر على iOS بسبب `!GetPlatform.isIOS`.

ماذا تفعل؟

تعرض خطة العمل أو الاشتراك الحالي والمعاملات المرتبطة به.

فحص مهم:

- تظهر على Android.
- لا تظهر على iOS.
- فتح الصفحة لا يخضع لنفس trial modal العام لأنها تمر مباشرة إذا route هو `RouteHelper.mySubscription`.

### تعديل الملف الشخصي

العنوان في القائمة: `edit_profile`

المسار البرمجي:

- route: `RouteHelper.getUpdateProfileRoute()`
- الشاشة: `lib/features/profile/screens/update_profile_screen.dart`

شرط الظهور:

- يظهر دائماً.

ماذا تفعل؟

تعديل بيانات صاحب الحساب أو الموظف وصورة الملف الشخصي.

فحص مهم:

- تظهر صورة profile داخل زر القائمة.
- owner يأخذ صورة `profileModel.imageFullUrl`.
- employee يأخذ صورة `profileModel.employeeInfo.imageFullUrl`.

### الإعدادات

العنوان في القائمة: `settings`

المسار البرمجي:

- route: `RouteHelper.getSettingRoute()`
- الشاشة: `lib/features/profile/screens/setting_screen.dart`

شرط الظهور:

- يظهر دائماً.

ماذا تفعل؟

إعدادات الحساب والتطبيق مثل الإشعارات وتحذير المخزون المنخفض وربما خيارات أخرى حسب الشاشة.

فحص مهم:

- تغيير إعدادات الإشعارات.
- إخفاء تحذير low stock.
- أي action حساس مثل حذف الحساب يحتاج confirmation.

### الدعم الفني

العنوان في القائمة: `الدعم الفني`

المسار البرمجي:

- route: `https://wa.me/+201036860264`
- `isWhatsApp == true`

شرط الظهور:

- يظهر دائماً.

ماذا يفعل؟

يفتح واتساب خارجي عبر `url_launcher` إذا كان الرابط قابل للفتح.

فحص مهم:

- جهاز عليه واتساب.
- جهاز بدون واتساب.
- `canLaunchUrl` يرجع false ولا يحدث crash.

## صفحات موجودة لكن غير ظاهرة حالياً من القائمة

هذه الصفحات موجودة في المشروع أو موثقة، لكن عناصرها داخل `MenuScreen` معلّقة حالياً بتعليقات:

- `RouteHelper.getCouponRoute()` -> `coupon_screen.dart`
- `RouteHelper.getReportsRoute()` -> `reports_screen.dart`
- `RouteHelper.getPosRoute()` -> `pos_screen.dart`
- `RouteHelper.getStoreSectionsRoute()` -> `store_sections_screen.dart`
- `RouteHelper.getStoreRoute()` -> `store_screen.dart`

ملاحظة:

هذه ليست صفحات ناقصة، لكنها غير متاحة من القائمة الحالية بسبب التعليقات في الكود. إذا أردنا إرجاعها للقائمة لاحقاً يجب مراجعة الصلاحيات والاشتراك ونوع الموديول قبل فك التعليق.

## MenuButtonWidget

المسار: `lib/features/menu/widgets/menu_button_widget.dart`

### ماذا يفعل؟

عنصر زر القائمة. لا يكتفي بعرض route، بل يحتوي منطق خاص لبعض الأزرار:

- فتح `PaymentMethodsScreen` مباشرة مع تمرير المتجر.
- تسجيل الخروج أو الانتقال لتسجيل الدخول.
- فتح اختيار اللغة.
- التعامل مع صفحة الاشتراك وتجربة trial.

### فحص مهم

- زر logout لمستخدم مسجل.
- زر login لمستخدم غير مسجل.
- زر language يغير اللغة ويحفظها.
- زر subscription يحترم trial modal.

## Rental Module Overview

المسار العام: `lib/features/rental_module`

### ما هو هذا الموديول؟

جزء خاص بموديول التأجير أو taxi/rental داخل التطبيق. يحتوي شاشات ومجلدات controllers/services/repositories منفصلة عن موديول المتجر الغذائي/التجاري.

### حالة التنفيذ الحالية

الشاشات موجودة، والـ controllers/services/repositories موجودة كهيكل، لكن عدة repositories داخل `rental_module` ترمي `UnimplementedError` في عمليات `add/get/getList/update/delete`. هذا يعني أن التوثيق هنا يصف مسؤولية الشاشة المتوقعة والهيكل الحالي، وليس رحلة network مكتملة لكل شاشة.

## TaxiHomeScreen

المسار: `lib/features/rental_module/home/screens/taxi_home_screen.dart`

### ماذا تفعل الصفحة؟

الصفحة الرئيسية لموديول التأجير. يفترض أن تعرض ملخص الأداء أو الرحلات/الحجوزات أو معلومات تشغيلية خاصة بمزود خدمة التأجير.

### الاعتماديات

- `TaxiProfileController`
- `TaxiBannerController`
- controllers خاصة بالرحلات أو التقارير عند تفعيلها.

### فحص مهم

- فتح الصفحة عندما يكون module type خاص بالتأجير.
- حالة بيانات profile غير محملة.
- ظهور widgets بدون data حقيقية.
- الرجوع والتنقل إلى القائمة أو تفاصيل الرحلات.

## TaxiMenuScreen

المسار: `lib/features/rental_module/menu/screens/taxi_menu_screen.dart`

### ماذا تفعل الصفحة؟

قائمة خاصة بموديول التأجير. وظيفتها تشبه `MenuScreen` لكن بعناصر مناسبة للـ rental مثل الرحلات، المزود، المحادثات، التقارير، والإعدادات الخاصة.

### فحص مهم

- عناصر القائمة المناسبة للتأجير فقط.
- عدم ظهور عناصر متجر الطعام/المنتجات إذا كانت غير مناسبة.
- routes الخاصة بالـ taxi تعمل بدون تداخل مع routes العادية.

## TaxiChatScreen

المسار: `lib/features/rental_module/chat/screens/taxi_chat_screen.dart`

### ماذا تفعل الصفحة؟

واجهة محادثة خاصة بموديول التأجير. تستخدم نماذج ورسائل taxi منفصلة عن chat العادي.

### الاعتماديات

- `TaxiChatController`
- `TaxiChatService`
- `TaxiChatRepository`
- `TaxiMessageModel`

### حالة network

`TaxiChatRepository` موجود لكنه يحتوي methods غير منفذة حالياً. لذلك أي شاشة تعتمد على بيانات حقيقية من هذا repository تحتاج استكمال API قبل اعتبارها production-ready.

### فحص مهم

- فتح الشاشة بدون crash.
- حالة الرسائل الفارغة.
- محاولة تحميل بيانات حقيقية بعد تنفيذ repository لاحقاً.

## ProviderScreen

المسار: `lib/features/rental_module/provider/screens/provider_screen.dart`

### ماذا تفعل الصفحة؟

تعرض أو تدير بيانات مزود خدمة التأجير. يمكن اعتبارها profile/operations screen خاصة بمزود rental.

### الاعتماديات

- `ProviderController`
- `ProviderService`
- `ProviderRepository`

### حالة التنفيذ

`ProviderRepository` موجود كهيكل، لكن عمليات CRUD الأساسية غير منفذة وتحتاج endpoints واضحة.

### فحص مهم

- فتح الصفحة بدون بيانات.
- عرض بيانات provider عند توفرها.
- أي زر تعديل يجب ألا يستدعي method غير منفذة بدون معالجة.

## TripHistoryScreen

المسار: `lib/features/rental_module/trips/screens/trip_history_screen.dart`

### ماذا تفعل الصفحة؟

تعرض سجل رحلات أو حجوزات التأجير.

### الاعتماديات

- `TripController`
- `TripService`
- `TripRepository`

### حالة التنفيذ

`TripRepository` لا ينفذ `getList` حالياً، لذلك سجل الرحلات يحتاج ربط API قبل الفحص النهائي.

### فحص مهم

- قائمة فارغة.
- pagination بعد توفر API.
- فلترة الرحلات حسب الحالة أو التاريخ إن أضيفت.
- فتح تفاصيل رحلة.

## TripDetailsScreen

المسار: `lib/features/rental_module/trips/screens/trip_details_screen.dart`

### ماذا تفعل الصفحة؟

تعرض تفاصيل رحلة واحدة: العميل، المركبة أو الخدمة، الحالة، السعر، الوقت، والعنوان أو المسار حسب بيانات الـ rental.

### فحص مهم

- فتح التفاصيل من سجل الرحلات.
- رحلة غير موجودة أو id غير صالح.
- حالة trip مختلفة: pending, accepted, ongoing, completed, canceled.
- أي إجراء على الرحلة يجب أن يكون مربوطاً بـ API منفذ.

## Controllers وطبقات rental الموجودة

### Controllers

- `TaxiBannerController`
- `TaxiChatController`
- `TaxiCouponController`
- `DriverController`
- `TaxiProfileController`
- `ProviderController`
- `TaxiReportController`
- `TripController`

### Services

- `TaxiBannerService`
- `TaxiChatService`
- `TaxiCouponService`
- `DriverService`
- `TaxiProfileService`
- `ProviderService`
- `TaxiReportService`
- `TripService`

### Repositories

- `TaxiBannerRepository`
- `TaxiChatRepository`
- `TaxiCouponRepository`
- `DriverRepository`
- `TaxiProfileRepository`
- `ProviderRepository`
- `TaxiReportRepository`
- `TripRepository`

### ملاحظة تنفيذ

وجود هذه الطبقات يعطي شكل architecture جاهز، لكن لا يكفي وحده. يجب فحص كل repository قبل الاعتماد على feature، لأن وجود `UnimplementedError` يعني أن الشاشة قد تكون mock أو واجهة غير مكتملة.

## قائمة فحص موديول التأجير

- الدخول بحساب module type rental/taxi.
- التأكد أن dashboard يوجه إلى صفحات rental الصحيحة.
- فتح home/menu/chat/provider/trip history/trip details.
- فحص أن أي زر لا يستدعي `UnimplementedError`.
- إضافة endpoints للـ repositories قبل تفعيل features للمستخدم.
- فصل صلاحيات rental عن صلاحيات المتجر العادي.
