# شرح Features: Addons, Categories, Banners, Coupons, Campaigns

هذا الملف يغطي ميزات تشغيل الكتالوج والعروض: الإضافات، الفئات، البنرات، الكوبونات، والحملات.

## Addon - AddonScreen

**Path**: `lib/features/addon/screens/addon_screen.dart`
**Route / Entry Point**: `RouteHelper.addons` / `/addons`
**Controller**: `AddonController`, `StoreController`, `ProfileController`
**Purpose**: عرض وإدارة إضافات المنتجات.

### ماذا يظهر للمستخدم

- AppBar بعنوان `addons`.
- زر عائم لإضافة addon.
- قائمة addons، وكل عنصر يعرض:
  - الاسم.
  - الفئة التابعة.
  - السعر أو `free`.
  - menu للإجراءات.

### ماذا يستطيع المستخدم أن يفعل

- تحديث القائمة بالسحب.
- إضافة addon جديد إذا `itemSection` مفعلة.
- تعديل addon موجود.
- حذف addon عبر dialog تأكيد.

### البيانات والمنطق

- عند الفتح يحمل:
  - `AddonController.getAddonList`.
  - `AddonController.getAddonCategoryList`.
  - `StoreController.getVatTaxList` إذا `systemTaxType == product_wise`.
- يمنع الإضافة إذا admin أغلق `itemSection`.

### الحالات

- **Loading**: CircularProgressIndicator.
- **Empty**: `no_addon_found`.
- **Blocked by admin**: snackbar.

## Addon - AddAddonScreen

**Path**: `lib/features/addon/screens/add_addon_screen.dart`
**Route / Entry Point**: `RouteHelper.addAddon` / `/add-addon`
**Purpose**: إضافة أو تعديل addon.

### ماذا يظهر للمستخدم

- AppBar يختلف بين add/update.
- حقول الاسم والسعر.
- اختيار فئة addon.
- اختيار VAT tax عند product-wise tax.
- زر submit/update.

### ماذا يستطيع المستخدم أن يفعل

- إدخال اسم وسعر addon.
- ربط addon بفئة.
- اختيار ضرائب VAT.
- حفظ أو تحديث addon.

### الحالات

- الاسم مطلوب.
- السعر مطلوب.
- الفئة مطلوبة.
- VAT مطلوب عند product-wise tax.

## Category - CategoryScreen

**Path**: `lib/features/category/screens/category_screen.dart`
**Route / Entry Point**: `RouteHelper.categories` / `/categories`
**Controller**: `CategoryController`
**Purpose**: عرض الفئات الرئيسية وإدارة الانتقال للفئات الفرعية.

### ماذا يظهر للمستخدم

- AppBar بعنوان `categories`.
- زر `add_category` يفتح bottom sheet لاختيار/إضافة فئات من الكتالوج العام.
- قائمة فئات رئيسية مع:
  - الصورة.
  - الاسم.
  - ID.
  - حالة active/inactive.

### ماذا يستطيع المستخدم أن يفعل

- تحديث القائمة.
- فتح فئة لرؤية الفئات الفرعية.
- إضافة فئة من قائمة global categories.

### البيانات والمنطق

- يستدعي `CategoryController.getCategoryList`.
- عند الضغط على فئة يفتح `SubCategoryScreen(parentCategory: category)`.
- يستخدم API مباشر في بعض أجزاء الصفحة لجلب global categories.

### الحالات

- **Loading**: انتظار category list.
- **Empty**: لا توجد فئات.
- **Inactive**: تظهر الفئة بلون/وسم متوقفة.

## Category - SubCategoryScreen

**Path**: `lib/features/category/screens/sub_category_screen.dart`
**Purpose**: عرض وإدارة الفئات الفرعية لفئة رئيسية.

### ماذا يظهر للمستخدم

- عنوان مرتبط باسم الفئة الرئيسية.
- قائمة فئات فرعية.
- حالات تحميل/فارغ.

### ماذا يستطيع المستخدم أن يفعل

- مشاهدة الفئات الفرعية.
- اختيار أو إدارة فئة فرعية حسب الأزرار المتاحة.
- الرجوع للفئات الرئيسية.

## Category - CategoryProductScreen

**Path**: `lib/features/category/screens/category_product_screen.dart`
**Purpose**: عرض منتجات فئة معينة.

### ماذا يظهر للمستخدم

- AppBar باسم الفئة.
- قائمة منتجات هذه الفئة.
- بحث/فلترة حسب تطبيق الصفحة.

## Banner - BannerListScreen

**Path**: `lib/features/banner/screens/banner_list_screen.dart`
**Route / Entry Point**: `RouteHelper.bannerList` / `/banner-list`
**Controller**: `BannerController`
**Purpose**: إدارة بنرات المتجر والبنرات الجاهزة من الكتالوج.

### ماذا يظهر للمستخدم

- AppBar بعنوان `banner_list`.
- Tooltip يشرح أين تظهر البنرات للعملاء.
- segmented control:
  - `catalog_banners`.
  - `my_banners`.
