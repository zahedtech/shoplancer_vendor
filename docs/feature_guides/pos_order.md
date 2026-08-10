# شرح Features: POS و Orders

هذا الملف يشرح رحلة إنشاء الطلب من شاشة POS، ثم متابعة الطلبات من شاشة الطلبات وتفاصيل الطلب.

## POS - PosScreen

**Path**: `lib/features/pos/screens/pos_screen.dart`
**Entry Point**: التبويب الأوسط داخل `DashboardScreen`
**Controllers**: `PosController`, `StoreController`
**Purpose**: إنشاء طلب يدوي جديد من الموبايل عبر البحث عن المنتجات أو مسح الباركود وإضافتها إلى السلة.

### ماذا يظهر للمستخدم

- AppBar بعنوان `إنشاء طلب جديد (POS)`.
- زر تفريغ السلة إذا كانت السلة غير فارغة.
- هيدر أعلى الصفحة يحتوي:
  - حقل بحث يفتح bottom sheet للبحث عن المنتجات.
  - زر كاميرا barcode scanner.
  - كاميرا مدمجة عند تفعيل scan.
- حالة فارغة عند عدم وجود منتجات في السلة.
- قائمة منتجات السلة عند إضافة منتجات.
- زر `متابعة الطلب` أسفل الصفحة عند وجود منتجات.

### ماذا يستطيع المستخدم أن يفعل

- فتح نافذة بحث المنتجات.
- مسح باركود منتج بالكاميرا.
- إضافة منتج إلى السلة.
- زيادة أو تقليل الكمية.
- حذف منتج من السلة.
- تفريغ السلة كاملة.
- متابعة الطلب إلى bottom sheet تفاصيل الطلب.

### البيانات والمنطق

- البحث بالاسم يتم داخل `_ProductSearchBottomSheet`.
- مسح الباركود يحاول أولًا إيجاد المنتج في `StoreController.itemList`.
- إذا لم يوجد، يستدعي `storeServiceInterface.getItemList` مع `barcode`.
- عند العثور على المنتج يستدعي `PosController.addToCart`.
- السلة مخزنة في `PosController.cartList`.

### الحالات

- **Empty cart**: تظهر رسالة أن السلة فارغة مع زر بحث وإضافة منتج.
- **Barcode not found**: يظهر snackbar.
- **Scanner**: الكاميرا تظهر inline داخل أعلى الصفحة وتغلق بعد scan ناجح.
- **Cart active**: يظهر زر متابعة الطلب مع عدد المنتجات والإجمالي.

### الانتقال

- من Dashboard tab الخاص بالـ POS.
- إلى `PosCartBottomSheet` عند متابعة الطلب.

## POS - PosCartBottomSheet

**Path**: `lib/features/pos/widgets/pos_cart_bottom_sheet.dart`
**Entry Point**: من زر متابعة الطلب داخل `PosScreen`
**Controller**: `PosController`
**Purpose**: إكمال بيانات الطلب قبل إرساله: العميل، نوع الطلب، الدفع، العنوان، والإجمالي.

### ماذا يظهر للمستخدم

- عنوان السلة مع عدد المنتجات.
- اختيار العميل:
  - حقل بحث بالاسم أو الهاتف.
  - زر إضافة عميل جديد.
  - قائمة نتائج العملاء.
  - بطاقة العميل المختار مع زر إزالة.
- قائمة المنتجات المختارة.
- أزرار زيادة/تقليل/حذف لكل منتج.
- اختيار نوع الطلب:
  - take away.
  - delivery.
- عند delivery:
  - رسوم التوصيل.
  - عنوان التوصيل.
  - رقم العمارة.
  - رقم الشقة.
- طريقة الدفع.
- حالة الدفع: paid/unpaid.
- ملخص المبلغ: subtotal, delivery fee, grand total.
- زر `تأكيد وإرسال الطلب`.

### ماذا يستطيع المستخدم أن يفعل

- البحث عن عميل موجود.
- إضافة عميل جديد عبر `AddPosCustomerDialog`.
- اختيار أو إزالة العميل.
- تعديل كميات المنتجات.
- اختيار نوع الطلب.
- إدخال عنوان ورسوم توصيل عند delivery.
- اختيار طريقة وحالة الدفع.
- إرسال الطلب.

### البيانات والمنطق

- `PosController.searchCustomers` يجلب العملاء.
- `PosController.selectCustomer` يحدد العميل.
- `PosController.setOrderType`, `setPaymentMethod`, `setPaymentStatus` تغير إعدادات الطلب.
- `PosController.subTotal` يحسب مجموع المنتجات.
- `PosController.grandTotal` يحسب الإجمالي بعد الخصومات ورسوم التوصيل.
- الإرسال يتم عبر `PosController.placeOrder`.