- قائمة بنرات.
- زر إضافة يظهر عند وجود banners.

### ماذا يستطيع المستخدم أن يفعل

- التبديل بين بنرات الكتالوج وبنراته الخاصة.
- إضافة بنر من الكتالوج إلى المتجر.
- فتح تفاصيل/رابط بنر إذا متاح.
- حذف أو إدارة بنراته.
- إنشاء بنر جديد.

### البيانات والمنطق

- عند الفتح يحمل:
  - `getBannerList`.
  - `getCatalogBannerList`.
- يحدد هل بنر الكتالوج مضاف بالفعل عبر مقارنة `bannerCatalogId`.

### الحالات

- **Catalog loading** أو **store loading**.
- **Empty**: لا توجد بنرات.
- **Item loading**: `_loadingCatalogBannerId` عند إضافة بنر محدد.

## Banner - AddBannerScreen

**Path**: `lib/features/banner/screens/add_banner_screen.dart`
**Route / Entry Point**: `RouteHelper.addBanner` / `/add-banner`
**Purpose**: إضافة أو تعديل بنر.

### ماذا يظهر للمستخدم

- نموذج بنر.
- نوع بنر image/text.
- لون خلفية افتراضي وخيارات ألوان.
- اختيار صورة أو بيانات نصية حسب النوع.

### الحالات

- تحقق من الحقول المطلوبة.
- تحميل أثناء الإرسال.

## Coupon - CouponScreen

**Path**: `lib/features/coupon/screens/coupon_screen.dart`
**Route / Entry Point**: `RouteHelper.coupon` / `/coupon`
**Controller**: `CouponController`
**Purpose**: عرض وإدارة كوبونات المتجر.

### ماذا يظهر للمستخدم

- AppBar بعنوان `coupon_list`.
- زر عائم لإضافة كوبون.
- بطاقات كوبونات بتصميم بصري.
- لكل كوبون:
  - قيمة الخصم أو free delivery.
  - كود الكوبون.
  - تاريخ البداية والنهاية.
  - الحد الأدنى للشراء.
  - menu للإجراءات.

### ماذا يستطيع المستخدم أن يفعل

- تحديث القائمة.
- فتح تفاصيل كوبون bottom sheet.
- تغيير حالة الكوبون.
- تعديل كوبون.
- حذف كوبون بعد تأكيد.
- إضافة كوبون جديد.

### البيانات والمنطق

- عند الفتح يستدعي `CouponController.getCouponList`.
- عند edit يحمل التفاصيل عبر `getCouponDetails`.
- يستخدم `CouponCardDialogueWidget` لعرض التفاصيل.

### الحالات

- **Loading**: CustomLoader عند تحميل تفاصيل edit.
- **Empty**: قائمة فارغة.
- **Delete confirmation**: ConfirmationDialogWidget.

## Coupon - AddCouponScreen

**Path**: `lib/features/coupon/screens/add_coupon_screen.dart`
**Purpose**: إضافة أو تعديل كوبون.

### ماذا يظهر للمستخدم

- حقول بيانات الكوبون.
- نوع الخصم.
- قيمة الخصم.
- تاريخ البداية والنهاية.
- الحد الأدنى للشراء.
- إعدادات الحالة أو الاستخدام حسب المتاح.

## Campaign - CampaignScreen

**Path**: `lib/features/campaign/screens/campaign_screen.dart`
**Route / Entry Point**: `RouteHelper.campaign` / `/campaign`
**Controller**: `CampaignController`
**Purpose**: عرض الحملات المتاحة والحملات التي انضم لها المتجر.

### ماذا يظهر للمستخدم

- AppBar بعنوان `campaign`.
- popup filter فيه:
  - all.
  - joined.
- قائمة حملات عبر `CampaignWidget`.

### ماذا يستطيع المستخدم أن يفعل

- عرض كل الحملات.
- فلترة الحملات المنضم لها.
- تحديث القائمة بالسحب.
- فتح تفاصيل حملة من widget الحملة.

### البيانات والمنطق

- يستدعي `CampaignController.getCampaignList`.
- الفلتر يستخدم `CampaignController.filterCampaign`.

### الحالات

- **Loading**: CircularProgressIndicator.
- **Empty**: `no_campaign_available`.

## Campaign - CampaignDetailsScreen

**Path**: `lib/features/campaign/screens/campaign_details_screen.dart`
**Route / Entry Point**: `RouteHelper.campaignDetails` / `/campaign-details`
**Purpose**: عرض تفاصيل حملة وإجراءات الانضمام أو المتابعة.

### ماذا يظهر للمستخدم

- تفاصيل الحملة.
- المنتجات/الشروط/التواريخ حسب بيانات الحملة.
- أزرار الانضمام أو الإجراءات المتاحة.

## ملاحظات متابعة

- يجب قراءة `AddCouponScreen`, `AddBannerScreen`, و`CampaignDetailsScreen` عند الحاجة لتوثيق validation field-by-field.
- هذه الصفحة توثق الوظيفة والسلوك المرئي، لا تفاصيل كل payload.