### الحالات

- **Empty cart**: لا يمكن إرسال الطلب.
- **Delivery validation**: إذا نوع الطلب delivery يجب إدخال عنوان.
- **Loading**: زر الإرسال يستخدم `posController.isLoading`.
- **Success**: عند نجاح الإرسال تغلق bottom sheet وتفرغ السلة.
- **Error**: يظهر snackbar أو `ApiChecker`.

### الانتقال

- يرجع إلى `PosScreen` بعد إغلاق bottom sheet.
- يفتح `AddPosCustomerDialog` لإضافة عميل.

## POS - PosController

**Path**: `lib/features/pos/controllers/pos_controller.dart`
**Purpose**: إدارة حالة إنشاء الطلب: السلة، العميل، الدفع، الخصومات، الطلبات المعلقة، والإرسال.

### الحالة الأساسية

- `cartList`: المنتجات داخل السلة.
- `selectedCustomer`: العميل المختار.
- `orderType`: `delivery`, `take_away`, أو `dine_in`.
- `paymentMethod`: مثل `cash_on_delivery` أو `digital_payment`.
- `paymentStatus`: `paid` أو `unpaid`.
- `discountAmount`, `couponDiscountAmount`, `couponCode`.
- `deliveryCharge`.
- `heldOrders`: طلبات معلقة في POS desktop.

### أهم العمليات

- `addToCart`: يضيف منتج أو يزيد كميته إذا موجود.
- `updateQuantity`: يزيد أو يقلل كمية سطر.
- `removeFromCart`: يحذف منتج من السلة.
- `clearCart`: يفرغ حالة الطلب.
- `searchCustomers`: يبحث عن العملاء.
- `addCustomer`: يضيف عميل جديد.
- `applyCoupon`: يطبق كوبون.
- `placeOrder`: يبني payload الطلب ويرسله.
- `holdCurrentOrderAndStartNew`: يعلّق الطلب الحالي ويبدأ طلبًا جديدًا.
- `resumeHeldOrder`: يسترجع طلبًا معلقًا.

### إرسال الطلب

`placeOrder` يبني body يحتوي:

- `customer_id`
- `order_type`
- `payment_method`
- `payment_status`
- `order_amount`
- `discount_amount`
- `coupon_discount_amount`
- `delivery_charge`
- `coupon_code`
- `address`, `house`, `floor`
- `order_note`
- `cart`
- بيانات منشئ الطلب مثل `created_by`, `creator_type`, `employee_id`, `seller_id`

إذا فشل الاتصال وكان المنصة تدعم local DB، يحفظ الطلب في queue محلي ويرسله لاحقًا عبر `PosSyncService`.

## POS - DesktopPosScreen

**Path**: `lib/features/pos/screens/desktop_pos_screen.dart`
**Entry Point**: route البداية على Windows/macOS حسب `RouteHelper.initial`
**Controllers**: `StoreController`, `CategoryController`, `PosController`
**Purpose**: واجهة كاشير للديسكتوب بمنتجات على الجانب وسلة/خيارات الطلب في المساحة الرئيسية.

### ماذا يظهر للمستخدم

- Sidebar بعرض ثابت للمنتجات.
- Search/Barcode في أعلى الـ sidebar.
- زر كاميرا scan.
- Tabs داخل الـ sidebar:
  - الأصناف.
  - المنتجات.
  - الطلبات المعلقة.
- Grid منتجات.
- لوحة إنشاء الطلب في المساحة الرئيسية.
- Header فيه:
  - عنوان إنشاء طلب.
  - زر تعليق وطلب جديد.
  - زر تفريغ السلة.
  - زر إعدادات.
- قائمة السلة مع أزرار كمية كبيرة.
- إعدادات الطلب والإجمالي في الأسفل.

### ماذا يستطيع المستخدم أن يفعل

- البحث عن منتجات.
- إدخال باركود يدويًا والضغط Enter.
- مسح باركود بالكاميرا.
- اختيار فئة لتصفية المنتجات.
- إضافة منتج للسلة من grid.
- تعديل سعر منتج سريعًا.
- تعليق الطلب الحالي واستئنافه لاحقًا.
- حذف طلب معلق.
- فتح إعدادات الديسكتوب.
- إرسال الطلب.

### البيانات والمنطق

- عند `initState` يحمل المنتجات والفئات.
- `_ProductsSidebar` يدير البحث والفئات والمنتجات والطلبات المعلقة.
- `_OrderCreationPanel` يدير عرض السلة وخيارات الطلب.
- `PosHeldOrder` يمثل snapshot لطلب معلق.
- إذا توجد سلة نشطة عند استئناف طلب معلق، يعلق الحالي أولًا حتى لا تضيع البيانات.

### الحالات

- **No products**: تظهر رسالة لا توجد منتجات مطابقة.
- **No held orders**: تظهر رسالة لا توجد طلبات معلقة.
- **Empty cart**: تظهر دعوة لاختيار منتجات.
- **Offline place order**: يدعم الحفظ المحلي حسب `PosController.placeOrder`.

### الانتقال

- يفتح مباشرة على الديسكتوب.
- إلى `DesktopSettingsScreen` من زر الإعدادات.

## POS - PosBarcodeScannerScreen

**Path**: `lib/features/pos/screens/pos_barcode_scanner_screen.dart`
**Route / Entry Point**: `RouteHelper.posBarcode` / `/pos-barcode`
**Purpose**: شاشة مخصصة لمسح باركود في POS.

### ماذا يظهر للمستخدم

- كاميرا scanner.
- إطار/منطقة مسح.
- إرشادات للمستخدم.

### ماذا يستطيع المستخدم أن يفعل

- مسح باركود لإضافة المنتج أو البحث عنه.
- الرجوع إذا لم يرغب بالمسح.

### ملاحظات

- توجد أيضًا كاميرا مدمجة داخل `PosScreen` و`DesktopPosScreen`.
- إذا كانت الشاشة غير مستخدمة في التدفق الحالي، تبقى كمسار احتياطي أو قديم.

## Order - OrderHistoryScreen

**Path**: `lib/features/order/screens/order_history_screen.dart`
**Entry Point**: تبويب Orders داخل `DashboardScreen`
**Controller**: `OrderController`
**Purpose**: عرض الطلبات الجارية وسجل الطلبات في تبويبين.

### ماذا يظهر للمستخدم

- AppBar بعنوان `my_orders`.
- TabBar:
  - Running Order.
  - Order History.
- `RunningOrderBodyWidget` للطلبات الحالية.
- `OrderHistoryBodyWidget` للطلبات السابقة.

### ماذا يستطيع المستخدم أن يفعل

- التبديل بين الطلبات الجارية والتاريخ.
- فتح تفاصيل طلب.
- التصفح والفلترة حسب ما توفره widgets الداخلية.

### البيانات والمنطق

- عند الفتح يستدعي:
  - `OrderController.getCurrentOrders`.
  - `OrderController.getPaginatedOrders(1, true)`.
- الطلبات الجارية تقسم حسب status داخل `OrderController.runningOrders`.
- سجل الطلبات يستخدم pagination.

### الحالات

- **Loading**: تعرض widgets الداخلية shimmer/loading.
- **Empty**: تعرض حالة لا توجد طلبات.
- **Pagination**: في سجل الطلبات.

### الانتقال

- من Dashboard tab الثاني.
- إلى `OrderDetailsScreen` عند اختيار طلب.

## Order - OrderDetailsScreen

**Path**: `lib/features/order/screens/order_details_screen.dart`
**Route / Entry Point**: `RouteHelper.orderDetails` / `/order-details`
**Controller**: `OrderController`
**Purpose**: عرض تفاصيل الطلب وتنفيذ إجراءات تشغيلية عليه حسب الحالة والصلاحيات.

### ماذا يظهر للمستخدم

- AppBar يحتوي رقم الطلب وحالة الطلب.
- تفاصيل العميل والعنوان والدفع.
- قائمة عناصر الطلب.
- تفاصيل الأسعار والضرائب والتوصيل.
- أزرار إجراءات حسب الحالة، مثل قبول/تحديث/إلغاء/تسليم.
- خيارات مشاركة الفاتورة كنص أو صورة.
- صور الوصفة أو إثبات التسليم عند الحاجة.
- dialogs وbottom sheets للإلغاء، إدخال مبلغ، جمع مال، تحقق التوصيل، وإرفاق صورة.

### ماذا يستطيع المستخدم أن يفعل

- مراجعة كل معلومات الطلب.
- تحديث حالة الطلب.
- إلغاء الطلب إذا الحالة والصلاحيات تسمح.
- مشاركة الفاتورة.
- إضافة أو عرض صور مرتبطة بالطلب.
- فتح محادثة أو اتصال حسب البيانات المتاحة.
- اختيار بديل لمنتج عند الحاجة.

### البيانات والمنطق

- عند الفتح:
  - يمسح بيانات الطلب السابقة.
  - يحمل profile إذا غير موجود.
  - يستدعي `getOrderDetails(orderId)`.
  - يستدعي `getOrderItemsDetails(orderId)`.
  - يبدأ timer يحدث تفاصيل الطلب كل 10 ثواني.
- عند pause يوقف timer.
- عند resume يعيد تشغيل timer.
- `_canStoreCancelOrder` يسمح بالإلغاء فقط في `pending` أو `confirmed` وبدون حالات نهائية مثل delivered/canceled/refunded.

### الحالات

- **Loading**: عندما `orderModel` أو `orderDetailsModel` غير محملة.
- **Polling**: تحديث كل 10 ثواني.
- **From notification**: إذا دخل من إشعار والرجوع غير ممكن، يرجع إلى initial route.
- **Cancel permission**: يعتمد على config `canceledByStore` وحالة الطلب.
- **Delivery image**: قد تظهر حقول صورة توصيل حسب controller.

### الانتقال

- من OrderHistory أو Home running orders أو notification.
- إلى initial route عند الرجوع من notification.
- إلى شاشات/حوارات فرعية حسب إجراءات الطلب.

## Order - AlternativeItemSelectionScreen

**Path**: `lib/features/order/screens/alternative_item_selection_screen.dart`
**Route / Entry Point**: `RouteHelper.alternativeItemSelection`
**Controllers**: `StoreController`, `ProfileController`
**Purpose**: اختيار منتج بديل لطلب عندما يكون منتج معين غير متاح أو يحتاج تبديل.

### ماذا يظهر للمستخدم

- AppBar بعنوان اختيار منتج بديل.
- شريط فئات sticky.
- فلتر type إذا الموديول food وveg/non-veg مفعل.
- حقل بحث بالاسم.
- قائمة منتجات مع pagination.
- بطاقات منتج مع صورة وسعر وحالة توفر.

### ماذا يستطيع المستخدم أن يفعل

- اختيار فئة.
- البحث عن منتج.
- استخدام فلاتر الطعام عند توفرها.
- اختيار منتج بديل للطلب.
- الرجوع مع reset للفلاتر.

### البيانات والمنطق

- عند الفتح يحمل profile.
- يستدعي `StoreController.getItemList` مع `type: all`.
- يستدعي `getStoreCategories`.
- pagination عبر scroll listener.
- عند الرجوع يستدعي `storeController.resetFilters`.

### الحالات

- **Loading**: تحميل المنتجات أو الفئات.
- **No store**: ينتظر profile.
- **Pagination**: تحميل صفحات إضافية عند نهاية القائمة.
- **Filter reset**: عند الخروج.

### الانتقال

- من تفاصيل الطلب أو إجراء اختيار بديل.
- يرجع إلى الطلب بعد الاختيار أو الرجوع.

## OrderController - دور عام

**Path**: `lib/features/order/controllers/order_controller.dart`

`OrderController` يدير:

- الطلبات الجارية `runningOrders`.
- سجل الطلبات `historyOrderList`.
- تفاصيل الطلب `orderModel`.
- عناصر الطلب `orderDetailsModel`.
- حالات الفلاتر والتواريخ.
- أسباب الإلغاء.
- صور الوصفة أو إثبات التسليم.
- checklist لعناصر الطلب.
- تحديث الحالة وإرسال إشعارات التسليم.

عند توثيق أي إجراء في تفاصيل الطلب، يجب الرجوع إلى `OrderController` لمعرفة:

- هل الإجراء يعتمد على status.
- هل يحتاج صورة أو OTP.
- هل يغير القائمة أو تفاصيل الطلب.
- هل يعرض snackbar أو يستخدم `ApiChecker`.

## رحلة إنشاء الطلب المختصرة

1. يفتح المستخدم POS من Dashboard أو Desktop.
2. يبحث عن منتج أو يمسح باركود.
3. يضيف المنتجات إلى السلة.
4. يعدل الكميات.
5. يفتح متابعة الطلب.
6. يختار العميل أو يضيف عميل جديد.
7. يختار نوع الطلب وطريقة الدفع وحالة الدفع.
8. إذا كان الطلب delivery، يدخل العنوان ورسوم التوصيل.
9. يضغط تأكيد وإرسال الطلب.
10. عند النجاح تفرغ السلة ويظهر تأكيد.
11. الطلب يظهر لاحقًا في الطلبات الجارية أو سجل الطلبات حسب حالته.

## ملاحظات متابعة

- يجب توثيق `RunningOrderBodyWidget` و`OrderHistoryBodyWidget` بالتفصيل عند استكمال ملف order.
- يجب مراجعة كل أزرار `OrderDetailsScreen` لأنها كثيرة وتعتمد على status.
- يجب توثيق offline POS flow بشكل أعمق إذا كان الديسكتوب جزءًا مهمًا من التشغيل.
